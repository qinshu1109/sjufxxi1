"""
趋势检测 AWEL 节点
使用 Prophet 和 Kats 进行时序数据趋势分析和预测
"""

import os
import logging
import pandas as pd
import numpy as np
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
import seaborn as sns
from io import BytesIO
import base64

from dbgpt.core.awel import MapOperator


@dataclass
class TrendDetectionRequest:
    """趋势检测请求"""
    data: List[Dict]
    date_column: str
    value_column: str
    forecast_periods: int = 7
    confidence_interval: float = 0.95
    enable_changepoint_detection: bool = True
    enable_seasonality: bool = True


@dataclass
class TrendResult:
    """趋势分析结果"""
    trend_direction: str  # "上升", "下降", "平稳"
    trend_strength: float  # 0-1
    forecast_values: List[float]
    forecast_dates: List[str]
    changepoints: List[Dict]
    seasonality_components: Dict[str, List[float]]
    chart_base64: str
    confidence_intervals: Dict[str, List[float]]


class TrendDetector:
    """趋势检测器"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self._setup_plotting()
    
    def _setup_plotting(self):
        """设置绘图样式"""
        plt.style.use('seaborn-v0_8')
        sns.set_palette("husl")
        plt.rcParams['font.sans-serif'] = ['SimHei', 'Arial Unicode MS', 'DejaVu Sans']
        plt.rcParams['axes.unicode_minus'] = False
    
    async def detect_trend(self, request: TrendDetectionRequest) -> TrendResult:
        """检测趋势"""
        try:
            # 1. 数据预处理
            df = self._prepare_data(request)
            
            if len(df) < 10:
                raise ValueError(f"数据点不足，至少需要10个数据点，当前只有{len(df)}个")
            
            # 2. 趋势分析
            trend_info = self._analyze_trend(df, request.value_column)
            
            # 3. 使用 Prophet 进行预测
            forecast_result = await self._prophet_forecast(df, request)
            
            # 4. 变点检测
            changepoints = []
            if request.enable_changepoint_detection:
                changepoints = self._detect_changepoints(df, request.value_column)
            
            # 5. 季节性分析
            seasonality = {}
            if request.enable_seasonality:
                seasonality = self._analyze_seasonality(df, request.value_column)
            
            # 6. 生成可视化图表
            chart_base64 = self._generate_chart(
                df, forecast_result, changepoints, request
            )
            
            return TrendResult(
                trend_direction=trend_info["direction"],
                trend_strength=trend_info["strength"],
                forecast_values=forecast_result["values"],
                forecast_dates=forecast_result["dates"],
                changepoints=changepoints,
                seasonality_components=seasonality,
                chart_base64=chart_base64,
                confidence_intervals=forecast_result["confidence_intervals"]
            )
            
        except Exception as e:
            self.logger.error(f"趋势检测失败: {e}")
            raise
    
    def _prepare_data(self, request: TrendDetectionRequest) -> pd.DataFrame:
        """数据预处理"""
        df = pd.DataFrame(request.data)
        
        # 转换日期列
        df[request.date_column] = pd.to_datetime(df[request.date_column])
        
        # 转换数值列
        df[request.value_column] = pd.to_numeric(df[request.value_column], errors='coerce')
        
        # 移除空值
        df = df.dropna(subset=[request.date_column, request.value_column])
        
        # 按日期排序
        df = df.sort_values(request.date_column)
        
        # 重置索引
        df = df.reset_index(drop=True)
        
        return df
    
    def _analyze_trend(self, df: pd.DataFrame, value_column: str) -> Dict[str, Any]:
        """分析趋势方向和强度"""
        values = df[value_column].values
        n = len(values)
        
        if n < 2:
            return {"direction": "平稳", "strength": 0.0}
        
        # 计算线性回归斜率
        x = np.arange(n)
        slope, intercept = np.polyfit(x, values, 1)
        
        # 计算相关系数
        correlation = np.corrcoef(x, values)[0, 1]
        strength = abs(correlation)
        
        # 判断趋势方向
        if slope > 0 and strength > 0.3:
            direction = "上升"
        elif slope < 0 and strength > 0.3:
            direction = "下降"
        else:
            direction = "平稳"
        
        return {
            "direction": direction,
            "strength": strength,
            "slope": slope,
            "correlation": correlation
        }
    
    async def _prophet_forecast(self, df: pd.DataFrame, request: TrendDetectionRequest) -> Dict[str, Any]:
        """使用 Prophet 进行预测"""
        try:
            # 尝试导入 Prophet
            try:
                from prophet import Prophet
            except ImportError:
                self.logger.warning("Prophet 未安装，使用简单线性预测")
                return self._simple_forecast(df, request)
            
            # 准备 Prophet 数据格式
            prophet_df = df[[request.date_column, request.value_column]].copy()
            prophet_df.columns = ['ds', 'y']
            
            # 创建 Prophet 模型
            model = Prophet(
                yearly_seasonality=request.enable_seasonality,
                weekly_seasonality=request.enable_seasonality,
                daily_seasonality=False,
                interval_width=request.confidence_interval,
                changepoint_prior_scale=0.05
            )
            
            # 训练模型
            model.fit(prophet_df)
            
            # 创建未来日期
            future = model.make_future_dataframe(periods=request.forecast_periods)
            
            # 进行预测
            forecast = model.predict(future)
            
            # 提取预测结果
            forecast_start_idx = len(prophet_df)
            forecast_values = forecast['yhat'][forecast_start_idx:].tolist()
            forecast_dates = forecast['ds'][forecast_start_idx:].dt.strftime('%Y-%m-%d').tolist()
            
            # 置信区间
            confidence_intervals = {
                "lower": forecast['yhat_lower'][forecast_start_idx:].tolist(),
                "upper": forecast['yhat_upper'][forecast_start_idx:].tolist()
            }
            
            return {
                "values": forecast_values,
                "dates": forecast_dates,
                "confidence_intervals": confidence_intervals,
                "model": model,
                "forecast_df": forecast
            }
            
        except Exception as e:
            self.logger.error(f"Prophet 预测失败: {e}")
            return self._simple_forecast(df, request)
    
    def _simple_forecast(self, df: pd.DataFrame, request: TrendDetectionRequest) -> Dict[str, Any]:
        """简单线性预测（备用方案）"""
        values = df[request.value_column].values
        dates = df[request.date_column]
        
        # 线性回归
        x = np.arange(len(values))
        slope, intercept = np.polyfit(x, values, 1)
        
        # 预测未来值
        future_x = np.arange(len(values), len(values) + request.forecast_periods)
        forecast_values = (slope * future_x + intercept).tolist()
        
        # 生成未来日期
        last_date = dates.iloc[-1]
        forecast_dates = []
        for i in range(1, request.forecast_periods + 1):
            future_date = last_date + timedelta(days=i)
            forecast_dates.append(future_date.strftime('%Y-%m-%d'))
        
        # 简单置信区间（基于历史标准差）
        std_dev = np.std(values)
        confidence_intervals = {
            "lower": [v - 1.96 * std_dev for v in forecast_values],
            "upper": [v + 1.96 * std_dev for v in forecast_values]
        }
        
        return {
            "values": forecast_values,
            "dates": forecast_dates,
            "confidence_intervals": confidence_intervals
        }
    
    def _detect_changepoints(self, df: pd.DataFrame, value_column: str) -> List[Dict]:
        """检测变点"""
        try:
            # 简单的变点检测算法
            values = df[value_column].values
            dates = df[df.columns[0]]  # 假设第一列是日期
            
            changepoints = []
            window_size = max(5, len(values) // 10)
            
            for i in range(window_size, len(values) - window_size):
                # 计算前后窗口的均值差异
                before_mean = np.mean(values[i-window_size:i])
                after_mean = np.mean(values[i:i+window_size])
                
                # 计算变化幅度
                change_magnitude = abs(after_mean - before_mean) / before_mean if before_mean != 0 else 0
                
                # 如果变化幅度超过阈值，认为是变点
                if change_magnitude > 0.2:  # 20% 变化阈值
                    changepoints.append({
                        "date": dates.iloc[i].strftime('%Y-%m-%d'),
                        "index": i,
                        "change_magnitude": change_magnitude,
                        "direction": "increase" if after_mean > before_mean else "decrease"
                    })
            
            return changepoints
            
        except Exception as e:
            self.logger.error(f"变点检测失败: {e}")
            return []
    
    def _analyze_seasonality(self, df: pd.DataFrame, value_column: str) -> Dict[str, List[float]]:
        """分析季节性"""
        try:
            # 简单的季节性分析
            df_copy = df.copy()
            df_copy['weekday'] = df_copy.iloc[:, 0].dt.dayofweek
            df_copy['month'] = df_copy.iloc[:, 0].dt.month
            
            seasonality = {}
            
            # 周季节性
            weekly_pattern = df_copy.groupby('weekday')[value_column].mean().tolist()
            seasonality['weekly'] = weekly_pattern
            
            # 月季节性
            monthly_pattern = df_copy.groupby('month')[value_column].mean().tolist()
            seasonality['monthly'] = monthly_pattern
            
            return seasonality
            
        except Exception as e:
            self.logger.error(f"季节性分析失败: {e}")
            return {}
    
    def _generate_chart(self, df: pd.DataFrame, forecast_result: Dict, 
                       changepoints: List[Dict], request: TrendDetectionRequest) -> str:
        """生成趋势图表"""
        try:
            fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))
            
            # 主趋势图
            dates = df[request.date_column]
            values = df[request.value_column]
            
            # 绘制历史数据
            ax1.plot(dates, values, 'o-', label='历史数据', linewidth=2, markersize=4)
            
            # 绘制预测数据
            if forecast_result:
                forecast_dates = pd.to_datetime(forecast_result['dates'])
                forecast_values = forecast_result['values']
                
                ax1.plot(forecast_dates, forecast_values, 's--', 
                        label='预测数据', linewidth=2, markersize=4, alpha=0.8)
                
                # 绘制置信区间
                if 'confidence_intervals' in forecast_result:
                    ci = forecast_result['confidence_intervals']
                    ax1.fill_between(forecast_dates, ci['lower'], ci['upper'], 
                                   alpha=0.3, label='置信区间')
            
            # 标记变点
            for cp in changepoints:
                cp_date = pd.to_datetime(cp['date'])
                ax1.axvline(x=cp_date, color='red', linestyle=':', alpha=0.7)
                ax1.annotate(f"变点\n{cp['direction']}", 
                           xy=(cp_date, values.iloc[cp['index']]),
                           xytext=(10, 10), textcoords='offset points',
                           bbox=dict(boxstyle='round,pad=0.3', facecolor='yellow', alpha=0.7),
                           arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0'))
            
            ax1.set_title(f'{request.value_column} 趋势分析', fontsize=14, fontweight='bold')
            ax1.set_xlabel('日期')
            ax1.set_ylabel(request.value_column)
            ax1.legend()
            ax1.grid(True, alpha=0.3)
            
            # 分布图
            ax2.hist(values, bins=20, alpha=0.7, edgecolor='black')
            ax2.set_title('数值分布', fontsize=12)
            ax2.set_xlabel(request.value_column)
            ax2.set_ylabel('频次')
            ax2.grid(True, alpha=0.3)
            
            plt.tight_layout()
            
            # 转换为 base64
            buffer = BytesIO()
            plt.savefig(buffer, format='png', dpi=150, bbox_inches='tight')
            buffer.seek(0)
            chart_base64 = base64.b64encode(buffer.getvalue()).decode()
            plt.close()
            
            return chart_base64
            
        except Exception as e:
            self.logger.error(f"图表生成失败: {e}")
            return ""


class TrendDetectionOperator(MapOperator):
    """趋势检测 AWEL 操作符"""
    
    def __init__(self):
        super().__init__(
            map_function=self._detect_trend,
            task_name="trend_detection"
        )
        self.detector = TrendDetector()
    
    async def _detect_trend(self, context: Dict) -> Dict:
        """执行趋势检测"""
        try:
            # 从查询结果中提取时序数据
            query_result = context.get("query_result", {})
            data = query_result.get("data", [])
            columns = query_result.get("columns", [])
            
            if not data or len(data) < 10:
                context["trend_result"] = {
                    "error": "数据不足，无法进行趋势分析"
                }
                return context
            
            # 自动识别日期和数值列
            date_column, value_column = self._identify_columns(data, columns)
            
            if not date_column or not value_column:
                context["trend_result"] = {
                    "error": "未找到合适的日期列或数值列"
                }
                return context
            
            # 创建趋势检测请求
            trend_request = TrendDetectionRequest(
                data=data,
                date_column=date_column,
                value_column=value_column,
                forecast_periods=7,
                enable_changepoint_detection=True,
                enable_seasonality=True
            )
            
            # 执行趋势检测
            trend_result = await self.detector.detect_trend(trend_request)
            
            context["trend_result"] = {
                "success": True,
                "trend_direction": trend_result.trend_direction,
                "trend_strength": trend_result.trend_strength,
                "forecast": {
                    "values": trend_result.forecast_values,
                    "dates": trend_result.forecast_dates,
                    "confidence_intervals": trend_result.confidence_intervals
                },
                "changepoints": trend_result.changepoints,
                "seasonality": trend_result.seasonality_components,
                "chart": trend_result.chart_base64
            }
            
            return context
            
        except Exception as e:
            logging.error(f"趋势检测操作失败: {e}")
            context["trend_result"] = {
                "error": str(e)
            }
            return context
    
    def _identify_columns(self, data: List[Dict], columns: List[str]) -> Tuple[Optional[str], Optional[str]]:
        """自动识别日期列和数值列"""
        if not data or not columns:
            return None, None
        
        sample_row = data[0]
        date_column = None
        value_column = None
        
        # 查找日期列
        for col in columns:
            if col in sample_row:
                value = sample_row[col]
                if isinstance(value, str):
                    # 尝试解析为日期
                    try:
                        pd.to_datetime(value)
                        date_column = col
                        break
                    except:
                        continue
        
        # 查找数值列
        for col in columns:
            if col != date_column and col in sample_row:
                value = sample_row[col]
                if isinstance(value, (int, float)) or (isinstance(value, str) and value.replace('.', '').isdigit()):
                    value_column = col
                    break
        
        return date_column, value_column
