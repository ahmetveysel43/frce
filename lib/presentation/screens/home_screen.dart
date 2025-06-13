import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/utils/app_logger.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/test_controller.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/quick_stats_widget.dart';
import '../widgets/recent_tests_widget.dart';
import '../widgets/app_drawer.dart';

/// izForce ana ekran (DÜZELTME VERSİYONU)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Show exit confirmation dialog
        final shouldExit = await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: AppTheme.darkCard,
            title: const Text(
              'Çıkış',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Uygulamadan çıkmak istediğinize emin misiniz?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('Çıkış'),
              ),
            ],
          ),
        );
        
        if (shouldExit == true) {
          // Exit the app completely
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: AppTheme.darkBackground,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Logo ve başlık merkezi tasarım - responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 360;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with modern design
                  Container(
                    width: isSmallScreen ? 60 : 80,
                    height: isSmallScreen ? 60 : 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 15 : 20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.successColor,
                          AppTheme.successColor.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 15 : 20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if logo not found
                          return Icon(
                            Icons.scatter_plot_rounded,
                            color: Colors.white,
                            size: isSmallScreen ? 30 : 40,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 20),
                  
                  // Title and subtitle
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'izForce',
                          style: Get.textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: isSmallScreen ? 26 : 32,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.successColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Kuvvet Platformu - Analitik',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w700,
                              fontSize: isSmallScreen ? 10 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Notification button with modern design
                  if (!isSmallScreen)
                    Container(
                      margin: const EdgeInsets.only(left: 20),
                      child: IconButton(
                        onPressed: () {
                          Get.snackbar('Bilgi', 'Bildirimler yakında gelecek');
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          
        ],
      ),
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
                const Icon(
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
                  color: color.withValues(alpha: 0.2),
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
            Expanded(
              child: Text(
                'İstatistikler',
                style: Get.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                Get.snackbar('Bilgi', 'Detaylı istatistikler yakında gelecek');
              },
              child: const Text(
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
            Expanded(
              child: Text(
                'Son Testler',
                style: Get.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/results'),
              child: const Text(
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
            heroTag: 'main',
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

  // DÜZELTME: Test başlatma metodunu yeniden yaz
  void _startNewTest() {
    final testController = Get.find<TestController>();
    final athleteController = Get.find<AthleteController>();
    
    AppLogger.info('Home', '🚀 START NEW TEST CALLED FROM HOME');
    AppLogger.info('Home', '   Connected: ${testController.isConnected}');
    AppLogger.info('Home', '   Total Athletes: ${athleteController.totalAthletes}');
    
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
          title: const Text(
            'Sporcu Bulunamadı',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Test yapmak için önce sporcu eklemeniz gerekiyor.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.toNamed('/athlete-selection');
              },
              child: const Text('Sporcu Ekle'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Test akışını başlat - doğru sırayla
    AppLogger.info('Home', '✅ All prerequisites met, starting test flow...');
    
    // Test controller'ı sıfırla ve athlete selection'a git
    testController.restartTestFlow();
    
    // Athlete selection ekranına git
    Get.toNamed('/athlete-selection');
  }

  void _connectDevice() {
    final testController = Get.find<TestController>();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text(
          'Cihaz Bağlantısı',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Force plate cihazına bağlanmak istiyor musunuz?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
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
            child: const Text('Bağlan'),
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
        decoration: const BoxDecoration(
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
                    'Test Kalitesi',
                    '94%',
                    Icons.verified,
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
                child: const Text('Detaylı İstatistikler'),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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