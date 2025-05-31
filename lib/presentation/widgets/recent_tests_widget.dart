import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../../domain/entities/test_result.dart';
import '../../domain/entities/athlete.dart';

/// Son testler widget'ı
class RecentTestsWidget extends StatelessWidget {
  const RecentTestsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AthleteController>(
      builder: (controller) {
        // Mock data - gerçek uygulamada database'den gelecek
        final recentTests = _generateMockRecentTests(controller);
        
        if (recentTests.isEmpty) {
          return _buildEmptyState();
        }
        
        return Column(
          children: [
            // Test listesi
            ...recentTests.take(5).map((test) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTestCard(test, controller),
            )),
            
            // "Daha fazla göster" butonu
            if (recentTests.length > 5) ...[
              const SizedBox(height: 8),
              _buildShowMoreButton(recentTests.length - 5),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkDivider,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.textHint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.history,
              color: AppTheme.textHint,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Henüz Test Yapılmamış',
            style: Get.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'İlk testi yapmak için sporcu seçin ve teste başlayın',
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppTheme.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/athlete-selection'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('İlk Testi Başlat'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(RecentTestData test, AthleteController controller) {
    final athlete = controller.findAthleteById(test.athleteId);
    
    return Card(
      color: AppTheme.darkCard,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _onTestTap(test),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header row
              Row(
                children: [
                  // Test type icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getTestTypeColor(test.testType).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTestTypeIcon(test.testType),
                      color: _getTestTypeColor(test.testType),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Test info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.testType.turkishName,
                          style: Get.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          athlete?.fullName ?? 'Bilinmeyen Sporcu',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Quality badge
                  _buildQualityBadge(test.quality),
                ],
              ),
              const SizedBox(height: 12),
              
              // Metrics row
              Row(
                children: [
                  // Ana metrik
                  Expanded(
                    child: _buildMetricItem(
                      title: _getPrimaryMetricName(test.testType),
                      value: _getPrimaryMetricValue(test.testType, test.metrics),
                      unit: _getPrimaryMetricUnit(test.testType),
                      color: _getTestTypeColor(test.testType),
                    ),
                  ),
                  
                  Container(
                    width: 1,
                    height: 24,
                    color: AppTheme.darkDivider,
                  ),
                  
                  // İkincil metrik
                  Expanded(
                    child: _buildMetricItem(
                      title: 'Asimetri',
                      value: test.metrics['asymmetryIndex']?.toStringAsFixed(1) ?? '0.0',
                      unit: '%',
                      color: _getAsymmetryColor(test.metrics['asymmetryIndex'] ?? 0),
                    ),
                  ),
                  
                  Container(
                    width: 1,
                    height: 24,
                    color: AppTheme.darkDivider,
                  ),
                  
                  // Tarih
                  Expanded(
                    child: _buildMetricItem(
                      title: 'Tarih',
                      value: DateFormat('dd.MM').format(test.testDate),
                      unit: DateFormat('HH:mm').format(test.testDate),
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Footer row
              Row(
                children: [
                  // Duration
                  Icon(
                    Icons.timer,
                    size: 14,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${test.duration.inSeconds}s',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textHint,
                      fontSize: 11,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Sport
                  if (athlete?.sport != null) ...[
                    Icon(
                      Icons.sports,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      athlete!.sport!,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // View button
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppTheme.textHint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityBadge(TestQuality quality) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(int.parse(quality.colorHex.replaceFirst('#', '0xFF'))).withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        quality.turkishName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(int.parse(quality.colorHex.replaceFirst('#', '0xFF'))),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: Get.textTheme.bodySmall?.copyWith(
            color: AppTheme.textHint,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: Get.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShowMoreButton(int remainingCount) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Get.toNamed('/results'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
        label: Text('$remainingCount Daha Fazla Test Göster'),
      ),
    );
  }

  // Helper methods
  Color _getTestTypeColor(TestType testType) {
    switch (testType.category) {
      case TestCategory.jump:
        return AppColors.chartColors[0]; // Blue
      case TestCategory.strength:
        return AppColors.chartColors[1]; // Orange
      case TestCategory.balance:
        return AppColors.chartColors[2]; // Green
      case TestCategory.agility:
        return AppColors.chartColors[3]; // Purple
    }
  }

  IconData _getTestTypeIcon(TestType testType) {
    switch (testType.category) {
      case TestCategory.jump:
        return Icons.trending_up;
      case TestCategory.strength:
        return Icons.fitness_center;
      case TestCategory.balance:
        return Icons.balance;
      case TestCategory.agility:
        return Icons.speed;
    }
  }

  String _getPrimaryMetricName(TestType testType) {
    switch (testType.category) {
      case TestCategory.jump:
        return 'Yükseklik';
      case TestCategory.strength:
        return 'Max Kuvvet';
      case TestCategory.balance:
        return 'COP Mesafe';
      case TestCategory.agility:
        return 'Hız';
    }
  }

  String _getPrimaryMetricValue(TestType testType, Map<String, double> metrics) {
    switch (testType.category) {
      case TestCategory.jump:
        return (metrics['jumpHeight'] ?? 0).toStringAsFixed(1);
      case TestCategory.strength:
        return (metrics['peakForce'] ?? 0).toStringAsFixed(0);
      case TestCategory.balance:
        return (metrics['copRange'] ?? 0).toStringAsFixed(1);
      case TestCategory.agility:
        return (metrics['speed'] ?? 0).toStringAsFixed(2);
    }
  }

  String _getPrimaryMetricUnit(TestType testType) {
    switch (testType.category) {
      case TestCategory.jump:
        return 'cm';
      case TestCategory.strength:
        return 'N';
      case TestCategory.balance:
        return 'mm';
      case TestCategory.agility:
        return 'm/s';
    }
  }

  Color _getAsymmetryColor(double asymmetry) {
    if (asymmetry < 5) return AppTheme.successColor;
    if (asymmetry < 10) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  void _onTestTap(RecentTestData test) {
    Get.bottomSheet(
      _buildTestDetailsBottomSheet(test),
      isScrollControlled: true,
    );
  }

  Widget _buildTestDetailsBottomSheet(RecentTestData test) {
    return Container(
      height: Get.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTestTypeColor(test.testType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTestTypeIcon(test.testType),
                  color: _getTestTypeColor(test.testType),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.testType.turkishName,
                      style: Get.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMMM yyyy, HH:mm').format(test.testDate),
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildQualityBadge(test.quality),
            ],
          ),
          const SizedBox(height: 24),
          
          // Metrics grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: test.metrics.length,
              itemBuilder: (context, index) {
                final entry = test.metrics.entries.elementAt(index);
                return _buildDetailMetricCard(entry.key, entry.value);
              },
            ),
          ),
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.back();
                    // TODO: Share test result
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Paylaş'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    // TODO: Navigate to detailed results
                  },
                  icon: const Icon(Icons.analytics, size: 18),
                  label: const Text('Detay Görüntüle'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetricCard(String metricName, double value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getMetricDisplayName(metricName),
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value.toStringAsFixed(1),
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' ${_getMetricUnit(metricName)}',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMetricDisplayName(String metricName) {
    switch (metricName) {
      case 'jumpHeight': return 'Sıçrama Yüksekliği';
      case 'peakForce': return 'Tepe Kuvvet';
      case 'averageForce': return 'Ort. Kuvvet';
      case 'asymmetryIndex': return 'Asimetri';
      case 'flightTime': return 'Uçuş Süresi';
      case 'contactTime': return 'Temas Süresi';
      case 'rfd': return 'RFD';
      case 'copRange': return 'COP Mesafe';
      case 'stabilityIndex': return 'Stabilite';
      default: return metricName;
    }
  }

  String _getMetricUnit(String metricName) {
    switch (metricName) {
      case 'jumpHeight': return 'cm';
      case 'peakForce':
      case 'averageForce': return 'N';
      case 'asymmetryIndex': return '%';
      case 'flightTime':
      case 'contactTime': return 'ms';
      case 'rfd': return 'N/s';
      case 'copRange': return 'mm';
      case 'stabilityIndex': return '';
      default: return '';
    }
  }

  // Mock data generator
  List<RecentTestData> _generateMockRecentTests(AthleteController controller) {
    final athletes = controller.athletes;
    if (athletes.isEmpty) return [];
    
    final tests = <RecentTestData>[];
    final now = DateTime.now();
    
    // Generate 8 mock tests
    for (int i = 0; i < 8; i++) {
      final athlete = athletes[i % athletes.length];
      final testType = TestType.values[i % TestType.values.length];
      final testDate = now.subtract(Duration(hours: i * 6));
      
      tests.add(RecentTestData(
        id: 'test_$i',
        athleteId: athlete.id,
        testType: testType,
        testDate: testDate,
        duration: Duration(seconds: 5 + (i % 10)),
        quality: TestQuality.values[i % TestQuality.values.length],
        metrics: _generateMockMetrics(testType),
      ));
    }
    
    // Sort by date (newest first)
    tests.sort((a, b) => b.testDate.compareTo(a.testDate));
    
    return tests;
  }

  Map<String, double> _generateMockMetrics(TestType testType) {
    final random = DateTime.now().millisecond;
    
    switch (testType.category) {
      case TestCategory.jump:
        return {
          'jumpHeight': 30.0 + (random % 20),
          'peakForce': 1000.0 + (random % 500),
          'flightTime': 400.0 + (random % 200),
          'asymmetryIndex': 5.0 + (random % 10),
          'rfd': 3000.0 + (random % 1000),
        };
      case TestCategory.strength:
        return {
          'peakForce': 800.0 + (random % 400),
          'averageForce': 600.0 + (random % 200),
          'asymmetryIndex': 3.0 + (random % 8),
          'rfd': 2500.0 + (random % 1500),
        };
      case TestCategory.balance:
        return {
          'copRange': 15.0 + (random % 20),
          'stabilityIndex': 70.0 + (random % 25),
          'asymmetryIndex': 2.0 + (random % 6),
        };
      case TestCategory.agility:
        return {
          'speed': 2.5 + ((random % 15) / 10),
          'asymmetryIndex': 4.0 + (random % 8),
        };
    }
  }
}

/// Son test verisi için model
class RecentTestData {
  final String id;
  final String athleteId;
  final TestType testType;
  final DateTime testDate;
  final Duration duration;
  final TestQuality quality;
  final Map<String, double> metrics;

  const RecentTestData({
    required this.id,
    required this.athleteId,
    required this.testType,
    required this.testDate,
    required this.duration,
    required this.quality,
    required this.metrics,
  });
}