import { useState } from 'react';
import { Button, Space, Typography, Avatar, Switch, Card } from 'antd';
import {
  RobotOutlined,
  SettingOutlined,
} from '@ant-design/icons';

// DB-GPT 组件
import { ChatBox } from '@/components/dbgpt';

// Hooks
import { useThemeStore } from '@/stores/themeStore';

const { Text, Title } = Typography;

const Chat = () => {
  const { isDark } = useThemeStore();
  const [showSettings, setShowSettings] = useState(false);

  const handleChatError = (error: Error) => {
    console.error('ChatBox 错误:', error);
  };

  const handleChatReady = () => {
    console.log('ChatBox 已准备就绪');
  };

  return (
    <div className="h-full flex flex-col bg-bg-primary">
      {/* 顶部工具栏 */}
      <div className="flex items-center justify-between p-4 border-b border-border-primary bg-bg-card">
        <div className="flex items-center space-x-3">
          <Avatar icon={<RobotOutlined />} className="bg-primary-500" />
          <div>
            <Title level={4} className="mb-0">
              AI 智能对话
            </Title>
            <Text className="text-text-secondary text-sm">
              与AI助手进行智能数据分析对话
            </Text>
          </div>
        </div>
        
        <Space>
          <Button 
            icon={<SettingOutlined />} 
            onClick={() => setShowSettings(!showSettings)}
          >
            设置
          </Button>
        </Space>
      </div>

      {/* 设置面板 */}
      {showSettings && (
        <div className="p-4 border-b border-border-primary bg-bg-secondary">
          <Card size="small" title="聊天设置">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <Text>主题模式</Text>
                <Switch 
                  checked={isDark} 
                  checkedChildren="暗色" 
                  unCheckedChildren="亮色"
                  onChange={() => {/* 主题切换逻辑 */}}
                />
              </div>
              <div className="flex items-center justify-between">
                <Text>智能建议</Text>
                <Switch defaultChecked />
              </div>
              <div className="flex items-center justify-between">
                <Text>语音输入</Text>
                <Switch />
              </div>
            </div>
          </Card>
        </div>
      )}

      {/* DB-GPT ChatBox 组件 */}
      <div className="flex-1 relative">
        <ChatBox
          className="h-full"
          theme={isDark ? 'dark' : 'light'}
          apiBaseUrl="/api/ai"
          onError={handleChatError}
          onReady={handleChatReady}
        />
      </div>
    </div>
  );
};

export default Chat;
