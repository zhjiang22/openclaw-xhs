#!/bin/bash
# 通用 MCP 调用脚本（支持 Streamable HTTP + Session ID）

set -e

TOOL_NAME="$1"
TOOL_ARGS="$2"
MCP_URL="${MCP_URL:-http://localhost:18060/mcp}"
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
    echo "  user_profile          - 获取用户主页 {\"user_id\": \"...\"}"
    echo "  like_feed             - 点赞/取消 {\"feed_id\": \"...\", \"xsec_token\": \"...\", \"like\": true}"
    echo "  favorite_feed         - 收藏/取消 {\"feed_id\": \"...\", \"xsec_token\": \"...\", \"favorite\": true}"
    echo "  get_login_qrcode      - 获取登录二维码"
    echo "  publish_content       - 发布图文"
    echo "  publish_with_video    - 发布视频"
    exit 1
fi

[ -z "$TOOL_ARGS" ] && TOOL_ARGS="{}"

# 1. Initialize 并获取 Session ID
INIT_RESPONSE=$(curl --noproxy '*' -s -i -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"openclaw","version":"1.0"}}}')

SESSION_ID=$(echo "$INIT_RESPONSE" | grep -i "Mcp-Session-Id" | awk '{print $2}' | tr -d '\r\n')

if [ -z "$SESSION_ID" ]; then
    echo "错误: 无法获取 MCP Session ID"
    echo "请确保 MCP 服务正在运行: ./start-mcp.sh"
    exit 1
fi

# 2. Initialized notification
curl --noproxy '*' -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -H "Mcp-Session-Id: $SESSION_ID" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' > /dev/null

# 3. Call tool
RESULT=$(curl --noproxy '*' -s --max-time 120 -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -H "Mcp-Session-Id: $SESSION_ID" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"$TOOL_NAME\",\"arguments\":$TOOL_ARGS}}")

# 输出结果
if command -v jq &> /dev/null; then
    echo "$RESULT" | jq .
else
    echo "$RESULT"
fi
