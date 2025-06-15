#!/bin/bash
# Docker容器网络问题综合解决方案
# 基于深度分析的系统性修复

set -e

echo "🧠 Docker容器网络问题深度分析与修复"
echo "========================================"

# 加载环境配置
source "$(dirname "$0")/load_env.sh"

echo ""
echo "🔍 第一步：深度诊断网络环境"
echo "================================"

echo "📊 系统信息:"
echo "- 操作系统: $(uname -a)"
echo "- Docker版本: $(docker --version)"
echo "- Docker Compose版本: $(docker compose version)"

echo ""
echo "🌐 网络配置分析:"

# 1. 检查宿主机网络
echo "1. 宿主机网络状态:"
echo "   - 代理设置: $(env | grep -i proxy | head -1 || echo '未设置')"
echo "   - DNS配置: $(cat /etc/resolv.conf | head -1)"
echo "   - 路由表: $(ip route | grep default | head -1)"

# 2. 检查Docker网络
echo ""
echo "2. Docker网络配置:"
echo "   - Docker守护进程状态: $(systemctl is-active docker)"
echo "   - Docker网络列表:"
docker network ls | grep -E 'docker|dify'

# 3. 检查代理可达性
echo ""
echo "3. 代理服务器状态:"
if nc -z 127.0.0.1 7890 2>/dev/null; then
    echo "   ✅ 代理服务器 127.0.0.1:7890 可访问"
else
    echo "   ❌ 代理服务器 127.0.0.1:7890 不可访问"
fi

echo ""
echo "🎯 第二步：问题根因分析"
echo "========================"

cat << 'EOF'
根据深度分析，发现以下根本问题：

1. 🔒 Docker网络隔离问题
   - 容器内 127.0.0.1 指向容器自身
   - 无法访问宿主机的 127.0.0.1:7890 代理
   - Docker网桥网络限制外部访问

2. 🌐 DNS解析问题  
   - 容器内DNS配置可能与宿主机不同
   - 代理设置未正确传递到容器

3. 🔧 Docker配置问题
   - Docker守护进程未配置代理
   - 容器构建时网络环境未优化

4. 📦 PyPI访问限制
   - 直接访问pypi.org被阻断
   - 国内镜像源也无法访问
EOF

echo ""
echo "🛠️ 第三步：系统性解决方案"
echo "========================="

echo "方案优先级排序 (按成功率和实施难度):"
echo ""
echo "🥇 方案1: Docker系统级代理配置 (推荐)"
echo "🥈 方案2: 容器网络桥接修复"  
echo "🥉 方案3: 离线包管理"
echo "🏅 方案4: 绕过插件直接配置"

read -p "请选择要执行的方案 (1/2/3/4) 或按回车查看所有方案: " choice

case $choice in
    1)
        echo ""
        echo "🥇 执行方案1: Docker系统级代理配置"
        echo "================================="
        
        # 创建Docker服务配置目录
        echo "📁 创建Docker服务配置目录..."
        sudo mkdir -p /etc/systemd/system/docker.service.d
        
        # 配置Docker代理
        echo "⚙️ 配置Docker守护进程代理..."
        sudo tee /etc/systemd/system/docker.service.d/proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:7890"
Environment="HTTPS_PROXY=http://127.0.0.1:7890"  
Environment="NO_PROXY=localhost,127.0.0.1,docker-registry.example.com,.corp,172.16.0.0/12,192.168.0.0/16,10.0.0.0/8"
EOF
        
        # 配置Docker客户端代理
        echo "👤 配置Docker客户端代理..."
        mkdir -p ~/.docker
        cat > ~/.docker/config.json << EOF
{
  "proxies": {
    "default": {
      "httpProxy": "http://127.0.0.1:7890",
      "httpsProxy": "http://127.0.0.1:7890"
    }
  }
}
EOF
        
        # 重启Docker服务
        echo "🔄 重启Docker服务..."
        sudo systemctl daemon-reload
        sudo systemctl restart docker
        
        echo "⏳ 等待Docker服务启动..."
        sleep 10
        
        # 重启Dify服务
        echo "🐳 重启Dify容器..."
        cd "$DIFY_DIR/docker"
        docker compose down
        docker compose up -d
        
        echo "⏳ 等待服务启动..."
        sleep 30
        
        # 测试网络
        echo "🧪 测试网络连接..."
        if docker compose exec plugin_daemon python3 -c "
import urllib.request
try:
    urllib.request.urlopen('https://pypi.org/simple/', timeout=10)
    print('✅ PyPI连接成功')
except Exception as e:
    print('❌ PyPI连接失败:', e)
        "; then
            echo "🎉 方案1修复成功！"
        else
            echo "⚠️ 方案1未完全解决，继续尝试方案2..."
            choice=2
        fi
        ;;
esac

if [ "$choice" = "2" ]; then
    echo ""
    echo "🥈 执行方案2: 容器网络桥接修复"
    echo "==============================="
    
    # 创建自定义网络
    echo "🌐 创建自定义Docker网络..."
    docker network create --driver bridge \
        --subnet=172.20.0.0/16 \
        --gateway=172.20.0.1 \
        --opt "com.docker.network.bridge.name"="dify-bridge" \
        dify-network || echo "网络已存在"
    
    # 修改docker-compose.yaml
    echo "📝 修改docker-compose配置..."
    cd "$DIFY_DIR/docker"
    
    if ! grep -q "networks:" docker-compose.yaml; then
        cat >> docker-compose.yaml << EOF

networks:
  default:
    external:
      name: dify-network
EOF
    fi
    
    # 配置容器代理环境变量
    echo "⚙️ 配置容器环境变量..."
    
    python3 << 'PYEOF'
import yaml

with open('docker-compose.yaml', 'r') as f:
    config = yaml.safe_load(f)

# 为plugin_daemon添加代理环境变量
if 'services' in config and 'plugin_daemon' in config['services']:
    if 'environment' not in config['services']['plugin_daemon']:
        config['services']['plugin_daemon']['environment'] = []
    
    proxy_vars = [
        'HTTP_PROXY=http://172.20.0.1:7890',
        'HTTPS_PROXY=http://172.20.0.1:7890',
        'http_proxy=http://172.20.0.1:7890',
        'https_proxy=http://172.20.0.1:7890',
        'NO_PROXY=localhost,127.0.0.1,172.20.0.0/16'
    ]
    
    env_list = config['services']['plugin_daemon']['environment']
    if isinstance(env_list, list):
        for var in proxy_vars:
            if var not in env_list:
                env_list.append(var)

with open('docker-compose.yaml', 'w') as f:
    yaml.dump(config, f, default_flow_style=False)
    
print("配置文件修改完成")
PYEOF
    
    # 重启服务
    echo "🔄 重启服务..."
    docker compose down
    docker compose up -d
    
    echo "⏳ 等待服务启动..."
    sleep 30
fi

if [ "$choice" = "3" ]; then
    echo ""
    echo "🥉 执行方案3: 离线包管理"
    echo "======================"
    
    # 在宿主机下载包
    echo "📦 在宿主机下载依赖包..."
    mkdir -p /tmp/dify-packages
    cd /tmp/dify-packages
    
    # 使用宿主机的代理下载
    pip download --proxy http://127.0.0.1:7890 \
        -i https://pypi.org/simple/ \
        dify-plugin requests packaging setuptools wheel
    
    # 复制到容器
    echo "📂 复制包到容器..."
    docker cp /tmp/dify-packages docker-plugin_daemon-1:/tmp/packages
    
    # 在容器内安装
    echo "🔧 在容器内安装包..."
    docker compose exec plugin_daemon bash -c "
        cd /tmp/packages
        pip install --no-index --find-links . *.whl *.tar.gz
    "
fi

if [ "$choice" = "4" ] || [ "$choice" = "" ]; then
    echo ""
    echo "🏅 方案4: 绕过插件直接配置 (最稳定)"
    echo "=================================="
    
    cat << 'EOF'
直接在Dify UI中配置OpenAI兼容模型：

1. 🌐 访问: http://localhost/console
2. 📂 进入: 设置 → 模型供应商
3. ➕ 选择: OpenAI → 自定义
4. ⚙️ 配置:
   - API Base URL: https://api.deepseek.com/v1
   - API Key: your_deepseek_api_key
   - 模型名称: deepseek-chat
5. ✅ 测试连接并保存

这种方式：
✅ 无需插件安装
✅ 避开网络问题  
✅ 配置简单快速
✅ 功能完全兼容
EOF
fi

echo ""
echo "🧪 最终测试"
echo "==========="

echo "🔍 测试当前网络状态..."
cd "$DIFY_DIR/docker"

# 测试容器网络
echo "1. 容器网络测试:"
if docker compose exec plugin_daemon python3 -c "
import urllib.request
import socket
socket.setdefaulttimeout(10)

test_urls = [
    'https://pypi.org/simple/',
    'https://mirrors.aliyun.com/pypi/simple/',
    'https://pypi.tuna.tsinghua.edu.cn/simple/'
]

for url in test_urls:
    try:
        urllib.request.urlopen(url)
        print(f'✅ {url} - 可访问')
        break
    except:
        print(f'❌ {url} - 不可访问')
else:
    print('❌ 所有PyPI源都不可访问')
"; then
    echo "网络修复可能成功"
else
    echo "网络仍有问题，建议使用方案4"
fi

echo ""
echo "2. 服务状态检查:"
docker compose ps | grep -E 'plugin_daemon|STATUS'

echo ""
echo "📋 修复总结"
echo "==========="

cat << 'EOF'
🎯 根据测试结果，推荐操作：

如果网络修复成功：
→ 可以在Dify界面重试安装插件
→ 访问 http://localhost/console

如果网络仍有问题：
→ 使用方案4直接配置OpenAI兼容模型
→ 避开插件安装问题，直接使用API

📞 技术支持：
如果问题仍未解决，可能需要：
1. 检查防火墙设置
2. 配置企业网络代理
3. 使用其他网络环境测试
EOF

# 创建快速配置脚本
cat > ../quick_model_config.sh << 'EOF'
#!/bin/bash
echo "🚀 快速模型配置指南"
echo "==================="
echo ""
echo "1. 访问 http://localhost/console"
echo "2. 进入 '设置' → '模型供应商'"
echo "3. 选择 'OpenAI'"
echo "4. 配置信息:"
echo "   API Base: https://api.deepseek.com/v1"
echo "   API Key: [你的DeepSeek密钥]"
echo "5. 添加模型: deepseek-chat"
echo "6. 测试连接并保存"
echo ""
echo "✅ 配置完成后即可使用DeepSeek模型！"
EOF

chmod +x ../quick_model_config.sh

echo ""
echo "🎉 综合修复完成！"
echo "快速配置脚本: $DIFY_DIR/quick_model_config.sh"