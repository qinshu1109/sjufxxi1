#!/usr/bin/env python3
"""
基础集成测试脚本
测试项目配置和文件结构，不依赖 DB-GPT 模块
"""

import os
import sys
import json
import logging
from datetime import datetime
from typing import Dict, List


class BasicIntegrationTester:
    """基础集成测试器"""
    
    def __init__(self):
        self.logger = self._setup_logging()
        self.test_results = []
        self.project_root = "/home/qinshu/douyin-analytics"
    
    def _setup_logging(self):
        """设置日志"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        return logging.getLogger(__name__)
    
    def run_all_tests(self):
        """运行所有测试"""
        self.logger.info("开始基础集成测试")
        
        # 测试用例
        test_cases = [
            self.test_project_structure,
            self.test_db_gpt_files,
            self.test_configuration_files,
            self.test_containerfile,
            self.test_podman_compose,
            self.test_awel_flows,
            self.test_scripts,
            self.test_model_config
        ]
        
        for test_case in test_cases:
            try:
                self.logger.info(f"运行测试: {test_case.__name__}")
                result = test_case()
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
    
    def test_project_structure(self) -> bool:
        """测试项目结构"""
        try:
            required_dirs = [
                "external",
                "external/dbgpt",
                "flows",
                "config",
                "scripts",
                "data",
                "data/db"
            ]
            
            for dir_path in required_dirs:
                full_path = os.path.join(self.project_root, dir_path)
                if not os.path.exists(full_path):
                    self.logger.error(f"目录不存在: {full_path}")
                    return False
                self.logger.info(f"目录存在: {dir_path}")
            
            return True
            
        except Exception as e:
            self.logger.error(f"项目结构测试失败: {e}")
            return False
    
    def test_db_gpt_files(self) -> bool:
        """测试 DB-GPT 相关文件"""
        try:
            required_files = [
                "external/dbgpt/Containerfile",
                "external/dbgpt/entrypoint.sh",
                "external/dbgpt/configs/dbgpt-sjufxxi-config.toml"
            ]
            
            for file_path in required_files:
                full_path = os.path.join(self.project_root, file_path)
                if not os.path.exists(full_path):
                    self.logger.error(f"文件不存在: {full_path}")
                    return False
                self.logger.info(f"文件存在: {file_path}")
            
            # 检查 Containerfile 内容
            containerfile = os.path.join(self.project_root, "external/dbgpt/Containerfile")
            with open(containerfile, 'r', encoding='utf-8') as f:
                content = f.read()
                if "sjufxxi" not in content:
                    self.logger.error("Containerfile 中未找到项目标识")
                    return False
            
            # 检查 entrypoint.sh 权限
            entrypoint = os.path.join(self.project_root, "external/dbgpt/entrypoint.sh")
            if not os.access(entrypoint, os.X_OK):
                self.logger.error("entrypoint.sh 没有执行权限")
                return False
            
            return True
            
        except Exception as e:
            self.logger.error(f"DB-GPT 文件测试失败: {e}")
            return False
    
    def test_configuration_files(self) -> bool:
        """测试配置文件"""
        try:
            config_files = [
                "config/model_config.py",
                ".gitmodules"
            ]
            
            for file_path in config_files:
                full_path = os.path.join(self.project_root, file_path)
                if not os.path.exists(full_path):
                    self.logger.error(f"配置文件不存在: {full_path}")
                    return False
                self.logger.info(f"配置文件存在: {file_path}")
            
            # 检查 .gitmodules 内容
            gitmodules = os.path.join(self.project_root, ".gitmodules")
            with open(gitmodules, 'r', encoding='utf-8') as f:
                content = f.read()
                if "external/dbgpt" not in content:
                    self.logger.error(".gitmodules 中未找到 dbgpt 子模块配置")
                    return False
            
            return True
            
        except Exception as e:
            self.logger.error(f"配置文件测试失败: {e}")
            return False
    
    def test_containerfile(self) -> bool:
        """测试 Containerfile"""
        try:
            containerfile = os.path.join(self.project_root, "external/dbgpt/Containerfile")
            
            with open(containerfile, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 检查关键配置
            required_elements = [
                "ubuntu:22.04",  # 更灵活的匹配
                "PYTHON_VERSION=3.11",
                "USER dbgpt",
                "EXPOSE 3000 5000",
                "HEALTHCHECK"
            ]
            
            for element in required_elements:
                if element not in content:
                    self.logger.error(f"Containerfile 中缺少: {element}")
                    return False
            
            self.logger.info("Containerfile 配置验证通过")
            return True
            
        except Exception as e:
            self.logger.error(f"Containerfile 测试失败: {e}")
            return False
    
    def test_podman_compose(self) -> bool:
        """测试 podman-compose 配置"""
        try:
            compose_file = os.path.join(self.project_root, "podman-compose.yml")
            
            with open(compose_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 检查 dbgpt 服务配置
            required_elements = [
                "dbgpt:",
                "build:",
                "context: ./external/dbgpt",
                "dockerfile: Containerfile",
                "DEEPSEEK_API_KEY:",
                "ports:",
                "5000:5000",  # 更灵活的端口匹配
                "3000:3000",
                "volumes:",
                "dbgpt_data:",
                "dbgpt_logs:",
                "dbgpt_config:"
            ]
            
            for element in required_elements:
                if element not in content:
                    self.logger.error(f"podman-compose.yml 中缺少: {element}")
                    return False
            
            self.logger.info("podman-compose.yml 配置验证通过")
            return True
            
        except Exception as e:
            self.logger.error(f"podman-compose 测试失败: {e}")
            return False
    
    def test_awel_flows(self) -> bool:
        """测试 AWEL 工作流文件"""
        try:
            flow_files = [
                "flows/nl2sql_pipeline.py",
                "flows/trend_detection.py"
            ]
            
            for file_path in flow_files:
                full_path = os.path.join(self.project_root, file_path)
                if not os.path.exists(full_path):
                    self.logger.error(f"工作流文件不存在: {full_path}")
                    return False
                
                # 检查文件内容
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if len(content) < 1000:  # 基本的内容长度检查
                        self.logger.error(f"工作流文件内容过少: {file_path}")
                        return False
                
                self.logger.info(f"工作流文件验证通过: {file_path}")
            
            return True
            
        except Exception as e:
            self.logger.error(f"AWEL 工作流测试失败: {e}")
            return False
    
    def test_scripts(self) -> bool:
        """测试脚本文件"""
        try:
            script_files = [
                "scripts/embed_schema.py",
                "scripts/test_dbgpt_integration.py"
            ]
            
            for file_path in script_files:
                full_path = os.path.join(self.project_root, file_path)
                if not os.path.exists(full_path):
                    self.logger.error(f"脚本文件不存在: {full_path}")
                    return False
                
                # 检查执行权限
                if not os.access(full_path, os.X_OK):
                    self.logger.error(f"脚本文件没有执行权限: {file_path}")
                    return False
                
                self.logger.info(f"脚本文件验证通过: {file_path}")
            
            return True
            
        except Exception as e:
            self.logger.error(f"脚本文件测试失败: {e}")
            return False
    
    def test_model_config(self) -> bool:
        """测试模型配置"""
        try:
            config_file = os.path.join(self.project_root, "config/model_config.py")
            
            # 尝试导入配置
            sys.path.insert(0, os.path.join(self.project_root, "config"))
            
            try:
                import model_config
                
                # 检查关键类和函数
                if not hasattr(model_config, 'ModelConfig'):
                    self.logger.error("model_config 中缺少 ModelConfig 类")
                    return False
                
                if not hasattr(model_config, 'model_config'):
                    self.logger.error("model_config 中缺少 model_config 实例")
                    return False
                
                # 测试配置实例
                config = model_config.model_config
                databases = config.databases
                
                if 'douyin_analytics' not in databases:
                    self.logger.error("配置中缺少 douyin_analytics 数据库")
                    return False
                
                self.logger.info("模型配置验证通过")
                return True
                
            except ImportError as e:
                self.logger.error(f"无法导入 model_config: {e}")
                return False
            
        except Exception as e:
            self.logger.error(f"模型配置测试失败: {e}")
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
                "test_type": "基础集成测试",
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
            report_file = os.path.join(self.project_root, "basic_integration_test_report.json")
            with open(report_file, 'w', encoding='utf-8') as f:
                json.dump(report, f, ensure_ascii=False, indent=2)
            
            # 打印摘要
            self.logger.info("=" * 60)
            self.logger.info("DB-GPT 基础集成测试报告")
            self.logger.info("=" * 60)
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
            
            # 总结
            if passed_tests == total_tests:
                self.logger.info("🎉 所有基础集成测试通过！可以继续进行 DB-GPT 部署。")
            else:
                self.logger.warning("⚠️ 部分测试失败，请检查配置后再进行部署。")
            
        except Exception as e:
            self.logger.error(f"生成测试报告失败: {e}")


def main():
    """主函数"""
    tester = BasicIntegrationTester()
    tester.run_all_tests()


if __name__ == "__main__":
    main()
