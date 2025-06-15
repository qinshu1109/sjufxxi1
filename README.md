# 抖音电商数据分析平台

一个基于DuckDB和Dify的抖音电商数据分析平台。

## 项目概述

本项目实现了一个完整的电商数据分析解决方案，包括：
- 使用DuckDB作为高性能分析数据库
- 使用Dify作为AI对话平台，支持自然语言查询
- 集成DeepSeek API提供智能分析能力
- 支持飞书Webhook告警通知

## 项目结构

```
douyin-analytics/
├── config/                 # 配置文件
│   ├── dify_env.txt       # Dify环境变量配置
│   ├── feishu_config.py   # 飞书配置
│   └── init_database.sql  # 数据库初始化脚本
├── scripts/               # 实用脚本
│   ├── analyze_data.sql   # 数据分析SQL
│   ├── check_dify_status.sh   # Dify状态检查
│   ├── complete_pre_check.sh  # 完整性检查
│   └── import_csv.py      # CSV数据导入
├── dify/                  # Dify平台（Git子模块）
├── deploy.sh             # 主部署脚本
└── simple-deploy.sh      # 简化部署脚本
```

## 快速开始

1. 克隆仓库：
```bash
git clone <repository-url>
cd douyin-analytics
```

2. 运行部署脚本：
```bash
./deploy.sh
```

3. 访问Dify平台：
- URL: http://localhost/
- 用户名: qinshu
- 密码: zhou1109

## 系统要求

- Docker和Docker Compose
- Python 3.x
- 至少8GB内存
- 20GB可用磁盘空间

## 功能特点

- **数据导入**：支持CSV格式的电商数据批量导入
- **智能查询**：通过自然语言与数据对话
- **实时分析**：基于DuckDB的高性能数据分析
- **可视化报表**：Dify平台提供的数据可视化
- **告警通知**：集成飞书Webhook实时告警

## 部署说明

详细的部署和配置说明请参考项目文档。

## 注意事项

- Dify文件夹已在.gitignore中排除，需要单独克隆
- 确保DeepSeek API密钥正确配置
- 首次运行需要初始化数据库

## 更新日志

### 2025-06-16
- 优化.gitignore配置，正确处理dify子项目
- 完善项目文档和部署说明
- 添加网络修复和验收报告

## 技术支持

如有问题，请查看项目文档或提交Issue。

## 许可证

本项目遵循MIT许可证。