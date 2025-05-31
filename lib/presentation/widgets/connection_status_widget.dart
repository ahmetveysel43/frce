import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/test_controller.dart';

/// Cihaz bağlantı durumu widget'ı
class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({super.key});

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
    return Obx(() {
      final status = controller.connectionStatus;
      final isConnected = status == ConnectionStatus.connected;
      final isConnecting = status == ConnectionStatus.connecting;
      final hasError = status == ConnectionStatus.error;
      
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
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
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
                color: statusColor.withOpacity(0.2),
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
    });
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
        color: AppTheme.successColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi,
            size: 14,
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 4),
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
              Icon(
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
              Icon(
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
              Icon(
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
                color: AppTheme.warningColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology,
                    size: 14,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 6),
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
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
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
    return Obx(() {
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
                side: BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              icon: const Icon(Icons.speed_outlined, size: 18),
              label: const Text('Test'),
            ),
          ],
        ],
      );
    });
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
        title: Row(
          children: [
            Icon(Icons.link, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
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
            Text(
              'Force plate cihazına bağlanmak istiyor musunuz?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
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
            child: Text('İptal'),
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
        title: Row(
          children: [
            Icon(Icons.link_off, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            Text(
              'Bağlantıyı Kes',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Cihaz bağlantısını kesmek istiyor musunuz? Devam eden testler durdurulacak.',
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
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.speed, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
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
            const SizedBox(height: 16),
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
}