import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  role: 'admin' | 'user';
  permissions: string[];
  lastLoginAt?: string;
  createdAt: string;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  
  // Actions
  login: (user: User, token: string) => void;
  logout: () => void;
  updateUser: (user: Partial<User>) => void;
  setLoading: (loading: boolean) => void;
  
  // Permission helpers
  hasPermission: (permission: string) => boolean;
  hasRole: (role: string) => boolean;
  canAccess: (path: string) => boolean;
}

// 路由权限映射
const routePermissions: Record<string, string[]> = {
  '/dashboard': ['dashboard:read'],
  '/analytics': ['analytics:read'],
  '/reports': ['reports:read'],
  '/settings': ['settings:read', 'admin'],
  '/ai/chat': ['ai:chat'],
  '/ai/sql-lab': ['ai:sql'],
  '/ai/visualization': ['ai:visualization'],
  '/ai/workflow': ['ai:workflow', 'admin'],
};

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,
      
      login: (user: User, token: string) => {
        set({
          user,
          token,
          isAuthenticated: true,
          isLoading: false,
        });
        
        // 设置 axios 默认 header
        if (typeof window !== 'undefined') {
          localStorage.setItem('auth-token', token);
        }
      },
      
      logout: () => {
        set({
          user: null,
          token: null,
          isAuthenticated: false,
          isLoading: false,
        });
        
        // 清除 token
        if (typeof window !== 'undefined') {
          localStorage.removeItem('auth-token');
        }
      },
      
      updateUser: (userData: Partial<User>) => {
        const { user } = get();
        if (user) {
          set({
            user: { ...user, ...userData },
          });
        }
      },
      
      setLoading: (loading: boolean) => {
        set({ isLoading: loading });
      },
      
      hasPermission: (permission: string) => {
        const { user } = get();
        if (!user) return false;
        
        // 管理员拥有所有权限
        if (user.role === 'admin') return true;
        
        return user.permissions.includes(permission);
      },
      
      hasRole: (role: string) => {
        const { user } = get();
        if (!user) return false;
        
        return user.role === role;
      },
      
      canAccess: (path: string) => {
        const { user, hasPermission, hasRole } = get();
        if (!user) return false;
        
        // 获取路径所需权限
        const requiredPermissions = routePermissions[path];
        if (!requiredPermissions) return true; // 无权限要求的路由
        
        // 检查是否有任一所需权限
        return requiredPermissions.some(permission => {
          // 如果是角色检查
          if (permission === 'admin' || permission === 'user') {
            return hasRole(permission);
          }
          // 如果是权限检查
          return hasPermission(permission);
        });
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);

// 初始化时恢复认证状态
if (typeof window !== 'undefined') {
  const token = localStorage.getItem('auth-token');
  if (token && !useAuthStore.getState().isAuthenticated) {
    // 这里可以调用 API 验证 token 有效性
    // 暂时使用模拟数据
    const mockUser: User = {
      id: '1',
      name: '管理员',
      email: 'admin@douyin.com',
      role: 'admin',
      permissions: [
        'dashboard:read',
        'analytics:read',
        'reports:read',
        'settings:read',
        'ai:chat',
        'ai:sql',
        'ai:visualization',
        'ai:workflow',
      ],
      createdAt: new Date().toISOString(),
    };
    
    useAuthStore.getState().login(mockUser, token);
  }
}
