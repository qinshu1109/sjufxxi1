#!/usr/bin/env python3
"""
简化的 DB-GPT 服务
提供基础的 API 接口和数据库查询功能
"""

import os
import logging
import json
from datetime import datetime
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# 设置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 创建 FastAPI 应用
app = FastAPI(
    title="DB-GPT Simple Service",
    description="简化的 DB-GPT 服务，提供基础的 NL2SQL 功能",
    version="1.0.0"
)

# 添加 CORS 中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 请求模型
class NL2SQLRequest(BaseModel):
    question: str
    database: str = "analytics"

class QueryRequest(BaseModel):
    sql: str
    database: str = "analytics"

# 响应模型
class NL2SQLResponse(BaseModel):
    sql: str
    explanation: str
    confidence: float

class QueryResponse(BaseModel):
    data: list
    columns: list
    row_count: int

@app.get("/")
async def root():
    return {
        "service": "DB-GPT Simple",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "dbgpt-simple",
        "timestamp": datetime.now().isoformat(),
        "components": {
            "api": "ok",
            "database": "ok"
        }
    }

@app.post("/api/v1/nl2sql", response_model=NL2SQLResponse)
async def nl2sql(request: NL2SQLRequest):
    """
    自然语言转 SQL
    """
    try:
        # 简化的 NL2SQL 逻辑
        question = request.question.lower()
        
        if "销售" in question or "sales" in question:
            sql = "SELECT category, SUM(sales_amount) as total_sales FROM douyin_products GROUP BY category ORDER BY total_sales DESC"
            explanation = "查询各类目的总销售额"
        elif "商品" in question or "product" in question:
            sql = "SELECT * FROM douyin_products ORDER BY created_date DESC LIMIT 10"
            explanation = "查询最新的商品信息"
        elif "趋势" in question or "trend" in question:
            sql = "SELECT created_date, SUM(sales_amount) as daily_sales FROM douyin_products GROUP BY created_date ORDER BY created_date"
            explanation = "查询销售趋势数据"
        else:
            sql = "SELECT COUNT(*) as total_products, AVG(price) as avg_price FROM douyin_products"
            explanation = "查询商品总数和平均价格"
        
        return NL2SQLResponse(
            sql=sql,
            explanation=explanation,
            confidence=0.85
        )
    
    except Exception as e:
        logger.error(f"NL2SQL 错误: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/query", response_model=QueryResponse)
async def execute_query(request: QueryRequest):
    """
    执行 SQL 查询
    """
    try:
        # 这里应该连接到实际的数据库
        # 为了演示，返回模拟数据
        mock_data = [
            {"id": 1, "name": "测试商品A", "price": 99.99, "sales": 100, "category": "电子产品"},
            {"id": 2, "name": "测试商品B", "price": 199.99, "sales": 50, "category": "服装"},
            {"id": 3, "name": "测试商品C", "price": 299.99, "sales": 75, "category": "美妆"}
        ]
        
        columns = ["id", "name", "price", "sales", "category"]
        
        return QueryResponse(
            data=mock_data,
            columns=columns,
            row_count=len(mock_data)
        )
    
    except Exception as e:
        logger.error(f"查询执行错误: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/databases")
async def list_databases():
    """
    列出可用的数据库
    """
    return {
        "databases": [
            {
                "name": "analytics",
                "description": "抖音数据分析数据库",
                "tables": ["douyin_products", "sales_data", "user_behavior"]
            }
        ]
    }

@app.get("/api/v1/tables/{database}")
async def list_tables(database: str):
    """
    列出数据库中的表
    """
    if database == "analytics":
        return {
            "database": database,
            "tables": [
                {
                    "name": "douyin_products",
                    "description": "抖音商品信息表",
                    "columns": ["id", "product_id", "title", "price", "sales_volume", "category"]
                },
                {
                    "name": "sales_data",
                    "description": "销售数据表",
                    "columns": ["date", "product_id", "sales_amount", "quantity"]
                }
            ]
        }
    else:
        raise HTTPException(status_code=404, detail="数据库不存在")

if __name__ == "__main__":
    host = os.getenv('DBGPT_HOST', '0.0.0.0')
    port = int(os.getenv('DBGPT_PORT', '5000'))
    
    logger.info(f"启动 DB-GPT Simple 服务: {host}:{port}")
    uvicorn.run(app, host=host, port=port)
