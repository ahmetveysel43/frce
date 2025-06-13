import 'package:flutter/material.dart';

/// Custom painter for logo background pattern
class LogoPatternPainter extends CustomPainter {
  final Color color;

  LogoPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw circuit-like pattern for tech feel
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset(centerX, centerY),
        (size.width / 6) * i,
        paint,
      );
    }
    
    // Draw cross lines
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      paint,
    );
    
    // Draw corner to center lines
    final cornerPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 0.5;
      
    canvas.drawLine(Offset(0, 0), Offset(centerX, centerY), cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(centerX, centerY), cornerPaint);
    canvas.drawLine(Offset(0, size.height), Offset(centerX, centerY), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(centerX, centerY), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}