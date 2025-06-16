# AdsPower 本地API启用指南

## 问题确认
✅ 代理服务器正常运行  
✅ 网络连接正常（新加坡IP）  
✅ AdsPower主程序运行正常  
❌ **本地API权限未启用** ← 这是核心问题

## 解决方案

### 方法1：通过AdsPower界面启用（推荐）

1. **确保AdsPower窗口可见**
   ```bash
   wmctrl -a "AdsPower Browser"
   ```

2. **在AdsPower界面中操作**：
   - 点击右上角的 **设置图标**（齿轮⚙️）
   - 或者点击菜单栏中的 **"设置"** 选项
   - 在左侧菜单中找到 **"本地API"** 或 **"Local API"**
   - 开启 **"启用本地API"** 开关
   - 确认端口设置为：**50325**
   - 点击 **"保存"** 按钮

3. **重启AdsPower**
   ```bash
   pkill -f adspower_global
   sleep 3
   "/opt/AdsPower Global/adspower_global" --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox &
   ```

### 方法2：使用配置文件修改

如果界面操作不便，可以尝试直接修改配置：

```bash
# 停止AdsPower
pkill -f adspower_global
sleep 3

# 修改配置数据库
sqlite3 "/home/qinshu/.config/adspower_global/cwd_global/source/conf" "
INSERT OR REPLACE INTO config (key, value, update_time) VALUES 
('local_api_switch', '{\"local_api_switch\":\"1\"}', $(date +%s));
INSERT OR REPLACE INTO config (key, value, update_time) VALUES 
('local_api_port', '{\"local_api_port\":\"50325\"}', $(date +%s));
"

# 重启AdsPower
"/opt/AdsPower Global/adspower_global" --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox &
```

### 方法3：使用环境变量强制启用

```bash
# 使用特殊环境变量启动
./set_proxy_env.sh
```

## 验证步骤

启用本地API后，运行以下命令验证：

```bash
# 等待AdsPower完全启动
sleep 10

# 测试本地API
curl -s "http://localhost:50325/api/v1/browser/start?user_id=384"
```

**成功的响应示例**：
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "ws": "ws://localhost:9222/devtools/browser/...",
    "debug_port": "9222"
  }
}
```

**失败的响应**：
```json
{"data":{},"msg":"No local API permission","code":9110}
```

## 如果仍然失败

### 检查用户384是否存在

1. 在AdsPower界面中查看浏览器列表
2. 确认是否有ID为384的浏览器配置
3. 如果没有，请：
   - 创建新的浏览器配置
   - 记录新的用户ID
   - 使用正确的用户ID重新测试

### 代理配置检查

如果本地API启用成功但仍有代理错误：

1. **在AdsPower中配置代理**：
   - 编辑用户384的浏览器配置
   - 代理设置：
     - 类型：HTTP
     - 地址：127.0.0.1
     - 端口：7890
   - 保存配置

2. **测试代理连接**：
   ```bash
   curl -x http://127.0.0.1:7890 -s http://httpbin.org/ip
   ```

## 快速解决脚本

```bash
#!/bin/bash
echo "正在解决AdsPower本地API问题..."

# 1. 停止AdsPower
pkill -f adspower_global
sleep 3

# 2. 启用本地API
sqlite3 "/home/qinshu/.config/adspower_global/cwd_global/source/conf" "
INSERT OR REPLACE INTO config (key, value, update_time) VALUES 
('local_api_switch', '{\"local_api_switch\":\"1\"}', $(date +%s));"

# 3. 重启AdsPower
"/opt/AdsPower Global/adspower_global" --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox &

# 4. 等待启动
sleep 10

# 5. 测试API
echo "测试本地API..."
curl -s "http://localhost:50325/api/v1/browser/start?user_id=384"
```

## 联系支持

如果以上方法都无法解决问题：

1. 收集日志文件：
   ```bash
   tail -50 "/home/qinshu/.config/adspower_global/logs/main.log"
   ```

2. 联系AdsPower客服，提供：
   - 错误截图
   - 日志文件
   - 系统环境信息
   - 代理配置详情
