// lib/presentation/screens/izforce_dashboard_screen.dart - VALD INSPIRED ANALYTICS
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/usb_controller.dart';
import '../widgets/charts/dual_platform_visualizer.dart';
import '../widgets/charts/force_metrics_grid.dart';
import '../widgets/charts/asymmetry_analyzer.dart';
import '../widgets/charts/test_results_table.dart';

class IzForceDashboardScreen extends StatefulWidget {
  const IzForceDashboardScreen({super.key});

  @override
  State<IzForceDashboardScreen> createState() => _IzForceDashboardScreenState();
}

class _IzForceDashboardScreenState extends State<IzForceDashboardScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTest = 'countermovement_jump';
  String _selectedMetric = 'jump_height';
  bool _showAsymmetry = false;
  
  final Map<String, String> _testTypes = {
    'countermovement_jump': 'CMJ',
    'squat_jump': 'SJ', 
    'drop_jump': 'DJ',
    'isometric_midthigh_pull': 'IMTP',
    'single_leg_jump': 'SLJ',
    'balance_test': 'Balance',
  };
  
  final Map<String, String> _metrics = {
    'jump_height': 'Jump Height (cm)',
    'peak_force': 'Peak Force (N)',
    'rfd_peak': 'RFD Peak (N/s)',
    'impulse_100ms': 'Impulse 100ms (N·s)',
    'takeoff_velocity': 'Takeoff Velocity (m/s)',
    'landing_rfd': 'Landing RFD (N/s)',
    'eccentric_duration': 'Eccentric Duration (ms)',
    'concentric_duration': 'Concentric Duration (ms)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IzForce Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                Text(
                  'Professional Force Analysis',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<UsbController>(
            builder: (context, controller, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: controller.isConnected ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.isConnected ? Icons.sensors : Icons.sensors_off,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      controller.isConnected ? 'Connected' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer<UsbController>(
            builder: (context, controller, child) {
              if (!controller.isConnected) {
                return const SizedBox.shrink();
              }
              
              return Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF1565C0),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF1565C0),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Live Testing'),
                    Tab(text: 'Results Dashboard'),
                    Tab(text: 'Analysis'),
                    Tab(text: 'Reports'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: Consumer<UsbController>(
        builder: (context, controller, child) {
          if (!controller.isConnected) {
            return _buildConnectionScreen(controller);
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildLiveTestingTab(controller),
              _buildResultsDashboard(controller),
              _buildAnalysisTab(controller),
              _buildReportsTab(controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConnectionScreen(UsbController controller) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sensors_off,
                size: 60,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'IzForce Platform',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to dual force platforms to begin testing',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => _showConnectionDialog(context, controller),
              icon: const Icon(Icons.link),
              label: const Text('Connect IzForce'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTestingTab(UsbController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Test Selection Header
            _buildTestSelectionHeader(),
            const SizedBox(height: 16),
            
            // Dual Platform Visualizer - Ana görsel
            Expanded(
              flex: 2,
              child: DualPlatformVisualizer(
                dataStream: controller.forceDataStream,
                testType: _selectedTest,
              ),
            ),
            const SizedBox(height: 16),
            
            // Live Metrics Row
            Expanded(
              child: Row(
                children: [
                  // Force Metrics Grid
                  Expanded(
                    flex: 2,
                    child: ForceMetricsGrid(
                      dataStream: controller.forceDataStream,
                      selectedMetrics: [
                        'peak_force',
                        'rfd_peak', 
                        'jump_height',
                        'takeoff_velocity'
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Asymmetry Analyzer
                  Expanded(
                    child: AsymmetryAnalyzer(
                      dataStream: controller.forceDataStream,
                      testType: _selectedTest,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsDashboard(UsbController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dashboard Controls
            _buildDashboardControls(),
            const SizedBox(height: 16),
            
            // Results Overview - 4 metrics like VALD
            _buildResultsOverview(controller),
            const SizedBox(height: 16),
            
            // Results Table
            Expanded(
              child: TestResultsTable(
                dataStream: controller.forceDataStream,
                testType: _selectedTest,
                selectedMetric: _selectedMetric,
                showAsymmetry: _showAsymmetry,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTab(UsbController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Analysis Header
            _buildAnalysisHeader(),
            const SizedBox(height: 16),
            
            // Force-Time Curve Visualization
            Expanded(
              flex: 2,
              child: _buildForceTimeCurve(controller),
            ),
            const SizedBox(height: 16),
            
            // Detailed Metrics
            Expanded(
              child: _buildDetailedMetrics(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab(UsbController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReportsHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildReportsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSelectionHeader() {
    return Container(
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
          const Row(
            children: [
              Icon(Icons.play_circle_outline, color: Color(0xFF1565C0), size: 24),
              SizedBox(width: 8),
              Text(
                'Live Testing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _testTypes.entries.map((entry) {
              final isSelected = _selectedTest == entry.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedTest = entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1565C0) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildDashboardControls() {
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Results Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedMetric,
                  items: _metrics.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedMetric = value!),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              const Text(
                'View',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showAsymmetry = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: !_showAsymmetry ? const Color(0xFF1565C0) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Performance',
                        style: TextStyle(
                          color: !_showAsymmetry ? Colors.white : Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showAsymmetry = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _showAsymmetry ? const Color(0xFF1565C0) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Asymmetry',
                        style: TextStyle(
                          color: _showAsymmetry ? Colors.white : Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsOverview(UsbController controller) {
    final latestData = controller.latestForceData;
    
    return Container(
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
            'Results Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildResultBar(
                  'Jump Height',
                  latestData != null ? (latestData.totalGRF * 0.01).toStringAsFixed(1) : '0',
                  'cm',
                  latestData != null ? latestData.totalGRF * 0.01 / 50 : 0,
                  const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildResultBar(
                  'Peak Force',
                  latestData?.totalGRF.toStringAsFixed(0) ?? '0',
                  'N',
                  latestData != null ? latestData.totalGRF / 2000 : 0,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildResultBar(
                  'RFD Peak',
                  latestData?.loadRate.toStringAsFixed(0) ?? '0',
                  'N/s',
                  latestData != null ? latestData.loadRate / 5000 : 0,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildResultBar(
                  'Asymmetry',
                  latestData != null ? (latestData.asymmetryIndex * 100).toStringAsFixed(1) : '0',
                  '%',
                  latestData?.asymmetryIndex ?? 0,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultBar(String title, String value, String unit, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisHeader() {
    return Container(
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
      child: const Row(
        children: [
          Icon(Icons.analytics, color: Color(0xFF1565C0), size: 24),
          SizedBox(width: 8),
          Text(
            'Force-Time Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForceTimeCurve(UsbController controller) {
    return Container(
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
      child: const Center(
        child: Text(
          'Force-Time Curve Visualization\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics(UsbController controller) {
    return Container(
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
      child: const Center(
        child: Text(
          'Detailed Metrics Analysis\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildReportsHeader() {
    return Container(
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
      child: const Row(
        children: [
          Icon(Icons.description, color: Color(0xFF1565C0), size: 24),
          SizedBox(width: 8),
          Text(
            'Performance Reports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return Container(
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
      child: const Center(
        child: Text(
          'Athlete Reports & Analytics\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  void _showConnectionDialog(BuildContext context, UsbController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sensors, color: Color(0xFF1565C0), size: 28),
            SizedBox(width: 12),
            Text('IzForce Analytics'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available force platforms:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...controller.availableDevices.map((device) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(device.replaceAll('Mock', 'IzForce Pro')),
                subtitle: const Text('1000 Hz • Dual Platform • Professional Grade'),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sensors, color: Color(0xFF1565C0)),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 16),
                          Text('Connecting to IzForce Analytics...'),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  
                  final success = await controller.connectToDevice(device);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              success ? Icons.check_circle : Icons.error,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(success 
                                  ? 'Connected successfully! Professional analytics ready.' 
                                  : 'Connection failed: ${controller.errorMessage}'),
                            ),
                          ],
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}