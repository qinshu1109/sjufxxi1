#!/bin/bash
# 修复项目权限脚本

echo "🔧 修复权限和配置..."

PROJECT_DIR="/home/qinshu/douyin-analytics"
USER="qinshu"

# 1. 修复项目目录权限
echo "修复项目目录权限..."
sudo chown -R $USER:$USER $PROJECT_DIR
chmod -R 755 $PROJECT_DIR

# 2. 修复Docker权限
echo "修复Docker权限..."
sudo usermod -aG docker $USER
sudo chown -R $USER:$USER ~/.docker 2>/dev/null || true

# 3. 修复脚本执行权限
echo "修复脚本执行权限..."
find $PROJECT_DIR/scripts -name "*.sh" -exec chmod +x {} \;
find $PROJECT_DIR/config -name "*.py" -exec chmod +x {} \;

# 4. 检查关键文件权限
echo -e "\n检查关键文件权限："
ls -la $PROJECT_DIR/data/db/analytics.duckdb 2>/dev/null && echo "✅ DuckDB文件权限正常" || echo "❌ DuckDB文件不存在"
ls -la ~/.docker/config.json 2>/dev/null && echo "✅ Docker配置文件权限正常" || echo "❌ Docker配置文件不存在"

# 5. 测试Docker权限
echo -e "\n测试Docker权限："
if docker ps >/dev/null 2>&1; then
    echo "✅ Docker权限正常"
else
    echo "❌ Docker权限异常，可能需要重新登录"
fi

echo -e "\n✅ 权限修复完成！"