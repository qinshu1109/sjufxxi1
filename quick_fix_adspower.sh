#!/bin/bash

echo "=== AdsPower 快速修复脚本 ==="
echo ""

echo "🔧 正在解决AdsPower本地API问题..."

# 1. 停止AdsPower
echo "1. 停止AdsPower进程..."
pkill -f adspower_global
sleep 3

# 2. 启用本地API
echo "2. 启用本地API权限..."
sqlite3 "/home/qinshu/.config/adspower_global/cwd_global/source/conf" "
INSERT OR REPLACE INTO config (key, value, update_time) VALUES 
('local_api_switch', '{\"local_api_switch\":\"1\"}', $(date +%s));
INSERT OR REPLACE INTO config (key, value, update_time) VALUES 
('local_api_port', '{\"local_api_port\":\"50325\"}', $(date +%s));
"

echo "✅ 本地API配置已更新"

# 3. 重启AdsPower
echo "3. 重启AdsPower..."
"/opt/AdsPower Global/adspower_global" --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox &

# 4. 等待启动
echo "4. 等待AdsPower启动..."
sleep 15

# 5. 检查进程
echo "5. 检查AdsPower进程状态..."
if pgrep -f "adspower_global" > /dev/null; then
    echo "✅ AdsPower进程正在运行"
else
    echo "❌ AdsPower进程未运行"
    exit 1
fi

# 6. 检查端口
echo "6. 检查API端口状态..."
if ss -tlnp | grep -q 50325; then
    echo "✅ API端口 50325 正在监听"
else
    echo "❌ API端口 50325 未监听"
    exit 1
fi

# 7. 测试API
echo "7. 测试本地API..."
API_RESPONSE=$(curl -s "http://localhost:50325/api/v1/browser/start?user_id=384")
echo "API响应: $API_RESPONSE"

if echo "$API_RESPONSE" | grep -q "No local API permission"; then
    echo "❌ 本地API权限仍未启用"
    echo ""
    echo "请手动在AdsPower界面中启用本地API:"
    echo "1. 打开AdsPower设置"
    echo "2. 找到'本地API'选项"
    echo "3. 启用'开启本地API'开关"
    echo "4. 保存设置"
    
    # 激活AdsPower窗口
    wmctrl -a "AdsPower Browser" 2>/dev/null
    
elif echo "$API_RESPONSE" | grep -q "用户不存在\|user not found"; then
    echo "❌ 用户ID 384 不存在"
    echo "请在AdsPower中检查用户ID是否正确"
    
elif echo "$API_RESPONSE" | grep -q "代理失败\|proxy"; then
    echo "❌ 代理配置问题"
    echo "请检查AdsPower中的代理设置"
    
elif echo "$API_RESPONSE" | grep -q "success\|ws://"; then
    echo "✅ 浏览器启动成功！"
    echo "问题已解决"
    
else
    echo "⚠️  未知响应，请检查详细信息"
fi

echo ""
echo "=== 修复脚本执行完成 ==="
