import { Card, Typography } from 'antd';

const { Title, Text } = Typography;

const Settings = () => {
  return (
    <div className="space-y-6">
      <div>
        <Title level={2} className="mb-2">
          系统设置
        </Title>
        <Text className="text-text-secondary">
          配置系统参数和用户权限
        </Text>
      </div>

      <Card>
        <div className="text-center py-12">
          <Title level={3} className="text-text-muted">
            设置功能开发中...
          </Title>
          <Text className="text-text-secondary">
            即将为您提供完整的系统设置功能
          </Text>
        </div>
      </Card>
    </div>
  );
};

export default Settings;
