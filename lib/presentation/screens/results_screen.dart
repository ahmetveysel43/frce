import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../../presentation/widgets/metrics_display_widget.dart';
import '../../domain/entities/test_result.dart';
import '../../domain/entities/athlete.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          Text(
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
                style: TextStyle(
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
          icon: Icon(
            Icons.sort,
            color: AppTheme.primaryColor,
          ),
        ),
        IconButton(
          onPressed: () => _showFilterDialog(),
          icon: Stack(
            children: [
              Icon(
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
                    decoration: BoxDecoration(
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
          Text(
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
                icon: Icon(Icons.clear_all, size: 14),
                label: Text('Tümünü Temizle'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  textStyle: TextStyle(fontSize: 12),
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
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 11,
        ),
      ),
      deleteIcon: Icon(
        Icons.close,
        size: 14,
        color: AppTheme.primaryColor,
      ),
      onDeleted: onRemove,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
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
                    Icon(
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
          
          // Export all button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: filteredResults.isNotEmpty 
                  ? () => _exportAllFormats(filteredResults)
                  : null,
              icon: Icon(Icons.download),
              label: Text('Tüm Formatları İndir'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
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
                icon: Icon(Icons.clear),
                label: Text('Filtreleri Temizle'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Get.offAllNamed('/'),
                icon: Icon(Icons.home),
                label: Text('Ana Sayfaya Git'),
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
                      color: _getTestTypeColor(result.testType).withOpacity(0.2),
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
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm').format(result.testDate),
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.timer,
                              size: 12,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${result.duration.inSeconds}s',
                              style: TextStyle(
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
                    icon: Icon(Icons.more_vert, color: AppTheme.textHint),
                    color: AppTheme.darkCard,
                    onSelected: (action) => _handleResultAction(action, result, athlete),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 18, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text('Detayları Görüntüle', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'compare',
                        child: Row(
                          children: [
                            Icon(Icons.compare, size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text('Karşılaştır', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 18, color: AppTheme.accentColor),
                            const SizedBox(width: 8),
                            Text('Dışa Aktar', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                            const SizedBox(width: 8),
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
          style: TextStyle(
            color: AppTheme.textHint,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(
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
        color: Color(int.parse(quality.colorHex.replaceFirst('#', '0xFF'))).withOpacity(0.2),
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
            style: TextStyle(
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
                  Text(
                    testType.code,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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
                        color: color.withOpacity(0.2),
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
                      style: TextStyle(
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    color: AppTheme.textHint,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
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
                      style: TextStyle(
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

  // Helper methods
  List<TestResult> _getFilteredResults(AthleteController controller) {
    // Mock data - gerçek uygulamada database'den gelecek
    final allResults = _generateMockResults(controller);
    
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

  List<TestResult> _generateMockResults(AthleteController controller) {
    final results = <TestResult>[];
    final athletes = controller.athletes;
    
    if (athletes.isEmpty) return results;
    
    // Generate 25 mock results
    for (int i = 0; i < 25; i++) {
      final athlete = athletes[i % athletes.length];
      final testType = TestType.values[i % TestType.values.length];
      final testDate = DateTime.now().subtract(Duration(days: i * 2));
      
      results.add(TestResult.create(
        sessionId: 'session_$i',
        athleteId: athlete.id,
        testType: testType,
        duration: Duration(seconds: 5 + (i % 10)),
        metrics: _generateMockMetricsForType(testType),
      ));
    }
    
    return results;
  }

  Map<String, double> _generateMockMetricsForType(TestType testType) {
    final random = DateTime.now().millisecond;
    
    switch (testType.category) {
      case TestCategory.jump:
        return {
          'jumpHeight': 30.0 + (random % 20),
          'peakForce': 1000.0 + (random % 500),
          'flightTime': 400.0 + (random % 200),
          'asymmetryIndex': 5.0 + (random % 10),
        };
      case TestCategory.strength:
        return {
          'peakForce': 800.0 + (random % 400),
          'averageForce': 600.0 + (random % 200),
          'asymmetryIndex': 3.0 + (random % 8),
          'rfd': 2500.0 + (random % 1500),
        };
      case TestCategory.balance:
        return {
          'copRange': 15.0 + (random % 20),
          'stabilityIndex': 70.0 + (random % 25),
          'asymmetryIndex': 2.0 + (random % 6),
        };
      case TestCategory.agility:
        return {
          'speed': 2.5 + ((random % 15) / 10),
          'asymmetryIndex': 4.0 + (random % 8),
        };
    }
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
        title: Text('Sıralama', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ResultsSortBy.values.map((sortBy) {
            return RadioListTile<ResultsSortBy>(
              title: Text(
                sortBy.turkishName,
                style: TextStyle(color: Colors.white),
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
            child: Text('İptal'),
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
        decoration: BoxDecoration(
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
            Text('Spor Dalı', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSport,
              style: TextStyle(color: Colors.white),
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
            Text('Test Türü', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<TestType>(
              value: _selectedTestType,
              style: TextStyle(color: Colors.white),
              dropdownColor: AppTheme.darkCard,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('Tümü')),
                ...TestType.values.map((type) => 
                  DropdownMenuItem(value: type, child: Text(type.code)),
                ),
              ],
              onChanged: (value) => setState(() => _selectedTestType = value),
            ),
            const SizedBox(height: 16),
            
            // Date range filter
            Text('Tarih Aralığı', style: TextStyle(color: AppTheme.textSecondary)),
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
                    Icon(Icons.date_range, color: AppTheme.textSecondary),
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
                    child: Text('Temizle'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    child: Text('Uygula'),
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
            colorScheme: ColorScheme.dark(
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
        decoration: BoxDecoration(
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
                    color: _getTestTypeColor(result.testType).withOpacity(0.2),
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
                      _exportFormat(ExportFormat.pdf, [result]);
                    },
                    icon: Icon(Icons.download),
                    label: Text('Dışa Aktar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close),
                    label: Text('Kapat'),
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
      case 'delete':
        _confirmDeleteResult(result);
        break;
    }
  }

  void _confirmDeleteResult(TestResult result) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Sonucu Sil', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bu test sonucunu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Başarılı', 'Test sonucu silindi');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _exportFormat(ExportFormat format, List<TestResult> results) {
    Get.snackbar(
      'Dışa Aktarılıyor',
      '${results.length} sonuç ${format.name} formatında dışa aktarılıyor...',
      backgroundColor: AppTheme.primaryColor,
      colorText: Colors.white,
    );
  }

  void _exportAllFormats(List<TestResult> results) {
    Get.snackbar(
      'Tüm Formatlar',
      '${results.length} sonuç tüm formatlarda dışa aktarılıyor...',
      backgroundColor: AppTheme.primaryColor,
      colorText: Colors.white,
    );
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