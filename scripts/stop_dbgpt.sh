#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PID_FILE="$PROJECT_ROOT/.dbgpt.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 $PID 2>/dev/null; then
        echo "停止 DB-GPT 服务 (PID: $PID)..."
        kill $PID
        rm -f "$PID_FILE"
        echo "DB-GPT 服务已停止"
    else
        echo "DB-GPT 服务未运行"
        rm -f "$PID_FILE"
    fi
else
    echo "找不到 PID 文件，尝试通过端口查找进程..."
    lsof -ti:5000 | xargs kill -9 2>/dev/null || echo "没有找到运行的 DB-GPT 服务"
fi
