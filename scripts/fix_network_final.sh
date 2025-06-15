#!/bin/bash
# 最终网络问题解决脚本
# 针对 mihomo-party 代理环境优化

set -euo pipefail

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $*"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $*"
}

info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] INFO:${NC} $*"
}

setup_proxy_env() {
    log "设置代理环境变量..."
    
    # 设置代理环境变量
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    export NO_PROXY=localhost,127.0.0.1,::1
    export no_proxy=localhost,127.0.0.1,::1
    
    # 写入到 shell 配置文件
    cat >> ~/.bashrc << 'EOF'

# 代理配置 (mihomo-party)
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export NO_PROXY=localhost,127.0.0.1,::1
export no_proxy=localhost,127.0.0.1,::1
EOF
    
    log "代理环境变量设置完成"
}

create_podman_config() {
    log "创建 Podman 配置..."
    
    mkdir -p ~/.config/containers
    
    # 创建简化的 registries.conf
    cat > ~/.config/containers/registries.conf << 'EOF'
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry.mirror]]
location = "dockerproxy.com"
insecure = false

[[registry.mirror]]
location = "docker.mirrors.ustc.edu.cn"
insecure = false

[[registry.mirror]]
location = "registry.docker-cn.com"
insecure = false
EOF
    
    log "Podman 镜像源配置完成"
}

test_docker_registry() {
    log "测试 Docker 镜像仓库访问..."
    
    # 测试直接访问
    if curl -s --connect-timeout 10 --proxy "$HTTP_PROXY" https://registry-1.docker.io/v2/ | grep -q "unauthorized"; then
        log "✓ Docker Hub 访问正常"
        return 0
    fi
    
    # 测试镜像源
    if curl -s --connect-timeout 10 --proxy "$HTTP_PROXY" https://dockerproxy.com/v2/ | grep -q "unauthorized"; then
        log "✓ Docker 镜像源访问正常"
        return 0
    fi
    
    warn "Docker 镜像仓库访问测试失败"
    return 1
}

test_podman_pull() {
    log "测试 Podman 镜像拉取..."
    
    # 尝试拉取小镜像进行测试
    if timeout 60 podman pull hello-world; then
        log "✓ Podman 镜像拉取成功"
        return 0
    else
        warn "Podman 镜像拉取失败"
        return 1
    fi
}

try_alternative_registries() {
    log "尝试替代镜像源..."
    
    # 创建包含更多镜像源的配置
    cat > ~/.config/containers/registries.conf << 'EOF'
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "dockerproxy.com"

[[registry]]
prefix = "docker.io"
location = "docker.mirrors.ustc.edu.cn"

[[registry]]
prefix = "docker.io"
location = "registry.docker-cn.com"

[[registry]]
prefix = "docker.io"
location = "hub-mirror.c.163.com"

[[registry]]
prefix = "docker.io"
location = "docker.io"
EOF
    
    log "替代镜像源配置完成"
}

build_dbgpt_with_proxy() {
    log "使用代理构建 DB-GPT 镜像..."
    
    cd /home/qinshu/douyin-analytics
    
    # 设置构建时的代理参数
    if podman build \
        --build-arg HTTP_PROXY="$HTTP_PROXY" \
        --build-arg HTTPS_PROXY="$HTTPS_PROXY" \
        --build-arg http_proxy="$http_proxy" \
        --build-arg https_proxy="$https_proxy" \
        --build-arg NO_PROXY="$NO_PROXY" \
        --build-arg no_proxy="$no_proxy" \
        -f external/dbgpt/Containerfile \
        -t dbgpt:latest \
        external/dbgpt; then
        log "✓ DB-GPT 镜像构建成功"
        return 0
    else
        error "DB-GPT 镜像构建失败"
        return 1
    fi
}

try_prebuilt_image() {
    log "尝试使用预构建镜像..."
    
    # 尝试从不同的镜像源拉取预构建镜像
    local registries=(
        "dockerproxy.com/eosphoros/dbgpt:latest"
        "registry.cn-hangzhou.aliyuncs.com/dbgpt/dbgpt:latest"
        "ghcr.io/eosphoros-ai/db-gpt:latest"
    )
    
    for registry in "${registries[@]}"; do
        log "尝试从 $registry 拉取镜像..."
        if timeout 120 podman pull "$registry"; then
            log "✓ 成功拉取镜像: $registry"
            podman tag "$registry" dbgpt:latest
            log "✓ 镜像已标记为 dbgpt:latest"
            return 0
        else
            warn "从 $registry 拉取失败，尝试下一个..."
        fi
    done
    
    error "所有预构建镜像拉取失败"
    return 1
}

main() {
    log "开始最终网络问题解决..."
    
    # 1. 设置代理环境
    setup_proxy_env
    
    # 2. 创建 Podman 配置
    create_podman_config
    
    # 3. 测试网络连接
    if test_docker_registry; then
        log "网络连接测试通过"
    else
        warn "网络连接有问题，但继续尝试"
    fi
    
    # 4. 测试基础镜像拉取
    if test_podman_pull; then
        log "基础镜像拉取成功"
    else
        warn "基础镜像拉取失败，尝试替代方案"
        try_alternative_registries
    fi
    
    # 5. 尝试构建 DB-GPT 镜像
    if build_dbgpt_with_proxy; then
        log "DB-GPT 镜像构建成功"
    else
        warn "构建失败，尝试预构建镜像"
        if try_prebuilt_image; then
            log "预构建镜像获取成功"
        else
            error "所有方案都失败了"
            return 1
        fi
    fi
    
    log "网络问题解决完成！"
    
    echo ""
    echo "=========================================="
    echo "🎉 网络问题已解决！"
    echo "=========================================="
    echo ""
    echo "成功配置："
    echo "  - 代理环境变量: ✓"
    echo "  - Podman 镜像源: ✓"
    echo "  - DB-GPT 镜像: ✓"
    echo ""
    echo "验证命令："
    echo "  podman images | grep dbgpt"
    echo "  podman run --rm dbgpt:latest --version"
    echo ""
    echo "下一步："
    echo "  cd /home/qinshu/douyin-analytics"
    echo "  export DEEPSEEK_API_KEY='your-key'"
    echo "  ./scripts/deploy_dbgpt.sh"
    echo ""
}

# 如果直接运行脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
