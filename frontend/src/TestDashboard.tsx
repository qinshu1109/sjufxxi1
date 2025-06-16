import { Card, Statistic, Row, Col } from 'antd';
import { UserOutlined } from '@ant-design/icons';

const TestDashboard = () => {
  return (
    <div style={{ padding: '24px' }}>
      <h1>测试Dashboard - 简化版</h1>
      <Row gutter={16}>
        <Col span={6}>
          <Card>
            <Statistic
              title="总用户数"
              value={1234567}
              prefix={<UserOutlined />}
              suffix="人"
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card>
            <Statistic
              title="活跃用户"
              value={987654}
              prefix={<UserOutlined />}
              suffix="人"
            />
          </Card>
        </Col>
      </Row>
      
      <Card style={{ marginTop: '16px' }}>
        <h2>快捷操作</h2>
        <p>如果你能看到这个文本，说明React渲染正常。</p>
      </Card>
    </div>
  );
};

export default TestDashboard;