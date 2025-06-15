#!/bin/bash
# 测试数据导入脚本

set -e

echo "📥 导入测试数据到DuckDB..."

# 获取项目目录
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DB_PATH="$PROJECT_DIR/data/db/analytics.duckdb"
CSV_PATH="$PROJECT_DIR/data/csv/douyin_test_data_30days.csv"

# 检查文件是否存在
if [ ! -f "$CSV_PATH" ]; then
    echo "❌ 测试数据文件不存在: $CSV_PATH"
    echo "💡 请先运行: python3 scripts/generate_test_data.py"
    exit 1
fi

echo "📁 数据文件: $CSV_PATH"
echo "🗄️ 数据库: $DB_PATH"

# 确保数据库目录存在
mkdir -p "$(dirname "$DB_PATH")"

# 导入数据并创建表结构
echo "🔄 正在创建表和导入数据..."

duckdb "$DB_PATH" << SQL
-- 删除旧表（如果存在）
DROP TABLE IF EXISTS douyin_sales_detail;
DROP TABLE IF EXISTS douyin_products;

-- 创建销售明细表
CREATE TABLE douyin_sales_detail AS 
SELECT 
    CAST(date AS DATE) as date,
    sku,
    product_name,
    category,
    commission_rate,
    brand,
    daily_sales,
    daily_revenue,
    live_sales,
    card_sales,
    conversion_rate,
    avg_price,
    clicks,
    exposure,
    ctr,
    day_of_week,
    is_weekend
FROM read_csv_auto('$CSV_PATH');

-- 创建产品信息表
CREATE TABLE douyin_products AS
SELECT DISTINCT
    sku,
    product_name,
    category,
    brand,
    commission_rate
FROM douyin_sales_detail;

-- 创建索引
CREATE INDEX idx_sales_date ON douyin_sales_detail(date);
CREATE INDEX idx_sales_sku ON douyin_sales_detail(sku);
CREATE INDEX idx_sales_brand ON douyin_sales_detail(brand);
CREATE INDEX idx_sales_category ON douyin_sales_detail(category);
CREATE INDEX idx_products_sku ON douyin_products(sku);

-- 数据验证查询
SELECT 
    '基础统计' as metric,
    CAST(COUNT(*) AS VARCHAR) as value1,
    CAST(COUNT(DISTINCT sku) AS VARCHAR) as value2,
    CAST(MIN(date) AS VARCHAR) as value3,
    CAST(MAX(date) AS VARCHAR) as value4
FROM douyin_sales_detail

UNION ALL

SELECT 
    '销售统计' as metric,
    CAST(SUM(daily_sales) AS VARCHAR) as value1,
    CAST(COUNT(DISTINCT brand) AS VARCHAR) as value2,
    CAST(ROUND(AVG(daily_sales), 0) AS VARCHAR) as value3,
    CAST(ROUND(SUM(daily_revenue), 2) AS VARCHAR) as value4
FROM douyin_sales_detail

UNION ALL

SELECT 
    '异常检测' as metric,
    CAST(COUNT(*) AS VARCHAR) as value1,
    '高销量天数' as value2,
    '(>5000)' as value3,
    '' as value4
FROM douyin_sales_detail 
WHERE daily_sales > 5000;

-- 展示销售趋势
SELECT 
    sku,
    LEFT(product_name, 30) || '...' as product_name,
    SUM(daily_sales) as total_sales,
    ROUND(AVG(daily_sales), 0) as avg_sales,
    MAX(daily_sales) as peak_sales,
    ROUND(SUM(daily_revenue), 2) as total_revenue
FROM douyin_sales_detail
GROUP BY sku, product_name
ORDER BY total_sales DESC;

SQL

if [ $? -eq 0 ]; then
    echo "✅ 数据导入完成！"
    echo ""
    echo "📊 数据库表："
    echo "  - douyin_sales_detail: 销售明细数据"
    echo "  - douyin_products: 产品基础信息"
    echo ""
    echo "🔍 验证查询："
    echo "  duckdb $DB_PATH \"SELECT COUNT(*) FROM douyin_sales_detail\""
    echo "  duckdb $DB_PATH \"SELECT * FROM douyin_sales_detail LIMIT 5\""
else
    echo "❌ 数据导入失败！"
    exit 1
fi