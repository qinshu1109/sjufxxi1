#!/bin/bash

# GitHub推送辅助脚本
echo "=== GitHub 仓库推送助手 ==="
echo ""

# 检查是否已经有远程仓库
REMOTE_URL=$(git config --get remote.origin.url)
if [ -z "$REMOTE_URL" ]; then
    echo "错误：未找到远程仓库配置"
    exit 1
fi

echo "远程仓库：$REMOTE_URL"
echo ""

# 检查是否有未提交的更改
if ! git diff-index --quiet HEAD --; then
    echo "检测到未提交的更改，是否要提交？(y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        git add -A
        echo "请输入提交信息："
        read -r commit_msg
        git commit -m "$commit_msg"
    fi
fi

# 尝试使用git credential helper
echo "配置Git凭据管理器..."
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=3600'

# 打开GitHub登录页面
echo ""
echo "即将打开GitHub登录页面..."
echo "请在浏览器中："
echo "1. 登录您的GitHub账号"
echo "2. 生成个人访问令牌(Personal Access Token)"
echo "   - 访问: https://github.com/settings/tokens/new"
echo "   - 勾选 'repo' 权限"
echo "   - 生成并复制令牌"
echo ""

# 打开浏览器
xdg-open "https://github.com/settings/tokens/new?scopes=repo&description=douyin-analytics-push" 2>/dev/null || \
    open "https://github.com/settings/tokens/new?scopes=repo&description=douyin-analytics-push" 2>/dev/null || \
    echo "请手动打开: https://github.com/settings/tokens/new?scopes=repo&description=douyin-analytics-push"

echo ""
echo "请输入您的GitHub用户名："
read -r github_username

echo "请粘贴您的个人访问令牌(输入时不会显示)："
read -s github_token

# 更新远程URL以包含凭据
REPO_NAME=$(echo $REMOTE_URL | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
NEW_REMOTE_URL="https://${github_username}:${github_token}@github.com/${REPO_NAME}.git"

echo ""
echo "正在推送到GitHub..."
git push -u $NEW_REMOTE_URL master

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 推送成功！"
    echo "仓库地址：https://github.com/${REPO_NAME}"
    
    # 保存凭据配置（不包含令牌）
    git remote set-url origin "https://github.com/${REPO_NAME}.git"
    echo ""
    echo "提示：已更新远程仓库URL（不包含令牌）"
    echo "下次推送时，Git会使用缓存的凭据"
else
    echo ""
    echo "❌ 推送失败，请检查错误信息"
fi