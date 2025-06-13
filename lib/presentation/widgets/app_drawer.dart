import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../controllers/athlete_controller.dart';
import '../controllers/test_controller.dart';
import '../screens/advanced_test_comparison_screen.dart';
import 'user_profile_section.dart';

/// izForce uygulaması için özel tasarlanmış drawer menü
/// Atletik tema ve gelişmiş navigasyon özellikleri
class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.darkBackground,
      child: Column(
        children: [
          const UserProfileSection(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuSection('Ana Menü', [
                  _buildMenuItem(
                    icon: Icons.home_outlined,
                    title: 'Ana Sayfa',
                    onTap: () => _navigateTo('/'),
                    isSelected: Get.currentRoute == '/',
                  ),
                  _buildMenuItem(
                    icon: Icons.play_circle_outline,
                    title: 'Yeni Test',
                    onTap: () => _startNewTest(),
                    badge: _buildTestBadge(),
                  ),
                  _buildMenuItem(
                    icon: Icons.people_outline,
                    title: 'Sporcular',
                    subtitle: 'Sporcu yönetimi',
                    onTap: () => _navigateTo('/athlete-selection'),
                    isSelected: Get.currentRoute.contains('athlete'),
                  ),
                  _buildMenuItem(
                    icon: Icons.assignment_outlined,
                    title: 'Test Geçmişi',
                    subtitle: 'Sonuçlar ve raporlar',
                    onTap: () => _navigateTo('/results'),
                    isSelected: Get.currentRoute.contains('results'),
                  ),
                ]),
                
                const Divider(color: AppTheme.textHint, height: 32),
                
                _buildMenuSection('Analitik ve AI', [
                  _buildMenuItem(
                    icon: Icons.insights_outlined,
                    title: 'AI Insights',
                    subtitle: 'Gelişmiş performans analizi',
                    onTap: () => _showAIInsights(),
                    badge: _buildAIBadge(),
                  ),
                  _buildMenuItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Performans Paneli',
                    subtitle: 'İlerleme analizi',
                    onTap: () => _showProgressDashboard(),
                  ),
                  _buildMenuItem(
                    icon: Icons.analytics_outlined,
                    title: 'İstatistikler',
                    subtitle: 'Detaylı istatistikler',
                    onTap: () => _showStatistics(),
                  ),
                  _buildMenuItem(
                    icon: Icons.analytics_outlined,
                    title: 'Test Karşılaştırması',
                    subtitle: 'Gelişmiş analiz & Radar charts',
                    onTap: () => _showAdvancedComparison(),
                    badge: _buildPremiumBadge(),
                  ),
                ]),
                
                const Divider(color: AppTheme.textHint, height: 32),
                
                _buildMenuSection('Araçlar', [
                  _buildMenuItem(
                    icon: Icons.link_outlined,
                    title: 'Cihaz Bağlantısı',
                    subtitle: _getConnectionStatus(),
                    onTap: () => _showConnectionDialog(),
                    trailing: _buildConnectionIndicator(),
                  ),
                  _buildMenuItem(
                    icon: Icons.file_download_outlined,
                    title: 'Rapor Oluştur',
                    subtitle: 'PDF ve Excel export',
                    onTap: () => _showReportDialog(),
                  ),
                  _buildMenuItem(
                    icon: Icons.backup_outlined,
                    title: 'Yedekleme',
                    subtitle: 'Veri yedekleme ve geri yükleme',
                    onTap: () => _showBackupDialog(),
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Ayarlar',
                    subtitle: 'Uygulama ayarları',
                    onTap: () => _navigateTo('/settings'),
                    isSelected: Get.currentRoute.contains('settings'),
                  ),
                ]),
                
                const Divider(color: AppTheme.textHint, height: 32),
                
                _buildMenuSection('Bilgi', [
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Yardım',
                    onTap: () => _showHelp(),
                  ),
                  _buildMenuItem(
                    icon: Icons.code,
                    title: 'Geliştirici',
                    onTap: () => _showDeveloperDialog(),
                  ),
                  _buildMenuItem(
                    icon: Icons.article,
                    title: 'Lisans',
                    onTap: () => _showLicenseDialog(),
                  ),
                  _buildMenuItem(
                    icon: Icons.privacy_tip,
                    title: 'Gizlilik Politikası',
                    onTap: () => _showPrivacyDialog(),
                  ),
                  _buildMenuItem(
                    icon: Icons.support,
                    title: 'Destek',
                    onTap: () => _showSupportDialog(),
                  ),
                ]),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
          _buildDrawerFooter(),
        ],
      ),
    );
  }


  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textHint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Widget? badge,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)) : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                : AppTheme.darkCard,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (badge != null) badge,
          ],
        ),
        subtitle: subtitle != null 
            ? Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing,
        onTap: () {
          Navigator.pop(Get.context!);
          onTap();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildTestBadge() {
    return Obx(() {
      final testController = Get.find<TestController>();
      if (!testController.isConnected) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.errorColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Bağlantı Yok',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
      return const SizedBox();
    });
  }

  Widget _buildAIBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'AI',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    return Obx(() {
      final testController = Get.find<TestController>();
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: testController.isConnected ? Colors.green : Colors.red,
          shape: BoxShape.circle,
        ),
      );
    });
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.textHint.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.code,
                color: AppTheme.textHint,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'v1.0.0 - Doç Dr. İzzet İnce',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            final testController = Get.find<TestController>();
            return Row(
              children: [
                Icon(
                  testController.isMockMode ? Icons.science : Icons.hardware,
                  color: AppTheme.textHint,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  testController.isMockMode ? 'Simülasyon Modu' : 'Hardware Modu',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Navigation methods

  void _navigateTo(String route) {
    if (Get.currentRoute != route) {
      Get.toNamed(route);
    }
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
        icon: const Icon(Icons.warning, color: Colors.white),
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
          content: const Text(
            'Test yapmak için önce sporcu eklemeniz gerekiyor. Şimdi sporcu eklemek ister misiniz?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _navigateTo('/athlete-selection');
              },
              child: const Text('Sporcu Ekle'),
            ),
          ],
        ),
      );
      return;
    }
    
    testController.restartTestFlow();
    _navigateTo('/athlete-selection');
  }

  void _showAIInsights() {
    final athleteController = Get.find<AthleteController>();
    
    if (athleteController.totalAthletes == 0) {
      Get.snackbar(
        'Bilgi',
        'AI analizi için sporcu verileri gereklidir',
        backgroundColor: AppTheme.primaryColor,
        colorText: Colors.white,
        icon: const Icon(Icons.info, color: Colors.white),
      );
      return;
    }
    
    // Navigate to AI insights with first athlete
    final firstAthleteId = athleteController.athletes.first.id;
    Get.toNamed('/ai-insights/$firstAthleteId');
  }

  void _showProgressDashboard() {
    final athleteController = Get.find<AthleteController>();
    
    if (athleteController.totalAthletes == 0) {
      Get.snackbar(
        'Bilgi',
        'İlerleme analizi için sporcu verileri gereklidir',
        backgroundColor: AppTheme.primaryColor,
        colorText: Colors.white,
        icon: const Icon(Icons.info, color: Colors.white),
      );
      return;
    }
    
    final firstAthleteId = athleteController.athletes.first.id;
    Get.toNamed('/progress-dashboard?athleteId=$firstAthleteId');
  }

  void _showStatistics() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              'Detaylı İstatistikler',
              style: Get.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildStatisticsContent(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvancedComparison() {
    final athleteController = Get.find<AthleteController>();
    
    if (athleteController.totalAthletes == 0) {
      Get.snackbar(
        'Bilgi',
        'Test karşılaştırması için sporcu verileri gereklidir',
        backgroundColor: AppTheme.primaryColor,
        colorText: Colors.white,
        icon: const Icon(Icons.info, color: Colors.white),
      );
      return;
    }
    
    Get.to(() => const AdvancedTestComparisonScreen());
  }

  void _showConnectionDialog() {
    final testController = Get.find<TestController>();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(
              Icons.link,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            const Text(
              'Cihaz Bağlantısı',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durum: ${testController.isConnected ? "Bağlı" : "Bağlı Değil"}',
              style: TextStyle(
                color: testController.isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (testController.isMockMode)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.science, color: AppTheme.warningColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mock mode aktif - Simülasyon cihazı kullanılıyor',
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
          if (!testController.isConnected) ...[
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
          ] else ...[
            TextButton(
              onPressed: () async {
                Get.back();
                testController.disconnectDevice();
                Get.snackbar(
                  'Bilgi',
                  'Cihaz bağlantısı kesildi',
                  backgroundColor: AppTheme.warningColor,
                  colorText: Colors.white,
                );
              },
              child: const Text('Bağlantıyı Kes'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Tamam'),
            ),
          ],
        ],
      ),
    );
  }

  void _showReportDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              'Rapor Oluştur',
              style: Get.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildReportOption(
              'PDF Raporu',
              'Detaylı performans analizi PDF olarak',
              Icons.picture_as_pdf,
              Colors.red,
              () => _generatePDFReport(),
            ),
            _buildReportOption(
              'Excel Tablosu',
              'Test verilerini Excel formatında export',
              Icons.table_chart,
              Colors.green,
              () => _generateExcelReport(),
            ),
            _buildReportOption(
              'AI Analiz Raporu',
              'Research-grade AI analizi raporu',
              Icons.psychology,
              Colors.purple,
              () => _generateAIReport(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
      ),
      onTap: () {
        Get.back();
        onTap();
      },
    );
  }

  void _showBackupDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Veri Yedekleme',
              style: Get.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _createBackup(),
                    icon: const Icon(Icons.backup),
                    label: const Text('Yedek Oluştur'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _restoreBackup(),
                    icon: const Icon(Icons.restore),
                    label: const Text('Geri Yükle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showHelp() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yardım ve Destek',
              style: Get.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildHelpItem(
                    'Test Nasıl Yapılır?',
                    'Force plate üzerine çıkın, sporcu seçin ve test türünü belirleyin.',
                    Icons.help_outline,
                  ),
                  _buildHelpItem(
                    'AI Analizi Nedir?',
                    'Research-grade algoritmalar ile performans analizi yapar.',
                    Icons.psychology,
                  ),
                  _buildHelpItem(
                    'Cihaz Bağlantı Sorunu',
                    'USB kablosunu kontrol edin ve cihazı yeniden başlatın.',
                    Icons.link_off,
                  ),
                  _buildHelpItem(
                    'Veri Export',
                    'Test sonuçlarını PDF veya Excel formatında export edebilirsiniz.',
                    Icons.file_download,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon) {
    return ExpansionTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
          child: Text(
            description,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  void _showDeveloperDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Geliştirici Bilgileri',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Geliştirici adı - vurgulu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Proje Yöneticisi & Yazılım Mimarı',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Doç. Dr. İzzet İNCE',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.8),
                          AppTheme.primaryColor.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Uzmanlık alanları
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uzmanlık Alanları',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Spor Biyomekaniği ve Kuvvet Analizi\n'
                    '• Mobil Uygulama Geliştirme (Flutter)\n'
                    '• Veri Analizi ve Makine Öğrenmesi\n'
                    '• Spor Teknolojileri',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // İletişim bilgileri
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İletişim',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, color: AppTheme.primaryColor, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'izzetince43@gmail.com',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.school, color: AppTheme.primaryColor, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Ankara Yıldırım Beyazıt Üniversitesi',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Row(
          children: [
            Icon(Icons.article, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Açık Kaynak Lisansları', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bu uygulama aşağıdaki açık kaynak kütüphaneleri kullanmaktadır:',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildLicenseItem('Flutter', 'BSD-3-Clause', 'Google LLC'),
                    _buildLicenseItem('fl_chart', 'BSD-3-Clause', 'Iman Khoshabi'),
                    _buildLicenseItem('get', 'MIT', 'Jonny Borges'),
                    _buildLicenseItem('shared_preferences', 'BSD-3-Clause', 'Flutter Team'),
                    _buildLicenseItem('sqflite', 'MIT', 'Alexandre Roux'),
                    _buildLicenseItem('path_provider', 'BSD-3-Clause', 'Flutter Team'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseItem(String package, String license, String author) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            package,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lisans: $license',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          Text(
            'Yazar: $author',
            style: const TextStyle(color: AppTheme.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Gizlilik Politikası', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Veri Toplama ve Kullanım',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Uygulama sadece yerel cihazınızda veri saklar\n'
                '• Hiçbir kişisel veri internet üzerinden gönderilmez\n'
                '• Test sonuçları sadece sizin cihazınızda kalır\n'
                '• Uygulama internet bağlantısı gerektirmez',
                style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
              SizedBox(height: 16),
              Text(
                'Veri Güvenliği',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Tüm veriler şifrelenmiş olarak saklanır\n'
                '• Veritabanı yerel olarak korunur\n'
                '• Veri yedekleme kullanıcı kontrolündedir',
                style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Row(
          children: [
            Icon(Icons.support, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Destek ve Yardım', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teknik Destek',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, color: AppTheme.primaryColor, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'izzetince43@gmail.com',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sık Sorulan Sorular',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Cihaz bağlantı sorunları için Bluetooth ayarlarını kontrol edin\n'
                    '• Test sonuçları Raporlar bölümünde saklanır\n'
                    '• Veri yedekleme için Ayarlar menüsünü kullanın',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // Helper methods

  String _getConnectionStatus() {
    final testController = Get.find<TestController>();
    return testController.isConnected ? 'Bağlı' : 'Bağlı değil';
  }

  Widget _buildStatisticsContent() {
    return Obx(() {
      final athleteController = Get.find<AthleteController>();
      final stats = athleteController.athleteStats;
      
      return Column(
        children: [
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
                  'Erkek Sporcu',
                  stats.maleCount.toString(),
                  Icons.male,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Kadın Sporcu',
                  stats.femaleCount.toString(),
                  Icons.female,
                  Colors.pink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Tamamlanma',
                  '${stats.profileCompletionPercentage.toStringAsFixed(0)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'En Popüler Spor',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stats.mostPopularSport ?? 'Henüz veri yok',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
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
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textHint,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Action methods

  void _generatePDFReport() {
    Get.snackbar(
      'Bilgi',
      'PDF raporu oluşturuluyor...',
      backgroundColor: AppTheme.primaryColor,
      colorText: Colors.white,
      icon: const Icon(Icons.file_download, color: Colors.white),
    );
  }

  void _generateExcelReport() {
    Get.snackbar(
      'Bilgi',
      'Excel dosyası oluşturuluyor...',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.table_chart, color: Colors.white),
    );
  }

  void _generateAIReport() {
    Get.snackbar(
      'Bilgi',
      'AI analiz raporu oluşturuluyor...',
      backgroundColor: Colors.purple,
      colorText: Colors.white,
      icon: const Icon(Icons.psychology, color: Colors.white),
    );
  }

  void _createBackup() {
    Get.back();
    Get.snackbar(
      'Başarılı',
      'Veri yedeği oluşturuldu',
      backgroundColor: AppTheme.successColor,
      colorText: Colors.white,
      icon: const Icon(Icons.backup, color: Colors.white),
    );
  }

  void _restoreBackup() {
    Get.back();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text(
          'Veri Geri Yükleme',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Mevcut veriler silinecek ve yedekten geri yüklenecek. Devam etmek istiyor musunuz?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Başarılı',
                'Veriler geri yüklendi',
                backgroundColor: AppTheme.successColor,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
            child: const Text('Geri Yükle'),
          ),
        ],
      ),
    );
  }
}