import { test, expect } from '@playwright/test';

test.describe('认证功能', () => {
  test('应该重定向未认证用户到登录页', async ({ page }) => {
    // 尝试访问受保护的页面
    await page.goto('/analytics');
    
    // 应该被重定向到登录页
    await expect(page).toHaveURL(/.*\/login/);
  });

  test('应该能够登录', async ({ page }) => {
    await page.goto('/login');
    
    // 填写登录表单
    await page.fill('input[name="username"]', 'testuser');
    await page.fill('input[name="password"]', 'testpassword');
    
    // 提交表单
    await page.click('button[type="submit"]');
    
    // 等待导航
    await page.waitForNavigation();
    
    // 应该被重定向到首页
    await expect(page).toHaveURL(/.*\/$/);
    
    // 应该显示用户信息
    await expect(page.locator('[data-testid="user-menu"]')).toContainText('testuser');
  });

  test('应该显示登录错误信息', async ({ page }) => {
    await page.goto('/login');
    
    // 填写错误的凭据
    await page.fill('input[name="username"]', 'wronguser');
    await page.fill('input[name="password"]', 'wrongpassword');
    
    // 提交表单
    await page.click('button[type="submit"]');
    
    // 应该显示错误信息
    await expect(page.locator('[data-testid="error-message"]')).toContainText('用户名或密码错误');
  });

  test('应该能够登出', async ({ page }) => {
    // 先登录
    await page.goto('/login');
    await page.fill('input[name="username"]', 'testuser');
    await page.fill('input[name="password"]', 'testpassword');
    await page.click('button[type="submit"]');
    await page.waitForNavigation();
    
    // 点击用户菜单
    await page.click('[data-testid="user-menu"]');
    
    // 点击登出
    await page.click('text=退出登录');
    
    // 应该被重定向到登录页
    await expect(page).toHaveURL(/.*\/login/);
  });
});