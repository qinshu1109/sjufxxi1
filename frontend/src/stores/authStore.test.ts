import { describe, it, expect, beforeEach } from 'vitest';
import { useAuthStore } from './authStore';

describe('authStore', () => {
  beforeEach(() => {
    // 重置 store
    useAuthStore.setState({
      isAuthenticated: false,
      user: null,
      token: null,
    });
  });

  it('初始状态应该是未认证', () => {
    const { isAuthenticated, user, token } = useAuthStore.getState();
    expect(isAuthenticated).toBe(false);
    expect(user).toBe(null);
    expect(token).toBe(null);
  });

  it('登录应该更新状态', () => {
    const userData = {
      id: '1',
      username: 'testuser',
      email: 'test@example.com',
      name: 'Test User',
      role: 'user' as const,
      permissions: [],
      createdAt: new Date().toISOString(),
    };
    const tokenData = 'test-token';

    useAuthStore.getState().login(userData, tokenData);

    const { isAuthenticated, user, token } = useAuthStore.getState();
    expect(isAuthenticated).toBe(true);
    expect(user).toEqual(userData);
    expect(token).toBe(tokenData);
  });

  it('登出应该清除状态', () => {
    const userData = {
      id: '1',
      username: 'testuser',
      email: 'test@example.com',
      name: 'Test User',
      role: 'user' as const,
      permissions: [],
      createdAt: new Date().toISOString(),
    };
    const tokenData = 'test-token';

    useAuthStore.getState().login(userData, tokenData);
    useAuthStore.getState().logout();

    const { isAuthenticated, user, token } = useAuthStore.getState();
    expect(isAuthenticated).toBe(false);
    expect(user).toBe(null);
    expect(token).toBe(null);
  });
});
