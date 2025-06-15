# 容器迁移专业知识

## Docker到Podman迁移核心要点

### 技术差异对比
| 特性 | Docker | Podman | 迁移注意事项 |
|------|--------|--------|-------------|
| 架构 | Client-Server | 无守护进程 | 去除Docker daemon依赖 |
| 权限 | 需要root | 支持rootless | 用户命名空间配置 |
| 网络 | Docker网络 | CNI/Netavark | 网络配置适配 |
| 存储 | Docker卷 | 本地存储 | 卷挂载路径调整 |
| 编排 | docker-compose | podman-compose | Compose文件兼容性 |

### Rootless容器优势
- **安全性增强**：容器进程运行在用户权限下
- **多租户隔离**：不同用户的容器完全隔离
- **权限最小化**：遵循最小权限原则
- **审计友好**：更容易进行安全审计

### 迁移最佳实践
1. **环境准备**
   ```bash
   # 安装Podman
   dnf install podman podman-compose
   
   # 配置用户命名空间
   echo "user.max_user_namespaces=28633" >> /etc/sysctl.conf
   sysctl -p
   
   # 配置子UID/GID
   usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER
   ```

2. **网络配置**
   ```yaml
   # podman-compose.yml网络配置
   networks:
     app-network:
       driver: bridge
       ipam:
         config:
           - subnet: 172.20.0.0/16
   ```

3. **存储迁移**
   ```bash
   # 数据卷迁移
   podman volume create app-data
   podman run --rm -v docker-volume:/source -v app-data:/dest alpine cp -r /source/. /dest/
   ```

## Kubernetes就绪性

### Pod概念映射
- **Podman Pod** ≈ **Kubernetes Pod**
- 共享网络命名空间
- 共享存储卷
- 生命周期管理

### 生成K8s YAML
```bash
# 从Podman生成Kubernetes清单
podman generate kube my-pod > my-pod.yaml

# 在Kubernetes中部署
kubectl apply -f my-pod.yaml
```

### OpenShift兼容性
- **Security Context Constraints (SCC)**：支持restricted SCC
- **Route vs Ingress**：网络暴露策略
- **ImageStream**：镜像管理策略
- **BuildConfig**：CI/CD集成

## 性能优化

### 镜像优化
- **多阶段构建**：减少镜像大小
- **层缓存**：利用--layers参数
- **基础镜像选择**：Alpine vs UBI vs Distroless

### 运行时优化
- **资源限制**：CPU/内存限制配置
- **网络性能**：CNI插件选择
- **存储性能**：overlay2 vs fuse-overlayfs

### 监控集成
- **cAdvisor**：容器指标收集
- **Prometheus**：指标存储和查询
- **Grafana**：可视化监控面板
