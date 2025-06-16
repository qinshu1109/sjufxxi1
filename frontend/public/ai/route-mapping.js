// DB-GPT 路由映射配置
window.DBGPT_ROUTE_MAPPING = {
  '/': '/ai/chat',
  '/chat': '/ai/chat',
  '/construct/app': '/ai/sql-lab',
  '/knowledge': '/ai/visualization',
  '/flow': '/ai/workflow'
};

// 自动重定向函数
window.redirectToMainApp = function(path) {
  const mapping = window.DBGPT_ROUTE_MAPPING;
  const targetPath = mapping[path] || '/ai/chat';
  if (window.parent && window.parent !== window) {
    // 在 iframe 中，通知父窗口进行路由跳转
    window.parent.postMessage({
      type: 'DBGPT_ROUTE_CHANGE',
      path: targetPath
    }, '*');
  } else {
    // 直接跳转
    window.location.href = targetPath;
  }
};
