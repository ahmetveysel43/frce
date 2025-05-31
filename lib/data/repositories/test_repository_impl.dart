// lib/data/repositories/test_repository_impl.dart

import 'dart:math' as math; // math sınıfı kullanımı için eklendi
import 'package:flutter/material.dart'; // DateTimeRange için gerekli

import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/extensions/list_extensions.dart'; // groupBy metodu için eklendi
import '../../core/utils/app_logger.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/entities/force_data.dart';
import '../../domain/entities/test_result.dart';
import '../../domain/repositories/test_repository.dart';
import '../models/force_data_model.dart';
import '../models/test_result_model.dart';

/// Test domain repository'nin SQLite implementasyonu
class TestRepositoryImpl implements TestRepository {
  final DatabaseHelper _databaseHelper;

  TestRepositoryImpl({
    required DatabaseHelper databaseHelper,
  }) : _databaseHelper = databaseHelper;

  @override
  Future<String> saveTestResult(TestResult testResult) async {
    try {
      final testResultModel = TestResultModel.fromEntity(testResult);
      final sessionId = testResultModel.sessionId;

      // Test oturumunu kaydet
      await _databaseHelper.insertTestSession({
        'id': sessionId,
        'athleteId': testResultModel.athleteId,
        'testType': testResultModel.testType,
        'testDate': testResultModel.testDate.toIso8601String(),
        'duration': testResultModel.durationMs,
        'status': testResultModel.status,
        'notes': testResultModel.notes,
        'createdAt': testResultModel.createdAt.toIso8601String(),
      });

      // Test sonuçlarını (metrikleri) kaydet
      await _databaseHelper.insertTestResultsBatch(
        sessionId,
        testResultModel.metrics,
      );

      AppLogger.success('Test sonucu ve metrikler kaydedildi: $sessionId');
      return sessionId;
    } catch (e, stackTrace) {
      AppLogger.dbError('saveTestResult', e.toString());
      throw TestDatabaseException('Test sonucunu kaydederken hata: $e', originalError: e);
    }
  }

  @override
  Future<void> saveForceDataBatch(String sessionId, List<ForceData> forceDataList) async {
    try {
      final forceDataModels = forceDataList
          .map((data) => ForceDataModel.fromEntity(data, sessionId))
          .toList();

      // Batch insert için model listesini map listesine dönüştür
      final List<Map<String, dynamic>> dataToInsert = forceDataModels
          .map((model) => model.toMap())
          .toList();

      await _databaseHelper.insertForceDataBatch(sessionId, dataToInsert);
      AppLogger.info('Force data batch kaydedildi: $sessionId (${forceDataList.length} kayıt)');
    } catch (e, stackTrace) {
      AppLogger.dbError('saveForceDataBatch', e.toString());
      throw TestDatabaseException('Force data kaydederken hata: $e', originalError: e);
    }
  }

  @override
  Future<TestResult?> getTestResult(String sessionId) async {
    try {
      final sessionMaps = await (await _databaseHelper.database).query(
        'test_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      if (sessionMaps.isEmpty) {
        return null;
      }

      final metricsMap = await _databaseHelper.getTestResults(sessionId);
      final sessionData = sessionMaps.first;

      return TestResultModel.fromMap({
        ...sessionData,
        'metrics': metricsMap, // Metrikleri doğrudan ekle
      }).toEntity();
    } catch (e, stackTrace) {
      AppLogger.dbError('getTestResult', e.toString());
      throw TestDatabaseException('Test sonucunu getirirken hata: $e', originalError: e);
    }
  }

  @override
  Future<List<TestResult>> getAthleteTestHistory(String athleteId) async {
    try {
      final testSessions = await _databaseHelper.getAthleteTestHistory(athleteId);
      final List<TestResult> results = [];

      for (final sessionMap in testSessions) {
        final sessionId = sessionMap['id'] as String;
        final metricsMap = await _databaseHelper.getTestResults(sessionId);

        results.add(TestResultModel.fromMap({
          ...sessionMap,
          'metrics': metricsMap,
        }).toEntity());
      }
      return results;
    } catch (e, stackTrace) {
      AppLogger.dbError('getAthleteTestHistory', e.toString());
      throw TestDatabaseException('Sporcu test geçmişini getirirken hata: $e', originalError: e);
    }
  }

  @override
  Future<List<TestResult>> getTestResultsByType(TestType testType) async {
    try {
      final db = await _databaseHelper.database;
      final sessionMaps = await db.query(
        'test_sessions',
        where: 'testType = ?',
        whereArgs: [testType.name],
        orderBy: 'testDate DESC',
      );

      final List<TestResult> results = [];
      for (final sessionMap in sessionMaps) {
        final sessionId = sessionMap['id'] as String;
        final metricsMap = await _databaseHelper.getTestResults(sessionId);
        results.add(TestResultModel.fromMap({
          ...sessionMap,
          'metrics': metricsMap,
        }).toEntity());
      }
      return results;
    } catch (e, stackTrace) {
      AppLogger.dbError('getTestResultsByType', e.toString());
      throw TestDatabaseException('Test türüne göre sonuçları getirirken hata: $e', originalError: e);
    }
  }

  @override
  Future<List<TestResult>> getTestResultsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final db = await _databaseHelper.database;
      final sessionMaps = await db.query(
        'test_sessions',
        where: 'testDate BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'testDate DESC',
      );

      final List<TestResult> results = [];
      for (final sessionMap in sessionMaps) {
        final sessionId = sessionMap['id'] as String;
        final metricsMap = await _databaseHelper.getTestResults(sessionId);
        results.add(TestResultModel.fromMap({
          ...sessionMap,
          'metrics': metricsMap,
        }).toEntity());
      }
      return results;
    } catch (e, stackTrace) {
      AppLogger.dbError('getTestResultsByDateRange', e.toString());
      throw TestDatabaseException('Tarih aralığına göre sonuçları getirirken hata: $e', originalError: e);
    }
  }

  @override
  Future<List<ForceData>> getSessionForceData(String sessionId) async {
    try {
      final forceDataMaps = await _databaseHelper.getSessionForceData(sessionId);
      return forceDataMaps.map((map) => ForceData.fromMap(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.dbError('getSessionForceData', e.toString());
      throw TestDatabaseException('Force data getirirken hata: $e', originalError: e);
    }
  }

  @override
  Future<List<ForceData>> getSessionForceDataSampled(String sessionId, {int sampleRate = 100}) async {
    try {
      final allData = await getSessionForceData(sessionId);
      if (allData.isEmpty) {
        return [];
      }

      final originalSampleRate = allData.length * 1000.0 / (allData.last.timestamp - allData.first.timestamp);
      final samplingFactor = (originalSampleRate / sampleRate).round();

      return ForceDataCollection(allData).downsample(samplingFactor).data;
    } catch (e, stackTrace) {
      AppLogger.dbError('getSessionForceDataSampled', e.toString());
      throw TestDatabaseException('Örneklenmiş force data getirirken hata: $e', originalError: e);
    }
  }

  @override
  Future<void> updateTestResult(TestResult testResult) async {
    try {
      final testResultModel = TestResultModel.fromEntity(testResult);
      await _databaseHelper.updateTestSession(
        testResultModel.sessionId,
        testResultModel.toMap(),
      );
      // Metrikleri de güncellemeniz gerekebilir, burada basitçe silip yeniden ekliyoruz
      await (await _databaseHelper.database).delete(
        'test_results',
        where: 'sessionId = ?',
        whereArgs: [testResultModel.sessionId],
      );
      await _databaseHelper.insertTestResultsBatch(
        testResultModel.sessionId,
        testResultModel.metrics,
      );
      AppLogger.info('Test sonucu güncellendi: ${testResult.sessionId}');
    } catch (e, stackTrace) {
      AppLogger.dbError('updateTestResult', e.toString());
      throw TestDatabaseException('Test sonucunu güncellerken hata: $e', originalError: e);
    }
  }

  @override
  Future<void> deleteTestResult(String sessionId) async {
    try {
      // test_sessions tablosundan silmek, foreign key sayesinde ilgili diğer tabloları da siler
      await (await _databaseHelper.database).delete(
        'test_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      AppLogger.info('Test sonucu silindi: $sessionId');
    } catch (e, stackTrace) {
      AppLogger.dbError('deleteTestResult', e.toString());
      throw TestDatabaseException('Test sonucunu silerken hata: $e', originalError: e);
    }
  }

  @override
  Future<void> deleteTestSession(String sessionId) {
    return deleteTestResult(sessionId); // Aynı fonksiyonu çağırıyoruz
  }

  @override
  Future<List<TestResult>> getRecentTests({int limit = 10}) async {
    try {
      final db = await _databaseHelper.database;
      final sessionMaps = await db.query(
        'test_sessions',
        orderBy: 'testDate DESC',
        limit: limit,
      );

      final List<TestResult> results = [];
      for (final sessionMap in sessionMaps) {
        final sessionId = sessionMap['id'] as String;
        final metricsMap = await _databaseHelper.getTestResults(sessionId);
        results.add(TestResultModel.fromMap({
          ...sessionMap,
          'metrics': metricsMap,
        }).toEntity());
      }
      return results;
    } catch (e, stackTrace) {
      AppLogger.dbError('getRecentTests', e.toString());
      throw TestDatabaseException('Son testleri getirirken hata: $e', originalError: e);
    }
  }

  @override
  Future<List<TestResult>> getTodayTests() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getTestResultsByDateRange(startOfDay, endOfDay);
  }

  @override
  Future<List<TestResult>> getWeekTests() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Pazartesi
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return getTestResultsByDateRange(startOfWeek, endOfWeek);
  }

  @override
  Future<List<TestResult>> getMonthTests() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59); // Ayın son günü
    return getTestResultsByDateRange(startOfMonth, endOfMonth);
  }

  @override
  Future<TestStatistics> getTestStatistics() async {
    try {
      final allTests = await getTestResultsByDateRange(DateTime(2000), DateTime.now()); // Tüm testler
      
      final totalTests = allTests.length;
      final todayTests = (await getTodayTests()).length;
      final weekTests = (await getWeekTests()).length;
      final monthTests = (await getMonthTests()).length;

      final testTypeDistribution = <TestType, int>{};
      final qualityDistribution = <TestQuality, int>{};
      final monthlyTestCounts = <String, int>{};
      final uniqueAthletes = <String>{};
      final athleteTestCounts = <String, int>{};
      double totalDuration = 0.0;

      for (final test in allTests) {
        testTypeDistribution[test.testType] = (testTypeDistribution[test.testType] ?? 0) + 1;
        qualityDistribution[test.quality] = (qualityDistribution[test.quality] ?? 0) + 1;
        
        final monthKey = '${test.testDate.year}-${test.testDate.month.toString().padLeft(2, '0')}';
        monthlyTestCounts[monthKey] = (monthlyTestCounts[monthKey] ?? 0) + 1;

        uniqueAthletes.add(test.athleteId);
        athleteTestCounts[test.athleteId] = (athleteTestCounts[test.athleteId] ?? 0) + 1;
        totalDuration += test.duration.inMilliseconds;
      }

      String mostTestedAthleteId = '';
      if (athleteTestCounts.isNotEmpty) {
        mostTestedAthleteId = athleteTestCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }
      
      TestType mostPopularTestType = TestType.counterMovementJump; // Default
      if (testTypeDistribution.isNotEmpty) {
        mostPopularTestType = testTypeDistribution.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // Ortalama metrikler hesaplaması (basitleştirilmiş, sadece CMJ JumpHeight için)
      final averageMetricsByTestType = <String, double>{};
      final cmjTests = allTests.where((t) => t.testType == TestType.counterMovementJump).toList();
      if (cmjTests.isNotEmpty) {
        final totalJumpHeight = cmjTests.map((t) => t.metrics['jumpHeight'] ?? 0.0).reduce((a, b) => a + b);
        averageMetricsByTestType['CMJ_jumpHeight'] = totalJumpHeight / cmjTests.length;
      }
      // Diğer test türleri ve metrikler için benzer şekilde eklenebilir

      return TestStatistics(
        totalTests: totalTests,
        todayTests: todayTests,
        weekTests: weekTests,
        monthTests: monthTests,
        testTypeDistribution: testTypeDistribution,
        qualityDistribution: qualityDistribution,
        monthlyTestCounts: monthlyTestCounts,
        averageTestDuration: totalTests > 0 ? totalDuration / totalTests / 1000.0 : 0.0, // Saniye cinsinden
        averageMetricsByTestType: averageMetricsByTestType,
        uniqueAthletesTested: uniqueAthletes.length,
        mostTestedAthlete: mostTestedAthleteId,
        mostPopularTestType: mostPopularTestType,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Test istatistiklerini getirirken hata', e, stackTrace);
      return const TestStatistics();
    }
  }

  @override
  Future<AthletePerformanceAnalysis> getAthletePerformanceAnalysis(String athleteId) async {
    try {
      final athleteTests = await getAthleteTestHistory(athleteId);
      if (athleteTests.isEmpty) {
        return AthletePerformanceAnalysis([], athleteId: athleteId);
      }

      final testsByType = athleteTests.groupBy((test) => test.testType);
      
      final Map<String, PerformanceTrend> metricTrends = {};
      final Map<TestType, double> bestPerformances = {};
      final Map<TestType, double> averagePerformances = {};
      final List<TestResult> personalRecords = [];
      final List<TestResult> topPerformances = [];

      // Metrik trendleri, en iyi/ortalama performanslar
      for (final entry in testsByType.entries) {
        final testType = entry.key;
        final tests = entry.value..sort((a, b) => a.testDate.compareTo(b.testDate));

        if (tests.length > 1) {
          final primaryMetricName = _getPrimaryMetricNameForTrend(testType);
          if (primaryMetricName != null) {
            final metricValues = tests.map((t) => _getPrimaryMetricValue(t)).toList(); // Corrected: use helper
            
            // Basit trend hesaplaması (lineer regresyon veya moving average)
            // Burada basitçe ilk ve son değer farkını alıyoruz
            final firstValue = metricValues.first;
            final lastValue = metricValues.last;
            double trendValue = 0.0;
            if (firstValue != 0) {
              trendValue = ((lastValue - firstValue) / firstValue) * 100;
            }
            
            TrendDirection direction; // Corrected: Use TrendDirection from test_repository.dart
            if (trendValue > 5) {
              direction = TrendDirection.improving;
            } else if (trendValue < -5) {
              direction = TrendDirection.declining;
            } else {
              direction = TrendDirection.stable;
            }

            metricTrends[primaryMetricName] = PerformanceTrend(
              trend: trendValue,
              confidence: 0.8, // Basit güven
              direction: direction,
              dataPoints: metricValues,
            );
          }
        }

        // En iyi performans
        final bestTest = tests.reduce((a, b) {
          final aPrimary = _getPrimaryMetricValue(a); // Corrected: use helper
          final bPrimary = _getPrimaryMetricValue(b); // Corrected: use helper
          return aPrimary > bPrimary ? a : b;
        });
        bestPerformances[testType] = _getPrimaryMetricValue(bestTest); // Corrected: use helper
        personalRecords.add(bestTest);

        // Ortalama performans
        final allPrimaryMetrics = tests.map((t) => _getPrimaryMetricValue(t)).toList(); // Corrected: use helper
        if (allPrimaryMetrics.isNotEmpty) {
          averagePerformances[testType] = allPrimaryMetrics.reduce((a, b) => a + b) / allPrimaryMetrics.length;
        }
      }
      
      // Genel gelişim (Basitleştirilmiş)
      double overallImprovement = 0.0;
      if (metricTrends.isNotEmpty) {
        overallImprovement = metricTrends.values.map((t) => t.trend).fold(0.0, (sum, current) => sum + current) / metricTrends.length; // Corrected: use fold
      }

      // Öneriler (Basitleştirilmiş)
      final recommendations = <String>[];
      if (overallImprovement < 0) {
        recommendations.add('Performansta düşüş gözlemlendi. Antrenman programını gözden geçirin.');
      } else if (overallImprovement > 0) {
        recommendations.add('Harika gelişim! Devam edin.');
      }

      // En iyi performanslar (tüm test türleri arasında)
      final sortedAllTests = athleteTests.toList()..sort((a, b) { // Corrected: Use athleteTests
        final aPrimary = _getPrimaryMetricValue(a); // Corrected: use helper
        final bPrimary = _getPrimaryMetricValue(b); // Corrected: use helper
        return bPrimary.compareTo(aPrimary); // En yüksekten düşüğe
      });
      topPerformances.addAll(sortedAllTests.take(3)); // En iyi 3 test

      return AthletePerformanceAnalysis(
        topPerformances, // Top performance artık yapıcı metoda ilk argüman olarak alınıyor
        athleteId: athleteId,
        totalTests: athleteTests.length,
        firstTestDate: athleteTests.first.testDate,
        lastTestDate: athleteTests.last.testDate,
        testsByType: testsByType,
        metricTrends: metricTrends,
        bestPerformances: bestPerformances,
        averagePerformances: averagePerformances,
        personalRecords: personalRecords,
        overallImprovement: overallImprovement,
        recommendations: recommendations,
      );

    } catch (e, stackTrace) {
      AppLogger.error('Sporcu performans analizini getirirken hata', e, stackTrace);
      return AthletePerformanceAnalysis([], athleteId: athleteId); // Boş sonuç döndür
    }
  }

  // Metrik trendi için birincil metrik adı
  String? _getPrimaryMetricNameForTrend(TestType testType) {
    switch (testType) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        return 'jumpHeight';
      case TestType.isometricMidThighPull:
      case TestType.isometricSquat:
        return 'peakForce';
      case TestType.staticBalance:
      case TestType.singleLegBalance:
      case TestType.dynamicBalance:
        return 'stabilityIndex';
      case TestType.continuousJump:
      case TestType.lateralHop:
      case TestType.anteriorPosteriorHop:
      case TestType.medialLateralHop:
        return 'speed'; // Örnek bir metrik
    }
  }

  // Helper function to get primary metric value safely
  double _getPrimaryMetricValue(TestResult test) {
    switch (test.testType) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        return test.metrics['jumpHeight'] ?? 0.0;
      case TestType.isometricMidThighPull:
      case TestType.isometricSquat:
        return test.metrics['peakForce'] ?? 0.0;
      case TestType.staticBalance:
      case TestType.singleLegBalance:
      case TestType.dynamicBalance:
        return test.metrics['stabilityIndex'] ?? 0.0;
      case TestType.continuousJump:
      case TestType.lateralHop:
      case TestType.anteriorPosteriorHop:
      case TestType.medialLateralHop:
        return test.metrics['speed'] ?? 0.0;
      default:
        return 0.0;
    }
  }

  @override
  Future<TestTypeStatistics> getTestTypeStatistics(TestType testType) async {
    try {
      final testsOfType = await getTestResultsByType(testType);
      if (testsOfType.isEmpty) {
        return TestTypeStatistics(testType: testType);
      }

      final totalTests = testsOfType.length;
      final Map<String, List<double>> allMetrics = {};

      for (final test in testsOfType) {
        test.metrics.forEach((key, value) {
          allMetrics.putIfAbsent(key, () => []).add(value);
        });
      }

      final averageMetrics = <String, double>{};
      final bestMetrics = <String, double>{};
      final metricStandardDeviations = <String, double>{};
      final metricDistributions = <String, PerformanceDistribution>{};

      allMetrics.forEach((metricName, values) {
        if (values.isNotEmpty) {
          averageMetrics[metricName] = values.reduce((a, b) => a + b) / values.length;
          bestMetrics[metricName] = values.reduce((a, b) => a > b ? a : b); // En yüksek değer
          
          final mean = averageMetrics[metricName]!;
          final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
          metricStandardDeviations[metricName] = math.sqrt(variance);

          // Performans dağılımı
          final sortedValues = List<double>.from(values)..sort();
          metricDistributions[metricName] = PerformanceDistribution(
            percentile25: _getPercentile(sortedValues, 25),
            percentile50: _getPercentile(sortedValues, 50),
            percentile75: _getPercentile(sortedValues, 75),
            percentile90: _getPercentile(sortedValues, 90),
            percentile95: _getPercentile(sortedValues, 95),
            min: sortedValues.first,
            max: sortedValues.last,
            mean: mean,
            standardDeviation: metricStandardDeviations[metricName]!,
          );
        }
      });

      // Top performanslar (örneğin JumpHeight için en iyi 3)
      final List<TestResult> topPerformances = testsOfType.toList()
        ..sort((a, b) {
          final aPrimary = _getPrimaryMetricValue(a); // Corrected: use helper
          final bPrimary = _getPrimaryMetricValue(b); // Corrected: use helper
          return bPrimary.compareTo(aPrimary);
        });

      // Normatif veri (basitleştirilmiş)
      final normativeData = <String, double>{
        // Burada yaşa, cinsiyete vb. göre normatif veriler getirilebilir
        // Şimdilik boş bırakıyoruz
      };

      return TestTypeStatistics(
        testType: testType,
        totalTests: totalTests,
        averageMetrics: averageMetrics,
        bestMetrics: bestMetrics,
        metricStandardDeviations: metricStandardDeviations,
        metricDistributions: metricDistributions,
        topPerformances: topPerformances.take(3).toList(),
        normativeData: normativeData,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Test türü istatistiklerini getirirken hata', e, stackTrace);
      return TestTypeStatistics(testType: testType);
    }
  }

  // Percentile hesaplama yardımcı fonksiyonu
  double _getPercentile(List<double> sortedValues, double percentile) {
    if (sortedValues.isEmpty) {
      return 0.0;
    }
    if (percentile < 0 || percentile > 100) {
      throw ArgumentError('Percentile must be between 0 and 100');
    }
    
    final index = (percentile / 100) * (sortedValues.length - 1);
    
    if (index == index.floor()) {
      return sortedValues[index.floor()];
    } else {
      final lower = sortedValues[index.floor()];
      final upper = sortedValues[index.ceil()];
      final fraction = index - index.floor();
      return lower + (upper - lower) * fraction;
    }
  }

  @override
  Future<void> deleteMultipleTests(List<String> sessionIds) async {
    try {
      final db = await _databaseHelper.database;
      final batch = db.batch();
      for (final sessionId in sessionIds) {
        batch.delete(
          'test_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
        );
      }
      await batch.commit(noResult: true);
      AppLogger.info('${sessionIds.length} test toplu olarak silindi.');
    } catch (e, stackTrace) {
      AppLogger.error('Toplu test silme hatası', e, stackTrace);
      throw TestDatabaseException('Toplu test silme başarısız: $e', originalError: e);
    }
  }

  @override
  Future<List<TestResult>> searchTests(String query) async {
    try {
      final db = await _databaseHelper.database;
      final searchQuery = '%${query.toLowerCase()}%';

      // test_sessions ve athletes tablolarını birleştirerek arama yap
      final rawResults = await db.rawQuery('''
        SELECT
          ts.*,
          a.firstName AS athleteFirstName,
          a.lastName AS athleteLastName
        FROM test_sessions ts
        JOIN athletes a ON ts.athleteId = a.id
        WHERE
          LOWER(ts.testType) LIKE ? OR
          LOWER(ts.notes) LIKE ? OR
          LOWER(a.firstName) LIKE ? OR
          LOWER(a.lastName) LIKE ?
        ORDER BY ts.testDate DESC
      ''', [searchQuery, searchQuery, searchQuery, searchQuery]);

      final List<TestResult> results = [];
      for (final row in rawResults) {
        final sessionId = row['id'] as String;
        final metricsMap = await _databaseHelper.getTestResults(sessionId);
        
        results.add(TestResultModel.fromMap({
          ...row,
          'metrics': metricsMap,
        }).toEntity());
      }
      return results;
    } catch (e, stackTrace) {
      AppLogger.error('Test arama hatası', e, stackTrace);
      throw TestDatabaseException('Test arama başarısız: $e', originalError: e);
    }
  }

  @override
  Future<List<TestResult>> getTestsByQuality(TestQuality quality) async {
    try {
      final allTests = await getTestResultsByDateRange(DateTime(2000), DateTime.now());
      return allTests.where((test) => test.quality == quality).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Kaliteye göre testleri getirirken hata', e, stackTrace);
      throw TestDatabaseException('Kaliteye göre testleri getirirken hata: $e', originalError: e);
    }
  }

  @override
  Future<List<TestResult>> getTestsByPerformanceCategory(PerformanceCategory category) async {
    try {
      final allTests = await getTestResultsByDateRange(DateTime(2000), DateTime.now());
      // Bu fonksiyon atlet bilgisine de ihtiyaç duyar, bu yüzden basit bir mock kullanıyoruz
      // Gerçek implementasyonda AthleteRepository'den atlet bilgisi çekilmeli
      return allTests.where((test) {
        final mockAthlete = Athlete.create(firstName: 'Mock', lastName: 'Athlete'); // Geçici atlet
        return test.getPerformanceCategory(mockAthlete) == category;
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Performans kategorisine göre testleri getirirken hata', e, stackTrace);
      throw TestDatabaseException('Performans kategorisine göre testleri getirirken hata: $e', originalError: e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> exportTestData(List<String> sessionIds) async {
    try {
      final List<Map<String, dynamic>> exportedData = [];
      for (final sessionId in sessionIds) {
        final sessionMaps = await (await _databaseHelper.database).query( // Corrected: await sessionMaps
          'test_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
        );
        if (sessionMaps.isNotEmpty) { // Corrected: Check sessionMaps.isNotEmpty
          final metrics = await _databaseHelper.getTestResults(sessionId);
          final forceDataMaps = await _databaseHelper.getSessionForceData(sessionId); // Corrected: Await forceDataMaps

          exportedData.add({
            'session': sessionMaps.first,
            'metrics': metrics,
            'force_data': forceDataMaps, // Corrected: remove .map((d) => d.toMap())
          });
        }
      }
      return exportedData;
    } catch (e, stackTrace) {
      AppLogger.error('Test verilerini dışa aktarırken hata', e, stackTrace);
      throw TestDatabaseException('Veri dışa aktarma başarısız: $e', originalError: e);
    }
  }

  @override
  Future<void> importTestData(List<Map<String, dynamic>> testData) async {
    try {
      for (final dataEntry in testData) {
        final sessionMap = dataEntry['session'] as Map<String, dynamic>;
        final metricsMap = dataEntry['metrics'] as Map<String, dynamic>;
        final forceDataListMap = dataEntry['force_data'] as List<dynamic>;

        final sessionId = sessionMap['id'] as String;

        // Oturumu kaydet
        await _databaseHelper.insertTestSession(sessionMap);

        // Metrikleri kaydet
        await _databaseHelper.insertTestResultsBatch(
          sessionId,
          metricsMap.map((key, value) => MapEntry(key, value as double)),
        );

        // Force datayı kaydet
        await _databaseHelper.insertForceDataBatch(
          sessionId,
          forceDataListMap.map((e) => e as Map<String, dynamic>).toList(),
        );
      }
      AppLogger.info('${testData.length} test başarıyla içe aktarıldı.');
    } catch (e, stackTrace) {
      AppLogger.error('Test verilerini içe aktarırken hata', e, stackTrace);
      throw TestDatabaseException('Veri içe aktarma başarısız: $e', originalError: e);
    }
  }

  @override
  Future<int> getDatabaseSize() async {
    try {
      return await _databaseHelper.getDatabaseSize();
    } catch (e, stackTrace) {
      AppLogger.error('Database boyutu alınırken hata', e, stackTrace);
      return 0;
    }
  }

  @override
  Future<void> cleanupOldTests(DateTime cutoffDate) async {
    try {
      final db = await _databaseHelper.database;
      // Belirtilen tarihten önceki test oturumlarını sil
      // FOREIGN KEY CASCADE sayesinde force_data ve test_results da silinecektir
      final deletedCount = await db.delete(
        'test_sessions',
        where: 'testDate < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      AppLogger.info('$deletedCount adet eski test silindi (önceki tarih: $cutoffDate).');
    } catch (e, stackTrace) {
      AppLogger.error('Eski testleri temizlerken hata', e, stackTrace);
      throw TestDatabaseException('Eski testleri temizlerken hata: $e', originalError: e);
    }
  }

  @override
  Future<bool> testSessionExists(String sessionId) async {
    try {
      final sessionMaps = await (await _databaseHelper.database).query( // Corrected: await sessionMaps
        'test_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      return sessionMaps.isNotEmpty; // Corrected: Check sessionMaps.isNotEmpty
    } catch (e, stackTrace) {
      AppLogger.error('Test oturumu varlığını kontrol ederken hata', e, stackTrace);
      return false;
    }
  }

  @override
  Future<DateTime?> getAthleteLastTestDate(String athleteId) async {
    try {
      final db = await _databaseHelper.database;
      final results = await db.query(
        'test_sessions',
        where: 'athleteId = ?',
        whereArgs: [athleteId],
        orderBy: 'testDate DESC',
        limit: 1,
      );
      if (results.isNotEmpty) {
        return DateTime.parse(results.first['testDate'] as String);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Atletin son test tarihini getirirken hata', e, stackTrace);
      return null;
    }
  }

  @override
  Future<TestComparison?> compareTests(String sessionId1, String sessionId2) async {
    try {
      final test1 = await getTestResult(sessionId1);
      final test2 = await getTestResult(sessionId2);

      if (test1 == null || test2 == null) {
        throw TestDataNotFoundException('Karşılaştırma için testlerden biri bulunamadı.');
      }
      if (test1.testType != test2.testType) {
        throw InvalidTestDataException('Farklı test türleri karşılaştırılamaz.');
      }

      return test1.compareWith(test2);
    } catch (e, stackTrace) {
      AppLogger.error('Testleri karşılaştırırken hata', e, stackTrace);
      if (e is TestRepositoryException) {
        rethrow;
      }
      throw TestDatabaseException('Testleri karşılaştırırken hata: $e', originalError: e);
    }
  }

  @override
  Future<NormativeAnalysis> getNormativeAnalysis(TestResult testResult, Athlete athlete) async {
    // Bu kısım normatif veritabanı veya karmaşık istatistiksel modeller gerektirir.
    // Şimdilik basitleştirilmiş bir implementasyon sunuyoruz.
    try {
      final percentileRankings = <String, double>{};
      final metricCategories = <String, PerformanceCategory>{};
      final strengths = <String>[];
      final improvementAreas = <String>[];
      final recommendations = <String>[];

      // Örnek: Jump Height için basit normatif değerlendirme
      final jumpHeight = testResult.metrics['jumpHeight'];
      if (jumpHeight != null && athlete.gender != null && athlete.age != null) {
        // Mock normatif veriden percentile hesapla (Gerçekte daha detaylı PopulationNorms kullanılmalı)
        final isMale = athlete.gender == Gender.male;
        double mean = isMale ? 35.0 : 28.0; // cm
        double std = isMale ? 8.0 : 6.0; // cm

        // Yaşa göre ayar
        if (athlete.age! < 18) {
          mean *= 0.8;
          std *= 0.8;
        } else if (athlete.age! > 35) {
          mean *= 0.9;
          std *= 0.9;
        }

        final zScore = (jumpHeight - mean) / std;
        final percentile = (50 + 50 * _erf(zScore / math.sqrt(2))).clamp(0.0, 100.0);
        percentileRankings['jumpHeight'] = percentile;

        if (percentile >= 90) {
          metricCategories['jumpHeight'] = PerformanceCategory.excellent;
          strengths.add('Sıçrama yüksekliği mükemmel düzeyde.');
        } else if (percentile >= 70) {
          metricCategories['jumpHeight'] = PerformanceCategory.good;
        } else if (percentile >= 30) {
          metricCategories['jumpHeight'] = PerformanceCategory.average;
        } else {
          metricCategories['jumpHeight'] = PerformanceCategory.poor;
          improvementAreas.add('Sıçrama yüksekliği geliştirilmeli.');
          recommendations.add('Pliometrik ve kuvvet antrenmanlarına odaklanın.');
        }
      }

      // Diğer metrikler için de benzer analizler yapılabilir

      // Genel performans değerlendirmesi (Basitleştirilmiş)
      OverallPerformanceRating overallRating = OverallPerformanceRating.average;
      if (percentileRankings.isNotEmpty) {
        final avgPercentile = percentileRankings.values.reduce((a, b) => a + b) / percentileRankings.length;
        if (avgPercentile >= 90) {
          overallRating = OverallPerformanceRating.excellent;
        } else if (avgPercentile >= 70) {
          overallRating = OverallPerformanceRating.good;
        } else if (avgPercentile >= 30) {
          overallRating = OverallPerformanceRating.average;
        } else {
          overallRating = OverallPerformanceRating.poor;
        }
      }
      
      return NormativeAnalysis(
        testResult: testResult,
        athlete: athlete,
        percentileRankings: percentileRankings,
        metricCategories: metricCategories,
        overallRating: overallRating,
        strengths: strengths,
        improvementAreas: improvementAreas,
        recommendations: recommendations,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Normatif analiz yapılırken hata', e, stackTrace);
      throw TestRepositoryException('Normatif analiz yapılırken hata: $e', originalError: e);
    }
  }

  // Simplified error function approximation (Copied from TestConstants)
  double _erf(double x) {
    final a = 0.3275911;
    final t = 1.0 / (1.0 + a * x.abs());
    final result = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * math.exp(-x * x);
    return x >= 0 ? result : -result;
  }
}

// Metrik trend yönü enum'u
enum MetricTrendDirection {
  improving,
  declining,
  stable,
}