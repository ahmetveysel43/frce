import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

import '../../data/models/athlete_model.dart';
import '../../data/models/test_result_model.dart';
import '../../core/services/pdf_report_service.dart';
import '../../core/services/file_share_service.dart';
import '../../core/services/advanced_comparison_service.dart';
import '../../core/services/unified_data_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/common_ui_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/metric_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/analysis_filter_widget.dart';
import '../widgets/advanced_charts_widget.dart';

/// Modern ve gelişmiş test karşılaştırma ekranı
/// Nike Training Club, MyLift, Hawkin Dynamics'den ilham alınmıştır
class AdvancedTestComparisonScreen extends StatefulWidget {
  final String? athleteId;
  final String? testType;

  const AdvancedTestComparisonScreen({
    super.key,
    this.athleteId,
    this.testType,
  });

  @override
  State<AdvancedTestComparisonScreen> createState() => _AdvancedTestComparisonScreenState();
}

class _AdvancedTestComparisonScreenState extends State<AdvancedTestComparisonScreen>
    with TickerProviderStateMixin {
  static const String _tag = 'AdvancedTestComparisonScreen';
  
  final UnifiedDataService _dataService = UnifiedDataService();
  final List<TestResultModel> _allTestResults = [];
  final List<TestResultModel> _filteredResults = [];
  TestResultModel? _selectedTest1;
  TestResultModel? _selectedTest2;
  bool _isLoading = true;
  final bool _isDataReloading = false;

  
  // Filter states
  AthleteModel? _selectedAthlete;
  TestType? _selectedTestType;
  DateTimeRange? _selectedDateRange;
  String _comparisonMode = 'latest'; // latest, best, baseline, custom
  final String _selectedMetric = 'Tüm Metrikler';
  
  // Available data
  final List<AthleteModel> _availableAthletes = [];
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late TabController _tabController;

  // PDF service
  bool _isGeneratingPDF = false;

  // Radar chart data
  List<RadarDataPoint> _radarData = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _tabController = TabController(length: 5, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);

      // Data service is ready to use

      // Load all athletes using unified service
      _availableAthletes.clear();
      _availableAthletes.addAll(await _dataService.getAllAthletes());

      // Set initial filters
      if (widget.athleteId != null) {
        _selectedAthlete = _availableAthletes.isNotEmpty 
          ? _availableAthletes.firstWhere(
              (a) => a.id == widget.athleteId,
              orElse: () => _availableAthletes.first,
            )
          : null;
      } else if (_availableAthletes.isNotEmpty) {
        _selectedAthlete = _availableAthletes.first;
      }

      if (widget.testType != null) {
        // Find test type from available test types
        _selectedTestType = TestType.values.firstWhere(
          (t) => t.code.toUpperCase() == widget.testType!.toUpperCase(),
          orElse: () => TestType.counterMovementJump,
        );
      }

      // Load all test results using unified service
      if (_availableAthletes.isNotEmpty) {
        AppLogger.info('$_tag: Loading test results for ${_availableAthletes.length} athletes');
        await _loadAllTestResults();
        AppLogger.info('$_tag: Loaded ${_allTestResults.length} total test results');
        _applyFilters();
        AppLogger.info('$_tag: Applied filters, ${_filteredResults.length} results remain');
        _autoSelectTests();
        AppLogger.info('$_tag: Auto-selected tests: ${_selectedTest1?.id} vs ${_selectedTest2?.id}');
      }

      _fadeController.forward();
      _slideController.forward();

      AppLogger.info('$_tag: Loaded ${_allTestResults.length} total test results');
    } catch (e, stackTrace) {
      AppLogger.error('Error loading initial data', e, stackTrace);
      if (mounted) {
        CommonUIUtils.showErrorSnackBar(context, 'Veri yükleme hatası',
          error: e is Exception ? e : Exception(e.toString()), 
          stackTrace: stackTrace);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllTestResults() async {
    try {
      _allTestResults.clear();
      
      // OPTIMIZED: If specific athlete selected, load only their data
      if (_selectedAthlete != null) {
        AppLogger.info('$_tag: Loading test results for selected athlete ${_selectedAthlete!.fullName} (${_selectedAthlete!.id})');
        final testResults = await _dataService.getAthleteTestResults(_selectedAthlete!.id);
        AppLogger.info('$_tag: Found ${testResults.length} test results for ${_selectedAthlete!.fullName}');
        _allTestResults.addAll(testResults);
      } else {
        // Load test results for all athletes if no specific selection
        for (final athlete in _availableAthletes) {
          AppLogger.info('$_tag: Loading test results for athlete ${athlete.fullName} (${athlete.id})');
          final testResults = await _dataService.getAthleteTestResults(athlete.id);
          AppLogger.info('$_tag: Found ${testResults.length} test results for ${athlete.fullName}');
          _allTestResults.addAll(testResults);
        }
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


  void _applyFilters() {
    _filteredResults.clear();
    
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
      
      _filteredResults.add(result);
    }
    
    setState(() {});
  }

  void _autoSelectTests() {
    if (_filteredResults.isEmpty) return;
    
    switch (_comparisonMode) {
      case 'latest':
        _selectedTest2 = _filteredResults.first; // Most recent
        if (_filteredResults.length > 1) {
          _selectedTest1 = _filteredResults[1]; // Second most recent
        }
        break;
      case 'best':
        _selectedTest2 = _findBestPerformance();
        _selectedTest1 = _filteredResults.first;
        break;
      case 'baseline':
        // Find oldest test as baseline
        final sortedByDate = List<TestResultModel>.from(_filteredResults)
          ..sort((a, b) => a.testDate.compareTo(b.testDate));
        _selectedTest1 = sortedByDate.first;
        _selectedTest2 = _filteredResults.first;
        break;
      default:
        _selectedTest2 = _filteredResults.first;
        if (_filteredResults.length > 1) {
          _selectedTest1 = _filteredResults[1];
        }
    }
    
    _generateRadarData();
  }

  TestResultModel? _findBestPerformance() {
    if (_filteredResults.isEmpty) return null;
    
    return _filteredResults.reduce((a, b) {
      final aScore = _getPrimaryMetricValue(a);
      final bScore = _getPrimaryMetricValue(b);
      return aScore > bScore ? a : b;
    });
  }

  double _getPrimaryMetricValue(TestResultModel test) {
    switch (_selectedTestType?.category) {
      case TestCategory.jump:
        return test.metrics['jumpHeight'] ?? test.metrics['flightTime'] ?? 0.0;
      case TestCategory.strength:
        return test.metrics['peakForce'] ?? test.metrics['rfd'] ?? 0.0;
      case TestCategory.balance:
        return 100 - (test.metrics['stabilityIndex'] ?? 100.0);
      case TestCategory.agility:
        return test.metrics['hopDistance'] ?? test.metrics['movementEfficiency'] ?? 0.0;
      default:
        return test.qualityScore ?? 0.0;
    }
  }

  void _generateRadarData() {
    if (_selectedTest1 == null || _selectedTest2 == null) return;
    
    _radarData = [];
    final metrics = _getFilteredMetrics();
    
    for (final metric in metrics) {
      final value1 = _selectedTest1!.metrics[metric['key']] ?? 0.0;
      final value2 = _selectedTest2!.metrics[metric['key']] ?? 0.0;
      
      // Skip if both values are zero
      if (value1 == 0.0 && value2 == 0.0) continue;
      
      // Normalize values to 0-100 scale
      final maxValue = math.max(value1, value2) * 1.2;
      final normalizedValue1 = maxValue > 0 ? (value1 / maxValue) * 100 : 0.0;
      final normalizedValue2 = maxValue > 0 ? (value2 / maxValue) * 100 : 0.0;
      
      _radarData.add(RadarDataPoint(
        metric['name'] ?? '',
        normalizedValue1,
        normalizedValue2,
      ));
    }
  }

  List<Map<String, String>> _getComparableMetrics() {
    if (_selectedTestType?.code != null) {
      final metrics = MetricConstants.getMetricsForTestType(_selectedTestType!.code);
      return metrics.map((m) => {
        'key': m.key,
        'name': m.displayName,
      }).toList();
    }
    
    // Fallback to default metrics
    return [
      {'key': 'peakForce', 'name': 'Pik Kuvvet'},
      {'key': 'averageForce', 'name': 'Ort. Kuvvet'},
    ];
  }
  
  List<Map<String, String>> _getFilteredMetrics() {
    // Metrik filtresi var mı kontrol et
    final selectedMetric = _selectedMetric;
    
    // Eğer belirli bir metrik seçilmişse, sadece o metrik için radar yapma
    // Bunun yerine tek metrik görselleştirme yap
    if (selectedMetric != 'Tüm Metrikler' && selectedMetric != 'All Metrics') {
      // Tek metrik için radar uygun değil, bu durumda tüm metrikleri göster
      return _getComparableMetrics();
    }
    
    // Tüm metrikler seçilmişse veya metrik seçimi yoksa, tüm metrikleri göster
    return _getComparableMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _isLoading
          ? _buildLoadingScreen()
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      children: [
                        AnalysisFilterWidget(
                          athletes: _availableAthletes,
                          selectedAthleteId: _selectedAthlete?.id,
                          selectedTestType: _selectedTestType?.code ?? 'Tümü',
                          selectedDateRange: _selectedDateRange,
                          selectedMetric: 'Tüm Metrikler',
                          resultCount: _filteredResults.length,
                          onAthleteChanged: (value) {
                            if (value != null && !_isDataReloading) {
                              setState(() {
                                _selectedAthlete = _availableAthletes.firstWhere((a) => a.id == value);
                              });
                              // OPTIMIZED: Just apply filters, no data reload needed
                              _applyFilters();
                              _autoSelectTests();
                            }
                          },
                          onTestTypeChanged: (value) {
                            setState(() {
                              _selectedTestType = value == 'All' 
                                  ? null 
                                  : TestType.values.firstWhere(
                                      (t) => t.code == value,
                                      orElse: () => TestType.counterMovementJump,
                                    );
                            });
                            _applyFilters();
                            _autoSelectTests();
                          },
                          onDateRangeChanged: (dateRange) {
                            setState(() {
                              _selectedDateRange = dateRange;
                            });
                            _applyFilters();
                            _autoSelectTests();
                          },
                          onMetricChanged: (metric) {
                            // Metrik değişimini handle et
                          },
                          onRefresh: _loadInitialData,
                          isExpanded: false,
                          isDarkTheme: true,
                        ),
                        _buildComparisonModeSelector(),
                        if (_filteredResults.length < 2)
                          _buildInsufficientTestsMessage()
                        else
                          _buildMainContent(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _selectedTest1 != null && _selectedTest2 != null
          ? _buildFloatingActions()
          : null,
    );
  }

  Widget _buildLoadingScreen() {
    return CommonUIUtils.buildLoadingWidget(message: 'Test verileri yükleniyor...');
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A1A),
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Karşılaştırması',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_selectedAthlete != null)
              Text(
                _selectedAthlete!.fullName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF2D2D2D),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 20,
                top: 60,
                child: Icon(
                  _getTestTypeIcon(),
                  size: 60,
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadInitialData,
        ),
      ],
    );
  }

  IconData _getTestTypeIcon() {
    switch (_selectedTestType?.category) {
      case TestCategory.jump:
        return Icons.trending_up;
      case TestCategory.strength:
        return Icons.fitness_center;
      case TestCategory.balance:
        return Icons.balance;
      case TestCategory.agility:
        return Icons.directions_run;
      default:
        return Icons.analytics;
    }
  }

  Widget _buildComparisonModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildModeChip('latest', 'Son Testler', Icons.schedule),
          const SizedBox(width: 8),
          _buildModeChip('best', 'En İyi', Icons.star),
          const SizedBox(width: 8),
          _buildModeChip('baseline', 'Başlangıç', Icons.timeline),
        ],
      ),
    );
  }

  Widget _buildModeChip(String mode, String label, IconData icon) {
    final isSelected = _comparisonMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _comparisonMode = mode);
          _autoSelectTests();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsufficientTestsMessage() {
    return CommonUIUtils.buildNoDataWidget(
      icon: Icons.compare_arrows,
      title: 'Karşılaştırma için en az 2 test gerekli',
      subtitle: 'Filtreleri değiştirerek daha fazla test bulabilirsiniz',
      action: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _selectedTestType = null;
            _selectedDateRange = null;
          });
          _applyFilters();
        },
        icon: const Icon(Icons.clear_all),
        label: const Text('Filtreleri Temizle'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildTestSelectionCards(),
        const SizedBox(height: 24),
        _buildTabView(),
        const SizedBox(height: 100), // Space for floating action button
      ],
    );
  }

  Widget _buildTestSelectionCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTestCard(
              'Test 1 (Eski)',
              _selectedTest1,
              Colors.blue,
              (test) => setState(() => _selectedTest1 = test),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.compare_arrows,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _calculateDaysBetween(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTestCard(
              'Test 2 (Yeni)',
              _selectedTest2,
              Colors.green,
              (test) => setState(() => _selectedTest2 = test),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDaysBetween() {
    if (_selectedTest1 == null || _selectedTest2 == null) return '';
    
    final diff = _selectedTest2!.testDate.difference(_selectedTest1!.testDate).inDays;
    return '$diff gün';
  }

  Widget _buildTestCard(
    String title,
    TestResultModel? test,
    Color color,
    Function(TestResultModel?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (test != null) ...[
            Text(
              '${test.testDate.day}/${test.testDate.month}/${test.testDate.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              test.testType,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getQualityColor(test.qualityScore ?? 0).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Kalite: ${(test.qualityScore ?? 0).toInt()}%',
                style: TextStyle(
                  color: _getQualityColor(test.qualityScore ?? 0),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Text(
                  'Test Seçin',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButton<TestResultModel>(
            value: test,
            isExpanded: true,
            underline: Container(),
            hint: const Text(
              'Test seçin',
              style: TextStyle(color: Colors.white54),
            ),
            dropdownColor: const Color(0xFF2D2D2D),
            items: _filteredResults.map((testResult) {
              final athlete = _getAthleteById(testResult.athleteId);
              return DropdownMenuItem<TestResultModel>(
                value: testResult,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${testResult.testDate.day}/${testResult.testDate.month}/${testResult.testDate.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: _getQualityColor(testResult.qualityScore ?? 0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '${(testResult.qualityScore ?? 0).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${athlete.fullName} - ${testResult.testType}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${_getPrimaryMetricValue(testResult).toStringAsFixed(1)} ${_getPrimaryMetricUnit()}',
                            style: const TextStyle(
                              color: Colors.cyan,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (test) {
              onChanged(test);
              _generateRadarData();
            },
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(double score) {
    return CommonUIUtils.getQualityColor(score);
  }

  AthleteModel _getAthleteById(String athleteId) {
    return _availableAthletes.firstWhere(
      (athlete) => athlete.id == athleteId,
      orElse: () => AthleteModel(
        id: athleteId,
        firstName: 'Bilinmeyen',
        lastName: 'Sporcu',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Widget _buildTabView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamically calculate height based on available space
        final screenHeight = MediaQuery.of(context).size.height;
        final availableHeight = screenHeight - 300; // Account for app bar and other elements
        final tabViewHeight = availableHeight.clamp(600.0, 900.0);
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: tabViewHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.white54,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Özet'),
                  Tab(text: 'Radar'),
                  Tab(text: 'Trend'),
                  Tab(text: 'Detay'),
                  Tab(text: 'Analiz'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildRadarTab(),
                    _buildTrendTab(),
                    _buildDetailTab(),
                    _buildAnalysisTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    if (_selectedTest1 == null || _selectedTest2 == null) {
      return const Center(
        child: Text(
          'Karşılaştırma için 2 test seçin',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final comparisonData = _prepareComparisonData();
    final overallImprovement = _calculateOverallImprovement(comparisonData);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall performance card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  overallImprovement > 0 ? Colors.green : Colors.orange,
                  (overallImprovement > 0 ? Colors.green : Colors.orange).withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  overallImprovement > 0 ? Icons.trending_up : Icons.trending_down,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  '${overallImprovement > 0 ? '+' : ''}${overallImprovement.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  overallImprovement > 0 ? 'Gelişim' : 'Düşüş',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Key metrics
          const Text(
            'Ana Metrikler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: math.min(comparisonData.length, 4),
              itemBuilder: (context, index) {
                final data = comparisonData[index];
                return _buildMetricSummaryCard(data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSummaryCard(Map<String, dynamic> data) {
    final improvement = data['improvement'] as bool;
    final percentChange = data['percentChange'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: improvement ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              improvement ? Icons.trending_up : Icons.trending_down,
              color: improvement ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['metric'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${data['test1Value'].toStringAsFixed(1)} → ${data['test2Value'].toStringAsFixed(1)} ${data['unit']}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${percentChange > 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
            style: TextStyle(
              color: improvement ? Colors.green : Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarTab() {
    if (_selectedTest1 == null || _selectedTest2 == null) {
      return const Center(
        child: Text(
          'Radar analizi için 2 test seçin',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // Belirli bir metrik seçilmişse, bar chart göster
    if (_selectedMetric != 'Tüm Metrikler' && _selectedMetric != 'All Metrics') {
      return _buildSingleMetricComparison();
    }

    // Tüm metrikler için radar chart
    if (_radarData.isEmpty) {
      return const Center(
        child: Text(
          'Radar chart verisi yok',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Performans Radar (Tüm Metrikler)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_radarData.length} metrik',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildRadarChart(),
          ),
          const SizedBox(height: 24),
          _buildRadarLegend(),
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
    // Bu gerçek bir radar chart implementasyonu olacak
    // fl_chart paketinin radar chart özelliği kullanılacak veya custom çizim yapılacak
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: RadarChartPainter(_radarData),
        size: const Size(300, 300),
      ),
    );
  }

  Widget _buildRadarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Test 1', Colors.blue),
        _buildLegendItem('Test 2', Colors.green),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
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
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendTab() {
    if (_selectedTest1 == null || _selectedTest2 == null) {
      return const Center(
        child: Text(
          'Trend analizi için 2 test seçin',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // Create a list of tests in chronological order for trend analysis
    final allTests = [_selectedTest1!, _selectedTest2!]
      ..sort((a, b) => a.testDate.compareTo(b.testDate));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performans Trend Analizi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Line chart showing progression
          SizedBox(
            height: 550,
            child: AdvancedChartsWidget(
              testResults: allTests,
              chartType: 'line',
              height: 550,
              primaryColor: AppTheme.primaryColor,
              showGrid: true,
              enableInteraction: true,
              showLegend: false,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Performance metrics comparison bar chart
          SizedBox(
            height: 400,
            child: AdvancedChartsWidget(
              testResults: allTests,
              chartType: 'bar',
              height: 400,
              primaryColor: Colors.green,
              showGrid: true,
              enableInteraction: true,
              showLegend: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTab() {
    if (_selectedTest1 == null || _selectedTest2 == null) {
      return const Center(
        child: Text(
          'Detay için 2 test seçin',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final comparisonData = _prepareComparisonData();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Table(
          border: TableBorder.all(color: Colors.grey.withValues(alpha: 0.3)),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: AppTheme.primaryColor),
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Metrik', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Test 1', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Test 2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Değişim', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                ),
              ],
            ),
            ...comparisonData.map((data) {
              final improvement = data['improvement'] as bool;
              final percentChange = data['percentChange'] as double;
              
              return TableRow(
                decoration: const BoxDecoration(color: Color(0xFF2D2D2D)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(data['metric'], style: const TextStyle(color: Colors.white)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${data['test1Value'].toStringAsFixed(2)} ${data['unit']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${data['test2Value'].toStringAsFixed(2)} ${data['unit']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          improvement ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: improvement ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${percentChange > 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: improvement ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    if (_selectedTest1 == null || _selectedTest2 == null) {
      return const Center(
        child: Text(
          'Analiz için 2 test seçin',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final allTests = [_selectedTest1!, _selectedTest2!];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gelişmiş Performans Analizi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Radar chart for comprehensive performance profile
          SizedBox(
            height: 550,
            child: AdvancedChartsWidget(
              testResults: allTests,
              chartType: 'radar',
              height: 550,
              primaryColor: AppTheme.primaryColor,
              showLegend: false,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Force-velocity profile if available
          if (_selectedTest1!.metrics.containsKey('peakForce') && 
              _selectedTest1!.metrics.containsKey('peakVelocity'))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kuvvet-Hız Profili',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 400,
                  child: AdvancedChartsWidget(
                    testResults: allTests,
                    chartType: 'scatter',
                    height: 400,
                    primaryColor: Colors.orange,
                    enableInteraction: true,
                    showLegend: false,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'pdf',
          onPressed: _isGeneratingPDF ? null : _generateComparisonReportPDF,
          backgroundColor: AppTheme.primaryColor,
          child: _isGeneratingPDF
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.picture_as_pdf, color: Colors.white),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'share',
          onPressed: () => _shareComparisonSummary(),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.share, color: Colors.white),
        ),
      ],
    );
  }

  // Helper methods
  List<Map<String, dynamic>> _prepareComparisonData() {
    if (_selectedTest1 == null || _selectedTest2 == null) return [];
    
    final comparisons = <Map<String, dynamic>>[];
    final metrics = _getComparableMetrics();
    
    for (final metric in metrics) {
      final value1 = _selectedTest1!.metrics[metric['key']] ?? 0.0;
      final value2 = _selectedTest2!.metrics[metric['key']] ?? 0.0;
      
      if (value1 > 0 && value2 > 0) {
        final difference = value2 - value1;
        final percentChange = (difference / value1) * 100;
        final improvement = _isImprovementForMetric(metric['key']!, difference);
        
        comparisons.add({
          'metric': metric['name'],
          'unit': MetricConstants.getMetricUnit(metric['key']!),
          'test1Value': value1,
          'test2Value': value2,
          'difference': difference,
          'percentChange': percentChange,
          'improvement': improvement,
        });
      }
    }
    
    return comparisons;
  }

  bool _isImprovementForMetric(String metricKey, double difference) {
    final higherIsBetter = MetricConstants.isImprovementWhenIncreased(metricKey);
    
    if (higherIsBetter) {
      return difference > 0; // Improvement if increase
    } else {
      return difference < 0; // Improvement if decrease
    }
  }

  double _calculateOverallImprovement(List<Map<String, dynamic>> comparisonData) {
    if (comparisonData.isEmpty) return 0.0;
    
    final improvements = comparisonData
        .where((data) => data['improvement'] as bool)
        .map((data) => (data['percentChange'] as double).abs())
        .toList();
    
    final deteriorations = comparisonData
        .where((data) => !(data['improvement'] as bool))
        .map((data) => (data['percentChange'] as double).abs())
        .toList();
    
    final avgImprovement = improvements.isNotEmpty 
        ? improvements.reduce((a, b) => a + b) / improvements.length 
        : 0.0;
    
    final avgDeterioration = deteriorations.isNotEmpty 
        ? deteriorations.reduce((a, b) => a + b) / deteriorations.length 
        : 0.0;
    
    return avgImprovement - avgDeterioration;
  }



  Future<void> _generateComparisonReportPDF() async {
    if (_isGeneratingPDF || _selectedTest1 == null || _selectedTest2 == null) return;
    
    setState(() => _isGeneratingPDF = true);
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          backgroundColor: Color(0xFF2D2D2D),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              SizedBox(width: 16),
              Text(
                'Gelişmiş rapor oluşturuluyor...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
      
      // Create comprehensive comparison using advanced service
      AppLogger.info('$_tag: Performing comprehensive comparison between tests ${_selectedTest1!.id} and ${_selectedTest2!.id}');
      final comparisonResult = await AdvancedComparisonService.performComprehensiveComparison(
        test1: _selectedTest1!,
        test2: _selectedTest2!,
        athlete: _getAthleteById(_selectedTest1!.athleteId),
      );
      AppLogger.info('$_tag: Comparison completed with ${comparisonResult.metrics.length} metrics analyzed');
      
      // Generate advanced PDF report with radar charts and trend analysis
      final pdfBytes = await PDFReportService.generateAdvancedTestComparisonReport(
        athlete: _getAthleteById(_selectedTest1!.athleteId),
        comparison: comparisonResult,
      );
      
      // Save report
      final athleteName = _getAthleteById(_selectedTest1!.athleteId).fullName.replaceAll(' ', '_');
      final fileName = 'advanced_comparison_${athleteName}_${_selectedTest1!.testType}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // PDF'i paylaş
      await FileShareService.sharePDFBytes(
        pdfBytes: pdfBytes,
        fileName: fileName,
        subject: 'izForce Gelişmiş Test Karşılaştırması',
        text: 'Detaylı test karşılaştırma analizi. ${_getAthleteById(_selectedTest1!.athleteId).fullName} için oluşturulmuştur.',
      );
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Success message
      if (mounted) {
        CommonUIUtils.showSuccessSnackBar(context, 'Gelişmiş karşılaştırma raporu başarıyla paylaşıldı!');
      }
      
    } catch (e) {
      // Close loading dialog on error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        CommonUIUtils.showErrorSnackBar(context, 'PDF oluşturulurken hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPDF = false);
      }
    }
  }

  /// Karşılaştırma özetini metin olarak paylaş
  Future<void> _shareComparisonSummary() async {
    if (_selectedTest1 == null || _selectedTest2 == null) return;

    try {
      final athlete = _getAthleteById(_selectedTest1!.athleteId);
      final test1Date = DateFormat('dd.MM.yyyy').format(_selectedTest1!.testDate);
      final test2Date = DateFormat('dd.MM.yyyy').format(_selectedTest2!.testDate);
      
      // Ana metriklerin karşılaştırması
      final jumpHeight1 = _selectedTest1!.metrics['jumpHeight'] ?? 0.0;
      final jumpHeight2 = _selectedTest2!.metrics['jumpHeight'] ?? 0.0;
      final jumpHeightChange = jumpHeight2 - jumpHeight1;
      final jumpHeightPercent = jumpHeight1 != 0 ? (jumpHeightChange / jumpHeight1 * 100) : 0.0;
      
      final peakForce1 = _selectedTest1!.metrics['peakForce'] ?? 0.0;
      final peakForce2 = _selectedTest2!.metrics['peakForce'] ?? 0.0;
      final peakForceChange = peakForce2 - peakForce1;
      final peakForcePercent = peakForce1 != 0 ? (peakForceChange / peakForce1 * 100) : 0.0;
      
      final summaryText = '''
🏃‍♂️ izForce Test Karşılaştırması

👤 Sporcu: ${athlete.fullName}
📅 Test 1: $test1Date
📅 Test 2: $test2Date
🧪 Test Türü: ${_selectedTest1!.testType}

📊 PERFORMANS KARŞILAŞTIRMASI:

🦵 Sıçrama Yüksekliği:
   Test 1: ${jumpHeight1.toStringAsFixed(1)} cm
   Test 2: ${jumpHeight2.toStringAsFixed(1)} cm
   Değişim: ${jumpHeightChange > 0 ? '+' : ''}${jumpHeightChange.toStringAsFixed(1)} cm (${jumpHeightPercent > 0 ? '+' : ''}${jumpHeightPercent.toStringAsFixed(1)}%)

💪 Tepe Kuvvet:
   Test 1: ${peakForce1.toStringAsFixed(0)} N
   Test 2: ${peakForce2.toStringAsFixed(0)} N
   Değişim: ${peakForceChange > 0 ? '+' : ''}${peakForceChange.toStringAsFixed(0)} N (${peakForcePercent > 0 ? '+' : ''}${peakForcePercent.toStringAsFixed(1)}%)

📈 Genel Trend: ${jumpHeightChange > 0 ? 'İyileşme' : jumpHeightChange < 0 ? 'Düşüş' : 'Sabit'}

🔬 Bu analiz izForce uygulaması ile oluşturulmuştur.
Detaylı rapor için PDF indir seçeneğini kullanın.
''';

      await FileShareService.shareText(
        text: summaryText,
        subject: 'izForce Test Karşılaştırması - ${athlete.fullName}',
      );

    } catch (e) {
      AppLogger.error('Karşılaştırma özeti paylaşma hatası', e);
      if (mounted) {
        CommonUIUtils.showErrorSnackBar(context, 'Özet paylaşılamadı: $e');
      }
    }
  }
  
  String _getPrimaryMetricUnit() {
    switch (_selectedTestType?.category) {
      case TestCategory.jump:
        return 'cm'; // jumpHeight için
      case TestCategory.strength:
        return 'N'; // peakForce için
      case TestCategory.balance:
        return 'puan'; // stabilityIndex için
      case TestCategory.agility:
        return 'cm'; // hopDistance için
      default:
        return '';
    }
  }
  
  Widget _buildSingleMetricComparison() {
    final metricKey = _getMetricKeyFromDisplayName(_selectedMetric);
    final value1 = _selectedTest1!.metrics[metricKey] ?? 0.0;
    final value2 = _selectedTest2!.metrics[metricKey] ?? 0.0;
    final change = value2 - value1;
    final percentChange = value1 != 0 ? (change / value1 * 100) : 0.0;
    final isImprovement = change > 0;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Metrik Karşılaştırması: $_selectedMetric',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          
          // Büyük bar chart gösterimi
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMetricBar(
                  'Test 1',
                  '${_selectedTest1!.testDate.day}/${_selectedTest1!.testDate.month}/${_selectedTest1!.testDate.year}',
                  value1,
                  Colors.blue,
                  math.max(value1, value2),
                ),
                _buildMetricBar(
                  'Test 2',
                  '${_selectedTest2!.testDate.day}/${_selectedTest2!.testDate.month}/${_selectedTest2!.testDate.year}',
                  value2,
                  Colors.green,
                  math.max(value1, value2),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Değişim bilgisi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isImprovement ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isImprovement ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Değişim',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${change > 0 ? '+' : ''}${change.toStringAsFixed(2)} ${_getMetricUnit(metricKey)}',
                      style: TextStyle(
                        color: isImprovement ? Colors.green : Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Yüzde Değişim',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isImprovement ? Icons.trending_up : Icons.trending_down,
                          color: isImprovement ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${percentChange > 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isImprovement ? Colors.green : Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricBar(String title, String date, double value, Color color, double maxValue) {
    final height = maxValue > 0 ? (value / maxValue * 200).clamp(20.0, 200.0) : 20.0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          date,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  String _getMetricKeyFromDisplayName(String displayName) {
    // AnalysisFilterWidget'taki mapping'i kullan
    const Map<String, String> displayToKey = {
      'Sıçrama Yüksekliği (cm)': 'jumpHeight',
      'Tepe Kuvvet (N)': 'peakForce',
      'Tepe Güç (W)': 'peakPower',
      'Kuvvet Gelişim Hızı (N/s)': 'rfd',
      'Uçuş Süresi (ms)': 'flightTime',
      'Temas Süresi (ms)': 'contactTime',
      'Kalkış Hızı (m/s)': 'takeoffVelocity',
      'Asimetri İndeksi (%)': 'asymmetryIndex',
      'Reaktif Güç İndeksi': 'reactiveStrengthIndex',
      'Stabilite İndeksi': 'stabilityIndex',
      'COP Mesafesi (mm)': 'copRange',
      'COP Hızı (mm/s)': 'copVelocity',
      'COP Alanı (mm²)': 'copArea',
      'Hop Mesafesi (cm)': 'hopDistance',
    };
    
    return displayToKey[displayName] ?? displayName.toLowerCase().replaceAll(' ', '_');
  }
  
  String _getMetricUnit(String metricKey) {
    const Map<String, String> units = {
      'jumpHeight': 'cm',
      'peakForce': 'N',
      'peakPower': 'W',
      'rfd': 'N/s',
      'flightTime': 'ms',
      'contactTime': 'ms',
      'takeoffVelocity': 'm/s',
      'asymmetryIndex': '%',
      'reactiveStrengthIndex': '',
      'stabilityIndex': 'score',
      'copRange': 'mm',
      'copVelocity': 'mm/s',
      'copArea': 'mm²',
      'hopDistance': 'cm',
    };
    
    return units[metricKey] ?? '';
  }
}

/// Radar chart data point
class RadarDataPoint {
  final String label;
  final double value1;
  final double value2;

  RadarDataPoint(this.label, this.value1, this.value2);
}

/// Custom radar chart painter
class RadarChartPainter extends CustomPainter {
  final List<RadarDataPoint> data;

  RadarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    
    // Paint grid
    _paintGrid(canvas, center, radius);
    
    // Paint data
    _paintData(canvas, center, radius);
    
    // Paint labels
    _paintLabels(canvas, center, radius);
  }

  void _paintGrid(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, paint);
    }

    // Draw radial lines
    for (int i = 0; i < data.length; i++) {
      final angle = (i * 2 * math.pi / data.length) - math.pi / 2;
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, endPoint, paint);
    }
  }

  void _paintData(Canvas canvas, Offset center, double radius) {
    if (data.isEmpty) return;

    // Test 1 (blue)
    final path1 = Path();
    final paint1 = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Test 2 (green)
    final path2 = Path();
    final paint2 = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final angle = (i * 2 * math.pi / data.length) - math.pi / 2;
      
      // Test 1 point
      final r1 = radius * (data[i].value1 / 100);
      final point1 = Offset(
        center.dx + r1 * math.cos(angle),
        center.dy + r1 * math.sin(angle),
      );
      
      // Test 2 point
      final r2 = radius * (data[i].value2 / 100);
      final point2 = Offset(
        center.dx + r2 * math.cos(angle),
        center.dy + r2 * math.sin(angle),
      );

      if (i == 0) {
        path1.moveTo(point1.dx, point1.dy);
        path2.moveTo(point2.dx, point2.dy);
      } else {
        path1.lineTo(point1.dx, point1.dy);
        path2.lineTo(point2.dx, point2.dy);
      }
    }

    path1.close();
    path2.close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);

    // Draw stroke
    final strokePaint1 = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final strokePaint2 = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path1, strokePaint1);
    canvas.drawPath(path2, strokePaint2);
  }

  void _paintLabels(Canvas canvas, Offset center, double radius) {
    for (int i = 0; i < data.length; i++) {
      final angle = (i * 2 * math.pi / data.length) - math.pi / 2;
      final labelRadius = radius + 20;
      final labelPosition = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelPosition.dx - textPainter.width / 2,
          labelPosition.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Extension for PDF service
extension PDFReportServiceExtension on PDFReportService {
  static Future<Uint8List> generateAdvancedTestComparisonReport({
    required AthleteModel athlete,
    required dynamic comparison,
  }) async {
    // This would implement advanced PDF generation with:
    // - Radar charts
    // - Trend analysis
    // - Professional layout
    // - Multiple chart types
    
    // For now, return a placeholder
    return Uint8List.fromList([]);
  }
}