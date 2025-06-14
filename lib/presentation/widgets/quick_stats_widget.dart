import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../../presentation/controllers/test_controller.dart';

/// Ana ekran hızlı istatistikler widget'ı
class QuickStatsWidget extends StatelessWidget {
  const QuickStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AthleteController>(
      builder: (athleteController) {
        return GetBuilder<TestController>(
          builder: (testController) {
            final stats = athleteController.athleteStats;
            
            return Column(
              children: [
                // İlk satır - Sporcu istatistikleri
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Toplam Sporcu',
                        value: stats.totalCount.toString(),
                        icon: Icons.people,
                        color: AppTheme.primaryColor,
                        trend: _calculateAthleteTrend(stats.totalCount),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Aktif Sporcu',
                        value: athleteController.getActiveAthletes().length.toString(),
                        icon: Icons.person_outline,
                        color: AppTheme.accentColor,
                        trend: StatTrend.stable,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // İkinci satır - Test istatistikleri
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Bugünkü Test',
                        value: _getTodayTestCount().toString(),
                        icon: Icons.today,
                        color: AppColors.chartColors[2],
                        trend: StatTrend.positive,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Bu Hafta',
                        value: _getWeekTestCount().toString(),
                        icon: Icons.date_range,
                        color: AppColors.chartColors[3],
                        trend: StatTrend.positive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Üçüncü satır - Kalite ve performans
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Profil Tamamlama',
                        value: '${stats.profileCompletionPercentage.toStringAsFixed(0)}%',
                        icon: Icons.check_circle_outline,
                        color: stats.profileCompletionPercentage > 80 
                            ? AppTheme.successColor 
                            : AppTheme.warningColor,
                        trend: _getProfileCompletionTrend(stats.profileCompletionPercentage),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: testController.isConnected ? 'Bağlı' : 'Bağlantı Yok',
                        value: testController.isConnected ? 'Hazır' : 'Offline',
                        icon: testController.isConnected ? Icons.wifi : Icons.wifi_off,
                        color: testController.isConnected 
                            ? AppTheme.successColor 
                            : AppTheme.errorColor,
                        trend: testController.isConnected ? StatTrend.positive : StatTrend.negative,
                      ),
                    ),
                  ],
                ),
                
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    StatTrend trend = StatTrend.stable,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon ve trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                _buildTrendIndicator(trend),
              ],
            ),
            const SizedBox(height: 12),
            
            // Değer
            Text(
              value,
              style: Get.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            
            // Başlık
            Text(
              title,
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
    );
  }

  Widget _buildTrendIndicator(StatTrend trend) {
    if (trend == StatTrend.stable) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: _getTrendColor(trend).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        _getTrendIcon(trend),
        size: 12,
        color: _getTrendColor(trend),
      ),
    );
  }



  // Helper methods for trends and calculations
  StatTrend _calculateAthleteTrend(int totalCount) {
    // Bu gerçek uygulamada geçmiş verilerle karşılaştırılacak
    if (totalCount > 50) return StatTrend.positive;
    if (totalCount > 20) return StatTrend.stable;
    return StatTrend.negative;
  }

  StatTrend _getProfileCompletionTrend(double completion) {
    if (completion > 80) return StatTrend.positive;
    if (completion > 60) return StatTrend.stable;
    return StatTrend.negative;
  }

  int _getTodayTestCount() {
    // Mock data - gerçek uygulamada database'den gelecek
    return 12;
  }

  int _getWeekTestCount() {
    // Mock data - gerçek uygulamada database'den gelecek
    return 47;
  }

  IconData _getTrendIcon(StatTrend trend) {
    switch (trend) {
      case StatTrend.positive:
        return Icons.trending_up;
      case StatTrend.negative:
        return Icons.trending_down;
      case StatTrend.stable:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(StatTrend trend) {
    switch (trend) {
      case StatTrend.positive:
        return AppTheme.successColor;
      case StatTrend.negative:
        return AppTheme.errorColor;
      case StatTrend.stable:
        return AppTheme.textHint;
    }
  }
}

/// İstatistik trend enum'u
enum StatTrend {
  positive,
  negative,
  stable,
}

/// İstatistik kartı için model
class StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final StatTrend trend;
  final VoidCallback? onTap;

  const StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend = StatTrend.stable,
    this.onTap,
  });
}

/// Hazır istatistik kartları
class QuickStatCards {
  static List<StatCardData> getDefaultCards(
    AthleteController athleteController,
    TestController testController,
  ) {
    final stats = athleteController.athleteStats;
    
    return [
      StatCardData(
        title: 'Toplam Sporcu',
        value: stats.totalCount.toString(),
        icon: Icons.people,
        color: AppTheme.primaryColor,
        trend: stats.totalCount > 10 ? StatTrend.positive : StatTrend.stable,
        onTap: () => Get.toNamed('/athlete-selection'),
      ),
      
      StatCardData(
        title: 'Bağlantı Durumu',
        value: testController.isConnected ? 'Bağlı' : 'Offline',
        icon: testController.isConnected ? Icons.wifi : Icons.wifi_off,
        color: testController.isConnected ? AppTheme.successColor : AppTheme.errorColor,
        trend: testController.isConnected ? StatTrend.positive : StatTrend.negative,
      ),
      
      StatCardData(
        title: 'Profil Tamamlama',
        value: '${stats.profileCompletionPercentage.toStringAsFixed(0)}%',
        icon: Icons.check_circle_outline,
        color: stats.profileCompletionPercentage > 80 
            ? AppTheme.successColor 
            : AppTheme.warningColor,
        trend: stats.profileCompletionPercentage > 80 
            ? StatTrend.positive 
            : StatTrend.stable,
      ),
      
      StatCardData(
        title: 'Bugünkü Test',
        value: '12', // Mock data
        icon: Icons.today,
        color: AppColors.chartColors[2],
        trend: StatTrend.positive,
        onTap: () => Get.toNamed('/results'),
      ),
    ];
  }
}