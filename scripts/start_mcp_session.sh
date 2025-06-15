#!/bin/bash

echo "🚀 启动MCP增强的Claude Code会话..."
echo ""

# 设置环境变量
export GITHUB_TOKEN="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"
export TZ='Asia/Shanghai'

# 进入项目目录
cd /home/qinshu/douyin-analytics

echo "📍 当前目录: $(pwd)"
echo "🔧 已配置环境变量:"
echo "   - GITHUB_TOKEN: ${GITHUB_TOKEN:0:20}..."
echo "   - TZ: $TZ"
echo ""

echo "✅ 可用的MCP工具:"
claude mcp list | while read line; do
    echo "   - $line"
done
echo ""

echo "🎯 启动任务: 创建并推送douyin-analytics仓库"
echo ""
echo "在新会话中，请说:"
echo '   "使用GitHub MCP工具创建douyin-analytics仓库并推送所有项目文件"'
echo ""

# 启动带MCP的Claude Code会话
exec claude --mcp-config=/home/qinshu/MCP工具/mcp-config.json