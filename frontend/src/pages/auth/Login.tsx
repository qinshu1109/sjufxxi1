import { GithubOutlined, GoogleOutlined, LockOutlined, UserOutlined } from '@ant-design/icons';
import { Button, Checkbox, Divider, Form, Input, message } from 'antd';
import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

// Hooks
import { useAuthStore } from '@/stores/authStore';

interface LoginForm {
  username: string;
  password: string;
  remember: boolean;
}

const Login = () => {
  const navigate = useNavigate();
  const { login } = useAuthStore();
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (values: LoginForm) => {
    setLoading(true);

    try {
      // 模拟登录 API 调用
      await new Promise(resolve => setTimeout(resolve, 1000));

      // 模拟用户数据
      const mockUser = {
        id: '1',
        name: values.username === 'admin' ? '管理员' : '用户',
        email: values.username === 'admin' ? 'admin@douyin.com' : 'user@douyin.com',
        role: values.username === 'admin' ? 'admin' as const : 'user' as const,
        permissions: values.username === 'admin'
          ? [
            'dashboard:read',
            'analytics:read',
            'reports:read',
            'settings:read',
            'ai:chat',
            'ai:sql',
            'ai:visualization',
            'ai:workflow',
          ]
          : [
            'dashboard:read',
            'analytics:read',
            'reports:read',
            'ai:chat',
            'ai:sql',
            'ai:visualization',
          ],
        createdAt: new Date().toISOString(),
      };

      const mockToken = 'mock-jwt-token-' + Date.now();

      login(mockUser, mockToken);
      message.success('登录成功！');
      navigate('/dashboard');

    } catch (error) {
      message.error('登录失败，请检查用户名和密码');
    } finally {
      setLoading(false);
    }
  };

  const handleSocialLogin = (provider: string) => {
    message.info(`${provider} 登录功能开发中...`);
  };

  return (
    <div className="space-y-6">
      <div className="text-center">
        <h1 className="text-2xl font-bold mb-2">欢迎回来</h1>
        <p className="text-text-secondary">
          登录您的账户以继续使用数据分析平台
        </p>
      </div>

      <Form
        name="login"
        onFinish={handleSubmit}
        autoComplete="off"
        size="large"
        layout="vertical"
      >
        <Form.Item
          name="username"
          rules={[
            { required: true, message: '请输入用户名' },
            { min: 3, message: '用户名至少3个字符' },
          ]}
        >
          <Input
            prefix={<UserOutlined />}
            placeholder="用户名 (试试 admin 或 user)"
          />
        </Form.Item>

        <Form.Item
          name="password"
          rules={[
            { required: true, message: '请输入密码' },
            { min: 6, message: '密码至少6个字符' },
          ]}
        >
          <Input.Password
            prefix={<LockOutlined />}
            placeholder="密码 (任意6位以上)"
          />
        </Form.Item>

        <Form.Item>
          <div className="flex items-center justify-between">
            <Form.Item name="remember" valuePropName="checked" noStyle>
              <Checkbox>记住我</Checkbox>
            </Form.Item>
            <Link
              to="/auth/forgot-password"
              className="text-primary-500 hover:text-primary-600"
            >
              忘记密码？
            </Link>
          </div>
        </Form.Item>

        <Form.Item>
          <Button
            type="primary"
            htmlType="submit"
            loading={loading}
            className="w-full h-12"
          >
            登录
          </Button>
        </Form.Item>
      </Form>

      <Divider>或</Divider>

      <div className="space-y-3">
        <Button
          icon={<GithubOutlined />}
          onClick={() => handleSocialLogin('GitHub')}
          className="w-full h-12"
        >
          使用 GitHub 登录
        </Button>

        <Button
          icon={<GoogleOutlined />}
          onClick={() => handleSocialLogin('Google')}
          className="w-full h-12"
        >
          使用 Google 登录
        </Button>
      </div>

      <div className="text-center">
        <span className="text-text-secondary">还没有账户？</span>
        <Link
          to="/auth/register"
          className="ml-1 text-primary-500 hover:text-primary-600"
        >
          立即注册
        </Link>
      </div>

      {/* 演示提示 */}
      <div className="mt-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
        <p className="text-sm text-blue-700 dark:text-blue-300 mb-2">
          <strong>演示账户：</strong>
        </p>
        <ul className="text-sm text-blue-600 dark:text-blue-400 space-y-1">
          <li>• 管理员：用户名 <code>admin</code>，密码任意6位以上</li>
          <li>• 普通用户：用户名 <code>user</code>，密码任意6位以上</li>
        </ul>
      </div>
    </div>
  );
};

export default Login;
