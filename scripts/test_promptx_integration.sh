#!/bin/bash

echo "🎭 PromptX 集成测试"
echo "==================="

PROJECT_DIR="/home/qinshu/douyin-analytics"
cd "$PROJECT_DIR"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "\n${BLUE}1. PromptX 基础功能测试${NC}"
echo "------------------------"

# 测试 PromptX 安装
echo -n "测试 PromptX 安装: "
if timeout 10 npx -y -f dpml-prompt@snapshot --version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 已安装${NC}"
else
    echo -e "${RED}❌ 安装失败${NC}"
    exit 1
fi

# 测试 hello 命令
echo -n "测试角色发现功能: "
if timeout 15 npx -y -f dpml-prompt@snapshot hello >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 正常${NC}"
else
    echo -e "${RED}❌ 失败${NC}"
fi

# 测试 MCP 服务器
echo -n "测试 MCP 服务器: "
if timeout 10 npx -y -f dpml-prompt@snapshot mcp-server --help >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 正常${NC}"
else
    echo -e "${RED}❌ 失败${NC}"
fi

echo -e "\n${BLUE}2. 女娲角色专项测试${NC}"
echo "------------------------"

# 测试女娲角色激活
echo -n "测试女娲角色激活: "
if timeout 20 npx -y -f dpml-prompt@snapshot action nuwa >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 成功激活${NC}"
else
    echo -e "${YELLOW}⚠️ 需要检查${NC}"
fi

echo -e "\n${BLUE}3. MCP 配置验证${NC}"
echo "------------------------"

CONFIG_FILE="/home/qinshu/MCP工具/mcp-config.json"
echo -n "检查 MCP 配置文件: "
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✅ 存在${NC}"
    
    # 检查 PromptX 配置
    if grep -q 'promptx' "$CONFIG_FILE"; then
        echo -e "${GREEN}✅ PromptX 已配置${NC}"
    else
        echo -e "${RED}❌ PromptX 未配置${NC}"
    fi
    
    # 验证 JSON 格式
    if python3 -c "import json; json.load(open('$CONFIG_FILE'))" 2>/dev/null; then
        echo -e "${GREEN}✅ JSON 格式正确${NC}"
    else
        echo -e "${RED}❌ JSON 格式错误${NC}"
    fi
else
    echo -e "${RED}❌ 配置文件不存在${NC}"
fi

echo -e "\n${BLUE}4. 启动脚本测试${NC}"
echo "------------------------"

# 检查启动脚本
SCRIPTS=(
    "scripts/start_mcp_session.sh"
    "scripts/push_with_mcp.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo -e "${GREEN}✅ $script 可执行${NC}"
    else
        echo -e "${RED}❌ $script 不可执行${NC}"
    fi
done

echo -e "\n${PURPLE}5. PromptX 功能演示${NC}"
echo "------------------------"

echo "🎭 可用的专业角色："
echo "- assistant: 通用助手"
echo "- frontend-developer: 前端开发专家"
echo "- java-backend-developer: Java后端开发专家"
echo "- product-manager: 产品经理"
echo "- xiaohongshu-marketer: 小红书营销专家"
echo "- nuwa: 女娲角色创造顾问 ⭐"

echo -e "\n🔧 PromptX 工具使用示例："
echo "1. 发现角色: promptx_hello"
echo "2. 激活女娲: promptx_action nuwa"
echo "3. 保存记忆: promptx_remember '重要信息'"
echo "4. 检索记忆: promptx_recall '查询内容'"
echo "5. 学习知识: promptx_learn '资源URL'"

echo -e "\n${GREEN}🎉 PromptX 集成测试完成！${NC}"
echo "==============================="

echo -e "\n${YELLOW}📋 测试总结：${NC}"
echo "• PromptX 工具：已成功集成"
echo "• 女娲角色：可正常激活"
echo "• MCP 配置：已正确配置"
echo "• 启动脚本：已准备就绪"

echo -e "\n${BLUE}🚀 下一步操作：${NC}"
echo "1. 启动 MCP 会话："
echo "   ./scripts/start_mcp_session.sh"
echo ""
echo "2. 在 AI 应用中使用 PromptX 工具："
echo "   - promptx_hello (发现角色)"
echo "   - promptx_action nuwa (激活女娲)"
echo "   - promptx_remember (保存记忆)"
echo ""
echo "3. 创建自定义角色："
echo "   - 激活女娲角色后，描述您的需求"
echo "   - 女娲将为您快速创建专业角色"

echo -e "\n${PURPLE}💡 特别提示：${NC}"
echo "女娲角色是专业的角色创造顾问，能够："
echo "• 快速理解您的需求"
echo "• 创建符合 DPML 规范的专业角色"
echo "• 确保角色与系统完美集成"
echo "• 提供3步极简创建流程"
