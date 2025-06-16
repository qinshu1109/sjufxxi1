#!/bin/bash

echo "=== AdsPower 最终测试脚本 ==="
echo ""

# 激活AdsPower窗口
echo "🖥️  激活AdsPower窗口..."
wmctrl -a "AdsPower Browser"
sleep 2

echo "📋 当前状态检查："
echo ""

# 1. 检查AdsPower进程
if pgrep -f "adspower_global" > /dev/null; then
    echo "✅ AdsPower进程正在运行"
else
    echo "❌ AdsPower进程未运行"
    exit 1
fi

# 2. 检查API端口
if ss -tlnp | grep -q 50325; then
    echo "✅ API端口 50325 正在监听"
else
    echo "❌ API端口 50325 未监听"
    exit 1
fi

# 3. 检查代理
echo "✅ 代理服务器状态："
if ss -tlnp | grep -q 7890; then
    echo "   - 代理端口 7890 正在运行"
    PROXY_TEST=$(curl -x http://127.0.0.1:7890 --connect-timeout 5 -s -o /dev/null -w "%{http_code}" http://www.google.com)
    echo "   - 代理连接测试: $PROXY_TEST"
else
    echo "   - ❌ 代理端口 7890 未运行"
fi

echo ""
echo "🔍 测试本地API权限..."

# 测试API
API_RESPONSE=$(curl -s "http://localhost:50325/api/v1/browser/start?user_id=384")
echo "API响应: $API_RESPONSE"

echo ""
if echo "$API_RESPONSE" | grep -q "No local API permission"; then
    echo "❌ 本地API权限未启用"
    echo ""
    echo "🔧 请按以下步骤操作："
    echo "1. 在已激活的AdsPower窗口中"
    echo "2. 点击右上角的设置图标 ⚙️"
    echo "3. 找到'本地API'或'Local API'选项"
    echo "4. 启用'开启本地API'开关"
    echo "5. 确认端口为 50325"
    echo "6. 保存设置"
    echo ""
    echo "设置完成后，请运行以下命令验证："
    echo "curl -s \"http://localhost:50325/api/v1/browser/start?user_id=384\""
    
elif echo "$API_RESPONSE" | grep -q "用户不存在\|user not found"; then
    echo "❌ 用户ID 384 不存在"
    echo ""
    echo "🔧 请检查："
    echo "1. 在AdsPower中查看现有的浏览器配置"
    echo "2. 确认正确的用户ID"
    echo "3. 或创建新的浏览器配置"
    
elif echo "$API_RESPONSE" | grep -q "success\|ws://"; then
    echo "🎉 成功！浏览器启动正常"
    echo ""
    echo "✅ 问题已解决！"
    
elif echo "$API_RESPONSE" | grep -q "代理失败\|proxy"; then
    echo "❌ 代理配置问题"
    echo ""
    echo "🔧 请在AdsPower中配置代理："
    echo "1. 编辑用户384的浏览器配置"
    echo "2. 设置代理："
    echo "   - 类型: HTTP"
    echo "   - 地址: 127.0.0.1"
    echo "   - 端口: 7890"
    echo "3. 保存配置"
    
else
    echo "⚠️  未知响应，请检查详细信息"
    echo "可能需要联系AdsPower技术支持"
fi

echo ""
echo "=== 测试完成 ==="
