import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/test_result_model.dart';
import '../theme/app_theme.dart';
import '../../core/utils/app_logger.dart';
import '../../core/constants/metric_constants.dart';

/// Professional sports performance analytics charts
/// Inspired by Hawkin Dynamics, MyLift, Catapult Sports
/// Comprehensive chart widget for all performance visualization needs
class AdvancedChartsWidget extends StatefulWidget {
  final List<TestResultModel> testResults;
  final Map<String, dynamic>? analytics;
  final String chartType;
  final double height;
  final bool showLegend;
  final bool showGrid;
  final bool showTooltips;
  final bool enableInteraction;
  final String? primaryMetric;
  final List<String>? secondaryMetrics;
  final Color? primaryColor;
  final Color? secondaryColor;

  const AdvancedChartsWidget({
    super.key,
    required this.testResults,
    this.analytics,
    this.chartType = 'line',
    this.height = 400,
    this.showLegend = true,
    this.showGrid = true,
    this.showTooltips = true,
    this.enableInteraction = true,
    this.primaryMetric,
    this.secondaryMetrics,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<AdvancedChartsWidget> createState() => _AdvancedChartsWidgetState();
}

class _AdvancedChartsWidgetState extends State<AdvancedChartsWidget> with TickerProviderStateMixin {
  String _selectedMetric = 'jumpHeight';
  String _selectedChartType = 'line';
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Available metrics based on test data
  List<String> _availableMetrics = [];
  
  // Chart data
  final List<FlSpot> _primaryData = [];
  final List<FlSpot> _secondaryData = [];
  double _minY = 0;
  double _maxY = 100;
  
  // For radar chart
  final List<RadarDataPoint> _radarData = [];
  
  // For force-velocity profile
  final List<ScatterSpot> _forceVelocityData = [];

  @override
  void initState() {
    super.initState();
    
    // Validate widget parameters
    if (widget.height <= 0) {
      AppLogger.warning('AdvancedChartsWidget', 'Invalid height provided: ${widget.height}, using default');
    }
    
    if (widget.testResults.isEmpty) {
      AppLogger.warning('AdvancedChartsWidget', 'Empty test results provided to chart widget');
    }
    
    _selectedChartType = widget.chartType;
    _selectedMetric = widget.primaryMetric ?? 'jumpHeight';
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _initializeAvailableMetrics();
    _prepareChartData();
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _initializeAvailableMetrics() {
    if (widget.testResults.isEmpty) return;
    
    // Get all unique metrics from test results
    final metricsSet = <String>{};
    for (final result in widget.testResults) {
      metricsSet.addAll(result.metrics.keys);
    }
    
    _availableMetrics = metricsSet.toList()..sort();
    
    // Ensure selected metric is available
    if (!_availableMetrics.contains(_selectedMetric)) {
      _selectedMetric = _availableMetrics.isNotEmpty ? _availableMetrics.first : 'jumpHeight';
    }
  }
  
  void _prepareChartData() {
    if (widget.testResults.isEmpty) {
      AppLogger.warning('AdvancedChartsWidget', 'No test results provided for chart data preparation');
      return;
    }
    
    // Sort by date
    final sortedResults = List<TestResultModel>.from(widget.testResults)
      ..sort((a, b) => a.testDate.compareTo(b.testDate));
    
    // Additional validation: check if results have valid data
    final validResults = sortedResults.where((result) {
      return result.metrics.isNotEmpty && 
             result.metrics.containsKey(_selectedMetric) &&
             result.metrics[_selectedMetric] != null;
    }).toList();
    
    if (validResults.isEmpty) {
      AppLogger.warning('AdvancedChartsWidget', 'No valid test results found for metric: $_selectedMetric');
      _minY = 0;
      _maxY = 100;
      return;
    }
    
    // Prepare primary data
    _primaryData.clear();
    _secondaryData.clear();
    _forceVelocityData.clear();
    
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;
    
    for (int i = 0; i < validResults.length; i++) {
      final result = validResults[i];
      double value = result.metrics[_selectedMetric] ?? 0.0;
      
      // Safety check for extreme values
      if (!value.isFinite || value.isNaN) {
        value = 0.0;
      }
      
      // Clamp values to reasonable ranges to prevent invalid arguments
      value = value.clamp(-10000.0, 10000.0);
      
      _primaryData.add(FlSpot(i.toDouble(), value));
      
      // Update min/max with outlier protection
      if (value < minValue) minValue = value;
      if (value > maxValue) maxValue = value;
      
      // Add secondary metric if specified
      if (widget.secondaryMetrics != null && widget.secondaryMetrics!.isNotEmpty) {
        double secondaryValue = result.metrics[widget.secondaryMetrics!.first] ?? 0.0;
        
        // Safety check for secondary values
        if (!secondaryValue.isFinite || secondaryValue.isNaN) {
          secondaryValue = 0.0;
        }
        secondaryValue = secondaryValue.clamp(-10000.0, 10000.0);
        
        _secondaryData.add(FlSpot(i.toDouble(), secondaryValue));
      }
      
      // Prepare force-velocity data if available
      if (result.metrics.containsKey('peakForce') && result.metrics.containsKey('peakVelocity')) {
        _forceVelocityData.add(ScatterSpot(
          result.metrics['peakForce']!,
          result.metrics['peakVelocity']!,
          dotPainter: FlDotCirclePainter(
            radius: 6,
            color: widget.primaryColor ?? AppTheme.primaryColor,
            strokeWidth: 2,
            strokeColor: Colors.white,
          ),
        ));
      }
    }
    
    // Set Y-axis bounds with padding and safety checks
    if (minValue == double.infinity || maxValue == double.negativeInfinity) {
      // No valid data points
      _minY = 0;
      _maxY = 100;
    } else if (maxValue == minValue) {
      _minY = maxValue > 0 ? 0 : maxValue - 10;
      _maxY = maxValue > 0 ? maxValue + 10 : 10;
    } else {
      final range = maxValue - minValue;
      final padding = range * 0.1;
      _minY = (minValue - padding).floorToDouble();
      _maxY = (maxValue + padding).ceilToDouble();
    }
    
    // Safety clamps to prevent invalid chart arguments
    _minY = _minY.clamp(-50000.0, 50000.0);
    _maxY = _maxY.clamp(-50000.0, 50000.0);
    
    // Ensure minimum range for chart display
    if ((_maxY - _minY) < 1) {
      final center = (_maxY + _minY) / 2;
      _minY = center - 5;
      _maxY = center + 5;
    }
    
    // Final safety check
    if (!_minY.isFinite || !_maxY.isFinite || _minY.isNaN || _maxY.isNaN) {
      _minY = 0;
      _maxY = 100;
    }
    
    // Prepare radar data
    _prepareRadarData();
  }
  
  void _prepareRadarData() {
    if (widget.testResults.isEmpty) return;
    
    // Calculate average values for radar chart
    final latestResult = widget.testResults.last;
    final metrics = ['jumpHeight', 'peakForce', 'power', 'rfd', 'flightTime'];
    
    _radarData.clear();
    for (final metric in metrics) {
      final value = latestResult.metrics[metric] ?? 0.0;
      final normalizedValue = _normalizeForRadar(metric, value);
      _radarData.add(RadarDataPoint(
        label: _getMetricLabel(metric),
        value: normalizedValue,
        color: widget.primaryColor ?? AppTheme.primaryColor,
      ));
    }
  }
  
  double _normalizeForRadar(String metric, double value) {
    // Normalize values to 0-100 scale based on typical ranges
    switch (metric) {
      case 'jumpHeight':
        return (value / 60) * 100; // 60cm max
      case 'peakForce':
        return (value / 3000) * 100; // 3000N max
      case 'power':
        return (value / 5000) * 100; // 5000W max
      case 'rfd':
        return (value / 20000) * 100; // 20000 N/s max
      case 'flightTime':
        return (value / 800) * 100; // 800ms max
      default:
        return value;
    }
  }
  
  String _getMetricLabel(String metric) {
    final metricInfo = MetricConstants.getMetricInfo(metric);
    return metricInfo?.displayName ?? metric;
  }
  
  double _getHorizontalInterval() {
    final range = _maxY - _minY;
    if (range <= 0 || !range.isFinite || range.isNaN || _maxY.isInfinite || _minY.isInfinite) {
      AppLogger.warning('AdvancedChartsWidget', 'Invalid range for horizontal interval: range=$range, _minY=$_minY, _maxY=$_maxY');
      return 20.0; // Default safe interval
    }
    
    double interval = range / 4;
    
    // Clamp to reasonable values
    interval = interval.clamp(0.1, 10000.0);
    
    // Final safety check
    if (!interval.isFinite || interval.isNaN || interval <= 0) {
      AppLogger.warning('AdvancedChartsWidget', 'Invalid calculated interval: $interval, using default');
      return 20.0;
    }
    
    return interval;
  }

  // 🎯 PROFESSIONAL CHART HELPERS - Inspired by Hawkin Dynamics & MyLift
  
  /// Smart value formatting for axis labels (prevents overlap and improves readability)
  String _formatAxisValue(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else if (value.abs() >= 100) {
      return value.toStringAsFixed(0);
    } else if (value.abs() >= 10) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  /// Performance-based color coding (like professional sports apps)
  Color _getPerformanceColor(double value, double min, double max) {
    if (max == min) return widget.primaryColor ?? AppTheme.primaryColor;
    
    final normalized = (value - min) / (max - min);
    if (normalized >= 0.8) return const Color(0xFF4CAF50); // Excellent - Green
    if (normalized >= 0.6) return const Color(0xFF8BC34A); // Good - Light Green  
    if (normalized >= 0.4) return const Color(0xFFFF9800); // Average - Orange
    if (normalized >= 0.2) return const Color(0xFFFF5722); // Below Average - Deep Orange
    return const Color(0xFFF44336); // Poor - Red
  }

  /// Smart date formatting for X-axis (prevents overlap)
  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final daysDiff = now.difference(date).inDays;
    
    if (daysDiff < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else if (daysDiff < 90) {
      return '${date.day}/${date.month}';
    } else {
      return '${date.month}/${date.year.toString().substring(2)}';
    }
  }



  @override
  Widget build(BuildContext context) {
    AppLogger.info('AdvancedChartsWidget', 'Building chart with ${widget.testResults.length} test results');
    AppLogger.info('AdvancedChartsWidget', 'Chart type: ${widget.chartType}, Selected metric: $_selectedMetric');
    
    if (widget.testResults.isEmpty) {
      AppLogger.warning('AdvancedChartsWidget', 'No test results provided - showing empty state');
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate exact overhead to prevent overflow
        const cardPadding = 24.0; // 12px padding * 2
        const headerHeight = 50.0; // Approximate header height
        const selectorHeight = 40.0; // Approximate selector height
        const spacingTotal = 36.0; // 3 * 12px spacing
        const legendHeight = 40.0; // Legend height when shown
        const minChartHeight = 250.0; // Minimum chart area
        
        // Total overhead calculation
        final totalOverhead = cardPadding + headerHeight + selectorHeight + spacingTotal + 
                             (widget.showLegend ? legendHeight + 12.0 : 0.0);
        
        // Calculate available chart height
        final availableHeight = constraints.maxHeight > 0 ? constraints.maxHeight : widget.height;
        final maxChartHeight = math.max(widget.height - totalOverhead, minChartHeight);
        (availableHeight - totalOverhead).clamp(minChartHeight, maxChartHeight);
        
        return Card(
          elevation: 4,
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight > 0 ? constraints.maxHeight : widget.height,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildMetricSelector(),
                const SizedBox(height: 12),
                Expanded(
                  child: SizedBox(
                    width: constraints.maxWidth - 24,
                    child: _buildChart(),
                  ),
                ),
                if (widget.showLegend) ...[ 
                  const SizedBox(height: 12),
                  _buildLegend(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.all(12),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Veri bulunmuyor',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performans Analizi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.testResults.length} test analiz edildi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _buildChartTypeSelector(),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildChartTypeSelector() {
    final chartTypes = [
      {'type': 'line', 'icon': Icons.show_chart, 'label': 'Trend'},
      {'type': 'bar', 'icon': Icons.bar_chart, 'label': 'Karşılaştır'},
      {'type': 'radar', 'icon': Icons.radar, 'label': 'Profil'},
      {'type': 'scatter', 'icon': Icons.scatter_plot, 'label': 'Kuvvet-Hız'},
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: chartTypes.map((chart) {
            final isSelected = _selectedChartType == chart['type'];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedChartType = chart['type'] as String;
                  _prepareChartData();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  chart['icon'] as IconData,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey[400],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    final metrics = _getAvailableMetrics();
    
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: metrics.map((metric) {
            final isSelected = metric == _selectedMetric;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  metric,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AppTheme.primaryColor : Colors.white70,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMetric = metric;
                      _prepareChartData();
                    });
                  }
                },
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primaryColor,
                backgroundColor: const Color(0xFF2D2D2D),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                  width: 1,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (widget.testResults.isEmpty) {
      return _buildEmptyState();
    }
    
    // Additional validation: check if data is properly prepared
    if (_primaryData.isEmpty && _selectedChartType != 'radar' && _selectedChartType != 'pie') {
      AppLogger.warning('AdvancedChartsWidget', 'No primary data available for chart type: $_selectedChartType');
      return _buildEmptyState();
    }
    
    // Validate chart bounds
    if (!_minY.isFinite || !_maxY.isFinite || _minY.isNaN || _maxY.isNaN) {
      AppLogger.error('AdvancedChartsWidget', 'Invalid chart bounds: _minY=$_minY, _maxY=$_maxY');
      return _buildEmptyState();
    }
    
    try {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          switch (_selectedChartType) {
            case 'bar':
              return _buildAdvancedBarChart();
            case 'radar':
              return _buildRadarChart();
            case 'scatter':
              return _buildForceVelocityProfile();
            case 'pie':
              return _buildPieChart();
            case 'heatmap':
              return _buildHeatmapChart();
            case 'box':
              return _buildBoxPlotChart();
            case 'line':
            default:
              return _buildAdvancedLineChart();
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('AdvancedChartsWidget', 'Error building chart: $e', stackTrace);
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Grafik yüklenirken hata oluştu', style: TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              Text('Hata: ${e.toString()}', 
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildAdvancedLineChart() {
    // Final validation before rendering
    if (_primaryData.isEmpty) {
      AppLogger.warning('AdvancedChartsWidget', 'No primary data available for line chart');
      return _buildEmptyState();
    }
    
    if (!_minY.isFinite || !_maxY.isFinite || _minY >= _maxY) {
      AppLogger.error('AdvancedChartsWidget', 'Invalid Y-axis bounds: min=$_minY, max=$_maxY');
      return _buildEmptyState();
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2D2D2D).withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: widget.showGrid,
              drawVerticalLine: false,
              horizontalInterval: _getHorizontalInterval(),
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[700]!.withValues(alpha: 0.3),
                  strokeWidth: 1,
                  dashArray: [8, 4],
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: _getHorizontalInterval(),
                  getTitlesWidget: (value, meta) {
                    return Container(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        _formatAxisValue(value),
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                  reservedSize: 55,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= _primaryData.length || value.toInt() >= widget.testResults.length) return const SizedBox();
                    
                    // Smart interval calculation based on screen width
                    final screenWidth = MediaQuery.of(context).size.width;
                    final maxLabels = screenWidth > 600 ? 8 : 6;
                    final interval = (_primaryData.length / maxLabels).ceil().clamp(1, _primaryData.length);
                    
                    if (_primaryData.length > maxLabels && value.toInt() % interval != 0) {
                      return const SizedBox();
                    }
                    
                    final result = widget.testResults[value.toInt()];
                    return Container(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.rotate(
                        angle: -0.3, // Slight rotation for better readability
                        child: Text(
                          _formatDateLabel(result.testDate),
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (_primaryData.length - 1).toDouble(),
            minY: _minY,
            maxY: _maxY,
            lineBarsData: [
              LineChartBarData(
                spots: _primaryData.map((spot) => 
                  FlSpot(spot.x, spot.y * _animation.value)
                ).toList(),
                isCurved: true,
                curveSmoothness: 0.3,
                color: widget.primaryColor ?? AppTheme.primaryColor,
                barWidth: MediaQuery.of(context).size.width > 600 ? 4 : 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final isLatest = index == _primaryData.length - 1;
                    return FlDotCirclePainter(
                      radius: isLatest ? 6 : 4,
                      color: isLatest ? 
                        (widget.primaryColor ?? AppTheme.primaryColor) :
                        (widget.primaryColor ?? AppTheme.primaryColor).withValues(alpha: 0.8),
                      strokeWidth: isLatest ? 3 : 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (widget.primaryColor ?? AppTheme.primaryColor).withValues(alpha: 0.3),
                      (widget.primaryColor ?? AppTheme.primaryColor).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: widget.enableInteraction,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF2D2D2D),
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    if (spot.barIndex >= widget.testResults.length) return null;
                    final result = widget.testResults[spot.spotIndex];
                    final metricInfo = MetricConstants.getMetricInfo(_selectedMetric);
                    final unit = metricInfo?.unit ?? '';
                    
                    return LineTooltipItem(
                      '${_formatDateLabel(result.testDate)}\n${_formatAxisValue(spot.y)} $unit\n${result.testType}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    if (widget.chartType == 'pie') {
      return _buildPieLegend();
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _selectedMetric,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPieLegend() {
    // For pie charts, show performance distribution legend
    final excellentCount = widget.testResults.where((r) => (r.score ?? 0) >= 90).length;
    final goodCount = widget.testResults.where((r) => (r.score ?? 0) >= 70 && (r.score ?? 0) < 90).length;
    final averageCount = widget.testResults.where((r) => (r.score ?? 0) >= 50 && (r.score ?? 0) < 70).length;
    final poorCount = widget.testResults.where((r) => (r.score ?? 0) < 50).length;
    
    final categories = <MapEntry<String, int>>[];
    if (excellentCount > 0) categories.add(MapEntry('Mükemmel (90-100)', excellentCount));
    if (goodCount > 0) categories.add(MapEntry('İyi (70-89)', goodCount));
    if (averageCount > 0) categories.add(MapEntry('Ortalama (50-69)', averageCount));
    if (poorCount > 0) categories.add(MapEntry('Zayıf (<50)', poorCount));
    
    final colors = [
      const Color(0xFF4CAF50), // Green for excellent
      const Color(0xFF2196F3), // Blue for good
      const Color(0xFFFF9800), // Orange for average
      const Color(0xFFF44336), // Red for poor
    ];
    
    return Wrap(
      alignment: WrapAlignment.center,
      children: categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[index],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${category.key}: ${category.value}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Data processing methods

  List<String> _getAvailableMetrics() {
    return [
      'Genel Performans',
      'Tutarlılık Puanı',
      'Test Puanı',
      'Gelişim Oranı',
    ];
  }


  // Helper method to get metric value from test result






  // Advanced Professional Chart Methods
  
  Widget _buildAdvancedBarChart() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2D2D2D).withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _maxY * 1.1,
            barTouchData: BarTouchData(
              enabled: widget.enableInteraction,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF2D2D2D),
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.all(8),
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (groupIndex >= widget.testResults.length) return null;
                  final result = widget.testResults[groupIndex];
                  final value = rod.toY;
                  final metricInfo = MetricConstants.getMetricInfo(_selectedMetric);
                  final unit = metricInfo?.unit ?? '';
                  
                  return BarTooltipItem(
                    '${_formatDateLabel(result.testDate)}\n${_formatAxisValue(value)} $unit\n${result.testType}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: _getHorizontalInterval(),
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        _formatAxisValue(value),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                  reservedSize: 50,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= _primaryData.length || value.toInt() >= widget.testResults.length) return const SizedBox();
                    
                    // Smart interval calculation based on screen width
                    final screenWidth = MediaQuery.of(context).size.width;
                    final maxLabels = screenWidth > 600 ? 8 : 6;
                    final interval = (_primaryData.length / maxLabels).ceil().clamp(1, _primaryData.length);
                    
                    if (_primaryData.length > maxLabels && value.toInt() % interval != 0) {
                      return const SizedBox();
                    }
                    
                    final result = widget.testResults[value.toInt()];
                    return Container(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.rotate(
                        angle: -0.3, // Slight rotation for better readability
                        child: Text(
                          _formatDateLabel(result.testDate),
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
            ),
            gridData: FlGridData(
              show: widget.showGrid,
              drawVerticalLine: false,
              horizontalInterval: _getHorizontalInterval(),
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[800]!,
                  strokeWidth: 0.5,
                  dashArray: [5, 5],
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: _primaryData.asMap().entries.map((entry) {
              final index = entry.key;
              final spot = entry.value;
              final isLatest = index == _primaryData.length - 1;
              
              // Calculate responsive bar width based on available space
              final screenWidth = MediaQuery.of(context).size.width;
              final chartWidth = screenWidth - 100; // Account for padding and axis labels
              final maxBarWidth = chartWidth / (_primaryData.length * 1.5); // Leave space between bars
              final barWidth = maxBarWidth.clamp(12.0, 40.0); // Min 12px, max 40px
              
              // Use performance-based coloring
              final minValue = _primaryData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
              final maxValue = _primaryData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
              final performanceColor = _getPerformanceColor(spot.y, minValue, maxValue);
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: spot.y * _animation.value,
                    color: isLatest ? performanceColor : performanceColor.withValues(alpha: 0.8),
                    width: barWidth,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(barWidth * 0.2), // Proportional rounding
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: _maxY,
                      color: Colors.grey[800]!.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRadarChart() {
    if (_radarData.isEmpty) return _buildEmptyState();
    
    return Container(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [
            Color(0xFF2D2D2D),
            Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            radarBackgroundColor: Colors.transparent,
            borderData: FlBorderData(show: false),
            radarBorderData: const BorderSide(color: Colors.transparent),
            titlePositionPercentageOffset: 0.2,
            titleTextStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            getTitle: (index, angle) {
              if (index >= _radarData.length) return const RadarChartTitle(text: '');
              return RadarChartTitle(
                text: _radarData[index].label,
                angle: 0,
              );
            },
            tickCount: 5,
            ticksTextStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            tickBorderData: BorderSide(
              color: Colors.grey[700]!,
              width: 0.5,
            ),
            gridBorderData: BorderSide(
              color: Colors.grey[700]!,
              width: 0.5,
            ),
            dataSets: [
              RadarDataSet(
                fillColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                borderColor: AppTheme.primaryColor,
                borderWidth: 2,
                entryRadius: 4,
                dataEntries: _radarData.map((point) => 
                  RadarEntry(value: point.value * _animation.value)
                ).toList(),
              ),
            ],
          ),
          swapAnimationDuration: const Duration(milliseconds: 400),
          swapAnimationCurve: Curves.easeInOut,
        ),
      ),
    );
  }
  
  Widget _buildForceVelocityProfile() {
    if (_forceVelocityData.isEmpty) {
      return Center(
        child: Text(
          'Yetersiz kuvvet-hız verisi',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2D2D2D).withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ScatterChart(
          ScatterChartData(
            scatterSpots: _forceVelocityData.map((spot) => 
              ScatterSpot(
                spot.x * _animation.value,
                spot.y * _animation.value,
                dotPainter: spot.dotPainter,
              )
            ).toList(),
            minX: 0,
            maxX: 3500,
            minY: 0,
            maxY: 3.5,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: true,
              horizontalInterval: 0.5,
              verticalInterval: 500,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[800]!,
                  strokeWidth: 0.5,
                  dashArray: [5, 5],
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey[800]!,
                  strokeWidth: 0.5,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                axisNameWidget: const Text(
                  'Hız (m/s)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 0.5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: const Text(
                  'Kuvvet (N)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 500,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            scatterTouchData: ScatterTouchData(
              enabled: widget.enableInteraction,
              touchTooltipData: ScatterTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF2D2D2D),
                tooltipRoundedRadius: 8,
                getTooltipItems: (ScatterSpot touchedSpot) {
                  return ScatterTooltipItem(
                    'Kuvvet: ${touchedSpot.x.toStringAsFixed(0)} N\nH\u0131z: ${touchedSpot.y.toStringAsFixed(2)} m/s',
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeatmapChart() {
    // Implementation for heatmap visualization
    return Center(
      child: Text(
        'Isı haritası görselleştirmesi yakında gelecek',
        style: TextStyle(color: Colors.grey[400]),
      ),
    );
  }
  
  Widget _buildBoxPlotChart() {
    // Implementation for box plot visualization
    return Center(
      child: Text(
        'Kutu grafik görselleştirmesi yakında gelecek',
        style: TextStyle(color: Colors.grey[400]),
      ),
    );
  }
  
  Widget _buildPieChart() {
    if (widget.testResults.isEmpty) return _buildEmptyState();
    
    // Calculate performance distribution data
    final excellentCount = widget.testResults.where((r) => (r.score ?? 0) >= 90).length;
    final goodCount = widget.testResults.where((r) => (r.score ?? 0) >= 70 && (r.score ?? 0) < 90).length;
    final averageCount = widget.testResults.where((r) => (r.score ?? 0) >= 50 && (r.score ?? 0) < 70).length;
    final poorCount = widget.testResults.where((r) => (r.score ?? 0) < 50).length;
    
    final total = excellentCount + goodCount + averageCount + poorCount;
    if (total == 0) return _buildEmptyState();
    
    final pieData = [
      if (excellentCount > 0) PieChartSectionData(
        color: const Color(0xFF4CAF50),
        value: excellentCount.toDouble(),
        title: '${(excellentCount / total * 100).toStringAsFixed(1)}%',
        radius: (60 * _animation.value).clamp(20, 60),
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      ),
      if (goodCount > 0) PieChartSectionData(
        color: const Color(0xFF2196F3),
        value: goodCount.toDouble(),
        title: '${(goodCount / total * 100).toStringAsFixed(1)}%',
        radius: (60 * _animation.value).clamp(20, 60),
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      ),
      if (averageCount > 0) PieChartSectionData(
        color: const Color(0xFFFF9800),
        value: averageCount.toDouble(),
        title: '${(averageCount / total * 100).toStringAsFixed(1)}%',
        radius: (60 * _animation.value).clamp(20, 60),
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      ),
      if (poorCount > 0) PieChartSectionData(
        color: const Color(0xFFF44336),
        value: poorCount.toDouble(),
        title: '${(poorCount / total * 100).toStringAsFixed(1)}%',
        radius: (60 * _animation.value).clamp(20, 60),
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      ),
    ];
    
    return Container(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [
            Color(0xFF2D2D2D),
            Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PieChart(
          PieChartData(
            sections: pieData,
            centerSpaceRadius: 30,
            sectionsSpace: 2,
            startDegreeOffset: -90,
            borderData: FlBorderData(show: false),
            pieTouchData: PieTouchData(
              enabled: widget.enableInteraction,
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                // Handle touch interactions
              },
            ),
          ),
          swapAnimationDuration: const Duration(milliseconds: 600),
          swapAnimationCurve: Curves.easeInOut,
        ),
      ),
    );
  }
}

// Helper class for radar data
class RadarDataPoint {
  final String label;
  final double value;
  final Color color;
  
  RadarDataPoint({
    required this.label,
    required this.value,
    required this.color,
  });
}