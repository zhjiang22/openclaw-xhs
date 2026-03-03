#!/bin/bash
# 启动小红书登录工具（支持服务器下通过 Xvfb 提供虚拟显示）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
XHS_LOGIN="${XHS_LOGIN:-$HOME/.local/bin/xiaohongshu-login}"

HEADLESS="false"
for arg in "$@"; do
    case $arg in
        --headless=true)
            HEADLESS="true"
            ;;
    esac
done

echo "启动小红书登录工具..."

if [ "$HEADLESS" = "false" ]; then
    # 借用 start-mcp.sh 的 Xvfb 逻辑：先启动一次非 headless MCP 仅用于拉起 DISPLAY 环境（若需要）
    if [ -z "${DISPLAY:-}" ]; then
        echo "未检测到 DISPLAY，尝试通过 start-mcp.sh 准备 Xvfb..."
        "$SCRIPT_DIR/start-mcp.sh" --headless=false >/dev/null 2>&1 || true
        "$SCRIPT_DIR/stop-mcp.sh" >/dev/null 2>&1 || true
        export DISPLAY="${XHS_XVFB_DISPLAY:-:99}"
    fi
    echo "当前 DISPLAY: ${DISPLAY:-<unset>}"
fi

"$XHS_LOGIN"
