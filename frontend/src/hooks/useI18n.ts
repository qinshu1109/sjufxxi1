import { useTranslation } from 'react-i18next';
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface I18nState {
  language: 'zh' | 'en';
  changeLanguage: (lang: 'zh' | 'en') => void;
}

const useI18nStore = create<I18nState>()(
  persist(
    (set) => ({
      language: 'zh',
      changeLanguage: (lang: 'zh' | 'en') => {
        set({ language: lang });
      },
    }),
    {
      name: 'i18n-storage',
    },
  ),
);

export const useI18n = () => {
  const { t, i18n } = useTranslation();
  const { language, changeLanguage: setLanguage } = useI18nStore();

  const changeLanguage = (lang: 'zh' | 'en') => {
    setLanguage(lang);
    i18n.changeLanguage(lang);
  };

  return {
    t,
    language,
    changeLanguage,
    isRTL: false, // 中文和英文都是从左到右
  };
};
