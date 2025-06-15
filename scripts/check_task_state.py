#!/usr/bin/env python3
"""
任务状态检查和恢复脚本
用于防止上下文丢失导致的任务进度重置
"""

import json
import os
import sys
from datetime import datetime

TASK_STATE_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'task_state.json')

def load_task_state():
    """加载任务状态"""
    if not os.path.exists(TASK_STATE_FILE):
        print(f"❌ 任务状态文件不存在: {TASK_STATE_FILE}")
        return None
    
    try:
        with open(TASK_STATE_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"❌ 读取任务状态失败: {e}")
        return None

def display_task_state(state):
    """显示任务状态"""
    print("=" * 60)
    print("📋 抖音电商数据分析平台 - 任务状态报告")
    print("=" * 60)
    
    print(f"\n🏗️  项目: {state.get('project', 'Unknown')}")
    print(f"📍 当前阶段: {state.get('current_phase', 'Unknown')}")
    print(f"🕐 最后更新: {state.get('last_updated', 'Unknown')}")
    
    # 显示已完成任务
    print("\n✅ 已完成任务:")
    completed = state.get('completed_tasks', [])
    for i, task in enumerate(completed, 1):
        print(f"   {i}. {task}")
    
    # 显示待完成任务
    print("\n⏳ 待完成任务:")
    pending = state.get('pending_tasks', [])
    for i, task in enumerate(pending, 1):
        print(f"   {i}. {task}")
    
    # 显示当前问题
    print("\n⚠️  当前问题:")
    issues = state.get('current_issues', {})
    for issue_name, issue_data in issues.items():
        status = issue_data.get('status', 'unknown')
        desc = issue_data.get('description', 'No description')
        impact = issue_data.get('impact', 'Unknown impact')
        print(f"\n   🔸 {issue_name} [{status}]")
        print(f"      描述: {desc}")
        print(f"      影响: {impact}")
    
    # 显示重要凭据
    print("\n🔑 重要信息:")
    creds = state.get('important_credentials', {})
    if 'dify_admin' in creds:
        admin = creds['dify_admin']
        print(f"   Dify管理员:")
        print(f"   - URL: {admin.get('url', 'N/A')}")
        print(f"   - 用户名: {admin.get('username', 'N/A')}")
        print(f"   - 密码: {admin.get('password', 'N/A')}")
    
    print("\n" + "=" * 60)

def update_task_state(updates):
    """更新任务状态"""
    state = load_task_state()
    if not state:
        state = {}
    
    # 更新状态
    for key, value in updates.items():
        if key == 'add_completed_task':
            if 'completed_tasks' not in state:
                state['completed_tasks'] = []
            if value not in state['completed_tasks']:
                state['completed_tasks'].append(value)
                # 从待完成任务中移除
                if 'pending_tasks' in state and value in state['pending_tasks']:
                    state['pending_tasks'].remove(value)
        elif key == 'add_pending_task':
            if 'pending_tasks' not in state:
                state['pending_tasks'] = []
            if value not in state['pending_tasks']:
                state['pending_tasks'].append(value)
        else:
            state[key] = value
    
    # 更新时间戳
    state['last_updated'] = datetime.now().isoformat()
    
    # 保存状态
    try:
        with open(TASK_STATE_FILE, 'w', encoding='utf-8') as f:
            json.dump(state, f, ensure_ascii=False, indent=2)
        print(f"✅ 任务状态已更新")
        return True
    except Exception as e:
        print(f"❌ 保存任务状态失败: {e}")
        return False

def main():
    """主函数"""
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == 'show':
            # 显示任务状态
            state = load_task_state()
            if state:
                display_task_state(state)
        
        elif command == 'complete' and len(sys.argv) > 2:
            # 标记任务完成
            task = sys.argv[2]
            update_task_state({'add_completed_task': task})
            print(f"✅ 任务 '{task}' 已标记为完成")
        
        elif command == 'add' and len(sys.argv) > 2:
            # 添加待完成任务
            task = sys.argv[2]
            update_task_state({'add_pending_task': task})
            print(f"✅ 任务 '{task}' 已添加到待完成列表")
        
        elif command == 'phase' and len(sys.argv) > 2:
            # 更新当前阶段
            phase = ' '.join(sys.argv[2:])
            update_task_state({'current_phase': phase})
            print(f"✅ 当前阶段已更新为: {phase}")
        
        else:
            print("用法:")
            print("  python check_task_state.py show              # 显示任务状态")
            print("  python check_task_state.py complete <task>   # 标记任务完成")
            print("  python check_task_state.py add <task>        # 添加待完成任务")
            print("  python check_task_state.py phase <phase>     # 更新当前阶段")
    else:
        # 默认显示状态
        state = load_task_state()
        if state:
            display_task_state(state)

if __name__ == "__main__":
    main()