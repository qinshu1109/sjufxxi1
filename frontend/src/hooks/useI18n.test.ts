import { describe, it, expect } from 'vitest';
import { renderHook } from '@testing-library/react';
import { I18nextProvider } from 'react-i18next';
import i18n from '../i18n';
import { useI18n } from './useI18n';
import React from 'react';

const wrapper = ({ children }: { children: React.ReactNode }) =>
  React.createElement(I18nextProvider, { i18n }, children);

describe('useI18n', () => {
  it('应该返回翻译函数', () => {
    const { result } = renderHook(() => useI18n(), { wrapper });

    expect(result.current.t).toBeDefined();
    expect(typeof result.current.t).toBe('function');
  });

  it('应该返回当前语言', () => {
    const { result } = renderHook(() => useI18n(), { wrapper });

    expect(result.current.language).toBeDefined();
    expect(['zh-CN', 'en-US', 'zh']).toContain(result.current.language);
  });

  it('应该提供切换语言的功能', () => {
    const { result } = renderHook(() => useI18n(), { wrapper });

    expect(result.current.changeLanguage).toBeDefined();
    expect(typeof result.current.changeLanguage).toBe('function');
  });
});
