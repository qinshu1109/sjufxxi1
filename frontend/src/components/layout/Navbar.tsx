import {
  BellOutlined,
  GlobalOutlined,
  LogoutOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  MoonOutlined,
  QuestionCircleOutlined,
  SettingOutlined,
  SunOutlined,
  UserOutlined,
} from '@ant-design/icons';
import {
  Avatar,
  Badge,
  Button,
  Divider,
  Dropdown,
  Tooltip,
  Typography,
} from 'antd';
import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

// Hooks
import { useI18n } from '@/hooks/useI18n';
import { useAuthStore } from '@/stores/authStore';
import { useThemeStore } from '@/stores/themeStore';

const { Text } = Typography;

interface NavbarProps {
  collapsed: boolean;
  onToggle: () => void;
}

const Navbar = ({ collapsed, onToggle }: NavbarProps) => {
  const navigate = useNavigate();
  const location = useLocation();
  const { isDark, toggleTheme } = useThemeStore();
  const { user, logout } = useAuthStore();
  const { changeLanguage, t } = useI18n();
  const [notificationCount] = useState(3); // 模拟通知数量

  // 用户菜单
  const userMenuItems = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: t('个人资料'),
      onClick: () => navigate('/profile'),
    },
    {
      key: 'settings',
      icon: <SettingOutlined />,
      label: t('账户设置'),
      onClick: () => navigate('/settings'),
    },
    {
      type: 'divider' as const,
    },
    {
      key: 'help',
      icon: <QuestionCircleOutlined />,
      label: t('帮助中心'),
      onClick: () => window.open('/help', '_blank'),
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: t('退出登录'),
      onClick: () => {
        logout();
        navigate('/auth/login');
      },
    },
  ];

  // 语言切换菜单
  const languageMenuItems = [
    {
      key: 'zh',
      label: '简体中文',
      onClick: () => changeLanguage('zh'),
    },
    {
      key: 'en',
      label: 'English',
      onClick: () => changeLanguage('en'),
    },
  ];

  // 通知菜单
  const notificationMenuItems = [
    {
      key: 'notification-1',
      label: (
        <div className="py-2">
          <Text strong>系统更新</Text>
          <br />
          <Text type="secondary" className="text-xs">
            DB-GPT AWEL 功能已上线
          </Text>
        </div>
      ),
    },
    {
      key: 'notification-2',
      label: (
        <div className="py-2">
          <Text strong>数据同步完成</Text>
          <br />
          <Text type="secondary" className="text-xs">
            抖音数据已更新至最新
          </Text>
        </div>
      ),
    },
    {
      key: 'notification-3',
      label: (
        <div className="py-2">
          <Text strong>报表生成完成</Text>
          <br />
          <Text type="secondary" className="text-xs">
            月度分析报告已生成
          </Text>
        </div>
      ),
    },
    {
      type: 'divider' as const,
    },
    {
      key: 'view-all',
      label: (
        <div className="text-center py-1">
          <Text type="secondary">查看全部通知</Text>
        </div>
      ),
      onClick: () => navigate('/notifications'),
    },
  ];

  // 判断是否为AI页面
  const isAIPage = location.pathname.startsWith('/ai/');

  return (
    <div className="flex items-center justify-between h-16 px-6 bg-bg-card border-b border-border-primary">
      {/* 左侧：Logo + 菜单切换 */}
      <div className="flex items-center space-x-4">
        {/* 菜单切换按钮 - AI页面时隐藏 */}
        {!isAIPage && (
          <Button
            type="text"
            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={onToggle}
            className="flex items-center justify-center w-8 h-8"
          />
        )}

        {/* Logo */}
        <div
          className="flex items-center space-x-3 cursor-pointer"
          onClick={() => navigate('/')}
        >
          <div className="w-8 h-8 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-sm">DY</span>
          </div>
          <div className="hidden md:block">
            <Text strong className="text-lg text-gradient">
              抖音数据分析平台
            </Text>
          </div>
        </div>

        {/* AI页面标识 */}
        {isAIPage && (
          <div className="flex items-center space-x-2 px-3 py-1 bg-primary-50 dark:bg-primary-900 rounded-full">
            <div className="w-2 h-2 bg-primary-500 rounded-full animate-pulse"></div>
            <Text className="text-primary-600 dark:text-primary-400 text-sm font-medium">
              AI 助手
            </Text>
          </div>
        )}
      </div>

      {/* 右侧：功能按钮 + 用户信息 */}
      <div className="flex items-center space-x-2">
        {/* 主题切换 */}
        <Tooltip title={isDark ? '切换到亮色主题' : '切换到暗色主题'}>
          <Button
            type="text"
            icon={isDark ? <SunOutlined /> : <MoonOutlined />}
            onClick={toggleTheme}
            className="flex items-center justify-center w-8 h-8"
          />
        </Tooltip>

        {/* 语言切换 */}
        <Dropdown
          menu={{ items: languageMenuItems }}
          placement="bottomRight"
          trigger={['click']}
        >
          <Button
            type="text"
            icon={<GlobalOutlined />}
            className="flex items-center justify-center w-8 h-8"
          />
        </Dropdown>

        {/* 通知 */}
        <Dropdown
          menu={{ items: notificationMenuItems }}
          placement="bottomRight"
          trigger={['click']}
          overlayStyle={{ width: 300 }}
        >
          <Button
            type="text"
            className="flex items-center justify-center w-8 h-8"
          >
            <Badge count={notificationCount} size="small">
              <BellOutlined />
            </Badge>
          </Button>
        </Dropdown>

        <Divider type="vertical" className="h-6" />

        {/* 用户信息 */}
        <Dropdown
          menu={{ items: userMenuItems }}
          placement="bottomRight"
          trigger={['click']}
        >
          <div className="flex items-center space-x-2 cursor-pointer hover:bg-bg-hover rounded-lg px-2 py-1 transition-colors">
            <Avatar
              size="small"
              src={user?.avatar}
              icon={<UserOutlined />}
              className="bg-primary-500"
            />
            <div className="hidden md:block">
              <Text className="text-sm font-medium">
                {user?.name || '用户'}
              </Text>
            </div>
          </div>
        </Dropdown>
      </div>
    </div>
  );
};

export default Navbar;
