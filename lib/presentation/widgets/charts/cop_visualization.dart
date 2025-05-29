// lib/presentation/widgets/charts/cop_visualization.dart - DÜZELTİLMİŞ
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/entities/force_data.dart';

class CoPVisualization extends StatefulWidget {
  final Stream<ForceData>? dataStream;
  final double platformWidth;
  final double platformHeight;

  const CoPVisualization({
    super.key,
    required this.dataStream,
    this.platformWidth = 40.0,
    this.platformHeight = 60.0,
  });

  @override
  State<CoPVisualization> createState() => _CoPVisualizationState();
}

class _CoPVisualizationState extends State<CoPVisualization> {
  StreamSubscription<ForceData>? _subscription;
  ForceData? _latestData;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void didUpdateWidget(CoPVisualization oldWidget) {
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
          }
        });
      },
      onError: (error) {
        debugPrint('❌ CoPVisualization stream error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
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
            child: _buildVisualization(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.my_location, color: Colors.red, size: 24),
        const SizedBox(width: 8),
        const Text(
          'Basınç Merkezi (CoP)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_latestData != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'CANLI',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVisualization() {
    if (_latestData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'CoP verisi bekleniyor...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildPlatformVisualization(
            'Sol Platform',
            _latestData!.leftCoPX,
            _latestData!.leftCoPY,
            _latestData!.leftGRF,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPlatformVisualization(
            'Sağ Platform',
            _latestData!.rightCoPX,
            _latestData!.rightCoPY,
            _latestData!.rightGRF,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformVisualization(
    String title,
    double copX,
    double copY,
    double force,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Stack(
              children: [
                // Platform outline
                Center(
                  child: Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: color, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // CoP point
                Positioned(
                  left: 40 + (copX * 20) - 6, // Center + offset - half dot size
                  top: 60 + (copY * 20) - 6,  // Center + offset - half dot size
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Crosshairs
                Center(
                  child: Container(
                    width: 80,
                    height: 120,
                    child: CustomPaint(
                      painter: CrosshairsPainter(color: color.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${force.toStringAsFixed(0)}N',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'X: ${copX.toStringAsFixed(1)} Y: ${copY.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class CrosshairsPainter extends CustomPainter {
  final Color color;

  CrosshairsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Vertical line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}