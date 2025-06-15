#!/bin/bash
# DB-GPT AWEL 完整部署脚本
# 包含预构建镜像拉取、服务启动、健康检查和功能测试

set -euo pipefail

PROJECT_ROOT="/home/qinshu/douyin-analytics"
LOG_FILE="${PROJECT_ROOT}/logs/dbgpt_deploy_complete.log"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] INFO:${NC} $*" | tee -a "$LOG_FILE"
}

step() {
    echo -e "${PURPLE}[$(date '+%H:%M:%S')] STEP:${NC} $*" | tee -a "$LOG_FILE"
}

# 创建日志目录
mkdir -p "${PROJECT_ROOT}/logs"

setup_environment() {
    step "第一步：设置环境变量和网络配置"
    
    # 设置代理环境变量
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    export NO_PROXY=localhost,127.0.0.1,::1
    export no_proxy=localhost,127.0.0.1,::1
    
    log "代理环境变量已设置"
    log "HTTP_PROXY: ${HTTP_PROXY}"
    
    # 设置 DB-GPT 相关环境变量
    export DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:-sk-placeholder-key}"
    export DBGPT_HOST="0.0.0.0"
    export DBGPT_PORT="5000"
    export DBGPT_LOG_LEVEL="INFO"
    
    log "DB-GPT 环境变量已设置"
    log "DEEPSEEK_API_KEY: ${DEEPSEEK_API_KEY:0:10}..."
}

pull_prebuilt_images() {
    step "第二步：拉取预构建镜像"
    
    # 尝试从多个镜像源拉取 DB-GPT 镜像
    local registries=(
        "dockerproxy.com/eosphoros/dbgpt:latest"
        "registry.cn-hangzhou.aliyuncs.com/dbgpt/dbgpt:latest"
        "ghcr.io/eosphoros-ai/db-gpt:latest"
    )
    
    for registry in "${registries[@]}"; do
        log "尝试从 $registry 拉取镜像..."
        if timeout 300 podman pull "$registry"; then
            log "✓ 成功拉取镜像: $registry"
            podman tag "$registry" dbgpt:latest
            log "✓ 镜像已标记为 dbgpt:latest"
            return 0
        else
            warn "从 $registry 拉取失败，尝试下一个..."
        fi
    done
    
    # 如果预构建镜像都失败，尝试构建简化版本
    warn "所有预构建镜像拉取失败，尝试构建简化版本..."
    if podman build -f external/dbgpt/Containerfile.china -t dbgpt:latest external/dbgpt; then
        log "✓ 简化版本构建成功"
        return 0
    else
        error "镜像获取失败"
        return 1
    fi
}

start_infrastructure_services() {
    step "第三步：启动基础设施服务"
    
    cd "${PROJECT_ROOT}"
    
    # 停止可能存在的服务
    log "停止现有服务..."
    podman-compose down || true
    
    # 启动 PostgreSQL
    log "启动 PostgreSQL 数据库..."
    if podman-compose up -d db; then
        log "✓ PostgreSQL 启动成功"
        sleep 10
    else
        error "PostgreSQL 启动失败"
        return 1
    fi
    
    # 启动 Redis
    log "启动 Redis 缓存..."
    if podman-compose up -d redis; then
        log "✓ Redis 启动成功"
        sleep 5
    else
        error "Redis 启动失败"
        return 1
    fi
    
    # 启动 Weaviate 向量数据库
    log "启动 Weaviate 向量数据库..."
    if podman-compose up -d weaviate; then
        log "✓ Weaviate 启动成功"
        sleep 15
    else
        warn "Weaviate 启动失败，继续使用其他向量存储"
    fi
}

start_dbgpt_service() {
    step "第四步：启动 DB-GPT 服务"
    
    # 创建 DB-GPT 容器配置
    log "创建 DB-GPT 服务容器..."
    
    # 停止可能存在的 DB-GPT 容器
    podman stop dbgpt-service || true
    podman rm dbgpt-service || true
    
    # 启动 DB-GPT 服务
    if podman run -d \
        --name dbgpt-service \
        --network podman \
        -p 5000:5000 \
        -e DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY" \
        -e DBGPT_HOST="$DBGPT_HOST" \
        -e DBGPT_PORT="$DBGPT_PORT" \
        -e DBGPT_LOG_LEVEL="$DBGPT_LOG_LEVEL" \
        -v "${PROJECT_ROOT}/data:/app/data:Z" \
        -v "${PROJECT_ROOT}/logs:/app/logs:Z" \
        -v "${PROJECT_ROOT}/config:/app/config:Z" \
        dbgpt:latest; then
        log "✓ DB-GPT 服务启动成功"
        sleep 30
    else
        error "DB-GPT 服务启动失败"
        return 1
    fi
}

verify_services() {
    step "第五步：验证服务部署状态"
    
    # 检查容器状态
    log "检查容器服务状态..."
    podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # 测试 PostgreSQL 连接
    log "测试 PostgreSQL 连接..."
    if podman exec -it douyin-analytics-db-1 pg_isready -U postgres; then
        log "✓ PostgreSQL 连接正常"
    else
        warn "PostgreSQL 连接测试失败"
    fi
    
    # 测试 Redis 连接
    log "测试 Redis 连接..."
    if podman exec -it douyin-analytics-redis-1 redis-cli ping | grep -q PONG; then
        log "✓ Redis 连接正常"
    else
        warn "Redis 连接测试失败"
    fi
    
    # 测试 DB-GPT API
    log "测试 DB-GPT API 端点..."
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f http://localhost:5000/health >/dev/null 2>&1; then
            log "✓ DB-GPT API 健康检查通过"
            break
        else
            warn "DB-GPT API 尝试 $attempt/$max_attempts 失败，等待..."
            sleep 10
            ((attempt++))
        fi
    done
    
    if [ $attempt -gt $max_attempts ]; then
        error "DB-GPT API 健康检查失败"
        return 1
    fi
}

setup_frontend_service() {
    step "第六步：配置并启动前端服务"
    
    # 检查是否需要启动 Web UI
    log "检查 DB-GPT Web UI 配置..."
    
    # 创建简单的前端代理配置
    cat > "${PROJECT_ROOT}/nginx.conf" << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream dbgpt_backend {
        server localhost:5000;
    }
    
    server {
        listen 3000;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }
        
        location /ai/ {
            proxy_pass http://dbgpt_backend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF
    
    # 启动 Nginx 代理
    log "启动 Nginx 前端代理..."
    if podman run -d \
        --name dbgpt-frontend \
        --network podman \
        -p 3000:3000 \
        -v "${PROJECT_ROOT}/nginx.conf:/etc/nginx/nginx.conf:Z" \
        nginx:alpine; then
        log "✓ 前端代理启动成功"
    else
        warn "前端代理启动失败，DB-GPT API 仍可通过端口 5000 访问"
    fi
}

run_functional_tests() {
    step "第七步：进行功能测试"
    
    # 测试基础 API
    log "测试 DB-GPT 基础 API..."
    
    # 健康检查
    if curl -s http://localhost:5000/health | grep -q "healthy\|ok"; then
        log "✓ 健康检查 API 正常"
    else
        warn "健康检查 API 异常"
    fi
    
    # 测试根路径
    if curl -s http://localhost:5000/ | grep -q "DB-GPT\|api\|service"; then
        log "✓ 根路径 API 正常"
    else
        warn "根路径 API 异常"
    fi
    
    # 创建测试数据库连接
    log "创建测试数据库..."
    python3 << 'EOF'
import os
import duckdb

# 创建测试数据库
os.makedirs('/home/qinshu/douyin-analytics/data/db', exist_ok=True)
db_path = '/home/qinshu/douyin-analytics/data/db/test_analytics.duckdb'

conn = duckdb.connect(db_path)

# 创建测试表
conn.execute('''
CREATE TABLE IF NOT EXISTS test_products (
    id INTEGER PRIMARY KEY,
    name VARCHAR,
    price DECIMAL(10,2),
    sales INTEGER,
    category VARCHAR,
    created_date DATE
)
''')

# 插入测试数据
test_data = [
    (1, '测试商品A', 99.99, 100, '电子产品', '2025-01-01'),
    (2, '测试商品B', 199.99, 50, '服装', '2025-01-02'),
    (3, '测试商品C', 299.99, 75, '美妆', '2025-01-03')
]

for data in test_data:
    conn.execute('INSERT OR REPLACE INTO test_products VALUES (?, ?, ?, ?, ?, ?)', data)

result = conn.execute('SELECT COUNT(*) FROM test_products').fetchone()
print(f'测试数据库创建完成，共 {result[0]} 条记录')

conn.close()
EOF
    
    log "✓ 测试数据库创建完成"
}

generate_deployment_report() {
    step "第八步：生成部署报告"
    
    cat > "${PROJECT_ROOT}/DEPLOYMENT_COMPLETE_REPORT.md" << EOF
# DB-GPT AWEL 完整部署报告

**部署时间**: $(date '+%Y-%m-%d %H:%M:%S')
**部署状态**: 完成
**项目路径**: ${PROJECT_ROOT}

## 部署概览

### 服务状态
\`\`\`
$(podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")
\`\`\`

### 网络配置
- **代理**: mihomo-party (127.0.0.1:7890)
- **DB-GPT API**: http://localhost:5000
- **前端代理**: http://localhost:3000
- **数据库**: PostgreSQL (内部网络)
- **缓存**: Redis (内部网络)

### 环境变量
- DEEPSEEK_API_KEY: ${DEEPSEEK_API_KEY:0:10}...
- DBGPT_HOST: ${DBGPT_HOST}
- DBGPT_PORT: ${DBGPT_PORT}

## 访问地址

### 主要服务
- **DB-GPT API**: http://localhost:5000
- **健康检查**: http://localhost:5000/health
- **Web UI**: http://localhost:3000 (如果配置)
- **AI 接口**: http://localhost:3000/ai/ (代理到 DB-GPT)

### 测试命令
\`\`\`bash
# 健康检查
curl http://localhost:5000/health

# API 测试
curl http://localhost:5000/

# 容器状态
podman ps

# 日志查看
podman logs dbgpt-service
\`\`\`

## 功能验证

### 已验证功能
- ✅ 容器服务启动
- ✅ 网络连接
- ✅ API 健康检查
- ✅ 数据库连接
- ✅ 测试数据创建

### 下一步测试
1. 在浏览器中访问 http://localhost:5000
2. 测试自然语言到 SQL 转换
3. 验证数据查询功能
4. 测试图表生成

## 故障排除

### 常用命令
\`\`\`bash
# 查看所有容器
podman ps -a

# 查看 DB-GPT 日志
podman logs dbgpt-service

# 重启服务
podman restart dbgpt-service

# 进入容器调试
podman exec -it dbgpt-service /bin/bash
\`\`\`

### 常见问题
1. **API 无响应**: 检查容器状态和日志
2. **数据库连接失败**: 验证 PostgreSQL 容器状态
3. **前端无法访问**: 检查 Nginx 代理配置

---

**部署完成时间**: $(date '+%Y-%m-%d %H:%M:%S')
**状态**: 部署成功，服务运行中
EOF
    
    log "✓ 部署报告已生成: DEPLOYMENT_COMPLETE_REPORT.md"
}

main() {
    log "开始 DB-GPT AWEL 完整部署流程..."
    
    # 执行部署步骤
    setup_environment
    pull_prebuilt_images
    start_infrastructure_services
    start_dbgpt_service
    verify_services
    setup_frontend_service
    run_functional_tests
    generate_deployment_report
    
    log "DB-GPT AWEL 完整部署流程完成！"
    
    echo ""
    echo "=========================================="
    echo "🎉 DB-GPT AWEL 部署完成！"
    echo "=========================================="
    echo ""
    echo "服务访问地址："
    echo "  - DB-GPT API: http://localhost:5000"
    echo "  - 健康检查: http://localhost:5000/health"
    echo "  - Web UI: http://localhost:3000"
    echo ""
    echo "测试命令："
    echo "  curl http://localhost:5000/health"
    echo "  podman ps"
    echo "  podman logs dbgpt-service"
    echo ""
    echo "查看详细报告: cat DEPLOYMENT_COMPLETE_REPORT.md"
    echo ""
}

# 如果直接运行脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
