"""
DB-GPT 数据库模型配置
为 sjufxxi 抖音数据分析平台定制的数据库连接和表白名单配置
"""

import os
from typing import Dict, List, Optional
from dataclasses import dataclass
from enum import Enum


class DatabaseType(Enum):
    """支持的数据库类型"""
    DUCKDB = "duckdb"
    POSTGRESQL = "postgresql"
    MYSQL = "mysql"
    SQLITE = "sqlite"


@dataclass
class TableConfig:
    """表配置"""
    name: str
    description: str
    allowed_operations: List[str]
    sensitive_columns: List[str] = None
    row_limit: int = 10000


@dataclass
class DatabaseConfig:
    """数据库配置"""
    name: str
    type: DatabaseType
    connection_string: str
    description: str
    tables: List[TableConfig]
    security_level: str = "medium"
    enable_cache: bool = True


class ModelConfig:
    """DB-GPT 模型配置管理器"""
    
    def __init__(self):
        self.databases = self._init_databases()
        self.sql_whitelist = self._init_sql_whitelist()
        self.security_rules = self._init_security_rules()
    
    def _init_databases(self) -> Dict[str, DatabaseConfig]:
        """初始化数据库配置"""
        
        # 主数据库：DuckDB 分析数据库
        douyin_tables = [
            TableConfig(
                name="douyin_products",
                description="抖音商品数据表",
                allowed_operations=["SELECT", "WITH"],
                sensitive_columns=["shop_name", "anchor_name"],
                row_limit=50000
            ),
            TableConfig(
                name="sales_summary",
                description="销售汇总视图",
                allowed_operations=["SELECT"],
                sensitive_columns=[],
                row_limit=1000
            ),
            TableConfig(
                name="product_trends",
                description="商品趋势分析表",
                allowed_operations=["SELECT", "WITH"],
                sensitive_columns=[],
                row_limit=10000
            ),
            TableConfig(
                name="category_analysis",
                description="类目分析表",
                allowed_operations=["SELECT"],
                sensitive_columns=[],
                row_limit=5000
            )
        ]
        
        # 系统数据库：PostgreSQL (Dify)
        dify_tables = [
            TableConfig(
                name="conversations",
                description="对话记录表",
                allowed_operations=["SELECT"],
                sensitive_columns=["user_id", "ip_address"],
                row_limit=1000
            ),
            TableConfig(
                name="messages",
                description="消息记录表",
                allowed_operations=["SELECT"],
                sensitive_columns=["user_id", "content"],
                row_limit=5000
            ),
            TableConfig(
                name="apps",
                description="应用配置表",
                allowed_operations=["SELECT"],
                sensitive_columns=["api_key", "config"],
                row_limit=100
            )
        ]
        
        return {
            "douyin_analytics": DatabaseConfig(
                name="douyin_analytics",
                type=DatabaseType.DUCKDB,
                connection_string=os.getenv("LOCAL_DB_PATH", "/app/data/analytics.duckdb"),
                description="抖音电商数据分析主数据库",
                tables=douyin_tables,
                security_level="high",
                enable_cache=True
            ),
            "dify_system": DatabaseConfig(
                name="dify_system",
                type=DatabaseType.POSTGRESQL,
                connection_string=os.getenv("POSTGRES_URL", "postgresql://postgres:difyai123456@db:5432/dify"),
                description="Dify 系统数据库",
                tables=dify_tables,
                security_level="high",
                enable_cache=False
            )
        }
    
    def _init_sql_whitelist(self) -> Dict[str, List[str]]:
        """初始化 SQL 白名单"""
        return {
            "allowed_keywords": [
                # 查询关键字
                "SELECT", "FROM", "WHERE", "GROUP BY", "ORDER BY", "HAVING",
                "JOIN", "INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL JOIN",
                "UNION", "UNION ALL", "WITH", "AS", "DISTINCT", "LIMIT", "OFFSET",
                
                # 函数和操作符
                "COUNT", "SUM", "AVG", "MAX", "MIN", "ROUND", "CAST", "CASE", "WHEN", "THEN", "ELSE", "END",
                "AND", "OR", "NOT", "IN", "NOT IN", "LIKE", "ILIKE", "BETWEEN", "IS NULL", "IS NOT NULL",
                "EXTRACT", "DATE_TRUNC", "NOW", "CURRENT_DATE", "CURRENT_TIMESTAMP",
                
                # 窗口函数
                "ROW_NUMBER", "RANK", "DENSE_RANK", "LAG", "LEAD", "FIRST_VALUE", "LAST_VALUE",
                "OVER", "PARTITION BY", "ROWS", "RANGE", "PRECEDING", "FOLLOWING", "UNBOUNDED"
            ],
            
            "forbidden_keywords": [
                # 数据修改
                "INSERT", "UPDATE", "DELETE", "TRUNCATE", "MERGE", "UPSERT",
                
                # 结构修改
                "CREATE", "ALTER", "DROP", "RENAME", "ADD COLUMN", "DROP COLUMN",
                
                # 权限和用户管理
                "GRANT", "REVOKE", "CREATE USER", "DROP USER", "ALTER USER",
                
                # 系统操作
                "EXEC", "EXECUTE", "CALL", "PROCEDURE", "FUNCTION",
                "BACKUP", "RESTORE", "IMPORT", "EXPORT",
                
                # 危险操作
                "SHUTDOWN", "KILL", "LOCK", "UNLOCK"
            ],
            
            "allowed_functions": [
                # 聚合函数
                "count", "sum", "avg", "max", "min", "stddev", "variance",
                
                # 字符串函数
                "length", "substr", "upper", "lower", "trim", "replace", "concat",
                
                # 数学函数
                "abs", "round", "ceil", "floor", "sqrt", "power", "log",
                
                # 日期函数
                "extract", "date_trunc", "date_part", "age", "interval",
                
                # 条件函数
                "coalesce", "nullif", "greatest", "least"
            ]
        }
    
    def _init_security_rules(self) -> Dict[str, any]:
        """初始化安全规则"""
        return {
            "max_query_time": int(os.getenv("DBGPT_SECURITY_MAX_QUERY_TIME", "30")),
            "max_result_rows": 50000,
            "max_query_length": 10000,
            "enable_sql_injection_detection": True,
            "enable_sensitive_data_masking": True,
            "log_all_queries": True,
            "require_table_whitelist": True,
            "enable_row_level_security": False,
            "allowed_ip_ranges": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"],
            "rate_limit": {
                "queries_per_minute": 60,
                "queries_per_hour": 1000
            }
        }
    
    def get_database_config(self, db_name: str) -> Optional[DatabaseConfig]:
        """获取数据库配置"""
        return self.databases.get(db_name)
    
    def get_allowed_tables(self, db_name: str) -> List[str]:
        """获取允许访问的表列表"""
        db_config = self.get_database_config(db_name)
        if db_config:
            return [table.name for table in db_config.tables]
        return []
    
    def is_table_allowed(self, db_name: str, table_name: str) -> bool:
        """检查表是否在白名单中"""
        allowed_tables = self.get_allowed_tables(db_name)
        return table_name in allowed_tables
    
    def is_operation_allowed(self, db_name: str, table_name: str, operation: str) -> bool:
        """检查操作是否被允许"""
        db_config = self.get_database_config(db_name)
        if not db_config:
            return False
        
        for table in db_config.tables:
            if table.name == table_name:
                return operation.upper() in [op.upper() for op in table.allowed_operations]
        
        return False
    
    def validate_sql_keywords(self, sql: str) -> tuple[bool, str]:
        """验证 SQL 关键字"""
        sql_upper = sql.upper()
        
        # 检查禁止的关键字
        for keyword in self.sql_whitelist["forbidden_keywords"]:
            if keyword in sql_upper:
                return False, f"禁止使用关键字: {keyword}"
        
        # 检查是否包含允许的操作
        has_allowed_operation = False
        for keyword in ["SELECT", "WITH"]:
            if keyword in sql_upper:
                has_allowed_operation = True
                break
        
        if not has_allowed_operation:
            return False, "SQL 必须包含允许的查询操作 (SELECT, WITH)"
        
        return True, "SQL 关键字验证通过"
    
    def get_connection_string(self, db_name: str) -> Optional[str]:
        """获取数据库连接字符串"""
        db_config = self.get_database_config(db_name)
        if db_config:
            return db_config.connection_string
        return None


# 全局配置实例
model_config = ModelConfig()


def get_model_config() -> ModelConfig:
    """获取模型配置实例"""
    return model_config
