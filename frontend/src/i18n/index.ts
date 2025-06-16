import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

// 语言资源
import zhCN from './locales/zh-CN.json';
import enUS from './locales/en-US.json';

const resources = {
  zh: {
    translation: zhCN,
  },
  en: {
    translation: enUS,
  },
};

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources,
    fallbackLng: 'zh',
    lng: 'zh', // 默认语言
    
    interpolation: {
      escapeValue: false, // React 已经安全处理了
    },
    
    detection: {
      order: ['localStorage', 'navigator', 'htmlTag'],
      caches: ['localStorage'],
    },
    
    react: {
      useSuspense: false,
    },
  });

export default i18n;
