// lib/presentation/widgets/charts/asymmetry_analyzer.dart - VALD INSPIRED
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/entities/force_data.dart';

class AsymmetryAnalyzer extends StatefulWidget {
  final Stream<ForceData>? dataStream;
  final String testType;

  const AsymmetryAnalyzer({
    super.key,
    required this.dataStream,
    required this.testType,
  });

  @override
  State<AsymmetryAnalyzer> createState() => _AsymmetryAnalyzerState();
}

class _AsymmetryAnalyzerState extends State<AsymmetryAnalyzer> 
    with SingleTickerProviderStateMixin {
  StreamSubscription<ForceData>? _subscription;
  ForceData? _latestData;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _startListening();
  }

  @override
  void didUpdateWidget(AsymmetryAnalyzer oldWidget) {
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
            _animationController.forward();
          }
        });
      },
      onError: (error) {
        debugPrint('❌ AsymmetryAnalyzer stream error: $error');
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
            child: _buildAsymmetryAnalysis(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.balance, color: Colors.orange, size: 20),
        SizedBox(width: 8),
        Text(
          'Asymmetry Analysis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildAsymmetryAnalysis() {
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

    final asymmetryIndex = _latestData!.asymmetryIndex;
    final asymmetryPercentage = asymmetryIndex * 100;
    final isWithinNorm = asymmetryPercentage <= 15.0; // VALD standard: ≤15%
    final leftForce = _latestData!.leftGRF;
    final rightForce = _latestData!.rightGRF;
    final totalForce = leftForce + rightForce;
    
    // Calculate force distribution percentages
    final leftPercentage = totalForce > 0 ? (leftForce / totalForce) * 100 : 50;
    final rightPercentage = totalForce > 0 ? (rightForce / totalForce) * 100 : 50;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            // Asymmetry Gauge
            Expanded(
              flex: 2,
              child: Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: AsymmetryGaugePainter(
                      progress: (asymmetryPercentage / 50) * _animation.value, // Max 50% for gauge
                      isWithinNorm: isWithinNorm,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(asymmetryPercentage * _animation.value).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isWithinNorm ? Colors.green : Colors.orange,
                            ),
                          ),
                          Text(
                            'Asymmetry',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // VALD Standard Reference
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isWithinNorm ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isWithinNorm ? Colors.green : Colors.orange).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isWithinNorm ? Icons.check_circle : Icons.warning,
                    color: isWithinNorm ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VALD Standard: ≤15%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          isWithinNorm ? 'Within normal range' : 'Requires attention',
                          style: TextStyle(
                            fontSize: 10,
                            color: isWithinNorm ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Force Distribution
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Force Distribution',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Left vs Right Force Bars
                Row(
                  children: [
                    Expanded(
                      flex: leftPercentage.round(),
                      child: Container(
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1565C0),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: rightPercentage.round(),
                      child: Container(
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Force Values
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Left: ${leftForce.toStringAsFixed(0)}N',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        Text(
                          '${leftPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Right: ${rightForce.toStringAsFixed(0)}N',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${rightPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Asymmetry Recommendations
            _buildRecommendations(asymmetryPercentage, isWithinNorm),
          ],
        );
      },
    );
  }

  Widget _buildRecommendations(double asymmetryPercentage, bool isWithinNorm) {
    String recommendation;
    IconData icon;
    Color color;
    
    if (asymmetryPercentage <= 10) {
      recommendation = 'Excellent symmetry';
      icon = Icons.star;
      color = Colors.green;
    } else if (asymmetryPercentage <= 15) {
      recommendation = 'Good symmetry';
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (asymmetryPercentage <= 25) {
      recommendation = 'Monitor closely';
      icon = Icons.warning;
      color = Colors.orange;
    } else {
      recommendation = 'Requires intervention';
      icon = Icons.error;
      color = Colors.red;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
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
    _animationController.dispose();
    super.dispose();
  }
}

class AsymmetryGaugePainter extends CustomPainter {
  final double progress;
  final bool isWithinNorm;

  AsymmetryGaugePainter({
    required this.progress,
    required this.isWithinNorm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14, // Start from left
      3.14, // Half circle
      false,
      backgroundPaint,
    );
    
    // Progress arc
    final progressPaint = Paint()
      ..color = isWithinNorm ? Colors.green : Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14,
      3.14 * progress,
      false,
      progressPaint,
    );
    
    // Normal range indicator (15% mark)
    final normalRangeMark = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    final normalRangeAngle = -3.14 + (3.14 * 0.3); // 15% of 50% max = 30% of gauge
    final markStart = Offset(
      center.dx + (radius - 15) * -1, // cos(-π + 30% of π)
      center.dy + (radius - 15) * 0, // sin(-π + 30% of π) 
    );
    final markEnd = Offset(
      center.dx + (radius + 5) * -1,
      center.dy + (radius + 5) * 0,
    );
    
    canvas.drawLine(markStart, markEnd, normalRangeMark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}