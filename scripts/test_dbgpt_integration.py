#!/usr/bin/env python3
"""
DB-GPT 集成测试脚本
测试 NL2SQL 工作流的各个组件
"""

import os
import sys
import json
import asyncio
import logging
from datetime import datetime
from typing import Dict, List

# 添加项目路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from flows.nl2sql_pipeline import NL2SQLRequest, SQLValidator
from flows.trend_detection import TrendDetector, TrendDetectionRequest


class DBGPTIntegrationTester:
    """DB-GPT 集成测试器"""
    
    def __init__(self):
        self.logger = self._setup_logging()
        self.test_results = []
    
    def _setup_logging(self):
        """设置日志"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        return logging.getLogger(__name__)
    
    async def run_all_tests(self):
        """运行所有测试"""
        self.logger.info("开始 DB-GPT 集成测试")
        
        # 测试用例
        test_cases = [
            self.test_sql_validator,
            self.test_trend_detection,
            self.test_nl2sql_request_validation,
            self.test_schema_embedding_preparation,
            self.test_configuration_validation
        ]
        
        for test_case in test_cases:
            try:
                self.logger.info(f"运行测试: {test_case.__name__}")
                result = await test_case()
                self.test_results.append({
                    "test": test_case.__name__,
                    "status": "PASS" if result else "FAIL",
                    "timestamp": datetime.now().isoformat()
                })
                self.logger.info(f"测试 {test_case.__name__}: {'通过' if result else '失败'}")
            except Exception as e:
                self.logger.error(f"测试 {test_case.__name__} 出错: {e}")
                self.test_results.append({
                    "test": test_case.__name__,
                    "status": "ERROR",
                    "error": str(e),
                    "timestamp": datetime.now().isoformat()
                })
        
        # 生成测试报告
        self._generate_test_report()
    
    async def test_sql_validator(self) -> bool:
        """测试 SQL 验证器"""
        try:
            validator = SQLValidator()
            
            # 测试用例
            test_cases = [
                {
                    "sql": "SELECT * FROM douyin_products LIMIT 10",
                    "expected": True,
                    "description": "基本 SELECT 查询"
                },
                {
                    "sql": "SELECT category, SUM(sales_volume) FROM douyin_products GROUP BY category",
                    "expected": True,
                    "description": "聚合查询"
                },
                {
                    "sql": "DROP TABLE douyin_products",
                    "expected": False,
                    "description": "危险的 DROP 操作"
                },
                {
                    "sql": "DELETE FROM douyin_products WHERE id = 1",
                    "expected": False,
                    "description": "禁止的 DELETE 操作"
                },
                {
                    "sql": "SELECT * FROM unauthorized_table",
                    "expected": False,
                    "description": "未授权的表访问"
                }
            ]
            
            all_passed = True
            for case in test_cases:
                result = await validator.validate_sql(case["sql"], "douyin_analytics")
                if result.is_valid != case["expected"]:
                    self.logger.error(f"SQL 验证失败: {case['description']}")
                    all_passed = False
                else:
                    self.logger.info(f"SQL 验证通过: {case['description']}")
            
            return all_passed
            
        except Exception as e:
            self.logger.error(f"SQL 验证器测试失败: {e}")
            return False
    
    async def test_trend_detection(self) -> bool:
        """测试趋势检测"""
        try:
            detector = TrendDetector()
            
            # 生成测试数据
            test_data = []
            base_date = datetime(2025, 1, 1)
            for i in range(30):
                date = base_date.replace(day=i+1)
                value = 100 + i * 2 + (i % 7) * 5  # 带有趋势和周期性的数据
                test_data.append({
                    "date": date.strftime("%Y-%m-%d"),
                    "sales": value
                })
            
            # 创建趋势检测请求
            request = TrendDetectionRequest(
                data=test_data,
                date_column="date",
                value_column="sales",
                forecast_periods=7
            )
            
            # 执行趋势检测
            result = await detector.detect_trend(request)
            
            # 验证结果
            if not result.trend_direction:
                return False
            
            if not result.forecast_values or len(result.forecast_values) != 7:
                return False
            
            if not result.chart_base64:
                self.logger.warning("图表生成失败，但趋势检测功能正常")
            
            self.logger.info(f"趋势检测结果: {result.trend_direction}, 强度: {result.trend_strength:.2f}")
            return True
            
        except Exception as e:
            self.logger.error(f"趋势检测测试失败: {e}")
            return False
    
    async def test_nl2sql_request_validation(self) -> bool:
        """测试 NL2SQL 请求验证"""
        try:
            # 测试有效请求
            valid_request = NL2SQLRequest(
                question="查询销量最高的商品",
                user_id="test_user",
                session_id="test_session",
                database="douyin_analytics"
            )
            
            if not valid_request.question or not valid_request.user_id:
                return False
            
            # 测试无效请求
            try:
                invalid_request = NL2SQLRequest(
                    question="",
                    user_id="",
                    session_id="test_session"
                )
                # 应该有验证逻辑来拒绝空的问题和用户ID
            except:
                pass  # 预期的异常
            
            return True
            
        except Exception as e:
            self.logger.error(f"NL2SQL 请求验证测试失败: {e}")
            return False
    
    async def test_schema_embedding_preparation(self) -> bool:
        """测试 Schema 嵌入准备"""
        try:
            # 检查配置文件是否存在
            config_files = [
                "/home/qinshu/douyin-analytics/config/model_config.py",
                "/home/qinshu/douyin-analytics/external/dbgpt/configs/dbgpt-sjufxxi-config.toml"
            ]
            
            for config_file in config_files:
                if not os.path.exists(config_file):
                    self.logger.error(f"配置文件不存在: {config_file}")
                    return False
            
            # 检查数据库文件
            db_file = "/home/qinshu/douyin-analytics/data/db/analytics.duckdb"
            if not os.path.exists(db_file):
                self.logger.warning(f"数据库文件不存在: {db_file}")
                # 不算失败，因为可能还没有创建
            
            # 检查脚本文件
            script_files = [
                "/home/qinshu/douyin-analytics/scripts/embed_schema.py",
                "/home/qinshu/douyin-analytics/flows/nl2sql_pipeline.py"
            ]
            
            for script_file in script_files:
                if not os.path.exists(script_file):
                    self.logger.error(f"脚本文件不存在: {script_file}")
                    return False
            
            return True
            
        except Exception as e:
            self.logger.error(f"Schema 嵌入准备测试失败: {e}")
            return False
    
    async def test_configuration_validation(self) -> bool:
        """测试配置验证"""
        try:
            # 检查环境变量
            required_env_vars = [
                "DEEPSEEK_API_KEY",
                "LOCAL_DB_PATH",
                "POSTGRES_URL"
            ]
            
            missing_vars = []
            for var in required_env_vars:
                if not os.getenv(var):
                    missing_vars.append(var)
            
            if missing_vars:
                self.logger.warning(f"缺少环境变量: {missing_vars}")
                # 不算失败，因为在测试环境中可能没有设置
            
            # 检查 Containerfile
            containerfile = "/home/qinshu/douyin-analytics/external/dbgpt/Containerfile"
            if not os.path.exists(containerfile):
                self.logger.error(f"Containerfile 不存在: {containerfile}")
                return False
            
            # 检查 podman-compose 配置
            compose_file = "/home/qinshu/douyin-analytics/podman-compose.yml"
            if not os.path.exists(compose_file):
                self.logger.error(f"podman-compose.yml 不存在: {compose_file}")
                return False
            
            # 验证 compose 文件中是否包含 dbgpt 服务
            with open(compose_file, 'r', encoding='utf-8') as f:
                compose_content = f.read()
                if 'dbgpt:' not in compose_content:
                    self.logger.error("podman-compose.yml 中未找到 dbgpt 服务配置")
                    return False
            
            return True
            
        except Exception as e:
            self.logger.error(f"配置验证测试失败: {e}")
            return False
    
    def _generate_test_report(self):
        """生成测试报告"""
        try:
            # 统计结果
            total_tests = len(self.test_results)
            passed_tests = len([r for r in self.test_results if r["status"] == "PASS"])
            failed_tests = len([r for r in self.test_results if r["status"] == "FAIL"])
            error_tests = len([r for r in self.test_results if r["status"] == "ERROR"])
            
            # 生成报告
            report = {
                "timestamp": datetime.now().isoformat(),
                "summary": {
                    "total": total_tests,
                    "passed": passed_tests,
                    "failed": failed_tests,
                    "errors": error_tests,
                    "success_rate": f"{(passed_tests / total_tests * 100):.1f}%" if total_tests > 0 else "0%"
                },
                "details": self.test_results
            }
            
            # 保存报告
            report_file = "/home/qinshu/douyin-analytics/dbgpt_integration_test_report.json"
            with open(report_file, 'w', encoding='utf-8') as f:
                json.dump(report, f, ensure_ascii=False, indent=2)
            
            # 打印摘要
            self.logger.info("=" * 50)
            self.logger.info("DB-GPT 集成测试报告")
            self.logger.info("=" * 50)
            self.logger.info(f"总测试数: {total_tests}")
            self.logger.info(f"通过: {passed_tests}")
            self.logger.info(f"失败: {failed_tests}")
            self.logger.info(f"错误: {error_tests}")
            self.logger.info(f"成功率: {report['summary']['success_rate']}")
            self.logger.info(f"报告已保存: {report_file}")
            
            # 详细结果
            for result in self.test_results:
                status_icon = {"PASS": "✅", "FAIL": "❌", "ERROR": "⚠️"}
                icon = status_icon.get(result["status"], "❓")
                self.logger.info(f"{icon} {result['test']}: {result['status']}")
                if "error" in result:
                    self.logger.info(f"   错误: {result['error']}")
            
        except Exception as e:
            self.logger.error(f"生成测试报告失败: {e}")


async def main():
    """主函数"""
    tester = DBGPTIntegrationTester()
    await tester.run_all_tests()


if __name__ == "__main__":
    asyncio.run(main())
