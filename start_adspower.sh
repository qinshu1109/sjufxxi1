#!/bin/bash

# AdsPower浏览器启动脚本
# 解决图形渲染问题

echo "正在启动AdsPower浏览器..."

# 检查是否已有AdsPower进程在运行
if pgrep -f "adspower_global" > /dev/null; then
    echo "AdsPower浏览器已在运行，尝试激活窗口..."
    wmctrl -a "AdsPower Browser" 2>/dev/null || echo "无法激活窗口，请手动查找AdsPower窗口"
else
    echo "启动AdsPower浏览器..."
    "/opt/AdsPower Global/adspower_global" --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox &
    
    # 等待几秒钟让应用启动
    sleep 3
    
    # 尝试激活窗口
    wmctrl -a "AdsPower Browser" 2>/dev/null || echo "AdsPower浏览器已启动，请在任务栏或窗口列表中查找"
fi

echo "完成！"
