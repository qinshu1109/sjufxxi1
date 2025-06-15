#!/usr/bin/env python3
"""
飞书机器人配置和测试脚本
"""

import requests
import json
from datetime import datetime

# 飞书机器人配置
FEISHU_WEBHOOK_URL = "https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK_ID"  # 请替换为实际URL

def send_feishu_message(message, title="抖音数据分析"):
    """发送消息到飞书群"""
    
    payload = {
        "msg_type": "interactive",
        "card": {
            "config": {
                "wide_screen_mode": True
            },
            "header": {
                "title": {
                    "tag": "plain_text",
                    "content": title
                },
                "template": "blue"
            },
            "elements": [
                {
                    "tag": "div",
                    "text": {
                        "tag": "lark_md",
                        "content": message
                    }
                }
            ]
        }
    }
    
    try:
        response = requests.post(FEISHU_WEBHOOK_URL, json=payload)
        if response.status_code == 200:
            print("✅ 飞书消息发送成功")
            return True
        else:
            print(f"❌ 飞书消息发送失败: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 发送失败: {str(e)}")
        return False

def test_feishu_bot():
    """测试飞书机器人"""
    test_message = f"""
📊 **抖音数据分析系统测试**

🕐 测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

✅ 系统状态: 正常运行
📈 数据状态: 已就绪
🔔 告警功能: 正常

---
这是一条测试消息，如果您收到此消息，说明飞书机器人配置成功！
    """
    
    return send_feishu_message(test_message, "系统测试")

if __name__ == "__main__":
    if FEISHU_WEBHOOK_URL == "https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK_ID":
        print("⚠️  请先在脚本中配置正确的飞书Webhook URL")
    else:
        test_feishu_bot()