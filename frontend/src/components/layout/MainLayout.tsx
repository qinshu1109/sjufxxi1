import { useState } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { Layout, theme } from 'antd';

// 组件
import Navbar from './Navbar';
import Sidebar from './Sidebar';
import Breadcrumb from './Breadcrumb';
import Footer from './Footer';

// Hooks
import { useThemeStore } from '@/stores/themeStore';

const { Header, Sider, Content } = Layout;

const MainLayout = () => {
  const [collapsed, setCollapsed] = useState(false);
  const { isDark } = useThemeStore();
  const location = useLocation();

  const {
    token: { colorBgContainer, borderRadiusLG },
  } = theme.useToken();

  // 判断是否为全屏页面（如AI聊天页面）
  const isFullscreenPage = location.pathname.startsWith('/ai/');

  return (
    <Layout className="min-h-screen">
      {/* 顶部导航栏 */}
      <Header className="leading-16 fixed left-0 right-0 top-0 z-50 h-16 px-0">
        <Navbar collapsed={collapsed} onToggle={() => setCollapsed(!collapsed)} />
      </Header>

      <Layout className="mt-16">
        {/* 侧边栏 - 全屏页面时隐藏 */}
        {!isFullscreenPage && (
          <Sider
            trigger={null}
            collapsible
            collapsed={collapsed}
            width={240}
            collapsedWidth={80}
            className="fixed bottom-0 left-0 top-16 z-40 overflow-auto"
            style={{
              background: isDark ? '#1f2937' : '#ffffff',
            }}
          >
            <Sidebar collapsed={collapsed} />
          </Sider>
        )}

        {/* 主内容区域 */}
        <Layout
          className={`transition-all duration-300 ${
            isFullscreenPage ? 'ml-0' : collapsed ? 'ml-20' : 'ml-60'
          }`}
        >
          {/* 面包屑导航 - 全屏页面时隐藏 */}
          {!isFullscreenPage && (
            <div className="border-b border-border-primary bg-bg-secondary px-6 py-4">
              <Breadcrumb />
            </div>
          )}

          {/* 页面内容 */}
          <Content
            className={`${isFullscreenPage ? 'p-0' : 'p-6'} min-h-[calc(100vh-64px)]`}
            style={{
              background: isFullscreenPage ? colorBgContainer : isDark ? '#111827' : '#f9fafb',
            }}
          >
            <div
              className={`${isFullscreenPage ? 'h-full' : 'rounded-lg bg-bg-card shadow-sm'}`}
              style={{
                background: isFullscreenPage ? 'transparent' : colorBgContainer,
                borderRadius: isFullscreenPage ? 0 : borderRadiusLG,
                minHeight: isFullscreenPage ? '100%' : 'auto',
                padding: isFullscreenPage ? 0 : 24,
              }}
            >
              <Outlet />
            </div>
          </Content>

          {/* 底部 - 全屏页面时隐藏 */}
          {!isFullscreenPage && <Footer />}
        </Layout>
      </Layout>
    </Layout>
  );
};

export default MainLayout;
