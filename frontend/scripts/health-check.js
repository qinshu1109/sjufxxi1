#!/usr/bin/env node

/**
 * 健康检查脚本
 * 用于验证前端应用和AI集成的健康状态
 */

import axios from 'axios';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 配置
const CONFIG = {
  baseURL: process.env.APP_URL || 'http://localhost:5173',
  aiAPIURL: process.env.AI_API_URL || 'http://localhost:5000',
  timeout: 10000,
  retries: 3,
  outputFile: './reports/health-check.json'
};

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function success(message) {
  log(`✅ ${message}`, 'green');
}

function error(message) {
  log(`❌ ${message}`, 'red');
}

function warning(message) {
  log(`⚠️  ${message}`, 'yellow');
}

function info(message) {
  log(`ℹ️  ${message}`, 'blue');
}

// 健康检查结果
const healthReport = {
  timestamp: new Date().toISOString(),
  overall: 'unknown',
  checks: {}
};

// HTTP客户端配置
const client = axios.create({
  timeout: CONFIG.timeout,
  validateStatus: status => status < 500 // 4xx被认为是可接受的
});

/**
 * 检查前端应用是否可访问
 */
async function checkFrontendHealth() {
  info('检查前端应用健康状态...');
  
  try {
    const response = await client.get(CONFIG.baseURL);
    
    if (response.status === 200) {
      success('前端应用正常运行');
      healthReport.checks.frontend = {
        status: 'healthy',
        responseTime: response.headers['x-response-time'] || 'unknown',
        statusCode: response.status
      };
      return true;
    } else {
      warning(`前端应用响应异常，状态码: ${response.status}`);
      healthReport.checks.frontend = {
        status: 'degraded',
        statusCode: response.status,
        message: 'Unexpected status code'
      };
      return false;
    }
  } catch (err) {
    error(`前端应用无法访问: ${err.message}`);
    healthReport.checks.frontend = {
      status: 'unhealthy',
      error: err.message
    };
    return false;
  }
}

/**
 * 检查AI API是否可用
 */
async function checkAIAPIHealth() {
  info('检查AI API健康状态...');
  
  try {
    // 首先检查基础健康端点
    const healthResponse = await client.get(`${CONFIG.aiAPIURL}/api/v1/health`);
    
    if (healthResponse.status === 200) {
      success('AI API健康检查通过');
      
      // 进一步测试聊天API
      try {
        const chatResponse = await client.post(`${CONFIG.aiAPIURL}/api/v1/chat/send`, {
          message: 'health check test',
          stream: false
        }, {
          headers: {
            'Content-Type': 'application/json'
          }
        });
        
        if (chatResponse.status === 200 || chatResponse.status === 201) {
          success('AI聊天API正常工作');
          healthReport.checks.aiAPI = {
            status: 'healthy',
            healthCheck: true,
            chatAPI: true,
            responseTime: chatResponse.headers['x-response-time'] || 'unknown'
          };
          return true;
        }
      } catch (chatErr) {
        warning('AI聊天API测试失败，但基础服务正常');
        healthReport.checks.aiAPI = {
          status: 'degraded',
          healthCheck: true,
          chatAPI: false,
          chatError: chatErr.message
        };
        return false;
      }
    }
  } catch (err) {
    // 如果健康检查失败，尝试检查服务是否在线
    try {
      await client.get(CONFIG.aiAPIURL);
      warning('AI API在线但健康检查失败');
      healthReport.checks.aiAPI = {
        status: 'degraded',
        online: true,
        healthCheck: false,
        error: err.message
      };
      return false;
    } catch (connectErr) {
      error(`AI API无法连接: ${err.message}`);
      healthReport.checks.aiAPI = {
        status: 'unhealthy',
        online: false,
        error: err.message
      };
      return false;
    }
  }
}

/**
 * 检查构建产物是否存在
 */
async function checkBuildArtifacts() {
  info('检查构建产物...');
  
  const criticalFiles = [
    'dist/index.html',
    'dist/assets',
    'public/ai' // DB-GPT集成产物
  ];
  
  const results = {};
  let allPresent = true;
  
  for (const file of criticalFiles) {
    const fullPath = path.resolve(file);
    const exists = fs.existsSync(fullPath);
    
    results[file] = exists;
    
    if (exists) {
      success(`构建产物存在: ${file}`);
    } else {
      error(`构建产物缺失: ${file}`);
      allPresent = false;
    }
  }
  
  healthReport.checks.buildArtifacts = {
    status: allPresent ? 'healthy' : 'unhealthy',
    files: results
  };
  
  return allPresent;
}

/**
 * 检查关键配置文件
 */
async function checkConfiguration() {
  info('检查配置文件...');
  
  const configFiles = [
    'package.json',
    'vite.config.ts',
    'tsconfig.json'
  ];
  
  const results = {};
  let allValid = true;
  
  for (const file of configFiles) {
    try {
      if (fs.existsSync(file)) {
        if (file.endsWith('.json')) {
          // 验证JSON格式
          const content = fs.readFileSync(file, 'utf8');
          JSON.parse(content);
        }
        results[file] = 'valid';
        success(`配置文件有效: ${file}`);
      } else {
        results[file] = 'missing';
        error(`配置文件缺失: ${file}`);
        allValid = false;
      }
    } catch (err) {
      results[file] = 'invalid';
      error(`配置文件无效: ${file} - ${err.message}`);
      allValid = false;
    }
  }
  
  healthReport.checks.configuration = {
    status: allValid ? 'healthy' : 'unhealthy',
    files: results
  };
  
  return allValid;
}

/**
 * 检查端口占用情况
 */
async function checkPorts() {
  info('检查端口占用情况...');
  
  const ports = [
    { port: 5173, service: 'Frontend Dev Server' },
    { port: 5000, service: 'AI API Server' },
    { port: 80, service: 'Dify Platform' }
  ];
  
  const results = {};
  
  for (const { port, service } of ports) {
    try {
      const response = await client.get(`http://localhost:${port}`, {
        timeout: 2000
      });
      
      results[port] = {
        service,
        status: 'active',
        statusCode: response.status
      };
      success(`${service} (端口 ${port}) 正常运行`);
    } catch (err) {
      if (err.code === 'ECONNREFUSED') {
        results[port] = {
          service,
          status: 'inactive'
        };
        warning(`${service} (端口 ${port}) 未运行`);
      } else {
        results[port] = {
          service,
          status: 'error',
          error: err.message
        };
        error(`${service} (端口 ${port}) 检查失败: ${err.message}`);
      }
    }
  }
  
  healthReport.checks.ports = {
    status: 'informational',
    ports: results
  };
  
  return true; // 端口检查不影响整体健康状态
}

/**
 * 检查依赖状态
 */
async function checkDependencies() {
  info('检查依赖状态...');
  
  try {
    const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    const nodeModulesExists = fs.existsSync('node_modules');
    const lockFileExists = fs.existsSync('package-lock.json') || fs.existsSync('yarn.lock');
    
    const depCount = Object.keys(packageJson.dependencies || {}).length;
    const devDepCount = Object.keys(packageJson.devDependencies || {}).length;
    
    healthReport.checks.dependencies = {
      status: nodeModulesExists ? 'healthy' : 'unhealthy',
      nodeModulesExists,
      lockFileExists,
      dependencyCount: depCount,
      devDependencyCount: devDepCount
    };
    
    if (nodeModulesExists) {
      success(`依赖已安装 (${depCount} 生产依赖, ${devDepCount} 开发依赖)`);
      return true;
    } else {
      error('node_modules 目录不存在，请运行 npm install');
      return false;
    }
  } catch (err) {
    error(`依赖检查失败: ${err.message}`);
    healthReport.checks.dependencies = {
      status: 'unhealthy',
      error: err.message
    };
    return false;
  }
}

/**
 * 生成总体健康状态
 */
function generateOverallStatus() {
  const checks = Object.values(healthReport.checks);
  const healthyCount = checks.filter(check => check.status === 'healthy').length;
  const unhealthyCount = checks.filter(check => check.status === 'unhealthy').length;
  const degradedCount = checks.filter(check => check.status === 'degraded').length;
  
  if (unhealthyCount > 0) {
    healthReport.overall = 'unhealthy';
    error(`整体状态: 不健康 (${unhealthyCount} 个检查失败)`);
  } else if (degradedCount > 0) {
    healthReport.overall = 'degraded';
    warning(`整体状态: 降级 (${degradedCount} 个检查降级)`);
  } else {
    healthReport.overall = 'healthy';
    success(`整体状态: 健康 (${healthyCount} 个检查通过)`);
  }
}

/**
 * 保存健康检查报告
 */
function saveReport() {
  try {
    const reportsDir = path.dirname(CONFIG.outputFile);
    if (!fs.existsSync(reportsDir)) {
      fs.mkdirSync(reportsDir, { recursive: true });
    }
    
    fs.writeFileSync(CONFIG.outputFile, JSON.stringify(healthReport, null, 2));
    info(`健康检查报告已保存到: ${CONFIG.outputFile}`);
  } catch (err) {
    warning(`保存报告失败: ${err.message}`);
  }
}

/**
 * 主函数
 */
async function main() {
  console.log('\n🏥 开始健康检查...\n');
  
  const checks = [
    checkConfiguration,
    checkDependencies,
    checkBuildArtifacts,
    checkFrontendHealth,
    checkAIAPIHealth,
    checkPorts
  ];
  
  for (const check of checks) {
    try {
      await check();
    } catch (err) {
      error(`检查失败: ${err.message}`);
    }
    console.log(''); // 添加空行
  }
  
  generateOverallStatus();
  saveReport();
  
  console.log('\n📊 健康检查完成\n');
  
  // 根据整体状态设置退出码
  if (healthReport.overall === 'unhealthy') {
    process.exit(1);
  } else if (healthReport.overall === 'degraded') {
    process.exit(2);
  } else {
    process.exit(0);
  }
}

// 错误处理
process.on('unhandledRejection', (reason, promise) => {
  error(`未处理的Promise拒绝: ${reason}`);
  process.exit(1);
});

process.on('uncaughtException', (err) => {
  error(`未捕获的异常: ${err.message}`);
  process.exit(1);
});

// 运行健康检查
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(err => {
    error(`健康检查失败: ${err.message}`);
    process.exit(1);
  });
}

export {
  main as healthCheck,
  CONFIG
};