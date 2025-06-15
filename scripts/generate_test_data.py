#!/usr/bin/env python3
"""
基于蝉妈妈格式的测试数据生成器
生成30天的抖音电商销售数据用于验收测试
"""
import pandas as pd
import random
from datetime import datetime, timedelta
import os

def generate_test_data():
    """生成测试数据"""
    print("🔄 正在生成测试数据...")
    
    # 商品基础数据 - 基于真实蝉妈妈格式
    products = [
        {
            "sku": "3737962838157820139",
            "product_name": "DIY儿童服装设计启蒙国潮国风汉服手工制作女孩生日礼物创意玩具",
            "category": "礼品文创-创意礼品-创意礼品类-DIY礼品",
            "commission_rate": 20.0,
            "brand": "哈妹生活坊",
            "base_price": 89.9
        },
        {
            "sku": "3750278905861373956", 
            "product_name": "六一儿童节生日礼物送女孩子女童6-12岁小朋友10实用型库洛米礼盒",
            "category": "礼品文创-节日礼品",
            "commission_rate": 10.0,
            "brand": "童趣礼品店",
            "base_price": 159.9
        },
        {
            "sku": "3745623487291847362",
            "product_name": "【中考专属-金榜题名礼盒】送男生女生仪式感可乐定制礼盒中考礼品",
            "category": "礼品文创-定制礼品",
            "commission_rate": 25.0,
            "brand": "学霸文创",
            "base_price": 39.9
        },
        {
            "sku": "3758912345678901234",
            "product_name": "夏季新款女装连衣裙韩版时尚修身显瘦中长款气质裙子",
            "category": "服装鞋帽-女装-连衣裙",
            "commission_rate": 15.0,
            "brand": "时尚女装",
            "base_price": 199.9
        },
        {
            "sku": "3756789012345678901",
            "product_name": "智能蓝牙耳机无线运动型超长续航降噪通话音质高清",
            "category": "数码配件-音频设备",
            "commission_rate": 18.0,
            "brand": "数码科技",
            "base_price": 299.9
        }
    ]
    
    # 生成30天的销售数据
    all_data = []
    base_date = datetime.now() - timedelta(days=30)
    
    for day in range(30):
        current_date = base_date + timedelta(days=day)
        day_of_week = current_date.weekday()
        
        for product in products:
            # 根据产品类型生成不同的趋势
            if "DIY儿童服装" in product["product_name"]:
                # 模拟突增趋势 (用于测试异常检测)
                if day < 20:
                    base_sales = random.randint(1800, 2200)
                else:
                    base_sales = random.randint(7000, 8000)  # 突增
            elif "六一儿童节" in product["product_name"]:
                # 模拟节日商品增长趋势
                base_sales = 800 + day * 50 + random.randint(-100, 200)
            elif "中考专属" in product["product_name"]:
                # 模拟季节性商品
                if 15 <= day <= 25:  # 中考季
                    base_sales = 4000 + random.randint(-500, 500)
                else:
                    base_sales = 1500 + random.randint(-200, 200)
            else:
                # 模拟普通商品的周期性
                weekend_boost = 1.3 if day_of_week >= 5 else 1.0
                base_sales = int((2000 + day * 30) * weekend_boost + random.randint(-300, 300))
            
            # 确保销量最小值
            daily_sales = max(100, base_sales)
            
            # 计算价格（有一定波动）
            price_variance = random.uniform(0.8, 1.2)
            unit_price = round(product["base_price"] * price_variance, 2)
            
            # 计算各种指标
            live_sales = int(daily_sales * random.uniform(0.5, 0.7))
            card_sales = daily_sales - live_sales
            daily_revenue = round(daily_sales * unit_price, 2)
            conversion_rate = round(random.uniform(3.0, 18.0), 2)
            
            # 创建记录
            record = {
                "date": current_date.strftime("%Y-%m-%d"),
                "sku": product["sku"],
                "product_name": product["product_name"],
                "category": product["category"],
                "commission_rate": product["commission_rate"],
                "brand": product["brand"],
                "daily_sales": daily_sales,
                "daily_revenue": daily_revenue,
                "live_sales": live_sales,
                "card_sales": card_sales,
                "conversion_rate": conversion_rate,
                "avg_price": unit_price,
                "clicks": int(daily_sales / conversion_rate * 100),
                "exposure": int(daily_sales / conversion_rate * 1000),
                "ctr": round(random.uniform(2.0, 8.0), 2),
                "day_of_week": day_of_week,
                "is_weekend": day_of_week >= 5
            }
            all_data.append(record)
    
    # 转换为DataFrame
    df = pd.DataFrame(all_data)
    
    # 确保输出目录存在
    output_dir = os.path.expanduser("~/douyin-analytics/data/csv")
    os.makedirs(output_dir, exist_ok=True)
    
    # 保存完整数据集
    full_data_path = f"{output_dir}/douyin_test_data_30days.csv"
    df.to_csv(full_data_path, index=False, encoding='utf-8-sig')
    
    # 保存最新一天数据
    latest_df = df[df['date'] == df['date'].max()]
    latest_data_path = f"{output_dir}/douyin_test_data_latest.csv"
    latest_df.to_csv(latest_data_path, index=False, encoding='utf-8-sig')
    
    # 生成汇总统计
    summary_stats = df.groupby(['sku', 'product_name']).agg({
        'daily_sales': ['sum', 'mean', 'max', 'std'],
        'daily_revenue': ['sum', 'mean'],
        'conversion_rate': 'mean',
        'avg_price': 'mean'
    }).round(2)
    
    # 检测异常值 (用于测试异常检测功能)
    anomalies = []
    for sku in df['sku'].unique():
        sku_data = df[df['sku'] == sku]['daily_sales']
        mean_sales = sku_data.mean()
        std_sales = sku_data.std()
        
        # 查找超过2个标准差的数据点
        anomaly_threshold = mean_sales + 2 * std_sales
        anomaly_days = df[(df['sku'] == sku) & (df['daily_sales'] > anomaly_threshold)]
        
        if not anomaly_days.empty:
            for _, row in anomaly_days.iterrows():
                anomalies.append({
                    'date': row['date'],
                    'sku': row['sku'],
                    'product_name': row['product_name'][:50] + '...',
                    'sales': row['daily_sales'],
                    'threshold': int(anomaly_threshold),
                    'increase_rate': round((row['daily_sales'] - mean_sales) / mean_sales * 100, 1)
                })
    
    print("✅ 测试数据生成完成！")
    print(f"📁 文件位置: {output_dir}")
    print(f"📊 生成记录数: {len(df)}")
    print(f"📈 产品数量: {len(products)}")
    print(f"📅 时间范围: {df['date'].min()} ~ {df['date'].max()}")
    
    print(f"\n📈 销售统计概览:")
    for sku in df['sku'].unique():
        sku_data = df[df['sku'] == sku]
        product_name = sku_data['product_name'].iloc[0][:30] + '...'
        total_sales = sku_data['daily_sales'].sum()
        total_revenue = sku_data['daily_revenue'].sum()
        print(f"  {product_name}: 总销量 {total_sales:,}, 总收入 ¥{total_revenue:,.2f}")
    
    if anomalies:
        print(f"\n🚨 检测到 {len(anomalies)} 个异常数据点 (用于测试告警功能):")
        for anomaly in anomalies[:3]:  # 只显示前3个
            print(f"  📅 {anomaly['date']}: {anomaly['product_name']} 销量 {anomaly['sales']} (+{anomaly['increase_rate']}%)")
    
    return df, anomalies

if __name__ == "__main__":
    try:
        data, anomalies = generate_test_data()
        print("\n🎯 数据生成成功，可以继续执行导入步骤")
    except Exception as e:
        print(f"❌ 数据生成失败: {e}")
        exit(1)