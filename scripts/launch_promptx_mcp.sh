#!/bin/bash

echo "🎭 启动 PromptX 增强的 MCP 会话"
echo "================================"

PROJECT_DIR="/home/qinshu/douyin-analytics"
cd "$PROJECT_DIR"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "\n${BLUE}🔧 环境准备${NC}"
echo "----------------"

# 设置环境变量
export GITHUB_TOKEN="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"
export TZ='Asia/Shanghai'
export PROMPTX_WORKSPACE="/home/qinshu/douyin-analytics"

echo -e "${GREEN}✅ 环境变量已设置${NC}"
echo "   - GITHUB_TOKEN: ${GITHUB_TOKEN:0:20}..."
echo "   - TZ: $TZ"
echo "   - PROMPTX_WORKSPACE: $PROMPTX_WORKSPACE"

# 确保配置文件存在
CONFIG_SOURCE="/home/qinshu/MCP工具/mcp-config.json"
CONFIG_TARGET="$HOME/.config/claude/claude_desktop_config.json"

echo -e "\n${BLUE}📁 配置文件检查${NC}"
echo "----------------"

if [ -f "$CONFIG_SOURCE" ]; then
    echo -e "${GREEN}✅ 源配置文件存在${NC}: $CONFIG_SOURCE"
    
    # 创建目标目录
    mkdir -p "$(dirname "$CONFIG_TARGET")"
    
    # 复制配置文件
    cp "$CONFIG_SOURCE" "$CONFIG_TARGET"
    echo -e "${GREEN}✅ 配置文件已复制到${NC}: $CONFIG_TARGET"
else
    echo -e "${RED}❌ 源配置文件不存在${NC}: $CONFIG_SOURCE"
    exit 1
fi

echo -e "\n${BLUE}🧪 PromptX 功能验证${NC}"
echo "----------------"

# 快速验证 PromptX
echo -n "验证 PromptX 安装: "
if timeout 10 npx -y -f dpml-prompt@snapshot --version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 正常${NC}"
else
    echo -e "${RED}❌ 失败${NC}"
    exit 1
fi

echo -n "验证女娲角色: "
if timeout 15 npx -y -f dpml-prompt@snapshot hello | grep -q "nuwa" 2>/dev/null; then
    echo -e "${GREEN}✅ 可用${NC}"
else
    echo -e "${YELLOW}⚠️ 检查中${NC}"
fi

echo -e "\n${PURPLE}🎯 MCP 工具清单${NC}"
echo "----------------"
echo "📦 基础工具 (10个):"
echo "  • fs - 文件系统访问"
echo "  • github - GitHub仓库管理"
echo "  • git - Git版本控制"
echo "  • fetch - HTTP请求处理"
echo "  • memory - 内存存储服务器"
echo "  • screenshot - 屏幕截图工具"
echo "  • ocr - OCR文字识别"
echo "  • autogui - GUI自动化操作"
echo "  • time - 时间管理服务"
echo "  • vision - 计算机视觉"

echo -e "\n🎭 PromptX 增强系统 (1个):"
echo "  • promptx - AI专业角色增强系统"
echo "    ├── promptx_init - 系统初始化"
echo "    ├── promptx_hello - 角色发现"
echo "    ├── promptx_action - 角色激活"
echo "    ├── promptx_learn - 知识学习"
echo "    ├── promptx_recall - 记忆检索"
echo "    └── promptx_remember - 经验保存"

echo -e "\n${YELLOW}⭐ 特色角色：女娲 (Nuwa)${NC}"
echo "  专业角色创造顾问，具备："
echo "  • 🎯 需求洞察能力"
echo "  • 🏗️ 角色设计能力"
echo "  • ⚡ 快速交付能力"
echo "  • 🔧 系统集成能力"

echo -e "\n${BLUE}🚀 启动 Claude Code${NC}"
echo "----------------"

echo "即将启动 Claude Code 与完整的 MCP 工具生态系统..."
echo ""
echo -e "${YELLOW}💡 使用提示：${NC}"
echo "1. 启动后，您可以使用以下 PromptX 工具："
echo "   • promptx_hello - 发现所有可用角色"
echo "   • promptx_action nuwa - 激活女娲角色"
echo "   • promptx_remember '信息' - 保存重要信息"
echo ""
echo "2. 女娲角色激活后，您可以："
echo "   • 描述您需要的专业角色"
echo "   • 女娲将为您快速创建角色"
echo "   • 3步流程，2分钟完成"
echo ""
echo "3. 其他 MCP 工具也已就绪："
echo "   • GitHub 自动化推送"
echo "   • 文件系统操作"
echo "   • 截图和 OCR 功能"
echo ""

read -p "按回车键启动 Claude Code..."

# 启动 Claude Code
echo -e "\n${GREEN}🎉 启动 Claude Code...${NC}"
exec claude --config="$CONFIG_TARGET"
