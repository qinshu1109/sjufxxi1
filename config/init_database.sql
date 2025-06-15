-- 蝉妈妈抖音电商数据表结构
CREATE TABLE IF NOT EXISTS douyin_products (
    id BIGINT PRIMARY KEY,
    product_id VARCHAR,
    title VARCHAR,
    price DECIMAL(10,2),
    sales_volume INTEGER,
    sales_amount DECIMAL(15,2),
    shop_name VARCHAR,
    category VARCHAR,
    brand VARCHAR,
    rating DECIMAL(3,2),
    comments_count INTEGER,
    live_room_title VARCHAR,
    anchor_name VARCHAR,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    created_date DATE,
    updated_date TIMESTAMP DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_products_date ON douyin_products(created_date);
CREATE INDEX IF NOT EXISTS idx_products_category ON douyin_products(category);
CREATE INDEX IF NOT EXISTS idx_products_sales ON douyin_products(sales_volume);
CREATE INDEX IF NOT EXISTS idx_products_sales_amount ON douyin_products(sales_amount);

-- 插入真实测试数据
INSERT OR REPLACE INTO douyin_products VALUES
(1, 'DY001', '【直播专享】护肤品三件套', 299.90, 1520, 455848.00, '美妆旗舰店', '美妆护肤', '兰蔻', 4.8, 892, '美妆达人直播间', '美妆小雅', '2025-06-15 20:00:00', '2025-06-15 22:00:00', '2025-06-15', NOW()),
(2, 'DY002', '夏季爆款连衣裙', 189.50, 856, 162202.00, '时尚女装店', '服装鞋帽', '韩都衣舍', 4.6, 445, '时尚穿搭直播', '时尚达人Anna', '2025-06-15 19:30:00', '2025-06-15 21:30:00', '2025-06-15', NOW()),
(3, 'DY003', '透明手机壳爆款', 29.90, 3240, 96876.00, '数码配件专营', '数码配件', '小米', 4.9, 1567, '数码好物推荐', '科技小王', '2025-06-15 21:00:00', '2025-06-15 23:00:00', '2025-06-15', NOW()),
(4, 'DY004', '每日坚果礼盒装', 128.00, 674, 86272.00, '健康食品店', '食品饮料', '三只松鼠', 4.7, 298, '健康生活分享', '健康小贴士', '2025-06-15 18:00:00', '2025-06-15 20:00:00', '2025-06-15', NOW()),
(5, 'DY005', '智能哑铃套装', 458.00, 234, 107172.00, '运动用品店', '运动户外', 'Keep', 4.5, 156, '健身器材推荐', '健身教练Mike', '2025-06-15 20:30:00', '2025-06-15 22:30:00', '2025-06-15', NOW()),
(6, 'DY006', '网红零食大礼包', 88.80, 2156, 191404.80, '零食小铺', '食品饮料', '良品铺子', 4.6, 1023, '零食试吃直播', '吃货小美', '2025-06-14 19:00:00', '2025-06-14 21:00:00', '2025-06-14', NOW()),
(7, 'DY007', '婴儿纸尿裤超值装', 198.00, 567, 112266.00, '母婴专营店', '母婴用品', '花王', 4.9, 234, '母婴用品推荐', '辣妈团长', '2025-06-14 20:00:00', '2025-06-14 22:00:00', '2025-06-14', NOW()),
(8, 'DY008', '蓝牙耳机性价比王', 159.00, 1834, 291606.00, '数码旗舰店', '数码配件', '小米', 4.4, 876, '数码产品测评', '数码狂人', '2025-06-14 21:30:00', '2025-06-14 23:30:00', '2025-06-14', NOW());

-- 创建销售统计视图
CREATE VIEW sales_summary AS
SELECT 
    category,
    COUNT(*) as product_count,
    SUM(sales_volume) as total_sales_volume,
    SUM(sales_amount) as total_sales_amount,
    AVG(price) as avg_price,
    AVG(rating) as avg_rating
FROM douyin_products 
GROUP BY category;

SELECT '✅ 数据库初始化完成，已插入 ' || COUNT(*) || ' 条测试数据' as status FROM douyin_products;
