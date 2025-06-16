import { create } from 'zustand';
import { persist } from 'zustand/middleware';

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
      primaryColor: '#ef4444',
      
      toggleTheme: () => {
        const { isDark } = get();
        set({ isDark: !isDark });
        
        // 更新 HTML 属性
        document.documentElement.setAttribute('data-theme', !isDark ? 'dark' : 'light');
        document.documentElement.className = !isDark ? 'dark' : '';
      },
      
      setPrimaryColor: (color: string) => {
        set({ primaryColor: color });
        
        // 更新 CSS 变量
        document.documentElement.style.setProperty('--primary', color);
      },
      
      setTheme: (isDark: boolean) => {
        set({ isDark });
        
        // 更新 HTML 属性
        document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
        document.documentElement.className = isDark ? 'dark' : '';
      },
    }),
    {
      name: 'theme-storage',
      partialize: (state) => ({
        isDark: state.isDark,
        primaryColor: state.primaryColor,
      }),
    }
  )
);
