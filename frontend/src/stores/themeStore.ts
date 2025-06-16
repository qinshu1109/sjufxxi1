import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { themeManager, baseColors } from '@/config/theme.config';

interface ThemeState {
  isDark: boolean;
  primaryColor: string;
  toggleTheme: () => void;
  setPrimaryColor: (color: string) => void;
  setTheme: (isDark: boolean) => void;
}

export const useThemeStore = create<ThemeState>()(
  persist(
    (set, get) => ({
      isDark: false,
      primaryColor: baseColors.primary[500], // 使用统一的颜色定义

      toggleTheme: () => {
        const { isDark } = get();
        const newIsDark = !isDark;
        set({ isDark: newIsDark });

        // 使用统一的主题管理器
        themeManager.setTheme(newIsDark);
      },

      setPrimaryColor: (color: string) => {
        set({ primaryColor: color });

        // 使用统一的主题管理器
        themeManager.setPrimaryColor(color);
      },

      setTheme: (isDark: boolean) => {
        set({ isDark });

        // 使用统一的主题管理器
        themeManager.setTheme(isDark);
      },
    }),
    {
      name: 'theme-storage',
      partialize: (state) => ({
        isDark: state.isDark,
        primaryColor: state.primaryColor,
      }),
    },
  ),
);
