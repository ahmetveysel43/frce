import 'dart:math' as math;
import '../../data/models/test_result_model.dart';
import '../../data/models/athlete_model.dart';
import '../utils/app_logger.dart';
import 'progress_analyzer.dart';

/// Test karşılaştırma ve analiz servisi
/// Smart Metrics uygulamasından adapte edilmiş gelişmiş karşılaştırma özellikleri
class TestComparisonService {
  static const String _tag = 'TestComparisonService';

  /// İki test sonucu arasında detaylı karşılaştırma yap
  Future<ComparisonResult> compareTests({
    required TestResultModel test1,
    required TestResultModel test2,
  }) async {
    try {
      AppLogger.info('Comparing tests: ${test1.id} vs ${test2.id}');

      final scoreDifference = (test2.score ?? 0.0) - (test1.score ?? 0.0);
      final percentChange = ((test1.score ?? 0.0) != 0.0) ? (scoreDifference / (test1.score ?? 1.0)) * 100 : 0.0;
      final improvementLevel = _calculateImprovementLevel(percentChange);
      
      final metricComparisons = <String, MetricComparison>{};
      
      // Mevcut metrikleri karşılaştır
      for (final metric in test1.metrics.keys) {
        if (test2.metrics.containsKey(metric)) {
          final value1 = test1.metrics[metric]!;
          final value2 = test2.metrics[metric]!;
          final difference = value2 - value1;
          final change = value1 != 0 ? (difference / value1) * 100 : 0.0;
          
          metricComparisons[metric] = MetricComparison(
            metric: metric,
            value1: value1,
            value2: value2,
            difference: difference,
            percentChange: change,
            significance: _calculateSignificance(change),
          );
        }
      }

      final insights = _generateComparisonInsights(
        test1, test2, scoreDifference, percentChange, metricComparisons
      );

      return ComparisonResult(
        test1: test1,
        test2: test2,
        scoreDifference: scoreDifference,
        percentChange: percentChange,
        improvementLevel: improvementLevel,
        metricComparisons: metricComparisons,
        insights: insights,
        comparisonDate: DateTime.now(),
      );

    } catch (e, stackTrace) {
      AppLogger.error('Error comparing tests', e, stackTrace);
      rethrow;
    }
  }

  /// Belirli bir süre aralığındaki testleri karşılaştır
  Future<PeriodComparisonResult> comparePeriods({
    required List<TestResultModel> period1Results,
    required List<TestResultModel> period2Results,
    required String period1Label,
    required String period2Label,
  }) async {
    try {
      AppLogger.info(_tag, 'Comparing periods: $period1Label vs $period2Label');

      if (period1Results.isEmpty || period2Results.isEmpty) {
        throw ArgumentError('Both periods must contain at least one test result');
      }

      final analytics1 = await ProgressAnalyzer.calculateAdvancedAnalytics(
        period1Results, 
        period1Results.first.athleteId
      );
      final analytics2 = await ProgressAnalyzer.calculateAdvancedAnalytics(
        period2Results, 
        period2Results.first.athleteId
      );

      final performanceChange = (analytics2['cv'] as double? ?? 0.0) - (analytics1['cv'] as double? ?? 0.0);
      final consistencyChange = (analytics2['reliability'] as double? ?? 0.0) - (analytics1['reliability'] as double? ?? 0.0);
      
      final testTypeComparisons = _compareTestTypes(period1Results, period2Results);
      final volumeComparison = _compareTestVolume(period1Results, period2Results);
      
      final insights = _generatePeriodInsights(
        analytics1, analytics2, performanceChange, consistencyChange, 
        testTypeComparisons, volumeComparison
      );

      return PeriodComparisonResult(
        period1Label: period1Label,
        period2Label: period2Label,
        period1Results: period1Results,
        period2Results: period2Results,
        period1Analytics: analytics1,
        period2Analytics: analytics2,
        performanceChange: performanceChange,
        consistencyChange: consistencyChange,
        testTypeComparisons: testTypeComparisons,
        volumeComparison: volumeComparison,
        insights: insights,
        comparisonDate: DateTime.now(),
      );

    } catch (e, stackTrace) {
      AppLogger.error( 'Error comparing periods', e, stackTrace);
      rethrow;
    }
  }

  /// Birden fazla sporcu arasında karşılaştırma yap
  Future<AthleteComparisonResult> compareAthletes({
    required List<AthletePerformanceData> athleteData,
    required String testType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.info(_tag, 'Comparing ${athleteData.length} athletes for $testType');

      final comparisons = <AthleteComparison>[];
      final rankings = <AthleteRanking>[];

      for (final data in athleteData) {
        final filteredResults = _filterResultsByDateAndType(
          data.testResults, testType, startDate, endDate
        );
        
        if (filteredResults.isNotEmpty) {
          // Analytics will be calculated by progress analyzer
          final analytics = <String, dynamic>{};

          final scores = filteredResults.map((e) => e.score ?? 0.0).toList();
          final avgScore = scores.reduce((a, b) => a + b) / scores.length;
          final bestScore = scores.reduce(math.max);
          final latestScore = scores.last;

          comparisons.add(AthleteComparison(
            athlete: data.athlete,
            analytics: analytics,
            averageScore: avgScore,
            bestScore: bestScore,
            latestScore: latestScore,
            testCount: filteredResults.length,
            improvementRate: _calculateImprovementRate(filteredResults),
          ));
        }
      }

      // Sıralama oluştur
      final sortedByAverage = List<AthleteComparison>.from(comparisons)
        ..sort((a, b) => b.averageScore.compareTo(a.averageScore));
      
      for (int i = 0; i < sortedByAverage.length; i++) {
        rankings.add(AthleteRanking(
          athlete: sortedByAverage[i].athlete,
          rank: i + 1,
          score: sortedByAverage[i].averageScore,
          category: 'Average Performance',
        ));
      }

      final insights = _generateAthleteComparisonInsights(comparisons, rankings);

      return AthleteComparisonResult(
        testType: testType,
        comparisonPeriod: DateRange(startDate, endDate),
        athleteComparisons: comparisons,
        rankings: rankings,
        insights: insights,
        comparisonDate: DateTime.now(),
      );

    } catch (e, stackTrace) {
      AppLogger.error( 'Error comparing athletes', e, stackTrace);
      rethrow;
    }
  }

  /// Test tiplerini karşılaştır
  Future<TestTypeComparisonResult> compareTestTypes({
    required List<TestResultModel> allResults,
    required String athleteId,
  }) async {
    try {
      AppLogger.info(_tag, 'Comparing test types for athlete: $athleteId');

      final testTypeGroups = <String, List<TestResultModel>>{};
      
      // Test tiplerine göre gruplandır
      for (final result in allResults) {
        testTypeGroups.putIfAbsent(result.testType, () => []).add(result);
      }

      final typeAnalytics = <String, TestTypeAnalysis>{};
      
      for (final entry in testTypeGroups.entries) {
        final testType = entry.key;
        final results = entry.value;
        
        if (results.isNotEmpty) {
          // Analytics will be calculated by progress analyzer
          final analytics = <String, dynamic>{};
          
          final scores = results.map((e) => e.score ?? 0.0).toList();
          final avgScore = scores.reduce((a, b) => a + b) / scores.length;
          final bestScore = scores.reduce(math.max);
          final worstScore = scores.reduce(math.min);
          final improvementRate = _calculateImprovementRate(results);
          
          typeAnalytics[testType] = TestTypeAnalysis(
            testType: testType,
            analytics: analytics,
            testCount: results.length,
            averageScore: avgScore,
            bestScore: bestScore,
            worstScore: worstScore,
            improvementRate: improvementRate,
            frequency: _calculateTestFrequency(results),
          );
        }
      }

      final strengths = _identifyStrengths(typeAnalytics);
      final weaknesses = _identifyWeaknesses(typeAnalytics);
      final recommendations = _generateTestTypeRecommendations(typeAnalytics, strengths, weaknesses);

      return TestTypeComparisonResult(
        athleteId: athleteId,
        testTypeAnalytics: typeAnalytics,
        strengths: strengths,
        weaknesses: weaknesses,
        recommendations: recommendations,
        comparisonDate: DateTime.now(),
      );

    } catch (e, stackTrace) {
      AppLogger.error( 'Error comparing test types', e, stackTrace);
      rethrow;
    }
  }

  // Private helper methods

  ImprovementLevel _calculateImprovementLevel(double percentChange) {
    if (percentChange >= 10) return ImprovementLevel.significant;
    if (percentChange >= 5) return ImprovementLevel.moderate;
    if (percentChange >= 1) return ImprovementLevel.minor;
    if (percentChange >= -1) return ImprovementLevel.stable;
    if (percentChange >= -5) return ImprovementLevel.minorDecline;
    if (percentChange >= -10) return ImprovementLevel.moderateDecline;
    return ImprovementLevel.significantDecline;
  }

  SignificanceLevel _calculateSignificance(double percentChange) {
    final absChange = percentChange.abs();
    if (absChange >= 20) return SignificanceLevel.high;
    if (absChange >= 10) return SignificanceLevel.medium;
    if (absChange >= 5) return SignificanceLevel.low;
    return SignificanceLevel.minimal;
  }

  List<String> _generateComparisonInsights(
    TestResultModel test1,
    TestResultModel test2,
    double scoreDifference,
    double percentChange,
    Map<String, MetricComparison> metricComparisons,
  ) {
    final insights = <String>[];

    // Genel performans analizi
    if (percentChange > 10) {
      insights.add('Significant improvement of ${percentChange.toStringAsFixed(1)}% between tests');
    } else if (percentChange < -10) {
      insights.add('Performance declined by ${percentChange.abs().toStringAsFixed(1)}% - review training approach');
    } else if (percentChange.abs() <= 2) {
      insights.add('Performance remained stable with minimal change of ${percentChange.toStringAsFixed(1)}%');
    }

    // Metrik bazlı analiz
    final improvedMetrics = metricComparisons.values
        .where((m) => m.percentChange > 5)
        .map((m) => m.metric)
        .toList();
    
    final declinedMetrics = metricComparisons.values
        .where((m) => m.percentChange < -5)
        .map((m) => m.metric)
        .toList();

    if (improvedMetrics.isNotEmpty) {
      insights.add('Notable improvements in: ${improvedMetrics.join(', ')}');
    }
    
    if (declinedMetrics.isNotEmpty) {
      insights.add('Areas needing attention: ${declinedMetrics.join(', ')}');
    }

    // Zaman bazlı analiz
    final daysBetween = test2.timestamp.difference(test1.timestamp).inDays;
    if (daysBetween <= 7 && percentChange > 5) {
      insights.add('Rapid improvement within a week - excellent progress');
    } else if (daysBetween > 30 && percentChange < 2) {
      insights.add('Limited progress over extended period - consider training modifications');
    }

    return insights;
  }

  Map<String, TestTypeComparison> _compareTestTypes(
    List<TestResultModel> period1Results,
    List<TestResultModel> period2Results,
  ) {
    final comparisons = <String, TestTypeComparison>{};
    
    final testTypes = {
      ...period1Results.map((e) => e.testType),
      ...period2Results.map((e) => e.testType),
    };

    for (final testType in testTypes) {
      final type1Results = period1Results.where((r) => r.testType == testType).toList();
      final type2Results = period2Results.where((r) => r.testType == testType).toList();
      
      if (type1Results.isNotEmpty && type2Results.isNotEmpty) {
        final avg1 = type1Results.map((e) => e.score ?? 0.0).reduce((a, b) => a + b) / type1Results.length;
        final avg2 = type2Results.map((e) => e.score ?? 0.0).reduce((a, b) => a + b) / type2Results.length;
        final change = avg2 - avg1;
        final percentChange = (change / avg1) * 100;

        comparisons[testType] = TestTypeComparison(
          testType: testType,
          period1Average: avg1,
          period2Average: avg2,
          change: change,
          percentChange: percentChange,
          period1Count: type1Results.length,
          period2Count: type2Results.length,
        );
      }
    }

    return comparisons;
  }

  VolumeComparison _compareTestVolume(
    List<TestResultModel> period1Results,
    List<TestResultModel> period2Results,
  ) {
    final volumeChange = period2Results.length - period1Results.length;
    final percentChange = period1Results.isNotEmpty 
        ? (volumeChange / period1Results.length) * 100 
        : 0.0;

    return VolumeComparison(
      period1Count: period1Results.length,
      period2Count: period2Results.length,
      volumeChange: volumeChange,
      percentChange: percentChange,
    );
  }

  List<String> _generatePeriodInsights(
    Map<String, dynamic> analytics1,
    Map<String, dynamic> analytics2,
    double performanceChange,
    double consistencyChange,
    Map<String, TestTypeComparison> testTypeComparisons,
    VolumeComparison volumeComparison,
  ) {
    final insights = <String>[];

    // Performans değişimi
    if (performanceChange > 5) {
      insights.add('Overall performance improved by ${performanceChange.toStringAsFixed(1)} points');
    } else if (performanceChange < -5) {
      insights.add('Overall performance declined by ${performanceChange.abs().toStringAsFixed(1)} points');
    }

    // Tutarlılık değişimi
    if (consistencyChange > 10) {
      insights.add('Consistency significantly improved by ${consistencyChange.toStringAsFixed(1)}%');
    } else if (consistencyChange < -10) {
      insights.add('Consistency decreased by ${consistencyChange.abs().toStringAsFixed(1)}%');
    }

    // Test hacmi değişimi
    if (volumeComparison.percentChange > 20) {
      insights.add('Test volume increased by ${volumeComparison.percentChange.toStringAsFixed(1)}%');
    } else if (volumeComparison.percentChange < -20) {
      insights.add('Test volume decreased by ${volumeComparison.percentChange.abs().toStringAsFixed(1)}%');
    }

    // En çok gelişim gösteren test tipleri
    final mostImproved = testTypeComparisons.values
        .where((t) => t.percentChange > 10)
        .map((t) => t.testType)
        .toList();
    
    if (mostImproved.isNotEmpty) {
      insights.add('Most improved test types: ${mostImproved.join(', ')}');
    }

    return insights;
  }

  List<String> _generateAthleteComparisonInsights(
    List<AthleteComparison> comparisons,
    List<AthleteRanking> rankings,
  ) {
    final insights = <String>[];

    if (rankings.isNotEmpty) {
      final topPerformer = rankings.first;
      insights.add('Top performer: ${topPerformer.athlete.firstName} ${topPerformer.athlete.lastName} with ${topPerformer.score.toStringAsFixed(1)}%');
      
      final scores = comparisons.map((c) => c.averageScore).toList();
      final avgScore = scores.reduce((a, b) => a + b) / scores.length;
      final maxScore = scores.reduce(math.max);
      final minScore = scores.reduce(math.min);
      
      insights.add('Score range: ${minScore.toStringAsFixed(1)}% - ${maxScore.toStringAsFixed(1)}% (avg: ${avgScore.toStringAsFixed(1)}%)');
      
      final gapToTop = maxScore - avgScore;
      if (gapToTop > 10) {
        insights.add('Significant performance gap - top performer excels by ${gapToTop.toStringAsFixed(1)} points');
      }
    }

    return insights;
  }

  List<TestResultModel> _filterResultsByDateAndType(
    List<TestResultModel> results,
    String testType,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return results.where((result) {
      if (result.testType != testType) return false;
      if (startDate != null && result.timestamp.isBefore(startDate)) return false;
      if (endDate != null && result.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  double _calculateImprovementRate(List<TestResultModel> results) {
    if (results.length < 2) return 0.0;
    
    final sortedResults = List<TestResultModel>.from(results)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final firstScore = sortedResults.first.score ?? 0.0;
    final lastScore = sortedResults.last.score ?? 0.0;
    
    return firstScore != 0 ? ((lastScore - firstScore) / firstScore) * 100 : 0.0;
  }

  double _calculateTestFrequency(List<TestResultModel> results) {
    if (results.length < 2) return 0.0;
    
    final sortedResults = List<TestResultModel>.from(results)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final totalDays = sortedResults.last.timestamp
        .difference(sortedResults.first.timestamp)
        .inDays;
    
    return totalDays > 0 ? results.length / (totalDays / 7.0) : 0.0; // Tests per week
  }

  List<String> _identifyStrengths(Map<String, TestTypeAnalysis> typeAnalytics) {
    return typeAnalytics.values
        .where((analysis) => analysis.averageScore >= 80)
        .map((analysis) => analysis.testType)
        .toList();
  }

  List<String> _identifyWeaknesses(Map<String, TestTypeAnalysis> typeAnalytics) {
    return typeAnalytics.values
        .where((analysis) => analysis.averageScore < 60)
        .map((analysis) => analysis.testType)
        .toList();
  }

  List<String> _generateTestTypeRecommendations(
    Map<String, TestTypeAnalysis> typeAnalytics,
    List<String> strengths,
    List<String> weaknesses,
  ) {
    final recommendations = <String>[];

    if (weaknesses.isNotEmpty) {
      recommendations.add('Focus additional training on: ${weaknesses.join(', ')}');
    }

    if (strengths.isNotEmpty) {
      recommendations.add('Maintain performance levels in: ${strengths.join(', ')}');
    }

    // Frekans bazlı öneriler
    final lowFrequencyTests = typeAnalytics.values
        .where((analysis) => analysis.frequency < 1.0) // Less than once per week
        .map((analysis) => analysis.testType)
        .toList();

    if (lowFrequencyTests.isNotEmpty) {
      recommendations.add('Consider increasing frequency for: ${lowFrequencyTests.join(', ')}');
    }

    return recommendations;
  }
}

// Supporting classes

enum ImprovementLevel {
  significantDecline,
  moderateDecline,
  minorDecline,
  stable,
  minor,
  moderate,
  significant,
}

enum SignificanceLevel {
  minimal,
  low,
  medium,
  high,
}

class MetricComparison {
  final String metric;
  final double value1;
  final double value2;
  final double difference;
  final double percentChange;
  final SignificanceLevel significance;

  MetricComparison({
    required this.metric,
    required this.value1,
    required this.value2,
    required this.difference,
    required this.percentChange,
    required this.significance,
  });
}

class ComparisonResult {
  final TestResultModel test1;
  final TestResultModel test2;
  final double scoreDifference;
  final double percentChange;
  final ImprovementLevel improvementLevel;
  final Map<String, MetricComparison> metricComparisons;
  final List<String> insights;
  final DateTime comparisonDate;

  ComparisonResult({
    required this.test1,
    required this.test2,
    required this.scoreDifference,
    required this.percentChange,
    required this.improvementLevel,
    required this.metricComparisons,
    required this.insights,
    required this.comparisonDate,
  });
}

class TestTypeComparison {
  final String testType;
  final double period1Average;
  final double period2Average;
  final double change;
  final double percentChange;
  final int period1Count;
  final int period2Count;

  TestTypeComparison({
    required this.testType,
    required this.period1Average,
    required this.period2Average,
    required this.change,
    required this.percentChange,
    required this.period1Count,
    required this.period2Count,
  });
}

class VolumeComparison {
  final int period1Count;
  final int period2Count;
  final int volumeChange;
  final double percentChange;

  VolumeComparison({
    required this.period1Count,
    required this.period2Count,
    required this.volumeChange,
    required this.percentChange,
  });
}

class PeriodComparisonResult {
  final String period1Label;
  final String period2Label;
  final List<TestResultModel> period1Results;
  final List<TestResultModel> period2Results;
  final Map<String, dynamic> period1Analytics;
  final Map<String, dynamic> period2Analytics;
  final double performanceChange;
  final double consistencyChange;
  final Map<String, TestTypeComparison> testTypeComparisons;
  final VolumeComparison volumeComparison;
  final List<String> insights;
  final DateTime comparisonDate;

  PeriodComparisonResult({
    required this.period1Label,
    required this.period2Label,
    required this.period1Results,
    required this.period2Results,
    required this.period1Analytics,
    required this.period2Analytics,
    required this.performanceChange,
    required this.consistencyChange,
    required this.testTypeComparisons,
    required this.volumeComparison,
    required this.insights,
    required this.comparisonDate,
  });
}

class AthletePerformanceData {
  final AthleteModel athlete;
  final List<TestResultModel> testResults;

  AthletePerformanceData({
    required this.athlete,
    required this.testResults,
  });
}

class AthleteComparison {
  final AthleteModel athlete;
  final Map<String, dynamic> analytics;
  final double averageScore;
  final double bestScore;
  final double latestScore;
  final int testCount;
  final double improvementRate;

  AthleteComparison({
    required this.athlete,
    required this.analytics,
    required this.averageScore,
    required this.bestScore,
    required this.latestScore,
    required this.testCount,
    required this.improvementRate,
  });
}

class AthleteRanking {
  final AthleteModel athlete;
  final int rank;
  final double score;
  final String category;

  AthleteRanking({
    required this.athlete,
    required this.rank,
    required this.score,
    required this.category,
  });
}

class AthleteComparisonResult {
  final String testType;
  final DateRange comparisonPeriod;
  final List<AthleteComparison> athleteComparisons;
  final List<AthleteRanking> rankings;
  final List<String> insights;
  final DateTime comparisonDate;

  AthleteComparisonResult({
    required this.testType,
    required this.comparisonPeriod,
    required this.athleteComparisons,
    required this.rankings,
    required this.insights,
    required this.comparisonDate,
  });
}

class TestTypeAnalysis {
  final String testType;
  final Map<String, dynamic> analytics;
  final int testCount;
  final double averageScore;
  final double bestScore;
  final double worstScore;
  final double improvementRate;
  final double frequency;

  TestTypeAnalysis({
    required this.testType,
    required this.analytics,
    required this.testCount,
    required this.averageScore,
    required this.bestScore,
    required this.worstScore,
    required this.improvementRate,
    required this.frequency,
  });
}

class TestTypeComparisonResult {
  final String athleteId;
  final Map<String, TestTypeAnalysis> testTypeAnalytics;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;
  final DateTime comparisonDate;

  TestTypeComparisonResult({
    required this.athleteId,
    required this.testTypeAnalytics,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    required this.comparisonDate,
  });
}

class DateRange {
  final DateTime? startDate;
  final DateTime? endDate;

  DateRange(this.startDate, this.endDate);
}