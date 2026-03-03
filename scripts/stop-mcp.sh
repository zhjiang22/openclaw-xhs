#!/bin/bash
# 停止小红书 MCP 服务（可选同时停止 Xvfb）

set -euo pipefail

PID_DIR="$HOME/.xiaohongshu"
PID_FILE="$PID_DIR/mcp.pid"
XVFB_PID_FILE="${XHS_XVFB_PID_FILE:-$PID_DIR/xvfb.pid}"

stop_by_pid_file() {
    local name="$1"
    local file="$2"

    if [ ! -f "$file" ]; then
        echo "$name 未运行"
        return 0
    fi

    local pid
    pid="$(cat "$file")"
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" || true
        echo "✓ 已停止 $name (PID: $pid)"
    else
        echo "$name 进程不存在，清理 PID 文件"
    fi
    rm -f "$file"
}

stop_by_pid_file "MCP 服务" "$PID_FILE"

# 默认不主动杀共享 DISPLAY；仅清理我们自己拉起的 Xvfb
if [ "${XHS_STOP_XVFB:-1}" = "1" ]; then
    stop_by_pid_file "Xvfb" "$XVFB_PID_FILE"
fi
