#!/bin/bash
# 更稳妥的互动脚本：自动重试 + 必要时重启 MCP
# 用法:
#   ./interact-safe.sh like <feed_id> <xsec_token>
#   ./interact-safe.sh comment <feed_id> <xsec_token> "评论内容"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ACTION="${1:-}"
FEED_ID="${2:-}"
XSEC_TOKEN="${3:-}"
CONTENT="${4:-}"

if [ -z "$ACTION" ] || [ -z "$FEED_ID" ] || [ -z "$XSEC_TOKEN" ]; then
  echo "用法:"
  echo "  $0 like <feed_id> <xsec_token>"
  echo "  $0 comment <feed_id> <xsec_token> \"评论内容\""
  exit 1
fi

if [ "$ACTION" = "comment" ] && [ -z "$CONTENT" ]; then
  echo "comment 模式需要评论内容"
  exit 1
fi

call_with_retry() {
  local tool="$1"
  local args="$2"

  # 首次尝试：内部重试 2 次
  XHS_MCP_TIMEOUT=150 XHS_MCP_RETRIES=2 "$SCRIPT_DIR/mcp-call.sh" "$tool" "$args" && return 0

  echo "[interact-safe] 首轮失败，尝试重启 MCP 后再试..." >&2
  "$SCRIPT_DIR/stop-mcp.sh" >/dev/null 2>&1 || true
  "$SCRIPT_DIR/start-mcp.sh" --headless=false >/dev/null 2>&1

  # 重启后再尝试一次
  XHS_MCP_TIMEOUT=150 XHS_MCP_RETRIES=1 "$SCRIPT_DIR/mcp-call.sh" "$tool" "$args"
}

case "$ACTION" in
  like)
    # 兼容新旧版本：先尝试仅 feed_id + token
    if call_with_retry "like_feed" "{\"feed_id\":\"$FEED_ID\",\"xsec_token\":\"$XSEC_TOKEN\"}"; then
      exit 0
    fi

    # 旧版本可能需要 like 参数
    call_with_retry "like_feed" "{\"feed_id\":\"$FEED_ID\",\"xsec_token\":\"$XSEC_TOKEN\",\"like\":true}"
    ;;
  comment)
    esc_content=$(printf '%s' "$CONTENT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
    call_with_retry "post_comment_to_feed" "{\"feed_id\":\"$FEED_ID\",\"xsec_token\":\"$XSEC_TOKEN\",\"content\":$esc_content}"
    ;;
  *)
    echo "不支持的 ACTION: $ACTION"
    exit 1
    ;;
esac
