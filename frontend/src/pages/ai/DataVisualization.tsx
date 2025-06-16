import { Card, Typography } from 'antd';

const { Title, Text } = Typography;

const DataVisualization = () => {
  return (
    <div className="h-full flex flex-col bg-bg-primary">
      {/* 顶部工具栏 */}
      <div className="flex items-center justify-between p-4 border-b border-border-primary bg-bg-card">
        <div>
          <Title level={4} className="mb-0">
            数据可视化
          </Title>
          <Text className="text-text-secondary text-sm">
            创建交互式图表和仪表板
          </Text>
        </div>
      </div>

      {/* 主要内容区域 */}
      <div className="flex-1 p-6">
        <Card className="h-full">
          <div className="text-center py-12">
            <Title level={3} className="text-text-muted">
              数据可视化功能开发中...
            </Title>
            <Text className="text-text-secondary">
              即将为您提供强大的数据可视化能力
            </Text>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default DataVisualization;
