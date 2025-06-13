import 'dart:async';
import '../../data/models/test_result_model.dart';
import '../../data/models/athlete_model.dart';
import '../database/database_helper.dart';
import '../utils/app_logger.dart';
import 'package:get/get.dart';
import '../../presentation/controllers/athlete_controller.dart';

/// Unified data service for consistent data access across all screens
class UnifiedDataService {
  static final UnifiedDataService _instance = UnifiedDataService._internal();
  factory UnifiedDataService() => _instance;
  UnifiedDataService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  
  // Cache için aktif taskları tut
  final Map<String, Future<List<TestResultModel>>> _activeResultTasks = {};
  
  // Cache timer'ları
  final Map<String, Timer> _cacheTimers = {};
  
  // Memory cache for frequently accessed data
  final Map<String, List<TestResultModel>> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache configuration
  static const Duration _memoryCacheDuration = Duration(minutes: 5);
  static const int _maxCacheSize = 50; // Maximum number of cached queries

  /// Get all athletes from unified source
  Future<List<AthleteModel>> getAllAthletes() async {
    try {
      final athleteController = Get.find<AthleteController>();
      return athleteController.athletes.map((athlete) => 
        AthleteModel.fromEntity(athlete)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error loading athletes', e, stackTrace);
      return [];
    }
  }

  /// Get athlete by ID
  Future<AthleteModel?> getAthleteById(String athleteId) async {
    try {
      if (athleteId.isEmpty) {
        throw ArgumentError('Athlete ID cannot be empty');
      }
      
      final athletes = await getAllAthletes();
      
      try {
        return athletes.firstWhere(
          (athlete) => athlete.id == athleteId,
        );
      } catch (e) {
        // Athlete not found
        AppLogger.warning('Athlete not found with ID: $athleteId');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading athlete by ID: $athleteId', e, stackTrace);
      return null;
    }
  }

  /// Get test results for an athlete (with concurrency protection and memory cache)
  Future<List<TestResultModel>> getAthleteTestResults(String athleteId, {
    String? testType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (athleteId.isEmpty) {
      throw ArgumentError('Athlete ID cannot be empty');
    }
    
    // Cache key oluştur
    final cacheKey = '${athleteId}_${testType ?? 'all'}_${startDate?.millisecondsSinceEpoch ?? 'null'}_${endDate?.millisecondsSinceEpoch ?? 'null'}';
    
    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey) && 
        _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      if (DateTime.now().difference(cacheTime) < _memoryCacheDuration) {
        AppLogger.debug('Using memory cache for: $cacheKey');
        return List.from(_memoryCache[cacheKey]!);
      } else {
        // Cache expired, remove it
        _memoryCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }
    
    // Eğer aktif task varsa bekle
    if (_activeResultTasks.containsKey(cacheKey)) {
      AppLogger.debug('Waiting for existing task: $cacheKey');
      try {
        return await _activeResultTasks[cacheKey]!;
      } catch (e) {
        // Remove failed task from cache
        _activeResultTasks.remove(cacheKey);
        _cacheTimers[cacheKey]?.cancel();
        _cacheTimers.remove(cacheKey);
        rethrow;
      }
    }
    
    // Yeni task başlat
    _activeResultTasks[cacheKey] = _fetchAthleteTestResults(athleteId, testType: testType, startDate: startDate, endDate: endDate);
    
    try {
      final results = await _activeResultTasks[cacheKey]!;
      
      // Store in memory cache
      _addToMemoryCache(cacheKey, results);
      
      // Cache 300 saniye (5 dakika) tut - daha aggressive caching
      _cacheTimers[cacheKey]?.cancel();
      _cacheTimers[cacheKey] = Timer(const Duration(seconds: 300), () {
        _activeResultTasks.remove(cacheKey);
        _cacheTimers.remove(cacheKey);
      });
      
      return results;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get athlete test results', e, stackTrace);
      _activeResultTasks.remove(cacheKey);
      _cacheTimers[cacheKey]?.cancel();
      _cacheTimers.remove(cacheKey);
      
      // Return empty list instead of rethrowing to prevent UI crashes
      return [];
    }
  }
  
  /// Actual fetch implementation
  Future<List<TestResultModel>> _fetchAthleteTestResults(String athleteId, {
    String? testType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (athleteId.isEmpty) {
        throw ArgumentError('Athlete ID cannot be empty');
      }
      
      final testHistory = await _databaseHelper.getAthleteTestHistory(
        athleteId,
        testType: testType,
        startDate: startDate,
        endDate: endDate,
      );
      final List<TestResultModel> results = [];

      for (final sessionData in testHistory) {
        try {
          final sessionId = sessionData['id'] as String?;
          if (sessionId == null || sessionId.isEmpty) {
            AppLogger.warning('Invalid session ID found in test history');
            continue;
          }
          
          final testResults = await _databaseHelper.getTestResults(sessionId);
          
          final testDateStr = sessionData['testDate'] as String?;
          if (testDateStr == null) {
            AppLogger.warning('Missing test date for session: $sessionId');
            continue;
          }
          
          DateTime testDate;
          try {
            testDate = DateTime.parse(testDateStr);
          } catch (e) {
            AppLogger.warning('Invalid test date format: $testDateStr');
            continue;
          }
          
          final sessionTestType = sessionData['testType'] as String? ?? 'unknown';

          // Apply filters
          if (testType != null && testType != 'Tümü' && sessionTestType != testType) {
            continue;
          }
          if (startDate != null && testDate.isBefore(startDate)) {
            continue;
          }
          if (endDate != null && testDate.isAfter(endDate)) {
            continue;
          }

          final testResult = TestResultModel(
            id: sessionId,
            sessionId: sessionId,
            athleteId: athleteId,
            testType: sessionTestType,
            testDate: testDate,
            durationMs: (sessionData['duration'] as int?) ?? 0,
            status: sessionData['status'] as String? ?? 'completed',
            createdAt: testDate,
            metrics: testResults,
            qualityScore: QualityScoreCalculator.calculateQualityScore(testResults, sessionTestType),
          );
          results.add(testResult);
        } catch (e, stackTrace) {
          AppLogger.error('Error processing session data', e, stackTrace);
          continue; // Skip this session and continue with others
        }
      }

      // Sort by date (newest first)
      results.sort((a, b) => b.testDate.compareTo(a.testDate));
      return results;
    } catch (e, stackTrace) {
      AppLogger.error('Error loading test results for athlete: $athleteId', e, stackTrace);
      return [];
    }
  }

  /// Get all test results with optional filters
  Future<List<TestResultModel>> getAllTestResults({
    String? athleteId,
    String? testType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final athletes = await getAllAthletes();
      final List<TestResultModel> allResults = [];

      for (final athlete in athletes) {
        if (athleteId != null && athlete.id != athleteId) {
          continue;
        }
        
        final results = await getAthleteTestResults(
          athlete.id,
          testType: testType,
          startDate: startDate,
          endDate: endDate,
        );
        allResults.addAll(results);
      }

      return allResults;
    } catch (e, stackTrace) {
      AppLogger.error('Error loading all test results', e, stackTrace);
      return [];
    }
  }

  /// Add results to memory cache with size management
  void _addToMemoryCache(String cacheKey, List<TestResultModel> results) {
    // Check cache size limit
    if (_memoryCache.length >= _maxCacheSize) {
      // Remove oldest cache entry
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _memoryCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
    
    _memoryCache[cacheKey] = List.from(results);
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    AppLogger.debug('Added to memory cache: $cacheKey (${results.length} results)');
  }

  /// Clear all caches
  void clearAllCaches() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _activeResultTasks.clear();
    
    // Cancel all timers
    for (final timer in _cacheTimers.values) {
      timer.cancel();
    }
    _cacheTimers.clear();
    
    AppLogger.info('All caches cleared');
  }
}

/// Unified quality score calculator
class QualityScoreCalculator {
  static double calculateQualityScore(Map<String, double> metrics, String testType) {
    if (metrics.isEmpty) return 0.0;
    
    double score = 75.0; // Base score

    try {
      // Check for key metrics presence and validity
      final jumpHeight = metrics['jumpHeight'];
      if (jumpHeight != null && jumpHeight > 0 && jumpHeight.isFinite) {
        score += 10;
        if (jumpHeight > 20) score += 5; // Good performance
        if (jumpHeight > 40) score += 5; // Excellent performance
      }
      
      final peakForce = metrics['peakForce'];
      if (peakForce != null && peakForce > 0 && peakForce.isFinite) {
        score += 8;
        if (peakForce > 1500) score += 4; // Good force production
        if (peakForce > 2500) score += 3; // Excellent force production
      }

      final asymmetry = metrics['asymmetryIndex'];
      if (asymmetry != null && asymmetry.isFinite) {
        if (asymmetry < 5) {
          score += 10;
        } else if (asymmetry >= 5 && asymmetry <= 10) {
          score += 5;
        } else if (asymmetry > 15) {
          score -= 15;
        } else if (asymmetry > 25) {
          score -= 25;
        }
      }
      
      final cv = metrics['forceCoefficientOfVariation'];
      if (cv != null && cv.isFinite && cv >= 0) {
        if (cv < 0.05) {
          score += 8; // Very low variability is excellent
        } else if (cv < 0.1) {
          score += 5; // Low variability is good
        } else if (cv > 0.3) {
          score -= 10; // High variability is poor
        }
      }

      // Test type specific adjustments
      switch (testType.toUpperCase()) {
        case 'CMJ':
        case 'SJ':
          final contactTime = metrics['contactTime'];
          if (contactTime != null && contactTime > 0 && contactTime.isFinite) {
            if (contactTime < 200) {
              score += 8; // Excellent contact time
            } else if (contactTime < 250) {
              score += 5; // Good contact time
            } else if (contactTime > 400) {
              score -= 5; // Slow contact time
            }
          }
          
          final rsi = metrics['reactiveStrengthIndex'];
          if (rsi != null && rsi > 0 && rsi.isFinite) {
            if (rsi > 2.0) score += 5;
            if (rsi > 3.0) score += 3;
          }
          break;
          
        case 'DJ':
          final rsi = metrics['reactiveStrengthIndex'];
          if (rsi != null && rsi > 0 && rsi.isFinite) {
            if (rsi > 1.5) score += 8;
            if (rsi > 2.5) score += 7;
          }
          break;
          
        case 'IMTP':
          final rfd = metrics['rfd'];
          if (rfd != null && rfd > 0 && rfd.isFinite) {
            score += 7; // RFD is important for IMTP
            if (rfd > 5000) score += 5; // Good RFD
          }
          
          final rfd100 = metrics['rfd0_100ms'];
          if (rfd100 != null && rfd100 > 0 && rfd100.isFinite) {
            score += 5; // Early RFD is crucial
          }
          break;
      }
      
      // Penalty for missing important metrics
      if (!metrics.containsKey('peakForce') || metrics['peakForce'] == null) {
        score -= 10;
      }
      if (!metrics.containsKey('asymmetryIndex') || metrics['asymmetryIndex'] == null) {
        score -= 5;
      }
      
    } catch (e) {
      AppLogger.error('Error calculating quality score', e);
      return 50.0; // Return middle score if calculation fails
    }
    
    return (score > 100) ? 100 : (score < 0) ? 0 : score;
  }
}