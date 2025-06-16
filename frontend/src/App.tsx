import { RouterProvider } from 'react-router-dom';
import { ConfigProvider, App as AntdApp, theme } from 'antd';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import zhCN from 'antd/locale/zh_CN';
import enUS from 'antd/locale/en_US';
import { useEffect } from 'react';

// 样式导入
import '@/styles/theme.css';
import 'antd/dist/reset.css';
import '@/styles/theme-overrides.css';

// 路由
import { router } from '@/router';

// Hooks
import { useThemeStore } from '@/stores/themeStore';
import { useI18n } from '@/hooks/useI18n';

// 主题配置
import { getAntdTheme, themeManager } from '@/config/theme.config';

// 创建 React Query 客户端
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 5 * 60 * 1000, // 5 分钟
    },
  },
});

function App() {
  const { isDark } = useThemeStore();
  const { language } = useI18n();

  // 应用主题
  useEffect(() => {
    themeManager.setTheme(isDark);
  }, [isDark]);

  // 创建 Ant Design 主题配置
  const antdTheme = {
    algorithm: isDark ? theme.darkAlgorithm : theme.defaultAlgorithm,
    ...getAntdTheme(isDark),
  };

  return (
    <QueryClientProvider client={queryClient}>
      <ConfigProvider
        theme={antdTheme}
        locale={language === 'zh' ? zhCN : enUS}
        componentSize="middle"
      >
        <AntdApp>
          <div className="app-container">
            <RouterProvider router={router} />
          </div>
        </AntdApp>
      </ConfigProvider>
    </QueryClientProvider>
  );
}

export default App;
