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
