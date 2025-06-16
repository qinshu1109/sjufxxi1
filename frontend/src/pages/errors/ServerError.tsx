import { useNavigate } from 'react-router-dom';
import { Button, Result } from 'antd';

const ServerError = () => {
  const navigate = useNavigate();

  return (
    <div className="flex min-h-screen items-center justify-center">
      <Result
        status="500"
        title="500"
        subTitle="抱歉，服务器出现了一些问题。"
        extra={
          <div className="space-x-4">
            <Button type="primary" onClick={() => navigate('/dashboard')}>
              返回首页
            </Button>
            <Button onClick={() => window.location.reload()}>刷新页面</Button>
          </div>
        }
      />
    </div>
  );
};

export default ServerError;
