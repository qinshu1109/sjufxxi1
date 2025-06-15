#!/bin/bash
# 插件安装临时解决方案

echo "🔧 插件安装临时解决方案"
echo "========================="

echo "方案1: 临时网络桥接（高级用户）"
echo "sudo docker run --rm --net=host -v /var/run/docker.sock:/var/run/docker.sock alpine/socat tcp-listen:3128,reuseaddr,fork tcp:127.0.0.1:7890 &"

echo ""
echo "方案2: 使用外部PyPI缓存服务"
echo "docker run -d --name pypi-cache -p 3141:3141 pypiserver/pypiserver:latest"

echo ""
echo "方案3: 手动下载并安装插件文件（最可靠）"
echo "1. 从GitHub下载插件源码"
echo "2. 手动复制到插件目录"
echo "3. 重启插件服务"

echo ""
echo "💡 推荐：直接使用OpenAI兼容配置，避开插件安装问题"