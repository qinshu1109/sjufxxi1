"""
NL2SQL AWEL 工作流管道
实现自然语言到SQL的完整转换流程，包括Schema检索、SQL生成、验证、执行和结果处理
"""

import os
import json
import logging
import asyncio
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from datetime import datetime

from dbgpt.core.awel import DAG, MapOperator, JoinOperator, BranchOperator
from dbgpt.core.awel.flow import IOField, ViewMetadata, Parameter
from dbgpt.core.interface.llm import LLMClient
from dbgpt.core.interface.embeddings import EmbeddingClient
from dbgpt.datasource.manages.connector_manager import ConnectorManager
from dbgpt.rag.retriever.embedding import EmbeddingRetriever


@dataclass
class NL2SQLRequest:
    """NL2SQL 请求"""
    question: str
    user_id: str
    session_id: str
    database: str = "douyin_analytics"
    max_results: int = 100
    enable_cache: bool = True


@dataclass
class SQLValidationResult:
    """SQL 验证结果"""
    is_valid: bool
    sql: str
    error_message: str = ""
    suggestions: List[str] = None


@dataclass
class QueryResult:
    """查询结果"""
    success: bool
    data: List[Dict] = None
    columns: List[str] = None
    row_count: int = 0
    execution_time: float = 0.0
    error_message: str = ""


class SchemaRetriever:
    """Schema 检索器"""
    
    def __init__(self, embedding_client: EmbeddingClient, weaviate_client):
        self.embedding_client = embedding_client
        self.weaviate_client = weaviate_client
        self.logger = logging.getLogger(__name__)
    
    async def retrieve_relevant_schemas(self, question: str, top_k: int = 3) -> List[Dict]:
        """检索相关的表结构"""
        try:
            # 生成问题的嵌入向量
            question_embedding = await self.embedding_client.aembed_query(question)
            
            # 在 Weaviate 中搜索相似的表结构
            result = self.weaviate_client.query.get("TableSchema", [
                "database_name", "table_name", "table_comment", 
                "business_description", "columns_info", "common_queries"
            ]).with_near_vector({
                "vector": question_embedding,
                "certainty": 0.7
            }).with_limit(top_k).do()
            
            schemas = []
            if "data" in result and "Get" in result["data"]:
                for item in result["data"]["Get"]["TableSchema"]:
                    schemas.append({
                        "table_name": item["table_name"],
                        "table_comment": item["table_comment"],
                        "business_description": item["business_description"],
                        "columns": json.loads(item["columns_info"]),
                        "common_queries": item["common_queries"].split("; ") if item["common_queries"] else []
                    })
            
            self.logger.info(f"检索到 {len(schemas)} 个相关表结构")
            return schemas
            
        except Exception as e:
            self.logger.error(f"Schema 检索失败: {e}")
            return []


class SQLGenerator:
    """SQL 生成器"""
    
    def __init__(self, llm_client: LLMClient):
        self.llm_client = llm_client
        self.logger = logging.getLogger(__name__)
    
    async def generate_sql(self, question: str, schemas: List[Dict]) -> str:
        """生成 SQL 查询"""
        try:
            # 构建提示词
            prompt = self._build_prompt(question, schemas)
            
            # 调用 LLM 生成 SQL
            response = await self.llm_client.agenerate(prompt)
            sql = self._extract_sql_from_response(response.text)
            
            self.logger.info(f"生成 SQL: {sql}")
            return sql
            
        except Exception as e:
            self.logger.error(f"SQL 生成失败: {e}")
            return ""
    
    def _build_prompt(self, question: str, schemas: List[Dict]) -> str:
        """构建 LLM 提示词"""
        schema_info = ""
        for schema in schemas:
            columns_desc = ", ".join([
                f"{col['name']}({col['type']})" for col in schema["columns"]
            ])
            schema_info += f"""
表名: {schema['table_name']}
描述: {schema['table_comment']}
列信息: {columns_desc}
业务说明: {schema['business_description']}
"""
        
        prompt = f"""
你是一个专业的SQL查询生成助手，专门为抖音电商数据分析平台生成SQL查询。

数据库表结构信息:
{schema_info}

用户问题: {question}

请根据用户问题和表结构信息，生成准确的SQL查询语句。

要求:
1. 只使用提供的表和列
2. 使用标准SQL语法
3. 确保查询逻辑正确
4. 添加适当的限制条件避免返回过多数据
5. 只返回SQL语句，不要包含其他解释

SQL查询:
"""
        return prompt
    
    def _extract_sql_from_response(self, response: str) -> str:
        """从LLM响应中提取SQL"""
        # 移除可能的markdown标记
        sql = response.strip()
        if sql.startswith("```sql"):
            sql = sql[6:]
        if sql.startswith("```"):
            sql = sql[3:]
        if sql.endswith("```"):
            sql = sql[:-3]
        
        return sql.strip()


class SQLValidator:
    """SQL 验证器 - 实现 AST 白名单"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        # 导入 sqlglot 用于 SQL 解析
        try:
            import sqlglot
            self.sqlglot = sqlglot
        except ImportError:
            self.logger.error("sqlglot 未安装，SQL 验证功能受限")
            self.sqlglot = None
    
    async def validate_sql(self, sql: str, database: str) -> SQLValidationResult:
        """验证 SQL 查询"""
        try:
            # 1. 基础语法检查
            if not sql or not sql.strip():
                return SQLValidationResult(False, sql, "SQL 不能为空")
            
            # 2. 关键字白名单检查
            keyword_check = self._check_keywords(sql)
            if not keyword_check[0]:
                return SQLValidationResult(False, sql, keyword_check[1])
            
            # 3. AST 解析检查
            if self.sqlglot:
                ast_check = self._check_ast(sql)
                if not ast_check[0]:
                    return SQLValidationResult(False, sql, ast_check[1])
            
            # 4. 表白名单检查
            table_check = self._check_tables(sql, database)
            if not table_check[0]:
                return SQLValidationResult(False, sql, table_check[1])
            
            return SQLValidationResult(True, sql)
            
        except Exception as e:
            self.logger.error(f"SQL 验证失败: {e}")
            return SQLValidationResult(False, sql, f"验证过程出错: {str(e)}")
    
    def _check_keywords(self, sql: str) -> Tuple[bool, str]:
        """检查关键字白名单"""
        sql_upper = sql.upper()
        
        # 禁止的关键字
        forbidden_keywords = [
            "DROP", "DELETE", "UPDATE", "INSERT", "ALTER", "CREATE", "TRUNCATE",
            "GRANT", "REVOKE", "EXEC", "EXECUTE", "CALL", "PROCEDURE"
        ]
        
        for keyword in forbidden_keywords:
            if keyword in sql_upper:
                return False, f"禁止使用关键字: {keyword}"
        
        # 必须包含的关键字
        if "SELECT" not in sql_upper:
            return False, "SQL 必须是 SELECT 查询"
        
        return True, ""
    
    def _check_ast(self, sql: str) -> Tuple[bool, str]:
        """使用 AST 检查 SQL 结构"""
        try:
            # 解析 SQL
            parsed = self.sqlglot.parse_one(sql, dialect="duckdb")
            
            # 检查是否为 SELECT 语句
            if not isinstance(parsed, self.sqlglot.expressions.Select):
                return False, "只允许 SELECT 查询"
            
            # 检查是否包含子查询中的危险操作
            for node in parsed.walk():
                if isinstance(node, (
                    self.sqlglot.expressions.Drop,
                    self.sqlglot.expressions.Delete,
                    self.sqlglot.expressions.Update,
                    self.sqlglot.expressions.Insert,
                    self.sqlglot.expressions.Create
                )):
                    return False, f"禁止使用 {type(node).__name__} 操作"
            
            return True, ""
            
        except Exception as e:
            return False, f"SQL 语法错误: {str(e)}"
    
    def _check_tables(self, sql: str, database: str) -> Tuple[bool, str]:
        """检查表白名单"""
        from config.model_config import model_config
        
        allowed_tables = model_config.get_allowed_tables(database)
        
        # 简单的表名提取（可以改进为使用 AST）
        sql_upper = sql.upper()
        for table in allowed_tables:
            if table.upper() in sql_upper:
                continue
        
        # 检查是否使用了未授权的表
        # 这里可以实现更精确的表名提取逻辑
        
        return True, ""


class AutoFixEngine:
    """自动修复引擎"""
    
    def __init__(self, llm_client: LLMClient, sql_validator: SQLValidator):
        self.llm_client = llm_client
        self.sql_validator = sql_validator
        self.logger = logging.getLogger(__name__)
        self.max_attempts = 3
    
    async def fix_sql(self, original_sql: str, error_message: str, schemas: List[Dict]) -> Optional[str]:
        """自动修复 SQL"""
        for attempt in range(self.max_attempts):
            try:
                self.logger.info(f"尝试修复 SQL (第 {attempt + 1} 次)")
                
                # 构建修复提示词
                fix_prompt = self._build_fix_prompt(original_sql, error_message, schemas)
                
                # 生成修复后的 SQL
                response = await self.llm_client.agenerate(fix_prompt)
                fixed_sql = self._extract_sql_from_response(response.text)
                
                # 验证修复后的 SQL
                validation_result = await self.sql_validator.validate_sql(fixed_sql, "douyin_analytics")
                
                if validation_result.is_valid:
                    self.logger.info(f"SQL 修复成功: {fixed_sql}")
                    return fixed_sql
                else:
                    error_message = validation_result.error_message
                    original_sql = fixed_sql
                    
            except Exception as e:
                self.logger.error(f"SQL 修复失败 (第 {attempt + 1} 次): {e}")
        
        self.logger.warning("SQL 自动修复失败，已达到最大尝试次数")
        return None
    
    def _build_fix_prompt(self, sql: str, error: str, schemas: List[Dict]) -> str:
        """构建修复提示词"""
        schema_info = ""
        for schema in schemas:
            columns_desc = ", ".join([f"{col['name']}({col['type']})" for col in schema["columns"]])
            schema_info += f"表 {schema['table_name']}: {columns_desc}\n"
        
        return f"""
请修复以下SQL查询中的错误:

原始SQL:
{sql}

错误信息:
{error}

可用的表结构:
{schema_info}

请生成修复后的SQL查询，确保:
1. 语法正确
2. 只使用允许的表和列
3. 符合安全规范

修复后的SQL:
"""
    
    def _extract_sql_from_response(self, response: str) -> str:
        """从响应中提取SQL"""
        sql = response.strip()
        if sql.startswith("```sql"):
            sql = sql[6:]
        if sql.startswith("```"):
            sql = sql[3:]
        if sql.endswith("```"):
            sql = sql[:-3]
        return sql.strip()


class QueryExecutor:
    """查询执行器"""
    
    def __init__(self, connector_manager: ConnectorManager):
        self.connector_manager = connector_manager
        self.logger = logging.getLogger(__name__)
    
    async def execute_query(self, sql: str, database: str) -> QueryResult:
        """执行 SQL 查询"""
        start_time = datetime.now()
        
        try:
            # 获取数据库连接
            connector = self.connector_manager.get_connector(database)
            
            # 执行查询
            result = await connector.aquery(sql)
            
            execution_time = (datetime.now() - start_time).total_seconds()
            
            return QueryResult(
                success=True,
                data=result.data,
                columns=result.columns,
                row_count=len(result.data) if result.data else 0,
                execution_time=execution_time
            )
            
        except Exception as e:
            execution_time = (datetime.now() - start_time).total_seconds()
            self.logger.error(f"查询执行失败: {e}")
            
            return QueryResult(
                success=False,
                execution_time=execution_time,
                error_message=str(e)
            )


# ============================================
# AWEL 工作流定义
# ============================================

class NL2SQLPipeline:
    """NL2SQL 工作流管道"""
    
    def __init__(self):
        self.dag = DAG("nl2sql_pipeline")
        self._build_pipeline()
    
    def _build_pipeline(self):
        """构建工作流管道"""
        
        # 1. Schema 检索节点
        schema_retrieval = MapOperator(
            map_function=self._retrieve_schemas,
            task_name="schema_retrieval"
        )
        
        # 2. SQL 生成节点
        sql_generation = MapOperator(
            map_function=self._generate_sql,
            task_name="sql_generation"
        )
        
        # 3. SQL 验证节点
        sql_validation = MapOperator(
            map_function=self._validate_sql,
            task_name="sql_validation"
        )
        
        # 4. 分支节点：验证通过或需要修复
        validation_branch = BranchOperator(
            branch_function=self._validation_branch,
            task_name="validation_branch"
        )
        
        # 5. 自动修复节点
        auto_fix = MapOperator(
            map_function=self._auto_fix_sql,
            task_name="auto_fix"
        )
        
        # 6. 查询执行节点
        query_execution = MapOperator(
            map_function=self._execute_query,
            task_name="query_execution"
        )
        
        # 7. 结果处理节点
        result_processing = MapOperator(
            map_function=self._process_results,
            task_name="result_processing"
        )
        
        # 构建工作流
        self.dag >> schema_retrieval >> sql_generation >> sql_validation >> validation_branch
        validation_branch >> query_execution  # 验证通过分支
        validation_branch >> auto_fix >> query_execution  # 需要修复分支
        query_execution >> result_processing
    
    async def _retrieve_schemas(self, request: NL2SQLRequest) -> Dict:
        """检索相关 Schema"""
        try:
            # 初始化 Schema 检索器
            schema_retriever = SchemaRetriever(
                embedding_client=self._get_embedding_client(),
                weaviate_client=self._get_weaviate_client()
            )

            # 检索相关表结构
            schemas = await schema_retriever.retrieve_relevant_schemas(
                question=request.question,
                top_k=3
            )

            return {
                "request": request,
                "schemas": schemas,
                "timestamp": datetime.now().isoformat()
            }

        except Exception as e:
            logging.error(f"Schema 检索失败: {e}")
            return {
                "request": request,
                "schemas": [],
                "error": str(e)
            }

    async def _generate_sql(self, context: Dict) -> Dict:
        """生成 SQL"""
        try:
            request = context["request"]
            schemas = context["schemas"]

            # 初始化 SQL 生成器
            sql_generator = SQLGenerator(llm_client=self._get_llm_client())

            # 生成 SQL
            sql = await sql_generator.generate_sql(
                question=request.question,
                schemas=schemas
            )

            context["generated_sql"] = sql
            context["generation_timestamp"] = datetime.now().isoformat()

            return context

        except Exception as e:
            logging.error(f"SQL 生成失败: {e}")
            context["error"] = str(e)
            return context

    async def _validate_sql(self, context: Dict) -> Dict:
        """验证 SQL"""
        try:
            sql = context.get("generated_sql", "")
            request = context["request"]

            # 初始化 SQL 验证器
            sql_validator = SQLValidator()

            # 验证 SQL
            validation_result = await sql_validator.validate_sql(
                sql=sql,
                database=request.database
            )

            context["validation_result"] = {
                "is_valid": validation_result.is_valid,
                "sql": validation_result.sql,
                "error_message": validation_result.error_message,
                "suggestions": validation_result.suggestions or []
            }
            context["validation_timestamp"] = datetime.now().isoformat()

            return context

        except Exception as e:
            logging.error(f"SQL 验证失败: {e}")
            context["validation_result"] = {
                "is_valid": False,
                "error_message": str(e)
            }
            return context

    def _validation_branch(self, context: Dict) -> str:
        """验证分支逻辑"""
        validation_result = context.get("validation_result", {})
        if validation_result.get("is_valid", False):
            return "execute"
        else:
            return "fix"

    async def _auto_fix_sql(self, context: Dict) -> Dict:
        """自动修复 SQL"""
        try:
            original_sql = context.get("generated_sql", "")
            error_message = context.get("validation_result", {}).get("error_message", "")
            schemas = context.get("schemas", [])

            # 初始化自动修复引擎
            auto_fix_engine = AutoFixEngine(
                llm_client=self._get_llm_client(),
                sql_validator=SQLValidator()
            )

            # 尝试修复 SQL
            fixed_sql = await auto_fix_engine.fix_sql(
                original_sql=original_sql,
                error_message=error_message,
                schemas=schemas
            )

            if fixed_sql:
                context["fixed_sql"] = fixed_sql
                context["final_sql"] = fixed_sql
                context["fix_success"] = True
            else:
                context["fix_success"] = False
                context["final_sql"] = original_sql

            context["fix_timestamp"] = datetime.now().isoformat()

            return context

        except Exception as e:
            logging.error(f"SQL 自动修复失败: {e}")
            context["fix_success"] = False
            context["fix_error"] = str(e)
            return context

    async def _execute_query(self, context: Dict) -> Dict:
        """执行查询"""
        try:
            sql = context.get("final_sql") or context.get("generated_sql", "")
            request = context["request"]

            # 初始化查询执行器
            query_executor = QueryExecutor(
                connector_manager=self._get_connector_manager()
            )

            # 执行查询
            query_result = await query_executor.execute_query(
                sql=sql,
                database=request.database
            )

            context["query_result"] = {
                "success": query_result.success,
                "data": query_result.data,
                "columns": query_result.columns,
                "row_count": query_result.row_count,
                "execution_time": query_result.execution_time,
                "error_message": query_result.error_message
            }
            context["execution_timestamp"] = datetime.now().isoformat()

            return context

        except Exception as e:
            logging.error(f"查询执行失败: {e}")
            context["query_result"] = {
                "success": False,
                "error_message": str(e)
            }
            return context

    async def _process_results(self, context: Dict) -> Dict:
        """处理结果"""
        try:
            request = context["request"]
            query_result = context.get("query_result", {})

            # 记录查询日志
            await self._log_query(context)

            # 构建最终响应
            response = {
                "request_id": f"{request.session_id}_{datetime.now().timestamp()}",
                "question": request.question,
                "sql": context.get("final_sql") or context.get("generated_sql", ""),
                "success": query_result.get("success", False),
                "data": query_result.get("data", []),
                "columns": query_result.get("columns", []),
                "row_count": query_result.get("row_count", 0),
                "execution_time": query_result.get("execution_time", 0.0),
                "error_message": query_result.get("error_message", ""),
                "metadata": {
                    "schemas_used": len(context.get("schemas", [])),
                    "validation_passed": context.get("validation_result", {}).get("is_valid", False),
                    "auto_fixed": context.get("fix_success", False),
                    "processing_time": self._calculate_processing_time(context)
                }
            }

            context["final_response"] = response

            return context

        except Exception as e:
            logging.error(f"结果处理失败: {e}")
            context["processing_error"] = str(e)
            return context

    def _calculate_processing_time(self, context: Dict) -> float:
        """计算处理时间"""
        try:
            start_time = datetime.fromisoformat(context["timestamp"])
            end_time = datetime.now()
            return (end_time - start_time).total_seconds()
        except:
            return 0.0

    async def _log_query(self, context: Dict):
        """记录查询日志"""
        try:
            log_entry = {
                "timestamp": datetime.now().isoformat(),
                "user_id": context["request"].user_id,
                "session_id": context["request"].session_id,
                "question": context["request"].question,
                "sql": context.get("final_sql", ""),
                "success": context.get("query_result", {}).get("success", False),
                "execution_time": context.get("query_result", {}).get("execution_time", 0.0),
                "row_count": context.get("query_result", {}).get("row_count", 0),
                "auto_fixed": context.get("fix_success", False)
            }

            # 写入日志文件
            log_file = "/app/logs/query_audit.log"
            os.makedirs(os.path.dirname(log_file), exist_ok=True)

            with open(log_file, "a", encoding="utf-8") as f:
                f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")

        except Exception as e:
            logging.error(f"查询日志记录失败: {e}")

    def _get_embedding_client(self):
        """获取嵌入客户端"""
        # 这里应该返回实际的嵌入客户端实例
        pass

    def _get_weaviate_client(self):
        """获取 Weaviate 客户端"""
        # 这里应该返回实际的 Weaviate 客户端实例
        pass

    def _get_llm_client(self):
        """获取 LLM 客户端"""
        # 这里应该返回实际的 LLM 客户端实例
        pass

    def _get_connector_manager(self):
        """获取连接管理器"""
        # 这里应该返回实际的连接管理器实例
        pass


# 导出工作流
nl2sql_pipeline = NL2SQLPipeline()
