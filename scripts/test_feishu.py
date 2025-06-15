#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
飞书机器人告警测试脚本
测试飞书Webhook集成功能
"""

import sys
import os
import json
import requests
import time
from datetime import datetime

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def load_feishu_config():
    """加载飞书配置"""
    config_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'config', 'feishu_config.py')
    if not os.path.exists(config_path):
        print("❌ 飞书配置文件不存在")
        return None
    
    # 动态导入配置
    spec = importlib.util.spec_from_file_location("feishu_config", config_path)
    config = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(config)
    
    return config

def send_test_message(webhook_url, message):
    """发送测试消息到飞书"""
    payload = {
        "msg_type": "text",
        "content": {
            "text": message
        }
    }
    
    try:
        response = requests.post(webhook_url, json=payload, timeout=10)
        response.raise_for_status()
        return True, response.json()
    except Exception as e:
        return False, str(e)

def test_basic_connectivity():
    """测试基本连接性"""
    print("🔍 测试1: 基本连接性测试")
    
    # 测试网络连接
    try:
        response = requests.get("https://www.feishu.cn", timeout=5)
        print("✅ 网络连接正常")
        return True
    except Exception as e:
        print(f"❌ 网络连接失败: {e}")
        return False

def test_webhook_message():
    """测试Webhook消息发送"""
    print("\n🔍 测试2: Webhook消息发送测试")
    
    # 加载配置
    try:
        import importlib.util
        config = load_feishu_config()
        if not config:
            return False
        
        webhook_url = config.FEISHU_WEBHOOK_URL
    except Exception as e:
        print(f"❌ 配置加载失败: {e}")
        return False
    
    # 发送测试消息
    test_message = f"🤖 抖音数据分析平台测试消息\n⏰ 时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n📊 状态: 系统正常运行"
    
    success, result = send_test_message(webhook_url, test_message)
    
    if success:
        print("✅ 飞书消息发送成功")
        print(f"📝 响应: {result}")
        return True
    else:
        print(f"❌ 飞书消息发送失败: {result}")
        return False

def test_alert_scenarios():
    """测试不同告警场景"""
    print("\n🔍 测试3: 告警场景测试")
    
    scenarios = [
        {
            "name": "销量异常告警",
            "message": "🚨 销量异常告警\n📈 产品: 测试商品A\n📊 当前销量: 1000\n📉 预期销量: 500\n⚠️ 异常幅度: +100%"
        },
        {
            "name": "数据更新通知",
            "message": "📊 数据更新通知\n🔄 更新时间: {}\n📁 数据量: 150条\n✅ 状态: 更新成功".format(datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        },
        {
            "name": "系统状态报告",
            "message": "📋 系统状态报告\n🖥️ Dify状态: 运行中\n💾 数据库状态: 正常\n🔗 API状态: 可用\n⏱️ 响应时间: <100ms"
        }
    ]
    
    try:
        import importlib.util
        config = load_feishu_config()
        webhook_url = config.FEISHU_WEBHOOK_URL
    except Exception as e:
        print(f"❌ 配置加载失败: {e}")
        return False
    
    success_count = 0
    for scenario in scenarios:
        print(f"\n📤 发送: {scenario['name']}")
        success, result = send_test_message(webhook_url, scenario['message'])
        
        if success:
            print(f"✅ {scenario['name']} 发送成功")
            success_count += 1
        else:
            print(f"❌ {scenario['name']} 发送失败: {result}")
        
        time.sleep(1)  # 避免频率限制
    
    print(f"\n📊 告警测试结果: {success_count}/{len(scenarios)} 成功")
    return success_count == len(scenarios)

def main():
    """主函数"""
    print("🚀 飞书机器人告警测试开始")
    print("=" * 50)
    
    tests = [
        test_basic_connectivity,
        test_webhook_message,
        test_alert_scenarios
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
            else:
                print("❌ 测试失败")
        except Exception as e:
            print(f"❌ 测试异常: {e}")
    
    print("\n" + "=" * 50)
    print(f"📊 测试总结: {passed}/{total} 通过")
    
    if passed == total:
        print("🎉 所有测试通过！飞书集成工作正常")
        return 0
    else:
        print("⚠️ 部分测试失败，请检查配置")
        return 1

if __name__ == "__main__":
    sys.exit(main())
