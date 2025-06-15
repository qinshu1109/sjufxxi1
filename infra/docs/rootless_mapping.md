# Rootless Podman用户命名空间映射文档

**生成时间**: 2025-06-16  
**适用版本**: Podman 4.9.3+  
**目的**: 为sjufxxi项目提供rootless容器权限映射指南

## 🔍 当前用户命名空间配置

### 用户信息
```bash
# 当前用户
$ id
uid=1000(qinshu) gid=1000(qinshu) groups=1000(qinshu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),100(users),114(lpadmin)

# 子UID范围
$ cat /etc/subuid | grep qinshu
qinshu:100000:65536

# 子GID范围  
$ cat /etc/subgid | grep qinshu
qinshu:100000:65536
```

### UID/GID映射表
| 容器内ID | 宿主机ID | 范围 | 用途 |
|----------|----------|------|------|
| 0 (root) | 1000 (qinshu) | 1 | 容器root映射到用户 |
| 1-65535 | 100000-165535 | 65535 | 容器用户映射范围 |

## 🛠️ 服务权限映射策略

### PostgreSQL (postgres:15-alpine)
```yaml
# 容器内用户: postgres (uid=999, gid=999)
# 映射到宿主机: uid=100999, gid=100999
services:
  postgres:
    user: "999:999"  # 明确指定用户
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

**权限设置**:
```bash
# 创建数据目录并设置权限
mkdir -p ~/data/postgres
podman unshare chown 999:999 ~/data/postgres
```

### Redis (redis:6-alpine)
```yaml
# 容器内用户: redis (uid=999, gid=999)
# 映射到宿主机: uid=100999, gid=100999
services:
  redis:
    user: "999:999"
    volumes:
      - redis_data:/data
```

**权限设置**:
```bash
mkdir -p ~/data/redis
podman unshare chown 999:999 ~/data/redis
```

### Nginx (nginx:latest)
```yaml
# 容器内用户: nginx (uid=101, gid=101)
# 映射到宿主机: uid=100101, gid=100101
services:
  nginx:
    user: "101:101"
    volumes:
      - ./nginx/conf:/etc/nginx/conf.d:ro
```

**权限设置**:
```bash
mkdir -p ~/config/nginx
podman unshare chown 101:101 ~/config/nginx
```

### Dify API/Worker (langgenius/dify-api)
```yaml
# 容器内用户: 通常为root或app用户
# 需要检查Dockerfile确定具体UID
services:
  api:
    user: "1000:1000"  # 使用非特权用户
    volumes:
      - app_storage:/app/api/storage
```

**权限设置**:
```bash
mkdir -p ~/data/app
podman unshare chown 1000:1000 ~/data/app
```

## 🔧 权限配置脚本

### 自动化权限设置脚本
```bash
#!/bin/bash
# setup_permissions.sh - 为sjufxxi项目设置rootless权限

set -e

echo "🔧 设置Podman rootless权限..."

# 创建数据目录
mkdir -p ~/data/{postgres,redis,weaviate,app,sandbox}
mkdir -p ~/config/{nginx,certbot}
mkdir -p ~/logs

# PostgreSQL权限 (uid=999, gid=999)
echo "设置PostgreSQL权限..."
podman unshare chown -R 999:999 ~/data/postgres

# Redis权限 (uid=999, gid=999)
echo "设置Redis权限..."
podman unshare chown -R 999:999 ~/data/redis

# 应用存储权限 (uid=1000, gid=1000)
echo "设置应用存储权限..."
podman unshare chown -R 1000:1000 ~/data/app

# Weaviate权限 (uid=1000, gid=1000)
echo "设置Weaviate权限..."
podman unshare chown -R 1000:1000 ~/data/weaviate

# Sandbox权限 (uid=1000, gid=1000)
echo "设置Sandbox权限..."
podman unshare chown -R 1000:1000 ~/data/sandbox

# Nginx配置权限 (uid=101, gid=101)
echo "设置Nginx配置权限..."
podman unshare chown -R 101:101 ~/config/nginx

# 日志目录权限
echo "设置日志目录权限..."
podman unshare chown -R 1000:1000 ~/logs

echo "✅ 权限设置完成！"
```

### 权限验证脚本
```bash
#!/bin/bash
# verify_permissions.sh - 验证权限设置

echo "🔍 验证目录权限..."

for dir in ~/data/* ~/config/* ~/logs; do
    if [ -d "$dir" ]; then
        echo "$(basename $dir): $(ls -ld $dir | awk '{print $3":"$4}')"
    fi
done

echo "🔍 验证Podman用户命名空间..."
podman unshare cat /proc/self/uid_map
podman unshare cat /proc/self/gid_map
```

## ⚠️ 常见问题和故障排除

### 问题1: 权限被拒绝错误
```
Error: mounting "/home/qinshu/data/postgres" to rootfs: permission denied
```

**解决方案**:
```bash
# 重新设置权限
podman unshare chown -R 999:999 ~/data/postgres
# 或者使用SELinux标签
podman run --security-opt label=disable ...
```

### 问题2: 文件所有者显示为nobody
```
$ ls -la ~/data/postgres
drwx------. 2 nobody nobody 4096 Jun 16 10:00 .
```

**解决方案**:
这是正常现象，在用户命名空间外看到的是映射后的UID。在容器内权限是正确的。

### 问题3: 无法写入挂载的卷
```
Error: cannot write to /var/lib/postgresql/data: permission denied
```

**解决方案**:
```bash
# 检查卷权限
podman volume inspect postgres_data

# 重新创建卷并设置权限
podman volume rm postgres_data
podman volume create postgres_data
podman unshare chown 999:999 $(podman volume inspect postgres_data --format '{{.Mountpoint}}')
```

### 问题4: 子UID/GID范围不足
```
Error: cannot set up namespace: user namespaces are not enabled
```

**解决方案**:
```bash
# 检查子UID/GID配置
cat /etc/subuid | grep $USER
cat /etc/subgid | grep $USER

# 如果没有配置，添加范围
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER

# 重新登录或重启
```

## 📋 权限检查清单

### 安装前检查
- [ ] 确认用户在/etc/subuid中有配置
- [ ] 确认用户在/etc/subgid中有配置
- [ ] 确认内核支持用户命名空间
- [ ] 确认cgroup v2已启用

### 配置后检查
- [ ] 运行权限设置脚本
- [ ] 验证目录权限正确
- [ ] 测试容器启动
- [ ] 验证数据持久性

### 运行时检查
- [ ] 容器内文件权限正确
- [ ] 数据卷可读写
- [ ] 日志文件可写入
- [ ] 配置文件可读取

## 🔒 安全最佳实践

1. **最小权限原则**: 仅授予容器必要的权限
2. **用户隔离**: 不同服务使用不同的用户ID
3. **只读挂载**: 配置文件使用只读挂载
4. **权限审计**: 定期检查文件权限
5. **备份权限**: 备份时保持权限信息

## 📚 参考资料

- [Podman Rootless Tutorial](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)
- [User Namespaces](https://man7.org/linux/man-pages/man7/user_namespaces.7.html)
- [Podman Security](https://docs.podman.io/en/latest/markdown/podman-run.1.html#security-opt-option)
