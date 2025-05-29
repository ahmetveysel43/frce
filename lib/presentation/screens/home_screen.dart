import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_controller.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/device_status_widget.dart';
import '../widgets/quick_stats_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppController>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'IzForce',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Notifications screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Settings screen
            },
          ),
        ],
      ),
      body: Consumer<AppController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Yükleniyor...'),
                ],
              ),
            );
          }

          if (controller.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hata: ${controller.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.refresh(),
                    child: const Text('Yeniden Dene'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(context),
                  const SizedBox(height: 24),

                  // Device Status
                  const DeviceStatusWidget(),
                  const SizedBox(height: 24),

                  // Quick Stats
                  QuickStatsWidget(
                    athleteCount: controller.athleteCount,
                    recentAthletes: controller.athletes,
                  ),
                  const SizedBox(height: 24),

                  // Main Actions Grid
                  _buildMainActions(context),
                  const SizedBox(height: 24),

                  // Secondary Actions
                  _buildSecondaryActions(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Günaydın';
    } else if (hour < 18) {
      greeting = 'İyi günler';
    } else {
      greeting = 'İyi akşamlar';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Force Platform Analysis\'e hoş geldiniz',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bugün ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ana İşlemler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            DashboardCard(
              title: 'Hızlı Test',
              subtitle: 'Test başlat',
              icon: Icons.play_circle_filled,
              color: Colors.green,
              onTap: () {
                // TODO: Navigate to quick test
                _showNotImplemented(context, 'Hızlı Test');
              },
            ),
            DashboardCard(
              title: 'Atletler',
              subtitle: '${context.read<AppController>().athleteCount} atlet',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () {
                // TODO: Navigate to athletes screen
                _showNotImplemented(context, 'Atlet Yönetimi');
              },
            ),
            DashboardCard(
              title: 'Test Geçmişi',
              subtitle: 'Sonuçları görüntüle',
              icon: Icons.history,
              color: Colors.orange,
              onTap: () {
                // TODO: Navigate to test history
                _showNotImplemented(context, 'Test Geçmişi');
              },
            ),
            DashboardCard(
              title: 'Analitik',
              subtitle: 'Veri analizi',
              icon: Icons.analytics,
              color: Colors.purple,
              onTap: () {
                // TODO: Navigate to analytics
                _showNotImplemented(context, 'Analitik');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diğer İşlemler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                title: 'Kalibrasyon',
                subtitle: 'Platform ayarları',
                icon: Icons.tune,
                color: Colors.teal,
                onTap: () {
                  _showNotImplemented(context, 'Kalibrasyon');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardCard(
                title: 'Dışa Aktar',
                subtitle: 'Veri paylaşımı',
                icon: Icons.file_download,
                color: Colors.indigo,
                onTap: () {
                  _showNotImplemented(context, 'Dışa Aktarma');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showNotImplemented(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature özelliği yakında eklenecek!'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}