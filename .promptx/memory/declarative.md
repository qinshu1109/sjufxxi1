# 陈述性记忆

## 高价值记忆（评分 ≥ 7）

- 2025/06/16 11:49 MCP工具配置完整方案：
1. 配置了11个MCP工具：fs, github, git, fetch, memory, screenshot, ocr, autogui, time, vision, promptx
2. 配置文件位置：/home/qinshu/douyin-analytics/MCP工具/mcp-config.json
3. 持久化配置已完成：复制到 ~/.config/claude/claude_desktop_config.json
4. 启动脚本：./scripts/launch_promptx_mcp.sh
5. 当前会话只有6个PromptX工具可用，需要重新启动完整MCP会话才能使用全部11个工具
6. GitHub token已配置，可实现自动推送
7. PromptX系统包含女娲角色，可创建自定义专业角色 --tags MCP工具 配置管理 Claude Code 工具生态系统 ##工具使用 #评分:8 #有效期:长期



- 2025/06/16 11:55 DB-GPT/AWEL前端集成项目关键信息：
1. 项目目标：将DB-GPT聊天和NL2SQL功能集成到React主站
2. 技术栈：React + Vite + TypeScript + Ant Design + Tailwind CSS
3. 关键挑战：Bundle体积控制、样式统一、API代理、性能优化
4. 时间规划：6天完成，包含F1-F5五个阶段
5. 验收标准：Lighthouse >85、E2E测试通过、Core Web Vitals达标
6. 项目结构：frontend/src + external/dbgpt + 容器化部署
7. 关键路由：/ai/chat, /ai/sql-lab
8. 性能预算：主包<200KB，首屏<2秒，Bundle分割策略 --tags DB-GPT 前端集成 React AWEL 性能优化 ##其他 #评分:8 #有效期:长期

- 2025/06/16 12:02 DB-GPT/AWEL前端集成完整实施方案：

## 🎯 完成状态
✅ **Phase 1**: 路由集成 - AI页面路由(/ai/chat, /ai/sql-lab)已配置
✅ **Phase 2**: API集成 - 完整的AI API客户端(aiAPI)和自定义Hooks(useChatAPI)
✅ **Phase 3**: 样式统一 - CSS变量系统、主题配置、AI Chat专用样式
✅ **Phase 4**: 构建脚本 - build:dbgpt脚本、package.json优化、性能预算
✅ **Phase 5**: E2E测试 - 完整的AI集成测试套件、健康检查脚本

## 📁 创建的关键文件
1. `/frontend/src/api/ai.ts` - AI API客户端和服务层
2. `/frontend/src/hooks/useChatAPI.ts` - Chat功能的React Hook
3. `/frontend/src/types/ai.ts` - 完整的AI相关类型定义
4. `/frontend/src/styles/theme.css` - 统一主题系统(更新)
5. `/frontend/tests/e2e/ai-integration.spec.ts` - E2E测试套件
6. `/frontend/scripts/health-check.js` - 健康检查脚本
7. `/frontend/package.json` - 增强的构建脚本和依赖

## 🔧 技术特性
- **API代理**: Vite配置支持/api/ai代理到localhost:5000
- **Bundle优化**: 代码分割、懒加载、200KB gzip限制
- **性能监控**: Core Web Vitals、Lighthouse集成
- **样式统一**: CSS变量映射Ant Design Token
- **类型安全**: 完整的TypeScript类型定义
- **测试覆盖**: Chat、SQL Lab、性能、无障碍访问测试

## 🚀 启动命令
- `npm run dev:proxy` - 同时启动前端和DB-GPT
- `npm run build:with-ai` - 构建包含AI组件的完整应用
- `npm run e2e:ai` - 运行AI集成测试
- `npm run health:check` - 健康检查
- `npm run perf:lighthouse` - 性能测试 --tags DB-GPT 前端集成 React TypeScript 完整实施方案 ##工具使用 #评分:8 #有效期:长期

- 2025/06/16 12:04 会话工作四原则与MCP工具快速激活指南：

## 💡 四原则
1. **启动会话时**: 运行 `./scripts/launch_promptx_mcp.sh`，检测11个工具，标准：终端输出 `MCP READY`
2. **项目工作时**: fs(文件修改) + git(本地提交) + github(远程PR)，原则：先本地commit+单测绿，再push PR  
3. **问题解决时**: `promptx.run(role='<expert_role>')` 激活专家角色：frontend_fix、devops、db、qa
4. **经验积累时**: `memory.remember(key, value)` 保存命令片段、错误修复对、性能基准值

## 🚀 30秒快速激活流程
1. `./scripts/launch_promptx_mcp.sh`
2. `fetch.get('http://localhost:5000/health')`  
3. `git.checkout('feature/fix-dashboard')`
4. `autogui.open() + screenshot.capture()`

## 错误处理循环
红屏 → `ocr.read()` → `promptx.run(role='frontend_fix')` → `fs.apply_patch()` → 循环

## 退出条件
- 页面渲染0报错
- Playwright 10/10通过  
- Bundle ≤170KB
- GitHub PR绿灯CI

每完成循环调用 `memory.remember('last_fix', commit_sha)` --tags MCP工具 工作流程 快速激活 会话原则 ##流程管理 #工具使用 #评分:8 #有效期:长期