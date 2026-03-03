#!/bin/bash
# 启动小红书 MCP 服务（支持服务器无桌面环境下自动启用 Xvfb）

set -euo pipefail

XHS_MCP="${XHS_MCP:-$HOME/.local/bin/xiaohongshu-mcp}"
PID_DIR="$HOME/.xiaohongshu"
PID_FILE="$PID_DIR/mcp.pid"
LOG_FILE="$PID_DIR/mcp.log"

# Xvfb 相关（可通过环境变量覆盖）
XVFB_PID_FILE="${XHS_XVFB_PID_FILE:-$PID_DIR/xvfb.pid}"
XVFB_DISPLAY="${XHS_XVFB_DISPLAY:-:99}"
XVFB_SCREEN="${XHS_XVFB_SCREEN:-1024x768x24}"

# Cookies 路径（可通过环境变量覆盖）
# XHS_COOKIES_SRC: 源 cookies 文件（用于远程服务器场景）
# 默认检查 ~/cookies.json 和 ~/.xiaohongshu/cookies.json
COOKIES_DST="/tmp/cookies.json"

mkdir -p "$PID_DIR"

sync_cookies() {
    local src=""

    if [ -n "${XHS_COOKIES_SRC:-}" ] && [ -f "$XHS_COOKIES_SRC" ]; then
        src="$XHS_COOKIES_SRC"
    elif [ -f "$HOME/cookies.json" ]; then
        src="$HOME/cookies.json"
    elif [ -f "$HOME/.xiaohongshu/cookies.json" ]; then
        src="$HOME/.xiaohongshu/cookies.json"
    fi

    if [ -n "$src" ]; then
        if [ ! -f "$COOKIES_DST" ] || [ "$src" -nt "$COOKIES_DST" ]; then
            cp "$src" "$COOKIES_DST"
            echo "已同步 cookies: $src -> $COOKIES_DST"
        fi
    fi
}

ensure_xvfb() {
    local display_num
    display_num="${XVFB_DISPLAY#:}"

    if [ -n "${DISPLAY:-}" ]; then
        echo "检测到 DISPLAY=${DISPLAY}，跳过 Xvfb 启动"
        return 0
    fi

    if command -v xdpyinfo >/dev/null 2>&1; then
        if xdpyinfo -display "$XVFB_DISPLAY" >/dev/null 2>&1; then
            export DISPLAY="$XVFB_DISPLAY"
            echo "复用已存在的 Xvfb 显示: $DISPLAY"
            return 0
        fi
    fi

    if ! command -v Xvfb >/dev/null 2>&1; then
        echo "✗ 未找到 Xvfb。请先安装后重试："
        echo "  Debian/Ubuntu: sudo apt-get update && sudo apt-get install -y xvfb"
        echo "  RHEL/CentOS:   sudo yum install -y xorg-x11-server-Xvfb"
        exit 1
    fi

    echo "启动 Xvfb: display=$XVFB_DISPLAY, screen=$XVFB_SCREEN"
    nohup Xvfb "$XVFB_DISPLAY" -screen 0 "$XVFB_SCREEN" -ac > "$PID_DIR/xvfb.log" 2>&1 &
    echo $! > "$XVFB_PID_FILE"
    sleep 1

    if kill -0 "$(cat "$XVFB_PID_FILE")" 2>/dev/null; then
        export DISPLAY="$XVFB_DISPLAY"
        echo "✓ Xvfb 已启动 (PID: $(cat "$XVFB_PID_FILE"), DISPLAY=$DISPLAY)"
    else
        echo "✗ Xvfb 启动失败，查看日志: $PID_DIR/xvfb.log"
        exit 1
    fi
}

sync_cookies

# 检查是否已在运行
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "MCP 服务已在运行 (PID: $PID)"
        echo "如需重启，请先运行 stop-mcp.sh"
        exit 0
    fi
fi

HEADLESS="true"
for arg in "$@"; do
    case $arg in
        --headless=false)
            HEADLESS="false"
            ;;
    esac
done

# 在无桌面服务器上，非 headless 模式自动启用 Xvfb
if [ "$HEADLESS" = "false" ]; then
    ensure_xvfb
fi

echo "启动小红书 MCP 服务..."
if [ "$HEADLESS" = "false" ]; then
    nohup "$XHS_MCP" -headless=false > "$LOG_FILE" 2>&1 &
else
    nohup "$XHS_MCP" > "$LOG_FILE" 2>&1 &
fi

echo $! > "$PID_FILE"
sleep 2

if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "✓ MCP 服务已启动 (PID: $(cat "$PID_FILE"))"
    echo "  端点: http://localhost:18060/mcp"
    echo "  日志: $LOG_FILE"
    if [ "$HEADLESS" = "false" ]; then
        echo "  DISPLAY: ${DISPLAY:-<unset>}"
    fi
else
    echo "✗ 启动失败，查看日志: $LOG_FILE"
    cat "$LOG_FILE"
    exit 1
fi
