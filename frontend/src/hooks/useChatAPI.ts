import { useState, useCallback, useRef } from 'react';
import { message } from 'antd';
import { aiServices, ChatMessage, ChatResponse } from '@/api/ai';

export interface UseChatAPIOptions {
  conversationId?: string;
  enableStream?: boolean;
  onError?: (error: Error) => void;
  onSuccess?: (response: ChatResponse) => void;
}

export interface UseChatAPIReturn {
  // 状态
  messages: ChatMessage[];
  isLoading: boolean;
  error: Error | null;
  
  // 方法
  sendMessage: (content: string) => Promise<ChatResponse | void>;
  sendMessageStream: (content: string, onChunk?: (chunk: string) => void) => Promise<void>;
  clearHistory: () => Promise<void>;
  loadHistory: () => Promise<void>;
  
  // 工具方法
  resetError: () => void;
  getLastMessage: () => ChatMessage | undefined;
}

export const useChatAPI = (options: UseChatAPIOptions = {}): UseChatAPIReturn => {
  const {
    conversationId,
    enableStream = false,
    onError,
    onSuccess,
  } = options;

  // 状态管理
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  
  // 引用，避免重复请求
  const abortControllerRef = useRef<AbortController | null>(null);

  // 重置错误状态
  const resetError = useCallback(() => {
    setError(null);
  }, []);

  // 获取最后一条消息
  const getLastMessage = useCallback(() => {
    return messages[messages.length - 1];
  }, [messages]);

  // 添加消息到列表
  const addMessage = useCallback((message: ChatMessage) => {
    setMessages(prev => [...prev, message]);
  }, []);

  // 更新最后一条消息
  const updateLastMessage = useCallback((updates: Partial<ChatMessage>) => {
    setMessages(prev => {
      const newMessages = [...prev];
      const lastIndex = newMessages.length - 1;
      if (lastIndex >= 0) {
        newMessages[lastIndex] = { ...newMessages[lastIndex], ...updates };
      }
      return newMessages;
    });
  }, []);

  // 发送普通消息
  const sendMessage = useCallback(async (content: string): Promise<ChatResponse | void> => {
    if (!content.trim() || isLoading) {
      return;
    }

    // 取消之前的请求
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }
    
    abortControllerRef.current = new AbortController();

    // 添加用户消息
    const userMessage: ChatMessage = {
      id: `user_${Date.now()}`,
      content: content.trim(),
      role: 'user',
      timestamp: new Date(),
    };
    
    addMessage(userMessage);
    setIsLoading(true);
    setError(null);

    try {
      const response = await aiServices.chat.send(content.trim(), conversationId);
      
      // 添加AI回复
      const botMessage: ChatMessage = {
        id: `bot_${Date.now()}`,
        content: response.content,
        role: 'assistant',
        timestamp: new Date(),
        metadata: response.metadata,
      };
      
      addMessage(botMessage);
      onSuccess?.(response);
      
      return response;
    } catch (err) {
      const error = err as Error;
      setError(error);
      onError?.(error);
      message.error('消息发送失败，请重试');
    } finally {
      setIsLoading(false);
      abortControllerRef.current = null;
    }
  }, [isLoading, conversationId, addMessage, onError, onSuccess]);

  // 发送流式消息
  const sendMessageStream = useCallback(async (
    content: string, 
    onChunk?: (chunk: string) => void
  ): Promise<void> => {
    if (!content.trim() || isLoading) {
      return;
    }

    // 添加用户消息
    const userMessage: ChatMessage = {
      id: `user_${Date.now()}`,
      content: content.trim(),
      role: 'user',
      timestamp: new Date(),
    };
    
    addMessage(userMessage);

    // 添加空的AI消息，用于流式更新
    const botMessage: ChatMessage = {
      id: `bot_${Date.now()}`,
      content: '',
      role: 'assistant',
      timestamp: new Date(),
    };
    
    addMessage(botMessage);
    setIsLoading(true);
    setError(null);

    try {
      let fullContent = '';
      
      await aiServices.chat.sendStream(
        content.trim(),
        conversationId,
        (chunk: string) => {
          fullContent += chunk;
          updateLastMessage({ content: fullContent });
          onChunk?.(chunk);
        }
      );
      
    } catch (err) {
      const error = err as Error;
      setError(error);
      onError?.(error);
      updateLastMessage({ 
        content: '抱歉，消息发送失败，请重试。',
        metadata: { error: error.message }
      });
    } finally {
      setIsLoading(false);
    }
  }, [isLoading, conversationId, addMessage, updateLastMessage, onError]);

  // 清空聊天历史
  const clearHistory = useCallback(async (): Promise<void> => {
    try {
      await aiServices.chat.clearHistory(conversationId);
      setMessages([]);
      message.success('聊天记录已清空');
    } catch (err) {
      const error = err as Error;
      setError(error);
      message.error('清空聊天记录失败');
      throw error;
    }
  }, [conversationId]);

  // 加载聊天历史
  const loadHistory = useCallback(async (): Promise<void> => {
    try {
      setIsLoading(true);
      const history = await aiServices.chat.getHistory(conversationId);
      setMessages(history);
    } catch (err) {
      const error = err as Error;
      setError(error);
      message.error('加载聊天记录失败');
    } finally {
      setIsLoading(false);
    }
  }, [conversationId]);

  return {
    // 状态
    messages,
    isLoading,
    error,
    
    // 方法
    sendMessage: enableStream ? 
      (content: string) => sendMessageStream(content) : 
      sendMessage,
    sendMessageStream,
    clearHistory,
    loadHistory,
    
    // 工具方法
    resetError,
    getLastMessage,
  };
};