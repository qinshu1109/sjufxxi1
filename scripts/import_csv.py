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
    # 使用相对路径获取项目根目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    db_file = os.path.join(project_dir, "data", "db", "analytics.duckdb")
    
    if not os.path.exists(csv_file):
        print(f"❌ CSV文件不存在: {csv_file}")
        sys.exit(1)
    
    import_csv_to_duckdb(csv_file, db_file)