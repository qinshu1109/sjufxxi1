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
