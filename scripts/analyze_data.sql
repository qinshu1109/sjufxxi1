-- 抖音电商数据分析SQL查询集合

-- 1. 销量TOP10商品
.print "=== 销量TOP10商品 ==="
SELECT 
    title,
    sales_volume,
    sales_amount,
    shop_name,
    category
FROM douyin_products 
ORDER BY sales_volume DESC 
LIMIT 10;

-- 2. 各类目销售情况
.print "\n=== 各类目销售统计 ==="
SELECT * FROM sales_summary ORDER BY total_sales_amount DESC;

-- 3. 近7天销量增长趋势（模拟）
.print "\n=== 销量趋势分析 ==="
SELECT 
    created_date,
    COUNT(*) as product_count,
    SUM(sales_volume) as daily_sales_volume,
    SUM(sales_amount) as daily_sales_amount,
    AVG(rating) as avg_rating
FROM douyin_products 
WHERE created_date >= DATE('now', '-7 days')
GROUP BY created_date
ORDER BY created_date;

-- 4. 高销量商品的直播信息
.print "\n=== 高销量商品直播信息 ==="
SELECT 
    title,
    sales_volume,
    live_room_title,
    anchor_name,
    start_time,
    end_time
FROM douyin_products 
WHERE sales_volume > 1000
ORDER BY sales_volume DESC;

-- 5. 价格区间分析
.print "\n=== 价格区间分析 ==="
SELECT 
    CASE 
        WHEN price < 50 THEN '0-50元'
        WHEN price < 100 THEN '50-100元'
        WHEN price < 200 THEN '100-200元'
        WHEN price < 500 THEN '200-500元'
        ELSE '500元以上'
    END as price_range,
    COUNT(*) as product_count,
    SUM(sales_volume) as total_sales,
    AVG(rating) as avg_rating
FROM douyin_products
GROUP BY price_range
ORDER BY AVG(price);