import '../entities/test_result.dart';
import '../entities/force_data.dart';
import '../entities/athlete.dart';
import '../../core/constants/app_constants.dart';

/// Test domain repository interface
/// Clean Architecture - Domain katmanı repository contract'ı
abstract class TestRepository {
  /// Test sonucu kaydet
  Future<String> saveTestResult(TestResult testResult);

  /// Force data batch kaydet
  Future<void> saveForceDataBatch(String sessionId, List<ForceData> forceDataList);

  /// Test sonucunu getir
  Future<TestResult?> getTestResult(String sessionId);

  /// Sporcu test geçmişini getir
  Future<List<TestResult>> getAthleteTestHistory(String athleteId);

  /// Test türüne göre sonuçları getir
  Future<List<TestResult>> getTestResultsByType(TestType testType);

  /// Tarih aralığına göre test sonuçları
  Future<List<TestResult>> getTestResultsByDateRange(DateTime startDate, DateTime endDate);

  /// Force data getir
  Future<List<ForceData>> getSessionForceData(String sessionId);

  /// Force data (örneklenmiş) getir - performans için
  Future<List<ForceData>> getSessionForceDataSampled(String sessionId, {int sampleRate = 100});

  /// Test sonucunu güncelle
  Future<void> updateTestResult(TestResult testResult);

  /// Test sonucunu sil
  Future<void> deleteTestResult(String sessionId);

  /// Test session'ı sil (cascade)
  Future<void> deleteTestSession(String sessionId);

  /// En son testleri getir
  Future<List<TestResult>> getRecentTests({int limit = 10});

  /// Bugünkü testleri getir
  Future<List<TestResult>> getTodayTests();

  /// Bu haftaki testleri getir
  Future<List<TestResult>> getWeekTests();

  /// Bu ayki testleri getir
  Future<List<TestResult>> getMonthTests();

  /// Test istatistikleri
  Future<TestStatistics> getTestStatistics();

  /// Sporcu performans analizi
  Future<AthletePerformanceAnalysis> getAthletePerformanceAnalysis(String athleteId);

  /// Test türü istatistikleri
  Future<TestTypeStatistics> getTestTypeStatistics(TestType testType);

  /// Toplu test silme
  Future<void> deleteMultipleTests(List<String> sessionIds);

  /// Test arama (sporcu adı, test türü, notlar)
  Future<List<TestResult>> searchTests(String query);

  /// Kalite filtresi ile testler
  Future<List<TestResult>> getTestsByQuality(TestQuality quality);

  /// Performans kategorisi ile testler
  Future<List<TestResult>> getTestsByPerformanceCategory(PerformanceCategory category);

  /// Test verilerini export et
  Future<List<Map<String, dynamic>>> exportTestData(List<String> sessionIds);

  /// Test verilerini import et
  Future<void> importTestData(List<Map<String, dynamic>> testData);

  /// Database boyutunu al
  Future<int> getDatabaseSize();

  /// Test verilerini temizle (tarih aralığı)
  Future<void> cleanupOldTests(DateTime cutoffDate);

  /// Test session var mı kontrolü
  Future<bool> testSessionExists(String sessionId);

  /// Sporcu son test tarihi
  Future<DateTime?> getAthleteLastTestDate(String athleteId);

  /// Test karşılaştırması
  Future<TestComparison?> compareTests(String sessionId1, String sessionId2);

  /// Normative data analizi
  Future<NormativeAnalysis> getNormativeAnalysis(TestResult testResult, Athlete athlete);
}

/// Test istatistikleri model
class TestStatistics {
  final int totalTests;
  final int todayTests;
  final int weekTests;
  final int monthTests;
  final Map<TestType, int> testTypeDistribution;
  final Map<TestQuality, int> qualityDistribution;
  final Map<String, int> monthlyTestCounts; // YYYY-MM -> count
  final double averageTestDuration;
  final Map<String, double> averageMetricsByTestType;
  final int uniqueAthletesTested;
  final String mostTestedAthlete;
  final TestType mostPopularTestType;

  const TestStatistics({
    this.totalTests = 0,
    this.todayTests = 0,
    this.weekTests = 0,
    this.monthTests = 0,
    this.testTypeDistribution = const {},
    this.qualityDistribution = const {},
    this.monthlyTestCounts = const {},
    this.averageTestDuration = 0.0,
    this.averageMetricsByTestType = const {},
    this.uniqueAthletesTested = 0,
    this.mostTestedAthlete = '',
    this.mostPopularTestType = TestType.counterMovementJump,
  });

  /// Test başarı oranı (completed / total)
  double get successRate {
    final completedTests = qualityDistribution.entries
        .where((e) => e.key != TestQuality.invalid)
        .map((e) => e.value)
        .fold(0, (sum, count) => sum + count);
    return totalTests > 0 ? (completedTests / totalTests) * 100 : 0.0;
  }

  /// Günlük ortalama test sayısı (son 30 gün)
  double get dailyAverageTests => monthTests / 30.0;

  /// Kalite dağılım yüzdesi
  Map<TestQuality, double> get qualityPercentages {
    if (totalTests == 0) return {};
    return qualityDistribution.map(
      (quality, count) => MapEntry(quality, (count / totalTests) * 100),
    );
  }
}

/// Sporcu performans analizi
class AthletePerformanceAnalysis {
  final String athleteId;
  final int totalTests;
  final DateTime? firstTestDate;
  final DateTime? lastTestDate;
  final Map<TestType, List<TestResult>> testsByType;
  final Map<String, PerformanceTrend> metricTrends;
  final Map<TestType, double> bestPerformances;
  final Map<TestType, double> averagePerformances;
  final List<TestResult> personalRecords;
  final double overallImprovement; // percentage
  final List<String> recommendations;

  const AthletePerformanceAnalysis({
    required this.athleteId,
    this.totalTests = 0,
    this.firstTestDate,
    this.lastTestDate,
    this.testsByType = const {},
    this.metricTrends = const {},
    this.bestPerformances = const {},
    this.averagePerformances = const {},
    this.personalRecords = const {},
    this.overallImprovement = 0.0,
    this.recommendations = const [],
  });

  /// Test sıklığı (testler arası ortalama gün)
  double get testFrequency {
    if (totalTests < 2 || firstTestDate == null || lastTestDate == null) return 0.0;
    final daysBetween = lastTestDate!.difference(firstTestDate!).inDays;
    return daysBetween / (totalTests - 1);
  }

  /// Tutarlılık skoru (düşük varyans = yüksek tutarlılık)
  double get consistencyScore {
    // Bu metrik hesaplamaları implementation'da yapılacak
    return 0.0; // Placeholder
  }

  /// En gelişen metrik
  String? get mostImprovedMetric {
    if (metricTrends.isEmpty) return null;
    return metricTrends.entries
        .where((e) => e.value.trend > 0)
        .fold<MapEntry<String, PerformanceTrend>?>(
          null,
          (best, current) => best == null || current.value.trend > best.value.trend 
              ? current 
              : best,
        )?.key;
  }
}

/// Test türü istatistikleri
class TestTypeStatistics {
  final TestType testType;
  final int totalTests;
  final Map<String, double> averageMetrics;
  final Map<String, double> bestMetrics;
  final Map<String, double> metricStandardDeviations;
  final Map<String, PerformanceDistribution> metricDistributions;
  final List<TestResult> topPerformances;
  final Map<String, double> normativeData; // Age/gender based norms

  const TestTypeStatistics({
    required this.testType,
    this.totalTests = 0,
    this.averageMetrics = const {},
    this.bestMetrics = const {},
    this.metricStandardDeviations = const {},
    this.metricDistributions = const {},
    this.topPerformances = const {},
    this.normativeData = const {},
  });

  /// Metrik güvenilirlik skoru (düşük std dev = yüksek güvenilirlik)
  Map<String, double> get metricReliability {
    return metricStandardDeviations.map((metric, stdDev) {
      final average = averageMetrics[metric] ?? 0.0;
      if (average == 0.0) return MapEntry(metric, 0.0);
      final cv = stdDev / average; // Coefficient of variation
      return MapEntry(metric, (1.0 - cv).clamp(0.0, 1.0) * 100);
    });
  }
}

/// Performans trendi
class PerformanceTrend {
  final double trend; // Pozitif = gelişim, negatif = gerileme
  final double confidence; // 0-1 arası güven seviyesi
  final TrendDirection direction;
  final List<double> dataPoints;

  const PerformanceTrend({
    required this.trend,
    required this.confidence,
    required this.direction,
    required this.dataPoints,
  });
}

/// Trend yönü
enum TrendDirection {
  improving,
  declining,
  stable,
  insufficient_data,
}

/// Performans dağılımı
class PerformanceDistribution {
  final double percentile25;
  final double percentile50; // Median
  final double percentile75;
  final double percentile90;
  final double percentile95;
  final double min;
  final double max;
  final double mean;
  final double standardDeviation;

  const PerformanceDistribution({
    required this.percentile25,
    required this.percentile50,
    required this.percentile75,
    required this.percentile90,
    required this.percentile95,
    required this.min,
    required this.max,
    required this.mean,
    required this.standardDeviation,
  });

  /// Performansı percentile'a çevir
  double getPercentile(double value) {
    if (value <= percentile25) return 25.0;
    if (value <= percentile50) return 50.0;
    if (value <= percentile75) return 75.0;
    if (value <= percentile90) return 90.0;
    if (value <= percentile95) return 95.0;
    return 99.0;
  }
}

/// Normatif analiz
class NormativeAnalysis {
  final TestResult testResult;
  final Athlete athlete;
  final Map<String, double> percentileRankings; // Metrik -> percentile
  final Map<String, PerformanceCategory> metricCategories;
  final OverallPerformanceRating overallRating;
  final List<String> strengths;
  final List<String> improvementAreas;
  final List<String> recommendations;

  const NormativeAnalysis({
    required this.testResult,
    required this.athlete,
    this.percentileRankings = const {},
    this.metricCategories = const {},
    this.overallRating = OverallPerformanceRating.average,
    this.strengths = const [],
    this.improvementAreas = const [],
    this.recommendations = const [],
  });
}

/// Genel performans değerlendirmesi
enum OverallPerformanceRating {
  excellent,
  good,
  average,
  below_average,
  poor,
}

/// Repository exception'ları
class TestRepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const TestRepositoryException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'TestRepositoryException: $message';
}

/// Veri bulunamadı exception'ı
class TestDataNotFoundException extends TestRepositoryException {
  const TestDataNotFoundException(String message) : super(message, code: 'NOT_FOUND');
}

/// Geçersiz veri exception'ı
class InvalidTestDataException extends TestRepositoryException {
  const InvalidTestDataException(String message) : super(message, code: 'INVALID_DATA');
}

/// Database exception'ı
class TestDatabaseException extends TestRepositoryException {
  const TestDatabaseException(String message, {dynamic originalError}) 
      : super(message, code: 'DATABASE_ERROR', originalError: originalError);
}