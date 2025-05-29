// lib/presentation/widgets/device_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_controller.dart';

class DeviceStatusWidget extends StatelessWidget {
  const DeviceStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, child) {
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
                    Icons.bluetooth,
                    color: controller.isBluetoothConnected ? Colors.blue : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Cihaz Durumu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusIndicator(controller.bluetoothState),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildStatusRow(
                'Bağlantı',
                _getConnectionStatusText(controller.bluetoothState),
                controller.isBluetoothConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 12),
              
              _buildStatusRow(
                'Platform',
                'Mock Device - IzForce 001',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              
              _buildStatusRow(
                'Kalibrasyon',
                controller.isBluetoothConnected ? 'Hazır' : 'Bekleniyor',
                controller.isBluetoothConnected ? Colors.green : Colors.orange,
              ),
              
              if (!controller.isBluetoothConnected) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showConnectionDialog(context, controller);
                    },
                    icon: const Icon(Icons.bluetooth_connected),
                    label: const Text('Cihaza Bağlan'),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.toggleBluetoothConnection();
                    },
                    icon: const Icon(Icons.bluetooth_disabled),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(BluetoothConnectionState state) {
    Color color;
    IconData icon;
    
    switch (state) {
      case BluetoothConnectionState.connected:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case BluetoothConnectionState.connecting:
        color = Colors.orange;
        icon = Icons.sync;
        break;
      case BluetoothConnectionState.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.bluetooth_disabled;
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

  String _getConnectionStatusText(BluetoothConnectionState state) {
    switch (state) {
      case BluetoothConnectionState.connected:
        return 'Bağlı';
      case BluetoothConnectionState.connecting:
        return 'Bağlanıyor';
      case BluetoothConnectionState.error:
        return 'Hata';
      case BluetoothConnectionState.disconnected:
      return 'Bağlı Değil';
    }
  }

  void _showConnectionDialog(BuildContext context, AppController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cihaz Bağlantısı'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mock modda çalışıyorsunuz.'),
            SizedBox(height: 8),
            Text('Gerçek cihaz bağlantısı için:'),
            SizedBox(height: 8),
            Text('• Bluetooth\'u açın'),
            Text('• IzForce platformunu açın'),
            Text('• Cihazlar menüsünden bağlanın'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.toggleBluetoothConnection();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mock bağlantı başarılı!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Mock Bağlantı'),
          ),
        ],
      ),
    );
  }
}