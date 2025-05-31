import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/test_controller.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/quick_stats_widget.dart';
import '../widgets/recent_tests_widget.dart';

/// izForce ana ekran
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Connection Status
              _buildConnectionSection(),
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),
              
              // Statistics
              _buildStatisticsSection(),
              const SizedBox(height: 24),
              
              // Recent Tests
              _buildRecentTestsSection(),
              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.analytics,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'app_name'.tr,
                    style: Get.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Force Plate Analiz Sistemi',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Settings button
            IconButton(
              onPressed: () {
                // TODO: Navigate to settings
                Get.snackbar('Bilgi', 'Ayarlar ekranı yakında gelecek');
              },
              icon: const Icon(
                Icons.settings,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Welcome message
        Obx(() {
          final testController = Get.find<TestController>();
          final athleteController = Get.find<AthleteController>();
          
          return Text(
            testController.isMockMode 
                ? '🎭 Mock Mode - ${athleteController.totalAthletes} sporcu kayıtlı'
                : '🔧 Hardware Mode - ${athleteController.totalAthletes} sporcu kayıtlı',
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppTheme.textHint,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConnectionSection() {
    return Card(
      color: AppTheme.darkCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cihaz Bağlantısı',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            const ConnectionStatusWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: Get.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            // New Test
            Expanded(
              child: _buildActionCard(
                icon: Icons.play_circle_filled,
                title: 'Yeni Test',
                subtitle: 'Test başlat',
                color: AppTheme.primaryColor,
                onTap: () => _startNewTest(),
              ),
            ),
            const SizedBox(width: 12),
            
            // Athletes
            Expanded(
              child: _buildActionCard(
                icon: Icons.people,
                title: 'Sporcular',
                subtitle: 'Sporcu yönetimi',
                color: AppTheme.accentColor,
                onTap: () => Get.toNamed('/athlete-selection'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            // Test History
            Expanded(
              child: _buildActionCard(
                icon: Icons.history,
                title: 'Test Geçmişi',
                subtitle: 'Sonuçları görüntüle',
                color: AppColors.chartColors[2],
                onTap: () => Get.toNamed('/results'),
              ),
            ),
            const SizedBox(width: 12),
            
            // Quick Stats
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'İstatistikler',
                subtitle: 'Hızlı bakış',
                color: AppColors.chartColors[3],
                onTap: () => _showQuickStats(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppTheme.darkCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                title,
                style: Get.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              
              Text(
                subtitle,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'İstatistikler',
              style: Get.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to detailed stats
                Get.snackbar('Bilgi', 'Detaylı istatistikler yakında gelecek');
              },
              child: Text(
                'Tümünü Gör',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        const QuickStatsWidget(),
      ],
    );
  }

  Widget _buildRecentTestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Son Testler',
              style: Get.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/results'),
              child: Text(
                'Tümünü Gör',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        const RecentTestsWidget(),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Obx(() {
      final testController = Get.find<TestController>();
      
      return FloatingActionButton.extended(
        onPressed: testController.isConnected 
            ? () => _startNewTest()
            : () => _connectDevice(),
        backgroundColor: testController.isConnected 
            ? AppTheme.primaryColor 
            : AppTheme.errorColor,
        icon: Icon(
          testController.isConnected 
              ? Icons.play_arrow 
              : Icons.link_off,
          color: Colors.white,
        ),
        label: Text(
          testController.isConnected ? 'Yeni Test' : 'Bağlan',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    });
  }

  void _startNewTest() {
    final testController = Get.find<TestController>();
    final athleteController = Get.find<AthleteController>();
    
    if (!testController.isConnected) {
      Get.snackbar(
        'Uyarı',
        'Önce cihaza bağlanmanız gerekiyor',
        backgroundColor: AppTheme.warningColor,
        colorText: Colors.white,
      );
      return;
    }
    
    if (athleteController.totalAthletes == 0) {
      Get.dialog(
        AlertDialog(
          backgroundColor: AppTheme.darkCard,
          title: Text(
            'Sporcu Bulunamadı',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Test yapmak için önce sporcu eklemeniz gerekiyor. Şimdi sporcu eklemek ister misiniz?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.toNamed('/athlete-selection');
              },
              child: Text('Sporcu Ekle'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Navigate to athlete selection for test
    Get.toNamed('/athlete-selection');
  }

  void _connectDevice() {
    final testController = Get.find<TestController>();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text(
          'Cihaz Bağlantısı',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Force plate cihazına bağlanmak istiyor musunuz?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            
            if (testController.isMockMode)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mock mode aktif - Simülasyon cihazı kullanılacak',
                        style: TextStyle(
                          color: AppTheme.warningColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              final success = await testController.connectToDevice('USB001');
              if (success) {
                Get.snackbar(
                  'Başarılı',
                  'Cihaza bağlanıldı',
                  backgroundColor: AppTheme.successColor,
                  colorText: Colors.white,
                );
              }
            },
            child: Text('Bağlan'),
          ),
        ],
      ),
    );
  }

  void _showQuickStats() {
    final athleteController = Get.find<AthleteController>();
    final stats = athleteController.athleteStats;
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            
            Text(
              'Hızlı İstatistikler',
              style: Get.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Sporcu',
                    stats.totalCount.toString(),
                    Icons.people,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Erkek / Kadın',
                    '${stats.maleCount} / ${stats.femaleCount}',
                    Icons.people_alt,
                    AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tamamlanan Profil',
                    '${stats.profileCompletionPercentage.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Popüler Spor',
                    stats.mostPopularSport ?? 'Yok',
                    Icons.sports,
                    AppColors.chartColors[2],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  // TODO: Navigate to detailed stats
                },
                child: Text('Detaylı İstatistikler'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Get.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}