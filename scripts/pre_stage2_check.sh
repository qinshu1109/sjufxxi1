#!/bin/bash
echo "=== 第二阶段前置检查 ==="

# 1. 检查Docker
echo -n "Docker状态: "
if docker info >/dev/null 2>&1; then
    echo "✅ 运行中 ($(docker --version | cut -d' ' -f3))"
else
    echo "❌ 未运行"
fi

# 2. 检查端口
for port in 80 5000 5432 6379; do
    echo -n "端口 $port: "
    if ! ss -tuln | grep -q ":$port "; then
        echo "✅ 可用"
    else
        echo "❌ 被占用 ($(ss -tuln | grep ":$port " | head -1))"
    fi
done

# 3. 检查内存
echo -n "可用内存: "
free -h | grep Mem | awk '{print "总计:" $2 " 可用:" $7}'

# 4. 检查磁盘空间
echo -n "磁盘空间: "
df -h . | tail -1 | awk '{print "可用:" $4 " 使用率:" $5}'

# 5. 检查DuckDB
echo -n "DuckDB数据库: "
if [ -f "/home/qinshu/douyin-analytics/data/db/analytics.duckdb" ]; then
    echo "✅ 存在 ($(duckdb /home/qinshu/douyin-analytics/data/db/analytics.duckdb "SELECT COUNT(*) FROM douyin_products;" | tail -1 | sed 's/│//g' | xargs)条记录)"
else
    echo "❌ 不存在"
fi

# 6. 检查API Key
echo -n "DeepSeek API: "
if grep -q "sk-3f07e058c2aa487a90af6acd5e3cadc7" /home/qinshu/douyin-analytics/config/dify_env.txt; then
    echo "✅ 已配置"
else
    echo "❌ 未配置"
fi

# 7. 检查网络连接
echo -n "外网连接: "
if timeout 3 curl -s https://api.deepseek.com >/dev/null 2>&1; then
    echo "✅ 正常"
else
    echo "⚠️  检查网络连接"
fi

echo -e "\n=== 检查完成 ==="