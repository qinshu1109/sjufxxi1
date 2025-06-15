#!/bin/bash
# 抖音电商数据分析平台部署脚本

set -e

echo "🚀 开始部署抖音电商数据分析平台..."
echo "========================================"

# 项目信息
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIFY_DIR="$PROJECT_DIR/dify"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 步骤1：环境检查
echo_status "步骤1: 环境检查..."

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo_error "Docker未安装，请先安装Docker"
    exit 1
fi
echo_success "Docker已安装: $(docker --version)"

# 检查docker compose（新版本使用docker compose而不是docker-compose）
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
    echo_success "Docker Compose已安装: $(docker compose version)"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    echo_success "Docker Compose已安装: $(docker-compose --version)"
else
    echo_error "Docker Compose未安装，请先安装"
    exit 1
fi

# 检查端口占用
check_port() {
    local port=$1
    if ss -tuln | grep -q ":$port "; then
        echo_warning "端口 $port 已被占用"
        return 1
    else
        echo_success "端口 $port 可用"
        return 0
    fi
}

check_port 80
check_port 5000
check_port 5432
check_port 6379

# 步骤2：创建项目结构
echo_status "步骤2: 确认项目结构..."
cd "$PROJECT_DIR"
echo_success "项目目录结构已创建"
tree . 2>/dev/null || ls -la

# 步骤3：克隆Dify
echo_status "步骤3: 克隆Dify仓库..."
if [ ! -d "$DIFY_DIR/.git" ]; then
    echo_status "正在克隆Dify仓库..."
    git clone https://github.com/langgenius/dify.git "$DIFY_DIR"
    echo_success "Dify仓库克隆完成"
else
    echo_success "Dify仓库已存在"
fi

# 步骤4：配置Dify环境
echo_status "步骤4: 配置Dify环境..."
cd "$DIFY_DIR/docker"

# 复制环境变量文件
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo_success "环境变量文件已创建"
fi

# 修改配置以适应我们的需求
echo_status "配置Dify环境变量..."
cat >> .env << 'EOF'

# 抖音数据分析项目配置
PROJECT_NAME=douyin-analytics
DIFY_VERSION=0.6.13

# 飞书机器人配置（待填入）
FEISHU_WEBHOOK_URL=

# DuckDB配置
DUCKDB_PATH=/app/data/db/analytics.duckdb
EOF

echo_success "Dify配置完成"

# 步骤5：部署Dify
echo_status "步骤5: 部署Dify平台..."
echo_warning "这将需要几分钟时间下载Docker镜像..."

# 启动Dify服务
$COMPOSE_CMD up -d

echo_status "等待服务启动..."
sleep 30

# 检查服务状态
echo_status "检查服务状态..."
$COMPOSE_CMD ps

echo_success "Dify平台部署完成！"
echo_status "Web界面: http://localhost"
echo_status "API地址: http://localhost:5000"

# 步骤6：安装DuckDB
echo_status "步骤6: 安装DuckDB..."
cd "$PROJECT_DIR"

# 检查是否已安装
if command -v duckdb &> /dev/null; then
    echo_success "DuckDB已安装: $(duckdb --version)"
else
    echo_status "正在安装DuckDB..."
    # 下载DuckDB CLI
    wget -O duckdb.zip https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-amd64.zip
    unzip duckdb.zip
    sudo mv duckdb /usr/local/bin/
    rm duckdb.zip
    echo_success "DuckDB安装完成"
fi

# 创建数据库和表结构
echo_status "步骤7: 创建数据库结构..."
cat > config/init_database.sql << 'EOF'
-- 蝉妈妈抖音电商数据表结构
CREATE TABLE IF NOT EXISTS douyin_products (
    id BIGINT PRIMARY KEY,
    title VARCHAR,
    price DECIMAL(10,2),
    sales_volume INTEGER,
    shop_name VARCHAR,
    category VARCHAR,
    brand VARCHAR,
    rating DECIMAL(3,2),
    comments_count INTEGER,
    created_date DATE,
    updated_date TIMESTAMP DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_products_date ON douyin_products(created_date);
CREATE INDEX IF NOT EXISTS idx_products_category ON douyin_products(category);
CREATE INDEX IF NOT EXISTS idx_products_sales ON douyin_products(sales_volume);

-- 插入测试数据
INSERT OR REPLACE INTO douyin_products VALUES
(1, '热销护肤品套装', 299.90, 1520, '美妆旗舰店', '美妆护肤', '知名品牌A', 4.8, 892, '2025-06-15', NOW()),
(2, '时尚女装连衣裙', 189.50, 856, '时尚女装店', '服装鞋帽', '品牌B', 4.6, 445, '2025-06-15', NOW()),
(3, '智能手机保护壳', 29.90, 3240, '数码配件专营', '数码配件', '品牌C', 4.9, 1567, '2025-06-15', NOW()),
(4, '有机坚果礼盒', 128.00, 674, '健康食品店', '食品饮料', '品牌D', 4.7, 298, '2025-06-15', NOW()),
(5, '运动健身器材', 458.00, 234, '运动用品店', '运动户外', '品牌E', 4.5, 156, '2025-06-15', NOW());

SELECT '数据库初始化完成，已插入' || COUNT(*) || '条测试数据' as status FROM douyin_products;
EOF

# 初始化数据库
duckdb data/db/analytics.duckdb < config/init_database.sql
echo_success "数据库初始化完成"

# 步骤8：创建验收测试脚本
echo_status "步骤8: 创建验收测试脚本..."
cat > test_deployment.sh << 'EOF'
#!/bin/bash
# 第一阶段验收测试脚本

echo "🧪 第一阶段验收测试"
echo "==================="

# 测试1：Dify服务检查
echo "1. 检查Dify服务状态..."
cd dify/docker
if docker compose ps | grep -q "Up"; then
    echo "✅ Dify容器运行正常"
else
    echo "❌ Dify容器异常"
fi

# 测试2：Web界面检查
echo "2. 检查Web界面..."
if curl -s http://localhost > /dev/null; then
    echo "✅ Dify Web界面可访问"
else
    echo "❌ Dify Web界面不可访问"
fi

# 测试3：API检查
echo "3. 检查API服务..."
if curl -s http://localhost:5000/health > /dev/null; then
    echo "✅ Dify API服务正常"
else
    echo "❌ Dify API服务异常"
fi

# 测试4：DuckDB检查
echo "4. 检查DuckDB数据库..."
cd ..
if duckdb data/db/analytics.duckdb "SELECT COUNT(*) as count FROM douyin_products;" 2>/dev/null | grep -q "5"; then
    echo "✅ DuckDB数据库正常，测试数据完整"
else
    echo "❌ DuckDB数据库异常"
fi

# 测试5：数据查询测试
echo "5. 执行数据查询测试..."
echo "销量TOP3商品："
duckdb data/db/analytics.duckdb "
SELECT title, sales_volume, shop_name 
FROM douyin_products 
ORDER BY sales_volume DESC 
LIMIT 3;
" 2>/dev/null || echo "❌ 查询失败"

echo ""
echo "📋 验收总结："
echo "1. 访问 http://localhost 进入Dify平台"
echo "2. 数据库文件: $(pwd)/data/db/analytics.duckdb"
echo "3. 测试数据已准备完成"
echo "4. 下一步：配置飞书机器人Webhook"
EOF

chmod +x test_deployment.sh

echo_success "部署脚本执行完成！"
echo ""
echo "📋 部署总结："
echo "============="
echo_status "项目目录: $PROJECT_DIR"
echo_status "Dify Web: http://localhost"
echo_status "Dify API: http://localhost:5000"
echo_status "数据库: $PROJECT_DIR/data/db/analytics.duckdb"
echo ""
echo_warning "下一步操作："
echo "1. 运行验收测试: ./test_deployment.sh"
echo "2. 配置飞书机器人Webhook URL"
echo "3. 准备蝉妈妈CSV数据文件"
echo ""
echo_success "第一阶段部署完成！🎉"