#!/bin/bash

echo "🎭 启动 VS Code 与 PromptX-MCP 集成"
echo "=================================="

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

echo -e "\n${BLUE}📁 VS Code MCP 配置检查${NC}"
echo "----------------"

VSCODE_MCP_CONFIG=".vscode/mcp.json"
VSCODE_SETTINGS=".vscode/settings.json"

if [ -f "$VSCODE_MCP_CONFIG" ]; then
    echo -e "${GREEN}✅ VS Code MCP 配置存在${NC}: $VSCODE_MCP_CONFIG"
    
    # 验证 JSON 格式
    if python3 -c "import json; json.load(open('$VSCODE_MCP_CONFIG'))" 2>/dev/null; then
        echo -e "${GREEN}✅ MCP 配置格式正确${NC}"
    else
        echo -e "${RED}❌ MCP 配置格式错误${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ VS Code MCP 配置文件不存在${NC}: $VSCODE_MCP_CONFIG"
    exit 1
fi

if [ -f "$VSCODE_SETTINGS" ]; then
    echo -e "${GREEN}✅ VS Code 设置文件存在${NC}: $VSCODE_SETTINGS"
    
    # 检查 MCP 是否启用
    if grep -q '"chat.mcp.enabled": true' "$VSCODE_SETTINGS"; then
        echo -e "${GREEN}✅ MCP 支持已启用${NC}"
    else
        echo -e "${YELLOW}⚠️ MCP 支持未启用${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ VS Code 设置文件不存在${NC}: $VSCODE_SETTINGS"
fi

echo -e "\n${BLUE}🧪 PromptX 功能验证${NC}"
echo "----------------"

# 快速验证 PromptX
echo -n "验证 PromptX 安装: "
if timeout 10 npx -y -f dpml-prompt@snapshot --version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 正常${NC}"
else
    echo -e "${RED}❌ 失败${NC}"
    echo "正在尝试安装 PromptX..."
    if npm install -g dpml-prompt@snapshot; then
        echo -e "${GREEN}✅ PromptX 安装成功${NC}"
    else
        echo -e "${RED}❌ PromptX 安装失败${NC}"
        exit 1
    fi
fi

echo -n "验证女娲角色: "
if timeout 15 npx -y -f dpml-prompt@snapshot hello | grep -q "nuwa" 2>/dev/null; then
    echo -e "${GREEN}✅ 可用${NC}"
else
    echo -e "${YELLOW}⚠️ 检查中${NC}"
fi

echo -e "\n${PURPLE}🎯 VS Code MCP 工具清单${NC}"
echo "----------------"
echo "📦 基础工具 (10个):"
echo "  • filesystem - 文件系统访问"
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

echo -e "\n${BLUE}🚀 启动 VS Code${NC}"
echo "----------------"

echo "即将启动 VS Code 与完整的 MCP 工具生态系统..."
echo ""
echo -e "${YELLOW}💡 使用提示：${NC}"
echo "1. 启动后，在 VS Code 中："
echo "   • 打开 Copilot Chat (Ctrl+Alt+I)"
echo "   • 选择 Agent 模式"
echo "   • 点击 Tools 按钮查看所有 MCP 工具"
echo ""
echo "2. 使用 PromptX 工具："
echo "   • 在聊天中输入 #promptx 来引用工具"
echo "   • 使用 /mcp.promptx.hello 发现角色"
echo "   • 使用 /mcp.promptx.action 激活女娲角色"
echo ""
echo "3. MCP 资源访问："
echo "   • 点击 Add Context > MCP Resources"
echo "   • 选择需要的资源类型"
echo ""
echo "4. 其他 MCP 工具也已就绪："
echo "   • GitHub 自动化操作"
echo "   • 文件系统管理"
echo "   • 截图和 OCR 功能"
echo ""

read -p "按回车键启动 VS Code..."

# 启动 VS Code
echo -e "\n${GREEN}🎉 启动 VS Code...${NC}"
code "$PROJECT_DIR"
