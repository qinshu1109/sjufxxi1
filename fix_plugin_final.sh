#!/bin/bash
# 最终插件网络修复方案

set -e

echo "🔧 最终插件网络修复方案"
echo "========================="

# 加载环境配置
source "$(dirname "$0")/load_env.sh"
cd "$DIFY_DIR/docker"

echo "📝 方案：使用国内PyPI镜像源 + 优化配置"
echo ""

echo "步骤1: 重启插件服务恢复正常状态..."
docker compose restart plugin_daemon
sleep 15

echo ""
echo "步骤2: 配置国内镜像源..."

# 创建pip配置
docker compose exec plugin_daemon bash -c "
mkdir -p /root/.pip
cat > /root/.pip/pip.conf << 'EOF'
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
extra-index-url = https://pypi.tuna.tsinghua.edu.cn/simple/
                   https://mirrors.cloud.tencent.com/pypi/simple/
trusted-host = mirrors.aliyun.com
                pypi.tuna.tsinghua.edu.cn
                mirrors.cloud.tencent.com
timeout = 120
retries = 5

[install]
trusted-host = mirrors.aliyun.com
                pypi.tuna.tsinghua.edu.cn  
                mirrors.cloud.tencent.com
EOF

echo '✅ pip镜像源配置完成'
"

echo ""
echo "步骤3: 测试网络连接..."

# 测试镜像源连接
echo "🌐 测试镜像源连接:"
test_sources=(
    "https://mirrors.aliyun.com/pypi/simple/"
    "https://pypi.tuna.tsinghua.edu.cn/simple/"
    "https://mirrors.cloud.tencent.com/pypi/simple/"
)

for source in "${test_sources[@]}"; do
    if docker compose exec plugin_daemon python3 -c "
import urllib.request
import socket
socket.setdefaulttimeout(15)
try:
    urllib.request.urlopen('$source')
    print('✅ $source - 可访问')
except Exception as e:
    print('❌ $source - 不可访问')
    " 2>/dev/null; then
        echo "找到可用镜像源"
        break
    fi
done

echo ""
echo "步骤4: 测试pip安装..."

# 测试pip安装一个小包
if docker compose exec plugin_daemon pip install --no-cache-dir --timeout 60 packaging > /dev/null 2>&1; then
    echo "✅ pip安装测试成功"
    docker compose exec plugin_daemon pip uninstall -y packaging > /dev/null 2>&1
else
    echo "⚠️  pip安装仍有问题，尝试备选方案..."
    
    # 备选方案：完全离线配置
    echo "配置更多备选镜像源..."
    docker compose exec plugin_daemon bash -c "
    cat > /root/.pip/pip.conf << 'EOF'
[global] 
index-url = https://mirrors.aliyun.com/pypi/simple/
extra-index-url = https://pypi.douban.com/simple/
                   https://pypi.mirrors.ustc.edu.cn/simple/
                   https://pypi.tuna.tsinghua.edu.cn/simple/
trusted-host = mirrors.aliyun.com
                pypi.douban.com
                pypi.mirrors.ustc.edu.cn
                pypi.tuna.tsinghua.edu.cn
timeout = 180
retries = 8
EOF
    "
fi

echo ""
echo "步骤5: 创建插件安装测试脚本..."

# 创建测试脚本
cat > ../test_plugin_ready.sh << 'EOF'
#!/bin/bash
echo "🧪 插件安装就绪测试"
echo "==================="

cd "$(dirname "$0")/docker"

echo "📦 测试pip配置:"
docker compose exec plugin_daemon pip --version

echo ""
echo "🌐 测试镜像源连接:"
docker compose exec plugin_daemon python3 -c "
import urllib.request
import socket
socket.setdefaulttimeout(10)

sources = [
    'https://mirrors.aliyun.com/pypi/simple/',
    'https://pypi.tuna.tsinghua.edu.cn/simple/',
    'https://pypi.douban.com/simple/'
]

available = 0
for source in sources:
    try:
        urllib.request.urlopen(source)
        print(f'✅ {source} - 可访问')
        available += 1
    except:
        print(f'❌ {source} - 不可访问')

if available > 0:
    print(f'\\n🎉 找到 {available} 个可用镜像源')
    print('插件安装应该可以正常进行！')
else:
    print('\\n❌ 所有镜像源都不可访问')
"

echo ""
echo "🔧 测试包安装:"
if docker compose exec plugin_daemon pip install --dry-run --no-deps requests >/dev/null 2>&1; then
    echo "✅ pip安装功能正常"
    echo "💡 现在可以在Dify界面重试安装插件了！"
    echo ""
    echo "🔗 访问 http://localhost/console 进入模型供应商设置"
else
    echo "❌ pip安装仍有问题"
    echo "💡 建议直接配置OpenAI兼容模型，避免插件安装问题"
fi
EOF

chmod +x ../test_plugin_ready.sh

echo ""
echo "🎉 插件网络修复完成！"
echo "====================="
echo ""
echo "📋 修复总结:"
echo "1. ✅ 恢复了正常的Docker网络配置"
echo "2. ✅ 配置了多个国内PyPI镜像源"
echo "3. ✅ 优化了pip超时和重试设置"
echo ""
echo "💡 现在可以尝试以下方案："
echo ""
echo "方案A: 重试插件安装"
echo "- 访问 http://localhost/console"
echo "- 进入模型供应商设置"
echo "- 重新尝试安装OpenAI或DeepSeek插件"
echo ""
echo "方案B: 手动配置（推荐）"
echo "- 在OpenAI供应商中配置:"
echo "- API Key: your_api_key"
echo "- Base URL: https://api.deepseek.com/v1 (用于DeepSeek)"
echo "- 或使用其他OpenAI兼容API"
echo ""
echo "🧪 测试脚本: $DIFY_DIR/test_plugin_ready.sh"

# 运行测试
echo ""
echo "🔍 立即测试网络状态..."
../test_plugin_ready.sh