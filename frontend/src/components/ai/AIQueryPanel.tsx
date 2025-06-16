import React, { useState } from 'react';
import { dbgptClient } from '@/config/ai-config';

export const AIQueryPanel: React.FC = () => {
  const [question, setQuestion] = useState('');
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const handleQuery = async () => {
    if (!question.trim()) return;

    setLoading(true);
    try {
      // 1. 转换自然语言为 SQL
      const nl2sqlResult = await dbgptClient.nl2sql(question);

      // 2. 执行工作流获取完整结果
      const workflowResult = await dbgptClient.executeWorkflow('nl2sql_pipeline', {
        question,
        database: 'analytics',
      });

      setResult({
        sql: nl2sqlResult.sql,
        explanation: nl2sqlResult.explanation,
        data: workflowResult.result.data,
        confidence: nl2sqlResult.confidence,
      });
    } catch (error) {
      console.error('查询失败:', error);
      setResult({ error: '查询失败，请重试' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="ai-query-panel rounded-lg bg-white p-4 shadow">
      <h3 className="mb-4 text-lg font-semibold">AI 智能查询</h3>

      <div className="mb-4">
        <input
          type="text"
          className="w-full rounded border p-2"
          placeholder="输入您的查询问题，例如：查询销量最高的商品"
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleQuery()}
        />
      </div>

      <button
        className="rounded bg-blue-500 px-4 py-2 text-white hover:bg-blue-600 disabled:opacity-50"
        onClick={handleQuery}
        disabled={loading || !question.trim()}
      >
        {loading ? '查询中...' : '智能查询'}
      </button>

      {result && (
        <div className="mt-4">
          {result.error ? (
            <div className="text-red-500">{result.error}</div>
          ) : (
            <>
              <div className="mb-2">
                <strong>生成的 SQL：</strong>
                <pre className="rounded bg-gray-100 p-2 text-sm">{result.sql}</pre>
              </div>
              <div className="mb-2">
                <strong>解释：</strong> {result.explanation}
              </div>
              <div className="mb-2">
                <strong>置信度：</strong> {(result.confidence * 100).toFixed(1)}%
              </div>
              {result.data && (
                <div>
                  <strong>查询结果：</strong>
                  <div className="overflow-x-auto">
                    <table className="mt-2 min-w-full border">
                      <thead>
                        <tr className="bg-gray-50">
                          {Object.keys(result.data[0] || {}).map((key) => (
                            <th key={key} className="border px-4 py-2">
                              {key}
                            </th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {result.data.map((row: any, idx: number) => (
                          <tr key={idx}>
                            {Object.values(row).map((val: any, i: number) => (
                              <td key={i} className="border px-4 py-2">
                                {String(val)}
                              </td>
                            ))}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      )}
    </div>
  );
};
