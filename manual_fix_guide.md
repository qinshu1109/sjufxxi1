# AdsPower 手动修复指南

## 🎯 问题确认
- ✅ 代理服务器正常运行
- ✅ 网络连接正常（新加坡IP）
- ✅ AdsPower主程序运行正常
- ❌ **本地API权限未启用** ← 需要手动解决

## 🔧 解决步骤

### 第一步：确保AdsPower窗口可见

运行以下命令激活AdsPower窗口：
```bash
wmctrl -a "AdsPower Browser"
```

### 第二步：在AdsPower界面中启用本地API

1. **找到设置入口**：
   - 在AdsPower主界面中，查找右上角的 **设置图标** ⚙️
   - 或者在菜单栏中找到 **"设置"** 选项
   - 或者在主界面中找到 **"系统设置"** 按钮

2. **进入本地API设置**：
   - 在设置页面的左侧菜单中找到：
     - **"本地API"**
     - **"Local API"**
     - **"API设置"**
     - **"开发者设置"**

3. **启用本地API**：
   - 找到 **"启用本地API"** 开关
   - 将开关设置为 **"开启"** 状态
   - 确认端口设置为：**50325**
   - 如果有IP地址设置，确保包含：**127.0.0.1** 或 **localhost**

4. **保存设置**：
   - 点击 **"保存"** 或 **"确定"** 按钮
   - 等待设置生效

### 第三步：重启AdsPower（如果需要）

如果设置后仍然无效，请重启AdsPower：
```bash
pkill -f adspower_global
sleep 3
"/opt/AdsPower Global/adspower_global" --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox &
```

### 第四步：验证本地API是否启用

等待10秒后运行：
```bash
curl -s "http://localhost:50325/api/v1/browser/start?user_id=384"
```

**成功响应示例**：
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

## 🔍 如果找不到本地API设置

### 方案A：查看所有设置选项
在AdsPower设置中仔细查看所有选项，本地API可能在：
- 高级设置
- 开发者选项
- 系统设置
- 网络设置

### 方案B：检查AdsPower版本
```bash
grep -r "version" "/opt/AdsPower Global/resources/app.asar" 2>/dev/null | head -5
```

### 方案C：查看AdsPower帮助文档
在AdsPower界面中查找：
- 帮助按钮
- 文档链接
- 关于页面

## 🚨 如果用户384不存在

### 检查现有用户
1. 在AdsPower主界面查看浏览器列表
2. 记录现有的用户ID
3. 使用正确的用户ID重新测试

### 创建新用户
1. 在AdsPower中点击 **"新建浏览器"**
2. 配置代理设置：
   - 代理类型：HTTP
   - 代理地址：127.0.0.1
   - 代理端口：7890
3. 保存配置并记录新的用户ID

## 🔄 完整测试流程

```bash
#!/bin/bash
echo "=== AdsPower 完整测试 ==="

# 1. 检查AdsPower进程
if pgrep -f "adspower_global" > /dev/null; then
    echo "✅ AdsPower正在运行"
else
    echo "❌ AdsPower未运行，正在启动..."
    "/opt/AdsPower Global/adspower_global" --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox &
    sleep 10
fi

# 2. 检查API端口
if ss -tlnp | grep -q 50325; then
    echo "✅ API端口正在监听"
else
    echo "❌ API端口未监听"
    exit 1
fi

# 3. 测试本地API权限
echo "测试本地API权限..."
API_RESPONSE=$(curl -s "http://localhost:50325/api/v1/browser/start?user_id=384")
echo "响应: $API_RESPONSE"

if echo "$API_RESPONSE" | grep -q "No local API permission"; then
    echo "❌ 需要在AdsPower界面中手动启用本地API"
    wmctrl -a "AdsPower Browser"
elif echo "$API_RESPONSE" | grep -q "success"; then
    echo "✅ 问题已解决！"
else
    echo "⚠️ 其他问题，请检查响应内容"
fi
```

## 📞 联系支持

如果以上步骤都无法解决问题：

1. **截图保存**：
   - AdsPower设置页面截图
   - 错误信息截图

2. **收集日志**：
   ```bash
   tail -50 "/home/qinshu/.config/adspower_global/logs/main.log" > adspower_error.log
   ```

3. **联系AdsPower客服**：
   - 提供截图和日志文件
   - 说明已尝试的解决方案
   - 提供系统环境信息

## 🎯 关键提醒

**最重要的是在AdsPower界面中找到并启用本地API设置！**

这是解决问题的关键步骤，数据库修改可能不会立即生效，必须通过界面操作来确保设置正确保存。
