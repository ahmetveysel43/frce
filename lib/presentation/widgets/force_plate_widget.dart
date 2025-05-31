import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/test_controller.dart';
import '../../domain/entities/force_data.dart';

/// Force plate görselleştirme widget'ı
class ForcePlateWidget extends StatelessWidget {
  final double width;
  final double height;
  final bool showCOP;
  final bool showForceValues;
  final bool showAsymmetry;

  const ForcePlateWidget({
    super.key,
    this.width = 300,
    this.height = 200,
    this.showCOP = true,
    this.showForceValues = true,
    this.showAsymmetry = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TestController>(
      builder: (controller) {
        final latestData = controller.forceData.isNotEmpty 
            ? controller.forceData.last 
            : null;
        
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.darkDivider,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Background grid
              _buildGrid(),
              
              // Platform representations
              _buildPlatforms(latestData),
              
              // Center of Pressure indicators
              if (showCOP && latestData != null) 
                _buildCOPIndicators(latestData),
              
              // Force value displays
              if (showForceValues && latestData != null)
                _buildForceDisplays(latestData),
              
              // Asymmetry indicator
              if (showAsymmetry && latestData != null)
                _buildAsymmetryIndicator(latestData),
              
              // Platform labels
              _buildLabels(),
              
              // Connection status overlay
              if (!controller.isConnected)
                _buildDisconnectedOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    return CustomPaint(
      size: Size(width, height),
      painter: GridPainter(),
    );
  }

  Widget _buildPlatforms(ForceData? data) {
    return Positioned.fill(
      child: Row(
        children: [
          // Sol platform
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getPlatformColor(
                  data?.leftGRF ?? 0,
                  AppColors.leftPlatform,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.leftPlatform.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: _buildPlatformContent(
                'SOL',
                data?.leftGRF ?? 0,
                data?.leftLoadPercentage ?? 50,
                AppColors.leftPlatform,
              ),
            ),
          ),
          
          // Orta boşluk
          Container(
            width: 20,
            height: double.infinity,
            child: Center(
              child: Container(
                width: 2,
                height: height * 0.6,
                decoration: BoxDecoration(
                  color: AppTheme.darkDivider,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          
          // Sağ platform
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getPlatformColor(
                  data?.rightGRF ?? 0,
                  AppColors.rightPlatform,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.rightPlatform.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: _buildPlatformContent(
                'SAĞ',
                data?.rightGRF ?? 0,
                data?.rightLoadPercentage ?? 50,
                AppColors.rightPlatform,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformContent(
    String label,
    double force,
    double percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Platform label
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          
          // Force value
          if (showForceValues) ...[
            Text(
              '${force.toStringAsFixed(0)} N',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            
            // Percentage
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCOPIndicators(ForceData data) {
    return Stack(
      children: [
        // Sol platform COP
        if (data.leftCOP_x != null && data.leftCOP_y != null)
          _buildCOPDot(
            data.leftCOP_x!,
            data.leftCOP_y!,
            AppColors.leftPlatform,
            isLeft: true,
          ),
        
        // Sağ platform COP
        if (data.rightCOP_x != null && data.rightCOP_y != null)
          _buildCOPDot(
            data.rightCOP_x!,
            data.rightCOP_y!,
            AppColors.rightPlatform,
            isLeft: false,
          ),
        
        // Combined COP
        if (data.combinedCOP != null)
          _buildCombinedCOP(data.combinedCOP!),
      ],
    );
  }

  Widget _buildCOPDot(double x, double y, Color color, {required bool isLeft}) {
    // Platform coordinates (-200 to 200 mm for 400mm platform)
    // Convert to widget coordinates
    final platformWidth = (width - 52) / 2; // Account for margins and center gap
    final platformHeight = height - 32; // Account for margins
    
    final normalizedX = (x + 200) / 400; // Normalize -200,200 to 0,1
    final normalizedY = (y + 300) / 600; // Normalize -300,300 to 0,1 (600mm length)
    
    final dotX = isLeft 
        ? 16 + (normalizedX * platformWidth)
        : 16 + platformWidth + 20 + (normalizedX * platformWidth);
    final dotY = 16 + (normalizedY * platformHeight);
    
    return Positioned(
      left: dotX - 4,
      top: dotY - 4,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedCOP(({double x, double y}) cop) {
    // Convert combined COP to widget coordinates
    final totalWidth = width - 32;
    final totalHeight = height - 32;
    
    final normalizedX = (cop.x + 400) / 800; // Assuming full width is 800mm
    final normalizedY = (cop.y + 300) / 600;
    
    final dotX = 16 + (normalizedX * totalWidth);
    final dotY = 16 + (normalizedY * totalHeight);
    
    return Positioned(
      left: dotX - 6,
      top: dotY - 6,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.totalForce,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.totalForce.withOpacity(0.6),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForceDisplays(ForceData data) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol platform force
          _buildForceChip(
            'L: ${data.leftGRF.toStringAsFixed(0)}N',
            AppColors.leftPlatform,
          ),
          
          // Total force
          _buildForceChip(
            'Total: ${data.totalGRF.toStringAsFixed(0)}N',
            AppColors.totalForce,
          ),
          
          // Sağ platform force
          _buildForceChip(
            'R: ${data.rightGRF.toStringAsFixed(0)}N',
            AppColors.rightPlatform,
          ),
        ],
      ),
    );
  }

  Widget _buildForceChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAsymmetryIndicator(ForceData data) {
    final asymmetry = data.asymmetryIndex;
    final color = _getAsymmetryColor(asymmetry);
    
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getAsymmetryIcon(asymmetry),
              color: color,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'Asimetri: ${asymmetry.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabels() {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'SOL PLATFORM',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.leftPlatform.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              'SAĞ PLATFORM',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.rightPlatform.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off,
              color: AppTheme.errorColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Platform Bağlantısı Yok',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cihaza bağlanın',
              style: TextStyle(
                color: AppTheme.textHint,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getPlatformColor(double force, Color baseColor) {
    if (force <= 0) return baseColor.withOpacity(0.1);
    
    // Normalize force (0-2000N range)
    final intensity = (force / 2000).clamp(0.0, 1.0);
    return Color.lerp(
      baseColor.withOpacity(0.2),
      baseColor.withOpacity(0.8),
      intensity,
    )!;
  }

  Color _getAsymmetryColor(double asymmetry) {
    if (asymmetry < 5) return AppTheme.successColor;
    if (asymmetry < 10) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  IconData _getAsymmetryIcon(double asymmetry) {
    if (asymmetry < 5) return Icons.check_circle;
    if (asymmetry < 10) return Icons.warning;
    return Icons.error;
  }
}

/// Grid painter for background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.darkDivider.withOpacity(0.3)
      ..strokeWidth = 0.5;

    // Vertical lines
    for (int i = 1; i < 8; i++) {
      final x = (size.width / 8) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (int i = 1; i < 6; i++) {
      final y = (size.height / 6) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact force plate widget for smaller spaces
class CompactForcePlateWidget extends StatelessWidget {
  final double size;
  final bool showValues;

  const CompactForcePlateWidget({
    super.key,
    this.size = 120,
    this.showValues = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TestController>(
      builder: (controller) {
        final latestData = controller.forceData.isNotEmpty 
            ? controller.forceData.last 
            : null;
        
        return Container(
          width: size,
          height: size * 0.6,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.darkDivider),
          ),
          child: Row(
            children: [
              // Sol platform
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getPlatformColor(
                      latestData?.leftGRF ?? 0,
                      AppColors.leftPlatform,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.leftPlatform.withOpacity(0.6),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'L',
                          style: TextStyle(
                            color: AppColors.leftPlatform,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (showValues && latestData != null)
                          Text(
                            '${latestData.leftGRF.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Sağ platform
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getPlatformColor(
                      latestData?.rightGRF ?? 0,
                      AppColors.rightPlatform,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.rightPlatform.withOpacity(0.6),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'R',
                          style: TextStyle(
                            color: AppColors.rightPlatform,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (showValues && latestData != null)
                          Text(
                            '${latestData.rightGRF.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getPlatformColor(double force, Color baseColor) {
    if (force <= 0) return baseColor.withOpacity(0.1);
    
    final intensity = (force / 1000).clamp(0.0, 1.0);
    return Color.lerp(
      baseColor.withOpacity(0.2),
      baseColor.withOpacity(0.8),
      intensity,
    )!;
  }
}

/// Force plate legend widget
class ForcePlateLegend extends StatelessWidget {
  const ForcePlateLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Platform Göstergeleri',
            style: Get.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildLegendItem(
            color: AppColors.leftPlatform,
            label: 'Sol Platform',
            description: 'Sol ayak kuvvet değerleri',
          ),
          const SizedBox(height: 4),
          
          _buildLegendItem(
            color: AppColors.rightPlatform,
            label: 'Sağ Platform',
            description: 'Sağ ayak kuvvet değerleri',
          ),
          const SizedBox(height: 4),
          
          _buildLegendItem(
            color: AppColors.totalForce,
            label: 'Birleşik COP',
            description: 'Toplam basınç merkezi',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}