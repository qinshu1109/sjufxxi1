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
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-2xl mb-4">
              <span className="text-white font-bold text-2xl">DY</span>
            </div>
            <Title level={2} className="mb-2 text-gradient">
              抖音数据分析平台
            </Title>
            <Text className="text-text-secondary">
              智能数据分析与AI助手
            </Text>
          </div>

          {/* 认证表单 */}
          <div 
            className="bg-bg-card rounded-2xl shadow-lg p-8 border border-border-primary"
            style={{
              background: isDark ? '#1f2937' : '#ffffff',
            }}
          >
            <Outlet />
          </div>

          {/* 底部信息 */}
          <div className="text-center mt-8">
            <Space split={<span className="text-text-muted">•</span>}>
              <Text className="text-text-muted text-sm">隐私政策</Text>
              <Text className="text-text-muted text-sm">服务条款</Text>
              <Text className="text-text-muted text-sm">帮助中心</Text>
            </Space>
            <div className="mt-4">
              <Text className="text-text-muted text-xs">
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
