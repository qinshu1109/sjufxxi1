import { ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { Result, Button } from 'antd';

// Hooks
import { useAuthStore } from '@/stores/authStore';

interface ProtectedRouteProps {
  children: ReactNode;
  requiredPermissions?: string[];
  requiredRole?: 'admin' | 'user';
  fallback?: ReactNode;
}

const ProtectedRoute = ({
  children,
  requiredPermissions = [],
  requiredRole,
  fallback,
}: ProtectedRouteProps) => {
  const location = useLocation();
  const { isAuthenticated, user, hasPermission, hasRole, canAccess } = useAuthStore();

  // 未登录，重定向到登录页
  if (!isAuthenticated || !user) {
    return <Navigate to="/auth/login" state={{ from: location }} replace />;
  }

  // 检查角色权限
  if (requiredRole && !hasRole(requiredRole)) {
    return (
      fallback || (
        <div className="min-h-screen flex items-center justify-center">
          <Result
            status="403"
            title="权限不足"
            subTitle={`此页面需要 ${requiredRole === 'admin' ? '管理员' : '用户'} 权限才能访问。`}
            extra={
              <Button type="primary" onClick={() => window.history.back()}>
                返回上一页
              </Button>
            }
          />
        </div>
      )
    );
  }

  // 检查具体权限
  if (requiredPermissions.length > 0) {
    const hasRequiredPermissions = requiredPermissions.some(permission => 
      hasPermission(permission)
    );

    if (!hasRequiredPermissions) {
      return (
        fallback || (
          <div className="min-h-screen flex items-center justify-center">
            <Result
              status="403"
              title="权限不足"
              subTitle="您没有访问此页面的权限。"
              extra={
                <Button type="primary" onClick={() => window.history.back()}>
                  返回上一页
                </Button>
              }
            />
          </div>
        )
      );
    }
  }

  // 检查路由权限
  if (!canAccess(location.pathname)) {
    return (
      fallback || (
        <div className="min-h-screen flex items-center justify-center">
          <Result
            status="403"
            title="访问受限"
            subTitle="您没有访问此页面的权限。"
            extra={
              <Button type="primary" onClick={() => window.history.back()}>
                返回上一页
              </Button>
            }
          />
        </div>
      )
    );
  }

  return <>{children}</>;
};

export default ProtectedRoute;
