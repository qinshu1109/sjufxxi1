#!/bin/bash

# 测试构建脚本
# 用于验证 DB-GPT 构建和主站构建是否正常

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

log "开始测试构建流程..."
log "前端目录: $FRONTEND_DIR"

cd "$FRONTEND_DIR"

# 检查必要文件
log "检查必要文件..."
REQUIRED_FILES=(
    "package.json"
    "vite.config.ts"
    "tsconfig.json"
    "tailwind.config.js"
    "src/main.tsx"
    "src/App.tsx"
    "scripts/build-dbgpt.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        error "必要文件不存在: $file"
        exit 1
    fi
done

success "所有必要文件检查通过"

# 检查 Node.js 环境
log "检查 Node.js 环境..."
if ! command -v node &> /dev/null; then
    error "Node.js 未安装"
    exit 1
fi

NODE_VERSION=$(node --version)
log "Node.js 版本: $NODE_VERSION"

# 检查包管理器
if command -v yarn &> /dev/null; then
    PACKAGE_MANAGER="yarn"
    log "使用 yarn 作为包管理器"
else
    PACKAGE_MANAGER="npm"
    log "使用 npm 作为包管理器"
fi

# 安装依赖（如果需要）
if [ ! -d "node_modules" ]; then
    log "安装前端依赖..."
    if [ "$PACKAGE_MANAGER" = "yarn" ]; then
        yarn install
    else
        npm install
    fi
else
    log "依赖已安装，跳过安装步骤"
fi

# 类型检查
log "执行 TypeScript 类型检查..."
if [ "$PACKAGE_MANAGER" = "yarn" ]; then
    yarn type-check
else
    npm run type-check
fi

success "TypeScript 类型检查通过"

# ESLint 检查
log "执行 ESLint 检查..."
if [ "$PACKAGE_MANAGER" = "yarn" ]; then
    yarn lint
else
    npm run lint
fi

success "ESLint 检查通过"

# 测试 DB-GPT 构建脚本
log "测试 DB-GPT 构建脚本..."
if [ -f "scripts/build-dbgpt.sh" ]; then
    # 只检查脚本语法，不实际执行
    bash -n scripts/build-dbgpt.sh
    success "DB-GPT 构建脚本语法检查通过"
else
    error "DB-GPT 构建脚本不存在"
    exit 1
fi

# 测试主站构建
log "测试主站构建..."
if [ "$PACKAGE_MANAGER" = "yarn" ]; then
    yarn build
else
    npm run build
fi

success "主站构建成功"

# 检查构建产物
BUILD_DIR="dist"
if [ -d "$BUILD_DIR" ]; then
    BUILD_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
    FILE_COUNT=$(find "$BUILD_DIR" -type f | wc -l)
    
    success "构建产物检查:"
    success "  - 构建目录: $BUILD_DIR"
    success "  - 构建大小: $BUILD_SIZE"
    success "  - 文件数量: $FILE_COUNT"
    
    # 检查关键文件
    CRITICAL_FILES=(
        "index.html"
        "assets"
    )
    
    for file in "${CRITICAL_FILES[@]}"; do
        if [ -e "$BUILD_DIR/$file" ]; then
            success "  - 关键文件存在: $file"
        else
            warning "  - 关键文件缺失: $file"
        fi
    done
else
    error "构建产物目录不存在: $BUILD_DIR"
    exit 1
fi

# 生成测试报告
REPORT_FILE="test-build-report.json"
log "生成测试报告: $REPORT_FILE"

cat > "$REPORT_FILE" << EOF
{
  "testTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "nodeVersion": "$NODE_VERSION",
  "packageManager": "$PACKAGE_MANAGER",
  "frontendDir": "$FRONTEND_DIR",
  "buildDir": "$BUILD_DIR",
  "buildSize": "$BUILD_SIZE",
  "fileCount": $FILE_COUNT,
  "checks": {
    "requiredFiles": true,
    "nodeEnvironment": true,
    "dependencies": true,
    "typeCheck": true,
    "eslint": true,
    "dbgptScript": true,
    "mainBuild": true,
    "buildArtifacts": true
  },
  "status": "success"
}
EOF

success "所有测试通过！"
success "测试报告已生成: $REPORT_FILE"

log "下一步可以执行:"
log "  1. npm run build:dbgpt  # 构建 DB-GPT 组件"
log "  2. npm run dev          # 启动开发服务器"
log "  3. npm run preview      # 预览构建产物"

exit 0
