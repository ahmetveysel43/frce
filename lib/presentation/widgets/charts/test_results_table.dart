// lib/presentation/widgets/charts/test_results_table.dart - VALD INSPIRED
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/entities/force_data.dart';

class TestResultsTable extends StatefulWidget {
  final Stream<ForceData>? dataStream;
  final String testType;
  final String selectedMetric;
  final bool showAsymmetry;

  const TestResultsTable({
    super.key,
    required this.dataStream,
    required this.testType,
    required this.selectedMetric,
    required this.showAsymmetry,
  });

  @override
  State<TestResultsTable> createState() => _TestResultsTableState();
}

class _TestResultsTableState extends State<TestResultsTable> {
  StreamSubscription<ForceData>? _subscription;
  final List<TestResult> _results = [];
  int _repCounter = 0;

  final Map<String, String> _metricNames = {
    'jump_height': 'Jump Height (cm)',
    'peak_force': 'Peak Force (N)',
    'rfd_peak': 'RFD Peak (N/s)',
    'impulse_100ms': 'Impulse 100ms (N·s)',
    'takeoff_velocity': 'Takeoff Velocity (m/s)',
    'landing_rfd': 'Landing RFD (N/s)',
    'eccentric_duration': 'Eccentric Duration (ms)',
    'concentric_duration': 'Concentric Duration (ms)',
  };

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void didUpdateWidget(TestResultsTable oldWidget) {
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
        // Simulate rep detection when force exceeds threshold
        if (forceData.totalGRF > 500 && _shouldRecordRep(forceData)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _repCounter++;
                _results.add(TestResult.fromForceData(forceData, _repCounter));
                
                // Keep only last 10 reps
                if (_results.length > 10) {
                  _results.removeAt(0);
                }
              });
            }
          });
        }
      },
      onError: (error) {
        debugPrint('❌ TestResultsTable stream error: $error');
      },
    );
  }

  bool _shouldRecordRep(ForceData data) {
    // Simple rep detection logic - could be more sophisticated
    if (_results.isEmpty) return true;
    
    final lastResult = _results.last;
    final timeDiff = DateTime.now().difference(lastResult.timestamp).inSeconds;
    
    return timeDiff > 2; // At least 2 seconds between reps
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
            child: _buildResultsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.table_chart, color: Color(0xFF1565C0), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Test Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              Text(
                widget.showAsymmetry ? 'Asymmetry View' : 'Performance View',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_results.length} reps',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsTable() {
    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Start testing to see results',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Stand on the platforms and perform movements',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Table Headers
        _buildTableHeaders(),
        
        const SizedBox(height: 12),
        
        // Results List
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final result = _results[_results.length - 1 - index]; // Show newest first
              return _buildResultRow(result, index == 0);
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Summary Statistics
        _buildSummaryStats(),
      ],
    );
  }

  Widget _buildTableHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            child: Text(
              'Rep',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _metricNames[widget.selectedMetric] ?? 'Metric',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
          if (widget.showAsymmetry) ...[
            const Expanded(
              child: Text(
                'Left %',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'Right %',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'Asym %',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ] else ...[
            const Expanded(
              child: Text(
                'Left',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'Right',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ],
          const SizedBox(
            width: 60,
            child: Text(
              'Time',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(TestResult result, bool isLatest) {
    final metricValue = result.getMetricValue(widget.selectedMetric);
    final leftValue = result.leftForce;
    final rightValue = result.rightForce;
    final asymmetry = result.asymmetryPercentage;
    
    // Calculate percentages for asymmetry view
    final totalForce = leftValue + rightValue;
    final leftPercentage = totalForce > 0 ? (leftValue / totalForce) * 100 : 50;
    final rightPercentage = totalForce > 0 ? (rightValue / totalForce) * 100 : 50;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLatest 
            ? const Color(0xFF1565C0).withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: isLatest 
            ? Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${result.repNumber}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                color: isLatest ? const Color(0xFF1565C0) : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              metricValue.toStringAsFixed(metricValue >= 100 ? 0 : 1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                color: isLatest ? const Color(0xFF1565C0) : Colors.grey[700],
              ),
            ),
          ),
          if (widget.showAsymmetry) ...[
            Expanded(
              child: Text(
                '${leftPercentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                  color: isLatest ? const Color(0xFF1565C0) : Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${rightPercentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                  color: isLatest ? Colors.green : Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${asymmetry.toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: asymmetry <= 15 ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                leftValue.toStringAsFixed(0),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                  color: isLatest ? const Color(0xFF1565C0) : Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              child: Text(
                rightValue.toStringAsFixed(0),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                  color: isLatest ? Colors.green : Colors.grey[700],
                ),
              ),
            ),
          ],
          SizedBox(
            width: 60,
            child: Text(
              _formatTime(result.timestamp),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    if (_results.isEmpty) return const SizedBox.shrink();
    
    final values = _results.map((r) => r.getMetricValue(widget.selectedMetric)).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Average', average, const Color(0xFF1565C0)),
          _buildSummaryItem('Maximum', max, Colors.green),
          _buildSummaryItem('Minimum', min, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(value >= 100 ? 0 : 1),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return '${diff.inSeconds}s';
    } else {
      return '${diff.inMinutes}m';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class TestResult {
  final int repNumber;
  final double jumpHeight;
  final double peakForce;
  final double rfdPeak;
  final double impulse100ms;
  final double takeoffVelocity;
  final double landingRfd;
  final double leftForce;
  final double rightForce;
  final double asymmetryPercentage;
  final DateTime timestamp;

  TestResult({
    required this.repNumber,
    required this.jumpHeight,
    required this.peakForce,
    required this.rfdPeak,
    required this.impulse100ms,
    required this.takeoffVelocity,
    required this.landingRfd,
    required this.leftForce,
    required this.rightForce,
    required this.asymmetryPercentage,
    required this.timestamp,
  });

  factory TestResult.fromForceData(ForceData data, int repNumber) {
    return TestResult(
      repNumber: repNumber,
      jumpHeight: data.totalGRF * 0.01, // Mock calculation
      peakForce: data.totalGRF,
      rfdPeak: data.loadRate,
      impulse100ms: data.totalGRF * 0.1,
      takeoffVelocity: data.totalGRF * 0.001,
      landingRfd: data.loadRate * 0.8,
      leftForce: data.leftGRF,
      rightForce: data.rightGRF,
      asymmetryPercentage: data.asymmetryIndex * 100,
      timestamp: DateTime.now(),
    );
  }

  double getMetricValue(String metric) {
    switch (metric) {
      case 'jump_height':
        return jumpHeight;
      case 'peak_force':
        return peakForce;
      case 'rfd_peak':
        return rfdPeak;
      case 'impulse_100ms':
        return impulse100ms;
      case 'takeoff_velocity':
        return takeoffVelocity;
      case 'landing_rfd':
        return landingRfd;
      default:
        return peakForce;
    }
  }
}