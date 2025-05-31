import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/test_controller.dart';
import '../../presentation/controllers/athlete_controller.dart';

/// Ayarlar ekranı
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Ayarlar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App info section
            _buildAppInfoSection(),
            const SizedBox(height: 24),
            
            // General settings
            _buildGeneralSettings(),
            const SizedBox(height: 24),
            
            // Test settings
            _buildTestSettings(),
            const SizedBox(height: 24),
            
            // Data management
            _buildDataManagement(),
            const SizedBox(height: 24),
            
            // About section
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // App icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          
          // App info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: Get.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v${AppConstants.appVersion}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appDescription,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSettingsSection(
      title: 'Genel Ayarlar',
      icon: Icons.settings,
      children: [
        _buildSwitchSetting(
          title: 'Karanlık Tema',
          subtitle: 'Koyu renk teması kullan',
          value: true, // Always dark for now
          onChanged: null, // Disabled for now
          icon: Icons.dark_mode,
        ),
        
        _buildListSetting(
          title: 'Dil',
          subtitle: 'Türkçe',
          icon: Icons.language,
          onTap: () => _showLanguageDialog(),
        ),
        
        _buildSwitchSetting(
          title: 'Ses Efektleri',
          subtitle: 'Test sırasında ses çal',
          value: true,
          onChanged: (value) {
            Get.snackbar('Ayar', 'Ses ayarı: ${value ? "Açık" : "Kapalı"}');
          },
          icon: Icons.volume_up,
        ),
        
        _buildSwitchSetting(
          title: 'Titreşim',
          subtitle: 'Haptik geri bildirim',
          value: true,
          onChanged: (value) {
            Get.snackbar('Ayar', 'Titreşim ayarı: ${value ? "Açık" : "Kapalı"}');
          },
          icon: Icons.vibration,
        ),
      ],
    );
  }

  Widget _buildTestSettings() {
    return GetBuilder<TestController>(
      builder: (testController) {
        return _buildSettingsSection(
          title: 'Test Ayarları',
          icon: Icons.analytics,
          children: [
            _buildSwitchSetting(
              title: 'Mock Mode',
              subtitle: 'Simülasyon verisi kullan',
              value: testController.isMockMode,
              onChanged: (value) {
                if (value) {
                  testController.enableMockMode();
                } else {
                  testController.disableMockMode();
                }
              },
              icon: Icons.psychology,
            ),
            
            _buildListSetting(
              title: 'Örnekleme Hızı',
              subtitle: '${AppConstants.sampleRate} Hz',
              icon: Icons.speed,
              onTap: () => _showSampleRateDialog(),
            ),
            
            _buildListSetting(
              title: 'Kalibrasyon Süresi',
              subtitle: '${AppConstants.calibrationDuration} saniye',
              icon: Icons.tune,
              onTap: () => _showCalibrationDialog(),
            ),
            
            _buildListSetting(
              title: 'Stabilite Eşiği',
              subtitle: '${AppConstants.weightStabilityThreshold} kg',
              icon: Icons.balance,
              onTap: () => _showStabilityDialog(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataManagement() {
    return GetBuilder<AthleteController>(
      builder: (athleteController) {
        return _buildSettingsSection(
          title: 'Veri Yönetimi',
          icon: Icons.storage,
          children: [
            _buildListSetting(
              title: 'Sporcu Sayısı',
              subtitle: '${athleteController.totalAthletes} kayıtlı sporcu',
              icon: Icons.people,
              onTap: () => _showDataStatsDialog(athleteController),
            ),
            
            _buildListSetting(
              title: 'Veritabanı Boyutu',
              subtitle: 'Yaklaşık 2.5 MB',
              icon: Icons.data_usage,
              onTap: () => _showDatabaseDialog(),
            ),
            
            _buildListSetting(
              title: 'Yedek Al',
              subtitle: 'Tüm verileri dışa aktar',
              icon: Icons.backup,
              onTap: () => _showBackupDialog(),
            ),
            
            _buildListSetting(
              title: 'Verileri Temizle',
              subtitle: 'Tüm test sonuçlarını sil',
              icon: Icons.delete_sweep,
              color: AppTheme.errorColor,
              onTap: () => _showClearDataDialog(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return _buildSettingsSection(
      title: 'Hakkında',
      icon: Icons.info,
      children: [
        _buildListSetting(
          title: 'Geliştirici',
          subtitle: AppConstants.companyName,
          icon: Icons.code,
          onTap: () => _showDeveloperDialog(),
        ),
        
        _buildListSetting(
          title: 'Lisans',
          subtitle: 'Açık kaynak lisansları',
          icon: Icons.article,
          onTap: () => _showLicenseDialog(),
        ),
        
        _buildListSetting(
          title: 'Gizlilik Politikası',
          subtitle: 'Veri koruma ve gizlilik',
          icon: Icons.privacy_tip,
          onTap: () => _showPrivacyDialog(),
        ),
        
        _buildListSetting(
          title: 'Destek',
          subtitle: 'Yardım ve iletişim',
          icon: Icons.support,
          onTap: () => _showSupportDialog(),
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Get.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Settings cards
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Divider(
                      color: AppTheme.darkDivider,
                      height: 1,
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? AppTheme.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildListSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? AppTheme.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppTheme.textHint,
      ),
      onTap: onTap,
    );
  }

  // Dialog methods
  void _showLanguageDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Dil Seçimi', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Türkçe', style: TextStyle(color: Colors.white)),
              value: 'tr',
              groupValue: 'tr',
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                Get.back();
                Get.snackbar('Dil', 'Türkçe seçildi');
              },
            ),
            RadioListTile<String>(
              title: Text('English', style: TextStyle(color: Colors.white)),
              value: 'en',
              groupValue: 'tr',
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                Get.back();
                Get.snackbar('Language', 'English selected');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showSampleRateDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Örnekleme Hızı', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [500, 1000, 2000].map((rate) =>
            RadioListTile<int>(
              title: Text('$rate Hz', style: TextStyle(color: Colors.white)),
              value: rate,
              groupValue: AppConstants.sampleRate,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                Get.back();
                Get.snackbar('Ayar', 'Örnekleme hızı: $value Hz');
              },
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showCalibrationDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Kalibrasyon Süresi', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [2, 3, 5].map((duration) =>
            RadioListTile<int>(
              title: Text('$duration saniye', style: TextStyle(color: Colors.white)),
              value: duration,
              groupValue: AppConstants.calibrationDuration,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                Get.back();
                Get.snackbar('Ayar', 'Kalibrasyon süresi: $value saniye');
              },
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showStabilityDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Stabilite Eşiği', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.2, 0.5, 1.0].map((threshold) =>
            RadioListTile<double>(
              title: Text('$threshold kg', style: TextStyle(color: Colors.white)),
              value: threshold,
              groupValue: AppConstants.weightStabilityThreshold,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                Get.back();
                Get.snackbar('Ayar', 'Stabilite eşiği: $value kg');
              },
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showDataStatsDialog(AthleteController controller) {
    final stats = controller.athleteStats;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Veri İstatistikleri', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Toplam Sporcu:', '${stats.totalCount}'),
            _buildStatRow('Erkek Sporcu:', '${stats.maleCount}'),
            _buildStatRow('Kadın Sporcu:', '${stats.femaleCount}'),
            _buildStatRow('Tamamlanan Profil:', '${stats.completeProfilesCount}'),
            _buildStatRow('En Popüler Spor:', stats.mostPopularSport ?? 'Yok'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showDatabaseDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Veritabanı Bilgileri', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Veritabanı Adı:', AppConstants.databaseName),
            _buildStatRow('Versiyon:', '${AppConstants.databaseVersion}'),
            _buildStatRow('Boyut:', '~2.5 MB'),
            _buildStatRow('Lokasyon:', 'Uygulama Dizini'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                Get.snackbar('Bilgi', 'Veritabanı optimizasyonu tamamlandı');
              },
              icon: Icon(Icons.tune),
              label: Text('Optimize Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Yedek Al', style: TextStyle(color: Colors.white)),
        content: Text(
          'Tüm sporcu verileri ve test sonuçları yedeklenecek. Bu işlem birkaç dakika sürebilir.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Yedekleme',
                'Veriler başarıyla yedeklendi',
                backgroundColor: AppTheme.successColor,
                colorText: Colors.white,
              );
            },
            icon: Icon(Icons.backup),
            label: Text('Yedekle'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Verileri Temizle', style: TextStyle(color: Colors.white)),
        content: Text(
          'TÜM test sonuçları silinecek. Bu işlem geri alınamaz! Sporcu bilgileri korunacak.',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Temizlendi',
                'Test sonuçları silindi',
                backgroundColor: AppTheme.errorColor,
                colorText: Colors.white,
              );
            },
            icon: Icon(Icons.delete_forever),
            label: Text('Sil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeveloperDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Geliştirici Bilgileri', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.companyName,
              style: Get.textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Türkiye\'nin özgün Force Plate analiz sistemi. Yerli ve milli teknoloji ile geliştirilmiştir.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Teknolojiler:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• Flutter & Dart\n• SQLite Database\n• GetX State Management\n• Real-time Data Processing',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Açık Kaynak Lisansları', style: TextStyle(color: Colors.white)),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildLicenseItem('Flutter', 'BSD 3-Clause'),
              _buildLicenseItem('GetX', 'MIT License'),
              _buildLicenseItem('SQLite', 'Public Domain'),
              _buildLicenseItem('Equatable', 'MIT License'),
              _buildLicenseItem('FL Chart', 'BSD 3-Clause'),
              _buildLicenseItem('Intl', 'BSD 3-Clause'),
              _buildLicenseItem('Path Provider', 'BSD 3-Clause'),
              _buildLicenseItem('Logger', 'MIT License'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseItem(String name, String license) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: Colors.white),
            ),
          ),
          Text(
            license,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Gizlilik Politikası', style: TextStyle(color: Colors.white)),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Text(
              '''izForce Gizlilik Politikası

1. Veri Toplama
• Sporcu bilgileri (ad, yaş, spor dalı)
• Test sonuçları ve metrikleri
• Uygulama kullanım verileri

2. Veri Güvenliği
• Tüm veriler yerel cihazda saklanır
• Şifreleme ile korunur
• İnternet bağlantısı gerektirmez

3. Veri Paylaşımı
• Verileriniz üçüncü taraflarla paylaşılmaz
• Dışa aktarma tamamen kullanıcı kontrolündedir
• Anonim istatistikler kullanılabilir

4. Kullanıcı Hakları
• Verilerinizi dilediğiniz zaman silebilirsiniz
• Yedekleme ve geri yükleme hakkınız vardır
• Veri taşınabilirliği desteklenir

Son güncelleme: Mayıs 2025''',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Anladım'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Destek & Yardım', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.email, color: AppTheme.primaryColor),
              title: Text('E-posta Desteği', style: TextStyle(color: Colors.white)),
              subtitle: Text('support@izforce.com', style: TextStyle(color: AppTheme.textSecondary)),
              onTap: () {
                Get.back();
                Get.snackbar('Bilgi', 'E-posta uygulaması açılacak');
              },
            ),
            ListTile(
              leading: Icon(Icons.phone, color: AppTheme.primaryColor),
              title: Text('Telefon Desteği', style: TextStyle(color: Colors.white)),
              subtitle: Text('+90 555 123 45 67', style: TextStyle(color: AppTheme.textSecondary)),
              onTap: () {
                Get.back();
                Get.snackbar('Bilgi', 'Telefon uygulaması açılacak');
              },
            ),
            ListTile(
              leading: Icon(Icons.web, color: AppTheme.primaryColor),
              title: Text('Web Sitesi', style: TextStyle(color: Colors.white)),
              subtitle: Text('www.izforce.com', style: TextStyle(color: AppTheme.textSecondary)),
              onTap: () {
                Get.back();
                Get.snackbar('Bilgi', 'Web sitesi açılacak');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }
}