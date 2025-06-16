/**
 * DB-GPT 组件包装器导出
 * 
 * 这些组件将在 DB-GPT 构建完成后替换为实际的 DB-GPT React 组件
 * 当前提供模拟实现以支持开发和测试
 */

// 主要组件
export { default as ChatBox } from './ChatBox';

// 类型定义
export interface DBGPTConfig {
  apiBaseUrl: string;
  theme: 'light' | 'dark';
  language: 'zh' | 'en';
  features: {
    chat: boolean;
    sqlLab: boolean;
    visualization: boolean;
    workflow: boolean;
  };
}

export interface ChatMessage {
  id: string;
  type: 'user' | 'ai';
  content: string;
  timestamp: Date;
  metadata?: Record<string, any>;
}

export interface SQLQuery {
  id: string;
  sql: string;
  database: string;
  timestamp: Date;
  results?: any[];
  error?: string;
}

// 工具函数
export const createDBGPTConfig = (overrides: Partial<DBGPTConfig> = {}): DBGPTConfig => ({
  apiBaseUrl: '/api/ai',
  theme: 'light',
  language: 'zh',
  features: {
    chat: true,
    sqlLab: true,
    visualization: true,
    workflow: true,
  },
  ...overrides,
});

// 检查 DB-GPT 是否可用
export const checkDBGPTAvailability = async (): Promise<boolean> => {
  try {
    const response = await fetch('/ai/dbgpt-config.json');
    return response.ok;
  } catch {
    return false;
  }
};

// 获取 DB-GPT 配置
export const getDBGPTConfig = async (): Promise<DBGPTConfig | null> => {
  try {
    const response = await fetch('/ai/dbgpt-config.json');
    if (response.ok) {
      return await response.json();
    }
    return null;
  } catch {
    return null;
  }
};
