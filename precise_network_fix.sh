#!/bin/bash
# 🎯 基于深度思考的精准网络修复方案

set -e

echo "🎯 基于深度思考的精准网络修复"
echo "============================="

# 获取关键网络信息
DOCKER_GATEWAY=$(docker network inspect docker_default | grep Gateway | awk -F'"' '{print $4}')
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📊 网络环境分析:"
echo "   - Docker网关: $DOCKER_GATEWAY"
echo "   - 项目目录: $PROJECT_DIR"

cd "$PROJECT_DIR/dify/docker"

echo ""
echo "🔧 第一步：配置容器环境变量"
echo "=========================="

# 直接在运行的容器中配置环境变量和pip
docker compose exec plugin_daemon bash -c "
echo '🔨 配置容器内环境...'

# 1. 设置环境变量
export HTTP_PROXY=http://$DOCKER_GATEWAY:7890
export HTTPS_PROXY=http://$DOCKER_GATEWAY:7890
export http_proxy=http://$DOCKER_GATEWAY:7890
export https_proxy=http://$DOCKER_GATEWAY:7890

# 2. 配置pip国内镜像源
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple/
extra-index-url = https://mirrors.aliyun.com/pypi/simple/
trusted-host = pypi.tuna.tsinghua.edu.cn
               mirrors.aliyun.com
timeout = 60
retries = 3
EOF

# 3. 配置永久环境变量
cat >> ~/.bashrc << 'EOF'
export HTTP_PROXY=http://$DOCKER_GATEWAY:7890
export HTTPS_PROXY=http://$DOCKER_GATEWAY:7890
export http_proxy=http://$DOCKER_GATEWAY:7890
export https_proxy=http://$DOCKER_GATEWAY:7890
EOF

echo '✅ 容器环境配置完成'
"

echo ""
echo "🌉 第二步：创建网络代理桥接"
echo "=========================="

# 创建简单的代理桥接
if ! docker ps | grep -q "dify-proxy-bridge"; then
    echo "创建代理桥接容器..."
    docker run -d --name dify-proxy-bridge \
        --restart unless-stopped \
        --network docker_default \
        alpine/socat:latest \
        socat TCP-LISTEN:7890,reuseaddr,fork TCP:$DOCKER_GATEWAY:7890
    
    echo "✅ 代理桥接创建完成"
else
    echo "✅ 代理桥接已存在"
fi

echo ""
echo "🧪 第三步：测试网络连接"
echo "===================="

# 测试网络连接
echo "测试容器网络连接..."
docker compose exec plugin_daemon bash -c "
# 设置代理环境变量
export HTTP_PROXY=http://$DOCKER_GATEWAY:7890
export HTTPS_PROXY=http://$DOCKER_GATEWAY:7890

# 测试连接
echo '1. 测试基本网络:'
python3 -c \"
import urllib.request
import socket
socket.setdefaulttimeout(10)

tests = [
    ('百度', 'http://www.baidu.com'),
    ('清华PyPI', 'https://pypi.tuna.tsinghua.edu.cn/simple/'),
    ('阿里PyPI', 'https://mirrors.aliyun.com/pypi/simple/')
]

for name, url in tests:
    try:
        urllib.request.urlopen(url)
        print(f'   ✅ {name}: 连接成功')
    except Exception as e:
        print(f'   ❌ {name}: 连接失败')
\"

echo ''
echo '2. 测试pip功能:'
pip --version
pip config list
"

echo ""
echo "🚀 第四步：测试包安装"
echo "=================="

# 测试安装一个简单的包
echo "尝试安装测试包..."
if docker compose exec plugin_daemon bash -c "
export HTTP_PROXY=http://$DOCKER_GATEWAY:7890
export HTTPS_PROXY=http://$DOCKER_GATEWAY:7890
pip install --no-cache-dir requests --timeout 30
"; then
    echo "✅ 测试包安装成功！"
    
    # 卸载测试包
    docker compose exec plugin_daemon pip uninstall -y requests
    
    echo ""
    echo "🎉 网络修复成功！"
    echo "=================="
    echo ""
    echo "现在可以尝试在Dify界面安装插件了："
    echo "1. 访问 http://localhost/console"
    echo "2. 进入模型供应商设置"
    echo "3. 安装OpenAI或DeepSeek插件"
    
else
    echo "⚠️ 包安装仍有问题，使用备选方案..."
    
    echo ""
    echo "🎯 备选方案：直接配置OpenAI兼容模型"
    echo "=================================="
    
    cat << 'EOF'
    
由于网络环境复杂，建议使用更稳定的直接配置方案：

📌 OpenAI兼容配置步骤:
1. 访问 http://localhost/console
2. 进入 "设置" → "模型供应商"  
3. 选择 "OpenAI" → "自定义配置"
4. 填写配置:
   ┌─────────────────────────────────────┐
   │ API Base URL: https://api.deepseek.com/v1
   │ API Key: [您的DeepSeek API密钥]
   │ 模型名称: deepseek-chat
   └─────────────────────────────────────┘

✨ 这种方式的优势:
✓ 绕过网络插件安装问题
✓ 配置简单，功能完整
✓ 直接使用API，更稳定
✓ 避免容器网络复杂性
EOF
fi

echo ""
echo "📚 其他有用命令:"
echo "- 查看容器日志: docker compose logs plugin_daemon"
echo "- 进入容器调试: docker compose exec plugin_daemon bash"  
echo "- 测试网络: docker compose exec plugin_daemon curl -I https://pypi.org"
echo "- 清理代理桥接: docker rm -f dify-proxy-bridge"

echo ""
echo "🧠 深度分析总结:"
echo "================"
echo "✅ 识别了Docker网络隔离的根本问题"
echo "✅ 实施了代理桥接解决方案"
echo "✅ 配置了国内镜像源备选"
echo "✅ 提供了直接配置的稳定方案"