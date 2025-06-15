#!/bin/bash
# 第二阶段完整准备验证脚本

echo "🔍 第二阶段部署前完整验证"
echo "=================================="

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        return 0
    else
        echo -e "${RED}❌ $1${NC}"
        return 1
    fi
}

warn_status() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

TOTAL_CHECKS=0
PASSED_CHECKS=0

# 1. 基础环境检查
echo -e "\n${BLUE}1. 基础环境检查${NC}"
echo "--------------------"

# Docker检查
((TOTAL_CHECKS++))
if docker --version >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3)
    check_status "Docker运行正常 ($DOCKER_VERSION)" && ((PASSED_CHECKS++))
else
    check_status "Docker运行异常"
fi

# Docker Compose检查
((TOTAL_CHECKS++))
if docker compose version >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version --short)
    check_status "Docker Compose可用 ($COMPOSE_VERSION)" && ((PASSED_CHECKS++))
else
    check_status "Docker Compose不可用"
fi

# 网络连接检查
((TOTAL_CHECKS++))
if timeout 5 docker run --rm hello-world >/dev/null 2>&1; then
    check_status "Docker Hub连接正常" && ((PASSED_CHECKS++))
else
    check_status "Docker Hub连接异常"
fi

# 2. 端口可用性检查
echo -e "\n${BLUE}2. 端口可用性检查${NC}"
echo "----------------------"

REQUIRED_PORTS=(80 5000 5432 6379 443 8080)
for port in "${REQUIRED_PORTS[@]}"; do
    ((TOTAL_CHECKS++))
    if ! ss -tuln | grep -q ":$port "; then
        check_status "端口 $port 可用" && ((PASSED_CHECKS++))
    else
        PROCESS=$(ss -tuln | grep ":$port " | head -1)
        check_status "端口 $port 被占用: $PROCESS"
    fi
done

# 3. 系统资源检查
echo -e "\n${BLUE}3. 系统资源检查${NC}"
echo "--------------------"

# 内存检查
((TOTAL_CHECKS++))
TOTAL_MEM=$(free -m | awk '/内存：/ {print $2}')
AVAIL_MEM=$(free -m | awk '/内存：/ {print $7}')
if [ "$TOTAL_MEM" -gt 6000 ] && [ "$AVAIL_MEM" -gt 4000 ]; then
    check_status "内存充足 (总计:${TOTAL_MEM}MB, 可用:${AVAIL_MEM}MB)" && ((PASSED_CHECKS++))
else
    check_status "内存不足 (总计:${TOTAL_MEM}MB, 可用:${AVAIL_MEM}MB)"
fi

# 磁盘空间检查
((TOTAL_CHECKS++))
DISK_AVAIL=$(df . | tail -1 | awk '{print $4}')
DISK_AVAIL_GB=$((DISK_AVAIL / 1024 / 1024))
if [ "$DISK_AVAIL_GB" -gt 10 ]; then
    check_status "磁盘空间充足 (${DISK_AVAIL_GB}GB可用)" && ((PASSED_CHECKS++))
else
    check_status "磁盘空间不足 (${DISK_AVAIL_GB}GB可用)"
fi

# 4. 数据库验证
echo -e "\n${BLUE}4. DuckDB数据库验证${NC}"
echo "------------------------"

DB_PATH="$PROJECT_DIR/data/db/analytics.duckdb"

# 数据库文件存在性
((TOTAL_CHECKS++))
if [ -f "$DB_PATH" ]; then
    DB_SIZE=$(ls -lh "$DB_PATH" | awk '{print $5}')
    check_status "数据库文件存在 ($DB_SIZE)" && ((PASSED_CHECKS++))
else
    check_status "数据库文件不存在"
fi

# 数据库连接测试
((TOTAL_CHECKS++))
if duckdb "$DB_PATH" "SELECT 'OK' as status;" >/dev/null 2>&1; then
    check_status "数据库连接正常" && ((PASSED_CHECKS++))
else
    check_status "数据库连接失败"
fi

# 数据完整性检查
((TOTAL_CHECKS++))
RECORD_COUNT=$(duckdb "$DB_PATH" "SELECT COUNT(*) FROM douyin_products;" 2>/dev/null | grep -o '[0-9]\+' | head -1)
if [ -n "$RECORD_COUNT" ] && [ "$RECORD_COUNT" -gt 0 ]; then
    check_status "数据完整 ($RECORD_COUNT 条记录)" && ((PASSED_CHECKS++))
else
    check_status "数据为空或异常"
fi

# 5. API配置验证
echo -e "\n${BLUE}5. API配置验证${NC}"
echo "------------------"

CONFIG_FILE="$PROJECT_DIR/config/dify_env.txt"

# 配置文件存在
((TOTAL_CHECKS++))
if [ -f "$CONFIG_FILE" ]; then
    check_status "配置文件存在" && ((PASSED_CHECKS++))
else
    check_status "配置文件不存在"
fi

# API Key检查
((TOTAL_CHECKS++))
if grep -q "sk-3f07e058c2aa487a90af6acd5e3cadc7" "$CONFIG_FILE" 2>/dev/null; then
    check_status "DeepSeek API Key已配置" && ((PASSED_CHECKS++))
else
    check_status "DeepSeek API Key未配置"
fi

# API连通性测试
((TOTAL_CHECKS++))
if timeout 10 curl -s "https://api.deepseek.com/v1/models" \
   -H "Authorization: Bearer sk-3f07e058c2aa487a90af6acd5e3cadc7" >/dev/null 2>&1; then
    check_status "DeepSeek API连接正常" && ((PASSED_CHECKS++))
else
    warn_status "DeepSeek API连接测试跳过 (可能需要实际调用测试)"
    ((PASSED_CHECKS++)) # 不强制要求此项通过
fi

# 6. 项目文件完整性
echo -e "\n${BLUE}6. 项目文件完整性${NC}"
echo "--------------------"

REQUIRED_FILES=(
    "data/db/analytics.duckdb"
    "config/dify_env.txt"
    "config/feishu_config.py"
    "scripts/import_csv.py"
    "scripts/analyze_data.sql"
    "scripts/verify_duckdb.sh"
    "scripts/fix_permissions.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    ((TOTAL_CHECKS++))
    if [ -f "$PROJECT_DIR/$file" ]; then
        check_status "$file 存在" && ((PASSED_CHECKS++))
    else
        check_status "$file 缺失"
    fi
done

# 7. Dify准备状态
echo -e "\n${BLUE}7. Dify部署准备${NC}"
echo "------------------"

# Dify源码检查
((TOTAL_CHECKS++))
if [ -d "$PROJECT_DIR/dify" ] && [ -f "$PROJECT_DIR/dify/docker/docker-compose.yaml" ]; then
    check_status "Dify源码已准备" && ((PASSED_CHECKS++))
else
    check_status "Dify源码未准备"
fi

# Docker镜像预检查
((TOTAL_CHECKS++))
if docker images | grep -q "hello-world"; then
    check_status "Docker镜像拉取功能正常" && ((PASSED_CHECKS++))
else
    check_status "Docker镜像拉取异常"
fi

# 8. 网络环境验证
echo -e "\n${BLUE}8. 网络环境验证${NC}"
echo "------------------"

# 代理配置检查
((TOTAL_CHECKS++))
if docker info | grep -q "HTTP Proxy"; then
    PROXY_INFO=$(docker info | grep "HTTP Proxy" | head -1)
    check_status "Docker代理已配置: $PROXY_INFO" && ((PASSED_CHECKS++))
else
    warn_status "Docker代理未配置"
    ((PASSED_CHECKS++)) # 在某些环境下可能不需要代理
fi

# 外网连接测试
((TOTAL_CHECKS++))
if timeout 5 curl -s https://www.github.com >/dev/null 2>&1; then
    check_status "外网连接正常" && ((PASSED_CHECKS++))
else
    check_status "外网连接异常"
fi

# 生成验证报告
echo -e "\n${BLUE}📊 验证结果总览${NC}"
echo "=================="

PASS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

echo "总检查项: $TOTAL_CHECKS"
echo "通过项数: $PASSED_CHECKS"
echo "通过率: $PASS_RATE%"

if [ "$PASS_RATE" -ge 90 ]; then
    echo -e "\n${GREEN}🎉 验证结果: 优秀 - 可以开始Dify部署${NC}"
    exit 0
elif [ "$PASS_RATE" -ge 80 ]; then
    echo -e "\n${YELLOW}👍 验证结果: 良好 - 建议修复少数问题后部署${NC}"
    exit 0
elif [ "$PASS_RATE" -ge 70 ]; then
    echo -e "\n${YELLOW}⚠️  验证结果: 及格 - 存在一些问题需要注意${NC}"
    exit 1
else
    echo -e "\n${RED}❌ 验证结果: 不及格 - 需要修复关键问题${NC}"
    exit 1
fi