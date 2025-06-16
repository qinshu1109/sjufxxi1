import { Outlet } from 'react-router-dom';
import { Layout, Typography, Space } from 'antd';
import { useThemeStore } from '@/stores/themeStore';

const { Content } = Layout;
const { Title, Text } = Typography;

const AuthLayout = () => {
  const { isDark } = useThemeStore();

  return (
    <Layout className="min-h-screen">
      <Content className="flex items-center justify-center p-6">
        <div className="w-full max-w-md">
          {/* Logo 和标题 */}
          <div className="mb-8 text-center">
            <div className="mb-4 inline-flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-primary-500 to-secondary-500">
              <span className="text-2xl font-bold text-white">DY</span>
            </div>
            <Title level={2} className="text-gradient mb-2">
              抖音数据分析平台
            </Title>
            <Text className="text-text-secondary">智能数据分析与AI助手</Text>
          </div>

          {/* 认证表单 */}
          <div
            className="rounded-2xl border border-border-primary bg-bg-card p-8 shadow-lg"
            style={{
              background: isDark ? '#1f2937' : '#ffffff',
            }}
          >
            <Outlet />
          </div>

          {/* 底部信息 */}
          <div className="mt-8 text-center">
            <Space split={<span className="text-text-muted">•</span>}>
              <Text className="text-sm text-text-muted">隐私政策</Text>
              <Text className="text-sm text-text-muted">服务条款</Text>
              <Text className="text-sm text-text-muted">帮助中心</Text>
            </Space>
            <div className="mt-4">
              <Text className="text-xs text-text-muted">
                © 2025 抖音数据分析平台. All rights reserved.
              </Text>
            </div>
          </div>
        </div>
      </Content>
    </Layout>
  );
};

export default AuthLayout;
