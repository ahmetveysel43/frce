import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/force_data.dart';
import '../theme/app_theme.dart';
import '../../core/algorithms/real_time_analyzer.dart';

/// Gerçek zamanlı force-time grafiği widget'ı
/// VALD ForceDecks tarzı canlı veri görselleştirme
class RealTimeGraphWidget extends StatefulWidget {
  final Stream<ForceData>? forceDataStream;
  final Stream<RealTimeMetrics>? metricsStream;
  final double height;
  final Duration displayWindow;
  final bool showPhaseOverlay;
  final bool showAsymmetry;
  final bool showMetricsPanel;
  final GraphDisplayMode displayMode;
  
  const RealTimeGraphWidget({
    super.key,
    this.forceDataStream,
    this.metricsStream,
    this.height = 300,
    this.displayWindow = const Duration(seconds: 10),
    this.showPhaseOverlay = true,
    this.showAsymmetry = true,
    this.showMetricsPanel = true,
    this.displayMode = GraphDisplayMode.combined,
  });

  @override
  State<RealTimeGraphWidget> createState() => _RealTimeGraphWidgetState();
}

class _RealTimeGraphWidgetState extends State<RealTimeGraphWidget> 
    with SingleTickerProviderStateMixin {
  // Graph data buffers
  final List<FlSpot> _totalForceData = [];
  final List<FlSpot> _leftForceData = [];
  final List<FlSpot> _rightForceData = [];
  
  // Animation controller
  late AnimationController _animationController;
  
  // Current metrics
  RealTimeMetrics? _currentMetrics;
  double _maxForce = 2000; // Default max
  double _minForce = 0;
  int _dataPointCount = 0;
  DateTime? _startTime;
  
  // Graph settings
// 1 saniye @ 1000Hz
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );
    
    // Force data stream listener
    widget.forceDataStream?.listen((data) {
      _addForceData(data);
    });
    
    // Metrics stream listener
    widget.metricsStream?.listen((metrics) {
      setState(() {
        _currentMetrics = metrics;
      });
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _addForceData(ForceData data) {
    if (!mounted) return;
    
    setState(() {
      _startTime ??= DateTime.fromMillisecondsSinceEpoch(data.timestamp);
      final timeSeconds = (data.timestamp - _startTime!.millisecondsSinceEpoch) / 1000.0;
      
      // Add data points
      _totalForceData.add(FlSpot(timeSeconds, data.totalGRF));
      _leftForceData.add(FlSpot(timeSeconds, data.leftGRF));
      _rightForceData.add(FlSpot(timeSeconds, data.rightGRF));
      
      // Update min/max for auto-scaling
      _maxForce = math.max(_maxForce, data.totalGRF * 1.1);
      _minForce = math.min(_minForce, data.totalGRF * 0.9);
      
      // Keep only recent data points
      final cutoffTime = timeSeconds - widget.displayWindow.inSeconds;
      _totalForceData.removeWhere((spot) => spot.x < cutoffTime);
      _leftForceData.removeWhere((spot) => spot.x < cutoffTime);
      _rightForceData.removeWhere((spot) => spot.x < cutoffTime);
      
      _dataPointCount++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Column(
        children: [
          // Header with live indicators
          if (widget.showMetricsPanel) _buildMetricsPanel(),
          
          // Main graph
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGraph(),
            ),
          ),
          
          // Bottom controls
          _buildControls(),
        ],
      ),
    );
  }
  
  Widget _buildMetricsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Current force
          _buildMetricItem(
            icon: Icons.show_chart,
            label: 'Force',
            value: '${_currentMetrics?.currentForce.toStringAsFixed(0) ?? '0'} N',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 24),
          
          // Peak force
          _buildMetricItem(
            icon: Icons.trending_up,
            label: 'Peak',
            value: '${_currentMetrics?.peakForce.toStringAsFixed(0) ?? '0'} N',
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 24),
          
          // Asymmetry
          if (widget.showAsymmetry) ...[
            _buildMetricItem(
              icon: Icons.balance,
              label: 'Asimetri',
              value: '${_currentMetrics?.asymmetryIndex.toStringAsFixed(1) ?? '0'}%',
              color: _getAsymmetryColor(_currentMetrics?.asymmetryIndex ?? 0),
            ),
            const SizedBox(width: 24),
          ],
          
          // Current phase
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPhaseColor(_currentMetrics?.currentPhase).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPhaseIcon(_currentMetrics?.currentPhase),
                        size: 16,
                        color: _getPhaseColor(_currentMetrics?.currentPhase),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currentMetrics?.currentPhase.turkishName ?? 'Bekleniyor',
                        style: TextStyle(
                          color: _getPhaseColor(_currentMetrics?.currentPhase),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildGraph() {
    if (_totalForceData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: AppTheme.textHint,
            ),
            SizedBox(height: 12),
            Text(
              'Veri bekleniyor...',
              style: TextStyle(
                color: AppTheme.textHint,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return LineChart(
      LineChartData(
        // Grid settings
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 200,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: AppTheme.darkDivider,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(
              color: AppTheme.darkDivider,
              strokeWidth: 1,
            );
          },
        ),
        
        // Titles
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)}s',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 500,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        
        // Border
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppTheme.darkDivider),
        ),
        
        // Min/Max values
        minX: _totalForceData.isNotEmpty 
            ? math.max(0, _totalForceData.last.x - widget.displayWindow.inSeconds)
            : 0,
        maxX: _totalForceData.isNotEmpty 
            ? _totalForceData.last.x 
            : widget.displayWindow.inSeconds.toDouble(),
        minY: _minForce,
        maxY: _maxForce,
        
        // Line data
        lineBarsData: _getLineBarsData(),
        
        // Touch interaction
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppTheme.darkCard,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isLeft = spot.barIndex == 1;
                final isRight = spot.barIndex == 2;
                
                return LineTooltipItem(
                  '${isLeft ? 'Sol' : isRight ? 'Sağ' : 'Toplam'}: ${spot.y.toStringAsFixed(0)} N',
                  TextStyle(
                    color: spot.bar.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 50),
      curve: Curves.linear,
    );
  }
  
  List<LineChartBarData> _getLineBarsData() {
    final lines = <LineChartBarData>[];
    
    // Total force line
    if (widget.displayMode == GraphDisplayMode.combined || 
        widget.displayMode == GraphDisplayMode.totalOnly) {
      lines.add(
        LineChartBarData(
          spots: _totalForceData,
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppTheme.primaryColor,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
      );
    }
    
    // Left/Right force lines
    if (widget.displayMode == GraphDisplayMode.combined || 
        widget.displayMode == GraphDisplayMode.splitLeftRight) {
      lines.add(
        LineChartBarData(
          spots: _leftForceData,
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppColors.leftPlatform,
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
      );
      
      lines.add(
        LineChartBarData(
          spots: _rightForceData,
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppColors.rightPlatform,
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
      );
    }
    
    return lines;
  }
  
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Simple icon buttons for display mode
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeButton(
                icon: Icons.merge_type,
                mode: GraphDisplayMode.combined,
                tooltip: 'Kombine',
              ),
              const SizedBox(width: 4),
              _buildModeButton(
                icon: Icons.show_chart,
                mode: GraphDisplayMode.totalOnly,
                tooltip: 'Toplam',
              ),
              const SizedBox(width: 4),
              _buildModeButton(
                icon: Icons.compare_arrows,
                mode: GraphDisplayMode.splitLeftRight,
                tooltip: 'Sol/Sağ',
              ),
            ],
          ),
          
          const Spacer(),
          
          // Sample rate indicator - ultra compact
          Text(
            '${_dataPointCount > 0 ? (_dataPointCount / (_totalForceData.isNotEmpty ? _totalForceData.last.x : 1)).toStringAsFixed(0) : '0'}Hz',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeButton({
    required IconData icon,
    required GraphDisplayMode mode,
    required String tooltip,
  }) {
    final isSelected = widget.displayMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          // Parent widget should handle this
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.darkDivider,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
  
  // Helper methods
  Color _getAsymmetryColor(double asymmetry) {
    if (asymmetry < 5) return AppTheme.successColor;
    if (asymmetry < 10) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
  
  Color _getPhaseColor(JumpPhase? phase) {
    if (phase == null) return AppTheme.textHint;
    
    switch (phase) {
      case JumpPhase.quietStanding:
        return AppColors.quietStanding;
      case JumpPhase.unloading:
        return AppColors.unloading;
      case JumpPhase.braking:
        return AppColors.braking;
      case JumpPhase.propulsion:
        return AppColors.propulsion;
      case JumpPhase.flight:
        return AppColors.flight;
      case JumpPhase.landing:
        return AppColors.landing;
    }
  }
  
  IconData _getPhaseIcon(JumpPhase? phase) {
    if (phase == null) return Icons.hourglass_empty;
    
    switch (phase) {
      case JumpPhase.quietStanding:
        return Icons.accessibility;
      case JumpPhase.unloading:
        return Icons.keyboard_arrow_down;
      case JumpPhase.braking:
        return Icons.speed;
      case JumpPhase.propulsion:
        return Icons.rocket_launch;
      case JumpPhase.flight:
        return Icons.flight;
      case JumpPhase.landing:
        return Icons.download;
    }
  }
}

/// Grafik görüntüleme modları
enum GraphDisplayMode {
  combined,      // Toplam + Sol/Sağ
  totalOnly,     // Sadece toplam force
  splitLeftRight // Sadece Sol/Sağ ayrı
}

/// Faz işaretleyici
class PhaseMarker {
  final double timeSeconds;
  final JumpPhase phase;
  final Color color;
  
  const PhaseMarker({
    required this.timeSeconds,
    required this.phase,
    required this.color,
  });
}