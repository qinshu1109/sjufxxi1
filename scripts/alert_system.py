#!/usr/bin/env python3
# 告警系统模拟器
import json
import sys
from datetime import datetime

def send_alert(alert_type, message, data=None):
    """发送告警"""
    alert = {
        "timestamp": datetime.now().isoformat(),
        "type": alert_type,
        "message": message,
        "data": data or {}
    }
    
    print(f"🚨 告警 [{alert_type.upper()}]: {message}")
    
    # 保存告警记录
    with open('alert_log.json', 'a', encoding='utf-8') as f:
        f.write(json.dumps(alert, ensure_ascii=False) + '\n')
    
    return True

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 alert_system.py <type> <message>")
        sys.exit(1)
    
    alert_type = sys.argv[1]
    message = sys.argv[2]
    send_alert(alert_type, message)
