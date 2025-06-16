import { HomeOutlined } from '@ant-design/icons';
import { Breadcrumb as AntdBreadcrumb } from 'antd';
import { useLocation } from 'react-router-dom';

// 路由元信息
import { routeMeta } from '@/router';

const Breadcrumb = () => {
  const location = useLocation();

  // 获取当前路径的面包屑
  const getBreadcrumbItems = () => {
    const pathname = location.pathname;
    const meta = routeMeta[pathname as keyof typeof routeMeta];

    if (!meta) {
      return [
        {
          title: (
            <span>
              <HomeOutlined />
              <span className="ml-1">首页</span>
            </span>
          ),
        },
      ];
    }

    // 构建面包屑项
    const items = meta.breadcrumb.map((item, index) => {
      if (index === 0) {
        return {
          title: (
            <span>
              <HomeOutlined />
              <span className="ml-1">{item}</span>
            </span>
          ),
        };
      }
      return {
        title: item,
      };
    });

    return items;
  };

  return <AntdBreadcrumb items={getBreadcrumbItems()} className="text-text-secondary" />;
};

export default Breadcrumb;
