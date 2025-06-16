import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'

// 国际化初始化
import './i18n'

// 确保根元素存在
const rootElement = document.getElementById('root')
if (!rootElement) {
  throw new Error('Root element not found')
}

ReactDOM.createRoot(rootElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
