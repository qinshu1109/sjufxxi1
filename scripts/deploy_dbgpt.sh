#!/bin/bash
# DB-GPT 部署脚本
# 自动化部署 DB-GPT AWEL 到 sjufxxi 项目

set -euo pipefail

# ============================================
# 配置变量
# ============================================

PROJECT_ROOT="/home/qinshu/douyin-analytics"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${PROJECT_ROOT}/logs/dbgpt_deploy.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# 函数定义
# ============================================

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $*" | tee -a "$LOG_FILE"
}

check_prerequisites() {
    log "检查部署前置条件..."
    
    # 检查 Podman
    if ! command -v podman &> /dev/null; then
        error "Podman 未安装，请先安装 Podman"
        exit 1
    fi
    
    # 检查 podman-compose
    if ! command -v podman-compose &> /dev/null; then
        warn "podman-compose 未安装，将使用 podman 命令"
    fi
    
    # 检查项目结构
    if [[ ! -f "${PROJECT_ROOT}/podman-compose.yml" ]]; then
        error "podman-compose.yml 不存在"
        exit 1
    fi
    
    if [[ ! -f "${PROJECT_ROOT}/external/dbgpt/Containerfile" ]]; then
        error "DB-GPT Containerfile 不存在"
        exit 1
    fi
    
    # 检查环境变量
    if [[ -z "${DEEPSEEK_API_KEY:-}" ]]; then
        warn "DEEPSEEK_API_KEY 环境变量未设置"
        read -p "请输入 DeepSeek API Key: " DEEPSEEK_API_KEY
        export DEEPSEEK_API_KEY
    fi
    
    log "前置条件检查完成"
}

setup_environment() {
    log "设置部署环境..."
    
    # 创建必要的目录
    mkdir -p "${PROJECT_ROOT}/logs"
    mkdir -p "${PROJECT_ROOT}/data/dbgpt"
    mkdir -p "${PROJECT_ROOT}/data/chroma"
    
    # 设置环境变量文件
    cat > "${PROJECT_ROOT}/.env.dbgpt" << EOF
# DB-GPT 环境变量配置
DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
DBGPT_HOST=0.0.0.0
DBGPT_PORT=5000
DBGPT_WEB_PORT=3000
DBGPT_LOG_LEVEL=INFO

# 数据库配置
LOCAL_DB_TYPE=duckdb
LOCAL_DB_PATH=/app/data/analytics.duckdb
POSTGRES_URL=postgresql://postgres:difyai123456@db:5432/dify

# 向量存储配置
VECTOR_STORE_TYPE=Chroma
CHROMA_PERSIST_PATH=/app/data/chroma

# 安全配置
DBGPT_SECURITY_ENABLE_SQL_WHITELIST=true
DBGPT_SECURITY_MAX_QUERY_TIME=30
EOF
    
    log "环境设置完成"
}

build_dbgpt_image() {
    log "构建 DB-GPT 镜像..."
    
    cd "${PROJECT_ROOT}"
    
    # 构建镜像
    if podman build \
        -f external/dbgpt/Containerfile \
        -t dbgpt:latest \
        --build-arg PYTHON_VERSION=3.11 \
        --build-arg EXTRAS="base,proxy_openai,rag,storage_chromadb,hf,dbgpts" \
        --build-arg VERSION=latest \
        external/dbgpt; then
        log "DB-GPT 镜像构建成功"
    else
        error "DB-GPT 镜像构建失败"
        return 1
    fi
}

start_dependencies() {
    log "启动依赖服务..."
    
    cd "${PROJECT_ROOT}"
    
    # 启动基础服务（如果还没有运行）
    if podman-compose ps | grep -q "Up"; then
        info "检测到已有服务运行"
    else
        info "启动基础服务..."
        podman-compose up -d db redis weaviate
        
        # 等待服务就绪
        log "等待数据库服务就绪..."
        sleep 30
    fi
}

deploy_dbgpt() {
    log "部署 DB-GPT 服务..."
    
    cd "${PROJECT_ROOT}"
    
    # 加载环境变量
    set -a
    source .env.dbgpt
    set +a
    
    # 启动 DB-GPT 服务
    if podman-compose up -d dbgpt; then
        log "DB-GPT 服务启动成功"
    else
        error "DB-GPT 服务启动失败"
        return 1
    fi
    
    # 等待服务就绪
    log "等待 DB-GPT 服务就绪..."
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f http://localhost:5000/health &>/dev/null; then
            log "DB-GPT 服务已就绪"
            break
        fi
        
        info "等待 DB-GPT 服务... (尝试 $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        error "DB-GPT 服务启动超时"
        return 1
    fi
}

run_schema_embedding() {
    log "运行 Schema 嵌入..."
    
    # 检查数据库文件是否存在
    if [[ ! -f "${PROJECT_ROOT}/data/db/analytics.duckdb" ]]; then
        warn "DuckDB 文件不存在，跳过 Schema 嵌入"
        return 0
    fi
    
    # 在容器中运行 Schema 嵌入脚本
    if podman exec -it douyin-analytics-dbgpt-1 python /app/scripts/embed_schema.py; then
        log "Schema 嵌入完成"
    else
        warn "Schema 嵌入失败，但不影响部署"
    fi
}

run_integration_tests() {
    log "运行集成测试..."
    
    cd "${PROJECT_ROOT}"
    
    # 运行基础集成测试
    if python3 scripts/test_integration_basic.py; then
        log "基础集成测试通过"
    else
        warn "基础集成测试失败，请检查配置"
    fi
    
    # 测试 DB-GPT API
    log "测试 DB-GPT API..."
    if curl -f http://localhost:5000/api/v1/health &>/dev/null; then
        log "DB-GPT API 测试通过"
    else
        warn "DB-GPT API 测试失败"
    fi
}

show_deployment_info() {
    log "部署完成！"
    
    echo ""
    echo "=========================================="
    echo "🎉 DB-GPT AWEL 部署成功！"
    echo "=========================================="
    echo ""
    echo "服务访问地址："
    echo "  - DB-GPT Web UI: http://localhost:3000"
    echo "  - DB-GPT API:    http://localhost:5000"
    echo "  - 健康检查:       http://localhost:5000/health"
    echo ""
    echo "配置文件："
    echo "  - 环境变量: ${PROJECT_ROOT}/.env.dbgpt"
    echo "  - 配置文件: ${PROJECT_ROOT}/external/dbgpt/configs/dbgpt-sjufxxi-config.toml"
    echo ""
    echo "日志文件："
    echo "  - 部署日志: ${LOG_FILE}"
    echo "  - 服务日志: podman-compose logs dbgpt"
    echo ""
    echo "常用命令："
    echo "  - 查看状态: podman-compose ps"
    echo "  - 查看日志: podman-compose logs -f dbgpt"
    echo "  - 重启服务: podman-compose restart dbgpt"
    echo "  - 停止服务: podman-compose stop dbgpt"
    echo ""
    echo "下一步："
    echo "  1. 访问 Web UI 测试 NL2SQL 功能"
    echo "  2. 配置前端 /ai 路由集成"
    echo "  3. 设置 Nginx 反向代理"
    echo "  4. 配置监控和告警"
    echo ""
}

cleanup_on_error() {
    error "部署过程中发生错误，正在清理..."
    
    # 停止可能启动的服务
    podman-compose stop dbgpt 2>/dev/null || true
    
    # 显示错误日志
    echo ""
    echo "最近的错误日志："
    tail -20 "$LOG_FILE" 2>/dev/null || true
    
    exit 1
}

# ============================================
# 主执行流程
# ============================================

main() {
    log "开始 DB-GPT AWEL 部署流程"
    
    # 设置错误处理
    trap cleanup_on_error ERR
    
    # 执行部署步骤
    check_prerequisites
    setup_environment
    build_dbgpt_image
    start_dependencies
    deploy_dbgpt
    run_schema_embedding
    run_integration_tests
    show_deployment_info
    
    log "DB-GPT AWEL 部署流程完成"
}

# 检查是否直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
