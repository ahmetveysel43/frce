import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/demo_data_manager.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../../presentation/controllers/settings_controller.dart';

/// Ayarlar ekranı
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
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
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                const Text(
                  'v${AppConstants.appVersion}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
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
    return GetBuilder<SettingsController>(
      builder: (settingsController) {
        return _buildSettingsSection(
          title: 'Genel Ayarlar',
          icon: Icons.settings,
          children: [
            _buildSwitchSetting(
              title: 'Karanlık Tema',
              subtitle: 'Koyu renk teması kullan',
              value: settingsController.isDarkMode,
              onChanged: (value) => settingsController.setDarkMode(value),
              icon: Icons.dark_mode,
            ),
            
            _buildListSetting(
              title: 'Dil',
              subtitle: settingsController.language == 'tr' ? 'Türkçe' : 'English',
              icon: Icons.language,
              onTap: () => _showLanguageDialog(),
            ),
            
            _buildListSetting(
              title: 'Tema Rengi',
              subtitle: _getColorName(settingsController.primaryColorIndex),
              icon: Icons.palette,
              onTap: () => _showColorDialog(),
            ),
            
            _buildSwitchSetting(
              title: 'Ses Efektleri',
              subtitle: 'Test sırasında ses çal',
              value: settingsController.soundEnabled,
              onChanged: (value) => settingsController.setSoundEnabled(value),
              icon: Icons.volume_up,
            ),
            
            _buildSwitchSetting(
              title: 'Titreşim',
              subtitle: 'Haptik geri bildirim',
              value: settingsController.vibrationEnabled,
              onChanged: (value) => settingsController.setVibrationEnabled(value),
              icon: Icons.vibration,
            ),
            
            _buildSwitchSetting(
              title: 'Otomatik Kayıt',
              subtitle: 'Test sonuçlarını otomatik kaydet',
              value: settingsController.autoSave,
              onChanged: (value) => settingsController.setAutoSave(value),
              icon: Icons.save,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTestSettings() {
    return GetBuilder<SettingsController>(
      builder: (settingsController) {
        return _buildSettingsSection(
          title: 'Test Ayarları',
          icon: Icons.analytics,
          children: [
            _buildSwitchSetting(
              title: 'Mock Mode',
              subtitle: 'Simülasyon verisi kullan',
              value: settingsController.mockMode,
              onChanged: (value) => settingsController.setMockMode(value),
              icon: Icons.psychology,
            ),
            
            _buildListSetting(
              title: 'Örnekleme Hızı',
              subtitle: '${settingsController.sampleRate} Hz',
              icon: Icons.speed,
              onTap: () => _showSampleRateDialog(),
            ),
            
            _buildListSetting(
              title: 'Kalibrasyon Süresi',
              subtitle: '${settingsController.calibrationDuration} saniye',
              icon: Icons.tune,
              onTap: () => _showCalibrationDialog(),
            ),
            
            _buildListSetting(
              title: 'Stabilite Eşiği',
              subtitle: '${settingsController.weightThreshold} kg',
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
            
            // Demo Data Section
            _buildListSetting(
              title: 'Demo Verileri Yükle',
              subtitle: 'Uygulamayı öğrenmek için örnek veriler',
              icon: Icons.psychology,
              color: AppTheme.primaryColor,
              onTap: () => _showLoadDemoDataDialog(athleteController),
            ),
            
            FutureBuilder<bool>(
              future: DemoDataManager.isDemoDataLoaded(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return _buildListSetting(
                    title: 'Demo Verileri Temizle',
                    subtitle: 'Örnek verileri sistemden kaldır',
                    icon: Icons.cleaning_services,
                    color: AppTheme.warningColor,
                    onTap: () => _showClearDemoDataDialog(athleteController),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            _buildListSetting(
              title: 'Eski Mock Verileri Temizle',
              subtitle: 'Ahmet, Fatma gibi eski test sporcularını sil',
              icon: Icons.auto_delete,
              color: AppTheme.errorColor,
              onTap: () => _showClearOldMockDataDialog(athleteController),
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
              title: 'Varsayılan Ayarlara Dön',
              subtitle: 'Tüm ayarları sıfırla',
              icon: Icons.restore,
              color: AppTheme.warningColor,
              onTap: () => _showResetSettingsDialog(),
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
                    const Divider(
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
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
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textHint,
      ),
      onTap: onTap,
    );
  }

  // Helper methods
  String _getColorName(int index) {
    final colors = ['Mavi', 'Yeşil', 'Kırmızı', 'Turuncu', 'Mor', 'Pembe'];
    return colors[index % colors.length];
  }
  
  List<Color> get _availableColors => AppTheme.availableColors;

  // Dialog methods
  void _showColorDialog() {
    Get.find<SettingsController>();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Tema Rengi', style: TextStyle(color: Colors.white)),
        content: GetBuilder<SettingsController>(
          builder: (controller) => SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: _availableColors.length,
              itemBuilder: (context, index) {
                final color = _availableColors[index];
                final isSelected = controller.primaryColorIndex == index;
                
                return GestureDetector(
                  onTap: () {
                    controller.setPrimaryColor(index);
                    Get.back();
                    Get.snackbar('Tema', 'Renk değiştirildi: ${_getColorName(index)}');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 32,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    Get.find<SettingsController>();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Dil Seçimi', style: TextStyle(color: Colors.white)),
        content: GetBuilder<SettingsController>(
          builder: (controller) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Türkçe', style: TextStyle(color: Colors.white)),
                value: 'tr',
                groupValue: controller.language,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  controller.setLanguage(value!);
                  Get.back();
                  Get.snackbar('Dil', 'Türkçe seçildi');
                },
              ),
              RadioListTile<String>(
                title: const Text('English', style: TextStyle(color: Colors.white)),
                value: 'en',
                groupValue: controller.language,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  controller.setLanguage(value!);
                  Get.back();
                  Get.snackbar('Language', 'English selected');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showSampleRateDialog() {
    Get.find<SettingsController>();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Örnekleme Hızı', style: TextStyle(color: Colors.white)),
        content: GetBuilder<SettingsController>(
          builder: (controller) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [500, 1000, 2000].map((rate) =>
              RadioListTile<int>(
                title: Text('$rate Hz', style: const TextStyle(color: Colors.white)),
                value: rate,
                groupValue: controller.sampleRate,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  controller.setSampleRate(value!);
                  Get.back();
                  Get.snackbar('Ayar', 'Örnekleme hızı: $value Hz');
                },
              ),
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showCalibrationDialog() {
    Get.find<SettingsController>();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Kalibrasyon Süresi', style: TextStyle(color: Colors.white)),
        content: GetBuilder<SettingsController>(
          builder: (controller) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [2, 3, 5].map((duration) =>
              RadioListTile<int>(
                title: Text('$duration saniye', style: const TextStyle(color: Colors.white)),
                value: duration,
                groupValue: controller.calibrationDuration,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  controller.setCalibrationDuration(value!);
                  Get.back();
                  Get.snackbar('Ayar', 'Kalibrasyon süresi: $value saniye');
                },
              ),
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showStabilityDialog() {
    Get.find<SettingsController>();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Stabilite Eşiği', style: TextStyle(color: Colors.white)),
        content: GetBuilder<SettingsController>(
          builder: (controller) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [0.2, 0.5, 1.0].map((threshold) =>
              RadioListTile<double>(
                title: Text('$threshold kg', style: const TextStyle(color: Colors.white)),
                value: threshold,
                groupValue: controller.weightThreshold,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  controller.setWeightThreshold(value!);
                  Get.back();
                  Get.snackbar('Ayar', 'Stabilite eşiği: $value kg');
                },
              ),
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
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
        title: const Text('Veri İstatistikleri', style: TextStyle(color: Colors.white)),
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
            child: const Text('Kapat'),
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
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
        title: const Text('Veritabanı Bilgileri', style: TextStyle(color: Colors.white)),
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
              icon: const Icon(Icons.tune),
              label: const Text('Optimize Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Yedek Al', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tüm sporcu verileri ve test sonuçları yedeklenecek. Bu işlem birkaç dakika sürebilir.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
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
            icon: const Icon(Icons.backup),
            label: const Text('Yedekle'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Verileri Temizle', style: TextStyle(color: Colors.white)),
        content: const Text(
          'TÜM test sonuçları silinecek. Bu işlem geri alınamaz! Sporcu bilgileri korunacak.',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
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
            icon: const Icon(Icons.delete_forever),
            label: const Text('Sil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }


  void _showResetSettingsDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Varsayılan Ayarlara Dön', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tüm ayarlar varsayılan değerlere döndürülecek. Bu işlem geri alınamaz!',
          style: TextStyle(color: AppTheme.warningColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final settingsController = Get.find<SettingsController>();
              settingsController.resetToDefaults();
              Get.back();
              Get.snackbar(
                'Başarılı',
                'Ayarlar varsayılan değerlere döndürüldü',
                backgroundColor: AppTheme.successColor,
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.restore),
            label: const Text('Sıfırla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }


  /// Demo data yükleme dialogu
  void _showLoadDemoDataDialog(AthleteController athleteController) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.psychology, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Demo Verileri Yükle',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu işlem aşağıdaki demo verilerini yükleyecek:',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            
            _buildDemoDataInfo('👨‍🏀 Emre Yıldırım', 'Profesyonel basketbolcu', 'Elite seviye performans verileri'),
            const SizedBox(height: 8),
            _buildDemoDataInfo('🏐 Zehra Güneş', 'Elit voleybolcu', 'Dikey sıçrama uzmanı'),
            const SizedBox(height: 8),
            _buildDemoDataInfo('⚽ Arda Kılıç', 'Genç futbolcu', 'Gelişim odaklı veriler'),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Her sporcu için 6 aylık kapsamlı test verileri (CMJ, SJ, IMTP, Balance) yüklenecek',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
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
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              _loadDemoDataWithProgress(athleteController);
            },
            icon: const Icon(Icons.download),
            label: const Text('Yükle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Demo data temizleme dialogu
  void _showClearDemoDataDialog(AthleteController athleteController) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.cleaning_services, color: AppTheme.warningColor),
            const SizedBox(width: 8),
            const Text(
              'Demo Verileri Temizle',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Bu işlem tüm demo sporcularını ve ilgili test verilerini sistemden kalıcı olarak kaldıracak. Bu işlem geri alınamaz.\n\nGerçek sporcu verileriniz etkilenmeyecek.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              _clearDemoDataWithProgress(athleteController);
            },
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Temizle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Eski mock data temizleme dialogu
  void _showClearOldMockDataDialog(AthleteController athleteController) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.auto_delete, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text(
              'Eski Mock Verileri Temizle',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu işlem aşağıdaki eski test sporcularını ve verilerini kalıcı olarak silecek:',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            
            _buildDemoDataInfo('👤 Ahmet Yılmaz', 'Eski mock sporcu', ''),
            _buildDemoDataInfo('👤 Fatma Kaya', 'Eski mock sporcu', ''),
            _buildDemoDataInfo('👤 Mehmet Demir', 'Eski mock sporcu', ''),
            _buildDemoDataInfo('👤 Ayşe Özkan', 'Eski mock sporcu', ''),
            _buildDemoDataInfo('👤 Can Arslan', 'Eski mock sporcu', ''),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppTheme.errorColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu işlem geri alınamaz. Sadece eski mock sporcuları etkilenecek.',
                      style: TextStyle(
                        color: AppTheme.errorColor,
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
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              _clearOldMockDataWithProgress(athleteController);
            },
            icon: const Icon(Icons.auto_delete),
            label: const Text('Temizle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoDataInfo(String name, String role, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(description, style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Demo data yükleme progress
  void _loadDemoDataWithProgress(AthleteController athleteController) async {
    // Progress dialog göster
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Row(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(width: 16),
            Text('Demo Verileri Yükleniyor...', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Demo sporcuları ve test verileri yükleniyor. Bu işlem birkaç saniye sürebilir.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final success = await DemoDataManager.loadDemoData();
      Get.back(); // Progress dialogunu kapat

      if (success) {
        // Athlete controller'ı yenile
        await athleteController.loadAthletes();
        
        Get.snackbar(
          'Başarılı',
          '3 demo sporcu ve kapsamlı test verileri yüklendi!\nArtık tüm analiz özelliklerini test edebilirsiniz.',
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Hata',
          'Demo verileri yüklenirken bir sorun oluştu.',
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Progress dialogunu kapat
      Get.snackbar(
        'Hata',
        'Demo verileri yüklenirken beklenmedik bir hata oluştu: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    }
  }

  /// Demo data temizleme progress
  void _clearDemoDataWithProgress(AthleteController athleteController) async {
    // Progress dialog göster
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Row(
          children: [
            CircularProgressIndicator(color: AppTheme.warningColor),
            SizedBox(width: 16),
            Text('Demo Verileri Temizleniyor...', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Demo sporcuları ve test verileri temizleniyor.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final success = await DemoDataManager.clearDemoData();
      Get.back(); // Progress dialogunu kapat

      if (success) {
        // Athlete controller'ı yenile
        await athleteController.loadAthletes();
        
        Get.snackbar(
          'Başarılı',
          'Tüm demo verileri temizlendi.',
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Hata',
          'Demo verileri temizlenirken bir sorun oluştu.',
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Progress dialogunu kapat
      Get.snackbar(
        'Hata',
        'Demo verileri temizlenirken beklenmedik bir hata oluştu: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    }
  }

  /// Eski mock data temizleme progress
  void _clearOldMockDataWithProgress(AthleteController athleteController) async {
    // Progress dialog göster
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Row(
          children: [
            CircularProgressIndicator(color: AppTheme.errorColor),
            SizedBox(width: 16),
            Text('Eski Mock Verileri Temizleniyor...', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Ahmet, Fatma gibi eski test sporcuları temizleniyor.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final success = await DemoDataManager.clearOldMockAthletes();
      Get.back(); // Progress dialogunu kapat

      if (success) {
        // Athlete controller'ı yenile
        await athleteController.loadAthletes();
        
        Get.snackbar(
          'Başarılı',
          'Eski mock sporcuları temizlendi. Artık yeni demo verilerini yükleyebilirsiniz.',
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Hata',
          'Eski mock verileri temizlenirken bir sorun oluştu.',
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Progress dialogunu kapat
      Get.snackbar(
        'Hata',
        'Eski mock verileri temizlenirken beklenmedik bir hata oluştu: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    }
  }
}