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
