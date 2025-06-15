#!/bin/bash
# 环境变量加载脚本
# 用于统一管理项目环境配置

set -e

# 获取项目根目录
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 默认环境变量
export PROJECT_NAME="douyin-analytics"
export PROJECT_DIR="$PROJECT_DIR"

# 加载环境变量的优先级：
# 1. 系统环境变量 (最高优先级)
# 2. .env 文件
# 3. .env.example 文件 (默认值)

load_env_file() {
    local env_file="$1"
    if [ -f "$env_file" ]; then
        echo "📝 加载环境配置: $env_file"
        # 读取环境变量文件，跳过注释和空行
        while IFS= read -r line; do
            # 跳过注释和空行
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
                # 如果变量尚未设置，则设置它
                var_name=$(echo "$line" | cut -d= -f1)
                if [ -z "${!var_name}" ]; then
                    export "$line"
                fi
            fi
        done < "$env_file"
        return 0
    fi
    return 1
}

echo "🔧 正在加载环境配置..."

# 1. 尝试加载 .env 文件
if load_env_file "$PROJECT_DIR/.env"; then
    echo "✅ 已加载用户配置 (.env)"
else
    echo "⚠️  未找到 .env 文件，使用默认配置"
    
    # 2. 加载默认配置
    if load_env_file "$PROJECT_DIR/.env.example"; then
        echo "✅ 已加载默认配置 (.env.example)"
    else
        echo "❌ 未找到配置文件，请创建 .env 或 .env.example"
        exit 1
    fi
fi

# 3. 设置项目特定的默认值
export DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:-your_api_key_here}"
export FEISHU_WEBHOOK="${FEISHU_WEBHOOK:-https://open.feishu.cn/open-apis/bot/v2/hook/default}"
export SECRET_KEY="${SECRET_KEY:-douyin-analytics-secret-$(date +%s)}"
export WEB_PORT="${WEB_PORT:-80}"
export API_PORT="${API_PORT:-5000}"

# 设置路径相关变量
export DUCKDB_PATH="${PROJECT_DIR}/data/db/analytics.duckdb"
export DUCKDB_DSN="duckdb://${DUCKDB_PATH}"
export DIFY_DIR="${PROJECT_DIR}/dify"

echo "✅ 环境配置加载完成"
echo "📁 项目目录: $PROJECT_DIR"
echo "📊 数据库路径: $DUCKDB_PATH"
echo "🐳 Dify目录: $DIFY_DIR"

# 验证关键配置
if [ "$DEEPSEEK_API_KEY" = "your_api_key_here" ]; then
    echo "⚠️  警告: DeepSeek API密钥未配置，请在 .env 文件中设置 DEEPSEEK_API_KEY"
fi

if [[ "$FEISHU_WEBHOOK" == *"default"* ]]; then
    echo "⚠️  警告: 飞书Webhook未配置，请在 .env 文件中设置 FEISHU_WEBHOOK"
fi