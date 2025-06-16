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
      tables: '/tables',
    },
  },

  // 功能开关
  features: {
    nl2sql: true,
    workflow: true,
    vectorSearch: true,
    dataInsight: true,
  },

  // 默认参数
  defaults: {
    database: 'analytics',
    temperature: 0.7,
    maxTokens: 2000,
  },
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
        database: database || AI_CONFIG.defaults.database,
      }),
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
        parameters: parameters || {},
      }),
    });
    return response.json();
  }

  async getDatabases() {
    const response = await fetch(`${this.baseUrl}${AI_CONFIG.dbgpt.endpoints.databases}`);
    return response.json();
  }
}

export const dbgptClient = new DBGPTClient();
