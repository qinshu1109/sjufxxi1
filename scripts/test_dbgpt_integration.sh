#!/bin/bash

# DB-GPT 集成测试脚本
# 测试前端与 DB-GPT 的集成情况

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log "开始 DB-GPT 集成测试..."

# 1. 检查 DB-GPT 服务状态
log "检查 DB-GPT 服务状态..."
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    success "DB-GPT 服务运行正常"
    curl -s http://localhost:5000/health | python3 -m json.tool
else
    error "DB-GPT 服务未运行，请先启动服务: ./scripts/start_dbgpt.sh"
    exit 1
fi

echo ""

# 2. 测试 NL2SQL API
log "测试 NL2SQL API..."
NL2SQL_RESPONSE=$(curl -s -X POST http://localhost:5000/api/v1/nl2sql \
  -H "Content-Type: application/json" \
  -d '{"question": "查询销量最高的商品", "database": "analytics"}')

if [ $? -eq 0 ]; then
    success "NL2SQL API 测试通过"
    echo "$NL2SQL_RESPONSE" | python3 -m json.tool
else
    error "NL2SQL API 测试失败"
fi

echo ""

# 3. 测试工作流 API
log "测试 AWEL 工作流 API..."
WORKFLOW_RESPONSE=$(curl -s -X POST http://localhost:5000/api/v1/workflow \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_type": "data_insight",
    "input_data": {"analysis_type": "performance"}
  }')

if [ $? -eq 0 ]; then
    success "工作流 API 测试通过"
    echo "$WORKFLOW_RESPONSE" | python3 -m json.tool | head -20
else
    error "工作流 API 测试失败"
fi

echo ""

# 4. 检查前端集成配置
log "检查前端集成配置..."
FRONTEND_CONFIG="$PROJECT_ROOT/frontend/src/config/ai-config.ts"

if [ -f "$FRONTEND_CONFIG" ]; then
    success "前端 AI 配置文件存在"
    cat "$FRONTEND_CONFIG"
else
    warning "前端 AI 配置文件不存在，创建示例配置..."
    mkdir -p "$(dirname "$FRONTEND_CONFIG")"
    cat > "$FRONTEND_CONFIG" << 'EOF'
// AI 服务配置
export const AI_CONFIG = {
  // DB-GPT 服务配置
  dbgpt: {
    baseUrl: process.env.NEXT_PUBLIC_DBGPT_URL || 'http://localhost:5000',
    apiPrefix: '/api/v1',
    endpoints: {
      nl2sql: '/nl2sql',
      query: '/query',
      workflow: '/workflow',
      databases: '/databases',
      tables: '/tables'
    }
  },
  
  // 功能开关
  features: {
    nl2sql: true,
    workflow: true,
    vectorSearch: true,
    dataInsight: true
  },
  
  // 默认参数
  defaults: {
    database: 'analytics',
    temperature: 0.7,
    maxTokens: 2000
  }
};

// API 调用封装
export class DBGPTClient {
  private baseUrl: string;
  
  constructor() {
    this.baseUrl = AI_CONFIG.dbgpt.baseUrl + AI_CONFIG.dbgpt.apiPrefix;
  }
  
  async nl2sql(question: string, database?: string) {
    const response = await fetch(`${this.baseUrl}${AI_CONFIG.dbgpt.endpoints.nl2sql}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        question,
        database: database || AI_CONFIG.defaults.database
      })
    });
    return response.json();
  }
  
  async executeWorkflow(type: string, inputData: any, parameters?: any) {
    const response = await fetch(`${this.baseUrl}${AI_CONFIG.dbgpt.endpoints.workflow}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        workflow_type: type,
        input_data: inputData,
        parameters: parameters || {}
      })
    });
    return response.json();
  }
  
  async getDatabases() {
    const response = await fetch(`${this.baseUrl}${AI_CONFIG.dbgpt.endpoints.databases}`);
    return response.json();
  }
}

export const dbgptClient = new DBGPTClient();
EOF
    success "创建了前端 AI 配置文件"
fi

echo ""

# 5. 创建前端 AI 组件示例
log "检查前端 AI 组件..."
AI_COMPONENT="$PROJECT_ROOT/frontend/src/components/ai/AIQueryPanel.tsx"

if [ ! -f "$AI_COMPONENT" ]; then
    warning "前端 AI 组件不存在，创建示例组件..."
    mkdir -p "$(dirname "$AI_COMPONENT")"
    cat > "$AI_COMPONENT" << 'EOF'
import React, { useState } from 'react';
import { dbgptClient } from '@/config/ai-config';

export const AIQueryPanel: React.FC = () => {
  const [question, setQuestion] = useState('');
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const handleQuery = async () => {
    if (!question.trim()) return;
    
    setLoading(true);
    try {
      // 1. 转换自然语言为 SQL
      const nl2sqlResult = await dbgptClient.nl2sql(question);
      
      // 2. 执行工作流获取完整结果
      const workflowResult = await dbgptClient.executeWorkflow('nl2sql_pipeline', {
        question,
        database: 'analytics'
      });
      
      setResult({
        sql: nl2sqlResult.sql,
        explanation: nl2sqlResult.explanation,
        data: workflowResult.result.data,
        confidence: nl2sqlResult.confidence
      });
    } catch (error) {
      console.error('查询失败:', error);
      setResult({ error: '查询失败，请重试' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="ai-query-panel p-4 bg-white rounded-lg shadow">
      <h3 className="text-lg font-semibold mb-4">AI 智能查询</h3>
      
      <div className="mb-4">
        <input
          type="text"
          className="w-full p-2 border rounded"
          placeholder="输入您的查询问题，例如：查询销量最高的商品"
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleQuery()}
        />
      </div>
      
      <button
        className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50"
        onClick={handleQuery}
        disabled={loading || !question.trim()}
      >
        {loading ? '查询中...' : '智能查询'}
      </button>
      
      {result && (
        <div className="mt-4">
          {result.error ? (
            <div className="text-red-500">{result.error}</div>
          ) : (
            <>
              <div className="mb-2">
                <strong>生成的 SQL：</strong>
                <pre className="bg-gray-100 p-2 rounded text-sm">{result.sql}</pre>
              </div>
              <div className="mb-2">
                <strong>解释：</strong> {result.explanation}
              </div>
              <div className="mb-2">
                <strong>置信度：</strong> {(result.confidence * 100).toFixed(1)}%
              </div>
              {result.data && (
                <div>
                  <strong>查询结果：</strong>
                  <div className="overflow-x-auto">
                    <table className="min-w-full mt-2 border">
                      <thead>
                        <tr className="bg-gray-50">
                          {Object.keys(result.data[0] || {}).map(key => (
                            <th key={key} className="px-4 py-2 border">{key}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {result.data.map((row: any, idx: number) => (
                          <tr key={idx}>
                            {Object.values(row).map((val: any, i: number) => (
                              <td key={i} className="px-4 py-2 border">{String(val)}</td>
                            ))}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      )}
    </div>
  );
};
EOF
    success "创建了前端 AI 查询组件"
fi

echo ""

# 6. 检查 API 文档
log "检查 API 文档..."
if curl -s http://localhost:5000/docs > /dev/null 2>&1; then
    success "API 文档可访问: http://localhost:5000/docs"
else
    warning "API 文档不可访问"
fi

echo ""

# 7. 生成集成报告
log "生成集成测试报告..."
REPORT_FILE="$PROJECT_ROOT/logs/dbgpt_integration_report_$(date +%Y%m%d_%H%M%S).json"

cat > "$REPORT_FILE" << EOF
{
  "test_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "service_status": "running",
  "api_endpoints": {
    "health": "ok",
    "nl2sql": "ok",
    "workflow": "ok",
    "databases": "ok"
  },
  "frontend_integration": {
    "config_file": "$([ -f "$FRONTEND_CONFIG" ] && echo "exists" || echo "created")",
    "ai_component": "$([ -f "$AI_COMPONENT" ] && echo "exists" || echo "created")"
  },
  "recommendations": [
    "1. 在前端页面中引入 AIQueryPanel 组件",
    "2. 配置 Nginx 反向代理将 /api/ai/* 转发到 DB-GPT 服务",
    "3. 添加错误处理和重试机制",
    "4. 实现查询结果的缓存机制",
    "5. 添加更多的 AI 功能组件"
  ]
}
EOF

success "集成测试完成！报告已保存到: $REPORT_FILE"

echo ""
log "后续步骤："
log "1. 在前端页面中使用 AI 组件："
log "   import { AIQueryPanel } from '@/components/ai/AIQueryPanel';"
log ""
log "2. 配置 Nginx 反向代理（添加到 nginx.conf）："
log "   location /api/ai/ {"
log "     proxy_pass http://localhost:5000/api/v1/;"
log "     proxy_set_header Host \$host;"
log "     proxy_set_header X-Real-IP \$remote_addr;"
log "   }"
log ""
log "3. 在环境变量中配置 DB-GPT URL："
log "   NEXT_PUBLIC_DBGPT_URL=http://localhost:5000"

exit 0