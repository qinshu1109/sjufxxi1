# 🎭 VS Code PromptX-MCP 集成指南

## 📋 概述

本指南介绍如何在 VS Code 中使用 PromptX-MCP 服务，实现 AI 专业角色增强系统与 VS Code Copilot 的深度集成。

## 🚀 快速开始

### 1. 启动 VS Code MCP 环境

```bash
# 方法1: 使用启动脚本
./scripts/launch_vscode_mcp.sh

# 方法2: 直接启动 VS Code
code douyin-analytics.code-workspace
```

### 2. 验证配置

```bash
# 验证 MCP 配置
./scripts/verify_vscode_mcp.sh
```

## 🔧 配置文件说明

### VS Code MCP 配置 (`.vscode/mcp.json`)

```json
{
  "inputs": [
    {
      "type": "promptString",
      "id": "github-token",
      "description": "GitHub Personal Access Token",
      "password": true
    }
  ],
  "servers": {
    "promptx": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "-f", "dpml-prompt@snapshot", "mcp-server"],
      "env": {
        "PROMPTX_WORKSPACE": "${workspaceFolder}"
      }
    }
  }
}
```

### VS Code 设置 (`.vscode/settings.json`)

```json
{
  "chat.mcp.enabled": true,
  "chat.mcp.discovery.enabled": true,
  "copilot.enable": {
    "*": true
  }
}
```

## 🎯 使用方法

### 1. 启用 Agent 模式

1. 打开 VS Code
2. 按 `Ctrl+Alt+I` 打开 Copilot Chat
3. 在聊天模式下拉菜单中选择 **Agent**
4. 点击 **Tools** 按钮查看可用工具

### 2. 使用 PromptX 工具

#### 发现可用角色
```
请使用 #promptx_hello 工具发现所有可用的专业角色
```

#### 激活女娲角色
```
请使用 #promptx_action 工具激活 nuwa 角色
```

#### 使用 MCP 提示
```
/mcp.promptx.hello
/mcp.promptx.action nuwa
```

### 3. 添加 MCP 资源

1. 在 Chat 视图中点击 **Add Context**
2. 选择 **MCP Resources**
3. 选择需要的资源类型
4. 提供必要的参数

### 4. 工具确认和参数编辑

- 当工具被调用时，VS Code 会显示确认对话框
- 可以选择自动确认特定工具
- 可以编辑工具输入参数

## 🛠️ 可用工具列表

### 基础 MCP 工具 (10个)

| 工具名 | 功能 | 用途 |
|--------|------|------|
| `filesystem` | 文件系统访问 | 读写文件、目录操作 |
| `github` | GitHub 仓库管理 | 创建 PR、管理 Issues |
| `git` | Git 版本控制 | 提交、分支管理 |
| `fetch` | HTTP 请求处理 | API 调用、数据获取 |
| `memory` | 内存存储 | 临时数据存储 |
| `screenshot` | 屏幕截图 | 界面截图 |
| `ocr` | OCR 文字识别 | 图片文字提取 |
| `autogui` | GUI 自动化 | 界面自动操作 |
| `time` | 时间管理 | 时间相关操作 |
| `vision` | 计算机视觉 | 图像处理分析 |

### PromptX 增强工具 (1个)

| 工具名 | 功能 | 用途 |
|--------|------|------|
| `promptx` | AI 专业角色系统 | 角色创建、激活、记忆管理 |

#### PromptX 子工具

- `promptx_init` - 系统初始化
- `promptx_hello` - 角色发现
- `promptx_action` - 角色激活
- `promptx_learn` - 知识学习
- `promptx_recall` - 记忆检索
- `promptx_remember` - 经验保存

## 🎭 女娲角色使用

### 激活女娲角色

```
请使用 promptx_action 工具激活 nuwa 角色
```

### 女娲角色能力

- **🎯 需求洞察**: 快速理解用户需求
- **🏗️ 角色设计**: 基于 DPML 协议创造专业角色
- **⚡ 快速交付**: 3步流程，2分钟完成
- **🔧 系统集成**: 确保角色与系统兼容

### 创建自定义角色

激活女娲角色后：
```
我需要一个数据分析专家角色，具备：
- DuckDB 数据库操作能力
- 抖音数据分析经验
- 可视化图表生成能力
```

## 📝 任务和调试

### VS Code 任务

在 VS Code 中按 `Ctrl+Shift+P`，输入 "Tasks: Run Task"：

- **启动 PromptX MCP 服务** - 单独启动 PromptX 服务
- **验证 MCP 工具** - 验证所有 MCP 工具状态
- **测试 PromptX 集成** - 测试 PromptX 功能

### 调试配置

在 VS Code 中按 `F5` 或使用调试面板：

- **Node.js: PromptX MCP 服务器** - 调试 PromptX MCP 服务
- **Python: 数据分析脚本** - 调试数据分析代码

## 🔍 故障排除

### 常见问题

1. **MCP 工具不显示**
   - 检查 `chat.mcp.enabled` 设置
   - 验证 `.vscode/mcp.json` 格式
   - 重启 VS Code

2. **PromptX 工具不可用**
   - 检查 Node.js 和 npm 安装
   - 验证 PromptX 包安装：`npx -y -f dpml-prompt@snapshot --version`
   - 检查环境变量设置

3. **工具调用失败**
   - 查看 MCP 输出日志
   - 检查网络连接
   - 验证 API 密钥配置

### 查看日志

1. 在 Chat 视图中点击错误通知
2. 选择 **Show Output** 查看服务器日志
3. 或运行命令：**MCP: List Servers** > 选择服务器 > **Show Output**

## 🎉 最佳实践

### 1. 工具组合使用

```
请使用以下工具组合分析抖音数据：
1. 使用 filesystem 工具读取 CSV 数据
2. 使用 promptx_action 激活数据分析专家角色
3. 使用 github 工具创建分析报告 PR
```

### 2. 资源管理

- 定期使用 `promptx_remember` 保存重要信息
- 使用 `promptx_recall` 检索历史记忆
- 利用 `memory` 工具存储会话数据

### 3. 工作流自动化

- 创建自定义任务组合多个 MCP 工具
- 使用工作区设置共享团队配置
- 利用 VS Code 扩展增强功能

## 📚 相关资源

- [Model Context Protocol 官方文档](https://modelcontextprotocol.io/)
- [PromptX GitHub 仓库](https://github.com/Deepractice/PromptX)
- [VS Code Copilot 文档](https://code.visualstudio.com/docs/copilot/overview)
- [MCP 服务器仓库](https://github.com/modelcontextprotocol/servers)

---

🎭 **享受 VS Code 中的 PromptX-MCP 增强体验！**
