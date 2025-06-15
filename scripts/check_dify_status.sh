#!/bin/bash
echo "检查Dify服务状态..."

# 检查容器
echo -e "\n--- Docker容器状态 ---"
if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "docker-"; then
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep "docker-"
else
    echo "暂无Dify容器运行"
fi

# 检查Web服务
echo -e "\n--- Web服务检查 ---"
timeout 5 curl -s http://localhost > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Web UI 可访问: http://localhost"
else
    echo "⏳ Web UI 还在启动中..."
fi

# 检查API服务
echo -e "\n--- API服务检查 ---"
timeout 5 curl -s http://localhost:5000/health > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ API 服务就绪: http://localhost:5000"
else
    echo "⏳ API 服务还在启动中..."
fi

# 检查服务日志
echo -e "\n--- 服务状态概览 ---"
if [ -d "/home/qinshu/douyin-analytics/dify/docker" ]; then
    cd /home/qinshu/douyin-analytics/dify/docker
    if [ -f "docker-compose.yml" ]; then
        docker compose ps 2>/dev/null || echo "Dify尚未部署"
    else
        echo "Dify配置文件不存在"
    fi
else
    echo "Dify目录不存在，尚未开始部署"
fi