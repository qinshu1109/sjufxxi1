# Docker配置基线分析报告

**生成时间**: 2025-06-16  
**分析范围**: sjufxxi项目现有Docker配置  
**分析目的**: 为Podman迁移提供基线数据

## 📋 服务架构概览

### 核心服务组件
| 服务名 | 镜像 | 端口 | 功能 | 迁移复杂度 |
|--------|------|------|------|------------|
| api | langgenius/dify-api:1.4.2 | 5001 | Dify API服务 | 中等 |
| worker | langgenius/dify-api:1.4.2 | - | Celery工作进程 | 中等 |
| web | langgenius/dify-web:1.4.2 | 3000 | 前端界面 | 低 |
| db | postgres:15-alpine | 5432 | PostgreSQL数据库 | 低 |
| redis | redis:6-alpine | 6379 | 缓存和消息队列 | 低 |
| nginx | nginx:latest | 80/443 | 反向代理 | 低 |
| weaviate | semitechnologies/weaviate:1.25.5 | 8080 | 向量数据库 | 中等 |
| sandbox | langgenius/dify-sandbox:0.2.10 | 8194 | 代码执行沙箱 | 高 |

### 可选服务组件
| 服务名 | 镜像 | 用途 | 迁移策略 |
|--------|------|------|----------|
| qdrant | qdrant/qdrant:v1.7.4 | 向量存储 | 按需迁移 |
| opensearch | opensearchproject/opensearch:2.13.0 | 搜索引擎 | 按需迁移 |
| elasticsearch | docker.elastic.co/elasticsearch/elasticsearch:8.14.3 | 搜索引擎 | 按需迁移 |
| milvus | milvusdb/milvus:v2.4.5 | 向量数据库 | 按需迁移 |

## 🔧 配置复杂度分析

### 环境变量统计
- **总环境变量数**: 500+
- **数据库相关**: 50+
- **向量存储相关**: 100+
- **安全相关**: 30+
- **插件相关**: 80+

### 网络配置
```yaml
networks:
  ssrf_proxy_network:
    driver: bridge
    internal: true
  milvus:
    driver: bridge
  opensearch-net:
    driver: bridge
    internal: true
```

### 存储卷配置
```yaml
volumes:
  - ./volumes/app/storage:/app/api/storage
  - ./volumes/db/data:/var/lib/postgresql/data
  - ./volumes/redis/data:/data
  - ./volumes/weaviate:/var/lib/weaviate
```

## ⚠️ 迁移风险评估

### 高风险项
1. **复杂的环境变量依赖**: 500+变量需要逐一验证
2. **多向量数据库支持**: 需要确保Podman网络兼容性
3. **插件系统**: plugin_daemon服务的rootless兼容性
4. **SSRF代理**: 内部网络隔离在Podman中的实现

### 中风险项
1. **健康检查**: 需要适配Podman的健康检查机制
2. **文件权限**: rootless模式下的权限映射
3. **服务依赖**: depends_on在podman-compose中的支持

### 低风险项
1. **基础服务**: PostgreSQL、Redis、Nginx标准配置
2. **端口映射**: 标准端口映射无兼容性问题

## 🎯 Podman迁移策略

### Phase 1: 核心服务迁移
- api, worker, web, db, redis, nginx
- 保持最小功能集，确保基本可用性

### Phase 2: 向量存储迁移
- weaviate作为默认向量存储
- 其他向量数据库按需配置

### Phase 3: 高级功能迁移
- sandbox代码执行环境
- 插件系统和marketplace

## 📊 资源需求评估

### 内存需求
- **最小配置**: 8GB RAM
- **推荐配置**: 16GB RAM
- **生产配置**: 32GB RAM

### 存储需求
- **配置文件**: <100MB
- **应用数据**: 1-10GB
- **向量数据**: 根据使用量动态增长

### CPU需求
- **最小配置**: 4核
- **推荐配置**: 8核
- **生产配置**: 16核

## ✅ 验收标准

1. **功能完整性**: 所有核心服务正常启动
2. **网络连通性**: 服务间通信正常
3. **数据持久性**: 数据卷正确挂载
4. **性能基准**: 响应时间不超过Docker版本15%
5. **安全合规**: rootless模式正常运行

## 📝 下一步行动

1. 创建Podman兼容的compose文件
2. 配置rootless用户命名空间
3. 测试核心服务启动
4. 验证服务间通信
5. 性能基准测试
