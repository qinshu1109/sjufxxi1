import {
  BarChartOutlined,
  CodeOutlined,
  DashboardOutlined,
  FileTextOutlined,
  MessageOutlined,
  NodeIndexOutlined,
  PieChartOutlined,
  RobotOutlined,
  SettingOutlined,
} from '@ant-design/icons';
import { Menu, Typography } from 'antd';
import { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

// Hooks
import { useI18n } from '@/hooks/useI18n';
import { useAuthStore } from '@/stores/authStore';

const { Text } = Typography;

interface SidebarProps {
  collapsed: boolean;
}

const Sidebar = ({ collapsed }: SidebarProps) => {
  const navigate = useNavigate();
  const location = useLocation();
  const { canAccess } = useAuthStore();
  const { t } = useI18n();
  const [selectedKeys, setSelectedKeys] = useState<string[]>([]);
  const [openKeys, setOpenKeys] = useState<string[]>([]);

  // 菜单项配置
  const menuItems = [
    {
      key: '/dashboard',
      icon: <DashboardOutlined />,
      label: t('nav.dashboard'),
      path: '/dashboard',
    },
    {
      key: '/analytics',
      icon: <BarChartOutlined />,
      label: t('nav.analytics'),
      path: '/analytics',
    },
    {
      key: '/reports',
      icon: <FileTextOutlined />,
      label: t('nav.reports'),
      path: '/reports',
    },
    {
      type: 'divider',
    },
    {
      key: 'ai-group',
      icon: <RobotOutlined />,
      label: t('nav.ai'),
      children: [
        {
          key: '/ai/chat',
          icon: <MessageOutlined />,
          label: t('nav.ai_chat'),
          path: '/ai/chat',
        },
        {
          key: '/ai/sql-lab',
          icon: <CodeOutlined />,
          label: t('nav.sql_lab'),
          path: '/ai/sql-lab',
        },
        {
          key: '/ai/visualization',
          icon: <PieChartOutlined />,
          label: t('nav.visualization'),
          path: '/ai/visualization',
        },
        {
          key: '/ai/workflow',
          icon: <NodeIndexOutlined />,
          label: t('nav.workflow'),
          path: '/ai/workflow',
        },
      ],
    },
    {
      type: 'divider',
    },
    {
      key: '/settings',
      icon: <SettingOutlined />,
      label: t('nav.settings'),
      path: '/settings',
    },
  ];

  // 过滤有权限的菜单项
  const filterMenuItems = (items: any[]): any[] => {
    return items
      .filter((item) => {
        if (item.type === 'divider') return true;
        if (item.path && !canAccess(item.path)) return false;
        return true;
      })
      .map((item) => {
        if (item.children) {
          const filteredChildren = filterMenuItems(item.children);
          return filteredChildren.length > 0 ? { ...item, children: filteredChildren } : null;
        }
        return item;
      })
      .filter(Boolean);
  };

  const visibleMenuItems = filterMenuItems(menuItems);

  // 根据当前路径设置选中状态
  useEffect(() => {
    const currentPath = location.pathname;
    setSelectedKeys([currentPath]);

    // 设置展开的子菜单
    if (currentPath.startsWith('/ai/')) {
      setOpenKeys(['ai-group']);
    }
  }, [location.pathname]);

  // 处理菜单点击
  const handleMenuClick = ({ key }: { key: string }) => {
    const menuItem = findMenuItemByKey(visibleMenuItems, key);
    if (menuItem?.path) {
      navigate(menuItem.path);
    }
  };

  // 递归查找菜单项
  const findMenuItemByKey = (items: any[], key: string): any => {
    for (const item of items) {
      if (item.key === key) return item;
      if (item.children) {
        const found = findMenuItemByKey(item.children, key);
        if (found) return found;
      }
    }
    return null;
  };

  // 处理子菜单展开/收起
  const handleOpenChange = (keys: string[]) => {
    setOpenKeys(keys);
  };

  // 转换菜单项格式
  const transformMenuItems = (items: any[]): any[] => {
    return items.map((item) => {
      if (item.type === 'divider') {
        return { type: 'divider' };
      }

      const menuItem: any = {
        key: item.key,
        icon: item.icon,
        label: item.label,
      };

      if (item.children) {
        menuItem.children = transformMenuItems(item.children);
      }

      return menuItem;
    });
  };

  return (
    <div className="h-full flex flex-col">
      {/* 侧边栏标题 */}
      {!collapsed && (
        <div className="p-4 border-b border-border-primary">
          <Text className="text-text-secondary text-xs font-medium uppercase tracking-wider">
            导航菜单
          </Text>
        </div>
      )}

      {/* 菜单 */}
      <div className="flex-1 overflow-y-auto">
        <Menu
          mode="inline"
          selectedKeys={selectedKeys}
          openKeys={collapsed ? [] : openKeys}
          onOpenChange={handleOpenChange}
          onClick={handleMenuClick}
          items={transformMenuItems(visibleMenuItems)}
          className="border-none"
          style={{
            background: 'transparent',
          }}
          inlineCollapsed={collapsed}
        />
      </div>

      {/* 底部信息 */}
      {!collapsed && (
        <div className="p-4 border-t border-border-primary">
          <div className="text-center">
            <Text className="text-text-muted text-xs">
              版本 1.0.0
            </Text>
          </div>
        </div>
      )}
    </div>
  );
};

export default Sidebar;
