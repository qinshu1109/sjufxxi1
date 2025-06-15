#!/bin/bash

echo "=== 最终推送脚本 ==="
echo "等待您在浏览器中创建 douyin-analytics 仓库..."
echo ""
echo "创建完成后，按回车继续..."
read

# 使用Personal Access Token推送
git push https://qinshu1109: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@github.com/qinshu1109/douyin-analytics.git master

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 推送成功！"
    echo "仓库地址：https://github.com/qinshu1109/douyin-analytics"
    
    # 设置后续推送不需要令牌
    git remote set-url origin https://github.com/qinshu1109/douyin-analytics.git
    
    echo ""
    echo "后续推送可使用: git push origin master"
    echo "系统会使用缓存的凭据"
else
    echo ""
    echo "❌ 推送失败"
fi