import { LockOutlined, MailOutlined, UserOutlined } from '@ant-design/icons';
import { Button, Form, Input, message } from 'antd';
import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

interface RegisterForm {
  username: string;
  email: string;
  password: string;
  confirmPassword: string;
}

const Register = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (_values: RegisterForm) => {
    setLoading(true);

    try {
      // 模拟注册 API 调用
      await new Promise((resolve) => setTimeout(resolve, 1500));

      message.success('注册成功！请登录您的账户');
      navigate('/auth/login');
    } catch (error) {
      message.error('注册失败，请重试');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="text-center">
        <h1 className="mb-2 text-2xl font-bold">创建账户</h1>
        <p className="text-text-secondary">注册新账户以开始使用数据分析平台</p>
      </div>

      <Form
        name="register"
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
            { max: 20, message: '用户名最多20个字符' },
            { pattern: /^[a-zA-Z0-9_]+$/, message: '用户名只能包含字母、数字和下划线' },
          ]}
        >
          <Input prefix={<UserOutlined />} placeholder="用户名" />
        </Form.Item>

        <Form.Item
          name="email"
          rules={[
            { required: true, message: '请输入邮箱地址' },
            { type: 'email', message: '请输入有效的邮箱地址' },
          ]}
        >
          <Input prefix={<MailOutlined />} placeholder="邮箱地址" />
        </Form.Item>

        <Form.Item
          name="password"
          rules={[
            { required: true, message: '请输入密码' },
            { min: 8, message: '密码至少8个字符' },
            {
              pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
              message: '密码必须包含大小写字母和数字',
            },
          ]}
        >
          <Input.Password prefix={<LockOutlined />} placeholder="密码" />
        </Form.Item>

        <Form.Item
          name="confirmPassword"
          dependencies={['password']}
          rules={[
            { required: true, message: '请确认密码' },
            ({ getFieldValue }) => ({
              validator(_, value) {
                if (!value || getFieldValue('password') === value) {
                  return Promise.resolve();
                }
                return Promise.reject(new Error('两次输入的密码不一致'));
              },
            }),
          ]}
        >
          <Input.Password prefix={<LockOutlined />} placeholder="确认密码" />
        </Form.Item>

        <Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} className="h-12 w-full">
            注册
          </Button>
        </Form.Item>
      </Form>

      <div className="text-center">
        <span className="text-text-secondary">已有账户？</span>
        <Link to="/auth/login" className="ml-1 text-primary-500 hover:text-primary-600">
          立即登录
        </Link>
      </div>

      {/* 注册提示 */}
      <div className="mt-6 rounded-lg border border-green-200 bg-green-50 p-4 dark:border-green-800 dark:bg-green-900/20">
        <p className="mb-2 text-sm text-green-700 dark:text-green-300">
          <strong>注册须知：</strong>
        </p>
        <ul className="space-y-1 text-sm text-green-600 dark:text-green-400">
          <li>• 用户名只能包含字母、数字和下划线</li>
          <li>• 密码必须包含大小写字母和数字</li>
          <li>• 注册后需要邮箱验证（演示环境跳过）</li>
        </ul>
      </div>
    </div>
  );
};

export default Register;
