#!/bin/bash

echo "🔍 VS Code MCP 配置验证"
echo "======================"

PROJECT_DIR="/home/qinshu/douyin-analytics"
cd "$PROJECT_DIR"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "\n${BLUE}1. VS Code 配置文件检查${NC}"
echo "------------------------"

# 检查必要的配置文件
CONFIG_FILES=(
    ".vscode/mcp.json"
    ".vscode/settings.json"
    ".vscode/extensions.json"
    ".vscode/tasks.json"
    ".vscode/launch.json"
)

for file in "${CONFIG_FILES[@]}"; do
    echo -n "检查 $file: "
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ 存在${NC}"
        
        # 验证 JSON 格式
        if [[ "$file" == *.json ]]; then
            if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
                echo -e "  ${GREEN}✅ JSON 格式正确${NC}"
            else
                echo -e "  ${RED}❌ JSON 格式错误${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ 缺失${NC}"
    fi
done

echo -e "\n${BLUE}2. MCP 配置验证${NC}"
echo "------------------------"

MCP_CONFIG=".vscode/mcp.json"
if [ -f "$MCP_CONFIG" ]; then
    echo -n "检查 MCP 服务器配置: "
    
    # 检查 PromptX 配置
    if grep -q '"promptx"' "$MCP_CONFIG"; then
        echo -e "${GREEN}✅ PromptX 已配置${NC}"
    else
        echo -e "${RED}❌ PromptX 未配置${NC}"
    fi
    
    # 统计服务器数量
    SERVER_COUNT=$(python3 -c "
import json
with open('$MCP_CONFIG') as f:
    config = json.load(f)
    print(len(config.get('servers', {})))
" 2>/dev/null)
    
    if [ ! -z "$SERVER_COUNT" ]; then
        echo -e "  ${GREEN}✅ 配置了 $SERVER_COUNT 个 MCP 服务器${NC}"
    fi
    
    # 检查输入变量
    INPUT_COUNT=$(python3 -c "
import json
with open('$MCP_CONFIG') as f:
    config = json.load(f)
    print(len(config.get('inputs', [])))
" 2>/dev/null)
    
    if [ ! -z "$INPUT_COUNT" ]; then
        echo -e "  ${GREEN}✅ 配置了 $INPUT_COUNT 个输入变量${NC}"
    fi
fi

echo -e "\n${BLUE}3. VS Code 设置验证${NC}"
echo "------------------------"

SETTINGS_FILE=".vscode/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    echo -n "检查 MCP 启用状态: "
    if grep -q '"chat.mcp.enabled": true' "$SETTINGS_FILE"; then
        echo -e "${GREEN}✅ MCP 支持已启用${NC}"
    else
        echo -e "${RED}❌ MCP 支持未启用${NC}"
    fi
    
    echo -n "检查 MCP 自动发现: "
    if grep -q '"chat.mcp.discovery.enabled": true' "$SETTINGS_FILE"; then
        echo -e "${GREEN}✅ 自动发现已启用${NC}"
    else
        echo -e "${YELLOW}⚠️ 自动发现未启用${NC}"
    fi
    
    echo -n "检查 Copilot 配置: "
    if grep -q '"copilot.enable"' "$SETTINGS_FILE"; then
        echo -e "${GREEN}✅ Copilot 已配置${NC}"
    else
        echo -e "${YELLOW}⚠️ Copilot 未配置${NC}"
    fi
fi

echo -e "\n${BLUE}4. PromptX 依赖检查${NC}"
echo "------------------------"

echo -n "检查 Node.js: "
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ $NODE_VERSION${NC}"
else
    echo -e "${RED}❌ 未安装${NC}"
fi

echo -n "检查 npm: "
if command -v npm >/dev/null 2>&1; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✅ $NPM_VERSION${NC}"
else
    echo -e "${RED}❌ 未安装${NC}"
fi

echo -n "检查 npx: "
if command -v npx >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 可用${NC}"
else
    echo -e "${RED}❌ 不可用${NC}"
fi

echo -n "检查 PromptX: "
if timeout 10 npx -y -f dpml-prompt@snapshot --version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 可用${NC}"
else
    echo -e "${RED}❌ 不可用${NC}"
fi

echo -e "\n${BLUE}5. Python 依赖检查${NC}"
echo "------------------------"

echo -n "检查 Python3: "
if command -v python3 >/dev/null 2>&1; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✅ $PYTHON_VERSION${NC}"
else
    echo -e "${RED}❌ 未安装${NC}"
fi

echo -n "检查 pipx: "
if command -v pipx >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 可用${NC}"
else
    echo -e "${RED}❌ 不可用${NC}"
fi

# 检查 Python MCP 服务器
PYTHON_MCP_SERVERS=(
    "mcp_server_git"
    "mcp_server_time"
    "opencv_mcp_server"
)

for server in "${PYTHON_MCP_SERVERS[@]}"; do
    echo -n "检查 $server: "
    if python3 -c "import $server" 2>/dev/null; then
        echo -e "${GREEN}✅ 可用${NC}"
    else
        echo -e "${RED}❌ 不可用${NC}"
    fi
done

echo -e "\n${BLUE}6. 启动脚本检查${NC}"
echo "------------------------"

SCRIPTS=(
    "scripts/launch_vscode_mcp.sh"
    "scripts/verify_vscode_mcp.sh"
)

for script in "${SCRIPTS[@]}"; do
    echo -n "检查 $script: "
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo -e "${GREEN}✅ 存在且可执行${NC}"
        else
            echo -e "${YELLOW}⚠️ 存在但不可执行${NC}"
        fi
    else
        echo -e "${RED}❌ 不存在${NC}"
    fi
done

echo -e "\n${PURPLE}7. 配置总结${NC}"
echo "------------------------"

echo "📦 VS Code MCP 工具生态系统："
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
echo "  • promptx - AI专业角色增强系统 🎭"

echo -e "\n${YELLOW}💡 使用指南：${NC}"
echo "1. 启动 VS Code: ./scripts/launch_vscode_mcp.sh"
echo "2. 在 VS Code 中打开 Copilot Chat (Ctrl+Alt+I)"
echo "3. 选择 Agent 模式"
echo "4. 点击 Tools 按钮查看所有 MCP 工具"
echo "5. 使用 #promptx 引用 PromptX 工具"
echo "6. 使用 /mcp.promptx.hello 发现角色"
echo "7. 使用 /mcp.promptx.action nuwa 激活女娲角色"

echo -e "\n${GREEN}🎉 VS Code MCP 配置验证完成！${NC}"
