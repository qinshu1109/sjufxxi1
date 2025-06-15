#!/bin/bash
#
# 上下文保护脚本
# 用于定期保存任务状态，防止上下文丢失
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
STATE_FILE="$PROJECT_DIR/task_state.json"
BACKUP_DIR="$PROJECT_DIR/.task_state_backups"

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 备份当前状态
backup_state() {
    if [ -f "$STATE_FILE" ]; then
        timestamp=$(date +%Y%m%d_%H%M%S)
        cp "$STATE_FILE" "$BACKUP_DIR/task_state_${timestamp}.json"
        echo "✅ 任务状态已备份: task_state_${timestamp}.json"
        
        # 只保留最近10个备份
        ls -t "$BACKUP_DIR"/task_state_*.json 2>/dev/null | tail -n +11 | xargs -r rm
    fi
}

# 创建CLAUDE.md文件记录当前状态
create_claude_md() {
    cat > "$PROJECT_DIR/CLAUDE.md" << 'EOF'
# Claude Context Guide - 抖音电商数据分析平台

## 项目概述
这是一个基于DuckDB和Dify的抖音电商数据分析平台。

## 当前状态
请运行以下命令查看最新任务状态：
```bash
python3 scripts/check_task_state.py show
```

## 重要信息
- **Dify管理员**: 
  - URL: http://localhost/
  - 用户名: qinshu
  - 密码: zhou1109
- **数据库**: DuckDB (已初始化8条测试数据)
- **API**: DeepSeek (已配置)

## 已知问题
1. **插件安装错误**: "Failed to request plugin daemon" - 不影响核心功能
2. **上下文回滚**: 任务状态可能在长对话中丢失

## 任务管理
更新任务状态的命令：
- 显示状态: `python3 scripts/check_task_state.py show`
- 完成任务: `python3 scripts/check_task_state.py complete <task_name>`
- 添加任务: `python3 scripts/check_task_state.py add <task_name>`
- 更新阶段: `python3 scripts/check_task_state.py phase <phase_name>`

## 项目结构
```
douyin-analytics/
├── config/          # 配置文件
├── scripts/         # 脚本工具
├── dify/           # Dify平台（子模块）
├── task_state.json # 任务状态跟踪
└── CLAUDE.md       # 本文件
```

## 下一步行动
1. 修复插件安装错误
2. 配置DuckDB数据源
3. 创建ChatFlow工作流
4. 配置飞书Webhook
5. 完成端到端测试

## 恢复提示
如果上下文丢失，请：
1. 运行 `python3 scripts/check_task_state.py show` 查看状态
2. 检查 `.task_state_backups/` 目录中的备份
3. 继续未完成的任务
EOF
    
    echo "✅ CLAUDE.md 文件已更新"
}

# 显示使用帮助
show_help() {
    echo "使用方法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  backup    - 备份当前任务状态"
    echo "  restore   - 从最新备份恢复状态"
    echo "  update    - 更新CLAUDE.md文件"
    echo "  guard     - 执行完整的上下文保护（备份+更新）"
    echo "  help      - 显示此帮助信息"
}

# 恢复最新备份
restore_latest() {
    latest_backup=$(ls -t "$BACKUP_DIR"/task_state_*.json 2>/dev/null | head -1)
    if [ -n "$latest_backup" ]; then
        cp "$latest_backup" "$STATE_FILE"
        echo "✅ 已从备份恢复: $(basename "$latest_backup")"
        python3 "$SCRIPT_DIR/check_task_state.py" show
    else
        echo "❌ 未找到备份文件"
    fi
}

# 主逻辑
case "${1:-guard}" in
    backup)
        backup_state
        ;;
    restore)
        restore_latest
        ;;
    update)
        create_claude_md
        ;;
    guard)
        backup_state
        create_claude_md
        echo "✅ 上下文保护完成"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "无效命令: $1"
        show_help
        exit 1
        ;;
esac