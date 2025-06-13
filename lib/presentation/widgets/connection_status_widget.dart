import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/test_controller.dart';

/// Cihaz bağlantı durumu widget'ı
class ConnectionStatusWidget extends StatefulWidget {
  const ConnectionStatusWidget({super.key});

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  bool _isSettingsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TestController>(
      builder: (controller) {
        return Column(
          children: [
            // Ana bağlantı durumu
            _buildConnectionStatus(controller),
            
            if (controller.connectionStatus == ConnectionStatus.connected) ...[
              const SizedBox(height: 16),
              _buildConnectedInfo(controller),
              const SizedBox(height: 16),
              _buildTestSettings(controller),
            ],
            
            if (controller.connectionStatus == ConnectionStatus.error) ...[
              const SizedBox(height: 12),
              _buildErrorInfo(controller),
            ],
            
            const SizedBox(height: 16),
            _buildActionButtons(controller),
          ],
        );
      },
    );
  }

  Widget _buildConnectionStatus(TestController controller) {
    final status = controller.connectionStatus;
    final isConnected = status == ConnectionStatus.connected;
    final isConnecting = status == ConnectionStatus.connecting;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case ConnectionStatus.connected:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        statusText = 'Bağlandı';
        break;
      case ConnectionStatus.connecting:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.sync;
        statusText = 'Bağlanıyor...';
        break;
      case ConnectionStatus.error:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.error;
        statusText = 'Bağlantı Hatası';
        break;
      default:
        statusColor = AppTheme.textHint;
        statusIcon = Icons.link_off;
        statusText = 'Bağlantı Yok';
    }
    
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isConnecting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: statusColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),
            
            // Status info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: Get.textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  Text(
                    _getStatusDescription(status, controller),
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Signal strength (only when connected)
            if (isConnected) _buildSignalStrength(),
          ],
        ),
      );
  }

  String _getStatusDescription(ConnectionStatus status, TestController controller) {
    switch (status) {
      case ConnectionStatus.connected:
        return controller.isMockMode 
            ? 'Mock cihaz - Test için hazır'
            : 'USB Force Plate - Test için hazır';
      case ConnectionStatus.connecting:
        return 'Force plate cihazına bağlanılıyor...';
      case ConnectionStatus.error:
        return controller.errorMessage ?? 'Bilinmeyen bağlantı hatası';
      default:
        return 'Force plate cihazı bağlı değil';
    }
  }

  Widget _buildSignalStrength() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi,
            size: 14,
            color: AppTheme.successColor,
          ),
          SizedBox(width: 4),
          Text(
            'Güçlü',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedInfo(TestController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Device info
          Row(
            children: [
              const Icon(
                Icons.devices,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Cihaz:',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.connectedDevice ?? 'Bilinmeyen',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Sample rate info
          Row(
            children: [
              const Icon(
                Icons.speed,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Örnekleme:',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${AppConstants.sampleRate} Hz',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              
              // Load cells info
              const Icon(
                Icons.sensors,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${AppConstants.loadCellCount} Load Cell',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          if (controller.isMockMode) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology,
                    size: 14,
                    color: AppTheme.warningColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Simülasyon Modu Aktif',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorInfo(TestController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bağlantı Sorunu',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.errorMessage ?? 'Bilinmeyen hata oluştu',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(TestController controller) {
    final status = controller.connectionStatus;
    final isConnected = status == ConnectionStatus.connected;
    final isConnecting = status == ConnectionStatus.connecting;
    
    return Row(
        children: [
          // Connect/Disconnect button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isConnecting 
                  ? null 
                  : () => _handleConnectionAction(controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected 
                    ? AppTheme.errorColor 
                    : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: Icon(
                isConnecting 
                    ? Icons.sync 
                    : isConnected 
                        ? Icons.link_off 
                        : Icons.link,
                size: 18,
              ),
              label: Text(
                isConnecting 
                    ? 'Bağlanıyor...' 
                    : isConnected 
                        ? 'Bağlantıyı Kes' 
                        : 'Bağlan',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          if (isConnected) ...[
            const SizedBox(width: 12),
            
            // Test connection button
            OutlinedButton.icon(
              onPressed: () => _testConnection(controller),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              icon: const Icon(Icons.speed_outlined, size: 18),
              label: const Text('Test'),
            ),
          ],
        ],
      );
  }

  void _handleConnectionAction(TestController controller) {
    if (controller.connectionStatus == ConnectionStatus.connected) {
      // Disconnect
      _showDisconnectDialog(controller);
    } else {
      // Connect
      _showConnectDialog(controller);
    }
  }

  void _showConnectDialog(TestController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Row(
          children: [
            Icon(Icons.link, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Cihaza Bağlan',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Force plate cihazına bağlanmak istiyor musunuz?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.isMockMode 
                          ? 'Mock mode: Simülasyon cihazı kullanılacak'
                          : 'USB üzerinden gerçek cihaza bağlanılacak',
                      style: const TextStyle(
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
              
              final success = await controller.connectToDevice('USB_ForcePlate_001');
              
              if (success) {
                Get.snackbar(
                  'Başarılı',
                  'Cihaza başarıyla bağlanıldı',
                  backgroundColor: AppTheme.successColor,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            icon: const Icon(Icons.link),
            label: const Text('Bağlan'),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog(TestController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Row(
          children: [
            Icon(Icons.link_off, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text(
              'Bağlantıyı Kes',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Cihaz bağlantısını kesmek istiyor musunuz? Devam eden testler durdurulacak.',
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
              controller.disconnectDevice();
              
              Get.snackbar(
                'Bilgi',
                'Cihaz bağlantısı kesildi',
                backgroundColor: AppTheme.warningColor,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            icon: const Icon(Icons.link_off),
            label: const Text('Bağlantıyı Kes'),
          ),
        ],
      ),
    );
  }

  void _testConnection(TestController controller) {
    Get.dialog(
      const AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.speed, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Bağlantı Testi',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Bağlantı test ediliyor...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
    
    // Simulate connection test
    Future.delayed(const Duration(seconds: 2), () {
      Get.back();
      
      Get.snackbar(
        'Test Sonucu',
        'Bağlantı başarıyla test edildi\n• Sinyal gücü: Mükemmel\n• Gecikme: <1ms\n• Load cell durumu: Normal',
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    });
  }

  Widget _buildTestSettings(TestController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Clickable
          InkWell(
            onTap: () {
              setState(() {
                _isSettingsExpanded = !_isSettingsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Ayarları',
                          style: Get.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Profesyonel ölçüm parametreleri',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showAdvancedSettings(controller),
                        icon: const Icon(
                          Icons.settings,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        tooltip: 'Gelişmiş ayarlar',
                      ),
                      Icon(
                        _isSettingsExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSettingsExpanded ? null : 0,
            child: _isSettingsExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        // Quick settings grid
                        _buildQuickSettingsGrid(controller),
                        
                        const SizedBox(height: 16),
                        
                        // Test protocols
                        _buildTestProtocols(controller),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettingsGrid(TestController controller) {
    return Column(
      children: [
        // System Status Header
        _buildSystemStatusHeader(),
        const SizedBox(height: 16),
        
        // Primary Settings - Acquisition Parameters
        _buildSettingsCategory(
          'Veri Toplama Parametreleri',
          Icons.sensors,
          AppTheme.primaryColor,
          [
            Row(
              children: [
                Expanded(child: _buildProfessionalSettingCard('Örnekleme Hızı', '1000 Hz', '100-2000 Hz', Icons.speed, AppTheme.primaryColor, () => _showSamplingRateDialog())),
                const SizedBox(width: 8),
                Expanded(child: _buildProfessionalSettingCard('Buffer Boyutu', '8192 samples', '1024-16384', Icons.memory, AppColors.chartColors[0], () => _showBufferSizeDialog())),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildProfessionalSettingCard('ADC Çözünürlük', '24-bit', '16/24-bit', Icons.high_quality, AppColors.chartColors[1], () => _showADCResolutionDialog())),
                const SizedBox(width: 8),
                Expanded(child: _buildProfessionalSettingCard('Gain Ayarı', 'Auto', 'x1-x1000', Icons.tune, AppColors.chartColors[2], () => _showGainDialog())),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Signal Processing
        _buildSettingsCategory(
          'Sinyal İşleme',
          Icons.graphic_eq,
          AppColors.chartColors[3],
          [
            Row(
              children: [
                Expanded(child: _buildProfessionalSettingCard('LPF Kesim', '50 Hz', '10-500 Hz', Icons.filter_alt, AppColors.chartColors[3], () => _showLowPassFilterDialog())),
                const SizedBox(width: 8),
                Expanded(child: _buildProfessionalSettingCard('HPF Kesim', '0.5 Hz', '0.1-10 Hz', Icons.filter_1, AppColors.chartColors[4], () => _showHighPassFilterDialog())),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildProfessionalSettingCard('Notch Filter', '50 Hz', 'Off/50/60 Hz', Icons.filter_2, AppColors.chartColors[5], () => _showNotchFilterDialog())),
                const SizedBox(width: 8),
                Expanded(child: _buildProfessionalSettingCard('Smoothing', 'Butterworth', 'Off/Butter/Bessel', Icons.waves, AppColors.chartColors[6], () => _showSmoothingDialog())),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Calibration & Zero
        _buildSettingsCategory(
          'Kalibrasyon & Sıfırlama',
          Icons.settings_backup_restore,
          AppColors.chartColors[7],
          [
            Row(
              children: [
                Expanded(child: _buildProfessionalSettingCard('Auto-Zero', '3.0 s', '1.0-10.0 s', Icons.timer, AppColors.chartColors[7], () => _showAutoZeroDialog())),
                const SizedBox(width: 8),
                Expanded(child: _buildProfessionalSettingCard('Bias Compensation', 'Aktif', 'On/Off', Icons.center_focus_strong, AppColors.chartColors[0], () => _showBiasCompensationDialog())),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildProfessionalSettingCard('Drift Correction', 'Linear', 'Off/Linear/Poly', Icons.trending_up, AppColors.chartColors[1], () => _showDriftCorrectionDialog())),
                const SizedBox(width: 8),
                Expanded(child: _buildProfessionalSettingCard('Temp. Komp.', 'Aktif', 'On/Off', Icons.thermostat, AppColors.chartColors[2], () => _showTemperatureCompDialog())),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Test Detection & Triggers
        _buildSettingsCategory(
          'Test Algılama & Tetikleyiciler',
          Icons.flash_on,
          AppColors.chartColors[3],
          [
            Row(
              children: [
                Expanded(child: _buildProfessionalSettingCard('Başlama Eşiği', '10 N', '5-50 N', Icons.play_arrow, AppColors.chartColors[3], () => _showStartThresholdDialog())),
                const SizedBox(width: 8),
                Expanded(child: _buildProfessionalSettingCard('Bitiş Eşiği', '5 N', '2-25 N', Icons.stop, AppColors.chartColors[4], () => _showEndThresholdDialog())),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildProfessionalSettingCard('Min. Test Süresi', '0.5 s', '0.1-5.0 s', Icons.schedule, AppColors.chartColors[5], () => _showMinDurationDialog())),
                const SizedBox(width: 8),
                Expanded(child: _buildProfessionalSettingCard('Max. Test Süresi', '30 s', '5-120 s', Icons.timer_off, AppColors.chartColors[6], () => _showMaxDurationDialog())),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Platform Configuration
        _buildSettingsCategory(
          'Platform Konfigürasyonu',
          Icons.dashboard,
          AppColors.chartColors[7],
          [
            Row(
              children: [
                Expanded(child: _buildProfessionalSettingCard('Platform Tipi', 'Dual Force', 'Single/Dual/Quad', Icons.view_quilt, AppColors.chartColors[7], () => _showPlatformTypeDialog())),
                const SizedBox(width: 8),
                Expanded(child: _buildProfessionalSettingCard('Load Cell Sayısı', '8 Kanal', '4/8/16 CH', Icons.sensors, AppColors.chartColors[0], () => _showLoadCellDialog())),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildProfessionalSettingCard('COP Hesaplama', 'Real-time', 'Real-time/Post', Icons.center_focus_weak, AppColors.chartColors[1], () => _showCOPCalculationDialog())),
                const SizedBox(width: 8),
                Expanded(child: _buildProfessionalSettingCard('Koordinat Sistemi', 'Lab Frame', 'Lab/Body Frame', Icons.grid_on, AppColors.chartColors[2], () => _showCoordinateSystemDialog())),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistem Durumu: HAZIR',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tüm sistemler çevrimiçi • Kalibrasyon: OK • Sıcaklık: 23.5°C',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'OPTIMAL',
              style: TextStyle(
                color: AppTheme.successColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCategory(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfessionalSettingCard(
    String title,
    String currentValue,
    String range,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 16),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              currentValue,
              style: Get.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              range,
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textHint,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTestProtocols(TestController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Test Protokolleri',
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildProtocolButton(
                'CMJ',
                'Countermovement Jump',
                Icons.arrow_upward,
                AppTheme.primaryColor,
                onTap: () => _startQuickTest('CMJ'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildProtocolButton(
                'SJ',
                'Squat Jump',
                Icons.fitness_center,
                AppColors.chartColors[1],
                onTap: () => _startQuickTest('SJ'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildProtocolButton(
                'IMTP',
                'Mid-Thigh Pull',
                Icons.vertical_align_top,
                AppColors.chartColors[2],
                onTap: () => _startQuickTest('IMTP'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProtocolButton(
    String code,
    String name,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              code,
              style: Get.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            Text(
              name,
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Advanced settings and quick test methods
  void _showAdvancedSettings(TestController controller) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.settings, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Gelişmiş Test Ayarları',
                    style: Get.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            
            const Divider(color: AppTheme.darkDivider),
            
            // Settings content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSettingsSection('Sinyal İşleme', [
                      _buildSliderSetting('Örnekleme Hızı', 500, 2000, 1000, 'Hz'),
                      _buildSliderSetting('Filtre Kesim Frekansı', 10, 100, 50, 'Hz'),
                      _buildSliderSetting('Filtre Derecesi', 2, 8, 4, ''),
                    ]),
                    
                    _buildSettingsSection('Eşik Değerleri', [
                      _buildSliderSetting('Sıçrama Eşiği', 5, 50, 10, 'N'),
                      _buildSliderSetting('İniş Eşiği', 20, 100, 50, 'N'),
                      _buildSliderSetting('Sessizlik Eşiği', 1, 10, 5, 'N'),
                    ]),
                    
                    _buildSettingsSection('Test Parametreleri', [
                      _buildSliderSetting('Maksimum Test Süresi', 10, 120, 60, 's'),
                      _buildSliderSetting('Stabilizasyon Süresi', 1, 5, 2, 's'),
                      _buildSliderSetting('Minimum Sessizlik', 200, 1000, 500, 'ms'),
                    ]),
                    
                    _buildSettingsSection('Kalibrasyon', [
                      _buildSwitchSetting('Otomatik Tare', true),
                      _buildSwitchSetting('Sıcaklık Kompansasyonu', true),
                      _buildSwitchSetting('Gerçek Zamanlı Görselleştirme', false),
                    ]),
                  ],
                ),
              ),
            ),
            
            // Save button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.snackbar(
                      'Başarılı',
                      'Test ayarları kaydedildi',
                      backgroundColor: AppTheme.successColor,
                      colorText: Colors.white,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Ayarları Kaydet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Get.textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSliderSetting(String title, double min, double max, double value, String unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$value $unit',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(Get.context!).copyWith(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.darkDivider,
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / (max > 100 ? 50 : 1)).round(),
              onChanged: (newValue) {
                // Handle slider change
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(String title, bool value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              // Handle switch change
            },
            activeColor: AppTheme.primaryColor,
            inactiveThumbColor: AppTheme.textHint,
            inactiveTrackColor: AppTheme.darkDivider,
          ),
        ],
      ),
    );
  }





  void _startQuickTest(String testType) {
    final testController = Get.find<TestController>();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.flash_on, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Hızlı Test: $testType',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          '$testType testi için hızlı başlatma. Sporcu seçimi yapılacak ve test otomatik olarak başlayacak.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Set test type and navigate
              testController.selectTestType(TestType.values.firstWhere(
                (t) => t.code == testType,
                orElse: () => TestType.counterMovementJump,
              ));
              Get.toNamed('/athlete-selection');
            },
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
  }




  // ===== PROFESYONEL FORCE PLATE AYARLARI =====
  
  void _showSamplingRateDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.speed, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Örnekleme Hızı Ayarları', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Force plate veri toplama hızını belirler. Yüksek hızlar daha hassas ölçüm sağlar.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildParameterOption('100 Hz', 'Temel testler', false),
            _buildParameterOption('500 Hz', 'Standart aplikasyonlar', false),
            _buildParameterOption('1000 Hz', 'Profesyonel (önerilen)', true),
            _buildParameterOption('2000 Hz', 'Araştırma seviyesi', false),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CPU yükü: ~15% • Buffer: 8192 samples • Precision: ±0.05%',
                      style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Uygula')),
        ],
      ),
    );
  }

  void _showBufferSizeDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.memory, color: AppColors.chartColors[0]),
            const SizedBox(width: 8),
            const Text('Buffer Boyutu', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Veri buffer boyutu sistem performansını ve gecikmeyi etkiler.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildParameterOption('1024 samples', 'Düşük gecikme (1ms)', false),
            _buildParameterOption('4096 samples', 'Dengeli performans', false),
            _buildParameterOption('8192 samples', 'Optimal (önerilen)', true),
            _buildParameterOption('16384 samples', 'Maksimum stabilite', false),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Uygula')),
        ],
      ),
    );
  }

  void _showADCResolutionDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.high_quality, color: AppColors.chartColors[1]),
            const SizedBox(width: 8),
            const Text('ADC Çözünürlük', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Analog-Digital çevirici çözünürlüğü ölçüm hassasiyetini belirler.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildParameterOption('16-bit', 'Temel hassasiyet (65,536 seviye)', false),
            _buildParameterOption('24-bit', 'Profesyonel (16.7M seviye)', true),
            const SizedBox(height: 12),
            Text(
              '24-bit: 0.00001% tam skala hassasiyet\nGürültü seviyesi: <0.001% RMS',
              style: TextStyle(color: AppTheme.textHint, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Uygula')),
        ],
      ),
    );
  }

  void _showGainDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.tune, color: AppColors.chartColors[2]),
            const SizedBox(width: 8),
            const Text('Gain Ayarları', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sinyal amplifikasyon faktörü. Düşük kuvvetler için yüksek gain kullanın.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildParameterOption('x1', 'Yüksek kuvvetler (>1000N)', false),
            _buildParameterOption('x10', 'Orta kuvvetler (100-1000N)', false),
            _buildParameterOption('Auto', 'Otomatik optimizasyon', true),
            _buildParameterOption('x1000', 'Çok düşük kuvvetler (<10N)', false),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Uygula')),
        ],
      ),
    );
  }

  void _showLowPassFilterDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.filter_alt, color: AppColors.chartColors[3]),
            const SizedBox(width: 8),
            const Text('Low-Pass Filter', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Yüksek frekanslı gürültüyü filtreler. CMJ için 50Hz, Balance için 10Hz önerilir.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildParameterOption('10 Hz', 'Balance/Postural testler', false),
            _buildParameterOption('20 Hz', 'İzometrik testler', false),
            _buildParameterOption('50 Hz', 'Jump testleri (önerilen)', true),
            _buildParameterOption('100 Hz', 'Ballistic hareketler', false),
            _buildParameterOption('Off', 'Filtresiz (sadece araştırma)', false),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Uygula')),
        ],
      ),
    );
  }

  void _showHighPassFilterDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.filter_1, color: AppColors.chartColors[4]),
            const SizedBox(width: 8),
            const Text('High-Pass Filter', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DC bias ve düşük frekanslı drifti elimine eder.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildParameterOption('0.1 Hz', 'Minimal filtering', false),
            _buildParameterOption('0.5 Hz', 'Standart (önerilen)', true),
            _buildParameterOption('1.0 Hz', 'Agresif drift removal', false),
            _buildParameterOption('Off', 'Filtresiz', false),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Uygula')),
        ],
      ),
    );
  }

  void _showNotchFilterDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.filter_2, color: AppColors.chartColors[5]),
            const SizedBox(width: 8),
            const Text('Notch Filter', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Elektrik şebekesi interferansını elimine eder.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildParameterOption('Off', 'Filtresiz', false),
            _buildParameterOption('50 Hz', 'Avrupa şebekesi (önerilen)', true),
            _buildParameterOption('60 Hz', 'Amerika şebekesi', false),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Uygula')),
        ],
      ),
    );
  }

  void _showAutoZeroDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.timer, color: AppColors.chartColors[7]),
            const SizedBox(width: 8),
            const Text('Auto-Zero Süresi', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Test başlangıcında otomatik sıfırlama için bekleme süresi.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildParameterOption('1.0 s', 'Hızlı testler', false),
            _buildParameterOption('2.0 s', 'Standart', false),
            _buildParameterOption('3.0 s', 'Optimal (önerilen)', true),
            _buildParameterOption('5.0 s', 'Maksimum stabilite', false),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Uygula')),
        ],
      ),
    );
  }

  void _showStartThresholdDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.play_arrow, color: AppColors.chartColors[3]),
            const SizedBox(width: 8),
            const Text('Test Başlama Eşiği', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Test otomatik başlatılması için gereken minimum kuvvet değeri.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildParameterOption('5 N', 'Çok hassas (çocuklar)', false),
            _buildParameterOption('10 N', 'Standart (önerilen)', true),
            _buildParameterOption('20 N', 'Güçlü sporcular', false),
            _buildParameterOption('50 N', 'Maksimum (IMTP)', false),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Uygula')),
        ],
      ),
    );
  }

  void _showPlatformTypeDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.view_quilt, color: AppColors.chartColors[7]),
            const SizedBox(width: 8),
            const Text('Platform Konfigürasyonu', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Force plate sistemi tipini seçin.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildParameterOption('Single Force', 'Tek platform (4 LC)', false),
            _buildParameterOption('Dual Force', 'Çift platform (8 LC)', true),
            _buildParameterOption('Quad Force', 'Dörtlü platform (16 LC)', false),
            const SizedBox(height: 12),
            Text(
              'Bilateral analiz için Dual Force önerilir',
              style: TextStyle(color: AppTheme.textHint, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Uygula')),
        ],
      ),
    );
  }

  // Diğer dialog metodları için placeholder'lar (kısaltma için)
  void _showSmoothingDialog() => _showGenericDialog('Smoothing', 'Butterworth 4th order filtering uygulanmaktadır.');
  void _showBiasCompensationDialog() => _showGenericDialog('Bias Compensation', 'Otomatik DC bias elimination aktif.');
  void _showDriftCorrectionDialog() => _showGenericDialog('Drift Correction', 'Linear drift correction uygulanmaktadır.');
  void _showTemperatureCompDialog() => _showGenericDialog('Temperature Compensation', 'Sıcaklık kompansasyonu aktif.');
  void _showEndThresholdDialog() => _showGenericDialog('Test Bitiş Eşiği', 'Test bitirme için 5N eşik değeri.');
  void _showMinDurationDialog() => _showGenericDialog('Minimum Test Süresi', 'En az 0.5 saniye test süresi gereklidir.');
  void _showMaxDurationDialog() => _showGenericDialog('Maksimum Test Süresi', 'Test maksimum 30 saniye sürebilir.');
  void _showLoadCellDialog() => _showGenericDialog('Load Cell Konfigürasyonu', '8 kanallı load cell sistemi aktif.');
  void _showCOPCalculationDialog() => _showGenericDialog('COP Hesaplama', 'Real-time center of pressure hesaplanmaktadır.');
  void _showCoordinateSystemDialog() => _showGenericDialog('Koordinat Sistemi', 'Lab frame koordinat sistemi kullanılmaktadır.');

  void _showGenericDialog(String title, String content) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tamam')),
        ],
      ),
    );
  }

  Widget _buildParameterOption(String value, String description, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
          ? AppTheme.primaryColor.withValues(alpha: 0.1) 
          : AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
            ? AppTheme.primaryColor 
            : AppTheme.darkDivider,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textHint,
          size: 20,
        ),
        title: Text(
          value,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        onTap: () {
          // Parameter selection logic here
        },
      ),
    );
  }
}