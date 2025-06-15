#!/usr/bin/env python3
"""
Schema 嵌入脚本
将数据库表结构和元数据嵌入到向量数据库中，用于 NL2SQL 的 Schema 检索
"""

import os
import sys
import json
import logging
import asyncio
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime

import duckdb
import psycopg2
import weaviate
import numpy as np
from sentence_transformers import SentenceTransformer

# 添加项目根目录到 Python 路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config.model_config import model_config


@dataclass
class TableSchema:
    """表结构信息"""
    database_name: str
    table_name: str
    table_comment: str
    columns: List[Dict[str, str]]
    sample_data: List[Dict]
    business_description: str
    common_queries: List[str]
    embedding: Optional[List[float]] = None


@dataclass
class ColumnInfo:
    """列信息"""
    name: str
    type: str
    nullable: bool
    comment: str
    sample_values: List[str]


class SchemaEmbedder:
    """Schema 嵌入器"""
    
    def __init__(self):
        self.logger = self._setup_logging()
        self.embedding_model = self._load_embedding_model()
        self.weaviate_client = self._setup_weaviate()
        self.schemas: List[TableSchema] = []
    
    def _setup_logging(self) -> logging.Logger:
        """设置日志"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/app/logs/schema_embedding.log'),
                logging.StreamHandler()
            ]
        )
        return logging.getLogger(__name__)
    
    def _load_embedding_model(self) -> SentenceTransformer:
        """加载嵌入模型"""
        try:
            # 使用中文优化的嵌入模型
            model_name = "BAAI/bge-large-zh-v1.5"
            model_path = "/app/models/bge-large-zh-v1.5"
            
            if os.path.exists(model_path):
                self.logger.info(f"从本地加载嵌入模型: {model_path}")
                return SentenceTransformer(model_path)
            else:
                self.logger.info(f"从 HuggingFace 下载嵌入模型: {model_name}")
                model = SentenceTransformer(model_name)
                # 保存到本地
                os.makedirs(os.path.dirname(model_path), exist_ok=True)
                model.save(model_path)
                return model
        except Exception as e:
            self.logger.error(f"加载嵌入模型失败: {e}")
            # 使用备用模型
            return SentenceTransformer("all-MiniLM-L6-v2")
    
    def _setup_weaviate(self) -> weaviate.Client:
        """设置 Weaviate 客户端"""
        try:
            weaviate_url = os.getenv("WEAVIATE_ENDPOINT", "http://weaviate:8080")
            api_key = os.getenv("WEAVIATE_API_KEY", "WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih")
            
            auth_config = weaviate.AuthApiKey(api_key=api_key)
            client = weaviate.Client(
                url=weaviate_url,
                auth_client_secret=auth_config
            )
            
            # 测试连接
            if client.is_ready():
                self.logger.info("Weaviate 连接成功")
                return client
            else:
                raise Exception("Weaviate 未就绪")
                
        except Exception as e:
            self.logger.error(f"Weaviate 连接失败: {e}")
            raise
    
    def extract_duckdb_schema(self) -> List[TableSchema]:
        """提取 DuckDB 表结构"""
        schemas = []
        db_path = os.getenv("LOCAL_DB_PATH", "/app/data/analytics.duckdb")
        
        try:
            conn = duckdb.connect(db_path)
            
            # 获取所有表
            tables_query = """
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'main' AND table_type = 'BASE TABLE'
            """
            tables = conn.execute(tables_query).fetchall()
            
            for (table_name,) in tables:
                if not model_config.is_table_allowed("douyin_analytics", table_name):
                    continue
                
                # 获取列信息
                columns_query = f"""
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns 
                WHERE table_name = '{table_name}'
                ORDER BY ordinal_position
                """
                columns_info = conn.execute(columns_query).fetchall()
                
                columns = []
                for col_name, col_type, nullable in columns_info:
                    # 获取样本值
                    sample_query = f"SELECT DISTINCT {col_name} FROM {table_name} WHERE {col_name} IS NOT NULL LIMIT 5"
                    try:
                        sample_values = [str(row[0]) for row in conn.execute(sample_query).fetchall()]
                    except:
                        sample_values = []
                    
                    columns.append({
                        "name": col_name,
                        "type": col_type,
                        "nullable": nullable == "YES",
                        "comment": self._get_column_comment(table_name, col_name),
                        "sample_values": sample_values
                    })
                
                # 获取样本数据
                sample_data_query = f"SELECT * FROM {table_name} LIMIT 3"
                try:
                    sample_rows = conn.execute(sample_data_query).fetchall()
                    column_names = [desc[0] for desc in conn.description]
                    sample_data = [dict(zip(column_names, row)) for row in sample_rows]
                except:
                    sample_data = []
                
                # 创建表结构对象
                schema = TableSchema(
                    database_name="douyin_analytics",
                    table_name=table_name,
                    table_comment=self._get_table_comment(table_name),
                    columns=columns,
                    sample_data=sample_data,
                    business_description=self._get_business_description(table_name),
                    common_queries=self._get_common_queries(table_name)
                )
                
                schemas.append(schema)
                self.logger.info(f"提取表结构: {table_name}")
            
            conn.close()
            
        except Exception as e:
            self.logger.error(f"提取 DuckDB 表结构失败: {e}")
        
        return schemas
    
    def _get_table_comment(self, table_name: str) -> str:
        """获取表注释"""
        comments = {
            "douyin_products": "抖音商品数据表，包含商品基本信息、销售数据、直播信息等",
            "sales_summary": "销售汇总视图，按类目统计销售数据",
            "product_trends": "商品趋势分析表，记录商品销售趋势变化",
            "category_analysis": "类目分析表，提供类目级别的统计分析"
        }
        return comments.get(table_name, f"{table_name} 数据表")
    
    def _get_column_comment(self, table_name: str, column_name: str) -> str:
        """获取列注释"""
        column_comments = {
            "douyin_products": {
                "id": "商品唯一标识",
                "product_id": "商品ID",
                "title": "商品标题",
                "price": "商品价格",
                "sales_volume": "销售量",
                "sales_amount": "销售额",
                "shop_name": "店铺名称",
                "category": "商品类目",
                "brand": "品牌",
                "rating": "评分",
                "live_room_title": "直播间标题",
                "anchor_name": "主播名称",
                "created_date": "创建日期",
                "updated_date": "更新时间"
            }
        }
        return column_comments.get(table_name, {}).get(column_name, f"{column_name} 字段")
    
    def _get_business_description(self, table_name: str) -> str:
        """获取业务描述"""
        descriptions = {
            "douyin_products": "存储抖音电商平台的商品信息，包括商品基本属性、销售数据、直播带货信息等。主要用于商品分析、销售统计、趋势预测等业务场景。",
            "sales_summary": "提供按类目汇总的销售统计数据，包括商品数量、总销量、总销售额、平均价格、平均评分等指标。",
            "product_trends": "记录商品销售趋势数据，用于分析商品销售表现的时间序列变化。",
            "category_analysis": "提供类目级别的深度分析数据，包括类目表现、竞争分析、市场份额等。"
        }
        return descriptions.get(table_name, f"{table_name} 业务数据表")
    
    def _get_common_queries(self, table_name: str) -> List[str]:
        """获取常见查询"""
        queries = {
            "douyin_products": [
                "查询销量最高的商品",
                "按类目统计销售数据",
                "查询特定价格区间的商品",
                "分析主播带货效果",
                "查询品牌销售排行"
            ],
            "sales_summary": [
                "查看各类目销售汇总",
                "比较不同类目的平均价格",
                "分析类目评分分布"
            ]
        }
        return queries.get(table_name, [])
    
    def generate_embeddings(self, schemas: List[TableSchema]) -> List[TableSchema]:
        """生成嵌入向量"""
        for schema in schemas:
            # 构建用于嵌入的文本
            text_parts = [
                f"表名: {schema.table_name}",
                f"描述: {schema.table_comment}",
                f"业务说明: {schema.business_description}",
                f"列信息: {', '.join([f'{col[\"name\"]}({col[\"type\"]})' for col in schema.columns])}"
            ]
            
            if schema.common_queries:
                text_parts.append(f"常见查询: {'; '.join(schema.common_queries)}")
            
            text = " | ".join(text_parts)
            
            # 生成嵌入向量
            try:
                embedding = self.embedding_model.encode(text, normalize_embeddings=True)
                schema.embedding = embedding.tolist()
                self.logger.info(f"生成嵌入向量: {schema.table_name}")
            except Exception as e:
                self.logger.error(f"生成嵌入向量失败 {schema.table_name}: {e}")
        
        return schemas
    
    def create_weaviate_schema(self):
        """创建 Weaviate Schema"""
        schema_definition = {
            "class": "TableSchema",
            "description": "数据库表结构信息",
            "vectorizer": "none",
            "properties": [
                {
                    "name": "database_name",
                    "dataType": ["string"],
                    "description": "数据库名称"
                },
                {
                    "name": "table_name",
                    "dataType": ["string"],
                    "description": "表名"
                },
                {
                    "name": "table_comment",
                    "dataType": ["text"],
                    "description": "表注释"
                },
                {
                    "name": "business_description",
                    "dataType": ["text"],
                    "description": "业务描述"
                },
                {
                    "name": "columns_info",
                    "dataType": ["text"],
                    "description": "列信息JSON"
                },
                {
                    "name": "sample_data",
                    "dataType": ["text"],
                    "description": "样本数据JSON"
                },
                {
                    "name": "common_queries",
                    "dataType": ["text"],
                    "description": "常见查询"
                }
            ]
        }
        
        try:
            # 删除现有的 schema（如果存在）
            if self.weaviate_client.schema.exists("TableSchema"):
                self.weaviate_client.schema.delete_class("TableSchema")
            
            # 创建新的 schema
            self.weaviate_client.schema.create_class(schema_definition)
            self.logger.info("创建 Weaviate Schema 成功")
        except Exception as e:
            self.logger.error(f"创建 Weaviate Schema 失败: {e}")
            raise
    
    def store_embeddings(self, schemas: List[TableSchema]):
        """存储嵌入向量到 Weaviate"""
        try:
            with self.weaviate_client.batch as batch:
                batch.batch_size = 10
                
                for schema in schemas:
                    if schema.embedding is None:
                        continue
                    
                    properties = {
                        "database_name": schema.database_name,
                        "table_name": schema.table_name,
                        "table_comment": schema.table_comment,
                        "business_description": schema.business_description,
                        "columns_info": json.dumps(schema.columns, ensure_ascii=False),
                        "sample_data": json.dumps(schema.sample_data, ensure_ascii=False, default=str),
                        "common_queries": "; ".join(schema.common_queries)
                    }
                    
                    batch.add_data_object(
                        data_object=properties,
                        class_name="TableSchema",
                        vector=schema.embedding
                    )
                    
                    self.logger.info(f"存储嵌入向量: {schema.table_name}")
            
            self.logger.info("所有嵌入向量存储完成")
            
        except Exception as e:
            self.logger.error(f"存储嵌入向量失败: {e}")
            raise
    
    def save_schema_index(self, schemas: List[TableSchema]):
        """保存 Schema 索引文件"""
        index_data = {
            "timestamp": datetime.now().isoformat(),
            "schemas": [asdict(schema) for schema in schemas]
        }
        
        index_file = "/app/data/schema_vectors.idx"
        os.makedirs(os.path.dirname(index_file), exist_ok=True)
        
        with open(index_file, 'w', encoding='utf-8') as f:
            json.dump(index_data, f, ensure_ascii=False, indent=2, default=str)
        
        self.logger.info(f"Schema 索引已保存: {index_file}")
    
    async def run(self):
        """运行嵌入流程"""
        try:
            self.logger.info("开始 Schema 嵌入流程")
            
            # 1. 提取表结构
            self.logger.info("提取 DuckDB 表结构...")
            schemas = self.extract_duckdb_schema()
            
            if not schemas:
                self.logger.warning("未找到可用的表结构")
                return
            
            # 2. 生成嵌入向量
            self.logger.info("生成嵌入向量...")
            schemas = self.generate_embeddings(schemas)
            
            # 3. 创建 Weaviate Schema
            self.logger.info("创建 Weaviate Schema...")
            self.create_weaviate_schema()
            
            # 4. 存储到向量数据库
            self.logger.info("存储嵌入向量...")
            self.store_embeddings(schemas)
            
            # 5. 保存索引文件
            self.logger.info("保存索引文件...")
            self.save_schema_index(schemas)
            
            self.logger.info(f"Schema 嵌入完成，共处理 {len(schemas)} 个表")
            
        except Exception as e:
            self.logger.error(f"Schema 嵌入流程失败: {e}")
            raise


async def main():
    """主函数"""
    embedder = SchemaEmbedder()
    await embedder.run()


if __name__ == "__main__":
    asyncio.run(main())
