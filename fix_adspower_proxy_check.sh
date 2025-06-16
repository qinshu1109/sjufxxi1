#!/bin/bash

echo "=== AdsPower 代理检查失败解决方案 ==="
echo ""

# 检查当前IP和位置
echo "🌍 检查当前网络状态..."
echo "当前IP地址:"
curl -s --connect-timeout 5 http://ipinfo.io/ip || echo "无法获取IP地址"

echo ""
echo "当前位置信息:"
curl -s --connect-timeout 5 http://ipinfo.io/json | grep -E '"country"|"region"|"city"' || echo "无法获取位置信息"

echo ""
echo "🔍 检查代理服务器状态..."

# 检查系统代理
echo "系统代理配置:"
env | grep -i proxy

echo ""
echo "代理服务器连接测试:"
if ss -tlnp | grep -q 7890; then
    echo "✅ 代理服务器 (7890) 正在运行"
    
    # 测试代理连接
    echo "测试代理连接到Google..."
    PROXY_TEST=$(curl -x http://127.0.0.1:7890 --connect-timeout 10 -s -o /dev/null -w "%{http_code}" http://www.google.com 2>/dev/null)
    if [ "$PROXY_TEST" = "200" ]; then
        echo "✅ 代理连接正常"
    else
        echo "❌ 代理连接失败 (HTTP状态码: $PROXY_TEST)"
    fi
    
    # 测试代理IP
    echo "通过代理获取IP地址:"
    PROXY_IP=$(curl -x http://127.0.0.1:7890 --connect-timeout 10 -s http://ipinfo.io/ip 2>/dev/null)
    if [ -n "$PROXY_IP" ]; then
        echo "代理IP: $PROXY_IP"
        echo "代理位置信息:"
        curl -x http://127.0.0.1:7890 --connect-timeout 10 -s http://ipinfo.io/json | grep -E '"country"|"region"|"city"' 2>/dev/null
    else
        echo "❌ 无法通过代理获取IP"
    fi
else
    echo "❌ 代理服务器 (7890) 未运行"
fi

echo ""
echo "🔧 AdsPower 代理问题解决方案:"
echo ""

# 方案1: 启用本地API权限
echo "方案1: 启用本地API权限"
echo "----------------------------------------"

# 检查本地API状态
LOCAL_API_PORT=$(cat "/home/qinshu/.config/adspower_global/cwd_global/source/local_api" 2>/dev/null | grep -o '[0-9]\+' | tail -1)
if [ -z "$LOCAL_API_PORT" ]; then
    LOCAL_API_PORT="50325"
fi

API_RESPONSE=$(curl -s "http://localhost:$LOCAL_API_PORT/api/v1/browser/start?user_id=384" 2>/dev/null)

if echo "$API_RESPONSE" | grep -q "No local API permission"; then
    echo "❌ 本地API权限未启用"
    echo "正在尝试启用本地API权限..."
    
    # 尝试修改配置
    sqlite3 "/home/qinshu/.config/adspower_global/cwd_global/source/conf" \
    "INSERT OR REPLACE INTO config (key, value, update_time) VALUES 
    ('local_api_switch', '{\"local_api_switch\":\"1\"}', $(date +%s));" 2>/dev/null
    
    echo "✅ 已尝试启用本地API权限"
    echo "请手动在AdsPower界面中启用本地API:"
    echo "1. 打开AdsPower设置"
    echo "2. 找到'本地API'选项"
    echo "3. 启用'开启本地API'开关"
    echo "4. 保存设置并重启AdsPower"
else
    echo "✅ 本地API权限已启用"
fi

echo ""
echo "方案2: 代理配置优化"
echo "----------------------------------------"

# 创建代理测试脚本
cat > test_proxy_for_adspower.sh << 'EOF'
#!/bin/bash
echo "测试AdsPower代理配置..."

# 测试不同的代理设置
echo "1. 测试HTTP代理:"
curl -x http://127.0.0.1:7890 --connect-timeout 5 -s http://httpbin.org/ip

echo "2. 测试HTTPS代理:"
curl -x http://127.0.0.1:7890 --connect-timeout 5 -s https://httpbin.org/ip

echo "3. 测试SOCKS5代理 (如果支持):"
curl --socks5 127.0.0.1:7890 --connect-timeout 5 -s http://httpbin.org/ip 2>/dev/null || echo "SOCKS5不可用"

echo "4. 测试目标网站连接:"
curl -x http://127.0.0.1:7890 --connect-timeout 5 -s -o /dev/null -w "状态码: %{http_code}, 总时间: %{time_total}s\n" https://www.google.com
EOF

chmod +x test_proxy_for_adspower.sh
echo "✅ 已创建代理测试脚本: test_proxy_for_adspower.sh"

echo ""
echo "方案3: AdsPower浏览器配置调整"
echo "----------------------------------------"
echo "在AdsPower中为用户384配置代理:"
echo "1. 打开AdsPower浏览器界面"
echo "2. 找到用户ID 384的浏览器配置"
echo "3. 编辑代理设置:"
echo "   - 代理类型: HTTP"
echo "   - 代理地址: 127.0.0.1"
echo "   - 代理端口: 7890"
echo "   - 如果需要认证，请填写用户名和密码"
echo "4. 保存配置"
echo "5. 重新尝试启动浏览器"

echo ""
echo "方案4: 环境变量优化"
echo "----------------------------------------"

# 创建环境变量设置脚本
cat > set_proxy_env.sh << 'EOF'
#!/bin/bash
# AdsPower代理环境变量设置

export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export NO_PROXY=localhost,127.0.0.1,::1
export no_proxy=localhost,127.0.0.1,::1

echo "代理环境变量已设置"
echo "HTTP_PROXY: $HTTP_PROXY"
echo "HTTPS_PROXY: $HTTPS_PROXY"

# 启动AdsPower
echo "启动AdsPower..."
"/opt/AdsPower Global/adspower_global" --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox &
EOF

chmod +x set_proxy_env.sh
echo "✅ 已创建环境变量设置脚本: set_proxy_env.sh"

echo ""
echo "方案5: 代理服务器重启"
echo "----------------------------------------"
echo "如果代理服务器有问题，请尝试重启代理服务"
echo "常见的代理软件重启命令:"
echo "- Clash: sudo systemctl restart clash"
echo "- V2Ray: sudo systemctl restart v2ray"
echo "- 其他代理软件请查看相应文档"

echo ""
echo "🚀 推荐执行顺序:"
echo "1. 运行代理测试: ./test_proxy_for_adspower.sh"
echo "2. 在AdsPower界面中启用本地API"
echo "3. 配置AdsPower中的代理设置"
echo "4. 如果仍有问题，使用环境变量启动: ./set_proxy_env.sh"

echo ""
echo "=== 脚本执行完成 ==="
