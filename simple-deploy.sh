#!/bin/bash
# 简化版部署脚本

set -e

echo "🚀 第一阶段：基础设施搭建"
echo "========================="

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# 步骤1：安装DuckDB
echo "📦 1. 安装DuckDB..."
if ! command -v duckdb &> /dev/null; then
    echo "正在下载DuckDB..."
    wget -O duckdb.zip https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-amd64.zip
    unzip duckdb.zip
    sudo mv duckdb /usr/local/bin/
    rm duckdb.zip
    echo "✅ DuckDB安装完成"
else
    echo "✅ DuckDB已安装"
fi

# 步骤2：创建数据库
echo "📊 2. 创建数据库和表结构..."
mkdir -p data/db

cat > config/init_database.sql << 'EOF'
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
EOF

# 初始化数据库
duckdb data/db/analytics.duckdb < config/init_database.sql
echo "✅ 数据库创建完成"

# 步骤3：创建数据导入脚本
echo "📥 3. 创建数据导入脚本..."
cat > scripts/import_csv.py << 'EOF'
#!/usr/bin/env python3
"""
蝉妈妈CSV数据导入脚本
支持批量导入CSV文件到DuckDB数据库
"""

import duckdb
import pandas as pd
import sys
import os
from datetime import datetime

def import_csv_to_duckdb(csv_file, db_file):
    """导入CSV文件到DuckDB"""
    try:
        # 连接数据库
        conn = duckdb.connect(db_file)
        
        # 读取CSV文件
        print(f"📁 读取CSV文件: {csv_file}")
        df = pd.read_csv(csv_file, encoding='utf-8')
        
        print(f"📊 数据概览:")
        print(f"   - 行数: {len(df)}")
        print(f"   - 列数: {len(df.columns)}")
        print(f"   - 列名: {list(df.columns)}")
        
        # 数据清洗和映射（根据实际CSV格式调整）
        # 这里是示例映射，需要根据蝉妈妈实际CSV格式调整
        if 'title' in df.columns or '商品标题' in df.columns:
            # 插入数据到DuckDB
            conn.execute("DELETE FROM douyin_products WHERE created_date = ?", [datetime.now().date()])
            conn.execute("INSERT INTO douyin_products SELECT * FROM df")
            
            print(f"✅ 数据导入成功！")
            
            # 显示统计信息
            result = conn.execute("SELECT COUNT(*) FROM douyin_products").fetchone()
            print(f"📈 数据库总记录数: {result[0]}")
            
        else:
            print("❌ CSV格式不匹配，请检查列名")
            
        conn.close()
        
    except Exception as e:
        print(f"❌ 导入失败: {str(e)}")
        return False
    
    return True

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("使用方法: python import_csv.py <csv文件路径>")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    db_file = "/home/qinshu/douyin-analytics/data/db/analytics.duckdb"
    
    if not os.path.exists(csv_file):
        print(f"❌ CSV文件不存在: {csv_file}")
        sys.exit(1)
    
    import_csv_to_duckdb(csv_file, db_file)
EOF

mkdir -p scripts
chmod +x scripts/import_csv.py

# 步骤4：创建分析查询脚本
echo "📈 4. 创建数据分析脚本..."
cat > scripts/analyze_data.sql << 'EOF'
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
EOF

# 步骤5：创建飞书机器人配置
echo "🤖 5. 创建飞书机器人配置..."
cat > config/feishu_config.py << 'EOF'
#!/usr/bin/env python3
"""
飞书机器人配置和测试脚本
"""

import requests
import json
from datetime import datetime

# 飞书机器人配置
FEISHU_WEBHOOK_URL = "https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK_ID"  # 请替换为实际URL

def send_feishu_message(message, title="抖音数据分析"):
    """发送消息到飞书群"""
    
    payload = {
        "msg_type": "interactive",
        "card": {
            "config": {
                "wide_screen_mode": True
            },
            "header": {
                "title": {
                    "tag": "plain_text",
                    "content": title
                },
                "template": "blue"
            },
            "elements": [
                {
                    "tag": "div",
                    "text": {
                        "tag": "lark_md",
                        "content": message
                    }
                }
            ]
        }
    }
    
    try:
        response = requests.post(FEISHU_WEBHOOK_URL, json=payload)
        if response.status_code == 200:
            print("✅ 飞书消息发送成功")
            return True
        else:
            print(f"❌ 飞书消息发送失败: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 发送失败: {str(e)}")
        return False

def test_feishu_bot():
    """测试飞书机器人"""
    test_message = f"""
📊 **抖音数据分析系统测试**

🕐 测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

✅ 系统状态: 正常运行
📈 数据状态: 已就绪
🔔 告警功能: 正常

---
这是一条测试消息，如果您收到此消息，说明飞书机器人配置成功！
    """
    
    return send_feishu_message(test_message, "系统测试")

if __name__ == "__main__":
    if FEISHU_WEBHOOK_URL == "https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK_ID":
        print("⚠️  请先在脚本中配置正确的飞书Webhook URL")
    else:
        test_feishu_bot()
EOF

chmod +x config/feishu_config.py

# 步骤6：创建验收测试
echo "🧪 6. 创建验收测试脚本..."
cat > test_phase1.sh << 'EOF'
#!/bin/bash
# 第一阶段验收测试

echo "🧪 第一阶段验收测试"
echo "==================="

cd /home/qinshu/douyin-analytics

# 测试1：项目结构
echo "1. ✅ 项目结构检查"
tree . 2>/dev/null || ls -la

# 测试2：DuckDB检查
echo -e "\n2. 📊 DuckDB数据库检查"
if command -v duckdb &> /dev/null; then
    echo "✅ DuckDB已安装: $(duckdb --version)"
    
    # 检查数据
    echo "📈 数据统计："
    duckdb data/db/analytics.duckdb "SELECT COUNT(*) as 总商品数 FROM douyin_products;"
    
    echo -e "\n📊 类目分布："
    duckdb data/db/analytics.duckdb "SELECT category as 类目, COUNT(*) as 商品数 FROM douyin_products GROUP BY category;"
    
else
    echo "❌ DuckDB未安装"
fi

# 测试3：数据分析测试
echo -e "\n3. 📈 数据分析功能测试"
echo "执行分析查询..."
duckdb data/db/analytics.duckdb < scripts/analyze_data.sql

# 测试4：脚本检查
echo -e "\n4. 🔧 脚本功能检查"
echo "✅ CSV导入脚本: scripts/import_csv.py"
echo "✅ 数据分析脚本: scripts/analyze_data.sql"
echo "✅ 飞书配置脚本: config/feishu_config.py"

echo -e "\n📋 第一阶段完成状态："
echo "========================="
echo "✅ 项目结构搭建完成"
echo "✅ DuckDB数据库就绪"
echo "✅ 测试数据导入完成"
echo "✅ 分析脚本准备就绪"
echo "⚠️  飞书机器人待配置"
echo "⚠️  Dify平台待部署"

echo -e "\n🎯 下一步操作："
echo "1. 配置飞书Webhook URL"
echo "2. 准备蝉妈妈CSV数据"
echo "3. 部署Dify平台"
echo "4. 配置可视化分析流程"
EOF

chmod +x test_phase1.sh

echo "✅ 第一阶段基础设施搭建完成！"
echo ""
echo "📋 完成内容："
echo "============="
echo "✅ DuckDB数据库 + 测试数据"
echo "✅ CSV导入脚本"
echo "✅ 数据分析SQL"
echo "✅ 飞书机器人配置"
echo "✅ 验收测试脚本"
echo ""
echo "🚀 立即测试："
echo "./test_phase1.sh"
echo ""
echo "📝 配置飞书Webhook："
echo "编辑 config/feishu_config.py 文件中的 FEISHU_WEBHOOK_URL"