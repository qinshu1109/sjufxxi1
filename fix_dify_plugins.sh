#!/bin/bash
# Dify插件错误修复脚本

set -e

# 加载环境配置
source "$(dirname "$0")/load_env.sh"

echo "🔧 修复Dify插件安装错误..."

cd "$DIFY_DIR"

# 1. 检查Dify服务状态
echo "📊 检查Dify服务状态..."
cd docker

# 确定使用的compose命令
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Docker Compose未安装"
    exit 1
fi

# 检查容器状态
echo "🐳 当前容器状态:"
$COMPOSE_CMD ps || true

# 2. 重启相关服务
echo "🔄 重启插件相关服务..."

# 停止所有服务
echo "⏹️  停止所有服务..."
$COMPOSE_CMD down || true

# 清理插件相关容器和数据
echo "🧹 清理插件缓存..."
docker volume prune -f || true
docker system prune -f || true

# 3. 修复插件守护进程配置
echo "🔧 修复插件守护进程配置..."

# 检查并修复 .env 配置
if grep -q "PLUGIN_ENABLED" .env; then
    echo "📝 更新插件配置..."
    sed -i 's/PLUGIN_ENABLED=false/PLUGIN_ENABLED=true/g' .env
else
    echo "📝 添加插件配置..."
    cat >> .env << EOF

# Plugin Configuration
PLUGIN_ENABLED=true
PLUGIN_DEBUG=false
PLUGIN_LOG_LEVEL=INFO
EOF
fi

# 4. 检查插件相关端口
echo "🔍 检查插件端口..."
plugin_ports=(5003 5004 5005)
for port in "${plugin_ports[@]}"; do
    if ss -tuln | grep -q ":$port "; then
        echo "⚠️  端口 $port 被占用，尝试释放..."
        sudo lsof -ti:$port | xargs -r sudo kill -9 || true
    fi
done

# 5. 重新启动服务
echo "🚀 重新启动Dify服务..."
$COMPOSE_CMD up -d

# 等待服务启动
echo "⏳ 等待服务启动（30秒）..."
sleep 30

# 6. 验证插件服务
echo "✅ 验证插件服务状态..."

# 检查容器状态
echo "📊 容器状态:"
$COMPOSE_CMD ps

# 检查API健康状态
echo "🏥 检查API健康状态..."
if curl -s http://localhost:5001/health > /dev/null 2>&1; then
    echo "✅ Dify API服务正常"
else
    echo "⚠️  Dify API服务可能需要更多时间启动"
fi

# 检查Web界面
if curl -s http://localhost > /dev/null 2>&1; then
    echo "✅ Dify Web界面可访问"
else
    echo "⚠️  Dify Web界面可能需要更多时间启动"
fi

# 7. 提供插件安装指南
echo ""
echo "📋 插件安装修复完成！"
echo "================================"
echo ""
echo "🔧 插件问题解决方案:"
echo "1. 访问 http://localhost 进入Dify管理界面"
echo "2. 进入设置 -> 扩展程序 -> 插件"
echo "3. 如果仍有错误，尝试以下步骤:"
echo "   - 刷新页面"
echo "   - 清除浏览器缓存"
echo "   - 重启Docker服务: $COMPOSE_CMD restart"
echo ""
echo "🔍 故障排查:"
echo "- 查看日志: $COMPOSE_CMD logs api"
echo "- 查看插件日志: $COMPOSE_CMD logs | grep plugin"
echo "- 检查端口占用: ss -tuln | grep ':500[0-9]'"
echo ""
echo "💡 如果插件功能仍有问题，可能需要:"
echo "1. 更新Dify到最新版本"
echo "2. 检查系统资源（内存、磁盘空间）"
echo "3. 重置插件配置"

# 8. 创建插件重置脚本
cat > ../reset_plugins.sh << 'EOF'
#!/bin/bash
# 插件完全重置脚本

echo "🔄 重置Dify插件..."
cd "$(dirname "$0")/docker"

# 停止服务
docker compose down

# 删除插件相关数据卷
docker volume rm $(docker volume ls -q | grep dify.*plugin) 2>/dev/null || true

# 重新启动
docker compose up -d

echo "✅ 插件重置完成"
EOF

chmod +x ../reset_plugins.sh

echo "✅ 插件修复脚本执行完成！"
echo "📁 额外工具: $DIFY_DIR/reset_plugins.sh （插件完全重置）"