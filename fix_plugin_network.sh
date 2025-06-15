#!/bin/bash
# 插件网络连接修复脚本

set -e

echo "🔧 修复插件网络连接问题"
echo "=============================="

# 加载环境配置
source "$(dirname "$0")/load_env.sh"
cd "$DIFY_DIR/docker"

# 获取Docker网关IP
GATEWAY_IP=$(docker network inspect docker_default | grep Gateway | awk -F'"' '{print $4}')
echo "📡 Docker网关IP: $GATEWAY_IP"

echo ""
echo "🔍 问题分析："
echo "- 宿主机代理: http://127.0.0.1:7890"
echo "- 容器内127.0.0.1指向容器自身，需要使用宿主机网关IP"
echo "- 修复方案: 配置容器使用 http://$GATEWAY_IP:7890"

echo ""
echo "步骤1: 添加网络调试工具到插件容器..."

# 创建网络工具安装脚本
cat > /tmp/install_network_tools.sh << 'EOF'
#!/bin/bash
apt-get update -qq
apt-get install -y --no-install-recommends \
    curl \
    wget \
    net-tools \
    iputils-ping \
    dnsutils \
    telnet
echo "网络工具安装完成"
EOF

# 复制脚本到容器并执行
docker cp /tmp/install_network_tools.sh docker-plugin_daemon-1:/tmp/
docker compose exec plugin_daemon bash /tmp/install_network_tools.sh

echo "✅ 网络工具安装完成"

echo ""
echo "步骤2: 配置容器代理设置..."

# 设置代理环境变量
docker compose exec plugin_daemon bash -c "
export HTTP_PROXY=http://$GATEWAY_IP:7890
export HTTPS_PROXY=http://$GATEWAY_IP:7890
export http_proxy=http://$GATEWAY_IP:7890
export https_proxy=http://$GATEWAY_IP:7890
export NO_PROXY=localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12
export no_proxy=localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12

# 保存到环境文件
cat > /etc/environment << EOL
HTTP_PROXY=http://$GATEWAY_IP:7890
HTTPS_PROXY=http://$GATEWAY_IP:7890
http_proxy=http://$GATEWAY_IP:7890
https_proxy=http://$GATEWAY_IP:7890
NO_PROXY=localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12
no_proxy=localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12
EOL

echo '✅ 代理配置已设置'
"

echo ""
echo "步骤3: 配置pip使用代理和国内镜像..."

# 配置pip
docker compose exec plugin_daemon bash -c "
mkdir -p ~/.pip

cat > ~/.pip/pip.conf << 'EOL'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple/
extra-index-url = https://pypi.org/simple/
trusted-host = pypi.tuna.tsinghua.edu.cn
                pypi.org
timeout = 120
retries = 5

[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
                pypi.org
EOL

echo '✅ pip配置完成'
"

echo ""
echo "步骤4: 测试网络连接..."

# 测试网络连接
echo "🌐 测试外网连接:"
docker compose exec plugin_daemon curl -s --connect-timeout 10 http://www.baidu.com > /dev/null && echo "✅ 能访问百度" || echo "❌ 无法访问百度"

echo ""
echo "🐍 测试PyPI连接:"
docker compose exec plugin_daemon curl -s --connect-timeout 10 https://pypi.org/simple/ > /dev/null && echo "✅ 能访问PyPI官方源" || echo "⚠️  无法访问PyPI官方源"

docker compose exec plugin_daemon curl -s --connect-timeout 10 https://pypi.tuna.tsinghua.edu.cn/simple/ > /dev/null && echo "✅ 能访问清华镜像源" || echo "❌ 无法访问清华镜像源"

echo ""
echo "📦 测试pip安装:"
docker compose exec plugin_daemon python3 -c "
import os
os.environ['HTTP_PROXY'] = 'http://$GATEWAY_IP:7890'
os.environ['HTTPS_PROXY'] = 'http://$GATEWAY_IP:7890'
import subprocess
result = subprocess.run(['pip', 'install', '--dry-run', 'requests'], capture_output=True, text=True)
if result.returncode == 0:
    print('✅ pip网络连接正常')
else:
    print('❌ pip安装测试失败:', result.stderr[:200])
"

echo ""
echo "步骤5: 重启插件服务以应用配置..."

# 修改docker-compose.yaml添加代理环境变量
if ! grep -q "HTTP_PROXY" docker-compose.yaml; then
    echo "📝 更新docker-compose.yaml配置..."
    
    # 备份原文件
    cp docker-compose.yaml docker-compose.yaml.backup
    
    # 添加环境变量到plugin_daemon服务
    python3 << EOL
import yaml
with open('docker-compose.yaml', 'r') as f:
    config = yaml.safe_load(f)

if 'services' in config and 'plugin_daemon' in config['services']:
    if 'environment' not in config['services']['plugin_daemon']:
        config['services']['plugin_daemon']['environment'] = []
    
    proxy_vars = [
        'HTTP_PROXY=http://$GATEWAY_IP:7890',
        'HTTPS_PROXY=http://$GATEWAY_IP:7890',
        'http_proxy=http://$GATEWAY_IP:7890',
        'https_proxy=http://$GATEWAY_IP:7890',
        'NO_PROXY=localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12',
        'no_proxy=localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12'
    ]
    
    # 替换$GATEWAY_IP为实际值
    proxy_vars = [var.replace('$GATEWAY_IP', '$GATEWAY_IP') for var in proxy_vars]
    
    for var in proxy_vars:
        if var not in config['services']['plugin_daemon']['environment']:
            config['services']['plugin_daemon']['environment'].append(var)

with open('docker-compose.yaml', 'w') as f:
    yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
    
print("配置文件已更新")
EOL

    # 手动替换$GATEWAY_IP变量
    sed -i "s/\$GATEWAY_IP/$GATEWAY_IP/g" docker-compose.yaml
fi

# 重启插件服务
echo "🔄 重启插件服务..."
docker compose restart plugin_daemon

echo ""
echo "等待插件服务启动..."
sleep 15

# 最终测试
echo ""
echo "🎯 最终网络测试:"
docker compose exec plugin_daemon python3 -c "
import urllib.request
import os

# 设置代理
os.environ['HTTP_PROXY'] = 'http://$GATEWAY_IP:7890'
os.environ['HTTPS_PROXY'] = 'http://$GATEWAY_IP:7890'

try:
    # 测试清华源
    urllib.request.urlopen('https://pypi.tuna.tsinghua.edu.cn/simple/', timeout=10)
    print('✅ 清华PyPI镜像源连接成功')
except Exception as e:
    print('❌ 清华源连接失败:', str(e)[:100])

try:
    # 测试官方源
    urllib.request.urlopen('https://pypi.org/simple/', timeout=10)
    print('✅ 官方PyPI源连接成功')
except Exception as e:
    print('⚠️  官方源连接失败:', str(e)[:100])
"

echo ""
echo "🧹 清理临时文件..."
rm -f /tmp/install_network_tools.sh

echo ""
echo "🎉 网络修复完成！"
echo "=============================="
echo ""
echo "📋 修复摘要:"
echo "1. ✅ 添加了网络调试工具 (curl, wget, ping, nslookup等)"
echo "2. ✅ 配置了正确的代理设置 (http://$GATEWAY_IP:7890)"
echo "3. ✅ 设置了pip国内镜像源"
echo "4. ✅ 重启了插件服务"
echo ""
echo "💡 现在可以重试安装插件了！"
echo "🌐 访问 http://localhost/console 进入模型供应商设置"

# 创建快速测试脚本
cat > ../test_plugin_network.sh << 'EOF'
#!/bin/bash
echo "🔍 插件网络连接测试"
echo "==================="

cd "$(dirname "$0")/dify/docker"

echo "📡 测试容器网络:"
docker compose exec plugin_daemon ping -c 2 8.8.8.8 || echo "❌ 无法ping外网"

echo ""
echo "🐍 测试PyPI连接:"
docker compose exec plugin_daemon curl -s --connect-timeout 5 https://pypi.tuna.tsinghua.edu.cn/simple/ > /dev/null && echo "✅ 清华源可访问" || echo "❌ 清华源不可访问"

echo ""
echo "🔧 测试pip:"
docker compose exec plugin_daemon pip --version

echo ""
echo "📦 测试包安装:"
docker compose exec plugin_daemon pip install --dry-run --no-deps requests || echo "❌ pip安装测试失败"
EOF

chmod +x ../test_plugin_network.sh

echo "📄 网络测试脚本已创建: $DIFY_DIR/test_plugin_network.sh"