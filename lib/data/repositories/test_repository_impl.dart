// lib/data/repositories/test_repository_impl.dart

import '../../domain/entities/test_result.dart';
import '../../domain/entities/force_data.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/repositories/test_repository.dart';
import '../datasources/usb_data_source.dart';
import '../datasources/mock_data_source.dart';
import '../models/test_result_model.dart';
import '../models/force_data_model.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/app_constants.dart';

class TestRepositoryImpl implements TestRepository {
  final DatabaseHelper _databaseHelper;
  final UsbDataSource? _usbDataSource;
  final MockDataSource _mockDataSource;
  bool _useMockData = true; // Geliştirme sırasında mock data kullan

  TestRepositoryImpl({
    required DatabaseHelper databaseHelper,
    UsbDataSource? usbDataSource,
    required MockDataSource mockDataSource,
  })  : _databaseHelper = databaseHelper,
        _usbDataSource = usbDataSource,
        _mockDataSource = mockDataSource;

  @override
  Future<String> saveTestResult(TestResult testResult) async {
    try {
      final testModel = TestResultModel.fromEntity(testResult);
      final id = await _databaseHelper.insertTestResult(testModel.toMap());
      return id;
    } catch (e) {
      print('Error saving test result: $e');
      throw TestRepositoryException('Failed to save test result');
    }
  }

  @override
  Future<void> saveForceDataBatch(String sessionId, List<ForceData> forceDataList) async {
    try {
      final forceDataMaps = forceDataList
          .map((data) => ForceDataModel.fromEntity(data).toMap())
          .toList();
      
      await _databaseHelper.insertForceDataBatch(sessionId, forceDataMaps);
    } catch (e) {
      print('Error saving force data batch: $e');
      throw TestRepositoryException('Failed to save force data');
    }
  }

  @override
  Future<TestResult?> getTestResult(String sessionId) async {
    try {
      final resultModel = await _databaseHelper.getTestResultById(sessionId);
      return resultModel?.toEntity();
    } catch (e) {
      print('Error getting test result: $e');
      return null;
    }
  }

  @override
  Future<List<TestResult>> getAthleteTestHistory(String athleteId) async {
    try {
      final results = await _databaseHelper.getTestResultsByAthlete(athleteId);
      return results.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting athlete test history: $e');
      return [];
    }
  }

  @override
  Future<List<TestResult>> getTestResultsByType(TestType testType) async {
    try {
      final results = await _databaseHelper.getTestResultsByType(testType);
      return results.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting test results by type: $e');
      return [];
    }
  }

  @override
  Future<List<TestResult>> getTestResultsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final results = await _databaseHelper.getTestResultsByDateRange(startDate, endDate);
      return results.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting test results by date range: $e');
      return [];
    }
  }

  @override
  Future<List<ForceData>> getSessionForceData(String sessionId) async {
    try {
      final forceDataModels = await _databaseHelper.getForceDataForTest(sessionId);
      return forceDataModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting session force data: $e');
      return [];
    }
  }

  @override
  Future<List<ForceData>> getSessionForceDataSampled(String sessionId, {int sampleRate = 100}) async {
    try {
      final allData = await getSessionForceData(sessionId);
      if (allData.isEmpty) return [];
      
      // Sample data for performance
      final step = (allData.length / sampleRate).ceil();
      final sampled = <ForceData>[];
      for (int i = 0; i < allData.length; i += step) {
        sampled.add(allData[i]);
      }
      return sampled;
    } catch (e) {
      print('Error getting sampled force data: $e');
      return [];
    }
  }

  @override
  Future<void> updateTestResult(TestResult testResult) async {
    try {
      final testModel = TestResultModel.fromEntity(testResult);
      await _databaseHelper.updateTestResult(testResult.sessionId, testModel.toMap());
    } catch (e) {
      print('Error updating test result: $e');
      throw TestRepositoryException('Failed to update test result');
    }
  }

  @override
  Future<void> deleteTestResult(String sessionId) async {
    try {
      await _databaseHelper.deleteTestResult(sessionId);
    } catch (e) {
      print('Error deleting test result: $e');
      throw TestRepositoryException('Failed to delete test result');
    }
  }

  @override
  Future<void> deleteTestSession(String sessionId) async {
    try {
      // Delete test result and associated force data
      await _databaseHelper.deleteTestResult(sessionId);
      // Force data should be deleted by foreign key constraint
    } catch (e) {
      print('Error deleting test session: $e');
      throw TestRepositoryException('Failed to delete test session');
    }
  }

  @override
  Future<List<TestResult>> getRecentTests({int limit = 10}) async {
    try {
      final results = await _databaseHelper.getRecentTests(limit);
      return results.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting recent tests: $e');
      return [];
    }
  }

  @override
  Future<List<TestResult>> getTodayTests() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    return getTestResultsByDateRange(startOfDay, endOfDay);
  }

  @override
  Future<List<TestResult>> getWeekTests() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: 7));
    return getTestResultsByDateRange(startOfWeek, now);
  }

  @override
  Future<List<TestResult>> getMonthTests() async {
    final now = DateTime.now();
    final startOfMonth = now.subtract(Duration(days: 30));
    return getTestResultsByDateRange(startOfMonth, now);
  }

  @override
  Future<TestStatistics> getTestStatistics() async {
    try {
      // Implementation placeholder - would calculate real statistics
      return const TestStatistics();
    } catch (e) {
      print('Error getting test statistics: $e');
      return const TestStatistics();
    }
  }

  @override
  Future<AthletePerformanceAnalysis> getAthletePerformanceAnalysis(String athleteId) async {
    try {
      final tests = await getAthleteTestHistory(athleteId);
      // Implementation placeholder - would analyze performance trends
      return AthletePerformanceAnalysis(
        [],
        athleteId: athleteId,
        totalTests: tests.length,
      );
    } catch (e) {
      print('Error getting athlete performance analysis: $e');
      return AthletePerformanceAnalysis([], athleteId: athleteId);
    }
  }

  @override
  Future<TestTypeStatistics> getTestTypeStatistics(TestType testType) async {
    try {
      // Implementation placeholder
      return TestTypeStatistics(testType: testType);
    } catch (e) {
      print('Error getting test type statistics: $e');
      return TestTypeStatistics(testType: testType);
    }
  }

  @override
  Future<void> deleteMultipleTests(List<String> sessionIds) async {
    try {
      for (final sessionId in sessionIds) {
        await deleteTestResult(sessionId);
      }
    } catch (e) {
      print('Error deleting multiple tests: $e');
      throw TestRepositoryException('Failed to delete tests');
    }
  }

  @override
  Future<List<TestResult>> searchTests(String query) async {
    try {
      final results = await _databaseHelper.searchTests(query);
      return results.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error searching tests: $e');
      return [];
    }
  }

  @override
  Future<List<TestResult>> getTestsByQuality(TestQuality quality) async {
    try {
      final results = await _databaseHelper.getTestsByQuality(quality);
      return results.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting tests by quality: $e');
      return [];
    }
  }

  @override
  Future<List<TestResult>> getTestsByPerformanceCategory(PerformanceCategory category) async {
    try {
      final results = await _databaseHelper.getTestsByPerformanceCategory(category);
      return results.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting tests by performance category: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> exportTestData(List<String> sessionIds) async {
    try {
      final results = <Map<String, dynamic>>[];
      for (final sessionId in sessionIds) {
        final test = await getTestResult(sessionId);
        if (test != null) {
          final testModel = TestResultModel.fromEntity(test);
          results.add(testModel.toMap());
        }
      }
      return results;
    } catch (e) {
      print('Error exporting test data: $e');
      return [];
    }
  }

  @override
  Future<void> importTestData(List<Map<String, dynamic>> testData) async {
    try {
      for (final data in testData) {
        await _databaseHelper.insertTestResult(data);
      }
    } catch (e) {
      print('Error importing test data: $e');
      throw TestRepositoryException('Failed to import test data');
    }
  }

  @override
  Future<int> getDatabaseSize() async {
    try {
      return await _databaseHelper.getDatabaseSize();
    } catch (e) {
      print('Error getting database size: $e');
      return 0;
    }
  }

  @override
  Future<void> cleanupOldTests(DateTime cutoffDate) async {
    try {
      await _databaseHelper.cleanupOldTests(cutoffDate);
    } catch (e) {
      print('Error cleaning up old tests: $e');
      throw TestRepositoryException('Failed to cleanup old tests');
    }
  }

  @override
  Future<bool> testSessionExists(String sessionId) async {
    try {
      final test = await getTestResult(sessionId);
      return test != null;
    } catch (e) {
      print('Error checking test session existence: $e');
      return false;
    }
  }

  @override
  Future<DateTime?> getAthleteLastTestDate(String athleteId) async {
    try {
      final tests = await getAthleteTestHistory(athleteId);
      if (tests.isEmpty) return null;
      
      tests.sort((a, b) => b.testDate.compareTo(a.testDate));
      return tests.first.testDate;
    } catch (e) {
      print('Error getting athlete last test date: $e');
      return null;
    }
  }

  @override
  Future<TestComparison?> compareTests(String sessionId1, String sessionId2) async {
    try {
      final test1 = await getTestResult(sessionId1);
      final test2 = await getTestResult(sessionId2);
      
      if (test1 == null || test2 == null) return null;
      
      // Implementation placeholder - would compare metrics
      return TestComparison(
        previousTest: test1,
        currentTest: test2,
        improvements: const {},
        metricDifferences: const {},
        percentageChanges: const {},
        overallImprovement: 0.0,
        significantChanges: const [],
      );
    } catch (e) {
      print('Error comparing tests: $e');
      return null;
    }
  }

  @override
  Future<NormativeAnalysis> getNormativeAnalysis(TestResult testResult, Athlete athlete) async {
    try {
      // Implementation placeholder - would analyze against norms
      return NormativeAnalysis(
        testResult: testResult,
        athlete: athlete,
      );
    } catch (e) {
      print('Error getting normative analysis: $e');
      return NormativeAnalysis(
        testResult: testResult,
        athlete: athlete,
      );
    }
  }

  // Mock data mode control
  void setMockDataMode(bool useMockData) {
    _useMockData = useMockData;
    print('Mock data mode: ${_useMockData ? "ENABLED" : "DISABLED"}');
  }
}