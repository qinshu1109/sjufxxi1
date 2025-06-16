import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios';
import { message } from 'antd';

// 类型定义
export interface ChatMessage {
  id: string;
  content: string;
  role: 'user' | 'assistant';
  timestamp: Date;
  metadata?: {
    sql?: string;
    chart?: any;
    error?: string;
  };
}

export interface ChatResponse {
  content: string;
  metadata?: {
    sql?: string;
    chart?: any;
    suggestions?: string[];
  };
}

export interface SQLQueryRequest {
  query: string;
  database?: string;
}

export interface SQLQueryResponse {
  success: boolean;
  data?: any[];
  columns?: string[];
  sql?: string;
  error?: string;
  execution_time?: number;
}

// AI API 客户端类
class AIAPIClient {
  private client: AxiosInstance;
  private baseURL: string;

  constructor(baseURL: string = '/api/ai') {
    this.baseURL = baseURL;
    this.client = axios.create({
      baseURL,
      timeout: 30000, // 30秒超时
      headers: {
        'Content-Type': 'application/json',
      },
    });

    this.setupInterceptors();
  }

  private setupInterceptors() {
    // 请求拦截器 - 添加认证头
    this.client.interceptors.request.use(
      (config: InternalAxiosRequestConfig) => {
        // 从localStorage或store获取token
        const token = localStorage.getItem('auth_token');
        if (token && config.headers) {
          config.headers.Authorization = `Bearer ${token}`;
        }

        // 添加请求ID用于追踪
        if (config.headers) {
          config.headers['X-Request-ID'] = `req_${Date.now()}_${Math.random().toString(36).slice(2)}`;
        }

        return config;
      },
      (error) => {
        console.error('API请求配置错误:', error);
        return Promise.reject(error);
      }
    );

    // 响应拦截器 - 统一错误处理
    this.client.interceptors.response.use(
      (response: AxiosResponse) => {
        return response;
      },
      (error) => {
        console.error('API响应错误:', error);
        
        if (error.response) {
          // 服务器响应错误
          const { status, data } = error.response;
          
          switch (status) {
            case 401:
              message.error('认证失败，请重新登录');
              // 重定向到登录页
              window.location.href = '/auth/login';
              break;
            case 403:
              message.error('权限不足，无法访问该功能');
              break;
            case 404:
              message.error('请求的资源不存在');
              break;
            case 429:
              message.error('请求频率过高，请稍后再试');
              break;
            case 500:
              message.error('服务器内部错误，请稍后重试');
              break;
            default:
              message.error(data?.message || '请求失败，请重试');
          }
        } else if (error.request) {
          // 网络错误
          message.error('网络连接异常，请检查网络设置');
        } else {
          // 其他错误
          message.error('请求配置错误');
        }

        return Promise.reject(error);
      }
    );
  }

  // 发送聊天消息
  async sendChatMessage(message: string, conversationId?: string): Promise<ChatResponse> {
    try {
      const response = await this.client.post('/chat/send', {
        message,
        conversation_id: conversationId,
        stream: false, // 是否启用流式响应
      });

      return response.data;
    } catch (error) {
      console.error('发送聊天消息失败:', error);
      throw error;
    }
  }

  // 流式聊天响应
  async sendChatMessageStream(
    message: string, 
    conversationId?: string,
    onMessage?: (chunk: string) => void
  ): Promise<void> {
    try {
      const response = await fetch(`${this.baseURL}/chat/stream`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('auth_token')}`,
        },
        body: JSON.stringify({
          message,
          conversation_id: conversationId,
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const reader = response.body?.getReader();
      if (!reader) {
        throw new Error('ReadableStream not supported');
      }

      const decoder = new TextDecoder();
      
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        
        const chunk = decoder.decode(value);
        onMessage?.(chunk);
      }
    } catch (error) {
      console.error('流式聊天失败:', error);
      throw error;
    }
  }

  // 执行SQL查询
  async executeSQL(request: SQLQueryRequest): Promise<SQLQueryResponse> {
    try {
      const response = await this.client.post('/sql/execute', request);
      return response.data;
    } catch (error) {
      console.error('SQL查询失败:', error);
      throw error;
    }
  }

  // 自然语言转SQL
  async naturalLanguageToSQL(query: string, database?: string): Promise<SQLQueryResponse> {
    try {
      const response = await this.client.post('/sql/nl2sql', {
        query,
        database,
      });
      return response.data;
    } catch (error) {
      console.error('NL2SQL转换失败:', error);
      throw error;
    }
  }

  // 获取数据库列表
  async getDatabases(): Promise<string[]> {
    try {
      const response = await this.client.get('/databases');
      return response.data.databases || [];
    } catch (error) {
      console.error('获取数据库列表失败:', error);
      throw error;
    }
  }

  // 获取表结构
  async getTableSchema(database: string, table: string): Promise<any> {
    try {
      const response = await this.client.get(`/databases/${database}/tables/${table}/schema`);
      return response.data;
    } catch (error) {
      console.error('获取表结构失败:', error);
      throw error;
    }
  }

  // 获取聊天历史
  async getChatHistory(conversationId?: string): Promise<ChatMessage[]> {
    try {
      const response = await this.client.get('/chat/history', {
        params: { conversation_id: conversationId },
      });
      return response.data.messages || [];
    } catch (error) {
      console.error('获取聊天历史失败:', error);
      throw error;
    }
  }

  // 清空聊天历史
  async clearChatHistory(conversationId?: string): Promise<void> {
    try {
      await this.client.delete('/chat/history', {
        data: { conversation_id: conversationId },
      });
    } catch (error) {
      console.error('清空聊天历史失败:', error);
      throw error;
    }
  }

  // 健康检查
  async healthCheck(): Promise<boolean> {
    try {
      const response = await this.client.get('/health');
      return response.data.status === 'ok';
    } catch (error) {
      console.error('健康检查失败:', error);
      return false;
    }
  }
}

// 创建全局AI API实例
export const aiAPI = new AIAPIClient();

// 导出便捷方法
export const aiServices = {
  chat: {
    send: (message: string, conversationId?: string) => 
      aiAPI.sendChatMessage(message, conversationId),
    sendStream: (message: string, conversationId?: string, onMessage?: (chunk: string) => void) => 
      aiAPI.sendChatMessageStream(message, conversationId, onMessage),
    getHistory: (conversationId?: string) => 
      aiAPI.getChatHistory(conversationId),
    clearHistory: (conversationId?: string) => 
      aiAPI.clearChatHistory(conversationId),
  },
  sql: {
    execute: (request: SQLQueryRequest) => 
      aiAPI.executeSQL(request),
    nl2sql: (query: string, database?: string) => 
      aiAPI.naturalLanguageToSQL(query, database),
  },
  database: {
    list: () => aiAPI.getDatabases(),
    getSchema: (database: string, table: string) => 
      aiAPI.getTableSchema(database, table),
  },
  system: {
    health: () => aiAPI.healthCheck(),
  },
};

export default aiAPI;