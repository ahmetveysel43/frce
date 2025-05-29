// lib/presentation/widgets/charts/force_symmetry_gauge.dart - YENİ
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../domain/entities/force_data.dart';

class ForceSymmetryGauge extends StatefulWidget {
  final Stream<ForceData>? dataStream;
  final Color primaryColor;
  final Color secondaryColor;

  const ForceSymmetryGauge({
    super.key,
    required this.dataStream,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.red,
  });

  @override
  State<ForceSymmetryGauge> createState() => _ForceSymmetryGaugeState();
}

class _ForceSymmetryGaugeState extends State<ForceSymmetryGauge> 
    with SingleTickerProviderStateMixin {
  StreamSubscription<ForceData>? _subscription;
  ForceData? _latestData;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _startListening();
  }

  @override
  void didUpdateWidget(ForceSymmetryGauge oldWidget) {
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
        // ✅ Layout hatalarını önlemek için addPostFrameCallback kullan
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
        debugPrint('❌ ForceSymmetryGauge stream error: $error');
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
          const SizedBox(height: 16),
          Expanded(
            child: _buildGauge(),
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
          'Simetri',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGauge() {
    if (_latestData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Veri\nbekleniyor',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final asymmetryIndex = _latestData!.asymmetryIndex;
    final symmetryPercentage = ((1.0 - asymmetryIndex) * 100).clamp(0, 100);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: SymmetryGaugePainter(
                      progress: (symmetryPercentage / 100 * _animation.value).toDouble(),
                      primaryColor: widget.primaryColor,
                      secondaryColor: widget.secondaryColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(symmetryPercentage * _animation.value).toInt()}%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _getSymmetryColor(symmetryPercentage.toDouble()),
                            ),
                          ),
                          Text(
                            _getSymmetryLabel(symmetryPercentage.toDouble()),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildForceComparison(),
          ],
        );
      },
    );
  }

  Widget _buildForceComparison() {
    if (_latestData == null) return const SizedBox.shrink();

    final leftForce = _latestData!.leftGRF;
    final rightForce = _latestData!.rightGRF;
    final totalForce = leftForce + rightForce;
    
    final leftPercentage = totalForce > 0 ? (leftForce / totalForce) : 0.5;
    final rightPercentage = totalForce > 0 ? (rightForce / totalForce) : 0.5;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: (leftPercentage * 100).round(),
              child: Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: (rightPercentage * 100).round(),
              child: Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${leftForce.toStringAsFixed(0)}N',
              style: const TextStyle(fontSize: 10, color: Colors.green),
            ),
            Text(
              '${rightForce.toStringAsFixed(0)}N',
              style: const TextStyle(fontSize: 10, color: Colors.purple),
            ),
          ],
        ),
      ],
    );
  }

  Color _getSymmetryColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  String _getSymmetryLabel(double percentage) {
    if (percentage >= 85) return 'Mükemmel';
    if (percentage >= 70) return 'İyi';
    if (percentage >= 50) return 'Orta';
    return 'Zayıf';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}

class SymmetryGaugePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  SymmetryGaugePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    
    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi,
      pi,
      false,
      backgroundPaint,
    );
    
    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Color based on progress
    if (progress >= 0.85) {
      progressPaint.color = Colors.green;
    } else if (progress >= 0.70) {
      progressPaint.color = Colors.orange;
    } else {
      progressPaint.color = Colors.red;
    }
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi,
      pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}