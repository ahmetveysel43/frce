// lib/presentation/widgets/charts/dual_platform_visualizer.dart - VALD INSPIRED
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/entities/force_data.dart';

class DualPlatformVisualizer extends StatefulWidget {
  final Stream<ForceData>? dataStream;
  final String testType;

  const DualPlatformVisualizer({
    super.key,
    required this.dataStream,
    required this.testType,
  });

  @override
  State<DualPlatformVisualizer> createState() => _DualPlatformVisualizerState();
}

class _DualPlatformVisualizerState extends State<DualPlatformVisualizer> {
  StreamSubscription<ForceData>? _subscription;
  ForceData? _latestData;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void didUpdateWidget(DualPlatformVisualizer oldWidget) {
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
        debugPrint('❌ DualPlatformVisualizer stream error: $error');
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
            child: _buildPlatformVisualization(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.view_column,
            color: Color(0xFF1565C0),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dual Force Platforms',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              Text(
                'Load Cell Distribution & Center of Pressure',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
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
                  'LIVE',
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

  Widget _buildPlatformVisualization() {
    if (_latestData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Waiting for force data...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Stand on the platforms to begin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Left Platform
        Expanded(
          child: _buildSinglePlatform(
            'Left Platform',
            _latestData!.leftGRF,
            _latestData!.leftCoPX,
            _latestData!.leftCoPY,
            [
              _latestData!.leftGRF * 0.3, // TL
              _latestData!.leftGRF * 0.25, // TR  
              _latestData!.leftGRF * 0.2, // BL
              _latestData!.leftGRF * 0.25, // BR
            ],
            const Color(0xFF1565C0),
            Icons.arrow_back,
          ),
        ),
        
        const SizedBox(width: 32),
        
        // Center Info
        _buildCenterInfo(),
        
        const SizedBox(width: 32),
        
        // Right Platform
        Expanded(
          child: _buildSinglePlatform(
            'Right Platform',
            _latestData!.rightGRF,
            _latestData!.rightCoPX,
            _latestData!.rightCoPY,
            [
              _latestData!.rightGRF * 0.25, // TL
              _latestData!.rightGRF * 0.3, // TR
              _latestData!.rightGRF * 0.25, // BL  
              _latestData!.rightGRF * 0.2, // BR
            ],
            Colors.green,
            Icons.arrow_forward,
          ),
        ),
      ],
    );
  }

  Widget _buildSinglePlatform(
    String title,
    double totalForce,
    double copX,
    double copY,
    List<double> loadCellForces,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        // Platform Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Total Force Display
        Text(
          '${totalForce.toStringAsFixed(1)} N',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 16),
        
        // Platform Visualization
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.6, // Platform is taller than wide
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 3),
                borderRadius: BorderRadius.circular(12),
                color: color.withValues(alpha: 0.05),
              ),
              child: Stack(
                children: [
                  // Load Cell Grid (2x2)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final force = loadCellForces[index];
                        final intensity = totalForce > 0 ? (force / totalForce).clamp(0.0, 1.0) : 0.0;
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1 + (intensity * 0.7)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'LC${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${force.toStringAsFixed(0)}N',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Center of Pressure Dot
                  Positioned(
                    left: (copX + 1) * 0.5 * 200 - 6, // Normalize CoP to widget size
                    top: (copY + 1) * 0.5 * 300 - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Crosshairs for CoP reference
                  CustomPaint(
                    size: const Size(200, 300),
                    painter: CrosshairsPainter(color: color.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // CoP Coordinates
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'CoP: X=${copX.toStringAsFixed(2)}, Y=${copY.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterInfo() {
    if (_latestData == null) return const SizedBox.shrink();
    
    final totalGRF = _latestData!.totalGRF;
    final asymmetry = _latestData!.asymmetryIndex;
    final bodyWeight = totalGRF / 9.81;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Total Force
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${totalGRF.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const Text(
                'N',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Body Weight
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Text(
                'Body Weight',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${bodyWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Asymmetry
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (asymmetry < 0.15 ? Colors.green : Colors.orange).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Text(
                'Asymmetry',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(asymmetry * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: asymmetry < 0.15 ? Colors.green : Colors.orange,
                ),
              ),
            ],
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

    // Vertical centerline
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Horizontal centerline
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}