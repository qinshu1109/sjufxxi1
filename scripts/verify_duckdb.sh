#!/bin/bash
echo "=== DuckDB数据库验证 ==="
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DB_PATH="$PROJECT_DIR/data/db/analytics.duckdb"

# 检查文件
if [ -f "$DB_PATH" ]; then
    echo "✅ 数据库文件存在: $DB_PATH"
    echo "文件大小: $(ls -lh $DB_PATH | awk '{print $5}')"
else
    echo "❌ 数据库文件不存在!"
    exit 1
fi

# 测试连接
echo -e "\n--- 测试数据库连接 ---"
if duckdb $DB_PATH "SELECT 'Connected' as status;" 2>/dev/null | grep -q "Connected"; then
    echo "✅ 数据库连接成功"
else
    echo "❌ 数据库连接失败"
    exit 1
fi

# 显示表信息
echo -e "\n--- 数据库表信息 ---"
duckdb $DB_PATH ".tables"

# 显示数据统计
echo -e "\n--- 数据统计 ---"
duckdb $DB_PATH "SELECT COUNT(*) as 总记录数, MAX(sales_volume) as 最高销量, SUM(sales_amount) as 总销售额 FROM douyin_products;"

echo -e "\n✅ DuckDB验证完成！"