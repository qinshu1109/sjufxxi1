# AdsPower 浏览器启动失败解决方案

## 问题诊断
错误信息：`384 启动浏览器失败 (Error: 代理失败，不打开浏览器)`

经过详细分析，问题的根本原因是：**本地API权限未启用**

## 当前状态
- ✅ AdsPower浏览器主程序正常运行
- ✅ 代理服务器 (127.0.0.1:7890) 正常运行
- ✅ 本地API服务器端口 50325 正常监听
- ❌ 本地API权限未启用 (错误代码: 9110)

## 解决方案

### 方法1：通过AdsPower界面启用本地API（推荐）

1. **打开AdsPower浏览器界面**
   - AdsPower窗口应该已经显示
   - 如果没有显示，运行：`wmctrl -a "AdsPower Browser"`

2. **进入设置页面**
   - 点击右上角的设置图标（齿轮图标）
   - 或者点击菜单中的"设置"选项

3. **启用本地API**
   - 在设置页面中找到"本地API"或"Local API"选项
   - 开启"启用本地API"开关
   - 确认API端口设置为：`50325`
   - 点击"保存"或"确定"

4. **重启AdsPower**
   - 关闭AdsPower浏览器
   - 重新启动AdsPower

### 方法2：使用自动化脚本

如果界面操作不便，可以运行以下命令：

```bash
# 运行诊断和修复脚本
./fix_adspower_proxy_issue.sh
```

### 方法3：手动配置（高级用户）

```bash
# 1. 停止AdsPower
pkill -f adspower_global

# 2. 修改配置数据库
sqlite3 "/home/qinshu/.config/adspower_global/cwd_global/source/conf" \
"INSERT OR REPLACE INTO config (key, value, update_time) VALUES 
('local_api_switch', '{\"local_api_switch\":\"1\"}', $(date +%s));"

# 3. 重启AdsPower
"/opt/AdsPower Global/adspower_global" --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox &
```

## 验证解决方案

启用本地API后，运行以下命令验证：

```bash
# 测试API连接
curl -s "http://localhost:50325/api/v1/browser/start?user_id=384"
```

成功的响应应该包含浏览器启动信息，而不是权限错误。

## 其他可能的问题

### 1. 用户ID 384 不存在
如果API权限启用后仍然失败，可能是用户ID不存在：
- 在AdsPower界面中检查是否有ID为384的浏览器配置
- 如果没有，请创建新的浏览器配置或使用正确的用户ID

### 2. 代理配置问题
如果仍然有代理相关错误：
- 检查代理服务器是否正常运行
- 验证代理设置是否正确
- 尝试在AdsPower中禁用代理或更换代理服务器

### 3. 网络连接问题
- 确保网络连接正常
- 检查防火墙设置
- 验证AdsPower账户登录状态

## 联系支持

如果以上方案都无法解决问题，请：
1. 收集错误日志：`/home/qinshu/.config/adspower_global/logs/main.log`
2. 联系AdsPower技术支持
3. 提供详细的错误信息和系统环境

## 快速启动命令

```bash
# 启动AdsPower（如果未运行）
"/opt/AdsPower Global/adspower_global" --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox &

# 激活AdsPower窗口
wmctrl -a "AdsPower Browser"

# 测试API
curl -s "http://localhost:50325/api/v1/browser/start?user_id=384"
```
