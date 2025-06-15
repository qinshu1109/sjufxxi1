#!/bin/bash

# 使用MCP工具推送到GitHub的脚本
echo "=== 使用MCP工具推送项目到GitHub ==="
echo ""

# 设置GitHub Token环境变量
export GITHUB_TOKEN="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"

# 启动带有MCP工具的Claude Code会话
echo "启动Claude Code会话，集成GitHub MCP工具..."
echo ""
echo "可用的MCP工具:"
echo "- fs: 文件系统操作"
echo "- github: GitHub仓库管理"
echo "- git: Git版本控制"
echo "- fetch: HTTP请求"
echo "- promptx: AI专业角色增强系统 🎭"
echo ""
echo "Claude Code将自动检测MCP工具并提供以下功能:"
echo "1. 自动创建GitHub仓库"
echo "2. 推送项目文件"
echo "3. 处理OAuth认证"
echo "4. PromptX专业角色和记忆管理"
echo ""

cd /home/qinshu/douyin-analytics

# 使用MCP配置启动Claude Code
claude --mcp-config=/home/qinshu/MCP工具/mcp-config.json