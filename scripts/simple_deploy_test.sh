#!/bin/bash
# 简化的 DB-GPT 部署测试脚本
# 用于验证基础功能，不依赖复杂的镜像构建

set -euo pipefail

PROJECT_ROOT="/home/qinshu/douyin-analytics"
LOG_FILE="${PROJECT_ROOT}/logs/simple_deploy_test.log"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $*" | tee -a "$LOG_FILE"
}

# 创建日志目录
mkdir -p "${PROJECT_ROOT}/logs"

log "开始简化部署测试..."

# 1. 检查基础环境
log "检查基础环境..."
if ! command -v podman &> /dev/null; then
    error "Podman 未安装"
    exit 1
fi

if ! command -v podman-compose &> /dev/null; then
    warn "podman-compose 未安装，将使用 podman 命令"
fi

# 2. 检查项目文件
log "检查项目文件..."
required_files=(
    "podman-compose.yml"
    "external/dbgpt/Containerfile"
    "external/dbgpt/entrypoint.sh"
    "config/model_config.py"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "${PROJECT_ROOT}/${file}" ]]; then
        error "文件不存在: ${file}"
        exit 1
    fi
    log "✓ ${file}"
done

# 3. 启动基础服务（不包括 dbgpt）
log "启动基础服务..."
cd "${PROJECT_ROOT}"

# 启动数据库和向量存储
log "启动 PostgreSQL..."
if podman-compose up -d db; then
    log "PostgreSQL 启动成功"
else
    error "PostgreSQL 启动失败"
    exit 1
fi

sleep 5

log "启动 Redis..."
if podman-compose up -d redis; then
    log "Redis 启动成功"
else
    error "Redis 启动失败"
    exit 1
fi

sleep 5

log "启动 Weaviate..."
if podman-compose up -d weaviate; then
    log "Weaviate 启动成功"
else
    error "Weaviate 启动失败"
    exit 1
fi

# 4. 等待服务就绪
log "等待服务就绪..."
sleep 30

# 5. 检查服务状态
log "检查服务状态..."
podman-compose ps

# 6. 测试服务连接
log "测试服务连接..."

# 测试 PostgreSQL
if podman exec douyin-analytics-db-1 pg_isready -U postgres -d dify; then
    log "✓ PostgreSQL 连接正常"
else
    warn "PostgreSQL 连接测试失败"
fi

# 测试 Redis
if podman exec douyin-analytics-redis-1 redis-cli ping | grep -q PONG; then
    log "✓ Redis 连接正常"
else
    warn "Redis 连接测试失败"
fi

# 测试 Weaviate
if curl -f http://localhost:8080/v1/.well-known/ready &>/dev/null; then
    log "✓ Weaviate 连接正常"
else
    warn "Weaviate 连接测试失败"
fi

# 7. 运行配置验证
log "运行配置验证..."
cd "${PROJECT_ROOT}"
if python3 scripts/test_integration_basic.py; then
    log "✓ 配置验证通过"
else
    warn "配置验证有问题，但不影响基础服务"
fi

# 8. 创建测试数据库
log "创建测试数据库..."
if [[ ! -f "${PROJECT_ROOT}/data/db/analytics.duckdb" ]]; then
    mkdir -p "${PROJECT_ROOT}/data/db"
    
    # 创建一个简单的测试数据库
    python3 -c "
import duckdb
import os

db_path = '${PROJECT_ROOT}/data/db/analytics.duckdb'
conn = duckdb.connect(db_path)

# 创建测试表
conn.execute('''
CREATE TABLE douyin_products (
    id INTEGER PRIMARY KEY,
    product_id VARCHAR,
    title VARCHAR,
    price DECIMAL(10,2),
    sales_volume INTEGER,
    sales_amount DECIMAL(15,2),
    shop_name VARCHAR,
    category VARCHAR,
    brand VARCHAR,
    rating DECIMAL(3,2),
    live_room_title VARCHAR,
    anchor_name VARCHAR,
    created_date DATE,
    updated_date TIMESTAMP
)
''')

# 插入测试数据
test_data = [
    (1, 'P001', '测试商品1', 99.99, 100, 9999.00, '测试店铺1', '电子产品', '测试品牌', 4.5, '直播间1', '主播1', '2025-01-01', '2025-01-01 10:00:00'),
    (2, 'P002', '测试商品2', 199.99, 50, 9999.50, '测试店铺2', '服装', '测试品牌2', 4.2, '直播间2', '主播2', '2025-01-02', '2025-01-02 11:00:00'),
    (3, 'P003', '测试商品3', 299.99, 75, 22499.25, '测试店铺3', '美妆', '测试品牌3', 4.8, '直播间3', '主播3', '2025-01-03', '2025-01-03 12:00:00')
]

for data in test_data:
    conn.execute('INSERT INTO douyin_products VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', data)

conn.close()
print('测试数据库创建完成')
"
    log "✓ 测试数据库创建完成"
else
    log "✓ 测试数据库已存在"
fi

# 9. 显示部署状态
log "部署测试完成！"

echo ""
echo "=========================================="
echo "🎉 基础服务部署测试完成！"
echo "=========================================="
echo ""
echo "运行中的服务："
podman-compose ps
echo ""
echo "服务访问地址："
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis:      localhost:6379"
echo "  - Weaviate:   http://localhost:8080"
echo ""
echo "测试数据："
echo "  - DuckDB:     ${PROJECT_ROOT}/data/db/analytics.duckdb"
echo ""
echo "日志文件："
echo "  - 部署日志:   ${LOG_FILE}"
echo "  - 服务日志:   podman-compose logs [service]"
echo ""
echo "下一步："
echo "  1. 设置 DEEPSEEK_API_KEY 环境变量"
echo "  2. 构建 DB-GPT 镜像"
echo "  3. 启动 DB-GPT 服务"
echo "  4. 测试 NL2SQL 功能"
echo ""
echo "常用命令："
echo "  - 查看状态: podman-compose ps"
echo "  - 查看日志: podman-compose logs -f [service]"
echo "  - 停止服务: podman-compose stop"
echo "  - 清理环境: podman-compose down"
echo ""
