#!/bin/bash
# 代理配置脚本
# 自动检测和配置代理设置

set -euo pipefail

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# 常见代理端口
PROXY_PORTS=(7890 7891 7892 1080 8080 8118 10809)

detect_proxy() {
    log "检测代理配置..."
    
    # 检查环境变量
    if [[ -n "${HTTP_PROXY:-}" ]] || [[ -n "${http_proxy:-}" ]]; then
        log "发现环境变量代理配置"
        return 0
    fi
    
    # 检测常见代理端口
    for port in "${PROXY_PORTS[@]}"; do
        if ss -tlnp | grep -q ":${port} "; then
            log "发现代理端口: ${port}"
            export HTTP_PROXY="http://127.0.0.1:${port}"
            export HTTPS_PROXY="http://127.0.0.1:${port}"
            export http_proxy="http://127.0.0.1:${port}"
            export https_proxy="http://127.0.0.1:${port}"
            export NO_PROXY="localhost,127.0.0.1,::1"
            export no_proxy="localhost,127.0.0.1,::1"
            return 0
        fi
    done
    
    # 尝试常见的代理配置
    for port in "${PROXY_PORTS[@]}"; do
        if curl -s --connect-timeout 3 --proxy "http://127.0.0.1:${port}" http://www.google.com >/dev/null 2>&1; then
            log "检测到工作的代理端口: ${port}"
            export HTTP_PROXY="http://127.0.0.1:${port}"
            export HTTPS_PROXY="http://127.0.0.1:${port}"
            export http_proxy="http://127.0.0.1:${port}"
            export https_proxy="http://127.0.0.1:${port}"
            export NO_PROXY="localhost,127.0.0.1,::1"
            export no_proxy="localhost,127.0.0.1,::1"
            return 0
        fi
    done
    
    warn "未检测到可用的代理配置"
    return 1
}

configure_podman_proxy() {
    log "配置 Podman 代理..."
    
    # 创建 containers.conf
    mkdir -p ~/.config/containers
    
    cat > ~/.config/containers/containers.conf << EOF
[containers]
# 代理配置
http_proxy = "${HTTP_PROXY:-}"
https_proxy = "${HTTPS_PROXY:-}"
no_proxy = "${NO_PROXY:-localhost,127.0.0.1,::1}"

[engine]
# 网络配置
network_cmd_options = ["enable_ipv6=false"]
EOF
    
    log "Podman 代理配置完成"
}

test_registry_access() {
    log "测试镜像仓库访问..."
    
    # 测试 Docker Hub 访问
    if podman search --limit 1 ubuntu >/dev/null 2>&1; then
        log "✓ Docker Hub 访问正常"
        return 0
    else
        warn "Docker Hub 访问失败，尝试使用镜像源"
        return 1
    fi
}

setup_mirror_registry() {
    log "配置镜像源..."
    
    cat > ~/.config/containers/registries.conf << 'EOF'
# Podman 镜像仓库配置
[registries.search]
registries = ['docker.io', 'ghcr.io', 'quay.io']

[registries.insecure]
registries = []

[registries.block]
registries = []

# 配置 Docker Hub 镜像加速
[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry.mirror]]
location = "registry.docker-cn.com"

[[registry.mirror]]
location = "docker.mirrors.ustc.edu.cn"

[[registry.mirror]]
location = "hub-mirror.c.163.com"

[[registry.mirror]]
location = "dockerproxy.com"
EOF
    
    log "镜像源配置完成"
}

main() {
    log "开始配置代理环境..."
    
    # 1. 检测代理
    if detect_proxy; then
        log "代理检测成功"
        log "HTTP_PROXY: ${HTTP_PROXY:-未设置}"
        log "HTTPS_PROXY: ${HTTPS_PROXY:-未设置}"
    else
        warn "未检测到代理，将使用镜像源"
    fi
    
    # 2. 配置 Podman 代理
    configure_podman_proxy
    
    # 3. 配置镜像源
    setup_mirror_registry
    
    # 4. 测试访问
    if test_registry_access; then
        log "✓ 镜像仓库访问配置成功"
    else
        warn "镜像仓库访问仍有问题，但已配置镜像源"
    fi
    
    log "代理配置完成！"
    
    echo ""
    echo "=========================================="
    echo "🎉 代理配置完成！"
    echo "=========================================="
    echo ""
    echo "当前代理设置："
    echo "  HTTP_PROXY:  ${HTTP_PROXY:-未设置}"
    echo "  HTTPS_PROXY: ${HTTPS_PROXY:-未设置}"
    echo "  NO_PROXY:    ${NO_PROXY:-未设置}"
    echo ""
    echo "配置文件："
    echo "  - ~/.config/containers/containers.conf"
    echo "  - ~/.config/containers/registries.conf"
    echo ""
    echo "测试命令："
    echo "  podman search ubuntu"
    echo "  podman pull ubuntu:22.04"
    echo ""
}

# 如果直接运行脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
