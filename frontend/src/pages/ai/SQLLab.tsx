import { HistoryOutlined, PlayCircleOutlined, SaveOutlined } from '@ant-design/icons';
import { Button, Card, Space, Table, Tabs, Typography } from 'antd';
import { useState } from 'react';

// 这里将来会替换为实际的 DB-GPT SQL Lab 组件
// import { SQLLab } from '@dbgpt/react';

const { Title, Text } = Typography;
const { TabPane } = Tabs;

const SQLLab = () => {
  const [sqlQuery, setSqlQuery] = useState(`-- 示例查询：获取抖音用户数据
SELECT 
  user_id,
  username,
  follower_count,
  video_count,
  total_likes
FROM douyin_users 
WHERE follower_count > 10000
ORDER BY follower_count DESC
LIMIT 10;`);

  const [queryResults] = useState([
    {
      key: '1',
      user_id: 'user_001',
      username: '数据分析师小王',
      follower_count: 150000,
      video_count: 89,
      total_likes: 2500000,
    },
    {
      key: '2',
      user_id: 'user_002',
      username: '科技达人',
      follower_count: 120000,
      video_count: 156,
      total_likes: 1800000,
    },
  ]);

  const columns = [
    {
      title: '用户ID',
      dataIndex: 'user_id',
      key: 'user_id',
    },
    {
      title: '用户名',
      dataIndex: 'username',
      key: 'username',
    },
    {
      title: '粉丝数',
      dataIndex: 'follower_count',
      key: 'follower_count',
      render: (value: number) => value.toLocaleString(),
    },
    {
      title: '视频数',
      dataIndex: 'video_count',
      key: 'video_count',
    },
    {
      title: '总点赞数',
      dataIndex: 'total_likes',
      key: 'total_likes',
      render: (value: number) => value.toLocaleString(),
    },
  ];

  const handleRunQuery = () => {
    // 模拟查询执行
    console.log('执行查询:', sqlQuery);
  };

  const handleSaveQuery = () => {
    // 模拟保存查询
    console.log('保存查询:', sqlQuery);
  };

  return (
    <div className="flex h-full flex-col bg-bg-primary">
      {/* 顶部工具栏 */}
      <div className="flex items-center justify-between border-b border-border-primary bg-bg-card p-4">
        <div>
          <Title level={4} className="mb-0">
            SQL 实验室
          </Title>
          <Text className="text-sm text-text-secondary">编写和执行 SQL 查询，分析抖音数据</Text>
        </div>

        <Space>
          <Button type="primary" icon={<PlayCircleOutlined />} onClick={handleRunQuery}>
            执行查询
          </Button>
          <Button icon={<SaveOutlined />} onClick={handleSaveQuery}>
            保存查询
          </Button>
          <Button icon={<HistoryOutlined />}>查询历史</Button>
        </Space>
      </div>

      {/* 主要内容区域 */}
      <div className="flex flex-1">
        {/* 左侧：SQL 编辑器 */}
        <div className="w-1/2 border-r border-border-primary">
          <div className="p-4">
            <Text strong className="mb-2 block">
              SQL 查询编辑器
            </Text>
            <textarea
              value={sqlQuery}
              onChange={(e) => setSqlQuery(e.target.value)}
              className="h-96 w-full resize-none rounded-lg border border-border-primary p-3 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
              placeholder="在此输入您的 SQL 查询..."
            />
          </div>
        </div>

        {/* 右侧：结果和工具 */}
        <div className="flex w-1/2 flex-col">
          <Tabs defaultActiveKey="results" className="flex-1">
            <TabPane tab="查询结果" key="results">
              <div className="p-4">
                <Table
                  columns={columns}
                  dataSource={queryResults}
                  size="small"
                  pagination={{ pageSize: 10 }}
                  scroll={{ y: 300 }}
                />
              </div>
            </TabPane>

            <TabPane tab="执行计划" key="plan">
              <div className="p-4">
                <Card size="small">
                  <Text className="text-text-secondary">查询执行计划将在此显示...</Text>
                </Card>
              </div>
            </TabPane>

            <TabPane tab="查询历史" key="history">
              <div className="p-4">
                <div className="space-y-2">
                  {[
                    'SELECT * FROM douyin_users LIMIT 10',
                    'SELECT COUNT(*) FROM douyin_videos',
                    'SELECT user_id, SUM(likes) FROM douyin_videos GROUP BY user_id',
                  ].map((query, index) => (
                    <Card
                      key={index}
                      size="small"
                      hoverable
                      className="cursor-pointer"
                      onClick={() => setSqlQuery(query)}
                    >
                      <Text className="font-mono text-sm">{query}</Text>
                    </Card>
                  ))}
                </div>
              </div>
            </TabPane>
          </Tabs>
        </div>
      </div>

      {/* 底部状态栏 */}
      <div className="border-t border-border-primary bg-bg-secondary p-2">
        <div className="flex items-center justify-between text-sm text-text-secondary">
          <div>
            <Text className="text-xs">
              连接状态: <span className="text-green-500">已连接</span> | 数据库:{' '}
              <span className="text-primary-500">analytics</span>
            </Text>
          </div>
          <div>
            <Text className="text-xs">行数: {queryResults.length} | 执行时间: 0.05s</Text>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SQLLab;
