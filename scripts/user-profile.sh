#!/bin/bash
# 获取小红书用户主页

USER_ID="$1"

if [ -z "$USER_ID" ]; then
    echo "用法: $0 <user_id>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/mcp-call.sh" user_profile "{\"user_id\": \"$USER_ID\"}"
