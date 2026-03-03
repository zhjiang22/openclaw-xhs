#!/bin/bash
# 通用 MCP 调用脚本（支持 Streamable HTTP + Session ID + 可重试）

set -euo pipefail

TOOL_NAME="${1:-}"
TOOL_ARGS="${2:-}"
MCP_URL="${MCP_URL:-http://localhost:18060/mcp}"
MCP_TIMEOUT="${XHS_MCP_TIMEOUT:-120}"
MCP_RETRIES="${XHS_MCP_RETRIES:-1}"
export no_proxy="${no_proxy:+$no_proxy,}localhost,127.0.0.1"

if [ -z "$TOOL_NAME" ]; then
    echo "用法: $0 <tool_name> [json_args]"
    echo ""
    echo "可用工具:"
    echo "  check_login_status    - 检查登录状态"
    echo "  search_feeds          - 搜索内容 {\"keyword\": \"...\"}"
    echo "  list_feeds            - 获取首页推荐"
    echo "  get_feed_detail       - 获取帖子详情 {\"feed_id\": \"...\", \"xsec_token\": \"...\"}"
    echo "  post_comment_to_feed  - 发表评论 {\"feed_id\": \"...\", \"xsec_token\": \"...\", \"content\": \"...\"}"
    echo "  user_profile          - 获取用户主页"
    echo "  like_feed             - 点赞/取消（具体参数受 xiaohongshu-mcp 版本影响）"
    echo "  favorite_feed         - 收藏/取消（具体参数受 xiaohongshu-mcp 版本影响）"
    echo "  get_login_qrcode      - 获取登录二维码"
    echo "  publish_content       - 发布图文"
    echo "  publish_with_video    - 发布视频"
    exit 1
fi

[ -z "$TOOL_ARGS" ] && TOOL_ARGS="{}"

call_once() {
    # 1. Initialize 并获取 Session ID
    local init_response session_id result

    init_response=$(curl --noproxy '*' -s -i -X POST "$MCP_URL" \
      -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"openclaw","version":"1.0"}}}')

    session_id=$(echo "$init_response" | grep -i "Mcp-Session-Id" | awk '{print $2}' | tr -d '\r\n')

    if [ -z "$session_id" ]; then
        echo "错误: 无法获取 MCP Session ID"
        echo "请确保 MCP 服务正在运行: ./start-mcp.sh"
        return 2
    fi

    # 2. Initialized notification
    curl --noproxy '*' -s -X POST "$MCP_URL" \
      -H "Content-Type: application/json" \
      -H "Mcp-Session-Id: $session_id" \
      -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' > /dev/null

    # 3. Call tool
    result=$(curl --noproxy '*' -s --max-time "$MCP_TIMEOUT" -X POST "$MCP_URL" \
      -H "Content-Type: application/json" \
      -H "Mcp-Session-Id: $session_id" \
      -d "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"$TOOL_NAME\",\"arguments\":$TOOL_ARGS}}")

    if [ -z "$result" ]; then
        echo "错误: MCP 返回空响应"
        return 3
    fi

    # 打印
    if command -v jq &> /dev/null; then
        echo "$result" | jq .
    else
        echo "$result"
    fi

    # 失败检测：JSON-RPC error / MCP result.isError
    if command -v jq &> /dev/null; then
        local has_error has_iserror
        has_error=$(echo "$result" | jq -r 'has("error")')
        has_iserror=$(echo "$result" | jq -r '.result.isError // false')
        if [ "$has_error" = "true" ] || [ "$has_iserror" = "true" ]; then
            return 4
        fi
    else
        if echo "$result" | grep -q '"error"\|"isError"[[:space:]]*:[[:space:]]*true'; then
            return 4
        fi
    fi

    return 0
}

attempt=1
while [ "$attempt" -le "$MCP_RETRIES" ]; do
    if call_once; then
        exit 0
    fi

    if [ "$attempt" -lt "$MCP_RETRIES" ]; then
        echo "[mcp-call] 第 ${attempt} 次失败，1 秒后重试..." >&2
        sleep 1
    fi
    attempt=$((attempt + 1))
done

exit 1
