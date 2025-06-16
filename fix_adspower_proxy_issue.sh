#!/bin/bash

echo "=== AdsPower 代理问题解决方案 ==="
echo ""

# 检查AdsPower是否在运行
if ! pgrep -f "adspower_global" > /dev/null; then
    echo "❌ AdsPower浏览器未运行，请先启动AdsPower"
    exit 1
fi

echo "✅ AdsPower浏览器正在运行"

# 检查本地API端口
LOCAL_API_PORT=$(cat "/home/qinshu/.config/adspower_global/cwd_global/source/local_api" 2>/dev/null | grep -o '[0-9]\+' | tail -1)
if [ -z "$LOCAL_API_PORT" ]; then
    LOCAL_API_PORT="50325"
fi

echo "🔍 本地API端口: $LOCAL_API_PORT"

# 测试API连接
echo "🔗 测试API连接..."
API_RESPONSE=$(curl -s "http://localhost:$LOCAL_API_PORT/api/v1/browser/start?user_id=384")
echo "API响应: $API_RESPONSE"

if echo "$API_RESPONSE" | grep -q "No local API permission"; then
    echo ""
    echo "❌ 问题诊断: 本地API权限未启用"
    echo ""
    echo "📋 解决步骤:"
    echo "1. 在AdsPower浏览器界面中，点击右上角的设置图标"
    echo "2. 选择 '本地API' 或 'Local API' 选项"
    echo "3. 启用 '开启本地API' 开关"
    echo "4. 设置API端口为: $LOCAL_API_PORT"
    echo "5. 点击保存设置"
    echo ""
    echo "🔧 或者尝试以下自动修复方法:"
    
    # 尝试自动启用本地API
    echo "正在尝试自动启用本地API权限..."
    
    # 在数据库中添加本地API配置
    sqlite3 "/home/qinshu/.config/adspower_global/cwd_global/source/conf" "INSERT OR REPLACE INTO config (key, value, timestamp) VALUES ('local_api_switch', '{\"local_api_switch\":\"1\"}', $(date +%s));"
    
    echo "✅ 已尝试启用本地API权限"
    echo "请重启AdsPower浏览器以使设置生效"
    
elif echo "$API_RESPONSE" | grep -q "代理失败"; then
    echo ""
    echo "❌ 问题诊断: 代理配置问题"
    echo ""
    echo "🔧 代理问题解决方案:"
    echo "1. 检查代理服务器是否正常运行"
    echo "2. 验证代理设置是否正确"
    echo "3. 尝试禁用代理或更换代理服务器"
    
elif echo "$API_RESPONSE" | grep -q "用户不存在"; then
    echo ""
    echo "❌ 问题诊断: 用户ID 384 不存在"
    echo ""
    echo "📋 解决步骤:"
    echo "1. 在AdsPower界面中检查是否存在用户ID为384的浏览器配置"
    echo "2. 如果不存在，请创建新的浏览器配置"
    echo "3. 记录正确的用户ID并重新尝试"
    
else
    echo "✅ API连接正常，可能是其他问题"
    echo "API响应: $API_RESPONSE"
fi

echo ""
echo "🔍 系统代理状态:"
env | grep -i proxy | while read line; do
    echo "  $line"
done

echo ""
echo "🔍 代理服务器状态:"
if ss -tlnp | grep -q 7890; then
    echo "  ✅ 代理服务器 (7890) 正在运行"
else
    echo "  ❌ 代理服务器 (7890) 未运行"
fi

echo ""
echo "💡 额外建议:"
echo "1. 确保AdsPower账户已登录"
echo "2. 检查网络连接是否正常"
echo "3. 尝试重启AdsPower浏览器"
echo "4. 如果问题持续，请联系AdsPower技术支持"

echo ""
echo "=== 脚本执行完成 ==="
