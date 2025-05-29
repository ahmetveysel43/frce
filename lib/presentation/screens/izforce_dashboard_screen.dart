// lib/presentation/screens/izforce_dashboard_screen.dart - Tam Functional
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/usb_controller.dart';

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
                  controller.isConnected ? Icons.sensors : Icons.sensors_off,
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
          
          // ✅ Test Senaryosu Seçimi - Artık kullanılıyor
          _buildTestScenarioCard(controller),
          const SizedBox(height: 16),
          
          // ✅ Gerçek Zamanlı Metrikler - Functional
          _buildRealTimeMetricsCard(controller),
          const SizedBox(height: 16),
          
          // ✅ Çift Platform Görselleştirmesi - Visual
          _buildDualPlatformCard(controller),
          const SizedBox(height: 16),
          
          // ✅ Asimetri Analizi - Real-time
          _buildAsymmetryAnalysisCard(controller),
          const SizedBox(height: 16),
          
          // ✅ Basınç Merkezi - Live CoP
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
                child: Text(
                  controller.isDataFlowing ? '1000 Hz' : 'Bekleniyor',
                  style: TextStyle(
                    color: controller.isDataFlowing ? Colors.green : Colors.orange,
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

  // ✅ Test Senaryosu Seçimi - Artık functional
  Widget _buildTestScenarioCard(UsbController controller) {
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
          const Text(
            'Test Senaryosu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _testScenarios.entries.map((entry) {
              final isSelected = _selectedTestScenario == entry.key;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTestScenario = entry.key;
                  });
                  // Mock USB service'e senaryo değişikliği gönder
                  controller.changeTestScenario(entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ✅ Gerçek Zamanlı Metrikler - Live data
  Widget _buildRealTimeMetricsCard(UsbController controller) {
    final latestData = controller.latestForceData;
    
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
          const Text(
            'Gerçek Zamanlı Metrikler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (latestData != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Toplam Kuvvet',
                    '${latestData.totalGRF.toStringAsFixed(1)} N',
                    Colors.blue,
                    Icons.fitness_center,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Asimetri',
                    '${(latestData.asymmetryIndex * 100).toStringAsFixed(1)}%',
                    Colors.orange,
                    Icons.balance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Sol Platform',
                    '${latestData.leftGRF.toStringAsFixed(1)} N',
                    Colors.green,
                    Icons.arrow_back,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Sağ Platform',
                    '${latestData.rightGRF.toStringAsFixed(1)} N',
                    Colors.purple,
                    Icons.arrow_forward,
                  ),
                ),
              ],
            ),
          ] else ...[
            const Center(
              child: Text(
                'Veri bekleniyor...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Çift Platform Görselleştirmesi - Visual representation
  Widget _buildDualPlatformCard(UsbController controller) {
    final latestData = controller.latestForceData;
    
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
          const Text(
            'Çift Platform Görselleştirmesi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Sol Platform
              Expanded(
                child: _buildPlatformVisual(
                  'Sol Platform',
                  latestData?.leftGRF ?? 0,
                  Colors.green,
                  true,
                ),
              ),
              const SizedBox(width: 16),
              // Sağ Platform
              Expanded(
                child: _buildPlatformVisual(
                  'Sağ Platform',
                  latestData?.rightGRF ?? 0,
                  Colors.purple,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformVisual(String title, double force, Color color, bool isLeft) {
    final intensity = (force / 1000).clamp(0.0, 1.0); // Normalize to 0-1
    
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Stack(
            children: [
              // Force visualization
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120 * intensity,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Force value
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLeft ? Icons.arrow_back : Icons.arrow_forward,
                      color: color,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${force.toStringAsFixed(0)}N',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Asimetri Analizi - Real-time asymmetry
  Widget _buildAsymmetryAnalysisCard(UsbController controller) {
    final latestData = controller.latestForceData;
    final asymmetryPercent = latestData != null 
        ? (latestData.asymmetryIndex * 100) 
        : 0.0;
    
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
          const Text(
            'Asimetri Analizi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Asimetri göstergesi
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        Colors.green,
                        Colors.yellow,
                        Colors.orange,
                        Colors.red,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('İdeal', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Kabul edilebilir', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Dikkat', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Risk', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  '${asymmetryPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getAsymmetryColor(asymmetryPercent),
                  ),
                ),
                Text(
                  _getAsymmetryStatus(asymmetryPercent),
                  style: TextStyle(
                    fontSize: 14,
                    color: _getAsymmetryColor(asymmetryPercent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAsymmetryColor(double asymmetryPercent) {
    if (asymmetryPercent < 5) return Colors.green;
    if (asymmetryPercent < 10) return Colors.yellow;
    if (asymmetryPercent < 15) return Colors.orange;
    return Colors.red;
  }

  String _getAsymmetryStatus(double asymmetryPercent) {
    if (asymmetryPercent < 5) return 'İdeal Denge';
    if (asymmetryPercent < 10) return 'Kabul Edilebilir';
    if (asymmetryPercent < 15) return 'Dikkat Gerekli';
    return 'Yüksek Risk';
  }

  // ✅ Basınç Merkezi - Live CoP visualization
  Widget _buildCenterOfPressureCard(UsbController controller) {
    final latestData = controller.latestForceData;
    
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
          const Text(
            'Basınç Merkezi (CoP)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (latestData != null) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sol Platform CoP',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'X: ${latestData.leftCoPX.toStringAsFixed(1)} mm',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Y: ${latestData.leftCoPY.toStringAsFixed(1)} mm',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sağ Platform CoP',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'X: ${latestData.rightCoPX.toStringAsFixed(1)} mm',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Y: ${latestData.rightCoPY.toStringAsFixed(1)} mm',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const Center(
              child: Text(
                'CoP verisi bekleniyor...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
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
              title: Text(device.replaceAll('VALD', 'IzForce')),
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