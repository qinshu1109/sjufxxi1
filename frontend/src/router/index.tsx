import { Spin } from 'antd';
import { lazy, Suspense } from 'react';
import { createBrowserRouter, Navigate } from 'react-router-dom';

// 权限守卫组件

// 布局组件
import AuthLayout from '@/components/layout/AuthLayout';
import MainLayout from '@/components/layout/MainLayout';

// 加载中组件
const PageLoading = () => (
  <div className="flex min-h-screen items-center justify-center">
    <Spin size="large" tip="加载中..." />
  </div>
);

// 懒加载组件包装器
const LazyWrapper = ({ children }: { children: React.ReactNode }) => (
  <Suspense fallback={<PageLoading />}>{children}</Suspense>
);

// 懒加载页面组件
const Dashboard = lazy(() => import('@/pages/Dashboard'));
const TestDashboard = lazy(() => import('@/TestDashboard'));
const Analytics = lazy(() => import('@/pages/Analytics'));
const Reports = lazy(() => import('@/pages/Reports'));
const Settings = lazy(() => import('@/pages/Settings'));

// AI 相关页面 - 懒加载 DB-GPT 组件
const AIChat = lazy(() => import('@/pages/ai/Chat'));
const SQLLab = lazy(() => import('@/pages/ai/SQLLab'));
const DataVisualization = lazy(() => import('@/pages/ai/DataVisualization'));
const WorkflowBuilder = lazy(() => import('@/pages/ai/WorkflowBuilder'));

// 认证页面
const Login = lazy(() => import('@/pages/auth/Login'));
const Register = lazy(() => import('@/pages/auth/Register'));

// 错误页面
const NotFound = lazy(() => import('@/pages/errors/NotFound'));
const ServerError = lazy(() => import('@/pages/errors/ServerError'));

// 路由配置
export const router = createBrowserRouter([
  {
    path: '/',
    element: <MainLayout />,
    children: [
      {
        index: true,
        element: <Navigate to="/dashboard" replace />,
      },
      {
        path: 'dashboard',
        element: (
          <LazyWrapper>
            <Dashboard />
          </LazyWrapper>
        ),
      },
      {
        path: 'test-dashboard',
        element: (
          <LazyWrapper>
            <TestDashboard />
          </LazyWrapper>
        ),
      },
      {
        path: 'analytics',
        element: (
          <LazyWrapper>
            <Analytics />
          </LazyWrapper>
        ),
      },
      {
        path: 'reports',
        element: (
          <LazyWrapper>
            <Reports />
          </LazyWrapper>
        ),
      },
      {
        path: 'settings',
        element: (
          <LazyWrapper>
            <Settings />
          </LazyWrapper>
        ),
      },
      // AI 功能路由组 - 按照清单要求
      {
        path: 'ai',
        children: [
          {
            index: true,
            element: <Navigate to="/ai/chat" replace />,
          },
          {
            path: 'chat',
            element: (
              <LazyWrapper>
                <AIChat />
              </LazyWrapper>
            ),
          },
          {
            path: 'sql-lab',
            element: (
              <LazyWrapper>
                <SQLLab />
              </LazyWrapper>
            ),
          },
          {
            path: 'visualization',
            element: (
              <LazyWrapper>
                <DataVisualization />
              </LazyWrapper>
            ),
          },
          {
            path: 'workflow',
            element: (
              <LazyWrapper>
                <WorkflowBuilder />
              </LazyWrapper>
            ),
          },
        ],
      },
    ],
  },
  // 认证路由
  {
    path: '/auth',
    element: <AuthLayout />,
    children: [
      {
        index: true,
        element: <Navigate to="/auth/login" replace />,
      },
      {
        path: 'login',
        element: (
          <LazyWrapper>
            <Login />
          </LazyWrapper>
        ),
      },
      {
        path: 'register',
        element: (
          <LazyWrapper>
            <Register />
          </LazyWrapper>
        ),
      },
    ],
  },
  // 错误页面
  {
    path: '/404',
    element: (
      <LazyWrapper>
        <NotFound />
      </LazyWrapper>
    ),
  },
  {
    path: '/500',
    element: (
      <LazyWrapper>
        <ServerError />
      </LazyWrapper>
    ),
  },
  // 捕获所有未匹配的路由
  {
    path: '*',
    element: <Navigate to="/404" replace />,
  },
]);

// 路由权限配置
export const routePermissions = {
  '/dashboard': ['user', 'admin'],
  '/analytics': ['user', 'admin'],
  '/reports': ['user', 'admin'],
  '/settings': ['admin'],
  '/ai/chat': ['user', 'admin'],
  '/ai/sql-lab': ['user', 'admin'],
  '/ai/visualization': ['user', 'admin'],
  '/ai/workflow': ['admin'],
} as const;

// 路由元信息
export const routeMeta = {
  '/dashboard': {
    title: '仪表板',
    icon: 'DashboardOutlined',
    breadcrumb: ['首页', '仪表板'],
  },
  '/analytics': {
    title: '数据分析',
    icon: 'BarChartOutlined',
    breadcrumb: ['首页', '数据分析'],
  },
  '/reports': {
    title: '报表中心',
    icon: 'FileTextOutlined',
    breadcrumb: ['首页', '报表中心'],
  },
  '/settings': {
    title: '系统设置',
    icon: 'SettingOutlined',
    breadcrumb: ['首页', '系统设置'],
  },
  '/ai/chat': {
    title: 'AI 对话',
    icon: 'MessageOutlined',
    breadcrumb: ['首页', 'AI 助手', 'AI 对话'],
  },
  '/ai/sql-lab': {
    title: 'SQL 实验室',
    icon: 'CodeOutlined',
    breadcrumb: ['首页', 'AI 助手', 'SQL 实验室'],
  },
  '/ai/visualization': {
    title: '数据可视化',
    icon: 'PieChartOutlined',
    breadcrumb: ['首页', 'AI 助手', '数据可视化'],
  },
  '/ai/workflow': {
    title: '工作流构建器',
    icon: 'NodeIndexOutlined',
    breadcrumb: ['首页', 'AI 助手', '工作流构建器'],
  },
} as const;

export default router;
