// lib/presentation/screens/izforce_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/usb_controller.dart';
import '../../domain/entities/force_data.dart';

class IzForceDashboardScreen extends StatefulWidget {
  const IzForceDashboardScreen({super.key});

  @override
  State<IzForceDashboardScreen> createState() => _IzForceDashboardScreenState();
}

class _IzForceDashboardScreenState extends State<IzForceDashboardScreen> {
  String _selectedTestScenario = 'sakin_durus';
  
  final Map<String, String> _testScenarios = {
    'sakin_durus': 'Sakin Duruş',
    'karsi_hareket_sicrami': 'Karşı Hareket Sıçraması',
    'denge_testi': 'Denge Testi',
    'izometrik_test': 'İzometrik Test',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'IzForce Kuvvet Platformu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<UsbController>(
            builder: (context, controller, child) {
              return IconButton(
                icon: Icon(
                  controller.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: controller.isConnected ? Colors.green : Colors.grey,
                ),
                onPressed: controller.isConnected 
                    ? () => controller.disconnect()
                    : () => _showConnectionDialog(context, controller),
              );
            },
          ),
        ],
      ),
      body: Consumer<UsbController>(
        builder: (context, controller, child) {
          if (!controller.isConnected) {
            return _buildConnectionScreen(controller);
          }
          return _buildDashboard(controller);
        },
      ),
    );
  }

  Widget _buildConnectionScreen(UsbController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sensors_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'IzForce Platform Bağlantısı Kesildi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Çift kuvvet platformuna bağlanarak başlayın',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showConnectionDialog(context, controller),
            icon: const Icon(Icons.link),
            label: const Text('IzForce Platformuna Bağlan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(UsbController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bağlantı Durumu Kartı
          _buildConnectionStatusCard(controller),
          const SizedBox(height: 16),
          
          // Test Senaryosu Seçimi
          _buildTestScenarioCard(controller),
          const SizedBox(height: 16),
          
          // Gerçek Zamanlı Metrikler
          _buildRealTimeMetricsCard(controller),
          const SizedBox(height: 16),
          
          // Çift Platform Görselleştirmesi
          _buildDualPlatformCard(controller),
          const SizedBox(height: 16),
          
          // Asimetri Analizi
          _buildAsymmetryAnalysisCard(controller),
          const SizedBox(height: 16),
          
          // Basınç Merkezi
          _buildCenterOfPressureCard(controller),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(UsbController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sensors, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IzForce Platform Bağlandı',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      controller.connectedDeviceId ?? 'Bilinmeyen Cihaz',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '2000 Hz',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatusItem('Sol Platform', '✓ Aktif')),
              Expanded(child: _buildStatusItem('Sağ Platform', '✓ Aktif')),
              Expanded(child: _buildStatusItem('Yük Hücreleri', '8/8 Çevrimiçi')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  // Diğer widget'lar için placeholder
  Widget _buildTestScenarioCard(UsbController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Test Senaryosu Kartı - Geliştirilecek'),
    );
  }

  Widget _buildRealTimeMetricsCard(UsbController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Gerçek Zamanlı Metrikler - Geliştirilecek'),
    );
  }

  Widget _buildDualPlatformCard(UsbController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Çift Platform Görselleştirmesi - Geliştirilecek'),
    );
  }

  Widget _buildAsymmetryAnalysisCard(UsbController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Asimetri Analizi - Geliştirilecek'),
    );
  }

  Widget _buildCenterOfPressureCard(UsbController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Basınç Merkezi - Geliştirilecek'),
    );
  }

  void _showConnectionDialog(BuildContext context, UsbController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('IzForce Platform Bağlantısı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IzForce modelinizi seçin:'),
            const SizedBox(height: 16),
            ...controller.availableDevices.map((device) => ListTile(
              title: Text(device.replaceAll('VALD', 'IzForce')), // VALD referanslarını temizle
              leading: const Icon(Icons.sensors),
              onTap: () async {
                Navigator.of(context).pop();
                final success = await controller.connectToDevice(device);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                          ? '$device bağlantısı başarılı!' 
                          : 'Bağlantı hatası: ${controller.errorMessage}'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }
}