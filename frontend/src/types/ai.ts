// DB-GPT AI 相关类型定义

export interface ChatMessage {
  id: string;
  content: string;
  role: 'user' | 'assistant' | 'system';
  timestamp: Date;
  metadata?: {
    sql?: string;
    chart?: ChartData;
    error?: string;
    suggestions?: string[];
    executionTime?: number;
    tokens?: {
      prompt: number;
      completion: number;
      total: number;
    };
  };
}

export interface ChatResponse {
  content: string;
  metadata?: {
    sql?: string;
    chart?: ChartData;
    suggestions?: string[];
    executionTime?: number;
    tokens?: {
      prompt: number;
      completion: number;
      total: number;
    };
  };
}

export interface ChartData {
  type: 'line' | 'bar' | 'pie' | 'scatter' | 'area' | 'table';
  data: any[];
  config?: {
    xAxis?: string;
    yAxis?: string | string[];
    title?: string;
    description?: string;
    colors?: string[];
  };
}

export interface SQLQueryRequest {
  query: string;
  database?: string;
  schema?: string;
  limit?: number;
  explain?: boolean;
}

export interface SQLQueryResponse {
  success: boolean;
  data?: any[];
  columns?: ColumnInfo[];
  sql?: string;
  error?: string;
  executionTime?: number;
  rowCount?: number;
  explain?: ExplainResult;
}

export interface ColumnInfo {
  name: string;
  type: string;
  nullable?: boolean;
  primaryKey?: boolean;
  autoIncrement?: boolean;
  defaultValue?: any;
  comment?: string;
}

export interface ExplainResult {
  plan: string;
  cost?: number;
  rows?: number;
  width?: number;
}

export interface DatabaseInfo {
  name: string;
  type: 'mysql' | 'postgresql' | 'sqlite' | 'duckdb' | 'clickhouse';
  host?: string;
  port?: number;
  description?: string;
  tables?: TableInfo[];
}

export interface TableInfo {
  name: string;
  schema?: string;
  type: 'table' | 'view' | 'materialized_view';
  rowCount?: number;
  columns?: ColumnInfo[];
  description?: string;
  indexes?: IndexInfo[];
}

export interface IndexInfo {
  name: string;
  columns: string[];
  unique: boolean;
  type?: string;
}

export interface ConversationInfo {
  id: string;
  title: string;
  createdAt: Date;
  updatedAt: Date;
  messageCount: number;
  tags?: string[];
}

// AWEL 工作流相关类型
export interface WorkflowNode {
  id: string;
  type: string;
  name: string;
  description?: string;
  position: { x: number; y: number };
  data: Record<string, any>;
  inputs?: WorkflowPort[];
  outputs?: WorkflowPort[];
}

export interface WorkflowPort {
  id: string;
  name: string;
  type: string;
  required?: boolean;
  description?: string;
}

export interface WorkflowEdge {
  id: string;
  source: string;
  target: string;
  sourcePort?: string;
  targetPort?: string;
  data?: Record<string, any>;
}

export interface Workflow {
  id: string;
  name: string;
  description?: string;
  version: string;
  nodes: WorkflowNode[];
  edges: WorkflowEdge[];
  metadata?: {
    author?: string;
    createdAt?: Date;
    updatedAt?: Date;
    tags?: string[];
  };
}

export interface WorkflowExecution {
  id: string;
  workflowId: string;
  status: 'pending' | 'running' | 'completed' | 'failed' | 'cancelled';
  startTime: Date;
  endTime?: Date;
  duration?: number;
  result?: any;
  error?: string;
  logs?: ExecutionLog[];
}

export interface ExecutionLog {
  timestamp: Date;
  level: 'debug' | 'info' | 'warn' | 'error';
  message: string;
  nodeId?: string;
  data?: any;
}

// 数据可视化相关类型
export interface VisualizationConfig {
  id: string;
  name: string;
  type: ChartData['type'];
  query: string;
  database?: string;
  refreshInterval?: number; // 秒
  config: {
    title?: string;
    description?: string;
    width?: number | string;
    height?: number | string;
    responsive?: boolean;
    theme?: 'light' | 'dark';
    colors?: string[];
    legend?: {
      show: boolean;
      position: 'top' | 'bottom' | 'left' | 'right';
    };
    tooltip?: {
      show: boolean;
      format?: string;
    };
    xAxis?: AxisConfig;
    yAxis?: AxisConfig;
  };
}

export interface AxisConfig {
  name?: string;
  type?: 'category' | 'value' | 'time' | 'log';
  min?: number;
  max?: number;
  format?: string;
  rotate?: number;
  show?: boolean;
}

// API 响应基础类型
export interface APIResponse<T = any> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
  pagination?: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
  metadata?: {
    requestId: string;
    timestamp: string;
    version: string;
  };
}

// 流式响应类型
export interface StreamResponse {
  type: 'start' | 'chunk' | 'end' | 'error';
  data?: string;
  error?: string;
  metadata?: Record<string, any>;
}

// 用户偏好设置
export interface ChatSettings {
  enableSuggestions: boolean;
  enableVoiceInput: boolean;
  theme: 'light' | 'dark' | 'auto';
  language: 'zh-CN' | 'en-US';
  maxHistoryLength: number;
  autoSave: boolean;
  streamMode: boolean;
}

// 性能监控类型
export interface PerformanceMetrics {
  requestId: string;
  endpoint: string;
  method: string;
  startTime: number;
  endTime: number;
  duration: number;
  status: number;
  responseSize?: number;
  userAgent?: string;
  timestamp: Date;
}

// 错误类型
export interface AIError extends Error {
  code?: string;
  status?: number;
  details?: any;
  requestId?: string;
}

// 实用工具类型
export type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

export type Optional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

export type RequiredOnly<T, K extends keyof T> = Partial<T> & Required<Pick<T, K>>;