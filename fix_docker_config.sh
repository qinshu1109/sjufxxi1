#!/bin/bash
# Docker配置修复脚本

set -e

# 加载环境配置
source "$(dirname "$0")/load_env.sh"

echo "🐳 修复Docker配置问题..."

cd "$DIFY_DIR/docker"

# 1. 创建 .env 文件（如果不存在）
if [ ! -f ".env" ]; then
    echo "📝 创建 Docker .env 文件..."
    cp .env.example .env
fi

# 2. 创建中间件环境配置
if [ ! -f "middleware.env" ]; then
    echo "📝 创建中间件环境配置..."
    cp middleware.env.example middleware.env
fi

# 3. 修复环境变量配置
echo "🔧 修复环境变量配置..."

# 在 .env 文件中添加项目特定配置
cat >> .env << EOF

# 抖音数据分析项目配置
PROJECT_NAME=douyin-analytics
DIFY_VERSION=latest

# 飞书机器人配置
FEISHU_WEBHOOK_URL=${FEISHU_WEBHOOK:-}

# DuckDB配置
DUCKDB_PATH=/app/data/db/analytics.duckdb
DUCKDB_HOST_PATH=${PROJECT_DIR}/data/db/analytics.duckdb

# 端口配置（避免冲突）
WEB_PORT=${WEB_PORT:-80}
API_PORT=${API_PORT:-5000}
EXPOSE_NGINX_PORT=${WEB_PORT:-80}
EXPOSE_API_PORT=${API_PORT:-5000}

# 安全配置
SECRET_KEY=${SECRET_KEY}
EOF

# 4. 修复 docker-compose.yaml 中的端口映射和环境变量
echo "🔧 修复 docker-compose 配置..."

# 备份原始文件
if [ ! -f "docker-compose.yaml.backup" ]; then
    cp docker-compose.yaml docker-compose.yaml.backup
fi

# 检查是否需要修复端口映射
if grep -q "80:80" docker-compose.yaml; then
    echo "📝 更新端口映射配置..."
    sed -i 's/80:80/${EXPOSE_NGINX_PORT:-80}:80/g' docker-compose.yaml
    sed -i 's/5001:5001/${EXPOSE_API_PORT:-5000}:5001/g' docker-compose.yaml
fi

# 5. 确保数据目录存在
echo "📁 创建必要的目录..."
mkdir -p "$PROJECT_DIR/data/db"
mkdir -p "./volumes/db/data"
mkdir -p "./volumes/redis/data"
mkdir -p "./volumes/app/storage"

# 6. 修复权限问题
echo "🔐 修复权限问题..."
sudo chown -R $USER:$USER ./volumes/ 2>/dev/null || true

# 7. 验证配置
echo "✅ 验证Docker配置..."

# 检查docker compose是否可用
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Docker Compose未安装"
    exit 1
fi

echo "📋 Docker配置验证完成"
echo "🔧 Docker Compose命令: $COMPOSE_CMD"
echo "📁 数据卷目录: $(pwd)/volumes/"
echo "📊 数据库挂载: $PROJECT_DIR/data/db -> /app/data/db"

echo ""
echo "✅ Docker配置修复完成！"
echo "💡 下一步: 运行 'cd $DIFY_DIR/docker && $COMPOSE_CMD up -d' 启动服务"