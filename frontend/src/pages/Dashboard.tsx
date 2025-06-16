import {
  ArrowDownOutlined,
  ArrowUpOutlined,
  DollarOutlined,
  EyeOutlined,
  RiseOutlined,
  UserOutlined,
} from '@ant-design/icons';
import { Button, Card, Col, Row, Statistic, Typography } from 'antd';

const { Title, Text } = Typography;

const Dashboard = () => {
  // 模拟数据
  const stats = [
    {
      title: '总用户数',
      value: 1234567,
      prefix: <UserOutlined />,
      suffix: '人',
      precision: 0,
      trend: 'up',
      trendValue: 12.5,
    },
    {
      title: '活跃用户',
      value: 987654,
      prefix: <EyeOutlined />,
      suffix: '人',
      precision: 0,
      trend: 'up',
      trendValue: 8.3,
    },
    {
      title: '总收入',
      value: 12345678.9,
      prefix: <DollarOutlined />,
      suffix: '元',
      precision: 2,
      trend: 'up',
      trendValue: 15.2,
    },
    {
      title: '增长率',
      value: 23.45,
      prefix: <RiseOutlined />,
      suffix: '%',
      precision: 2,
      trend: 'down',
      trendValue: 2.1,
    },
  ];

  const quickActions = [
    { title: 'AI 对话', description: '与AI助手进行智能对话', path: '/ai/chat' },
    { title: 'SQL 查询', description: '在SQL实验室中查询数据', path: '/ai/sql-lab' },
    { title: '数据分析', description: '查看详细的数据分析报告', path: '/analytics' },
    { title: '生成报表', description: '创建和管理数据报表', path: '/reports' },
  ];

  return (
    <div className="space-y-6">
      {/* 页面标题 */}
      <div className="flex items-center justify-between">
        <div>
          <Title level={2} className="mb-2">
            数据概览
          </Title>
          <Text className="text-text-secondary">
            欢迎回来！这里是您的数据分析仪表板
          </Text>
        </div>
        <Button type="primary" size="large">
          刷新数据
        </Button>
      </div>

      {/* 统计卡片 */}
      <Row gutter={[16, 16]}>
        {stats.map((stat, index) => (
          <Col xs={24} sm={12} lg={6} key={index}>
            <Card>
              <Statistic
                title={stat.title}
                value={stat.value}
                precision={stat.precision}
                prefix={stat.prefix}
                suffix={stat.suffix}
                valueStyle={{ color: '#3f8600' }}
              />
              <div className="mt-2 flex items-center">
                {stat.trend === 'up' ? (
                  <ArrowUpOutlined className="text-green-500 mr-1" />
                ) : (
                  <ArrowDownOutlined className="text-red-500 mr-1" />
                )}
                <Text
                  className={`text-sm ${stat.trend === 'up' ? 'text-green-500' : 'text-red-500'
                    }`}
                >
                  {stat.trendValue}%
                </Text>
                <Text className="text-text-muted text-sm ml-1">
                  较上周
                </Text>
              </div>
            </Card>
          </Col>
        ))}
      </Row>

      {/* 快捷操作 */}
      <Card title="快捷操作" className="mt-6">
        <Row gutter={[16, 16]}>
          {quickActions.map((action, index) => (
            <Col xs={24} sm={12} lg={6} key={index}>
              <Card
                hoverable
                className="h-full cursor-pointer transition-all duration-200 hover:shadow-md"
                onClick={() => window.location.href = action.path}
              >
                <div className="text-center">
                  <Title level={4} className="mb-2">
                    {action.title}
                  </Title>
                  <Text className="text-text-secondary">
                    {action.description}
                  </Text>
                </div>
              </Card>
            </Col>
          ))}
        </Row>
      </Card>

      {/* 最近活动 */}
      <Card title="最近活动">
        <div className="space-y-4">
          {[
            { time: '2 分钟前', action: '用户张三执行了SQL查询', type: 'sql' },
            { time: '5 分钟前', action: '生成了月度数据报表', type: 'report' },
            { time: '10 分钟前', action: 'AI助手回答了用户问题', type: 'ai' },
            { time: '15 分钟前', action: '数据同步任务完成', type: 'sync' },
          ].map((activity, index) => (
            <div key={index} className="flex items-center justify-between py-2 border-b border-border-primary last:border-b-0">
              <div>
                <Text>{activity.action}</Text>
              </div>
              <Text className="text-text-muted text-sm">
                {activity.time}
              </Text>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
};

export default Dashboard;
