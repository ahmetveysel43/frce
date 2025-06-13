import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/test_controller.dart';

/// Metrik gösterim widget'ı - Real-time ve sonuç gösterimi (OVERFLOW FIXED)
class MetricsDisplayWidget extends StatelessWidget {
  final Map<String, double>? metrics;
  final bool isRealTime;
  final MetricDisplayStyle style;
  final int maxMetrics;
  final List<String>? priorityMetrics;

  const MetricsDisplayWidget({
    super.key,
    this.metrics,
    this.isRealTime = false,
    this.style = MetricDisplayStyle.grid,
    this.maxMetrics = 6,
    this.priorityMetrics,
  });

  @override
  Widget build(BuildContext context) {
    if (isRealTime) {
      return GetBuilder<TestController>(
        builder: (controller) {
          final liveMetrics = controller.liveMetrics;
          return _buildMetricsDisplay(liveMetrics);
        },
      );
    } else {
      return _buildMetricsDisplay(metrics ?? {});
    }
  }

  Widget _buildMetricsDisplay(Map<String, double> metricsData) {
    if (metricsData.isEmpty) {
      return _buildEmptyState();
    }

    // Öncelikli metrikleri filtrele ve sırala
    final displayMetrics = _prepareMetricsForDisplay(metricsData);

    switch (style) {
      case MetricDisplayStyle.grid:
        return _buildGridDisplay(displayMetrics);
      case MetricDisplayStyle.list:
        return _buildListDisplay(displayMetrics);
      case MetricDisplayStyle.compact:
        return _buildCompactDisplay(displayMetrics);
      case MetricDisplayStyle.detailed:
        return _buildDetailedDisplay(displayMetrics);
    }
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120, // Fixed height to prevent overflow
      padding: const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics_outlined,
            color: AppTheme.textHint,
            size: 24, // Reduced size
          ),
          const SizedBox(height: 8), // Reduced spacing
          Text(
            isRealTime ? 'Metrikler hesaplanıyor...' : 'Metrik bulunamadı',
            style: Get.textTheme.bodySmall?.copyWith( // Changed to bodySmall
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (isRealTime) ...[
            const SizedBox(height: 8), // Reduced spacing
            const SizedBox(
              width: 16, // Reduced size
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridDisplay(List<MapEntry<String, double>> displayMetrics) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridColumns(),
        childAspectRatio: 1.3, // Increased for better proportion
        crossAxisSpacing: 8, // Reduced spacing
        mainAxisSpacing: 8,
      ),
      itemCount: displayMetrics.length,
      itemBuilder: (context, index) {
        final metric = displayMetrics[index];
        return _buildMetricCard(metric.key, metric.value);
      },
    );
  }

  Widget _buildListDisplay(List<MapEntry<String, double>> displayMetrics) {
    return SingleChildScrollView( // Added scroll view
      child: Column(
        children: displayMetrics.map((metric) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 6), // Reduced spacing
            child: _buildMetricListItem(metric.key, metric.value),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildCompactDisplay(List<MapEntry<String, double>> displayMetrics) {
    return Container(
      height: 80, // Fixed height
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: displayMetrics.take(4).map((metric) => 
          Expanded(
            child: _buildCompactMetricItem(metric.key, metric.value),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildDetailedDisplay(List<MapEntry<String, double>> displayMetrics) {
    return SingleChildScrollView( // CRITICAL: Added scroll view for detailed display
      child: Column(
        children: displayMetrics.map((metric) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8), // Reduced spacing
            child: _buildDetailedMetricCard(metric.key, metric.value),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildMetricCard(String metricName, double value) {
    final metricInfo = _getMetricInfo(metricName);
    final qualityColor = _getMetricQualityColor(metricName, value);
    
    return Container(
      padding: const EdgeInsets.all(8), // Reduced padding
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(10), // Slightly smaller radius
        border: Border.all(
          color: qualityColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Icon(
            metricInfo.icon,
            color: qualityColor,
            size: 18, // Reduced size
          ),
          const SizedBox(height: 4), // Reduced spacing
          
          // Value
          Flexible( // Added Flexible to prevent overflow
            child: Text(
              _formatMetricValue(value),
              style: AppTextStyles.metricValue.copyWith(
                fontSize: 14, // Reduced font size
                color: qualityColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Unit
          Text(
            metricInfo.unit,
            style: AppTextStyles.metricUnit.copyWith(
              fontSize: 9, // Reduced font size
              color: AppTheme.textHint,
            ),
          ),
          const SizedBox(height: 2), // Reduced spacing
          
          // Name
          Flexible( // Added Flexible
            child: Text(
              metricInfo.displayName,
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 9, // Reduced font size
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricListItem(String metricName, double value) {
    final metricInfo = _getMetricInfo(metricName);
    final qualityColor = _getMetricQualityColor(metricName, value);
    
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 28, // Reduced size
            height: 28,
            decoration: BoxDecoration(
              color: qualityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              metricInfo.icon,
              color: qualityColor,
              size: 14, // Reduced size
            ),
          ),
          const SizedBox(width: 10), // Reduced spacing
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metricInfo.displayName,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14, // Reduced font size
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (metricInfo.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    metricInfo.description,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textHint,
                      fontSize: 10, // Reduced font size
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMetricValue(value),
                style: AppTextStyles.metricValue.copyWith(
                  fontSize: 16, // Reduced font size
                  color: qualityColor,
                ),
              ),
              Text(
                metricInfo.unit,
                style: AppTextStyles.metricUnit.copyWith(
                  fontSize: 10, // Reduced font size
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetricItem(String metricName, double value) {
    final metricInfo = _getMetricInfo(metricName);
    final qualityColor = _getMetricQualityColor(metricName, value);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatMetricValue(value),
          style: AppTextStyles.metricValue.copyWith(
            fontSize: 12, // Reduced font size
            color: qualityColor,
          ),
        ),
        Text(
          metricInfo.unit,
          style: AppTextStyles.metricUnit.copyWith(
            fontSize: 8, // Reduced font size
          ),
        ),
        const SizedBox(height: 2), // Reduced spacing
        Flexible( // Added Flexible
          child: Text(
            metricInfo.shortName,
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 8, // Reduced font size
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetricCard(String metricName, double value) {
    final metricInfo = _getMetricInfo(metricName);
    final qualityColor = _getMetricQualityColor(metricName, value);
    final quality = _getMetricQuality(metricName, value);
    
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: qualityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // CRITICAL: Prevent infinite height
        children: [
          // Header
          Row(
            children: [
              Icon(
                metricInfo.icon,
                color: qualityColor,
                size: 18, // Reduced size
              ),
              const SizedBox(width: 6), // Reduced spacing
              Expanded(
                child: Text(
                  metricInfo.displayName,
                  style: Get.textTheme.titleSmall?.copyWith( // Changed to titleSmall
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14, // Set explicit smaller font size
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildQualityBadge(quality, qualityColor),
            ],
          ),
          const SizedBox(height: 8), // Reduced spacing
          
          // Value row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMetricValue(value),
                style: AppTextStyles.metricValue.copyWith(
                  fontSize: 20, // Reduced font size
                  color: qualityColor,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2), // Reduced padding
                child: Text(
                  metricInfo.unit,
                  style: AppTextStyles.metricUnit.copyWith(
                    fontSize: 10, // Reduced font size
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              if (isRealTime)
                _buildTrendIndicator(metricName, value),
            ],
          ),
          const SizedBox(height: 6), // Reduced spacing
          
          // Description
          if (metricInfo.description.isNotEmpty)
            Text(
              metricInfo.description,
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textHint,
                fontSize: 10, // Reduced font size
              ),
              maxLines: 2, // Limit lines to prevent overflow
              overflow: TextOverflow.ellipsis,
            ),
          
          // Reference range (if available)
          if (_hasReferenceRange(metricName)) ...[
            const SizedBox(height: 6), // Reduced spacing
            _buildReferenceRange(metricName, value),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityBadge(MetricQuality quality, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4), // Smaller radius
      ),
      child: Text(
        quality.turkishName,
        style: TextStyle(
          fontSize: 9, // Reduced font size
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(String metricName, double value) {
    // Mock trend calculation - gerçek uygulamada önceki değerlerle karşılaştırılacak
    final trend = _calculateTrend(metricName, value);
    
    return Container(
      padding: const EdgeInsets.all(3), // Reduced padding
      decoration: BoxDecoration(
        color: _getTrendColor(trend).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3), // Smaller radius
      ),
      child: Icon(
        _getTrendIcon(trend),
        size: 10, // Reduced size
        color: _getTrendColor(trend),
      ),
    );
  }

  Widget _buildReferenceRange(String metricName, double value) {
    final range = _getReferenceRange(metricName);
    if (range == null) return const SizedBox.shrink();
    
    final percentage = ((value - range.min) / (range.max - range.min)).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevent overflow
      children: [
        Text(
          'Referans Aralığı',
          style: Get.textTheme.bodySmall?.copyWith(
            color: AppTheme.textHint,
            fontSize: 9, // Reduced font size
          ),
        ),
        const SizedBox(height: 3), // Reduced spacing
        SizedBox( // Fixed width container
          height: 4, // Reduced height
          width: double.infinity,
          child: Stack(
            children: [
              // Background bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.darkDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Progress bar
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _getMetricQualityColor(metricName, value),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3), // Reduced spacing
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              range.min.toStringAsFixed(0),
              style: const TextStyle(fontSize: 8, color: AppTheme.textHint), // Reduced font size
            ),
            Text(
              range.max.toStringAsFixed(0),
              style: const TextStyle(fontSize: 8, color: AppTheme.textHint), // Reduced font size
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  List<MapEntry<String, double>> _prepareMetricsForDisplay(Map<String, double> metricsData) {
    var entries = metricsData.entries.toList();
    
    // Öncelikli metrikleri başa al
    if (priorityMetrics != null) {
      entries.sort((a, b) {
        final aIndex = priorityMetrics!.indexOf(a.key);
        final bIndex = priorityMetrics!.indexOf(b.key);
        
        if (aIndex != -1 && bIndex != -1) {
          return aIndex.compareTo(bIndex);
        } else if (aIndex != -1) {
          return -1;
        } else if (bIndex != -1) {
          return 1;
        } else {
          return a.key.compareTo(b.key);
        }
      });
    }
    
    // Maksimum sayıya sınırla
    return entries.take(maxMetrics).toList();
  }

  int _getGridColumns() {
    if (maxMetrics <= 2) return 2;
    if (maxMetrics <= 4) return 2;
    return 3;
  }

  MetricInfo _getMetricInfo(String metricName) {
    return _metricInfoMap[metricName] ?? MetricInfo(
      displayName: metricName,
      shortName: metricName,
      unit: '',
      icon: Icons.analytics,
      description: '',
    );
  }

  String _formatMetricValue(double value) {
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else if (value.abs() >= 100) {
      return value.toStringAsFixed(0);
    } else if (value.abs() >= 10) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Color _getMetricQualityColor(String metricName, double value) {
    final quality = _getMetricQuality(metricName, value);
    switch (quality) {
      case MetricQuality.excellent:
        return AppColors.excellent;
      case MetricQuality.good:
        return AppColors.good;
      case MetricQuality.average:
        return AppColors.average;
      case MetricQuality.poor:
        return AppColors.poor;
    }
  }

  MetricQuality _getMetricQuality(String metricName, double value) {
    // Basit kalite değerlendirmesi - gerçek uygulamada daha karmaşık olacak
    switch (metricName) {
      case 'jumpHeight':
        if (value > 40) return MetricQuality.excellent;
        if (value > 30) return MetricQuality.good;
        if (value > 20) return MetricQuality.average;
        return MetricQuality.poor;
      
      case 'asymmetryIndex':
        if (value < 5) return MetricQuality.excellent;
        if (value < 10) return MetricQuality.good;
        if (value < 15) return MetricQuality.average;
        return MetricQuality.poor;
      
      default:
        return MetricQuality.average;
    }
  }

  MetricTrend _calculateTrend(String metricName, double value) {
    // Mock trend - gerçek uygulamada geçmiş verilerle karşılaştırılacak
    final random = math.Random().nextDouble();
    if (random > 0.6) return MetricTrend.increasing;
    if (random > 0.3) return MetricTrend.stable;
    return MetricTrend.decreasing;
  }

  Color _getTrendColor(MetricTrend trend) {
    switch (trend) {
      case MetricTrend.increasing:
        return AppTheme.successColor;
      case MetricTrend.decreasing:
        return AppTheme.errorColor;
      case MetricTrend.stable:
        return AppTheme.textHint;
    }
  }

  IconData _getTrendIcon(MetricTrend trend) {
    switch (trend) {
      case MetricTrend.increasing:
        return Icons.trending_up;
      case MetricTrend.decreasing:
        return Icons.trending_down;
      case MetricTrend.stable:
        return Icons.trending_flat;
    }
  }

  bool _hasReferenceRange(String metricName) {
    return _referenceRanges.containsKey(metricName);
  }

  ReferenceRange? _getReferenceRange(String metricName) {
    return _referenceRanges[metricName];
  }

  // Static data
  static final Map<String, MetricInfo> _metricInfoMap = {
    'jumpHeight': const MetricInfo(
      displayName: 'Sıçrama Yüksekliği',
      shortName: 'Yükseklik',
      unit: 'cm',
      icon: Icons.trending_up,
      description: 'Düşey deplasmanın maksimum değeri',
    ),
    'peakForce': const MetricInfo(
      displayName: 'Tepe Kuvvet',
      shortName: 'Max Kuvvet',
      unit: 'N',
      icon: Icons.fitness_center,
      description: 'Test sırasında ulaşılan maksimum kuvvet değeri',
    ),
    'averageForce': const MetricInfo(
      displayName: 'Ortalama Kuvvet',
      shortName: 'Ort. Kuvvet',
      unit: 'N',
      icon: Icons.analytics,
      description: 'Test boyunca ortalama kuvvet değeri',
    ),
    'asymmetryIndex': const MetricInfo(
      displayName: 'Asimetri İndeksi',
      shortName: 'Asimetri',
      unit: '%',
      icon: Icons.balance,
      description: 'Sol ve sağ bacak arasındaki fark yüzdesi',
    ),
    'flightTime': const MetricInfo(
      displayName: 'Uçuş Süresi',
      shortName: 'Uçuş',
      unit: 'ms',
      icon: Icons.flight,
      description: 'Platformla temas kaybı süresi',
    ),
    'contactTime': const MetricInfo(
      displayName: 'Temas Süresi',
      shortName: 'Temas',
      unit: 'ms',
      icon: Icons.touch_app,
      description: 'Platform ile temas halinde geçen süre',
    ),
    'rfd': const MetricInfo(
      displayName: 'Kuvvet Gelişim Hızı',
      shortName: 'RFD',
      unit: 'N/s',
      icon: Icons.speed,
      description: 'Kuvvetin zamana göre değişim oranı',
    ),
    'copRange': const MetricInfo(
      displayName: 'COP Mesafesi',
      shortName: 'COP',
      unit: 'mm',
      icon: Icons.my_location,
      description: 'Basınç merkezinin hareket aralığı',
    ),
    'stabilityIndex': const MetricInfo(
      displayName: 'Stabilite İndeksi',
      shortName: 'Stabilite',
      unit: '',
      icon: Icons.center_focus_strong,
      description: 'Denge performansının genel değerlendirmesi',
    ),
  };

  static final Map<String, ReferenceRange> _referenceRanges = {
    'jumpHeight': const ReferenceRange(min: 20, max: 60),
    'asymmetryIndex': const ReferenceRange(min: 0, max: 15),
    'peakForce': const ReferenceRange(min: 800, max: 2500),
    'stabilityIndex': const ReferenceRange(min: 60, max: 100),
  };
}

// Enums and classes
enum MetricDisplayStyle { grid, list, compact, detailed }

enum MetricQuality {
  excellent('Mükemmel'),
  good('İyi'),
  average('Ortalama'),
  poor('Zayıf');

  const MetricQuality(this.turkishName);
  final String turkishName;
}

enum MetricTrend { increasing, decreasing, stable }

class MetricInfo {
  final String displayName;
  final String shortName;
  final String unit;
  final IconData icon;
  final String description;

  const MetricInfo({
    required this.displayName,
    required this.shortName,
    required this.unit,
    required this.icon,
    required this.description,
  });
}

class ReferenceRange {
  final double min;
  final double max;

  const ReferenceRange({required this.min, required this.max});
}