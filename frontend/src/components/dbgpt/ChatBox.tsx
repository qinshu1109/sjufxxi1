import { ReloadOutlined } from '@ant-design/icons';
import { Alert, Button, Spin } from 'antd';
import { useEffect, useRef, useState } from 'react';

interface ChatBoxProps {
  className?: string;
  style?: React.CSSProperties;
  apiBaseUrl?: string;
  theme?: 'light' | 'dark';
  onError?: (error: Error) => void;
  onReady?: () => void;
}

/**
 * DB-GPT ChatBox 组件包装器
 * 这个组件将在 DB-GPT 构建完成后替换为实际的 DB-GPT React 组件
 *
 * 使用方式:
 * import { ChatBox } from '@/components/dbgpt/ChatBox';
 * <ChatBox theme="light" apiBaseUrl="/api/ai" />
 */
const ChatBox = ({
  className = '',
  style = {},
  apiBaseUrl = '/api/ai',
  theme = 'light',
  onError,
  onReady,
}: ChatBoxProps) => {
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [retryCount, setRetryCount] = useState(0);

  // 检查 DB-GPT 构建产物是否存在
  const checkDBGPTAvailability = async () => {
    try {
      const response = await fetch('/ai/dbgpt-config.json');
      if (response.ok) {
        const config = await response.json();
        console.log('DB-GPT 配置加载成功:', config);
        return true;
      }
      return false;
    } catch (error) {
      console.warn('DB-GPT 构建产物未找到，使用模拟组件');
      return false;
    }
  };

  // 初始化 DB-GPT 组件
  useEffect(() => {
    const initializeDBGPT = async () => {
      setLoading(true);
      setError(null);

      try {
        const isAvailable = await checkDBGPTAvailability();

        if (isAvailable) {
          // DB-GPT 构建产物存在，加载实际组件
          loadDBGPTComponent();
        } else {
          // 使用模拟组件
          loadMockComponent();
        }
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : '未知错误';
        setError(errorMessage);
        onError?.(err instanceof Error ? err : new Error(errorMessage));
      }
    };

    initializeDBGPT();
  }, [retryCount]);

  // 加载实际的 DB-GPT 组件
  const loadDBGPTComponent = () => {
    if (!iframeRef.current) return;

    const iframe = iframeRef.current;

    // 设置 iframe 源
    iframe.src = `/ai/?theme=${theme}&apiBaseUrl=${encodeURIComponent(apiBaseUrl)}`;

    // 监听 iframe 加载事件
    iframe.onload = () => {
      setLoading(false);
      onReady?.();

      // 设置 iframe 样式以适应主站主题
      try {
        const iframeDoc = iframe.contentDocument || iframe.contentWindow?.document;
        if (iframeDoc) {
          // 注入主站主题样式
          const style = iframeDoc.createElement('style');
          style.textContent = `
            body {
              margin: 0;
              padding: 0;
              background: transparent;
            }
            .ant-layout {
              background: transparent;
            }
          `;
          iframeDoc.head.appendChild(style);
        }
      } catch (error) {
        console.warn('无法访问 iframe 内容，可能存在跨域限制');
      }
    };

    iframe.onerror = () => {
      setError('DB-GPT 组件加载失败');
      setLoading(false);
    };
  };

  // 加载模拟组件
  const loadMockComponent = () => {
    // 模拟加载时间
    setTimeout(() => {
      setLoading(false);
      onReady?.();
    }, 1000);
  };

  // 重试加载
  const handleRetry = () => {
    setRetryCount((prev) => prev + 1);
  };

  // 渲染加载状态
  if (loading) {
    return (
      <div
        className={`flex h-full min-h-96 items-center justify-center ${className}`}
        style={style}
      >
        <div className="text-center">
          <Spin size="large" />
          <div className="mt-4 text-text-secondary">正在加载 AI 聊天组件...</div>
        </div>
      </div>
    );
  }

  // 渲染错误状态
  if (error) {
    return (
      <div
        className={`flex h-full min-h-96 items-center justify-center ${className}`}
        style={style}
      >
        <Alert
          message="组件加载失败"
          description={error}
          type="error"
          showIcon
          action={
            <Button size="small" icon={<ReloadOutlined />} onClick={handleRetry}>
              重试
            </Button>
          }
        />
      </div>
    );
  }

  // 渲染 DB-GPT 组件
  return (
    <div className={`relative h-full ${className}`} style={style}>
      {/* 实际的 DB-GPT iframe 或模拟组件 */}
      <iframe
        ref={iframeRef}
        className="h-full w-full border-0"
        title="DB-GPT Chat Interface"
        sandbox="allow-scripts allow-same-origin allow-forms"
        style={{
          minHeight: '500px',
          background: 'transparent',
        }}
      />

      {/* 开发提示 */}
      {import.meta.env.DEV && (
        <div className="absolute right-2 top-2 z-10">
          <div className="rounded bg-blue-500 px-2 py-1 text-xs text-white">DB-GPT Mock</div>
        </div>
      )}
    </div>
  );
};

export default ChatBox;
