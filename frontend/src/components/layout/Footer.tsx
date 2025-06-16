import { Layout, Typography, Space, Divider } from 'antd';
import { GithubOutlined, HeartFilled } from '@ant-design/icons';

const { Footer: AntdFooter } = Layout;
const { Text, Link } = Typography;

const Footer = () => {
  const currentYear = new Date().getFullYear();

  return (
    <AntdFooter className="border-t border-border-primary bg-bg-secondary py-6 text-center">
      <div className="mx-auto max-w-6xl">
        <Space split={<Divider type="vertical" />} className="mb-4">
          <Link href="/about" className="text-text-secondary hover:text-primary-500">
            关于我们
          </Link>
          <Link href="/privacy" className="text-text-secondary hover:text-primary-500">
            隐私政策
          </Link>
          <Link href="/terms" className="text-text-secondary hover:text-primary-500">
            服务条款
          </Link>
          <Link href="/help" className="text-text-secondary hover:text-primary-500">
            帮助中心
          </Link>
          <Link href="/contact" className="text-text-secondary hover:text-primary-500">
            联系我们
          </Link>
        </Space>

        <div className="mb-4 flex items-center justify-center space-x-4">
          <Link
            href="https://github.com/qinshu1109/sjufxxi1"
            target="_blank"
            className="text-text-secondary hover:text-primary-500"
          >
            <GithubOutlined className="text-lg" />
          </Link>
        </div>

        <Text className="text-sm text-text-muted">
          © {currentYear} 抖音数据分析平台. Made with <HeartFilled className="mx-1 text-red-500" />
          by 数据分析团队
        </Text>

        <div className="mt-2">
          <Text className="text-xs text-text-muted">
            Powered by DB-GPT AWEL • React • Ant Design
          </Text>
        </div>
      </div>
    </AntdFooter>
  );
};

export default Footer;
