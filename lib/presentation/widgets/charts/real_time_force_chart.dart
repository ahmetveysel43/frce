// lib/presentation/widgets/charts/real_time_force_chart.dart - fl_chart 0.66.0 UYUMLU
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/entities/force_data.dart';

class RealTimeForceChart extends StatefulWidget {
  final Stream<ForceData>? dataStream;
  final bool showDualPlatform;
  final Color primaryColor;
  final Color secondaryColor;
  final Duration timeWindow;
  final int maxDataPoints;

  const RealTimeForceChart({
    super.key,
    required this.dataStream,
    this.showDualPlatform = true,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.green,
    this.timeWindow = const Duration(seconds: 10),
    this.maxDataPoints = 1000,
  });

  @override
  State<RealTimeForceChart> createState() => _RealTimeForceChartState();
}

class _RealTimeForceChartState extends State<RealTimeForceChart> {
  StreamSubscription<ForceData>? _subscription;
  final Queue<FlSpot> _totalForceData = Queue<FlSpot>();
  final Queue<FlSpot> _leftForceData = Queue<FlSpot>();
  final Queue<FlSpot> _rightForceData = Queue<FlSpot>();
  
  double _maxX = 10.0;
  double _maxY = 1000.0;
  double _minY = 0.0;
  late DateTime _startTime;
  ForceData? _latestData;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _startListening();
  }

  @override
  void didUpdateWidget(RealTimeForceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataStream != widget.dataStream) {
      _subscription?.cancel();
      _startListening();
    }
  }

  void _startListening() {
    if (widget.dataStream == null) {
      debugPrint('⚠️ RealTimeForceChart: dataStream is null');
      return;
    }
    
    debugPrint('📊 RealTimeForceChart: Starting to listen to data stream');
    
    _subscription = widget.dataStream!.listen(
      (forceData) {
        debugPrint('📊 RealTimeForceChart: Received data - Total: ${forceData.totalGRF}N');
        if (mounted) {
          _addDataPoint(forceData);
        }
      },
      onError: (error) {
        debugPrint('❌ RealTimeForceChart stream error: $error');
      },
      onDone: () {
        debugPrint('📊 RealTimeForceChart: Stream closed');
      },
    );
    
    debugPrint('📊 RealTimeForceChart: Successfully started listening');
  }

  void _addDataPoint(ForceData data) {
    final currentTime = DateTime.now();
    final elapsedSeconds = currentTime.difference(_startTime).inMilliseconds / 1000.0;
    
    // ✅ Layout sırasında setState çağrısını önlemek için WidgetsBinding.instance.addPostFrameCallback kullan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _latestData = data;
          
          // Add new data points
          _totalForceData.add(FlSpot(elapsedSeconds, data.totalGRF));
          
          if (widget.showDualPlatform) {
            _leftForceData.add(FlSpot(elapsedSeconds, data.leftGRF));
            _rightForceData.add(FlSpot(elapsedSeconds, data.rightGRF));
          }
          
          // Remove old data points (keep only points within time window)
          final cutoffTime = elapsedSeconds - widget.timeWindow.inSeconds;
          
          while (_totalForceData.isNotEmpty && _totalForceData.first.x < cutoffTime) {
            _totalForceData.removeFirst();
          }
          
          if (widget.showDualPlatform) {
            while (_leftForceData.isNotEmpty && _leftForceData.first.x < cutoffTime) {
              _leftForceData.removeFirst();
            }
            while (_rightForceData.isNotEmpty && _rightForceData.first.x < cutoffTime) {
              _rightForceData.removeFirst();
            }
          }
          
          // Update chart bounds
          _maxX = elapsedSeconds;
          
          // Auto-scale Y axis
          final allValues = <double>[
            ..._totalForceData.map((spot) => spot.y),
            if (widget.showDualPlatform) ..._leftForceData.map((spot) => spot.y),
            if (widget.showDualPlatform) ..._rightForceData.map((spot) => spot.y),
          ];
          
          if (allValues.isNotEmpty) {
            _maxY = allValues.reduce((a, b) => a > b ? a : b) * 1.1;
            _minY = (allValues.reduce((a, b) => a < b ? a : b) * 0.9).clamp(0, double.infinity);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.show_chart, color: widget.primaryColor, size: 24),
        const SizedBox(width: 8),
        const Text(
          'Gerçek Zamanlı Kuvvet Analizi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_latestData != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'CANLI',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChart() {
    if (_totalForceData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Kuvvet verisi bekleniyor...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          verticalInterval: 1,
          horizontalInterval: _maxY / 5,
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: _maxY / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}N',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}s',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        minX: (_maxX - widget.timeWindow.inSeconds).clamp(0, double.infinity),
        maxX: _maxX,
        minY: _minY,
        maxY: _maxY,
        lineBarsData: _buildLineBarsData(),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87, // ✅ getTooltipColor -> tooltipBgColor
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot; // ✅ barSpot.spot -> barSpot
                String label = 'Toplam: ${flSpot.y.toInt()}N';
                
                if (widget.showDualPlatform && barSpot.barIndex == 0) {
                  label = 'Sol: ${flSpot.y.toInt()}N';
                } else if (widget.showDualPlatform && barSpot.barIndex == 1) {
                  label = 'Sağ: ${flSpot.y.toInt()}N';
                }
                
                return LineTooltipItem(
                  label,
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    final List<LineChartBarData> bars = [];

    if (widget.showDualPlatform) {
      // Sol platform
      bars.add(
        LineChartBarData(
          spots: _leftForceData.toList(),
          color: Colors.green,
          barWidth: 2,  // ✅ fl_chart 0.66.0 için barWidth
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );

      // Sağ platform  
      bars.add(
        LineChartBarData(
          spots: _rightForceData.toList(),
          color: Colors.purple,
          barWidth: 2,  // ✅ fl_chart 0.66.0 için barWidth
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    // Toplam kuvvet (her zaman göster)
    bars.add(
      LineChartBarData(
        spots: _totalForceData.toList(),
        color: widget.primaryColor,
        barWidth: 3,  // ✅ fl_chart 0.66.0 için barWidth
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: widget.primaryColor.withValues(alpha: 0.1),
        ),
      ),
    );

    return bars;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}