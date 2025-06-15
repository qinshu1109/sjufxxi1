#!/usr/bin/env python3
"""
抖音数据分析系统验收测试脚本
按照用户提供的验收框架进行全面测试
"""
import os
import sys
import json
import subprocess
import sqlite3
from datetime import datetime, timedelta
import pandas as pd
import duckdb

class AcceptanceTest:
    def __init__(self):
        self.project_dir = os.path.expanduser("~/douyin-analytics")
        self.db_path = f"{self.project_dir}/data/db/analytics.duckdb"
        self.results = {
            "timestamp": datetime.now().isoformat(),
            "tests": [],
            "summary": {"passed": 0, "failed": 0, "skipped": 0}
        }
        
    def log_test(self, test_name, status, message, details=None):
        """记录测试结果"""
        test_result = {
            "test": test_name,
            "status": status,
            "message": message,
            "details": details or {},
            "timestamp": datetime.now().isoformat()
        }
        self.results["tests"].append(test_result)
        self.results["summary"][status] += 1
        
        status_icon = {"passed": "✅", "failed": "❌", "skipped": "⏭️"}
        print(f"{status_icon[status]} {test_name}: {message}")
        
    def test_environment_setup(self):
        """测试1: 环境基础设置"""
        print("\n🔍 测试1: 环境基础设置")
        print("-" * 30)
        
        # 检查项目目录结构
        required_dirs = ["data/db", "data/csv", "scripts", "config"]
        for dir_path in required_dirs:
            full_path = f"{self.project_dir}/{dir_path}"
            if os.path.exists(full_path):
                self.log_test(f"目录检查: {dir_path}", "passed", "目录存在")
            else:
                self.log_test(f"目录检查: {dir_path}", "failed", "目录缺失")
        
        # 检查DuckDB
        if os.path.exists(self.db_path):
            self.log_test("DuckDB数据库", "passed", "数据库文件存在")
        else:
            self.log_test("DuckDB数据库", "failed", "数据库文件缺失")
            
        # 检查Python环境
        try:
            import pandas
            import duckdb
            self.log_test("Python依赖", "passed", "pandas和duckdb已安装")
        except ImportError as e:
            self.log_test("Python依赖", "failed", f"依赖缺失: {e}")

    def test_data_generation_and_import(self):
        """测试2: 数据生成和导入"""
        print("\n📊 测试2: 数据生成和导入")
        print("-" * 30)
        
        # 检查测试数据文件
        csv_path = f"{self.project_dir}/data/csv/douyin_test_data_30days.csv"
        if os.path.exists(csv_path):
            try:
                df = pd.read_csv(csv_path)
                record_count = len(df)
                product_count = df['sku'].nunique()
                date_range = f"{df['date'].min()} ~ {df['date'].max()}"
                
                self.log_test("测试数据文件", "passed", 
                            f"数据文件存在，{record_count}条记录",
                            {"records": record_count, "products": product_count, "date_range": date_range})
                
                # 验证数据质量
                if record_count >= 150:  # 5产品 * 30天
                    self.log_test("数据完整性", "passed", "数据记录数量符合预期")
                else:
                    self.log_test("数据完整性", "failed", f"数据记录不足: {record_count}")
                    
            except Exception as e:
                self.log_test("测试数据文件", "failed", f"数据文件读取失败: {e}")
        else:
            self.log_test("测试数据文件", "failed", "测试数据文件不存在")
        
        # 检查DuckDB导入
        try:
            conn = duckdb.connect(self.db_path)
            
            # 检查表存在性
            tables = conn.execute("SHOW TABLES").fetchall()
            table_names = [table[0] for table in tables]
            
            expected_tables = ["douyin_sales_detail", "douyin_products"]
            for table in expected_tables:
                if table in table_names:
                    self.log_test(f"数据表: {table}", "passed", "表已创建")
                else:
                    self.log_test(f"数据表: {table}", "failed", "表不存在")
            
            # 检查数据导入
            if "douyin_sales_detail" in table_names:
                count = conn.execute("SELECT COUNT(*) FROM douyin_sales_detail").fetchone()[0]
                if count > 0:
                    self.log_test("数据导入", "passed", f"成功导入{count}条销售记录")
                else:
                    self.log_test("数据导入", "failed", "销售数据表为空")
            
            conn.close()
            
        except Exception as e:
            self.log_test("DuckDB连接", "failed", f"数据库连接失败: {e}")

    def test_data_analysis_functions(self):
        """测试3: 数据分析功能"""
        print("\n🔍 测试3: 数据分析功能")
        print("-" * 30)
        
        try:
            conn = duckdb.connect(self.db_path)
            
            # 基础统计查询
            basic_stats = conn.execute("""
                SELECT 
                    COUNT(*) as total_records,
                    COUNT(DISTINCT sku) as unique_products,
                    SUM(daily_sales) as total_sales,
                    ROUND(AVG(daily_sales), 2) as avg_sales,
                    MIN(date) as start_date,
                    MAX(date) as end_date
                FROM douyin_sales_detail
            """).fetchone()
            
            if basic_stats[0] > 0:
                self.log_test("基础统计", "passed", "统计查询执行成功",
                            {"总记录": basic_stats[0], "产品数": basic_stats[1], 
                             "总销量": basic_stats[2], "平均销量": basic_stats[3]})
            else:
                self.log_test("基础统计", "failed", "统计查询返回空结果")
            
            # 异常检测查询
            anomalies = conn.execute("""
                SELECT 
                    COUNT(*) as anomaly_count
                FROM douyin_sales_detail 
                WHERE daily_sales > 5000
            """).fetchone()[0]
            
            self.log_test("异常检测", "passed", f"检测到{anomalies}个异常销量数据点")
            
            # 品牌分析
            brand_analysis = conn.execute("""
                SELECT 
                    brand,
                    COUNT(*) as days,
                    SUM(daily_sales) as total_sales,
                    ROUND(AVG(daily_sales), 0) as avg_sales
                FROM douyin_sales_detail
                GROUP BY brand
                ORDER BY total_sales DESC
                LIMIT 3
            """).fetchall()
            
            if len(brand_analysis) > 0:
                self.log_test("品牌分析", "passed", f"成功分析{len(brand_analysis)}个品牌数据")
            else:
                self.log_test("品牌分析", "failed", "品牌分析查询失败")
            
            # 时间趋势分析
            trend_analysis = conn.execute("""
                SELECT 
                    DATE_PART('week', CAST(date AS DATE)) as week_num,
                    COUNT(DISTINCT date) as days,
                    SUM(daily_sales) as weekly_sales
                FROM douyin_sales_detail
                GROUP BY DATE_PART('week', CAST(date AS DATE))
                ORDER BY week_num
            """).fetchall()
            
            if len(trend_analysis) > 0:
                self.log_test("时间趋势", "passed", f"成功分析{len(trend_analysis)}周的趋势数据")
            else:
                self.log_test("时间趋势", "failed", "趋势分析查询失败")
            
            conn.close()
            
        except Exception as e:
            self.log_test("数据分析功能", "failed", f"分析查询失败: {e}")

    def test_alert_system(self):
        """测试4: 告警系统"""
        print("\n🚨 测试4: 告警系统")
        print("-" * 30)
        
        # 检查Webhook配置
        config_path = f"{self.project_dir}/config/webhook_config.json"
        if os.path.exists(config_path):
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                
                if 'feishu' in config and 'webhook_url' in config['feishu']:
                    self.log_test("Webhook配置", "passed", "配置文件存在且格式正确")
                else:
                    self.log_test("Webhook配置", "failed", "配置格式不正确")
                    
            except Exception as e:
                self.log_test("Webhook配置", "failed", f"配置文件解析失败: {e}")
        else:
            self.log_test("Webhook配置", "failed", "Webhook配置文件不存在")
        
        # 测试告警系统脚本
        alert_script = f"{self.project_dir}/scripts/alert_system.py"
        if os.path.exists(alert_script):
            try:
                result = subprocess.run([
                    sys.executable, alert_script, "test", "验收测试告警消息"
                ], capture_output=True, text=True, timeout=10)
                
                if result.returncode == 0:
                    self.log_test("告警系统", "passed", "告警脚本执行成功")
                else:
                    self.log_test("告警系统", "failed", f"告警脚本执行失败: {result.stderr}")
                    
            except Exception as e:
                self.log_test("告警系统", "failed", f"告警脚本测试失败: {e}")
        else:
            self.log_test("告警系统", "skipped", "告警脚本不存在")

    def test_dify_integration(self):
        """测试5: Dify平台集成"""
        print("\n🤖 测试5: Dify平台集成")
        print("-" * 30)
        
        # 检查Dify容器状态
        try:
            result = subprocess.run([
                "docker", "compose", "ps"
            ], capture_output=True, text=True, cwd=f"{self.project_dir}/dify/docker")
            
            if "Up" in result.stdout:
                self.log_test("Dify容器", "passed", "Dify服务正在运行")
            else:
                self.log_test("Dify容器", "failed", "Dify服务未运行")
                
        except Exception as e:
            self.log_test("Dify容器", "failed", f"容器状态检查失败: {e}")
        
        # 检查网络修复脚本
        network_scripts = [
            "ultimate_dify_network_fix.sh",
            "precise_network_fix.sh"
        ]
        
        for script in network_scripts:
            script_path = f"{self.project_dir}/{script}"
            if os.path.exists(script_path):
                self.log_test(f"网络修复: {script}", "passed", "脚本存在")
            else:
                self.log_test(f"网络修复: {script}", "skipped", "脚本不存在")

    def test_system_integration(self):
        """测试6: 系统集成"""
        print("\n🔗 测试6: 系统集成")
        print("-" * 30)
        
        # 检查系统组件协作
        components = {
            "数据生成": f"{self.project_dir}/scripts/generate_test_data.py",
            "数据导入": f"{self.project_dir}/scripts/import_test_data.sh",
            "Webhook配置": f"{self.project_dir}/scripts/config_feishu_webhook.py",
            "验收测试": f"{self.project_dir}/scripts/acceptance_test.py"
        }
        
        missing_components = []
        for name, path in components.items():
            if os.path.exists(path):
                self.log_test(f"组件: {name}", "passed", "组件文件存在")
            else:
                self.log_test(f"组件: {name}", "failed", "组件文件缺失")
                missing_components.append(name)
        
        if len(missing_components) == 0:
            self.log_test("系统完整性", "passed", "所有核心组件已部署")
        else:
            self.log_test("系统完整性", "failed", f"缺失组件: {', '.join(missing_components)}")

    def generate_report(self):
        """生成验收报告"""
        print("\n📄 生成验收报告")
        print("-" * 30)
        
        # 保存详细结果
        report_path = f"{self.project_dir}/validation_report.json"
        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)
        
        # 生成文本报告
        total_tests = sum(self.results["summary"].values())
        success_rate = round(self.results["summary"]["passed"] / total_tests * 100, 1) if total_tests > 0 else 0
        
        text_report = f"""
# 抖音数据分析系统验收报告

## 测试概览
- 🗓️ 测试时间: {self.results['timestamp']}
- 📊 测试总数: {total_tests}
- ✅ 通过: {self.results['summary']['passed']}
- ❌ 失败: {self.results['summary']['failed']}
- ⏭️ 跳过: {self.results['summary']['skipped']}
- 🎯 成功率: {success_rate}%

## 测试结果详情
"""
        
        for test in self.results["tests"]:
            status_icon = {"passed": "✅", "failed": "❌", "skipped": "⏭️"}
            text_report += f"- {status_icon[test['status']]} **{test['test']}**: {test['message']}\n"
        
        text_report += f"""
## 系统状态评估
"""
        
        if success_rate >= 90:
            text_report += "🎉 **优秀**: 系统运行状态良好，可以投入生产使用"
        elif success_rate >= 70:
            text_report += "⚠️ **良好**: 系统基本功能正常，建议修复失败项目后使用"
        else:
            text_report += "🚨 **需要改进**: 系统存在较多问题，建议修复后重新测试"
        
        text_report += f"""

## 建议后续行动
1. 🔧 修复失败的测试项目
2. 🔄 完善告警和监控系统  
3. 📝 补充文档和使用指南
4. 🧪 定期执行验收测试

---
*报告生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*
"""
        
        report_text_path = f"{self.project_dir}/validation_report.md"
        with open(report_text_path, 'w', encoding='utf-8') as f:
            f.write(text_report)
        
        print(f"✅ 详细报告已保存到:")
        print(f"  - JSON格式: {report_path}")
        print(f"  - Markdown格式: {report_text_path}")
        
        return report_path

    def run_all_tests(self):
        """执行全部验收测试"""
        print("🎯 抖音数据分析系统验收测试开始")
        print("=" * 50)
        
        test_methods = [
            self.test_environment_setup,
            self.test_data_generation_and_import,
            self.test_data_analysis_functions,
            self.test_alert_system,
            self.test_dify_integration,
            self.test_system_integration
        ]
        
        for test_method in test_methods:
            try:
                test_method()
            except Exception as e:
                test_name = test_method.__name__.replace('test_', '').replace('_', ' ').title()
                self.log_test(test_name, "failed", f"测试执行异常: {e}")
        
        print("\n🎉 验收测试完成!")
        print("=" * 50)
        print(f"📊 测试结果: {self.results['summary']['passed']}通过 / {self.results['summary']['failed']}失败 / {self.results['summary']['skipped']}跳过")
        
        report_path = self.generate_report()
        return self.results, report_path

if __name__ == "__main__":
    test_runner = AcceptanceTest()
    results, report_path = test_runner.run_all_tests()
    
    # 返回退出码
    if results["summary"]["failed"] > 0:
        sys.exit(1)
    else:
        sys.exit(0)