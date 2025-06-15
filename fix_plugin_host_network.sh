#!/bin/bash
# 使用host网络模式修复插件网络问题

set -e

echo "🌐 使用host网络模式修复插件网络"
echo "=================================="

# 加载环境配置
source "$(dirname "$0")/load_env.sh"
cd "$DIFY_DIR/docker"

echo "📝 备份并修改docker-compose.yaml..."

# 备份原文件
cp docker-compose.yaml docker-compose.yaml.original

# 修改plugin_daemon服务使用host网络
python3 << 'EOF'
import yaml
import sys

try:
    with open('docker-compose.yaml', 'r') as f:
        config = yaml.safe_load(f)

    if 'services' in config and 'plugin_daemon' in config['services']:
        # 设置为host网络模式
        config['services']['plugin_daemon']['network_mode'] = 'host'
        
        # 移除端口映射（host模式下不需要）
        if 'ports' in config['services']['plugin_daemon']:
            del config['services']['plugin_daemon']['ports']
        
        # 添加环境变量使其使用宿主机代理
        if 'environment' not in config['services']['plugin_daemon']:
            config['services']['plugin_daemon']['environment'] = []
        
        proxy_vars = [
            'HTTP_PROXY=http://127.0.0.1:7890',
            'HTTPS_PROXY=http://127.0.0.1:7890',
            'http_proxy=http://127.0.0.1:7890', 
            'https_proxy=http://127.0.0.1:7890',
            'NO_PROXY=localhost,127.0.0.1',
            'no_proxy=localhost,127.0.0.1'
        ]
        
        env_list = config['services']['plugin_daemon']['environment']
        if isinstance(env_list, list):
            # 移除旧的代理设置
            env_list = [e for e in env_list if not any(p in str(e) for p in ['proxy', 'PROXY'])]
            # 添加新的代理设置
            env_list.extend(proxy_vars)
            config['services']['plugin_daemon']['environment'] = env_list

    with open('docker-compose.yaml', 'w') as f:
        yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
    
    print("✅ docker-compose.yaml 修改完成")
    
except Exception as e:
    print(f"❌ 修改失败: {e}")
    sys.exit(1)
EOF

echo ""
echo "🔄 重启plugin_daemon服务..."
docker compose stop plugin_daemon
sleep 2
docker compose up -d plugin_daemon

echo ""
echo "⏳ 等待服务启动..."
sleep 10

echo ""
echo "🧪 测试网络连接..."

# 测试基本网络连接
echo "1. 测试基本网络连接:"
if docker compose exec plugin_daemon python3 -c "
import urllib.request
import socket
socket.setdefaulttimeout(10)
try:
    urllib.request.urlopen('http://www.baidu.com')
    print('✅ 可以访问百度')
except Exception as e:
    print('❌ 无法访问百度:', str(e)[:50])
"; then
    echo "基本网络连接正常"
else
    echo "基本网络连接可能有问题"
fi

echo ""
echo "2. 测试PyPI连接:"
docker compose exec plugin_daemon python3 -c "
import urllib.request
import socket
socket.setdefaulttimeout(10)

# 测试官方PyPI
try:
    response = urllib.request.urlopen('https://pypi.org/simple/')
    print('✅ 可以访问PyPI官方源')
except Exception as e:
    print('❌ 无法访问PyPI官方源:', str(e)[:50])

# 测试清华镜像
try:
    response = urllib.request.urlopen('https://pypi.tuna.tsinghua.edu.cn/simple/')
    print('✅ 可以访问清华镜像源')
except Exception as e:
    print('❌ 无法访问清华镜像源:', str(e)[:50])
"

echo ""
echo "3. 测试pip功能:"
if docker compose exec plugin_daemon pip --version > /dev/null 2>&1; then
    echo "✅ pip正常工作"
    
    # 测试pip install
    echo "测试pip安装包..."
    if docker compose exec plugin_daemon pip install --dry-run --no-deps requests > /dev/null 2>&1; then
        echo "✅ pip可以安装包"
    else
        echo "⚠️  pip安装可能有问题"
    fi
else
    echo "❌ pip无法正常工作"
fi

echo ""
echo "🎯 现在测试插件安装..."

# 创建简单的测试脚本
cat > /tmp/test_plugin_install.py << 'EOF'
import subprocess
import sys
import os

# 设置环境变量
os.environ['HTTP_PROXY'] = 'http://127.0.0.1:7890'
os.environ['HTTPS_PROXY'] = 'http://127.0.0.1:7890'

try:
    # 尝试安装一个简单的包来测试
    result = subprocess.run([
        'pip', 'install', '--no-cache-dir', '--timeout', '30', 'requests'
    ], capture_output=True, text=True, timeout=60)
    
    if result.returncode == 0:
        print("✅ pip安装测试成功")
        # 卸载测试包
        subprocess.run(['pip', 'uninstall', '-y', 'requests'], capture_output=True)
        sys.exit(0)
    else:
        print("❌ pip安装失败:")
        print(result.stderr[:300])
        sys.exit(1)
        
except subprocess.TimeoutExpired:
    print("❌ pip安装超时")
    sys.exit(1)
except Exception as e:
    print(f"❌ 测试过程出错: {e}")
    sys.exit(1)
EOF

# 复制到容器并执行测试
docker cp /tmp/test_plugin_install.py docker-plugin_daemon-1:/tmp/
if docker compose exec plugin_daemon python3 /tmp/test_plugin_install.py; then
    echo ""
    echo "🎉 网络修复成功！插件安装应该可以正常工作了"
    echo ""
    echo "📋 修复总结:"
    echo "1. ✅ 配置plugin_daemon使用host网络模式"
    echo "2. ✅ 容器现在可以直接使用宿主机的代理设置"
    echo "3. ✅ pip网络连接正常"
    echo ""
    echo "💡 现在可以在Dify界面重试安装插件了！"
    
else
    echo ""
    echo "⚠️  网络仍有问题，尝试备选方案..."
    
    echo "📝 配置pip使用国内镜像源（备选方案）..."
    docker compose exec plugin_daemon bash -c "
    mkdir -p ~/.pip
    cat > ~/.pip/pip.conf << 'EOL'
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
extra-index-url = https://pypi.tuna.tsinghua.edu.cn/simple/
trusted-host = mirrors.aliyun.com
                pypi.tuna.tsinghua.edu.cn
timeout = 60
retries = 3

[install]
trusted-host = mirrors.aliyun.com
                pypi.tuna.tsinghua.edu.cn
EOL
    "
    
    echo "✅ 已配置阿里云镜像源，这可能有助于插件安装"
fi

# 清理
rm -f /tmp/test_plugin_install.py

echo ""
echo "🔗 访问链接:"
echo "- Dify控制台: http://localhost/console"
echo "- 模型供应商设置: http://localhost/console/plugins"

echo ""
echo "📄 如需恢复原配置，运行:"
echo "cd $DIFY_DIR/docker && cp docker-compose.yaml.original docker-compose.yaml && docker compose restart plugin_daemon"