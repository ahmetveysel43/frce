import 'package:flutter/material.dart';
import '../../data/models/test_result_model.dart';
import '../../data/models/athlete_model.dart';
import '../../core/services/progress_analyzer.dart';
import '../../core/services/pdf_report_service.dart';
import '../../core/services/unified_data_service.dart';
import '../../core/services/modern_analytics_engine.dart';
import '../../core/services/file_share_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/common_ui_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/metric_constants.dart';
import '../widgets/advanced_charts_widget.dart';
import '../widgets/analysis_filter_widget.dart';
import '../theme/app_theme.dart';

/// İlerleme analizi ve performans gösterge paneli
/// Smart Metrics uygulamasından adapte edilmiş gelişmiş analitik ekranı
class ProgressDashboardScreen extends StatefulWidget {
  final String? athleteId;

  const ProgressDashboardScreen({
    super.key,
    this.athleteId,
  });

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen>
    with TickerProviderStateMixin {
  static const String _tag = 'ProgressDashboardScreen';
  
  late TabController _tabController;
  final UnifiedDataService _dataService = UnifiedDataService();
  final ModernAnalyticsEngine _modernAnalytics = ModernAnalyticsEngine();
  
  // Two separate lists like advanced_test_comparison_screen.dart
  final List<TestResultModel> _allTestResults = [];
  final List<TestResultModel> _filteredTestResults = [];
  AthleteModel? _selectedAthlete;
  List<AthleteModel> _allAthletes = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  bool _isAnalyticsLoading = false;
  bool _isDataLoaded = false; // Cache control
  DateTime? _lastDataLoad; // Cache timing
  String _selectedChartType = 'line';

  // Filter state variables (using TestType enum like advanced screen)
  TestType? _selectedTestType;
  DateTimeRange? _selectedDateRange;
  String _selectedMetric = 'Tüm Metrikler';

  // Available metrics
  List<String> _availableMetrics = ['Tüm Metrikler', 'Sıçrama Yüksekliği', 'Uçuş Süresi', 'Güç'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Initialize like advanced_test_comparison_screen.dart
    if (widget.athleteId != null) {
      // Will be set properly in _loadData when athletes are loaded
    }
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Data loading handled in initState
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check cache first - don't reload if data is recent (within 30 seconds)
      final now = DateTime.now();
      if (_isDataLoaded && 
          _lastDataLoad != null && 
          now.difference(_lastDataLoad!).inSeconds < 30) {
        AppLogger.debug('Using cached data for progress dashboard');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load all athletes using unified service (cached)
      _allAthletes = await _dataService.getAllAthletes();
      
      // Set initial athlete selection like advanced screen
      if (_selectedAthlete == null) {
        if (widget.athleteId != null) {
          _selectedAthlete = _allAthletes.isNotEmpty 
            ? _allAthletes.firstWhere(
                (a) => a.id == widget.athleteId,
                orElse: () => _allAthletes.first,
              )
            : null;
        } else if (_allAthletes.isNotEmpty) {
          _selectedAthlete = _allAthletes.first;
        }
      }
      
      // Load test results only if not cached
      await _loadAllTestResults();
      
      // Apply filters to get filtered results
      _applyFilters();
      
      // Update available metrics based on selected test type
      _updateAvailableMetrics();
      
      // Update analytics
      await _updateAnalytics();

      // Mark data as loaded and set timestamp
      _isDataLoaded = true;
      _lastDataLoad = DateTime.now();
      
      setState(() {
        _isLoading = false;
      });
      
      AppLogger.info('$_tag: Dashboard data loaded successfully');
      
    } catch (e, stackTrace) {
      AppLogger.error('Error loading dashboard data', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CommonUIUtils.showErrorSnackBar(context, 'Panel verileri yüklenemedi',
          error: e is Exception ? e : Exception(e.toString()), 
          stackTrace: stackTrace);
      }
    }
  }
  
  // Load all test results EXACTLY like advanced_test_comparison_screen.dart
  Future<void> _loadAllTestResults() async {
    try {
      _allTestResults.clear();
      
      // FIXED: Load test results for ALL athletes like advanced screen
      // Don't filter by selected athlete here - do it in _applyFilters()
      for (final athlete in _allAthletes) {
        AppLogger.info('$_tag: Loading test results for athlete ${athlete.fullName} (${athlete.id})');
        final testResults = await _dataService.getAthleteTestResults(athlete.id);
        AppLogger.info('$_tag: Found ${testResults.length} test results for ${athlete.fullName}');
        _allTestResults.addAll(testResults);
      }
      
      // If no results found, try loading all results as fallback
      if (_allTestResults.isEmpty) {
        AppLogger.warning('$_tag: No test results found for individual athletes, loading all results');
        final allResults = await _dataService.getAllTestResults();
        _allTestResults.addAll(allResults);
      }

      // Sort by date (newest first)
      _allTestResults.sort((a, b) => b.testDate.compareTo(a.testDate));
      
      AppLogger.info('$_tag: Total test results loaded: ${_allTestResults.length}');
    } catch (e, stackTrace) {
      AppLogger.error('Error loading test results', e, stackTrace);
      // Continue with empty results rather than throwing
    }
  }

  /// Analitikleri güncelle (veri yeniden yüklemeden)
  Future<void> _updateAnalytics() async {
    // Eğer analytics loading devam ediyorsa bekle
    if (_isAnalyticsLoading) {
      AppLogger.info('Analytics update already in progress, skipping');
      return;
    }
    
    try {
      setState(() {
        _isAnalyticsLoading = true;
      });
      
      if (_filteredTestResults.isNotEmpty) {
        AppLogger.info('$_tag: Updating analytics for ${_filteredTestResults.length} test results');
        
        final advancedMetrics = await ProgressAnalyzer.calculateAdvancedAnalytics(
          _filteredTestResults,
          _selectedAthlete?.id ?? '',
        );
        
        // Modern analytics integration
        final temporalDynamics = await _modernAnalytics.analyzeTemporalDynamics(
          testResults: _filteredTestResults,
        );
        
        final contextualAnalysis = await _modernAnalytics.analyzeContextualFactors(
          testResults: _filteredTestResults,
        );

        // Transform the analytics data to match the expected structure
        _analytics = {
          'reliability': advancedMetrics['reliability'] ?? 0.0,
          'cv': advancedMetrics['cv'] ?? 0.0,
          'icc': advancedMetrics['icc'] ?? 0.0,
          'sem': advancedMetrics['sem'] ?? 0.0,
          'mdc': advancedMetrics['mdc'] ?? 0.0,
          'swc': advancedMetrics['swc'] ?? 0.0,
          'metrics': {
            'Sıçrama Yüksekliği': _calculateAverageMetric('jumpHeight'),
            'Pik Kuvvet': _calculateAverageMetric('peakForce'),
            'Uçuş Süresi': _calculateAverageMetric('flightTime'),
            'Güç': _calculateAverageMetric('power'),
          },
          'trends': {
            'Son Trend': _calculateRecentTrend(),
            'Genel İlerleme': _calculateOverallProgress(),
            'Haftalık Değişim': _calculateWeeklyChange(),
          },
          'insights': _generateBasicInsights(),
          // Modern analytics additions
          'temporal_dynamics': {
            'volatility_index': temporalDynamics.volatilityIndex,
            'trend_persistence': temporalDynamics.trendPersistence,
            'detected_cycles': temporalDynamics.detectedCycles.length,
          },
          'contextual_factors': {
            'time_of_day_effects': contextualAnalysis.timeOfDayEffects,
            'day_of_week_effects': contextualAnalysis.dayOfWeekEffects,
            'seasonal_effects': contextualAnalysis.seasonalEffects,
          },
        };
        
        AppLogger.info('$_tag: Analytics updated successfully');
      } else {
        // Initialize empty analytics for UI consistency
        _analytics = {
          'reliability': 0.0,
          'cv': 0.0,
          'icc': 0.0,
          'sem': 0.0,
          'mdc': 0.0,
          'swc': 0.0,
          'metrics': {
            'Sıçrama Yüksekliği': 0.0,
            'Pik Kuvvet': 0.0,
            'Uçuş Süresi': 0.0,
            'Güç': 0.0,
          },
          'trends': {
            'Son Trend': 0.0,
            'Genel İlerleme': 0.0,
            'Haftalık Değişim': 0.0,
          },
          'insights': ['Yeterli veri bulunmuyor'],
          'temporal_dynamics': {
            'volatility_index': 0.0,
            'trend_persistence': 0.0,
            'detected_cycles': 0,
          },
          'contextual_factors': {
            'time_of_day_effects': <String, double>{},
            'day_of_week_effects': <String, double>{},
            'seasonal_effects': <String, double>{},
          },
        };
        AppLogger.warning('$_tag: No data available for analytics');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error updating analytics', e, stackTrace);
      // Provide fallback analytics with complete structure
      _analytics = {
        'reliability': 0.0,
        'cv': 0.0,
        'icc': 0.0,
        'sem': 0.0,
        'mdc': 0.0,
        'swc': 0.0,
        'metrics': {
          'Sıçrama Yüksekliği': 0.0,
          'Pik Kuvvet': 0.0,
          'Uçuş Süresi': 0.0,
          'Güç': 0.0,
        },
        'trends': {
          'Son Trend': 0.0,
          'Genel İlerleme': 0.0,
          'Haftalık Değişim': 0.0,
        },
        'insights': ['Analiz hesaplanırken hata oluştu'],
        'temporal_dynamics': {
          'volatility_index': 0.0,
          'trend_persistence': 0.0,
          'detected_cycles': 0,
        },
        'contextual_factors': {
          'time_of_day_effects': <String, double>{},
          'day_of_week_effects': <String, double>{},
          'seasonal_effects': <String, double>{},
        },
      };
    } finally {
      setState(() {
        _isAnalyticsLoading = false;
      });
    }
  }

  void _updateAvailableMetrics() {
    if (_selectedTestType == null) {
      _availableMetrics = ['Tüm Metrikler', 'Sıçrama Yüksekliği', 'Uçuş Süresi', 'Güç'];
    } else {
      final metrics = MetricConstants.getMetricsForTestType(_selectedTestType!.code);
      _availableMetrics = ['Tüm Metrikler', ...metrics.map((m) => m.displayName).toList()];
    }
    
    if (_availableMetrics.isEmpty) {
      _availableMetrics = ['Tüm Metrikler', 'Sıçrama Yüksekliği', 'Uçuş Süresi', 'Güç'];
    }
    
    if (!_availableMetrics.contains(_selectedMetric)) {
      _selectedMetric = _availableMetrics.first;
    }
  }
  

  // Apply filters exactly like advanced_test_comparison_screen.dart
  void _applyFilters() {
    _filteredTestResults.clear();
    
    for (final result in _allTestResults) {
      // Athlete filter
      if (_selectedAthlete != null && result.athleteId != _selectedAthlete!.id) {
        continue;
      }
      
      // Test type filter - FIXED: More flexible matching
      if (_selectedTestType != null) {
        final resultTestType = result.testType.toUpperCase();
        final selectedTestCode = _selectedTestType!.code.toUpperCase();
        final selectedTestName = _selectedTestType!.name.toUpperCase();
        
        bool typeMatches = false;
        
        // Direct matches
        if (resultTestType == selectedTestCode || 
            resultTestType == selectedTestName ||
            resultTestType == _selectedTestType!.name.toUpperCase()) {
          typeMatches = true;
        }
        
        // Common abbreviations and variations
        else if (selectedTestCode == 'CMJ' && 
                (resultTestType.contains('CMJ') || 
                 resultTestType.contains('COUNTER') || 
                 resultTestType.contains('MOVEMENT'))) {
          typeMatches = true;
        }
        else if (selectedTestCode == 'SJ' && 
                (resultTestType.contains('SJ') || 
                 resultTestType.contains('SQUAT'))) {
          typeMatches = true;
        }
        else if (selectedTestCode == 'DJ' && 
                (resultTestType.contains('DJ') || 
                 resultTestType.contains('DROP'))) {
          typeMatches = true;
        }
        else if (selectedTestCode.contains('BALANCE') && 
                resultTestType.contains('BALANCE')) {
          typeMatches = true;
        }
        
        if (!typeMatches) {
          continue;
        }
      }
      
      // Date range filter
      if (_selectedDateRange != null) {
        if (result.testDate.isBefore(_selectedDateRange!.start) ||
            result.testDate.isAfter(_selectedDateRange!.end)) {
          continue;
        }
      }
      
      _filteredTestResults.add(result);
    }
    
    AppLogger.info('$_tag: Applied filters: ${_filteredTestResults.length}/${_allTestResults.length} results');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Performans Paneli'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildExportButton(),
          _buildOptionsMenu(),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Genel Bakış', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Analitikler', icon: Icon(Icons.analytics_outlined)),
            Tab(text: 'Karşılaştırmalar', icon: Icon(Icons.compare_outlined)),
            Tab(text: 'Raporlar', icon: Icon(Icons.description_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? CommonUIUtils.buildLoadingWidget(message: 'Panel yükleniyor...')
          : Column(
              children: [
                // Tek filter widget tüm tab'lar için
                _buildFilterHeader(),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildAnalyticsTab(),
                      _buildComparisonsTab(),
                      _buildReportsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _filteredTestResults.isNotEmpty && _selectedAthlete != null
          ? FloatingActionButton(
              onPressed: _sharePerformanceSummary,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Performans Özeti Paylaş',
            )
          : null,
    );
  }

  Widget _buildFilterHeader() {
    // Guard against empty athletes list
    if (_allAthletes.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Text(
          'Henüz sporcu verisi yüklenmedi...',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnalysisFilterWidget(
        athletes: _allAthletes,
        selectedAthleteId: _selectedAthlete?.id,
        selectedTestType: _selectedTestType?.code ?? 'Tümü',
        selectedDateRange: _selectedDateRange,
        selectedMetric: _selectedMetric,
        resultCount: _filteredTestResults.length,
        onAthleteChanged: (value) {
          if (value != null && !_isAnalyticsLoading) {
            setState(() {
              _selectedAthlete = _allAthletes.firstWhere((a) => a.id == value);
            });
            _applyFilters();
            _updateAnalytics();
          }
        },
        onTestTypeChanged: (value) {
          if (!_isAnalyticsLoading) {
            setState(() {
              _selectedTestType = value == 'Tümü' 
                  ? null 
                  : TestType.values.firstWhere(
                      (t) => t.code == value,
                      orElse: () => TestType.counterMovementJump,
                    );
              _updateAvailableMetrics();
            });
            _applyFilters();
            _updateAnalytics();
          }
        },
        onDateRangeChanged: (dateRange) {
          if (_isAnalyticsLoading) return;
          
          setState(() {
            _selectedDateRange = dateRange;
          });
          _applyFilters();
          _updateAnalytics();
        },
        onMetricChanged: (value) {
          if (!_isAnalyticsLoading) {
            setState(() {
              _selectedMetric = value;
            });
            _updateAnalytics();
          }
        },
        onRefresh: _loadData,
        isExpanded: false,
        isDarkTheme: true,
      ),
    );
  }

  Widget _buildExportButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.file_download_outlined),
      tooltip: 'Dışa Aktar',
      onSelected: (value) {
        switch (value) {
          case 'pdf':
            _exportToPDF();
            break;
          case 'share_summary':
            _sharePerformanceSummary();
            break;
          case 'share_analytics':
            _shareAnalyticsSummary();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('PDF Raporu'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share_summary',
          child: Row(
            children: [
              Icon(Icons.share, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('Performans Özeti Paylaş'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share_analytics',
          child: Row(
            children: [
              Icon(Icons.analytics, size: 18, color: Colors.green),
              SizedBox(width: 8),
              Text('Analitik Özet Paylaş'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'refresh':
            _updateAnalytics();
            break;
          case 'settings':
            _showSettingsDialog();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'refresh', child: Text('Veriyi Yenile')),
        const PopupMenuItem(value: 'settings', child: Text('Ayarlar')),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Show data or no data message
          if (_filteredTestResults.isNotEmpty && _analytics != null) ...[
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildEnhancedPerformanceTrendChart(),
            const SizedBox(height: 24),
            _buildPerformanceProfileChart(),
            const SizedBox(height: 24),
            _buildRecentTestsSection(),
            const SizedBox(height: 24),
            _buildKeyInsightsSection(),
          ] else
            Center(
              child: Container(
                height: 400,
                child: _buildNoDataWidget(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          if (_filteredTestResults.isNotEmpty && _analytics != null) ...[
            // Advanced Chart with Multiple Views
            _buildAdvancedAnalyticsChart(),
            const SizedBox(height: 24),
            
            // Force-Velocity Profile if available
            if (_filteredTestResults.any((r) => r.metrics.containsKey('peakForce') && r.metrics.containsKey('peakVelocity')))
              _buildForceVelocityProfile(),
            const SizedBox(height: 24),
            
            _buildDetailedMetrics(),
            const SizedBox(height: 24),
            _buildTrendAnalysis(),
            const SizedBox(height: 24),
            _buildModernAnalyticsSection(),
          ] else
            Center(
              child: Container(
                height: 400,
                child: _buildNoDataWidget(),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAdvancedAnalyticsChart() {
    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Gelişmiş Performans Analitikleri',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: _buildChartTypeSelector()),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 550,
            child: AdvancedChartsWidget(
              testResults: _filteredTestResults,
              analytics: _analytics,
              chartType: _selectedChartType,
              height: 550,
              primaryColor: AppTheme.primaryColor,
              showGrid: true,
              enableInteraction: true,
              showLegend: true,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildForceVelocityProfile() {
    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.scatter_plot, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Kuvvet-Hız Profili',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 500,
            child: AdvancedChartsWidget(
              testResults: _filteredTestResults,
              analytics: _analytics,
              chartType: 'scatter',
              height: 500,
              primaryColor: Colors.orange,
              enableInteraction: true,
              showLegend: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          if (_filteredTestResults.isNotEmpty && _analytics != null) ...[
            _buildTestTypeComparisons(),
            const SizedBox(height: 24),
            _buildTimeperiodComparisons(),
            const SizedBox(height: 24),
            _buildPerformanceDistribution(),
          ] else
            Center(
              child: Container(
                height: 400,
                child: _buildNoDataWidget(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportTemplates(),
          const SizedBox(height: 24),
          _buildCustomReportBuilder(),
          const SizedBox(height: 24),
          _buildReportHistory(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard(
          'Genel Puan',
          '${((_analytics!['reliability'] as double?) ?? 0.0).toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.blue,
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard(
          'Tutarlılık',
          '${(100 - ((_analytics!['cv'] as double?) ?? 20.0)).toStringAsFixed(0)}%',
          Icons.show_chart,
          Colors.green,
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard(
          'Tamamlanan Testler',
          '${_filteredTestResults.length}',
          Icons.assignment_turned_in,
          Colors.orange,
        )),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return CommonUIUtils.buildMetricCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
    );
  }

  Widget _buildEnhancedPerformanceTrendChart() {
    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Performans Trend Analizi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: _buildChartTypeSelector()),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 600,
            child: AdvancedChartsWidget(
              testResults: _filteredTestResults,
              analytics: _analytics,
              chartType: _selectedChartType,
              height: 600,
              primaryColor: AppTheme.primaryColor,
              showGrid: true,
              enableInteraction: true,
              showLegend: true,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendSummary(),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceProfileChart() {
    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Atletik Performans Profili',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 600,
            child: AdvancedChartsWidget(
              testResults: _filteredTestResults,
              analytics: _analytics,
              chartType: 'radar',
              height: 600,
              primaryColor: AppTheme.primaryColor,
              showLegend: false,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrendSummary() {
    final trend = _calculateRecentTrend();
    final isPositive = trend > 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isPositive 
                ? 'Performans pozitif trend gösteriyor (+${trend.toStringAsFixed(1)}%)'
                : 'Performans düşüş gösteriyor (${trend.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTestsSection() {
    final recentTests = _filteredTestResults.take(5).toList();
    
    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son Testler',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (recentTests.isNotEmpty)
            ...recentTests.map((test) => _buildTestListItem(test))
          else
            Center(
              child: Text(
                'Son test bulunmuyor',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTestListItem(TestResultModel test) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getScoreColor(test.score ?? 0.0),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.testType,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${test.timestamp.day}/${test.timestamp.month}/${test.timestamp.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(test.score ?? 0.0).toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getScoreColor(test.score ?? 0.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInsightsSection() {
    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temel İçgörüler',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...(_analytics!['insights'] as List<dynamic>? ?? []).map((insight) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  insight.toString(),
                  style: const TextStyle(color: Colors.white70),
                )),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    final chartTypes = [
      {'type': 'line', 'icon': Icons.show_chart, 'label': 'Çizgi'},
      {'type': 'bar', 'icon': Icons.bar_chart, 'label': 'Çubuk'},
      {'type': 'scatter', 'icon': Icons.scatter_plot, 'label': 'Dağılım'},
      {'type': 'pie', 'icon': Icons.pie_chart, 'label': 'Pasta'},
    ];
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 200), // Limit maximum width
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: chartTypes.map((chart) {
            final isSelected = chart['type'] == _selectedChartType;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedChartType = chart['type'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced padding
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      chart['icon'] as IconData,
                      size: 14, // Reduced icon size
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    const SizedBox(width: 3), // Reduced spacing
                    Text(
                      chart['label'] as String,
                      style: TextStyle(
                        fontSize: 11, // Reduced font size
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detaylı Metrikler',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...() {
            final metricsData = _analytics!['metrics'];
            if (metricsData == null) return <Widget>[];
            
            final Map<String, dynamic> metrics = {};
            if (metricsData is Map) {
              metricsData.forEach((key, value) {
                metrics[key.toString()] = value;
              });
            }
            
            return metrics.entries.map((entry) => _buildMetricRow(
              entry.key,
              (entry.value is num ? entry.value.toDouble() : 0.0).toStringAsFixed(1),
              0.0, // Default trend
            )).toList();
          }(),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, double trend) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label, 
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 8),
              Icon(
                trend > 0 ? Icons.trending_up : 
                trend < 0 ? Icons.trending_down : Icons.trending_flat,
                size: 16,
                color: trend > 0 ? Colors.green : 
                       trend < 0 ? Colors.red : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Analizi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...() {
            final trendsData = _analytics!['trends'];
            if (trendsData == null) return <Widget>[];
            
            final Map<String, dynamic> trends = {};
            if (trendsData is Map) {
              trendsData.forEach((key, value) {
                trends[key.toString()] = value;
              });
            }
            
            return trends.entries.map((entry) {
              final value = entry.value is num ? entry.value.toDouble() : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: value > 0 ? Colors.green : 
                               value < 0 ? Colors.red : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          }(),
        ],
      ),
    );
  }

  Widget _buildTestTypeComparisons() {
    if (_filteredTestResults.isEmpty) {
      return CommonUIUtils.buildStandardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Tipi Karşılaştırmaları',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                height: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Karşılaştırma için test verisi bulunmuyor',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final testTypes = _filteredTestResults.map((e) => e.testType).toSet().toList();
    
    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Tipi Karşılaştırmaları',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (testTypes.isNotEmpty)
            ...testTypes.map((testType) {
              final typeResults = _filteredTestResults.where((r) => r.testType == testType).toList();
              final avgScore = typeResults.isEmpty 
                  ? 0.0 
                  : typeResults.map((e) => e.score ?? 0.0).reduce((a, b) => a + b) / typeResults.length;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        testType, 
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${avgScore.toStringAsFixed(1)}% (${typeResults.length} tests)',
                      style: TextStyle(color: _getScoreColor(avgScore)),
                    ),
                  ],
                ),
              );
            }).toList()
          else
            Center(
              child: Text(
                'Test tipi bulunmuyor',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeperiodComparisons() {
    final now = DateTime.now();
    final thisWeek = _filteredTestResults.where((r) => 
      r.testDate.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final lastWeek = _filteredTestResults.where((r) => 
      r.testDate.isAfter(now.subtract(const Duration(days: 14))) &&
      r.testDate.isBefore(now.subtract(const Duration(days: 7)))).toList();
    
    final thisMonth = _filteredTestResults.where((r) => 
      r.testDate.month == now.month && r.testDate.year == now.year).toList();
    final lastMonth = _filteredTestResults.where((r) => 
      r.testDate.month == (now.month - 1) && r.testDate.year == now.year).toList();

    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zaman Periyodu Karşılaştırmaları',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildPeriodComparisonRow(
            'Bu Hafta vs Geçen Hafta',
            thisWeek.length,
            lastWeek.length,
            _calculateAverageScore(thisWeek),
            _calculateAverageScore(lastWeek),
          ),
          const SizedBox(height: 12),
          _buildPeriodComparisonRow(
            'Bu Ay vs Geçen Ay',
            thisMonth.length,
            lastMonth.length,
            _calculateAverageScore(thisMonth),
            _calculateAverageScore(lastMonth),
          ),
          const SizedBox(height: 16),
          if ((thisWeek.isNotEmpty || lastWeek.isNotEmpty) && _analytics != null)
            SizedBox(
              height: 450,
              child: AdvancedChartsWidget(
                testResults: [...thisWeek, ...lastWeek],
                analytics: _analytics,
                chartType: 'bar',
                height: 450,
                primaryColor: AppTheme.primaryColor,
                showGrid: true,
                enableInteraction: true,
                showLegend: false,
              ),
            )
          else if (thisWeek.isEmpty && lastWeek.isEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Bu dönemde test verisi bulunmuyor',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPeriodComparisonRow(String label, int count1, int count2, double avg1, double avg2) {
    final change = avg2 > 0 ? ((avg1 - avg2) / avg2 * 100) : 0.0;
    final isImprovement = change > 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Testler: $count1 vs $count2',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    isImprovement ? Icons.trending_up : Icons.trending_down,
                    color: isImprovement ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isImprovement ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${avg1.toStringAsFixed(1)} vs ${avg2.toStringAsFixed(1)}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  double _calculateAverageScore(List<TestResultModel> tests) {
    if (tests.isEmpty) return 0.0;
    final scores = tests.map((t) => t.score ?? 0.0).toList();
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  Widget _buildPerformanceDistribution() {
    // Calculate performance distribution
    final excellentCount = _filteredTestResults.where((r) => (r.score ?? 0) >= 90).length;
    final goodCount = _filteredTestResults.where((r) => (r.score ?? 0) >= 70 && (r.score ?? 0) < 90).length;
    final averageCount = _filteredTestResults.where((r) => (r.score ?? 0) >= 50 && (r.score ?? 0) < 70).length;
    final poorCount = _filteredTestResults.where((r) => (r.score ?? 0) < 50).length;
    
    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performans Dağılımı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_filteredTestResults.isNotEmpty && _analytics != null) ...[
            SizedBox(
              height: 600,
              child: AdvancedChartsWidget(
                testResults: _filteredTestResults,
                analytics: _analytics,
                chartType: 'pie',
                height: 600,
                primaryColor: AppTheme.primaryColor,
                enableInteraction: true,
                showLegend: false,
              ),
            ),
            const SizedBox(height: 16),
            _buildDistributionLegend(excellentCount, goodCount, averageCount, poorCount),
          ] else
            Center(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Dağılım için yeterli veri bulunmuyor',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDistributionLegend(int excellent, int good, int average, int poor) {
    final total = excellent + good + average + poor;
    
    return Column(
      children: [
        _buildDistributionRow('Mükemmel (90-100)', excellent, total, Colors.green),
        _buildDistributionRow('İyi (70-89)', good, total, Colors.blue),
        _buildDistributionRow('Ortalama (50-69)', average, total, Colors.orange),
        _buildDistributionRow('Zayıf (<50)', poor, total, Colors.red),
      ],
    );
  }
  
  Widget _buildDistributionRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            '$count (${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTemplates() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rapor Şablonları',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportTemplate('Performans Özeti', 'Son performansın hızlı genel bakışı'),
            _buildReportTemplate('Detaylı Analiz', 'Kapsamlı performans analizi'),
            _buildReportTemplate('İlerleme Raporu', 'Uzun vadeli ilerleme takibi'),
            _buildReportTemplate('Karşılaştırma Raporu', 'Farklı zaman periyotlarını karşılaştır'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTemplate(String title, String description) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.download),
        onTap: () => _generateReport(title),
      ),
    );
  }

  Widget _buildCustomReportBuilder() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Özel Rapor Oluşturucu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCustomReportDialog,
              icon: const Icon(Icons.build),
              label: const Text('Özel Rapor Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHistory() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rapor Geçmişi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Daha önce rapor oluşturulmamış'),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return CommonUIUtils.buildNoDataWidget(
      icon: Icons.analytics_outlined,
      title: 'Analitik veri bulunmuyor',
      subtitle: 'Performans analitiklerinizi görmek için bazı testler tamamlayın',
      action: ElevatedButton.icon(
        onPressed: _loadData,
        icon: const Icon(Icons.refresh),
        label: const Text('Yenile'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    return CommonUIUtils.getScoreColor(score);
  }

  Future<void> _exportToPDF() async {
    try {
      if (_selectedAthlete == null || _filteredTestResults.isEmpty) {
        _showErrorSnackBar('Dışa aktarma için veri bulunmuyor');
        return;
      }

      _showSuccessSnackBar('Performans raporu oluşturuluyor...');

      // Generate performance analysis first
      final analysis = await ProgressAnalyzer.analyzePerformance(
        athleteId: widget.athleteId ?? '',
        athlete: _selectedAthlete!,
        results: _filteredTestResults,
        testType: TestType.counterMovementJump, // Default test type
      );

      final pdfFile = await PDFReportService.generatePerformanceReport(
        athlete: _selectedAthlete!,
        results: _filteredTestResults,
        analysis: analysis,
      );

      // PDF'i paylaş
      await FileShareService.sharePDFFile(
        pdfFile: pdfFile,
        subject: 'izForce Performans Raporu - ${_selectedAthlete!.firstName} ${_selectedAthlete!.lastName}',
        text: 'Performans paneli raporu. ${_filteredTestResults.length} test sonucu analiz edilmiştir.',
      );

      _showSuccessSnackBar('Rapor başarıyla oluşturuldu ve paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Error exporting PDF', e, stackTrace);
      _showErrorSnackBar('Rapor dışa aktarma başarısız');
    }
  }

  Future<void> _generateReport(String reportType) async {
    try {
      if (_selectedAthlete == null || _filteredTestResults.isEmpty) {
        _showErrorSnackBar('Rapor oluşturma için veri bulunmuyor');
        return;
      }

      _showSuccessSnackBar('$reportType oluşturuluyor...');

      // Generate performance analysis first
      final analysis = await ProgressAnalyzer.analyzePerformance(
        athleteId: widget.athleteId ?? '',
        athlete: _selectedAthlete!,
        results: _filteredTestResults,
        testType: TestType.counterMovementJump, // Default test type
      );

      final pdfFile = await PDFReportService.generatePerformanceReport(
        athlete: _selectedAthlete!,
        results: _filteredTestResults,
        analysis: analysis,
      );

      // PDF'i paylaş
      await FileShareService.sharePDFFile(
        pdfFile: pdfFile,
        subject: 'izForce $reportType - ${_selectedAthlete!.firstName} ${_selectedAthlete!.lastName}',
        text: '$reportType. ${_filteredTestResults.length} test sonucu analiz edilmiştir.',
      );

      _showSuccessSnackBar('$reportType başarıyla oluşturuldu ve paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Error generating report', e, stackTrace);
      _showErrorSnackBar('Rapor oluşturma başarısız');
    }
  }

  void _showCustomReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Özel Rapor Oluşturucu'),
        content: const Text('Özel rapor oluşturucu işlevleri burada uygulanacak'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateCustomReport();
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Panel Ayarları'),
        content: const Text('Panel ayarları burada uygulanacak'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    CommonUIUtils.showErrorSnackBar(context, message);
  }

  void _showSuccessSnackBar(String message) {
    CommonUIUtils.showSuccessSnackBar(context, message);
  }


  // Helper methods for analytics fallbacks
  double _calculateAverageMetric(String metricKey) {
    if (_filteredTestResults.isEmpty) return 0.0;
    
    final values = _filteredTestResults
        .map((r) => r.metrics[metricKey])
        .where((value) => value != null)
        .cast<double>()
        .toList();
        
    return values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateRecentTrend() {
    if (_filteredTestResults.length < 2) return 0.0;
    
    final recent = _filteredTestResults.take(5).toList();
    final scores = recent.map((r) => r.score ?? 0.0).toList();
    
    if (scores.length < 2) return 0.0;
    
    double trend = 0.0;
    for (int i = 1; i < scores.length; i++) {
      trend += scores[i] - scores[i - 1];
    }
    
    return trend / (scores.length - 1);
  }

  double _calculateOverallProgress() {
    if (_filteredTestResults.length < 2) return 0.0;
    
    final first = _filteredTestResults.last.score ?? 0.0;
    final last = _filteredTestResults.first.score ?? 0.0;
    
    return first != 0 ? ((last - first) / first * 100) : 0.0;
  }

  List<String> _generateBasicInsights() {
    final insights = <String>[];
    
    if (_filteredTestResults.isEmpty) {
      insights.add('Daha fazla test yaparak analiz kalitesini artırın');
      return insights;
    }
    
    final avgScore = _filteredTestResults
        .map((r) => r.score ?? 0.0)
        .reduce((a, b) => a + b) / _filteredTestResults.length;
    
    if (avgScore > 80) {
      insights.add('Mükemmel performans seviyesi gösteriyorsunuz');
    } else if (avgScore > 60) {
      insights.add('İyi performans seviyesi, gelişim devam ediyor');
    } else {
      insights.add('Performans gelişimi için daha fazla antrenman gerekli');
    }
    
    final trend = _calculateRecentTrend();
    if (trend > 2) {
      insights.add('Son testlerde olumlu bir gelişim trendi var');
    } else if (trend < -2) {
      insights.add('Son testlerde performans düşüşü gözlemleniyor');
    }
    
    return insights;
  }

  double _calculateWeeklyChange() {
    if (_filteredTestResults.length < 2) return 0.0;
    
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    
    final thisWeekTests = _filteredTestResults.where((r) => r.testDate.isAfter(oneWeekAgo)).toList();
    final lastWeekTests = _filteredTestResults.where((r) => 
      r.testDate.isBefore(oneWeekAgo) && 
      r.testDate.isAfter(oneWeekAgo.subtract(const Duration(days: 7)))
    ).toList();
    
    if (thisWeekTests.isEmpty || lastWeekTests.isEmpty) return 0.0;
    
    final thisWeekAvg = thisWeekTests.map((r) => r.score ?? 0.0).reduce((a, b) => a + b) / thisWeekTests.length;
    final lastWeekAvg = lastWeekTests.map((r) => r.score ?? 0.0).reduce((a, b) => a + b) / lastWeekTests.length;
    
    return lastWeekAvg != 0 ? ((thisWeekAvg - lastWeekAvg) / lastWeekAvg * 100) : 0.0;
  }

  Widget _buildModernAnalyticsSection() {
    return CommonUIUtils.buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                'Modern Analitikler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_analytics != null && _analytics!.containsKey('temporal_dynamics')) ...[ 
            _buildTemporalDynamicsCard(),
            const SizedBox(height: 16),
            _buildContextualFactorsCard(),
          ] else
            Center(
              child: Text(
                'Yeterli veri bulunmuyor (minimum 14 test gerekli)',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemporalDynamicsCard() {
    final temporalData = _analytics!['temporal_dynamics'] as Map<String, dynamic>;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zamansal Dinamik Analizi',
            style: TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTemporalMetric(
                'Volatilite İndeksi',
                '${(temporalData['volatility_index'] ?? 0.0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.orange,
              ),
              _buildTemporalMetric(
                'Trend Kalıcılığı',
                '${(temporalData['trend_persistence'] ?? 0.0).toStringAsFixed(2)}',
                Icons.timeline,
                Colors.blue,
              ),
              _buildTemporalMetric(
                'Performans Döngüleri',
                '${temporalData['detected_cycles'] ?? 0}',
                Icons.autorenew,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextualFactorsCard() {
    final contextualData = _analytics!['contextual_factors'] as Map<String, dynamic>;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bağlamsal Performans Faktörleri',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (contextualData['time_of_day_effects'] != null)
            _buildContextualCategory(
              'Gün Saati Etkileri',
              contextualData['time_of_day_effects'] as Map<String, double>,
            ),
          const SizedBox(height: 8),
          if (contextualData['day_of_week_effects'] != null)
            _buildContextualCategory(
              'Haftanın Günü Etkileri',
              contextualData['day_of_week_effects'] as Map<String, double>,
            ),
          const SizedBox(height: 8),
          if (contextualData['seasonal_effects'] != null)
            _buildContextualCategory(
              'Mevsimsel Etkiler',
              contextualData['seasonal_effects'] as Map<String, double>,
            ),
        ],
      ),
    );
  }

  Widget _buildTemporalMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContextualCategory(String title, Map<String, double> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ...data.entries.map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                '${entry.value.toStringAsFixed(1)}',
                style: TextStyle(
                  color: _getScoreColor(entry.value),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  // Test türüne göre metrik birimi döndürür

  /// Özel rapor oluştur
  Future<void> _generateCustomReport() async {
    try {
      if (_selectedAthlete == null || _filteredTestResults.isEmpty) {
        _showErrorSnackBar('Özel rapor için veri bulunmuyor');
        return;
      }

      _showSuccessSnackBar('Özel rapor oluşturuluyor...');

      // Özel rapor için veri hazırla
      final customData = <String, dynamic>{
        'athleteInfo': {
          'name': '${_selectedAthlete!.firstName} ${_selectedAthlete!.lastName}',
          'sport': _selectedAthlete!.sport,
          'totalTests': _filteredTestResults.length,
        },
        'dateRange': {
          'from': _filteredTestResults.isNotEmpty 
            ? _filteredTestResults.map((r) => r.testDate).reduce((a, b) => a.isBefore(b) ? a : b)
            : DateTime.now(),
          'to': _filteredTestResults.isNotEmpty 
            ? _filteredTestResults.map((r) => r.testDate).reduce((a, b) => a.isAfter(b) ? a : b)
            : DateTime.now(),
        },
        'metrics': _filteredTestResults.isNotEmpty 
          ? _filteredTestResults.first.metrics 
          : <String, double>{},
        'testTypes': _filteredTestResults.map((r) => r.testType).toSet().toList(),
      };

      // Özel rapor başlığı oluştur
      final reportTitle = 'Özel Performans Raporu - ${_selectedAthlete!.firstName} ${_selectedAthlete!.lastName}';

      // PDF raporu oluştur
      final pdfFile = await PDFReportService.generateCustomReport(
        title: reportTitle,
        data: customData,
        sections: [
          'Sporcu Bilgileri',
          'Test Özeti',
          'Performans Metrikleri',
          'Analiz Sonuçları',
        ],
        formatting: {
          'includeCharts': true,
          'includeStatistics': true,
          'includeRecommendations': true,
        },
      );

      // PDF'i paylaş
      await FileShareService.sharePDFFile(
        pdfFile: pdfFile,
        subject: reportTitle,
        text: 'Özel performans raporu. ${_filteredTestResults.length} test sonucu içeren kapsamlı analiz.',
      );

      _showSuccessSnackBar('Özel rapor başarıyla oluşturuldu ve paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Özel rapor oluşturma hatası', e, stackTrace);
      _showErrorSnackBar('Özel rapor oluşturma başarısız: ${e.toString()}');
    }
  }

  /// Performans özeti paylaş
  Future<void> _sharePerformanceSummary() async {
    try {
      if (_selectedAthlete == null || _filteredTestResults.isEmpty) {
        _showErrorSnackBar('Paylaşım için veri bulunmuyor');
        return;
      }

      final athleteName = '${_selectedAthlete!.firstName} ${_selectedAthlete!.lastName}';
      final testCount = _filteredTestResults.length;
      final avgScore = _filteredTestResults.map((r) => r.score ?? 0.0).reduce((a, b) => a + b) / testCount;
      final reliability = _analytics?['reliability'] ?? 0.0;
      final cv = _analytics?['cv'] ?? 0.0;
      final consistency = 100 - cv;

      final summary = '''
🏅 izForce Performans Özeti

🏃‍♀️ Sporcu: $athleteName
📈 Test Sayısı: $testCount
⭐ Ortalama Puan: ${avgScore.toStringAsFixed(1)}%
🎯 Güvenilirlik: ${reliability.toStringAsFixed(1)}%
🔄 Tutarlılık: ${consistency.toStringAsFixed(1)}%

📅 Rapor Tarihi: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
📱 izForce ile oluşturuldu''';

      await FileShareService.shareTextSummary(
        text: summary,
        subject: 'izForce Performans Özeti - $athleteName',
      );

      _showSuccessSnackBar('Performans özeti paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Performans özeti paylaşım hatası', e, stackTrace);
      _showErrorSnackBar('Paylaşım başarısız: ${e.toString()}');
    }
  }

  /// Analitik özet paylaş
  Future<void> _shareAnalyticsSummary() async {
    try {
      if (_selectedAthlete == null || _filteredTestResults.isEmpty || _analytics == null) {
        _showErrorSnackBar('Analitik veri bulunmuyor');
        return;
      }

      final athleteName = '${_selectedAthlete!.firstName} ${_selectedAthlete!.lastName}';
      final testCount = _filteredTestResults.length;
      final reliability = _analytics!['reliability'] ?? 0.0;
      final cv = _analytics!['cv'] ?? 0.0;
      final icc = _analytics!['icc'] ?? 0.0;
      final sem = _analytics!['sem'] ?? 0.0;
      final mdc = _analytics!['mdc'] ?? 0.0;
      
      // Temporal dynamics verilerini al
      final temporalData = _analytics!['temporal_dynamics'] as Map<String, dynamic>? ?? {};
      final volatilityIndex = temporalData['volatility_index'] ?? 0.0;
      final trendPersistence = temporalData['trend_persistence'] ?? 0.0;
      final detectedCycles = temporalData['detected_cycles'] ?? 0;

      final summary = '''
🔬 izForce Analitik Özet

🏃‍♀️ Sporcu: $athleteName
📈 Test Sayısı: $testCount

🔍 Temel Analitikler:
• Güvenilirlik: ${reliability.toStringAsFixed(1)}%
• Varyasyon Katsayısı: ${cv.toStringAsFixed(1)}%
• ICC: ${icc.toStringAsFixed(3)}
• SEM: ${sem.toStringAsFixed(2)}
• MDC: ${mdc.toStringAsFixed(2)}

🕰️ Zamansal Dinamikler:
• Volatilite İndeksi: ${volatilityIndex.toStringAsFixed(1)}%
• Trend Kalıcılığı: ${trendPersistence.toStringAsFixed(2)}
• Tespit Edilen Döngüler: $detectedCycles

📅 Analiz Tarihi: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
📱 izForce Research-Grade Analytics''';

      await FileShareService.shareTextSummary(
        text: summary,
        subject: 'izForce Analitik Özet - $athleteName',
      );

      _showSuccessSnackBar('Analitik özet paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Analitik özet paylaşım hatası', e, stackTrace);
      _showErrorSnackBar('Paylaşım başarısız: ${e.toString()}');
    }
  }

}