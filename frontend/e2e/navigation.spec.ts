import { test, expect } from '@playwright/test';

test.describe('导航功能', () => {
  test('应该能够访问首页', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/抖音数据分析平台/);
  });

  test('应该能够导航到数据分析页面', async ({ page }) => {
    await page.goto('/');
    
    // 点击数据分析链接
    await page.click('text=数据分析');
    
    // 验证 URL 改变
    await expect(page).toHaveURL(/.*\/analytics/);
    
    // 验证页面内容
    await expect(page.locator('h1')).toContainText('数据分析');
  });

  test('应该能够导航到报表页面', async ({ page }) => {
    await page.goto('/');
    
    // 点击报表链接
    await page.click('text=报表');
    
    // 验证 URL 改变
    await expect(page).toHaveURL(/.*\/reports/);
    
    // 验证页面内容
    await expect(page.locator('h1')).toContainText('报表');
  });

  test('侧边栏应该能够折叠和展开', async ({ page }) => {
    await page.goto('/');
    
    // 查找折叠按钮
    const collapseButton = page.locator('[data-testid="sidebar-toggle"]');
    
    // 初始状态侧边栏应该是展开的
    const sidebar = page.locator('[data-testid="sidebar"]');
    await expect(sidebar).toBeVisible();
    
    // 点击折叠按钮
    await collapseButton.click();
    
    // 验证侧边栏已折叠
    await expect(sidebar).toHaveAttribute('data-collapsed', 'true');
    
    // 再次点击展开
    await collapseButton.click();
    
    // 验证侧边栏已展开
    await expect(sidebar).toHaveAttribute('data-collapsed', 'false');
  });
});