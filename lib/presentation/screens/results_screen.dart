import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../../presentation/widgets/metrics_display_widget.dart';
import '../../domain/entities/test_result.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/repositories/test_repository.dart';
import '../../core/utils/app_logger.dart';
import '../../core/services/pdf_report_service.dart';
import '../../core/services/file_share_service.dart';
import '../../core/services/progress_analyzer.dart';
import '../../data/models/athlete_model.dart';
import '../../data/models/test_result_model.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

/// Test sonuçları ve geçmiş ekranı
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSport = 'Tümü';
  TestType? _selectedTestType;
  DateTimeRange? _selectedDateRange;
  ResultsSortBy _sortBy = ResultsSortBy.date;
  bool _sortAscending = false;
  
  List<TestResult> _allTestResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllTestResults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildAppBar(),
      body: GetBuilder<AthleteController>(
        builder: (controller) {
          return Column(
            children: [
              // Filters section
              _buildFiltersSection(controller),
              
              // Tab bar
              _buildTabBar(),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllResultsTab(controller),
                    _buildStatisticsTab(controller),
                    _buildExportTab(controller),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.darkSurface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Sonuçları',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          GetBuilder<AthleteController>(
            builder: (controller) {
              final totalResults = _getFilteredResults(controller).length;
              return Text(
                '$totalResults sonuç listeleniyor',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showSortDialog(),
          icon: const Icon(
            Icons.sort,
            color: AppTheme.primaryColor,
          ),
        ),
        IconButton(
          onPressed: () => _showFilterDialog(),
          icon: Stack(
            children: [
              const Icon(
                Icons.filter_list,
                color: AppTheme.primaryColor,
              ),
              if (_hasActiveFilters())
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(AthleteController controller) {
    if (!_hasActiveFilters()) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.darkSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktif Filtreler',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedSport != 'Tümü')
                _buildFilterChip(
                  label: 'Spor: $_selectedSport',
                  onRemove: () => setState(() => _selectedSport = 'Tümü'),
                ),
              if (_selectedTestType != null)
                _buildFilterChip(
                  label: 'Test: ${_selectedTestType!.code}',
                  onRemove: () => setState(() => _selectedTestType = null),
                ),
              if (_selectedDateRange != null)
                _buildFilterChip(
                  label: 'Tarih: ${DateFormat('dd.MM.yy').format(_selectedDateRange!.start)} - ${DateFormat('dd.MM.yy').format(_selectedDateRange!.end)}',
                  onRemove: () => setState(() => _selectedDateRange = null),
                ),
              
              // Clear all filters
              TextButton.icon(
                onPressed: () => _clearAllFilters(),
                icon: const Icon(Icons.clear_all, size: 14),
                label: const Text('Tümünü Temizle'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 11,
        ),
      ),
      deleteIcon: const Icon(
        Icons.close,
        size: 14,
        color: AppTheme.primaryColor,
      ),
      onDeleted: onRemove,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.darkSurface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryColor,
        tabs: const [
          Tab(
            icon: Icon(Icons.list, size: 20),
            text: 'Tüm Sonuçlar',
          ),
          Tab(
            icon: Icon(Icons.analytics, size: 20),
            text: 'İstatistikler',
          ),
          Tab(
            icon: Icon(Icons.download, size: 20),
            text: 'Dışa Aktar',
          ),
        ],
      ),
    );
  }

  Widget _buildAllResultsTab(AthleteController controller) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Test sonuçları yükleniyor...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    
    final filteredResults = _getFilteredResults(controller);
    
    if (filteredResults.isEmpty) {
      return _buildEmptyResults();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final result = filteredResults[index];
        final athlete = controller.findAthleteById(result.athleteId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildResultCard(result, athlete),
        );
      },
    );
  }

  Widget _buildStatisticsTab(AthleteController controller) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'İstatistikler hesaplanıyor...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    
    final filteredResults = _getFilteredResults(controller);
    
    if (filteredResults.isEmpty) {
      return _buildEmptyResults();
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall statistics
          _buildOverallStats(filteredResults),
          const SizedBox(height: 24),
          
          // Test type breakdown
          _buildTestTypeBreakdown(filteredResults),
          const SizedBox(height: 24),
          
          // Quality distribution
          _buildQualityDistribution(filteredResults),
          const SizedBox(height: 24),
          
          // Performance trends
          _buildPerformanceTrends(filteredResults),
        ],
      ),
    );
  }

  Widget _buildExportTab(AthleteController controller) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Veriler hazırlanıyor...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    
    final filteredResults = _getFilteredResults(controller);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.download,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Dışa Aktarma',
                      style: Get.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${filteredResults.length} test sonucu dışa aktarılacak',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Export options
          Text(
            'Dışa Aktarma Formatları',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          ...ExportFormat.values.map((format) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildExportFormatCard(format, filteredResults),
            ),
          ),
          
          const Spacer(),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: filteredResults.isNotEmpty 
                      ? () => _shareMultipleResults(filteredResults)
                      : null,
                  icon: const Icon(Icons.share),
                  label: const Text('Tümünü Paylaş'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: filteredResults.isNotEmpty 
                      ? () => _exportAllFormats(filteredResults)
                      : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Tümünü İndir'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasActiveFilters() ? Icons.search_off : Icons.analytics_outlined,
              size: 64,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters() ? 'Filtre Sonucu Bulunamadı' : 'Henüz Test Sonucu Yok',
              style: Get.textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveFilters()
                  ? 'Farklı filtreler deneyin veya filtreleri temizleyin'
                  : 'İlk testi yapmak için ana sayfaya gidin',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_hasActiveFilters())
              OutlinedButton.icon(
                onPressed: () => _clearAllFilters(),
                icon: const Icon(Icons.clear),
                label: const Text('Filtreleri Temizle'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Get.offAllNamed('/'),
                icon: const Icon(Icons.home),
                label: const Text('Ana Sayfaya Git'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(TestResult result, Athlete? athlete) {
    return Card(
      color: AppTheme.darkCard,
      child: InkWell(
        onTap: () => _showResultDetails(result, athlete),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  // Test type icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getTestTypeColor(result.testType).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTestTypeIcon(result.testType),
                      color: _getTestTypeColor(result.testType),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Test info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              result.testType.code,
                              style: Get.textTheme.titleMedium?.copyWith(
                                color: _getTestTypeColor(result.testType),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildQualityBadge(result.quality),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          athlete?.fullName ?? 'Bilinmeyen Sporcu',
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm').format(result.testDate),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.timer,
                              size: 12,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${result.duration.inSeconds}s',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppTheme.textHint),
                    color: AppTheme.darkCard,
                    onSelected: (action) => _handleResultAction(action, result, athlete),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 18, color: AppTheme.textSecondary),
                            SizedBox(width: 8),
                            Text('Detayları Görüntüle', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'compare',
                        child: Row(
                          children: [
                            Icon(Icons.compare, size: 18, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text('Karşılaştır', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 18, color: AppTheme.accentColor),
                            SizedBox(width: 8),
                            Text('Dışa Aktar', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 18, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text('Paylaş', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Key metrics
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: _buildKeyMetrics(result).map((metric) => 
                    Expanded(child: metric),
                  ).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildKeyMetrics(TestResult result) {
    final primaryMetrics = result.primaryMetrics;
    final metricEntries = primaryMetrics.entries.take(3).toList();
    
    return metricEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final metric = entry.value;
      
      return Row(
        children: [
          if (index > 0) _buildMetricDivider(),
          Expanded(
            child: _buildMetricItem(
              name: _getMetricDisplayName(metric.key),
              value: metric.value.toStringAsFixed(1),
              unit: _getMetricUnit(metric.key),
              color: _getMetricColor(metric.key, metric.value),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildMetricItem({
    required String name,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            color: AppTheme.textHint,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 30,
      color: AppTheme.darkDivider,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildQualityBadge(TestQuality quality) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color(int.parse(quality.colorHex.replaceFirst('#', '0xFF'))).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        quality.turkishName,
        style: TextStyle(
          color: Color(int.parse(quality.colorHex.replaceFirst('#', '0xFF'))),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOverallStats(List<TestResult> results) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Genel İstatistikler',
            style: Get.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.analytics,
                label: 'Toplam Test',
                value: results.length.toString(),
                color: AppTheme.primaryColor,
              ),
              _buildStatDivider(),
              _buildStatItem(
                icon: Icons.people,
                label: 'Sporcu',
                value: results.map((r) => r.athleteId).toSet().length.toString(),
                color: AppTheme.accentColor,
              ),
              _buildStatDivider(),
              _buildStatItem(
                icon: Icons.star,
                label: 'Ortalama Kalite',
                value: _calculateAverageQuality(results),
                color: AppTheme.successColor,
              ),
              _buildStatDivider(),
              _buildStatItem(
                icon: Icons.schedule,
                label: 'Toplam Süre',
                value: _calculateTotalDuration(results),
                color: AppColors.chartColors[3],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.darkDivider,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildTestTypeBreakdown(List<TestResult> results) {
    final testTypeCount = <TestType, int>{};
    for (final result in results) {
      testTypeCount[result.testType] = (testTypeCount[result.testType] ?? 0) + 1;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Türü Dağılımı',
            style: Get.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...testTypeCount.entries.map((entry) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTestTypeBreakdownItem(entry.key, entry.value, results.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTypeBreakdownItem(TestType testType, int count, int total) {
    final percentage = (count / total * 100).toStringAsFixed(1);
    final color = _getTestTypeColor(testType);
    
    return Row(
      children: [
        Icon(
          _getTestTypeIcon(testType),
          color: color,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      testType.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$count (%$percentage)',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: count / total,
                backgroundColor: AppTheme.darkDivider,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQualityDistribution(List<TestResult> results) {
    final qualityCount = <TestQuality, int>{};
    for (final result in results) {
      qualityCount[result.quality] = (qualityCount[result.quality] ?? 0) + 1;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kalite Dağılımı',
            style: Get.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: TestQuality.values.map((quality) {
              final count = qualityCount[quality] ?? 0;
              final percentage = results.isNotEmpty ? count / results.length : 0.0;
              final color = Color(int.parse(quality.colorHex.replaceFirst('#', '0xFF')));
              
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quality.turkishName,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${(percentage * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTrends(List<TestResult> results) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performans Trendleri',
            style: Get.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.darkBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    color: AppTheme.textHint,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Grafik Görünümü',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Yakında gelecek',
                    style: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportFormatCard(ExportFormat format, List<TestResult> results) {
    return Card(
      color: AppTheme.darkBackground,
      child: InkWell(
        onTap: results.isNotEmpty ? () => _exportFormat(format, results) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _getFormatIcon(format),
                color: results.isNotEmpty ? AppTheme.primaryColor : AppTheme.textHint,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format.name,
                      style: Get.textTheme.titleMedium?.copyWith(
                        color: results.isNotEmpty ? Colors.white : AppTheme.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getFormatDescription(format),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.download,
                color: results.isNotEmpty ? AppTheme.textSecondary : AppTheme.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Data loading methods
  Future<void> _loadAllTestResults() async {
    try {
      setState(() => _isLoading = true);
      
      final testRepository = Get.find<TestRepository>();
      final allResults = await testRepository.getRecentTests(limit: 100);
      
      setState(() {
        _allTestResults = allResults;
        _isLoading = false;
      });
      
      AppLogger.info('✅ ${allResults.length} test sonucu yüklendi');
    } catch (e) {
      AppLogger.error('Test sonuçları yüklenirken hata', e);
      setState(() => _isLoading = false);
      
      Get.snackbar(
        'Hata',
        'Test sonuçları yüklenemedi: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    }
  }

  // Helper methods
  List<TestResult> _getFilteredResults(AthleteController controller) {
    if (_isLoading) return [];
    
    final allResults = _allTestResults;
    
    var filtered = allResults.where((result) {
      // Sport filter
      if (_selectedSport != 'Tümü') {
        final athlete = controller.findAthleteById(result.athleteId);
        if (athlete?.sport != _selectedSport) return false;
      }
      
      // Test type filter
      if (_selectedTestType != null && result.testType != _selectedTestType) {
        return false;
      }
      
      // Date range filter
      if (_selectedDateRange != null) {
        final testDate = result.testDate;
        if (testDate.isBefore(_selectedDateRange!.start) || 
            testDate.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case ResultsSortBy.date:
          comparison = a.testDate.compareTo(b.testDate);
          break;
        case ResultsSortBy.athlete:
          final athleteA = controller.findAthleteById(a.athleteId);
          final athleteB = controller.findAthleteById(b.athleteId);
          comparison = (athleteA?.fullName ?? '').compareTo(athleteB?.fullName ?? '');
          break;
        case ResultsSortBy.testType:
          comparison = a.testType.turkishName.compareTo(b.testType.turkishName);
          break;
        case ResultsSortBy.quality:
          comparison = a.qualityScore.compareTo(b.qualityScore);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return filtered;
  }

  bool _hasActiveFilters() {
    return _selectedSport != 'Tümü' || 
           _selectedTestType != null || 
           _selectedDateRange != null;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedSport = 'Tümü';
      _selectedTestType = null;
      _selectedDateRange = null;
    });
  }

  Color _getTestTypeColor(TestType testType) {
    switch (testType.category) {
      case TestCategory.jump:
        return AppColors.chartColors[0];
      case TestCategory.strength:
        return AppColors.chartColors[1];
      case TestCategory.balance:
        return AppColors.chartColors[2];
      case TestCategory.agility:
        return AppColors.chartColors[3];
    }
  }

  IconData _getTestTypeIcon(TestType testType) {
    switch (testType.category) {
      case TestCategory.jump:
        return Icons.trending_up;
      case TestCategory.strength:
        return Icons.fitness_center;
      case TestCategory.balance:
        return Icons.balance;
      case TestCategory.agility:
        return Icons.speed;
    }
  }

  String _getMetricDisplayName(String metricName) {
    switch (metricName) {
      case 'jumpHeight': return 'Yükseklik';
      case 'peakForce': return 'Max Kuvvet';
      case 'averageForce': return 'Ort. Kuvvet';
      case 'asymmetryIndex': return 'Asimetri';
      case 'flightTime': return 'Uçuş';
      case 'contactTime': return 'Temas';
      case 'rfd': return 'RFD';
      case 'copRange': return 'COP';
      case 'stabilityIndex': return 'Stabilite';
      default: return metricName;
    }
  }

  String _getMetricUnit(String metricName) {
    switch (metricName) {
      case 'jumpHeight': return 'cm';
      case 'peakForce':
      case 'averageForce': return 'N';
      case 'asymmetryIndex': return '%';
      case 'flightTime':
      case 'contactTime': return 'ms';
      case 'rfd': return 'N/s';
      case 'copRange': return 'mm';
      default: return '';
    }
  }

  Color _getMetricColor(String metricName, double value) {
    switch (metricName) {
      case 'jumpHeight':
        if (value > 40) return AppTheme.successColor;
        if (value > 30) return AppTheme.warningColor;
        return AppTheme.errorColor;
      case 'asymmetryIndex':
        if (value < 5) return AppTheme.successColor;
        if (value < 10) return AppTheme.warningColor;
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _calculateAverageQuality(List<TestResult> results) {
    if (results.isEmpty) return '0';
    final avgScore = results.map((r) => r.qualityScore).reduce((a, b) => a + b) / results.length;
    return avgScore.toStringAsFixed(1);
  }

  String _calculateTotalDuration(List<TestResult> results) {
    final totalSeconds = results.map((r) => r.duration.inSeconds).fold(0, (a, b) => a + b);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
      case ExportFormat.excel:
        return Icons.table_chart;
      case ExportFormat.csv:
        return Icons.text_snippet;
      case ExportFormat.json:
        return Icons.code;
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'Rapor formatında çıktı';
      case ExportFormat.excel:
        return 'Excel tablosu olarak';
      case ExportFormat.csv:
        return 'CSV veri dosyası';
      case ExportFormat.json:
        return 'JSON ham verisi';
    }
  }

  void _showSortDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Sıralama', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ResultsSortBy.values.map((sortBy) {
            return RadioListTile<ResultsSortBy>(
              title: Text(
                sortBy.turkishName,
                style: const TextStyle(color: Colors.white),
              ),
              value: sortBy,
              groupValue: _sortBy,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  if (_sortBy == value) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = value!;
                    _sortAscending = true;
                  }
                });
                Get.back();
              },
            );
          }).toList(),
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

  void _showFilterDialog() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtreler',
              style: Get.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Sport filter
            const Text('Spor Dalı', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSport,
              style: const TextStyle(color: Colors.white),
              dropdownColor: AppTheme.darkCard,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: ['Tümü', 'Basketbol', 'Voleybol', 'Futbol', 'Atletizm', 'Halter']
                  .map((sport) => DropdownMenuItem(value: sport, child: Text(sport)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedSport = value!),
            ),
            const SizedBox(height: 16),
            
            // Test type filter
            const Text('Test Türü', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<TestType>(
              value: _selectedTestType,
              style: const TextStyle(color: Colors.white),
              dropdownColor: AppTheme.darkCard,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tümü')),
                ...TestType.values.map((type) => 
                  DropdownMenuItem(value: type, child: Text(type.code)),
                ),
              ],
              onChanged: (value) => setState(() => _selectedTestType = value),
            ),
            const SizedBox(height: 16),
            
            // Date range filter
            const Text('Tarih Aralığı', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDateRange(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.darkDivider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDateRange != null
                          ? '${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.end)}'
                          : 'Tarih aralığı seçin',
                      style: TextStyle(
                        color: _selectedDateRange != null ? Colors.white : AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _clearAllFilters();
                      Get.back();
                    },
                    child: const Text('Temizle'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Uygula'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.darkCard,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (dateRange != null) {
      setState(() => _selectedDateRange = dateRange);
    }
  }

  void _showResultDetails(TestResult result, Athlete? athlete) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTestTypeColor(result.testType).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTestTypeIcon(result.testType),
                    color: _getTestTypeColor(result.testType),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.testType.turkishName,
                        style: Get.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        athlete?.fullName ?? 'Bilinmeyen Sporcu',
                        style: Get.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildQualityBadge(result.quality),
              ],
            ),
            const SizedBox(height: 24),
            
            // Metrics
            Expanded(
              child: MetricsDisplayWidget(
                metrics: result.metrics,
                style: MetricDisplayStyle.detailed,
              ),
            ),
            
            // Actions
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      _shareResult(result, athlete);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Paylaş'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      _exportFormat(ExportFormat.pdf, [result]);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('İndir'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                    label: const Text('Kapat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleResultAction(String action, TestResult result, Athlete? athlete) {
    switch (action) {
      case 'view':
        _showResultDetails(result, athlete);
        break;
      case 'compare':
        Get.snackbar('Bilgi', 'Karşılaştırma özelliği yakında gelecek');
        break;
      case 'export':
        _exportFormat(ExportFormat.pdf, [result]);
        break;
      case 'share':
        _shareResult(result, athlete);
        break;
      case 'delete':
        _confirmDeleteResult(result);
        break;
    }
  }

  void _confirmDeleteResult(TestResult result) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Sonucu Sil', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu test sonucunu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Başarılı', 'Test sonucu silindi');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFormat(ExportFormat format, List<TestResult> results) async {
    if (results.isEmpty) {
      Get.snackbar(
        'Uyarı',
        'Dışa aktarılacak test sonucu bulunamadı',
        backgroundColor: AppTheme.warningColor,
        colorText: Colors.white,
      );
      return;
    }

    try {
      Get.snackbar(
        'Başlatılıyor',
        '${results.length} sonuç ${format.name} formatında hazırlanıyor...',
        backgroundColor: AppTheme.primaryColor,
        colorText: Colors.white,
      );

      switch (format) {
        case ExportFormat.pdf:
          // Test amaçlı önce basit PDF oluştur
          await _generateTestPDF();
          // Sonra gerçek PDF'i oluştur
          await _generatePDFReport(results);
          break;
        case ExportFormat.json:
          await _exportToJSON(results);
          break;
        case ExportFormat.csv:
          await _exportToCSV(results);
          break;
        case ExportFormat.excel:
          Get.snackbar(
            'Geliştiriliyor',
            'Excel export özelliği yakında eklenecek',
            backgroundColor: AppTheme.primaryColor,
            colorText: Colors.white,
          );
          break;
      }
    } catch (e) {
      AppLogger.error('Export hatası', e);
      Get.snackbar(
        'Hata',
        'Export işlemi başarısız: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _exportAllFormats(List<TestResult> results) async {
    if (results.isEmpty) {
      Get.snackbar(
        'Uyarı',
        'Dışa aktarılacak test sonucu bulunamadı',
        backgroundColor: AppTheme.warningColor,
        colorText: Colors.white,
      );
      return;
    }

    try {
      Get.snackbar(
        'Başlatılıyor',
        '${results.length} sonuç tüm formatlarda hazırlanıyor...',
        backgroundColor: AppTheme.primaryColor,
        colorText: Colors.white,
      );

      // PDF, JSON ve CSV export'larını sırayla yap
      await _generatePDFReport(results);
      await _exportToJSON(results);
      await _exportToCSV(results);

      Get.snackbar(
        'Tamamlandı',
        'Tüm formatlar başarıyla dışa aktarıldı',
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
    } catch (e) {
      AppLogger.error('Tüm format export hatası', e);
      Get.snackbar(
        'Hata',
        'Export işlemi başarısız: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    }
  }

  /// Test PDF oluştur
  Future<void> _generateTestPDF() async {
    try {
      final testFile = await PDFReportService.generateTestPDF();
      AppLogger.info('🧪 Test PDF oluşturuldu: ${testFile.path}');
    } catch (e, stackTrace) {
      AppLogger.error('Test PDF hatası', e, stackTrace);
    }
  }

  /// PDF raporu oluştur
  Future<void> _generatePDFReport(List<TestResult> results) async {
    try {
      AppLogger.info('📊 PDF raporu oluşturuluyor: ${results.length} test sonucu');
      
      // Sporcu bilgilerini grupla
      final athleteController = Get.find<AthleteController>();
      final athleteGroups = <String, List<TestResult>>{};
      
      for (final result in results) {
        athleteGroups.putIfAbsent(result.athleteId, () => []).add(result);
      }
      
      // Her sporcu için ayrı PDF oluştur
      int reportCount = 0;
      for (final entry in athleteGroups.entries) {
        final athleteId = entry.key;
        final athleteResults = entry.value;
        
        final athlete = athleteController.findAthleteById(athleteId);
        if (athlete == null) {
          AppLogger.warning('Sporcu bulunamadı: $athleteId');
          continue;
        }
        
        // Athlete entity'sini AthleteModel'e çevir
        final athleteModel = AthleteModel(
          id: athlete.id,
          firstName: athlete.firstName,
          lastName: athlete.lastName,
          email: athlete.email,
          dateOfBirth: athlete.dateOfBirth,
          gender: athlete.gender?.name,
          height: athlete.height,
          weight: athlete.weight,
          sport: athlete.sport,
          team: athlete.sport, // Team bilgisi sport olarak kullanılıyor
          position: athlete.position,
          level: athlete.level?.name,
          notes: athlete.notes,
          createdAt: athlete.createdAt,
          updatedAt: athlete.updatedAt,
          isActive: athlete.isActive,
        );
        
        // TestResult entity'lerini TestResultModel'e çevir
        final resultModels = athleteResults.map((result) => TestResultModel(
          id: result.id,
          sessionId: result.sessionId,
          athleteId: result.athleteId,
          testType: result.testType.name,
          testDate: result.testDate,
          durationMs: result.duration.inMilliseconds,
          status: result.status.name,
          metrics: result.metrics,
          metadata: result.metadata,
          notes: result.notes,
          createdAt: result.createdAt,
          qualityScore: result.qualityScore,
        )).toList();
        
        // Performans analizi oluştur
        final analysis = await ProgressAnalyzer.analyzePerformance(
          athleteId: athleteId,
          athlete: athleteModel,
          results: resultModels,
          testType: TestType.counterMovementJump,
        );
        
        // PDF raporu oluştur ve paylaş
        final pdfFile = await PDFReportService.generateAndSharePerformanceReport(
          athlete: athleteModel,
          results: resultModels,
          analysis: analysis,
          autoShare: true,
        );
        
        reportCount++;
        AppLogger.success('PDF oluşturuldu ve paylaşıldı: ${pdfFile.path}');
      }
      
      Get.snackbar(
        'Başarılı',
        '$reportCount PDF raporu oluşturuldu\\nDosya yolu logda gösterildi',
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('PDF raporu oluşturma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Tekil test sonucunu paylaş
  Future<void> _shareResult(TestResult result, Athlete? athlete) async {
    try {
      Get.snackbar(
        'Hazırlanıyor',
        'Test sonucu PDF raporu oluşturuluyor...',
        backgroundColor: AppTheme.primaryColor,
        colorText: Colors.white,
      );

      Get.find<AthleteController>();
      
      if (athlete == null) {
        Get.snackbar(
          'Hata',
          'Sporcu bilgisi bulunamadı',
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
        );
        return;
      }
      
      // Athlete entity'sini AthleteModel'e çevir
      final athleteModel = AthleteModel(
        id: athlete.id,
        firstName: athlete.firstName,
        lastName: athlete.lastName,
        email: athlete.email,
        dateOfBirth: athlete.dateOfBirth,
        gender: athlete.gender?.name,
        height: athlete.height,
        weight: athlete.weight,
        sport: athlete.sport,
        team: athlete.sport,
        position: athlete.position,
        level: athlete.level?.name,
        notes: athlete.notes,
        createdAt: athlete.createdAt,
        updatedAt: athlete.updatedAt,
        isActive: athlete.isActive,
      );
      
      // TestResult entity'sini TestResultModel'e çevir
      final resultModel = TestResultModel(
        id: result.id,
        sessionId: result.sessionId,
        athleteId: result.athleteId,
        testType: result.testType.name,
        testDate: result.testDate,
        durationMs: result.duration.inMilliseconds,
        status: result.status.name,
        metrics: result.metrics,
        metadata: result.metadata,
        notes: result.notes,
        createdAt: result.createdAt,
        qualityScore: result.qualityScore,
      );
      
      // Performans analizi oluştur
      final analysis = await ProgressAnalyzer.analyzePerformance(
        athleteId: result.athleteId,
        athlete: athleteModel,
        results: [resultModel],
        testType: TestType.counterMovementJump,
      );
      
      // PDF oluştur ve paylaş
      await PDFReportService.generateAndSharePerformanceReport(
        athlete: athleteModel,
        results: [resultModel],
        analysis: analysis,
        autoShare: true,
      );
      
      Get.snackbar(
        'Başarılı',
        'Test sonucu PDF raporu paylaşıldı',
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Test sonucu paylaşma hatası', e, stackTrace);
      Get.snackbar(
        'Hata',
        'Test sonucu paylaşılamadı: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    }
  }

  /// Çoklu test sonuçlarını paylaş
  Future<void> _shareMultipleResults(List<TestResult> results) async {
    if (results.isEmpty) {
      Get.snackbar(
        'Uyarı',
        'Paylaşılacak test sonucu bulunamadı',
        backgroundColor: AppTheme.warningColor,
        colorText: Colors.white,
      );
      return;
    }

    try {
      Get.snackbar(
        'Hazırlanıyor',
        '${results.length} test sonucu için PDF raporu oluşturuluyor...',
        backgroundColor: AppTheme.primaryColor,
        colorText: Colors.white,
      );

      // PDF raporu oluştur
      await _generatePDFReport(results);
      
      Get.snackbar(
        'Başarılı',
        '${results.length} test sonucu PDF raporu paylaşıldı',
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Çoklu test sonuçları paylaşma hatası', e, stackTrace);
      Get.snackbar(
        'Hata',
        'Test sonuçları paylaşılamadı: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    }
  }
  
  /// JSON formatında export
  Future<void> _exportToJSON(List<TestResult> results) async {
    try {
      AppLogger.info('📄 JSON export başlatılıyor: ${results.length} test sonucu');
      
      final jsonData = results.map((result) => {
        'id': result.id,
        'athleteId': result.athleteId,
        'testType': result.testType.name,
        'testDate': result.testDate.toIso8601String(),
        'duration': result.duration.inMilliseconds,
        'status': result.status.name,
        'metrics': result.metrics,
        'qualityScore': result.qualityScore,
        'notes': result.notes,
        'createdAt': result.createdAt.toIso8601String(),
      }).toList();
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/test_results_${DateTime.now().millisecondsSinceEpoch}.json');
      
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'exportDate': DateTime.now().toIso8601String(),
          'totalResults': results.length,
          'results': jsonData,
        }),
      );
      
      AppLogger.success('JSON export tamamlandı: ${file.path}');
      
      // JSON dosyasını paylaş
      await FileShareService.shareJSONFile(
        jsonFile: file,
        subject: 'izForce Test Verileri (JSON)',
        text: 'izForce uygulaması ile dışa aktarılan ${results.length} test sonucu.',
      );
      
      Get.snackbar(
        'JSON Export',
        'Test sonuçları JSON formatında paylaşıldı',
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('JSON export hatası', e, stackTrace);
      rethrow;
    }
  }
  
  /// CSV formatında export
  Future<void> _exportToCSV(List<TestResult> results) async {
    try {
      AppLogger.info('📊 CSV export başlatılıyor: ${results.length} test sonucu');
      
      final athleteController = Get.find<AthleteController>();
      final csvLines = <String>[];
      
      // CSV başlığı
      csvLines.add('Date,Athlete,Test Type,Duration (s),Quality Score,Jump Height,Peak Force,Peak Power,Status');
      
      // Veri satırları
      for (final result in results) {
        final athlete = athleteController.findAthleteById(result.athleteId);
        final athleteName = athlete != null ? '${athlete.firstName} ${athlete.lastName}' : 'Unknown';
        
        final jumpHeight = result.metrics['jumpHeight']?.toStringAsFixed(1) ?? 'N/A';
        final peakForce = result.metrics['peakForce']?.toStringAsFixed(0) ?? 'N/A';
        final peakPower = result.metrics['peakPower']?.toStringAsFixed(0) ?? 'N/A';
        
        csvLines.add([
          DateFormat('yyyy-MM-dd HH:mm').format(result.testDate),
          '"$athleteName"',
          result.testType.turkishName,
          (result.duration.inMilliseconds / 1000).toStringAsFixed(1),
          result.qualityScore.toStringAsFixed(1),
          jumpHeight,
          peakForce,
          peakPower,
          result.status.turkishName,
        ].join(','));
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/test_results_${DateTime.now().millisecondsSinceEpoch}.csv');
      
      await file.writeAsString(csvLines.join('\n'));
      
      AppLogger.success('CSV export tamamlandı: ${file.path}');
      
      // CSV dosyasını paylaş
      await FileShareService.shareCSVFile(
        csvFile: file,
        subject: 'izForce Test Verileri (CSV)',
        text: 'izForce uygulaması ile dışa aktarılan ${results.length} test sonucu.',
      );
      
      Get.snackbar(
        'CSV Export',
        'Test sonuçları CSV formatında paylaşıldı',
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('CSV export hatası', e, stackTrace);
      rethrow;
    }
  }
}

enum ResultsSortBy {
  date('Date', 'Tarih'),
  athlete('Athlete', 'Sporcu'),
  testType('Test Type', 'Test Türü'),
  quality('Quality', 'Kalite');

  const ResultsSortBy(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}