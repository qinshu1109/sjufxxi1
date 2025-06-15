#!/bin/bash
# DeepSeek插件安装修复脚本

set -e

# 加载环境配置
source "$(dirname "$0")/load_env.sh"

echo "🔧 修复DeepSeek插件安装问题..."
cd "$DIFY_DIR/docker"

echo "📊 当前问题分析："
echo "- 插件安装时无法连接PyPI服务器"
echo "- 需要配置网络代理或使用国内镜像源"

echo ""
echo "🔄 解决方案选择："
echo "1. 手动配置OpenAI兼容模型（推荐）"
echo "2. 修复网络连接后重试插件安装"
echo "3. 使用国内PyPI镜像源"

echo ""
read -p "请选择解决方案 (1/2/3): " choice

case $choice in
    1)
        echo "🔧 方案1: 手动配置OpenAI兼容模型"
        echo ""
        echo "DeepSeek API与OpenAI API完全兼容，可以直接配置："
        echo ""
        echo "1. 在Dify中选择 '模型供应商' -> 'OpenAI'"
        echo "2. 配置以下参数："
        echo "   - API Key: $DEEPSEEK_API_KEY"
        echo "   - API Base URL: https://api.deepseek.com/v1"
        echo "   - 模型名称: deepseek-chat"
        echo ""
        echo "3. 测试连接成功后即可使用DeepSeek模型"
        echo ""
        echo "✅ 这种方式最稳定，推荐使用！"
        ;;
    
    2)
        echo "🔧 方案2: 修复网络连接"
        echo ""
        echo "重启插件守护进程..."
        docker compose restart plugin_daemon
        
        echo "等待服务启动..."
        sleep 10
        
        echo "检查网络连接..."
        if docker compose exec plugin_daemon ping -c 3 pypi.org > /dev/null 2>&1; then
            echo "✅ 网络连接正常，可以重试安装插件"
        else
            echo "❌ 网络连接仍有问题，建议使用方案1或方案3"
        fi
        ;;
        
    3)
        echo "🔧 方案3: 配置国内PyPI镜像源"
        echo ""
        echo "创建pip配置文件..."
        
        # 创建pip配置目录和文件
        docker compose exec plugin_daemon mkdir -p /root/.pip
        
        cat > /tmp/pip.conf << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple/
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
EOF
        
        # 复制配置文件到容器
        docker cp /tmp/pip.conf docker-plugin_daemon-1:/root/.pip/pip.conf
        
        echo "重启插件服务..."
        docker compose restart plugin_daemon
        
        echo "等待服务启动..."
        sleep 10
        
        echo "✅ 已配置清华大学PyPI镜像源，可以重试安装插件"
        rm /tmp/pip.conf
        ;;
        
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "📋 手动配置DeepSeek模型步骤："
echo "================================"
echo ""
echo "1. 访问 http://localhost/console"
echo "2. 进入 '模型供应商' 设置"
echo "3. 选择 'OpenAI' 供应商"
echo "4. 填入以下配置："
echo "   API Key: $DEEPSEEK_API_KEY"
echo "   Base URL: https://api.deepseek.com/v1"
echo "5. 添加模型: deepseek-chat"
echo "6. 测试连接并保存"
echo ""
echo "🎯 这样就可以在应用中使用DeepSeek模型了！"

# 创建快速配置脚本
cat > ../quick_setup_deepseek.md << 'EOF'
# DeepSeek模型快速配置指南

## 方法：使用OpenAI兼容接口

DeepSeek API完全兼容OpenAI API格式，可以直接在Dify中配置为OpenAI模型。

### 配置步骤：

1. **访问模型设置**
   - 打开 http://localhost/console
   - 进入 "设置" -> "模型供应商"

2. **添加OpenAI供应商**
   - 选择 "OpenAI" 
   - 点击 "设置"

3. **填写配置信息**
   ```
   API Key: your_deepseek_api_key
   Base URL: https://api.deepseek.com/v1
   ```

4. **添加模型**
   - 在模型列表中添加：
     - 模型名称: `deepseek-chat`
     - 类型: Chat
   
5. **测试连接**
   - 点击 "测试" 验证连接
   - 保存配置

### 可用模型：
- `deepseek-chat` - 通用对话模型
- `deepseek-coder` - 代码生成模型

### 优势：
- ✅ 无需插件，直接使用
- ✅ 配置简单，兼容性好
- ✅ 避免网络连接问题
- ✅ 功能完整，性能稳定

配置完成后即可在应用中选择使用DeepSeek模型！
EOF

echo ""
echo "📄 详细配置指南已保存到: $DIFY_DIR/quick_setup_deepseek.md"
echo "✅ DeepSeek插件问题修复完成！"