import { test, expect } from '@playwright/test';

test('基本测试 - 应用应该能够启动', async ({ page }) => {
  await page.goto('/');
  
  // 等待页面加载
  await page.waitForLoadState('networkidle');
  
  // 验证页面标题包含应用名称
  const title = await page.title();
  expect(title).toContain('抖音');
  
  // 验证应用根节点存在
  const rootElement = await page.locator('#root');
  await expect(rootElement).toBeVisible();
});