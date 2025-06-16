import { Card, Typography } from 'antd';

const { Title, Text } = Typography;

const Reports = () => {
  return (
    <div className="space-y-6">
      <div>
        <Title level={2} className="mb-2">
          报表中心
        </Title>
        <Text className="text-text-secondary">
          创建和管理数据报表
        </Text>
      </div>

      <Card>
        <div className="text-center py-12">
          <Title level={3} className="text-text-muted">
            报表功能开发中...
          </Title>
          <Text className="text-text-secondary">
            即将为您提供丰富的报表功能
          </Text>
        </div>
      </Card>
    </div>
  );
};

export default Reports;
