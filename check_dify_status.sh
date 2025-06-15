#!/bin/bash
# Dify服务状态检查脚本

echo "🔍 Dify服务状态检查"
echo "==================="

cd /home/qinshu/douyin-analytics/dify/docker

# 检查容器状态
echo "📊 容器状态:"
docker compose ps

echo ""
echo "🌐 服务连接测试:"

# 测试Web界面
if curl -s http://localhost > /dev/null; then
    echo "✅ Web界面: http://localhost - 可访问"
else
    echo "❌ Web界面: 不可访问"
fi

# 测试API
api_response=$(curl -s http://localhost/console/api/setup)
if [[ $api_response == *"setup_at"* ]]; then
    echo "✅ API服务: http://localhost/console/api - 已设置完成"
elif [[ $api_response == *"not_setup"* ]]; then
    echo "⚠️  API服务: 需要初始化设置"
else
    echo "❌ API服务: 不可访问"
fi

# 测试数据库连接
if docker compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ PostgreSQL数据库: 连接正常"
else
    echo "❌ PostgreSQL数据库: 连接失败"
fi

# 测试Redis连接
if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis缓存: 连接正常"
else
    echo "❌ Redis缓存: 连接失败"
fi

echo ""
echo "🔗 访问链接:"
echo "主界面: http://localhost"
echo "登录页面: http://localhost/signin"
echo "管理后台: http://localhost/console"

echo ""
echo "📋 服务端口:"
echo "Web: 80 (HTTP)"
echo "API: 内部5001"
echo "插件: 5003"

if [[ $api_response == *"setup_at"* ]]; then
    echo ""
    echo "🎉 Dify平台已完全配置，可以正常使用！"
    echo "💡 下一步: 访问 http://localhost/signin 登录使用"
fi