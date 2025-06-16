#!/bin/bash

# DB-GPT 启动脚本
# 用于启动 DB-GPT 服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DBGPT_DIR="$PROJECT_ROOT/external/dbgpt"

log "开始启动 DB-GPT 服务..."
log "项目根目录: $PROJECT_ROOT"
log "DB-GPT 目录: $DBGPT_DIR"

# 检查 DB-GPT 目录
if [ ! -d "$DBGPT_DIR" ]; then
    error "DB-GPT 目录不存在: $DBGPT_DIR"
    exit 1
fi

# 创建日志目录
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"

# 检查端口是否被占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # 端口被占用
    else
        return 1  # 端口未被占用
    fi
}

# 检查 5000 端口
if check_port 5000; then
    warning "端口 5000 已被占用，尝试停止现有服务..."
    # 尝试杀死占用端口的进程
    lsof -ti:5000 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# 检查 Python 环境
if ! command -v python3 &> /dev/null; then
    error "Python3 未安装"
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
log "Python 版本: $PYTHON_VERSION"

# 检查并创建虚拟环境
VENV_DIR="$PROJECT_ROOT/venv"
if [ ! -d "$VENV_DIR" ]; then
    log "创建虚拟环境..."
    python3 -m venv "$VENV_DIR"
fi

# 激活虚拟环境
log "激活虚拟环境..."
source "$VENV_DIR/bin/activate"

# 安装必要的依赖
log "检查并安装必要的依赖..."
pip install -q --upgrade pip
pip install -q fastapi uvicorn duckdb pydantic python-multipart

# 设置环境变量
export DBGPT_HOST="0.0.0.0"
export DBGPT_PORT="5000"
export PYTHONPATH="$DBGPT_DIR:$PYTHONPATH"

# 启动服务
cd "$PROJECT_ROOT"

# 检查完整版启动脚本是否存在
FULL_APP="$DBGPT_DIR/full_dbgpt_app.py"
SIMPLE_APP="$DBGPT_DIR/start_simple.py"

if [ -f "$FULL_APP" ]; then
    log "使用完整版 DB-GPT 应用启动..."
    APP_TO_RUN="$FULL_APP"
elif [ -f "$SIMPLE_APP" ]; then
    log "使用简化版 DB-GPT 应用启动..."
    APP_TO_RUN="$SIMPLE_APP"
else
    error "找不到 DB-GPT 启动脚本"
    exit 1
fi

# 后台启动服务
LOG_FILE="$LOG_DIR/dbgpt_$(date +%Y%m%d_%H%M%S).log"
log "启动 DB-GPT 服务，日志文件: $LOG_FILE"

nohup python3 "$APP_TO_RUN" > "$LOG_FILE" 2>&1 &
PID=$!

# 保存 PID
echo $PID > "$PROJECT_ROOT/.dbgpt.pid"

# 等待服务启动
log "等待服务启动..."
sleep 5

# 检查服务是否成功启动
if kill -0 $PID 2>/dev/null; then
    if check_port 5000; then
        success "DB-GPT 服务启动成功！"
        success "服务地址: http://localhost:5000"
        success "进程 ID: $PID"
        success "日志文件: $LOG_FILE"
        
        # 显示最后几行日志
        log "最近的日志输出:"
        tail -n 20 "$LOG_FILE"
        
        # 测试服务
        log "测试服务健康状态..."
        if curl -s http://localhost:5000/health > /dev/null 2>&1; then
            success "服务健康检查通过"
            curl -s http://localhost:5000/health | python3 -m json.tool
        else
            warning "健康检查失败，但服务可能仍在启动中"
        fi
    else
        error "服务启动失败，端口 5000 未监听"
        cat "$LOG_FILE"
        exit 1
    fi
else
    error "DB-GPT 服务启动失败"
    cat "$LOG_FILE"
    exit 1
fi

log "创建停止脚本..."
cat > "$SCRIPT_DIR/stop_dbgpt.sh" << 'EOF'
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PID_FILE="$PROJECT_ROOT/.dbgpt.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 $PID 2>/dev/null; then
        echo "停止 DB-GPT 服务 (PID: $PID)..."
        kill $PID
        rm -f "$PID_FILE"
        echo "DB-GPT 服务已停止"
    else
        echo "DB-GPT 服务未运行"
        rm -f "$PID_FILE"
    fi
else
    echo "找不到 PID 文件，尝试通过端口查找进程..."
    lsof -ti:5000 | xargs kill -9 2>/dev/null || echo "没有找到运行的 DB-GPT 服务"
fi
EOF

chmod +x "$SCRIPT_DIR/stop_dbgpt.sh"

log "提示："
log "  - 查看日志: tail -f $LOG_FILE"
log "  - 停止服务: $SCRIPT_DIR/stop_dbgpt.sh"
log "  - 健康检查: curl http://localhost:5000/health"
log "  - API 文档: http://localhost:5000/docs"

exit 0