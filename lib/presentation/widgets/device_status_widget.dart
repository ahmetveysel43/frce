// lib/presentation/widgets/device_status_widget.dart - Provider düzeltmesi
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/usb_controller.dart';
import '../../core/enums/usb_connection_state.dart';

class DeviceStatusWidget extends StatelessWidget {
  const DeviceStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Tek Consumer kullan - UsbController zaten provide edilmiş
    return Consumer<UsbController>(
      builder: (context, usbController, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.usb,
                    color: usbController.isConnected ? Colors.blue : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'USB Force Platform',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusIndicator(usbController.connectionState),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildStatusRow(
                'Bağlantı',
                _getConnectionStatusText(usbController.connectionState),
                usbController.isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 12),
              
              _buildStatusRow(
                'Platform',
                usbController.connectedDeviceId ?? 'Bağlı değil',
                usbController.isConnected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(height: 12),
              
              _buildStatusRow(
                'Sampling Rate',
                usbController.isConnected ? '1000 Hz' : 'Bekleniyor',
                usbController.isConnected ? Colors.green : Colors.orange,
              ),
              
              if (usbController.isConnected && usbController.latestForceData != null) ...[
                const SizedBox(height: 12),
                _buildStatusRow(
                  'Toplam Kuvvet',
                  '${usbController.latestForceData!.totalForce.toStringAsFixed(1)} N',
                  Colors.purple,
                ),
              ],
              
              const SizedBox(height: 16),
              
              if (!usbController.isConnected) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showConnectionDialog(context, usbController);
                    },
                    icon: const Icon(Icons.usb),
                    label: const Text('USB Cihaza Bağlan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      usbController.disconnect();
                    },
                    icon: const Icon(Icons.usb_off),
                    label: const Text('Bağlantıyı Kes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              
              if (usbController.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Hata: ${usbController.errorMessage}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(UsbConnectionState state) {
    Color color;
    IconData icon;
    
    switch (state) {
      case UsbConnectionState.connected:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case UsbConnectionState.connecting:
        color = Colors.orange;
        icon = Icons.sync;
        break;
      case UsbConnectionState.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.usb_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            _getConnectionStatusText(state),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getConnectionStatusText(UsbConnectionState state) {
    switch (state) {
      case UsbConnectionState.connected:
        return 'Bağlı';
      case UsbConnectionState.connecting:
        return 'Bağlanıyor';
      case UsbConnectionState.error:
        return 'Hata';
      case UsbConnectionState.disconnected:
        return 'Bağlı Değil';
      }
  }

  void _showConnectionDialog(BuildContext context, UsbController usbController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('USB Cihaz Bağlantısı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mock USB Force Platform\'a bağlanıyor...'),
            const SizedBox(height: 8),
            const Text('• 1000Hz sampling rate'),
            const Text('• 8 load cell (4+4)'),
            const Text('• C4 sınıfı hassasiyet'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await usbController.connectToDevice('Mock Force Platform');
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? 'Mock USB bağlantısı başarılı! 1000Hz veri akışı başlatıldı.' 
                        : 'Bağlantı hatası: ${usbController.errorMessage}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Mock Bağlan'),
          ),
        ],
      ),
    );
  }
}