#!/bin/bash
# 永久修复插件daemon的网络问题

set -e

echo "🔧 Dify插件永久修复脚本"
echo "======================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: 清理docker-compose中的代理变量（如果存在）
echo -e "\n${GREEN}[1/4]${NC} 配置docker-compose环境..."

# 创建override文件来清除代理
cat > docker-compose.override.yml << 'EOF'
version: "3.5"
services:
  plugin_daemon:
    environment:
      # 清除所有代理设置
      HTTP_PROXY: ""
      HTTPS_PROXY: ""
      http_proxy: ""
      https_proxy: ""
      ALL_PROXY: ""
      all_proxy: ""
      NO_PROXY: "*"
      no_proxy: "*"
      # 使用阿里云PyPI镜像
      PIP_INDEX_URL: "https://mirrors.aliyun.com/pypi/simple/"
      PIP_TRUSTED_HOST: "mirrors.aliyun.com"
EOF

echo "✅ docker-compose.override.yml已创建"

# Step 2: 重启插件容器
echo -e "\n${GREEN}[2/4]${NC} 重启插件容器..."
docker compose down plugin_daemon
docker compose up -d plugin_daemon

# 等待容器启动
sleep 10

# Step 3: 验证环境
echo -e "\n${GREEN}[3/4]${NC} 验证环境配置..."
docker exec docker-plugin_daemon-1 sh -c '
echo "代理环境变量检查:"
env | grep -i proxy | grep -v "NO_PROXY" | grep -v "=" || echo "✅ 无代理设置"
echo ""
echo "PyPI配置:"
echo "PIP_INDEX_URL=$PIP_INDEX_URL"
'

# Step 4: 测试安装
echo -e "\n${GREEN}[4/4]${NC} 测试OpenAI包安装..."
docker exec docker-plugin_daemon-1 sh -c '
pip install openai==1.64.0 --no-cache-dir --timeout 60 && echo "✅ OpenAI包安装成功！"
'

echo -e "\n${GREEN}✅ 修复完成！${NC}"
echo "现在可以在Dify控制台重新安装OpenAI插件了。"
echo ""
echo "提示："
echo "1. 访问 http://localhost/apps"
echo "2. 进入设置 → 插件管理"
echo "3. 搜索并安装OpenAI插件"