#!/bin/bash

# DB-GPT 构建脚本
# 用于构建 DB-GPT Web 应用并将产物复制到主站

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

# 项目路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$FRONTEND_DIR")"
DBGPT_WEB_DIR="$PROJECT_ROOT/external/dbgpt/web"
OUTPUT_DIR="$FRONTEND_DIR/public/ai"

log "开始构建 DB-GPT Web 应用..."
log "项目根目录: $PROJECT_ROOT"
log "DB-GPT Web 目录: $DBGPT_WEB_DIR"
log "输出目录: $OUTPUT_DIR"

# 检查 DB-GPT Web 目录是否存在
if [ ! -d "$DBGPT_WEB_DIR" ]; then
    error "DB-GPT Web 目录不存在: $DBGPT_WEB_DIR"
    exit 1
fi

# 进入 DB-GPT Web 目录
cd "$DBGPT_WEB_DIR"

# 检查 package.json 是否存在
if [ ! -f "package.json" ]; then
    error "package.json 不存在于 $DBGPT_WEB_DIR"
    exit 1
fi

# 检查 Node.js 和 npm/yarn
if ! command -v node &> /dev/null; then
    error "Node.js 未安装"
    exit 1
fi

NODE_VERSION=$(node --version)
log "Node.js 版本: $NODE_VERSION"

# 优先使用 yarn，如果不存在则使用 npm
if command -v yarn &> /dev/null; then
    PACKAGE_MANAGER="yarn"
    log "使用 yarn 作为包管理器"
else
    PACKAGE_MANAGER="npm"
    log "使用 npm 作为包管理器"
fi

# 备份现有的 .env 文件
ENV_FILE=".env"
ENV_BACKUP=".env.backup.$(date +%s)"

if [ -f "$ENV_FILE" ]; then
    log "备份现有的 .env 文件到 $ENV_BACKUP"
    cp "$ENV_FILE" "$ENV_BACKUP"
fi

# 创建构建用的 .env 文件
log "创建构建用的 .env 文件..."
cat > "$ENV_FILE" << EOF
# DB-GPT Web 构建配置
API_BASE_URL=http://localhost:5000
NEXT_TELEMETRY_DISABLED=1
NODE_ENV=production
APP_ENV=prod

# 集成配置
ENABLE_ANALYTICS_INTEGRATION=true
ENABLE_MAIN_APP_INTEGRATION=true
EOF

# 安装依赖
log "安装依赖..."
if [ "$PACKAGE_MANAGER" = "yarn" ]; then
    yarn install --frozen-lockfile
else
    npm ci
fi

# 清理之前的构建产物
log "清理之前的构建产物..."
rm -rf .next out dist

# 构建应用
log "构建 DB-GPT Web 应用..."
if [ "$PACKAGE_MANAGER" = "yarn" ]; then
    NODE_OPTIONS=--max_old_space_size=8192 yarn build
    NODE_OPTIONS=--max_old_space_size=8192 yarn export
else
    NODE_OPTIONS=--max_old_space_size=8192 npm run build
    NODE_OPTIONS=--max_old_space_size=8192 npm run export
fi

# 检查构建产物
if [ ! -d "out" ]; then
    error "构建失败，out 目录不存在"
    exit 1
fi

# 创建输出目录
log "创建输出目录: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 清理旧的输出
log "清理旧的输出文件..."
rm -rf "$OUTPUT_DIR"/*

# 复制构建产物
log "复制构建产物到主站..."
cp -r out/* "$OUTPUT_DIR/"

# 创建集成配置文件
log "创建集成配置文件..."
cat > "$OUTPUT_DIR/dbgpt-config.json" << EOF
{
  "version": "1.0.0",
  "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "apiBaseUrl": "/api/ai",
  "features": {
    "chat": true,
    "sqlLab": true,
    "visualization": true,
    "workflow": true
  },
  "routes": {
    "chat": "/ai/chat",
    "sqlLab": "/ai/sql-lab",
    "visualization": "/ai/visualization",
    "workflow": "/ai/workflow"
  }
}
EOF

# 创建路由映射文件
log "创建路由映射文件..."
cat > "$OUTPUT_DIR/route-mapping.js" << EOF
// DB-GPT 路由映射配置
window.DBGPT_ROUTE_MAPPING = {
  '/': '/ai/chat',
  '/chat': '/ai/chat',
  '/construct/app': '/ai/sql-lab',
  '/knowledge': '/ai/visualization',
  '/flow': '/ai/workflow'
};

// 自动重定向函数
window.redirectToMainApp = function(path) {
  const mapping = window.DBGPT_ROUTE_MAPPING;
  const targetPath = mapping[path] || '/ai/chat';
  if (window.parent && window.parent !== window) {
    // 在 iframe 中，通知父窗口进行路由跳转
    window.parent.postMessage({
      type: 'DBGPT_ROUTE_CHANGE',
      path: targetPath
    }, '*');
  } else {
    // 直接跳转
    window.location.href = targetPath;
  }
};
EOF

# 修改 HTML 文件以支持集成
log "修改 HTML 文件以支持主站集成..."
find "$OUTPUT_DIR" -name "*.html" -type f | while read -r file; do
    # 在 head 中注入路由映射脚本
    sed -i '/<head>/a\  <script src="/ai/route-mapping.js"></script>' "$file"
    
    # 修改 base href 以支持子路径
    sed -i 's|<head>|<head>\n  <base href="/ai/">|' "$file"
done

# 恢复原始的 .env 文件
if [ -f "$ENV_BACKUP" ]; then
    log "恢复原始的 .env 文件..."
    mv "$ENV_BACKUP" "$ENV_FILE"
else
    log "删除构建用的 .env 文件..."
    rm -f "$ENV_FILE"
fi

# 生成构建报告
BUILD_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
FILE_COUNT=$(find "$OUTPUT_DIR" -type f | wc -l)

log "生成构建报告..."
cat > "$OUTPUT_DIR/build-report.json" << EOF
{
  "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "buildSize": "$BUILD_SIZE",
  "fileCount": $FILE_COUNT,
  "nodeVersion": "$NODE_VERSION",
  "packageManager": "$PACKAGE_MANAGER",
  "sourceDir": "$DBGPT_WEB_DIR",
  "outputDir": "$OUTPUT_DIR"
}
EOF

success "DB-GPT Web 应用构建完成！"
success "构建产物位置: $OUTPUT_DIR"
success "构建大小: $BUILD_SIZE"
success "文件数量: $FILE_COUNT"

log "构建产物结构:"
ls -la "$OUTPUT_DIR"

log "可以通过以下方式访问:"
log "  - 开发环境: http://localhost:5173/ai/"
log "  - 生产环境: 配置 Nginx 代理到 /ai/ 路径"

exit 0
