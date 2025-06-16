/**
 * 统一主题配置
 * 所有颜色定义的唯一来源，确保 CSS 变量、Tailwind 和 Ant Design 主题一致
 */

// 基础颜色定义
export const baseColors = {
  // 主色调 - 抖音红
  primary: {
    50: '#fef2f2',
    100: '#fee2e2',
    200: '#fecaca',
    300: '#fca5a5',
    400: '#f87171',
    500: '#ef4444', // 主色
    600: '#dc2626',
    700: '#b91c1c',
    800: '#991b1b',
    900: '#7f1d1d',
  },
  // 辅助色 - 科技蓝
  secondary: {
    50: '#eff6ff',
    100: '#dbeafe',
    200: '#bfdbfe',
    300: '#93c5fd',
    400: '#60a5fa',
    500: '#3b82f6',
    600: '#2563eb',
    700: '#1d4ed8',
    800: '#1e40af',
    900: '#1e3a8a',
  },
  // 成功色
  success: {
    50: '#f0fdf4',
    100: '#dcfce7',
    200: '#bbf7d0',
    300: '#86efac',
    400: '#4ade80',
    500: '#22c55e',
    600: '#16a34a',
    700: '#15803d',
    800: '#166534',
    900: '#14532d',
  },
  // 警告色
  warning: {
    50: '#fffbeb',
    100: '#fef3c7',
    200: '#fde68a',
    300: '#fcd34d',
    400: '#fbbf24',
    500: '#f59e0b',
    600: '#d97706',
    700: '#b45309',
    800: '#92400e',
    900: '#78350f',
  },
  // 错误色
  error: {
    50: '#fef2f2',
    100: '#fee2e2',
    200: '#fecaca',
    300: '#fca5a5',
    400: '#f87171',
    500: '#ef4444',
    600: '#dc2626',
    700: '#b91c1c',
    800: '#991b1b',
    900: '#7f1d1d',
  },
  // 信息色
  info: {
    50: '#eff6ff',
    100: '#dbeafe',
    200: '#bfdbfe',
    300: '#93c5fd',
    400: '#60a5fa',
    500: '#3b82f6',
    600: '#2563eb',
    700: '#1d4ed8',
    800: '#1e40af',
    900: '#1e3a8a',
  },
  // 中性色
  gray: {
    50: '#f9fafb',
    100: '#f3f4f6',
    200: '#e5e7eb',
    300: '#d1d5db',
    400: '#9ca3af',
    500: '#6b7280',
    600: '#4b5563',
    700: '#374151',
    800: '#1f2937',
    900: '#111827',
  },
};

// 语义化颜色定义
export const semanticColors = {
  light: {
    // 背景色
    bg: {
      primary: baseColors.gray[50], // #f9fafb
      secondary: baseColors.gray[100], // #f3f4f6
      card: '#ffffff',
      hover: baseColors.gray[100], // #f3f4f6
      active: baseColors.gray[200], // #e5e7eb
    },
    // 文本色
    text: {
      primary: baseColors.gray[900], // #111827
      secondary: baseColors.gray[600], // #4b5563
      muted: baseColors.gray[400], // #9ca3af
      inverse: '#ffffff',
      disabled: baseColors.gray[300], // #d1d5db
    },
    // 边框色
    border: {
      primary: baseColors.gray[200], // #e5e7eb
      secondary: baseColors.gray[300], // #d1d5db
      focus: baseColors.secondary[500], // #3b82f6
    },
  },
  dark: {
    // 背景色
    bg: {
      primary: baseColors.gray[900], // #111827
      secondary: baseColors.gray[800], // #1f2937
      card: baseColors.gray[800], // #1f2937
      hover: baseColors.gray[700], // #374151
      active: baseColors.gray[600], // #4b5563
    },
    // 文本色
    text: {
      primary: baseColors.gray[50], // #f9fafb
      secondary: baseColors.gray[300], // #d1d5db
      muted: baseColors.gray[400], // #9ca3af
      inverse: baseColors.gray[900], // #111827
      disabled: baseColors.gray[500], // #6b7280
    },
    // 边框色
    border: {
      primary: baseColors.gray[700], // #374151
      secondary: baseColors.gray[600], // #4b5563
      focus: baseColors.secondary[400], // #60a5fa
    },
  },
};

// 其他主题配置
export const themeConfig = {
  // 圆角
  radius: {
    none: '0',
    sm: '0.25rem', // 4px
    base: '0.375rem', // 6px
    md: '0.5rem', // 8px
    lg: '0.75rem', // 12px
    xl: '1rem', // 16px
    '2xl': '1.5rem', // 24px
    '3xl': '2rem', // 32px
    full: '9999px',
  },
  // 间距
  spacing: {
    xs: '0.25rem', // 4px
    sm: '0.5rem', // 8px
    md: '1rem', // 16px
    lg: '1.5rem', // 24px
    xl: '2rem', // 32px
    '2xl': '3rem', // 48px
  },
  // 字体大小
  fontSize: {
    xs: '0.75rem', // 12px
    sm: '0.875rem', // 14px
    base: '1rem', // 16px
    lg: '1.125rem', // 18px
    xl: '1.25rem', // 20px
    '2xl': '1.5rem', // 24px
    '3xl': '1.875rem', // 30px
    '4xl': '2.25rem', // 36px
  },
  // 行高
  lineHeight: {
    tight: '1.25',
    normal: '1.5',
    relaxed: '1.75',
  },
  // 字体
  fontFamily: {
    sans: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    mono: 'JetBrains Mono, Fira Code, Monaco, Consolas, monospace',
  },
  // 阴影
  shadow: {
    sm: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
    base: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
    md: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
    lg: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
    xl: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
  },
  // 暗色模式阴影
  darkShadow: {
    sm: '0 1px 2px 0 rgba(0, 0, 0, 0.3)',
    base: '0 1px 3px 0 rgba(0, 0, 0, 0.4), 0 1px 2px 0 rgba(0, 0, 0, 0.3)',
    md: '0 4px 6px -1px rgba(0, 0, 0, 0.4), 0 2px 4px -1px rgba(0, 0, 0, 0.3)',
    lg: '0 10px 15px -3px rgba(0, 0, 0, 0.5), 0 4px 6px -2px rgba(0, 0, 0, 0.4)',
    xl: '0 20px 25px -5px rgba(0, 0, 0, 0.6), 0 10px 10px -5px rgba(0, 0, 0, 0.5)',
  },
  // Z-index
  zIndex: {
    dropdown: 1000,
    sticky: 1020,
    fixed: 1030,
    modalBackdrop: 1040,
    modal: 1050,
    popover: 1060,
    tooltip: 1070,
    toast: 1080,
  },
};

// 生成 CSS 变量对象
export const getCSSVariables = (isDark: boolean) => {
  const colors = isDark ? semanticColors.dark : semanticColors.light;
  const shadows = isDark ? themeConfig.darkShadow : themeConfig.shadow;

  return {
    // 主色调
    '--primary': baseColors.primary[500],
    '--primary-hover': baseColors.primary[600],
    '--primary-active': baseColors.primary[700],
    '--primary-light': isDark ? baseColors.primary[900] : baseColors.primary[200],
    '--primary-lighter': isDark ? baseColors.primary[800] : baseColors.primary[100],

    // 辅助色
    '--secondary': baseColors.secondary[500],
    '--secondary-hover': baseColors.secondary[600],
    '--secondary-active': baseColors.secondary[700],

    // 功能色
    '--success': baseColors.success[500],
    '--warning': baseColors.warning[500],
    '--error': baseColors.error[500],
    '--info': baseColors.info[500],

    // 背景色
    '--bg-primary': colors.bg.primary,
    '--bg-secondary': colors.bg.secondary,
    '--bg-card': colors.bg.card,
    '--bg-hover': colors.bg.hover,
    '--bg-active': colors.bg.active,

    // 文本色
    '--text-primary': colors.text.primary,
    '--text-secondary': colors.text.secondary,
    '--text-muted': colors.text.muted,
    '--text-inverse': colors.text.inverse,
    '--text-disabled': colors.text.disabled,

    // 边框色
    '--border-primary': colors.border.primary,
    '--border-secondary': colors.border.secondary,
    '--border-focus': colors.border.focus,

    // 阴影
    '--shadow-sm': shadows.sm,
    '--shadow-md': shadows.md,
    '--shadow-lg': shadows.lg,
    '--shadow-xl': shadows.xl,

    // 圆角
    '--radius-sm': themeConfig.radius.sm,
    '--radius-md': themeConfig.radius.md,
    '--radius-lg': themeConfig.radius.lg,
    '--radius-xl': themeConfig.radius.xl,

    // 间距
    '--spacing-xs': themeConfig.spacing.xs,
    '--spacing-sm': themeConfig.spacing.sm,
    '--spacing-md': themeConfig.spacing.md,
    '--spacing-lg': themeConfig.spacing.lg,
    '--spacing-xl': themeConfig.spacing.xl,
    '--spacing-2xl': themeConfig.spacing['2xl'],

    // 字体大小
    '--font-xs': themeConfig.fontSize.xs,
    '--font-sm': themeConfig.fontSize.sm,
    '--font-base': themeConfig.fontSize.base,
    '--font-lg': themeConfig.fontSize.lg,
    '--font-xl': themeConfig.fontSize.xl,
    '--font-2xl': themeConfig.fontSize['2xl'],
    '--font-3xl': themeConfig.fontSize['3xl'],

    // 行高
    '--line-height-tight': themeConfig.lineHeight.tight,
    '--line-height-normal': themeConfig.lineHeight.normal,
    '--line-height-relaxed': themeConfig.lineHeight.relaxed,

    // Z-index
    '--z-dropdown': themeConfig.zIndex.dropdown,
    '--z-sticky': themeConfig.zIndex.sticky,
    '--z-fixed': themeConfig.zIndex.fixed,
    '--z-modal-backdrop': themeConfig.zIndex.modalBackdrop,
    '--z-modal': themeConfig.zIndex.modal,
    '--z-popover': themeConfig.zIndex.popover,
    '--z-tooltip': themeConfig.zIndex.tooltip,
    '--z-toast': themeConfig.zIndex.toast,
  };
};

// 生成 Ant Design 主题配置
export const getAntdTheme = (isDark: boolean) => {
  const colors = isDark ? semanticColors.dark : semanticColors.light;
  const shadows = isDark ? themeConfig.darkShadow : themeConfig.shadow;

  return {
    token: {
      // 主色调
      colorPrimary: baseColors.primary[500],
      colorSuccess: baseColors.success[500],
      colorWarning: baseColors.warning[500],
      colorError: baseColors.error[500],
      colorInfo: baseColors.info[500],

      // 背景色
      colorBgBase: colors.bg.primary,
      colorBgContainer: colors.bg.card,
      colorBgElevated: colors.bg.card,
      colorBgLayout: colors.bg.secondary,

      // 文本色
      colorText: colors.text.primary,
      colorTextSecondary: colors.text.secondary,
      colorTextTertiary: colors.text.muted,
      colorTextQuaternary: colors.text.disabled,

      // 边框色
      colorBorder: colors.border.primary,
      colorBorderSecondary: colors.border.secondary,

      // 圆角
      borderRadius: parseInt(themeConfig.radius.md),
      borderRadiusLG: parseInt(themeConfig.radius.lg),
      borderRadiusSM: parseInt(themeConfig.radius.base),

      // 字体
      fontFamily: themeConfig.fontFamily.sans,
      fontSize: parseInt(themeConfig.fontSize.sm),
      fontSizeLG: parseInt(themeConfig.fontSize.base),
      fontSizeSM: parseInt(themeConfig.fontSize.xs),

      // 间距
      padding: parseInt(themeConfig.spacing.md),
      paddingLG: parseInt(themeConfig.spacing.lg),
      paddingSM: parseInt(themeConfig.spacing.sm),
      paddingXS: parseInt(themeConfig.spacing.xs),

      // 阴影
      boxShadow: shadows.md,
      boxShadowSecondary: shadows.sm,
    },
    components: {
      // Button 组件定制
      Button: {
        borderRadius: parseInt(themeConfig.radius.md),
        controlHeight: 40,
        controlHeightSM: 32,
        controlHeightLG: 48,
      },
      // Input 组件定制
      Input: {
        borderRadius: parseInt(themeConfig.radius.md),
        controlHeight: 40,
        controlHeightSM: 32,
        controlHeightLG: 48,
      },
      // Card 组件定制
      Card: {
        borderRadius: parseInt(themeConfig.radius.lg),
        paddingLG: parseInt(themeConfig.spacing.lg),
      },
      // Menu 组件定制
      Menu: {
        borderRadius: parseInt(themeConfig.radius.md),
        itemBorderRadius: parseInt(themeConfig.radius.base),
      },
      // Table 组件定制
      Table: {
        borderRadius: parseInt(themeConfig.radius.md),
        headerBg: colors.bg.secondary,
      },
      // Modal 组件定制
      Modal: {
        borderRadius: parseInt(themeConfig.radius.lg),
      },
      // Drawer 组件定制
      Drawer: {
        borderRadius: parseInt(themeConfig.radius.lg),
      },
    },
  };
};

// 导出主题管理器
export const themeManager = {
  // 应用 CSS 变量到文档
  applyCSSVariables(isDark: boolean) {
    const variables = getCSSVariables(isDark);
    const root = document.documentElement;

    Object.entries(variables).forEach(([key, value]) => {
      root.style.setProperty(key, value.toString());
    });
  },

  // 设置主题
  setTheme(isDark: boolean) {
    // 设置 HTML 属性
    document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
    document.documentElement.className = isDark ? 'dark' : '';

    // 应用 CSS 变量
    this.applyCSSVariables(isDark);
  },

  // 设置主色调
  setPrimaryColor(color: string) {
    document.documentElement.style.setProperty('--primary', color);
  },
};
