// lib/presentation/screens/home_screen.dart - Düzeltilmiş
import 'package:flutter/material.dart';
import '../controllers/usb_controller.dart';
import '../../app/injection_container.dart' as di;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'IzForce Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good Morning',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome to Force Platform Analysis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Today ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // USB Status Widget
            const USBStatusWidget(),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            Container(
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
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New Test feature coming soon!')),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('New Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Athletes page coming soon!')),
                            );
                          },
                          icon: const Icon(Icons.people),
                          label: const Text('Athletes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }
}

// USB Status Widget
class USBStatusWidget extends StatefulWidget {
  const USBStatusWidget({super.key});

  @override
  State<USBStatusWidget> createState() => _USBStatusWidgetState();
}

class _USBStatusWidgetState extends State<USBStatusWidget> {
  late final UsbController _usbController;

  @override
  void initState() {
    super.initState();
    _usbController = di.sl<UsbController>();
    _usbController.addListener(_onUsbStatusChanged);
  }

  @override
  void dispose() {
    _usbController.removeListener(_onUsbStatusChanged);
    super.dispose();
  }

  void _onUsbStatusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Icon(
                Icons.usb,
                color: _usbController.isConnected ? Colors.blue : Colors.grey,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (_usbController.isConnected ? Colors.green : Colors.grey)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _usbController.isConnected ? 'Connected' : 'Not Connected',
                  style: TextStyle(
                    color: _usbController.isConnected ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_usbController.isConnected && _usbController.latestForceData != null) ...[
            Text(
              'Total Force: ${_usbController.latestForceData!.totalGRF.toStringAsFixed(1)} N', // ✅ totalForce -> totalGRF
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _usbController.isConnected 
                  ? () => _usbController.disconnect()
                  : () => _connectToDevice(),
              icon: Icon(_usbController.isConnected ? Icons.usb_off : Icons.usb),
              label: Text(_usbController.isConnected ? 'Disconnect' : 'Mock Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _usbController.isConnected ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _connectToDevice() async {
    final success = await _usbController.connectToDevice('Mock Force Platform');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Mock USB connection successful! Real-time data stream started.' 
              : 'Connection error: ${_usbController.errorMessage}'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}