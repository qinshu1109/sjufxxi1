import { RouterProvider } from 'react-router-dom';
import { ConfigProvider, App as AntdApp, theme } from 'antd';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import zhCN from 'antd/locale/zh_CN';
import enUS from 'antd/locale/en_US';

// 样式导入
import '@/styles/theme.css';
import 'antd/dist/reset.css';

// 路由
import { router } from '@/router';

// Hooks
import { useThemeStore } from '@/stores/themeStore';
import { useI18n } from '@/hooks/useI18n';

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

// Ant Design 主题配置
const getAntdTheme = (isDark: boolean) => ({
  algorithm: isDark ? theme.darkAlgorithm : theme.defaultAlgorithm,
  token: {
    // 主色调 - 映射 CSS 变量
    colorPrimary: '#ef4444',
    colorSuccess: '#22c55e',
    colorWarning: '#f59e0b',
    colorError: '#ef4444',
    colorInfo: '#3b82f6',
    
    // 背景色
    colorBgBase: isDark ? '#111827' : '#ffffff',
    colorBgContainer: isDark ? '#1f2937' : '#ffffff',
    colorBgElevated: isDark ? '#1f2937' : '#ffffff',
    colorBgLayout: isDark ? '#111827' : '#f9fafb',
    
    // 文本色
    colorText: isDark ? '#f9fafb' : '#111827',
    colorTextSecondary: isDark ? '#d1d5db' : '#4b5563',
    colorTextTertiary: isDark ? '#9ca3af' : '#6b7280',
    colorTextQuaternary: isDark ? '#6b7280' : '#9ca3af',
    
    // 边框色
    colorBorder: isDark ? '#374151' : '#e5e7eb',
    colorBorderSecondary: isDark ? '#4b5563' : '#d1d5db',
    
    // 圆角
    borderRadius: 8,
    borderRadiusLG: 12,
    borderRadiusSM: 6,
    
    // 字体
    fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    fontSize: 14,
    fontSizeLG: 16,
    fontSizeSM: 12,
    
    // 间距
    padding: 16,
    paddingLG: 24,
    paddingSM: 12,
    paddingXS: 8,
    
    // 阴影
    boxShadow: isDark 
      ? '0 4px 6px -1px rgba(0, 0, 0, 0.4), 0 2px 4px -1px rgba(0, 0, 0, 0.3)'
      : '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
    boxShadowSecondary: isDark
      ? '0 2px 4px -1px rgba(0, 0, 0, 0.3)'
      : '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
  },
  components: {
    // Button 组件定制
    Button: {
      borderRadius: 8,
      controlHeight: 40,
      controlHeightSM: 32,
      controlHeightLG: 48,
    },
    // Input 组件定制
    Input: {
      borderRadius: 8,
      controlHeight: 40,
      controlHeightSM: 32,
      controlHeightLG: 48,
    },
    // Card 组件定制
    Card: {
      borderRadius: 12,
      paddingLG: 24,
    },
    // Menu 组件定制
    Menu: {
      borderRadius: 8,
      itemBorderRadius: 6,
    },
    // Table 组件定制
    Table: {
      borderRadius: 8,
      headerBg: isDark ? '#1f2937' : '#f9fafb',
    },
    // Modal 组件定制
    Modal: {
      borderRadius: 12,
    },
    // Drawer 组件定制
    Drawer: {
      borderRadius: 12,
    },
  },
});

function App() {
  const { isDark } = useThemeStore();
  const { language } = useI18n();

  // 设置 HTML 主题属性
  document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
  document.documentElement.className = isDark ? 'dark' : '';

  return (
    <QueryClientProvider client={queryClient}>
      <ConfigProvider
        theme={getAntdTheme(isDark)}
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
