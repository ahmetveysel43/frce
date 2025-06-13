import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/test_controller.dart';

/// Test fazı gösterge widget'ı - OVERFLOW SORUNU ÇÖZÜLDİ
class PhaseIndicatorWidget extends StatelessWidget {
  final PhaseIndicatorStyle style;
  final bool showPhaseNames;
  final bool showProgress;
  final double height;

  const PhaseIndicatorWidget({
    super.key,
    this.style = PhaseIndicatorStyle.horizontal,
    this.showPhaseNames = true,
    this.showProgress = true,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TestController>(
      builder: (controller) {
        final currentPhase = controller.currentPhase;
        final testType = controller.selectedTestType;
        
        if (testType == null) {
          return _buildEmptyState();
        }
        
        final phases = _getTestPhases(testType);
        
        switch (style) {
          case PhaseIndicatorStyle.horizontal:
            return _buildHorizontalIndicator(phases, currentPhase, controller);
          case PhaseIndicatorStyle.vertical:
            return _buildVerticalIndicator(phases, currentPhase, controller);
          case PhaseIndicatorStyle.circular:
            return _buildCircularIndicator(phases, currentPhase, controller);
          case PhaseIndicatorStyle.compact:
            return _buildCompactIndicator(phases, currentPhase, controller);
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: math.max(height, 60).toDouble(),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Center(
        child: Text(
          'Test türü seçilmedi',
          style: Get.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textHint,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalIndicator(
    List<JumpPhase> phases,
    JumpPhase currentPhase,
    TestController controller,
  ) {
    // Dinamik yükseklik hesaplama - Daha güvenli hesaplama
    double calculatedHeight = 24; // Base padding
    if (showPhaseNames) calculatedHeight += 32; // Header space (reduced)
    calculatedHeight += 45; // Phase indicators space (reduced)  
    if (showProgress) calculatedHeight += 24; // Progress bar space (reduced)
    
    final finalHeight = math.max(height, calculatedHeight + 10); // +10 buffer

    return Container(
      height: finalHeight,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - Kompakt
          if (showPhaseNames) ...[
            SizedBox(
              height: 20, // Reduced from 24
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Test Fazları',
                      style: Get.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11, // Reduced from 12
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildCurrentPhaseChip(currentPhase),
                ],
              ),
            ),
            const SizedBox(height: 6), // Reduced from 8
          ],
          
          // Phase indicators - Scrollable container
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: phases.asMap().entries.map((entry) {
                    final index = entry.key;
                    final phase = entry.value;
                    final isActive = phase == currentPhase;
                    final isCompleted = _isPhaseCompleted(phase, currentPhase, phases);
                    
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPhaseStep(
                          phase: phase,
                          isActive: isActive,
                          isCompleted: isCompleted,
                          showName: showPhaseNames,
                        ),
                        if (index < phases.length - 1)
                          _buildPhaseConnector(isCompleted),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          // Progress bar - Conditional
          if (showProgress) ...[
            const SizedBox(height: 6), // Reduced from 8
            _buildProgressBar(phases, currentPhase, controller),
          ],
        ],
      ),
    );
  }

  Widget _buildVerticalIndicator(
    List<JumpPhase> phases,
    JumpPhase currentPhase,
    TestController controller,
  ) {
    final calculatedHeight = math.max(height, phases.length * 50.0 + 80);
    
    return Container(
      width: 200,
      height: calculatedHeight,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Test Fazları',
            style: Get.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          
          // Phase list - Expanded to fill available space
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: phases.length,
              separatorBuilder: (context, index) => _buildVerticalConnector(
                _isPhaseCompleted(phases[index], currentPhase, phases)
              ),
              itemBuilder: (context, index) {
                final phase = phases[index];
                final isActive = phase == currentPhase;
                final isCompleted = _isPhaseCompleted(phase, currentPhase, phases);
                
                return _buildVerticalPhaseItem(
                  phase: phase,
                  isActive: isActive,
                  isCompleted: isCompleted,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIndicator(
    List<JumpPhase> phases,
    JumpPhase currentPhase,
    TestController controller,
  ) {
    final size = math.max(height, 120).toDouble();
    
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Stack(
        children: [
          // Circular progress
          Center(
            child: SizedBox(
              width: size - 40,
              height: size - 40,
              child: CustomPaint(
                painter: CircularPhasePainter(
                  phases: phases,
                  currentPhase: currentPhase,
                ),
              ),
            ),
          ),
          
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPhaseIcon(currentPhase),
                  color: _getPhaseColor(currentPhase),
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  currentPhase.turkishName,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactIndicator(
    List<JumpPhase> phases,
    JumpPhase currentPhase,
    TestController controller,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Row(
        children: [
          // Current phase icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getPhaseColor(currentPhase).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getPhaseIcon(currentPhase),
              color: _getPhaseColor(currentPhase),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          
          // Phase info - Flexible to prevent overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentPhase.turkishName,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getPhaseDescription(currentPhase),
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Mini progress
          if (showProgress) ...[
            const SizedBox(width: 8),
            _buildMiniProgress(phases, currentPhase),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseStep({
    required JumpPhase phase,
    required bool isActive,
    required bool isCompleted,
    required bool showName,
  }) {
    final color = isActive 
        ? _getPhaseColor(phase)
        : isCompleted 
            ? AppTheme.successColor
            : AppTheme.textHint;
    
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Phase circle
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive || isCompleted 
                  ? color.withValues(alpha: 0.2)
                  : AppTheme.darkBackground,
              border: Border.all(
                color: color,
                width: isActive ? 2 : 1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted 
                  ? Icons.check
                  : _getPhaseIcon(phase),
              color: color,
              size: isActive ? 14 : 12,
            ),
          ),
          
          // Phase name - Only if there's space
          if (showName) ...[
            const SizedBox(height: 4),
            Text(
              _getPhaseShortName(phase),
              style: Get.textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseConnector(bool isCompleted) {
    return Container(
      height: 2,
      width: 12,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.successColor : AppTheme.darkDivider,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildVerticalPhaseItem({
    required JumpPhase phase,
    required bool isActive,
    required bool isCompleted,
  }) {
    final color = isActive 
        ? _getPhaseColor(phase)
        : isCompleted 
            ? AppTheme.successColor
            : AppTheme.textHint;
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Phase indicator
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isActive || isCompleted 
                  ? color.withValues(alpha: 0.2)
                  : AppTheme.darkBackground,
              border: Border.all(color: color, width: 1.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : _getPhaseIcon(phase),
              color: color,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          
          // Phase name
          Expanded(
            child: Text(
              phase.turkishName,
              style: Get.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalConnector(bool isCompleted) {
    return Container(
      width: 2,
      height: 8,
      margin: const EdgeInsets.only(left: 9),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.successColor : AppTheme.darkDivider,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildCurrentPhaseChip(JumpPhase currentPhase) {
    final color = _getPhaseColor(currentPhase);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPhaseIcon(currentPhase),
            color: color,
            size: 10,
          ),
          const SizedBox(width: 4),
          Text(
            _getPhaseShortName(currentPhase),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    List<JumpPhase> phases,
    JumpPhase currentPhase,
    TestController controller,
  ) {
    final currentIndex = phases.indexOf(currentPhase);
    final progress = currentIndex >= 0 ? (currentIndex + 1) / phases.length : 0.0;
    
    return SizedBox(
      height: 18, // Reduced from 20
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İlerleme',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 9, // Reduced from 10
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 9, // Reduced from 10
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3), // Reduced from 4
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.darkDivider,
            valueColor: AlwaysStoppedAnimation(_getPhaseColor(currentPhase)),
            minHeight: 2, // Reduced from 3
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProgress(List<JumpPhase> phases, JumpPhase currentPhase) {
    final currentIndex = phases.indexOf(currentPhase);
    final progress = currentIndex >= 0 ? (currentIndex + 1) / phases.length : 0.0;
    
    return SizedBox(
      width: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.darkDivider,
            valueColor: AlwaysStoppedAnimation(_getPhaseColor(currentPhase)),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<JumpPhase> _getTestPhases(TestType testType) {
    switch (testType.category) {
      case TestCategory.jump:
        return [
          JumpPhase.quietStanding,
          JumpPhase.unloading,
          JumpPhase.braking,
          JumpPhase.propulsion,
          JumpPhase.flight,
          JumpPhase.landing,
        ];
      case TestCategory.strength:
        return [
          JumpPhase.quietStanding,
          JumpPhase.braking, // Force buildup
        ];
      case TestCategory.balance:
        return [
          JumpPhase.quietStanding,
        ];
      case TestCategory.agility:
        return [
          JumpPhase.quietStanding,
          JumpPhase.propulsion,
          JumpPhase.flight,
          JumpPhase.landing,
        ];
    }
  }

  bool _isPhaseCompleted(JumpPhase phase, JumpPhase currentPhase, List<JumpPhase> phases) {
    final phaseIndex = phases.indexOf(phase);
    final currentIndex = phases.indexOf(currentPhase);
    return phaseIndex < currentIndex;
  }

  Color _getPhaseColor(JumpPhase phase) {
    switch (phase) {
      case JumpPhase.quietStanding:
        return AppColors.quietStanding;
      case JumpPhase.unloading:
        return AppColors.unloading;
      case JumpPhase.braking:
        return AppColors.braking;
      case JumpPhase.propulsion:
        return AppColors.propulsion;
      case JumpPhase.flight:
        return AppColors.flight;
      case JumpPhase.landing:
        return AppColors.landing;
    }
  }

  IconData _getPhaseIcon(JumpPhase phase) {
    switch (phase) {
      case JumpPhase.quietStanding:
        return Icons.accessibility;
      case JumpPhase.unloading:
        return Icons.keyboard_arrow_down;
      case JumpPhase.braking:
        return Icons.speed;
      case JumpPhase.propulsion:
        return Icons.rocket_launch;
      case JumpPhase.flight:
        return Icons.flight;
      case JumpPhase.landing:
        return Icons.padding;
    }
  }

  String _getPhaseShortName(JumpPhase phase) {
    switch (phase) {
      case JumpPhase.quietStanding:
        return 'Sakin';
      case JumpPhase.unloading:
        return 'Azalt';
      case JumpPhase.braking:
        return 'Fren';
      case JumpPhase.propulsion:
        return 'İtme';
      case JumpPhase.flight:
        return 'Uçuş';
      case JumpPhase.landing:
        return 'İniş';
    }
  }

  String _getPhaseDescription(JumpPhase phase) {
    switch (phase) {
      case JumpPhase.quietStanding:
        return 'Hareketsiz duruş';
      case JumpPhase.unloading:
        return 'Yük azaltma';
      case JumpPhase.braking:
        return 'Frenleme';
      case JumpPhase.propulsion:
        return 'İtme fazı';
      case JumpPhase.flight:
        return 'Havada kalma';
      case JumpPhase.landing:
        return 'İniş fazı';
    }
  }
}

/// Circular phase painter
class CircularPhasePainter extends CustomPainter {
  final List<JumpPhase> phases;
  final JumpPhase currentPhase;

  CircularPhasePainter({
    required this.phases,
    required this.currentPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final currentIndex = phases.indexOf(currentPhase);
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Background circle
    paint.color = AppTheme.darkDivider;
    canvas.drawCircle(center, radius, paint);

    // Progress arc
    if (currentIndex >= 0) {
      final sweepAngle = (currentIndex + 1) / phases.length * 2 * math.pi;
      paint.color = _getPhaseColor(currentPhase);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Color _getPhaseColor(JumpPhase phase) {
    switch (phase) {
      case JumpPhase.quietStanding:
        return AppColors.quietStanding;
      case JumpPhase.unloading:
        return AppColors.unloading;
      case JumpPhase.braking:
        return AppColors.braking;
      case JumpPhase.propulsion:
        return AppColors.propulsion;
      case JumpPhase.flight:
        return AppColors.flight;
      case JumpPhase.landing:
        return AppColors.landing;
    }
  }
}

/// Phase indicator styles
enum PhaseIndicatorStyle {
  horizontal,
  vertical,
  circular,
  compact,
}