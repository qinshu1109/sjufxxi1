# 环境变量和密钥清单

**生成时间**: 2025-06-16  
**分析范围**: sjufxxi项目Dify配置  
**安全等级**: 机密

## 🔐 密钥和敏感信息

### 高敏感度 (CRITICAL)
| 变量名 | 默认值 | 用途 | 迁移策略 |
|--------|--------|------|----------|
| POSTGRES_PASSWORD | difyai123456 | PostgreSQL密码 | 使用Podman secrets |
| REDIS_PASSWORD | difyai123456 | Redis密码 | 使用Podman secrets |
| SANDBOX_API_KEY | dify-sandbox | 沙箱API密钥 | 使用Podman secrets |
| WEAVIATE_AUTHENTICATION_APIKEY_ALLOWED_KEYS | WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih | Weaviate API密钥 | 使用Podman secrets |
| QDRANT_API_KEY | difyai123456 | Qdrant API密钥 | 使用Podman secrets |
| ELASTICSEARCH_PASSWORD | elastic | Elasticsearch密码 | 使用Podman secrets |
| ORACLE_PWD | Dify123456 | Oracle密码 | 使用Podman secrets |

### 中敏感度 (HIGH)
| 变量名 | 默认值 | 用途 | 迁移策略 |
|--------|--------|------|----------|
| SECRET_KEY | - | 应用密钥 | 环境变量 |
| CELERY_BROKER_URL | - | Celery消息队列 | 环境变量 |
| DATABASE_URL | - | 数据库连接串 | 环境变量 |
| VECTOR_STORE | weaviate | 向量存储选择 | 环境变量 |
| SENTRY_DSN | - | 错误监控 | 环境变量 |

### 低敏感度 (MEDIUM)
| 变量名 | 默认值 | 用途 | 迁移策略 |
|--------|--------|------|----------|
| LOG_LEVEL | INFO | 日志级别 | 环境变量 |
| NGINX_SERVER_NAME | _ | Nginx服务器名 | 环境变量 |
| WEAVIATE_QUERY_DEFAULTS_LIMIT | 25 | 查询限制 | 环境变量 |

## 🌐 网络和URL配置

### API端点配置
| 变量名 | 默认值 | 用途 | Podman适配 |
|--------|--------|------|------------|
| CONSOLE_API_URL | - | 控制台API地址 | 需要适配Pod网络 |
| CONSOLE_WEB_URL | - | 控制台Web地址 | 需要适配Pod网络 |
| SERVICE_API_URL | - | 服务API地址 | 需要适配Pod网络 |
| APP_API_URL | - | 应用API地址 | 需要适配Pod网络 |
| APP_WEB_URL | - | 应用Web地址 | 需要适配Pod网络 |
| FILES_URL | - | 文件服务地址 | 需要适配Pod网络 |

### 代理和网络配置
| 变量名 | 默认值 | 用途 | Podman适配 |
|--------|--------|------|------------|
| HTTP_PROXY | http://ssrf_proxy:3128 | HTTP代理 | 需要适配Pod网络 |
| HTTPS_PROXY | http://ssrf_proxy:3128 | HTTPS代理 | 需要适配Pod网络 |
| SSRF_HTTP_PORT | 3128 | SSRF代理端口 | 保持不变 |

## 📊 数据库配置

### PostgreSQL配置
| 变量名 | 默认值 | 用途 | Podman适配 |
|--------|--------|------|------------|
| PGUSER | postgres | 数据库用户 | 保持不变 |
| POSTGRES_DB | dify | 数据库名 | 保持不变 |
| PGDATA | /var/lib/postgresql/data/pgdata | 数据目录 | 需要适配卷挂载 |
| POSTGRES_MAX_CONNECTIONS | 100 | 最大连接数 | 保持不变 |
| POSTGRES_SHARED_BUFFERS | 128MB | 共享缓冲区 | 保持不变 |

### 向量数据库配置
| 变量名 | 默认值 | 用途 | Podman适配 |
|--------|--------|------|------------|
| WEAVIATE_PERSISTENCE_DATA_PATH | /var/lib/weaviate | Weaviate数据路径 | 需要适配卷挂载 |
| WEAVIATE_AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED | false | 匿名访问 | 保持不变 |
| QDRANT_API_KEY | difyai123456 | Qdrant密钥 | 使用secrets |

## 🔧 应用配置

### 日志配置
| 变量名 | 默认值 | 用途 | Podman适配 |
|--------|--------|------|------------|
| LOG_LEVEL | INFO | 日志级别 | 保持不变 |
| LOG_FILE | /app/logs/server.log | 日志文件路径 | 需要适配卷挂载 |
| LOG_FILE_MAX_SIZE | 20 | 日志文件最大大小(MB) | 保持不变 |
| LOG_FILE_BACKUP_COUNT | 5 | 日志备份数量 | 保持不变 |

### 性能配置
| 变量名 | 默认值 | 用途 | Podman适配 |
|--------|--------|------|------------|
| TEXT_GENERATION_TIMEOUT_MS | 60000 | 文本生成超时 | 保持不变 |
| WORKER_TIMEOUT | 15 | Worker超时 | 保持不变 |
| NGINX_WORKER_PROCESSES | auto | Nginx工作进程数 | 保持不变 |
| NGINX_CLIENT_MAX_BODY_SIZE | 15M | 最大请求体大小 | 保持不变 |

## 🚨 迁移风险评估

### 高风险项
1. **密钥管理**: 需要实现Podman secrets管理
2. **网络配置**: 服务间通信需要重新配置
3. **卷挂载**: 文件权限在rootless模式下需要调整

### 中风险项
1. **环境变量数量**: 500+变量需要逐一验证
2. **服务发现**: 容器名解析在Pod中的行为
3. **健康检查**: 需要适配Podman的健康检查机制

### 低风险项
1. **基础配置**: 大部分配置可以直接迁移
2. **端口映射**: 标准端口映射无兼容性问题

## 📋 迁移检查清单

### Phase 1: 密钥管理
- [ ] 创建Podman secrets存储
- [ ] 迁移所有敏感信息到secrets
- [ ] 验证secrets访问权限

### Phase 2: 网络配置
- [ ] 配置Pod内网络
- [ ] 更新服务发现配置
- [ ] 测试服务间通信

### Phase 3: 存储配置
- [ ] 配置卷挂载
- [ ] 调整文件权限
- [ ] 验证数据持久性

### Phase 4: 验证测试
- [ ] 功能完整性测试
- [ ] 性能基准测试
- [ ] 安全配置验证

## 🔒 安全建议

1. **密钥轮换**: 所有默认密钥必须更换
2. **权限最小化**: 仅授予必要的环境变量访问权限
3. **审计日志**: 记录所有敏感配置的访问
4. **加密传输**: 确保所有内部通信使用TLS
