import { test, expect, Page } from '@playwright/test';

// 测试配置
const TEST_CONFIG = {
  baseURL: 'http://localhost:5173',
  timeout: 30000,
  navigationTimeout: 15000,
  retries: 2,
};

// 页面对象模式
class AIIntegrationPage {
  constructor(private page: Page) {}

  // 导航方法
  async goto() {
    await this.page.goto('/ai/chat');
    await this.page.waitForLoadState('networkidle');
  }

  async gotoSQLLab() {
    await this.page.goto('/ai/sql-lab');
    await this.page.waitForLoadState('networkidle');
  }

  // 聊天相关方法
  async sendChatMessage(message: string) {
    await this.page.fill('[data-testid="chat-input"]', message);
    await this.page.click('[data-testid="send-button"]');
  }

  async waitForChatResponse() {
    await this.page.waitForSelector('[data-testid="chat-response"]', { 
      timeout: TEST_CONFIG.timeout 
    });
  }

  async getChatMessages() {
    return await this.page.locator('[data-testid="chat-message"]').allTextContents();
  }

  // SQL Lab 相关方法
  async executeSQLQuery(query: string) {
    await this.page.fill('[data-testid="sql-editor"]', query);
    await this.page.click('[data-testid="execute-button"]');
  }

  async waitForSQLResults() {
    await this.page.waitForSelector('[data-testid="sql-results"]', { 
      timeout: TEST_CONFIG.timeout 
    });
  }

  // 性能检查方法
  async checkPagePerformance() {
    const paintMetrics = await this.page.evaluate(() => {
      const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
      const paint = performance.getEntriesByType('paint');
      
      return {
        fcp: paint.find(entry => entry.name === 'first-contentful-paint')?.startTime || 0,
        lcp: 0, // 需要通过 PerformanceObserver 获取
        domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
        loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
      };
    });

    return paintMetrics;
  }

  // 错误检查方法
  async checkConsoleErrors() {
    const errors: string[] = [];
    this.page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });
    return errors;
  }
}

// 测试套件开始
test.describe('AI Integration E2E Tests', () => {
  let aiPage: AIIntegrationPage;

  test.beforeEach(async ({ page }) => {
    aiPage = new AIIntegrationPage(page);
    
    // 设置请求拦截器
    await page.route('**/api/ai/**', async route => {
      const url = route.request().url();
      console.log(`[API] ${route.request().method()} ${url}`);
      
      // 模拟API响应（用于测试环境）
      if (url.includes('/chat/send')) {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            content: '这是一个模拟的AI回复，用于测试目的。',
            metadata: {
              sql: 'SELECT * FROM sales WHERE date >= "2024-01-01"',
              executionTime: 150
            }
          })
        });
      } else if (url.includes('/sql/execute')) {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            success: true,
            data: [
              { date: '2024-01-01', sales: 1000, profit: 200 },
              { date: '2024-01-02', sales: 1200, profit: 240 },
              { date: '2024-01-03', sales: 900, profit: 180 }
            ],
            columns: [
              { name: 'date', type: 'date' },
              { name: 'sales', type: 'number' },
              { name: 'profit', type: 'number' }
            ],
            executionTime: 89
          })
        });
      } else {
        await route.continue();
      }
    });
  });

  test.describe('AI Chat 功能测试', () => {
    test('应该能够正常加载聊天页面', async () => {
      await aiPage.goto();
      
      // 检查页面标题
      await expect(aiPage.page).toHaveTitle(/AI.*聊天|chat/i);
      
      // 检查关键元素是否存在
      await expect(aiPage.page.locator('[data-testid="chat-container"]')).toBeVisible();
      await expect(aiPage.page.locator('[data-testid="chat-input"]')).toBeVisible();
      await expect(aiPage.page.locator('[data-testid="send-button"]')).toBeVisible();
    });

    test('应该能够发送消息并接收回复', async () => {
      await aiPage.goto();
      
      const testMessage = '显示最近7天的销售趋势';
      
      // 发送消息
      await aiPage.sendChatMessage(testMessage);
      
      // 等待回复
      await aiPage.waitForChatResponse();
      
      // 验证消息已显示
      const messages = await aiPage.getChatMessages();
      expect(messages).toContain(testMessage);
      expect(messages.length).toBeGreaterThan(1); // 至少包含用户消息和AI回复
    });

    test('应该能够显示SQL查询结果', async () => {
      await aiPage.goto();
      
      // 发送会生成SQL的消息
      await aiPage.sendChatMessage('查询销售数据');
      await aiPage.waitForChatResponse();
      
      // 检查是否显示了SQL代码块
      await expect(aiPage.page.locator('[data-testid="sql-block"]')).toBeVisible();
      
      // 检查SQL内容
      const sqlContent = await aiPage.page.locator('[data-testid="sql-block"]').textContent();
      expect(sqlContent).toContain('SELECT');
    });

    test('应该能够清空聊天历史', async () => {
      await aiPage.goto();
      
      // 发送几条消息
      await aiPage.sendChatMessage('消息1');
      await aiPage.waitForChatResponse();
      await aiPage.sendChatMessage('消息2');
      await aiPage.waitForChatResponse();
      
      // 清空历史
      await aiPage.page.click('[data-testid="clear-history-button"]');
      
      // 验证消息已清空
      const messages = await aiPage.page.locator('[data-testid="chat-message"]').count();
      expect(messages).toBe(0);
    });
  });

  test.describe('SQL Lab 功能测试', () => {
    test('应该能够正常加载SQL Lab页面', async () => {
      await aiPage.gotoSQLLab();
      
      // 检查页面标题
      await expect(aiPage.page).toHaveTitle(/SQL.*Lab|实验室/i);
      
      // 检查关键元素
      await expect(aiPage.page.locator('[data-testid="sql-editor"]')).toBeVisible();
      await expect(aiPage.page.locator('[data-testid="execute-button"]')).toBeVisible();
      await expect(aiPage.page.locator('[data-testid="results-container"]')).toBeVisible();
    });

    test('应该能够执行SQL查询', async () => {
      await aiPage.gotoSQLLab();
      
      const testQuery = 'SELECT * FROM sales LIMIT 10';
      
      // 输入并执行查询
      await aiPage.executeSQLQuery(testQuery);
      await aiPage.waitForSQLResults();
      
      // 验证结果显示
      await expect(aiPage.page.locator('[data-testid="sql-results"]')).toBeVisible();
      
      // 检查是否有数据行
      const rows = await aiPage.page.locator('[data-testid="result-row"]').count();
      expect(rows).toBeGreaterThan(0);
    });

    test('应该能够显示查询执行时间', async () => {
      await aiPage.gotoSQLLab();
      
      await aiPage.executeSQLQuery('SELECT COUNT(*) FROM sales');
      await aiPage.waitForSQLResults();
      
      // 检查执行时间显示
      await expect(aiPage.page.locator('[data-testid="execution-time"]')).toBeVisible();
      
      const executionTime = await aiPage.page.locator('[data-testid="execution-time"]').textContent();
      expect(executionTime).toMatch(/\d+\s*(ms|毫秒)/);
    });
  });

  test.describe('性能测试', () => {
    test('首屏加载时间应该小于2秒', async () => {
      const startTime = Date.now();
      
      await aiPage.goto();
      
      const endTime = Date.now();
      const loadTime = endTime - startTime;
      
      expect(loadTime).toBeLessThan(2000);
    });

    test('页面性能指标应该达标', async () => {
      await aiPage.goto();
      
      const metrics = await aiPage.checkPagePerformance();
      
      // First Contentful Paint 应该小于1.8秒
      expect(metrics.fcp).toBeLessThan(1800);
      
      // DOM Content Loaded 应该小于1秒
      expect(metrics.domContentLoaded).toBeLessThan(1000);
    });

    test('Bundle大小应该符合预期', async ({ page }) => {
      // 监控网络请求
      const requests: { url: string; size: number }[] = [];
      
      page.on('response', response => {
        const url = response.url();
        if (url.includes('.js') || url.includes('.css')) {
          requests.push({
            url: url,
            size: parseInt(response.headers()['content-length'] || '0')
          });
        }
      });
      
      await aiPage.goto();
      
      // 等待所有资源加载完成
      await page.waitForLoadState('networkidle');
      
      // 检查主要JS文件大小
      const mainJSFiles = requests.filter(req => req.url.includes('index') && req.url.includes('.js'));
      const totalJSSize = mainJSFiles.reduce((sum, file) => sum + file.size, 0);
      
      // 主要JS文件总大小应该小于200KB（压缩后）
      expect(totalJSSize).toBeLessThan(200 * 1024);
    });
  });

  test.describe('错误处理测试', () => {
    test('应该能够处理API错误', async ({ page }) => {
      // 模拟API错误
      await page.route('**/api/ai/chat/send', route => {
        route.fulfill({
          status: 500,
          contentType: 'application/json',
          body: JSON.stringify({ error: 'Internal Server Error' })
        });
      });
      
      await aiPage.goto();
      await aiPage.sendChatMessage('测试错误处理');
      
      // 应该显示错误消息
      await expect(page.locator('[data-testid="error-message"]')).toBeVisible();
    });

    test('应该能够处理网络超时', async ({ page }) => {
      // 模拟网络超时
      await page.route('**/api/ai/chat/send', route => {
        // 延迟响应超过超时时间
        setTimeout(() => {
          route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({ content: '延迟响应' })
          });
        }, 35000); // 35秒延迟
      });
      
      await aiPage.goto();
      await aiPage.sendChatMessage('测试超时');
      
      // 应该显示超时错误
      await expect(page.locator('[data-testid="timeout-error"]')).toBeVisible({ timeout: 40000 });
    });
  });

  test.describe('无障碍访问测试', () => {
    test('应该支持键盘导航', async () => {
      await aiPage.goto();
      
      // 使用Tab键导航
      await aiPage.page.keyboard.press('Tab');
      await aiPage.page.keyboard.press('Tab');
      
      // 检查焦点是否在输入框上
      const focused = await aiPage.page.locator(':focus');
      await expect(focused).toHaveAttribute('data-testid', 'chat-input');
      
      // 使用回车发送消息
      await aiPage.page.fill('[data-testid="chat-input"]', '键盘测试');
      await aiPage.page.keyboard.press('Enter');
      
      await aiPage.waitForChatResponse();
    });

    test('应该有正确的ARIA标签', async () => {
      await aiPage.goto();
      
      // 检查关键元素的ARIA标签
      await expect(aiPage.page.locator('[data-testid="chat-container"]')).toHaveAttribute('role', 'main');
      await expect(aiPage.page.locator('[data-testid="chat-input"]')).toHaveAttribute('aria-label');
      await expect(aiPage.page.locator('[data-testid="send-button"]')).toHaveAttribute('aria-label');
    });
  });

  test.describe('响应式设计测试', () => {
    test('应该在移动设备上正常显示', async ({ page }) => {
      // 设置移动设备视口
      await page.setViewportSize({ width: 375, height: 667 });
      
      await aiPage.goto();
      
      // 检查移动端布局
      await expect(aiPage.page.locator('[data-testid="mobile-menu"]')).toBeVisible();
      await expect(aiPage.page.locator('[data-testid="chat-container"]')).toBeVisible();
      
      // 检查输入框是否适配移动端
      const inputBox = aiPage.page.locator('[data-testid="chat-input"]');
      const boundingBox = await inputBox.boundingBox();
      expect(boundingBox?.width).toBeGreaterThan(300); // 适当的宽度
    });

    test('应该在平板设备上正常显示', async ({ page }) => {
      // 设置平板设备视口
      await page.setViewportSize({ width: 768, height: 1024 });
      
      await aiPage.goto();
      
      // 检查平板端布局
      await expect(aiPage.page.locator('[data-testid="chat-container"]')).toBeVisible();
      
      // 验证侧边栏在平板上的表现
      const sidebar = aiPage.page.locator('[data-testid="sidebar"]');
      if (await sidebar.isVisible()) {
        const sidebarBox = await sidebar.boundingBox();
        expect(sidebarBox?.width).toBeGreaterThan(200);
      }
    });
  });
});

// 自定义匹配器
test.describe('自定义验证', () => {
  test('Core Web Vitals 应该达标', async ({ page }) => {
    await aiPage.goto();
    
    // 等待页面完全加载
    await page.waitForLoadState('networkidle');
    
    // 注入 web-vitals 库并测量
    const vitals = await page.evaluate(async () => {
      // 简化的CLS测量
      let cls = 0;
      const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          if (!entry.hadRecentInput) {
            cls += (entry as any).value;
          }
        }
      });
      
      observer.observe({ type: 'layout-shift', buffered: true });
      
      // 等待一段时间收集数据
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      return { cls };
    });
    
    // CLS 应该小于 0.1
    expect(vitals.cls).toBeLessThan(0.1);
  });
});