#!/bin/bash

# 前端测试验证脚本
echo "🚀 开始前端测试验证..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查函数
check_step() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 通过${NC}"
    else
        echo -e "${RED}❌ $1 失败${NC}"
        exit 1
    fi
}

echo "📦 检查依赖安装..."
npm list --depth=0 > /dev/null 2>&1
check_step "依赖检查"

echo "🔍 运行 ESLint 检查..."
npm run lint
check_step "ESLint"

echo "🔧 运行 TypeScript 类型检查..."
npm run type-check
check_step "TypeScript 类型检查"

echo "💅 检查代码格式..."
npm run format:check
check_step "Prettier 格式检查"

echo "🧪 运行单元测试..."
npm test -- --run
check_step "单元测试"

echo "📊 生成测试覆盖率报告..."
npm run test:coverage > /dev/null 2>&1
check_step "测试覆盖率"

echo "🏗️ 验证构建..."
npm run build > /dev/null 2>&1
check_step "构建验证"

echo ""
echo -e "${GREEN}🎉 所有测试验证通过！${NC}"
echo ""
echo "📋 测试总结："
echo "   ✅ ESLint 代码规范检查"
echo "   ✅ TypeScript 类型检查"
echo "   ✅ Prettier 代码格式检查"
echo "   ✅ Vitest 单元测试"
echo "   ✅ 测试覆盖率报告"
echo "   ✅ 生产构建验证"
echo ""
echo "🔧 可用命令："
echo "   npm run lint           - ESLint 检查"
echo "   npm run type-check     - 类型检查"
echo "   npm run format         - 代码格式化"
echo "   npm test               - 单元测试"
echo "   npm run test:coverage  - 覆盖率报告"
echo "   npm run e2e            - E2E 测试"
echo "   npm run build          - 构建"
echo ""
echo -e "${YELLOW}📖 查看详细报告: TEST_SETUP_REPORT.md${NC}"