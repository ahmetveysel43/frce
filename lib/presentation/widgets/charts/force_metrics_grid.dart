// lib/presentation/widgets/charts/force_metrics_grid.dart - VALD INSPIRED
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/entities/force_data.dart';

class ForceMetricsGrid extends StatefulWidget {
  final Stream<ForceData>? dataStream;
  final List<String> selectedMetrics;

  const ForceMetricsGrid({
    super.key,
    required this.dataStream,
    required this.selectedMetrics,
  });

  @override
  State<ForceMetricsGrid> createState() => _ForceMetricsGridState();
}

class _ForceMetricsGridState extends State<ForceMetricsGrid> {
  StreamSubscription<ForceData>? _subscription;
  ForceData? _latestData;

  // Metric definitions - VALD style
  final Map<String, MetricDefinition> _metricDefs = {
    'peak_force': MetricDefinition(
      title: 'Peak Force',
      unit: 'N',
      icon: Icons.trending_up,
      color: const Color(0xFF1565C0),
      getValue: (data) => data.totalGRF,
      getNorm: () => 2500.0, // Example norm
    ),
    'rfd_peak': MetricDefinition(
      title: 'RFD Peak', 
      unit: 'N/s',
      icon: Icons.speed,
      color: Colors.orange,
      getValue: (data) => data.loadRate,
      getNorm: () => 4000.0,
    ),
    'jump_height': MetricDefinition(
      title: 'Jump Height',
      unit: 'cm',
      icon: Icons.height,
      color: Colors.green,
      getValue: (data) => data.totalGRF * 0.01, // Mock calculation
      getNorm: () => 35.0,
    ),
    'takeoff_velocity': MetricDefinition(
      title: 'Takeoff Velocity',
      unit: 'm/s',
      icon: Icons.rocket_launch,
      color: Colors.purple,
      getValue: (data) => data.totalGRF * 0.001, // Mock calculation
      getNorm: () => 2.5,
    ),
    'impulse_100ms': MetricDefinition(
      title: 'Impulse 100ms',
      unit: 'N·s',
      icon: Icons.flash_on,
      color: Colors.red,
      getValue: (data) => data.totalGRF * 0.1,
      getNorm: () => 250.0,
    ),
    'landing_rfd': MetricDefinition(
      title: 'Landing RFD',
      unit: 'N/s',
      icon: Icons.arrow_downward,
      color: Colors.teal,
      getValue: (data) => data.loadRate * 0.8,
      getNorm: () => 3000.0,
    ),
  };

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void didUpdateWidget(ForceMetricsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataStream != widget.dataStream) {
      _subscription?.cancel();
      _startListening();
    }
  }

  void _startListening() {
    if (widget.dataStream == null) return;
    
    _subscription = widget.dataStream!.listen(
      (forceData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _latestData = forceData;
            });
          }
        });
      },
      onError: (error) {
        debugPrint('❌ ForceMetricsGrid stream error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(height: 20),
          Expanded(
            child: _buildMetricsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.dashboard, color: Color(0xFF1565C0), size: 20),
        SizedBox(width: 8),
        Text(
          'Live Metrics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    if (_latestData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Waiting for data...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: widget.selectedMetrics.length,
      itemBuilder: (context, index) {
        final metricKey = widget.selectedMetrics[index];
        final metric = _metricDefs[metricKey];
        
        if (metric == null) return const SizedBox.shrink();
        
        return _buildMetricCard(metric, _latestData!);
      },
    );
  }

  Widget _buildMetricCard(MetricDefinition metric, ForceData data) {
    final value = metric.getValue(data);
    final norm = metric.getNorm();
    final percentage = (value / norm).clamp(0.0, 1.0);
    final isGood = percentage >= 0.8;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: metric.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and norm indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  metric.icon,
                  color: metric.color,
                  size: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isGood ? Colors.green : Colors.orange).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(percentage * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isGood ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Value
          Text(
            value.toStringAsFixed(value >= 100 ? 0 : 1),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: metric.color,
            ),
          ),
          
          const SizedBox(height: 2),
          
          // Unit and Title
          Row(
            children: [
              Text(
                metric.unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
            ],
          ),
          
          const SizedBox(height: 6),
          
          Text(
            metric.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          
          const Spacer(),
          
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              widthFactor: percentage,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: metric.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class MetricDefinition {
  final String title;
  final String unit;
  final IconData icon;
  final Color color;
  final double Function(ForceData) getValue;
  final double Function() getNorm;

  MetricDefinition({
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
    required this.getValue,
    required this.getNorm,
  });
}