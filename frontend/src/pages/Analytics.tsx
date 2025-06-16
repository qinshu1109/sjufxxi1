import { Card, Typography } from 'antd';

const { Title, Text } = Typography;

const Analytics = () => {
  return (
    <div className="space-y-6">
      <div>
        <Title level={2} className="mb-2">
          数据分析
        </Title>
        <Text className="text-text-secondary">深入分析抖音数据，发现业务洞察</Text>
      </div>

      <Card>
        <div className="py-12 text-center">
          <Title level={3} className="text-text-muted">
            数据分析功能开发中...
          </Title>
          <Text className="text-text-secondary">即将为您提供强大的数据分析能力</Text>
        </div>
      </Card>
    </div>
  );
};

export default Analytics;
