#!/bin/bash

echo "🔍 验证MCP工具生态系统（包含PromptX）"
echo "========================================"

PROJECT_DIR="/home/qinshu/douyin-analytics"
cd "$PROJECT_DIR"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_tool() {
    local tool_name="$1"
    local command="$2"
    echo -n "检查 $tool_name: "
    
    if timeout 10 $command >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 可用${NC}"
        return 0
    else
        echo -e "${RED}❌ 不可用${NC}"
        return 1
    fi
}

echo -e "\n${BLUE}1. 基础MCP工具验证${NC}"
echo "------------------------"

# 文件系统工具
check_tool "fs (文件系统)" "npx -y @modelcontextprotocol/server-filesystem --help"

# GitHub工具
check_tool "github (GitHub管理)" "npx -y @modelcontextprotocol/server-github --help"

# Git工具
check_tool "git (版本控制)" "python3 -c 'import mcp_server_git'"

# HTTP请求工具
check_tool "fetch (HTTP请求)" "pipx run mcp-server-fetch --help"

# 内存存储工具
check_tool "memory (内存存储)" "npx -y @modelcontextprotocol/server-memory --help"

echo -e "\n${BLUE}2. 高级功能工具验证${NC}"
echo "------------------------"

# 截图工具
check_tool "screenshot (截图)" "npx -y screenshot_mcp_server --help"

# OCR工具
check_tool "ocr (文字识别)" "npx -y @kazuph/mcp-screenshot --help"

# GUI自动化工具
check_tool "autogui (GUI自动化)" "pipx run screen-pilot-mcp --help"

# 时间管理工具
check_tool "time (时间管理)" "python3 -c 'import mcp_server_time'"

# 计算机视觉工具
check_tool "vision (计算机视觉)" "python3 -c 'import opencv_mcp_server'"

echo -e "\n${BLUE}3. PromptX AI专业角色增强系统验证${NC}"
echo "----------------------------------------"

# PromptX工具
check_tool "promptx (AI角色增强)" "npx -y -f dpml-prompt@snapshot --help"

# PromptX MCP服务器
echo -n "检查 PromptX MCP服务器: "
if timeout 5 npx -y -f dpml-prompt@snapshot mcp-server --help >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 可用${NC}"
else
    echo -e "${RED}❌ 不可用${NC}"
fi

echo -e "\n${BLUE}4. MCP配置文件验证${NC}"
echo "------------------------"

CONFIG_FILE="/home/qinshu/MCP工具/mcp-config.json"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✅ MCP配置文件存在${NC}: $CONFIG_FILE"
    
    # 验证JSON格式
    if python3 -c "import json; json.load(open('$CONFIG_FILE'))" 2>/dev/null; then
        echo -e "${GREEN}✅ JSON格式正确${NC}"
        
        # 检查PromptX配置
        if grep -q '"promptx"' "$CONFIG_FILE"; then
            echo -e "${GREEN}✅ PromptX已配置${NC}"
        else
            echo -e "${RED}❌ PromptX未配置${NC}"
        fi
    else
        echo -e "${RED}❌ JSON格式错误${NC}"
    fi
else
    echo -e "${RED}❌ MCP配置文件不存在${NC}"
fi

echo -e "\n${BLUE}5. PromptX功能测试${NC}"
echo "------------------------"

echo "测试PromptX基础功能..."

# 测试hello命令
echo -n "测试 promptx hello: "
if timeout 10 npx -y -f dpml-prompt@snapshot hello >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 成功${NC}"
else
    echo -e "${YELLOW}⚠️ 需要进一步配置${NC}"
fi

# 测试init命令
echo -n "测试 promptx init: "
if timeout 10 npx -y -f dpml-prompt@snapshot init >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 成功${NC}"
else
    echo -e "${YELLOW}⚠️ 需要进一步配置${NC}"
fi

echo -e "\n${BLUE}6. 启动脚本验证${NC}"
echo "------------------------"

SCRIPTS=(
    "scripts/start_mcp_session.sh"
    "scripts/push_with_mcp.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo -e "${GREEN}✅ $script 可执行${NC}"
    else
        echo -e "${RED}❌ $script 不可执行${NC}"
        chmod +x "$script" 2>/dev/null && echo -e "${YELLOW}   已修复权限${NC}"
    fi
done

echo -e "\n${GREEN}🎉 MCP工具生态系统验证完成！${NC}"
echo "========================================"
echo -e "${BLUE}总结：${NC}"
echo "• 基础MCP工具：10个"
echo "• PromptX增强系统：1个"
echo "• 总计：11个MCP工具"
echo ""
echo -e "${YELLOW}下一步：${NC}"
echo "1. 运行 ./scripts/start_mcp_session.sh 启动增强的MCP会话"
echo "2. 在AI应用中使用 promptx_hello 发现可用角色"
echo "3. 使用 promptx_action 激活专业角色"
echo "4. 使用 promptx_remember 保存重要信息"
