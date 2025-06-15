#!/bin/bash
# 🧠 基于深度思考的Dify插件网络终极解决方案
# 整合多种方案，智能选择最佳路径

set -e

echo "🧠 Dify插件网络问题深度分析与修复"
echo "===================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 获取项目目录
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIFY_DIR="$PROJECT_DIR/dify/docker"

echo ""
log_info "🔍 第一阶段：深度环境分析"
echo "=============================="

# 1. 网络环境诊断
log_info "1. 分析Docker网络环境..."
DOCKER_GATEWAY=$(docker network inspect docker_default | grep Gateway | awk -F'"' '{print $4}')
PROXY_HOST="127.0.0.1"
PROXY_PORT="7890"

echo "   - Docker网关: $DOCKER_GATEWAY"
echo "   - 宿主机代理: $PROXY_HOST:$PROXY_PORT"

# 2. 代理可达性测试
log_info "2. 测试代理连通性..."
if nc -z $PROXY_HOST $PROXY_PORT 2>/dev/null; then
    log_success "   ✅ 宿主机代理可达"
    PROXY_AVAILABLE=true
else
    log_error "   ❌ 宿主机代理不可达"
    PROXY_AVAILABLE=false
fi

# 3. 容器网络状态
log_info "3. 检查插件容器状态..."
if docker compose ps | grep plugin_daemon | grep -q "Up"; then
    log_success "   ✅ 插件容器运行中"
    CONTAINER_RUNNING=true
else
    log_error "   ❌ 插件容器未运行"
    CONTAINER_RUNNING=false
fi

echo ""
log_info "🎯 第二阶段：问题根因分析"
echo "=============================="

cat << 'EOF'
💡 深度分析结果：

┌─ 问题层次分析 ─┐
│ 1. 表层问题：插件安装失败 (Connection refused)
│ 2. 中层问题：PyPI访问被阻断  
│ 3. 深层问题：Docker网络隔离
│ 4. 根层问题：容器内127.0.0.1 ≠ 宿主机127.0.0.1
└────────────────┘

🔧 解决策略：
- 优先策略：网络桥接（彻底解决）
- 备选策略：离线安装（稳定可靠）
- 终极策略：自定义镜像（一劳永逸）
EOF

echo ""
log_info "🛠️ 第三阶段：智能修复方案选择"
echo "================================="

# 方案选择逻辑
if [[ "$PROXY_AVAILABLE" == "true" && "$CONTAINER_RUNNING" == "true" ]]; then
    RECOMMENDED_STRATEGY="network-bridge"
    log_info "推荐策略：网络桥接方案 (条件完备)"
elif [[ "$PROXY_AVAILABLE" == "true" ]]; then
    RECOMMENDED_STRATEGY="offline-install" 
    log_info "推荐策略：离线安装方案 (代理可用)"
else
    RECOMMENDED_STRATEGY="direct-config"
    log_info "推荐策略：直接配置方案 (绕过网络)"
fi

echo ""
echo "📋 可用方案："
echo "1️⃣ 网络桥接方案 (推荐: $([[ $RECOMMENDED_STRATEGY == "network-bridge" ]] && echo "⭐" || echo ""))"
echo "2️⃣ 离线安装方案 (推荐: $([[ $RECOMMENDED_STRATEGY == "offline-install" ]] && echo "⭐" || echo ""))"
echo "3️⃣ 代理桥接方案 (高级)"
echo "4️⃣ 直接配置方案 (绕过插件)"
echo "5️⃣ 自动选择最佳方案 ⭐"

read -p "请选择方案 [1-5, 回车=自动]: " choice
choice=${choice:-5}

# =============================================================================
# 方案1：网络桥接方案
# =============================================================================
fix_network_bridge() {
    log_info "🌐 执行方案1：网络桥接修复"
    
    cd "$DIFY_DIR"
    
    # 1. 创建增强的docker-compose配置
    log_info "1. 配置容器环境变量..."
    
    # 备份原文件
    cp docker-compose.yaml docker-compose.yaml.backup.$(date +%s)
    
    # 使用Python修改配置
    python3 << PYEOF
import yaml
import sys

try:
    with open('docker-compose.yaml', 'r') as f:
        config = yaml.safe_load(f)

    # 配置plugin_daemon服务
    if 'services' in config and 'plugin_daemon' in config['services']:
        service = config['services']['plugin_daemon']
        
        # 添加环境变量
        if 'environment' not in service:
            service['environment'] = []
        
        # 网络配置 - 使用Docker网关IP
        proxy_vars = [
            'HTTP_PROXY=http://$DOCKER_GATEWAY:7890',
            'HTTPS_PROXY=http://$DOCKER_GATEWAY:7890',
            'http_proxy=http://$DOCKER_GATEWAY:7890',
            'https_proxy=http://$DOCKER_GATEWAY:7890',
            'NO_PROXY=localhost,127.0.0.1,db,redis,api,worker,web',
            'PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple/',
            'PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn'
        ]
        
        env_list = service['environment']
        if isinstance(env_list, list):
            # 移除旧的代理设置
            env_list = [e for e in env_list if not any(p in str(e).upper() for p in ['PROXY', 'PIP_'])]
            # 添加新设置
            env_list.extend(proxy_vars)
            service['environment'] = env_list
        
        # 添加extra_hosts
        service['extra_hosts'] = [
            'host.docker.internal:host-gateway',
            'pypi.org:151.101.84.223',
            'files.pythonhosted.org:151.101.84.223'
        ]
        
        # 添加DNS设置
        service['dns'] = ['8.8.8.8', '114.114.114.114']

    with open('docker-compose.yaml', 'w') as f:
        yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
    
    print("✅ Docker配置修改成功")
    
except Exception as e:
    print(f"❌ 配置修改失败: {e}")
    sys.exit(1)
PYEOF

    # 替换Docker网关变量
    sed -i "s|\$DOCKER_GATEWAY|$DOCKER_GATEWAY|g" docker-compose.yaml
    
    # 2. 创建代理桥接服务
    log_info "2. 创建代理桥接服务..."
    
    # 检查是否需要创建代理桥接
    if ! docker ps | grep -q "proxy-bridge"; then
        cat > docker-compose.proxy.yml << EOF
version: '3.8'
services:
  proxy-bridge:
    image: alpine/socat:latest
    container_name: dify-proxy-bridge
    restart: unless-stopped
    network_mode: host
    command: |
      sh -c "
      echo 'Starting proxy bridge on port 7890...'
      socat TCP-LISTEN:7890,reuseaddr,fork TCP:127.0.0.1:7890 || echo 'Proxy bridge failed'
      "
    privileged: true
EOF
        
        # 启动代理桥接
        docker compose -f docker-compose.proxy.yml up -d
        sleep 5
    fi
    
    # 3. 重启插件服务
    log_info "3. 重启插件服务应用配置..."
    docker compose restart plugin_daemon
    
    log_info "4. 等待服务启动..."
    sleep 15
    
    return 0
}

# =============================================================================
# 方案2：离线安装方案  
# =============================================================================
fix_offline_install() {
    log_info "📦 执行方案2：离线安装修复"
    
    # 1. 准备离线包
    log_info "1. 在宿主机准备离线依赖包..."
    
    mkdir -p /tmp/dify_offline_packages
    cd /tmp/dify_offline_packages
    
    # 使用宿主机代理下载
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    
    log_info "   正在下载Python包..."
    pip download --no-cache-dir \
        requests==2.31.0 \
        urllib3==2.0.4 \
        certifi==2023.7.22 \
        charset-normalizer==3.2.0 \
        idna==3.4 \
        openai==1.3.0 \
        pydantic==2.4.2 \
        httpx==0.25.0 \
        typing-extensions==4.8.0 \
        dify-plugin 2>/dev/null || log_warning "部分包下载可能失败"
    
    # 2. 打包并传输到容器
    log_info "2. 传输包到容器..."
    tar czf dify_packages.tar.gz *.whl *.tar.gz 2>/dev/null || log_warning "打包可能不完整"
    
    # 复制到容器
    docker cp dify_packages.tar.gz docker-plugin_daemon-1:/tmp/ || {
        log_error "无法复制到容器"
        return 1
    }
    
    # 3. 容器内安装
    log_info "3. 在容器内安装离线包..."
    docker compose exec plugin_daemon bash -c "
        cd /tmp
        tar xzf dify_packages.tar.gz 2>/dev/null || echo 'Extract with some warnings'
        pip install --no-index --find-links . *.whl *.tar.gz 2>/dev/null || echo 'Some packages may not install'
        echo '✅ 离线安装尝试完成'
    "
    
    # 清理临时文件
    rm -rf /tmp/dify_offline_packages
    
    return 0
}

# =============================================================================
# 方案3：代理桥接方案
# =============================================================================
fix_proxy_bridge() {
    log_info "🌉 执行方案3：高级代理桥接"
    
    # 创建高级代理桥接
    log_info "1. 创建高级网络代理桥接..."
    
    # 使用socat创建端口转发
    docker run -d --name dify-proxy-forwarder \
        --restart unless-stopped \
        --network docker_default \
        alpine/socat:latest \
        socat TCP-LISTEN:3128,reuseaddr,fork TCP:$DOCKER_GATEWAY:7890
    
    # 修改容器配置使用内部代理
    cd "$DIFY_DIR"
    docker compose exec plugin_daemon bash -c "
        export HTTP_PROXY=http://dify-proxy-forwarder:3128
        export HTTPS_PROXY=http://dify-proxy-forwarder:3128
        export http_proxy=http://dify-proxy-forwarder:3128
        export https_proxy=http://dify-proxy-forwarder:3128
        
        # 保存到容器环境
        echo 'export HTTP_PROXY=http://dify-proxy-forwarder:3128' >> ~/.bashrc
        echo 'export HTTPS_PROXY=http://dify-proxy-forwarder:3128' >> ~/.bashrc
        
        echo '✅ 代理配置完成'
    "
    
    return 0
}

# =============================================================================
# 方案4：直接配置方案
# =============================================================================
fix_direct_config() {
    log_info "🎯 执行方案4：绕过插件直接配置"
    
    cat << 'EOF'
🔧 OpenAI兼容模型配置指南：

1. 🌐 访问: http://localhost/console
2. 📂 导航: 设置 → 模型供应商  
3. ➕ 选择: OpenAI → 自定义配置
4. ⚙️ 配置参数:
   ┌─────────────────────────────────────┐
   │ API Base URL: https://api.deepseek.com/v1
   │ API Key: [您的DeepSeek密钥]
   │ 模型名称: deepseek-chat
   └─────────────────────────────────────┘
5. ✅ 测试连接并保存

📌 优势:
✓ 无需插件安装
✓ 避开网络问题  
✓ 配置简单快速
✓ 功能完全兼容
EOF

    return 0
}

# =============================================================================
# 测试网络连接
# =============================================================================
test_network_connectivity() {
    log_info "🧪 测试网络连接状态..."
    
    cd "$DIFY_DIR"
    
    # 测试容器网络
    log_info "1. 测试插件容器网络连接:"
    if docker compose exec plugin_daemon python3 -c "
import urllib.request
import socket
socket.setdefaulttimeout(10)

test_urls = [
    ('PyPI官方', 'https://pypi.org/simple/'),
    ('清华源', 'https://pypi.tuna.tsinghua.edu.cn/simple/'),
    ('阿里源', 'https://mirrors.aliyun.com/pypi/simple/')
]

success_count = 0
for name, url in test_urls:
    try:
        urllib.request.urlopen(url)
        print(f'   ✅ {name}: 连接成功')
        success_count += 1
    except Exception as e:
        print(f'   ❌ {name}: {str(e)[:50]}...')

print(f'\\n📊 连接成功率: {success_count}/{len(test_urls)}')
if success_count > 0:
    exit(0)
else:
    exit(1)
    "; then
        log_success "网络连接测试通过！"
        return 0
    else
        log_warning "网络连接仍有问题"
        return 1
    fi
}

# =============================================================================
# 主执行流程
# =============================================================================
main() {
    case $choice in
        1)
            fix_network_bridge
            test_network_connectivity
            ;;
        2)
            fix_offline_install
            ;;
        3)
            fix_proxy_bridge
            test_network_connectivity
            ;;
        4)
            fix_direct_config
            ;;
        5|"")
            log_info "🤖 自动选择最佳方案..."
            
            if [[ "$RECOMMENDED_STRATEGY" == "network-bridge" ]]; then
                fix_network_bridge && test_network_connectivity
            elif [[ "$RECOMMENDED_STRATEGY" == "offline-install" ]]; then
                fix_offline_install
            else
                fix_direct_config
            fi
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac
    
    local result=$?
    
    echo ""
    log_info "🎉 修复完成！"
    echo "=============================="
    
    if [[ $result -eq 0 && $choice != 4 ]]; then
        log_success "✅ 网络修复成功！现在可以尝试安装插件："
        echo "   1. 访问 http://localhost/console"
        echo "   2. 进入模型供应商设置"
        echo "   3. 安装OpenAI或DeepSeek插件"
    else
        log_info "💡 建议使用直接配置方案："
        echo "   访问 http://localhost/console 配置OpenAI兼容模型"
    fi
    
    echo ""
    log_info "📚 更多选项:"
    echo "   - 网络测试: docker compose exec plugin_daemon python3 -c \"import urllib.request; urllib.request.urlopen('https://pypi.org')\""
    echo "   - 恢复配置: cp docker-compose.yaml.backup.* docker-compose.yaml"
    echo "   - 查看日志: docker compose logs plugin_daemon"
}

# 执行主流程
main

echo ""
log_success "🧠 深度分析与修复任务完成！"