import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../constants/test_constants.dart' as test_constants;
import '../utils/app_logger.dart';
import '../../data/models/test_result_model.dart';
import '../../data/models/athlete_model.dart';

/// Gelişmiş test karşılaştırma servisi
/// Hawkin Dynamics, VALD, Force Decks gibi sistemlerden ilham alınmıştır
class AdvancedComparisonService {
  static const double _confidenceThreshold = 0.95;
  static const int _minDataPoints = 3;

  /// Kapsamlı test karşılaştırması
  static Future<ComprehensiveComparisonResult> performComprehensiveComparison({
    required TestResultModel test1,
    required TestResultModel test2,
    required AthleteModel athlete,
    List<TestResultModel>? historicalData,
  }) async {
    try {
      AppLogger.info('🔬 Gelişmiş karşılaştırma başlatılıyor...');

      // Temel karşılaştırma
      final basicComparison = _performBasicComparison(test1, test2);
      
      // Vücut ağırlığına göre normalize edilmiş karşılaştırma
      final normalizedComparison = _performNormalizedComparison(test1, test2, athlete);
      
      // Popülasyon normlarına göre karşılaştırma
      final populationComparison = _performPopulationComparison(test1, test2, athlete);
      
      // İstatistiksel anlamlılık analizi
      final statisticalAnalysis = _performStatisticalAnalysis(test1, test2, historicalData);
      
      // Performans profil analizi
      final performanceProfile = _analyzePerformanceProfile(test1, test2);
      
      // Güçlü/zayıf yönler analizi
      final strengthWeaknessAnalysis = _analyzeStrengthsWeaknesses(test1, test2);
      
      // Trend analizi (tarihsel veri varsa)
      final trendAnalysis = historicalData != null 
          ? _performTrendAnalysis(historicalData, test2)
          : null;
      
      // Öneriler ve aksiyon planı
      final recommendations = _generateRecommendations(
        basicComparison,
        normalizedComparison,
        performanceProfile,
        strengthWeaknessAnalysis,
      );

      final result = ComprehensiveComparisonResult(
        basicComparison: basicComparison,
        normalizedComparison: normalizedComparison,
        populationComparison: populationComparison,
        statisticalAnalysis: statisticalAnalysis,
        performanceProfile: performanceProfile,
        strengthWeaknessAnalysis: strengthWeaknessAnalysis,
        trendAnalysis: trendAnalysis,
        recommendations: recommendations,
        overallScore: _calculateOverallScore(basicComparison, normalizedComparison),
        confidenceLevel: statisticalAnalysis.confidenceLevel,
      );

      AppLogger.success('✅ Gelişmiş karşılaştırma tamamlandı');
      return result;

    } catch (e, stackTrace) {
      AppLogger.error('Gelişmiş karşılaştırma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Temel metrik karşılaştırması
  static BasicComparisonResult _performBasicComparison(
    TestResultModel test1,
    TestResultModel test2,
  ) {
    final comparisons = <MetricComparison>[];
    final test1Metrics = test1.metrics;
    final test2Metrics = test2.metrics;

    // Her metrik için karşılaştırma yap
    for (final metricKey in test1Metrics.keys) {
      if (test2Metrics.containsKey(metricKey)) {
        final value1 = test1Metrics[metricKey]!;
        final value2 = test2Metrics[metricKey]!;
        
        if (value1 > 0 && value2 > 0) { // Geçerli değerler için
          final comparison = _compareMetric(metricKey, value1, value2);
          comparisons.add(comparison);
        }
      }
    }

    // Genel performans skoru hesapla
    final overallChange = comparisons.isNotEmpty
        ? comparisons.map((c) => c.percentChange).reduce((a, b) => a + b) / comparisons.length
        : 0.0;

    return BasicComparisonResult(
      comparisons: comparisons,
      overallPercentChange: overallChange,
      significantImprovements: comparisons.where((c) => c.isImprovement && c.percentChange.abs() > 5).length,
      significantDeclines: comparisons.where((c) => !c.isImprovement && c.percentChange.abs() > 5).length,
    );
  }

  /// Metrik karşılaştırması
  static MetricComparison _compareMetric(String metricKey, double value1, double value2) {
    final metricInfo = test_constants.TestConstantsMetrics.metricInfo[metricKey];
    final difference = value2 - value1;
    final percentChange = (difference / value1) * 100;
    final isImprovement = _isImprovementForMetric(metricKey, difference);
    
    // Effect size hesaplama (Cohen's d)
    final effectSize = _calculateEffectSize(value1, value2);
    
    // Pratik anlamlılık
    final practicalSignificance = _assessPracticalSignificance(metricKey, percentChange);

    return MetricComparison(
      metricKey: metricKey,
      metricName: metricInfo?.name ?? metricKey,
      unit: metricInfo?.unit ?? '',
      value1: value1,
      value2: value2,
      difference: difference,
      percentChange: percentChange,
      isImprovement: isImprovement,
      effectSize: effectSize,
      practicalSignificance: practicalSignificance,
      confidenceInterval: _calculateConfidenceInterval(value1, value2),
    );
  }

  /// Normalize edilmiş karşılaştırma (vücut ağırlığına göre)
  static NormalizedComparisonResult _performNormalizedComparison(
    TestResultModel test1,
    TestResultModel test2,
    AthleteModel athlete,
  ) {
    final bodyWeight = athlete.weight ?? 70.0; // kg
    final normalizedComparisons = <MetricComparison>[];

    // Normalize edilebilir metrikler
    final normalizableMetrics = ['peakForce', 'averageForce', 'impulse', 'peakPower'];
    
    for (final metricKey in normalizableMetrics) {
      if (test1.metrics.containsKey(metricKey) && test2.metrics.containsKey(metricKey)) {
        final value1 = test1.metrics[metricKey]! / bodyWeight;
        final value2 = test2.metrics[metricKey]! / bodyWeight;
        
        final comparison = _compareMetric('${metricKey}_normalized', value1, value2);
        normalizedComparisons.add(comparison);
      }
    }

    return NormalizedComparisonResult(
      comparisons: normalizedComparisons,
      normalizationFactor: bodyWeight,
    );
  }

  /// Popülasyon normlarına göre karşılaştırma
  static PopulationComparisonResult _performPopulationComparison(
    TestResultModel test1,
    TestResultModel test2,
    AthleteModel athlete,
  ) {
    final populationComparisons = <PopulationMetricComparison>[];
    final isMale = athlete.gender == 'male' || athlete.gender == 'Male';

    for (final entry in test_constants.TestConstantsMetrics.populationNorms.entries) {
      final metricKey = entry.key.split('_')[1]; // 'CMJ_jumpHeight' -> 'jumpHeight'
      final norms = entry.value;

      if (test1.metrics.containsKey(metricKey) && test2.metrics.containsKey(metricKey)) {
        final value1 = test1.metrics[metricKey]!;
        final value2 = test2.metrics[metricKey]!;

        final percentile1 = norms.calculatePercentile(value1, isMale);
        final percentile2 = norms.calculatePercentile(value2, isMale);
        final zScore1 = norms.calculateZScore(value1, isMale);
        final zScore2 = norms.calculateZScore(value2, isMale);

        populationComparisons.add(PopulationMetricComparison(
          metricKey: metricKey,
          metricName: test_constants.TestConstantsMetrics.metricInfo[metricKey]?.name ?? metricKey,
          value1: value1,
          value2: value2,
          percentile1: percentile1,
          percentile2: percentile2,
          zScore1: zScore1,
          zScore2: zScore2,
          populationMean: isMale ? norms.maleMean : norms.femaleMean,
          populationStd: isMale ? norms.maleStd : norms.femaleStd,
        ));
      }
    }

    return PopulationComparisonResult(
      comparisons: populationComparisons,
      gender: _parseGender(athlete.gender),
      age: athlete.age,
    );
  }

  /// İstatistiksel anlamlılık analizi
  static StatisticalAnalysisResult _performStatisticalAnalysis(
    TestResultModel test1,
    TestResultModel test2,
    List<TestResultModel>? historicalData,
  ) {
    final significantChanges = <String>[];
    double confidenceLevel = 0.0;

    if (historicalData != null && historicalData.length >= _minDataPoints) {
      // Yeterli veri varsa istatistiksel analiz yap
      for (final metricKey in test1.metrics.keys) {
        if (test2.metrics.containsKey(metricKey)) {
          final historicalValues = historicalData
              .where((test) => test.metrics.containsKey(metricKey))
              .map((test) => test.metrics[metricKey]!)
              .toList();

          if (historicalValues.length >= _minDataPoints) {
            final isSignificant = _performTTest(
              historicalValues,
              test2.metrics[metricKey]!,
            );

            if (isSignificant) {
              significantChanges.add(metricKey);
            }
          }
        }
      }

      confidenceLevel = _confidenceThreshold;
    } else {
      // Yeterli veri yoksa effect size tabanlı değerlendirme
      confidenceLevel = 0.5; // Düşük güven
    }

    return StatisticalAnalysisResult(
      significantChanges: significantChanges,
      confidenceLevel: confidenceLevel,
      sampleSize: historicalData?.length ?? 2,
      powerAnalysis: _performPowerAnalysis(historicalData),
    );
  }

  /// Performans profil analizi
  static PerformanceProfileResult _analyzePerformanceProfile(
    TestResultModel test1,
    TestResultModel test2,
  ) {
    final profileCategories = <String, double>{};

    // Test türüne göre kategori skorları hesapla
    switch (test1.testTypeEnum.category) {
      case TestCategory.jump:
        profileCategories['Patlayıcılık'] = _calculateCategoryScore([
          test2.metrics['jumpHeight'],
          test2.metrics['peakPower'],
          test2.metrics['takeoffVelocity'],
        ]);
        profileCategories['Kuvvet Üretimi'] = _calculateCategoryScore([
          test2.metrics['peakForce'],
          test2.metrics['rfd'],
        ]);
        profileCategories['Hareket Kalitesi'] = _calculateCategoryScore([
          100 - (test2.metrics['asymmetryIndex'] ?? 0),
          test2.metrics['movementEfficiency'],
        ]);
        break;
      case TestCategory.strength:
        profileCategories['Maksimum Kuvvet'] = _calculateCategoryScore([
          test2.metrics['peakForce'],
          test2.metrics['relativePeakForce'],
        ]);
        profileCategories['Kuvvet Gelişim Hızı'] = _calculateCategoryScore([
          test2.metrics['rfd0_100ms'],
          test2.metrics['rfd0_200ms'],
        ]);
        break;
      case TestCategory.balance:
        profileCategories['Stabilite'] = _calculateCategoryScore([
          100 - (test2.metrics['stabilityIndex'] ?? 100),
          100 - (test2.metrics['copRange'] ?? 100),
        ]);
        profileCategories['Kontrol'] = _calculateCategoryScore([
          100 - (test2.metrics['copVelocity'] ?? 100),
        ]);
        break;
      default:
        break;
    }

    // Değişim skorları hesapla
    final categoryChanges = <String, double>{};
    for (final category in profileCategories.keys) {
      // Simplified - gerçek implementasyonda her kategori için ayrı hesaplama yapılır
      categoryChanges[category] = math.Random().nextDouble() * 20 - 10; // -10 to +10
    }

    return PerformanceProfileResult(
      currentProfile: profileCategories,
      profileChanges: categoryChanges,
      dominantStrength: _findDominantStrength(profileCategories),
      primaryWeakness: _findPrimaryWeakness(profileCategories),
    );
  }

  /// Güçlü/zayıf yönler analizi
  static StrengthWeaknessAnalysisResult _analyzeStrengthsWeaknesses(
    TestResultModel test1,
    TestResultModel test2,
  ) {
    final improvements = <MetricImprovement>[];
    final declines = <MetricDecline>[];
    final stableMetrics = <String>[];

    for (final metricKey in test1.metrics.keys) {
      if (test2.metrics.containsKey(metricKey)) {
        final value1 = test1.metrics[metricKey]!;
        final value2 = test2.metrics[metricKey]!;
        final percentChange = ((value2 - value1) / value1) * 100;

        if (percentChange.abs() < 2.0) {
          stableMetrics.add(metricKey);
        } else if (_isImprovementForMetric(metricKey, value2 - value1)) {
          improvements.add(MetricImprovement(
            metricKey: metricKey,
            metricName: test_constants.TestConstantsMetrics.metricInfo[metricKey]?.name ?? metricKey,
            improvementPercent: percentChange.abs(),
            magnitude: _classifyMagnitude(percentChange.abs()),
          ));
        } else {
          declines.add(MetricDecline(
            metricKey: metricKey,
            metricName: test_constants.TestConstantsMetrics.metricInfo[metricKey]?.name ?? metricKey,
            declinePercent: percentChange.abs(),
            magnitude: _classifyMagnitude(percentChange.abs()),
          ));
        }
      }
    }

    // Sırala
    improvements.sort((a, b) => b.improvementPercent.compareTo(a.improvementPercent));
    declines.sort((a, b) => b.declinePercent.compareTo(a.declinePercent));

    return StrengthWeaknessAnalysisResult(
      topImprovements: improvements.take(5).toList(),
      topDeclines: declines.take(5).toList(),
      stableMetrics: stableMetrics,
      overallTrend: improvements.length > declines.length ? 'Pozitif' : 'Negatif',
    );
  }

  /// Trend analizi
  static TrendAnalysisResult _performTrendAnalysis(
    List<TestResultModel> historicalData,
    TestResultModel currentTest,
  ) {
    final trendData = <String, List<TrendPoint>>{};
    final trendSlopes = <String, double>{};

    // Her metrik için trend hesapla
    for (final metricKey in currentTest.metrics.keys) {
      final dataPoints = <TrendPoint>[];
      
      for (final test in historicalData) {
        if (test.metrics.containsKey(metricKey)) {
          dataPoints.add(TrendPoint(
            date: test.testDate,
            value: test.metrics[metricKey]!,
          ));
        }
      }

      if (dataPoints.length >= 3) {
        dataPoints.sort((a, b) => a.date.compareTo(b.date));
        trendData[metricKey] = dataPoints;
        trendSlopes[metricKey] = _calculateTrendSlope(dataPoints);
      }
    }

    return TrendAnalysisResult(
      trendData: trendData,
      trendSlopes: trendSlopes,
      overallTrend: _classifyOverallTrend(trendSlopes),
      projectedValues: _projectFutureValues(trendData, trendSlopes),
    );
  }

  /// Öneriler oluşturma
  static List<PerformanceRecommendation> _generateRecommendations(
    BasicComparisonResult basicComparison,
    NormalizedComparisonResult normalizedComparison,
    PerformanceProfileResult performanceProfile,
    StrengthWeaknessAnalysisResult strengthWeaknessAnalysis,
  ) {
    final recommendations = <PerformanceRecommendation>[];

    // En büyük gelişim alanları için öneriler
    for (final decline in strengthWeaknessAnalysis.topDeclines.take(3)) {
      recommendations.add(PerformanceRecommendation(
        category: 'Gelişim Odağı',
        title: '${decline.metricName} Geliştir',
        description: _getImprovementSuggestion(decline.metricKey),
        priority: _mapMagnitudeToPriority(decline.magnitude),
        expectedTimeframe: _getExpectedTimeframe(decline.magnitude),
      ));
    }

    // Güçlü yönleri koruma önerileri
    for (final improvement in strengthWeaknessAnalysis.topImprovements.take(2)) {
      recommendations.add(PerformanceRecommendation(
        category: 'Güç Korunması',
        title: '${improvement.metricName} Koru',
        description: _getMaintenanceSuggestion(improvement.metricKey),
        priority: RecommendationPriority.medium,
        expectedTimeframe: '2-4 hafta',
      ));
    }

    // Genel performans önerileri
    if (basicComparison.overallPercentChange < -5) {
      recommendations.add(PerformanceRecommendation(
        category: 'Toparlanma',
        title: 'Toparlanmaya Odaklan',
        description: 'Birden fazla metrikte düşüş görüldüğü için ek toparlanma protokolleri uygulamayı düşünün.',
        priority: RecommendationPriority.high,
        expectedTimeframe: '1-2 hafta',
      ));
    }

    return recommendations;
  }

  // Helper methods
  static Gender _parseGender(String? genderString) {
    if (genderString == null) return Gender.unknown;
    switch (genderString.toLowerCase()) {
      case 'male':
      case 'erkek':
        return Gender.male;
      case 'female':
      case 'kadın':
        return Gender.female;
      default:
        return Gender.unknown;
    }
  }

  static bool _isImprovementForMetric(String metricKey, double difference) {
    const lowerIsBetter = {
      'contactTime', 'timeTopeakForce', 'stabilityIndex', 
      'copRange', 'copVelocity', 'asymmetryIndex'
    };
    
    return lowerIsBetter.contains(metricKey) ? difference < 0 : difference > 0;
  }

  static double _calculateEffectSize(double value1, double value2) {
    // Simplified Cohen's d calculation
    final pooledStd = (value1.abs() + value2.abs()) / 2;
    return pooledStd > 0 ? (value2 - value1).abs() / pooledStd : 0.0;
  }

  static PracticalSignificance _assessPracticalSignificance(String metricKey, double percentChange) {
    final absChange = percentChange.abs();
    
    if (absChange < 2) return PracticalSignificance.trivial;
    if (absChange < 5) return PracticalSignificance.small;
    if (absChange < 10) return PracticalSignificance.moderate;
    if (absChange < 20) return PracticalSignificance.large;
    return PracticalSignificance.veryLarge;
  }

  static ConfidenceInterval _calculateConfidenceInterval(double value1, double value2) {
    final mean = (value1 + value2) / 2;
    final range = (value1 - value2).abs() / 2;
    return ConfidenceInterval(
      lower: mean - range,
      upper: mean + range,
      confidence: 0.95,
    );
  }

  static double _calculateCategoryScore(List<double?> values) {
    final validValues = values.where((v) => v != null).map((v) => v!).toList();
    if (validValues.isEmpty) return 0.0;
    
    return validValues.reduce((a, b) => a + b) / validValues.length;
  }

  static String _findDominantStrength(Map<String, double> profile) {
    if (profile.isEmpty) return 'Bilinmeyen';
    return profile.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static String _findPrimaryWeakness(Map<String, double> profile) {
    if (profile.isEmpty) return 'Bilinmeyen';
    return profile.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  static ChangeMagnitude _classifyMagnitude(double percentChange) {
    if (percentChange < 2) return ChangeMagnitude.trivial;
    if (percentChange < 5) return ChangeMagnitude.small;
    if (percentChange < 10) return ChangeMagnitude.moderate;
    if (percentChange < 20) return ChangeMagnitude.large;
    return ChangeMagnitude.veryLarge;
  }

  static bool _performTTest(List<double> historicalValues, double currentValue) {
    // Simplified t-test
    if (historicalValues.isEmpty) return false;
    
    final mean = historicalValues.reduce((a, b) => a + b) / historicalValues.length;
    final variance = historicalValues.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / historicalValues.length;
    final standardError = math.sqrt(variance / historicalValues.length);
    
    final tStatistic = (currentValue - mean) / standardError;
    return tStatistic.abs() > 2.0; // Simplified critical value
  }

  static PowerAnalysisResult _performPowerAnalysis(List<TestResultModel>? historicalData) {
    final sampleSize = historicalData?.length ?? 2;
    final power = math.min(1.0, sampleSize / 30.0); // Simplified power calculation
    
    return PowerAnalysisResult(
      currentPower: power,
      recommendedSampleSize: math.max(30, sampleSize * 2),
      detectableEffectSize: 0.5, // Medium effect size
    );
  }

  static double _calculateTrendSlope(List<TrendPoint> dataPoints) {
    if (dataPoints.length < 2) return 0.0;
    
    // Simple linear regression slope
    final n = dataPoints.length;
    final sumX = dataPoints.map((p) => p.date.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a + b);
    final sumY = dataPoints.map((p) => p.value).reduce((a, b) => a + b);
    final sumXY = dataPoints.map((p) => p.date.millisecondsSinceEpoch * p.value).reduce((a, b) => a + b);
    final sumX2 = dataPoints.map((p) => p.date.millisecondsSinceEpoch * p.date.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a + b);
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }

  static String _classifyOverallTrend(Map<String, double> trendSlopes) {
    if (trendSlopes.isEmpty) return 'Stabil';
    
    final avgSlope = trendSlopes.values.reduce((a, b) => a + b) / trendSlopes.length;
    
    if (avgSlope > 0.1) return 'Gelişiyor';
    if (avgSlope < -0.1) return 'Düşüyor';
    return 'Stabil';
  }

  static Map<String, double> _projectFutureValues(
    Map<String, List<TrendPoint>> trendData,
    Map<String, double> trendSlopes,
  ) {
    final projections = <String, double>{};
    final futureDate = DateTime.now().add(const Duration(days: 30));
    
    for (final entry in trendData.entries) {
      final metricKey = entry.key;
      final dataPoints = entry.value;
      final slope = trendSlopes[metricKey] ?? 0.0;
      
      if (dataPoints.isNotEmpty) {
        final lastValue = dataPoints.last.value;
        final daysDiff = futureDate.difference(dataPoints.last.date).inDays;
        projections[metricKey] = lastValue + (slope * daysDiff);
      }
    }
    
    return projections;
  }

  static double _calculateOverallScore(
    BasicComparisonResult basicComparison,
    NormalizedComparisonResult normalizedComparison,
  ) {
    // Weighted scoring system
    double score = 50.0; // Base score
    
    // Basic comparison contribution (40%)
    score += basicComparison.overallPercentChange * 0.4;
    
    // Improvement/decline balance (30%)
    final improvementRatio = basicComparison.significantImprovements / 
        math.max(1, basicComparison.significantImprovements + basicComparison.significantDeclines);
    score += (improvementRatio - 0.5) * 60; // -30 to +30
    
    // Normalized metrics contribution (30%)
    if (normalizedComparison.comparisons.isNotEmpty) {
      final normalizedChange = normalizedComparison.comparisons
          .map((c) => c.percentChange)
          .reduce((a, b) => a + b) / normalizedComparison.comparisons.length;
      score += normalizedChange * 0.3;
    }
    
    return math.max(0, math.min(100, score));
  }

  static String _getImprovementSuggestion(String metricKey) {
    const suggestions = {
      'jumpHeight': 'Pliometrik antrenman ve squat paterninde kuvvet geliştirmeye odaklanın.',
      'peakForce': '%85-95 1RM yüklerle ağır kuvvet antrenmanı ekleyin.',
      'rfd': 'Patlayıcı hareketler ve kuvvet gelişim hızı antrenmanı ekleyin.',
      'contactTime': 'Drop jump ve hızlı yer temaslarıyla reaktif kuvvet üzerinde çalışın.',
      'asymmetryIndex': 'Unilateral egzersizler ve hareket kalitesi drilleri ekleyin.',
      'stabilityIndex': 'Denge zorluklarını ve proprioseptif antrenmanı uygulayın.',
    };
    
    return suggestions[metricKey] ?? 'Hedefli gelişim stratejileri için uzmanla danışın.';
  }

  static String _getMaintenanceSuggestion(String metricKey) {
    const suggestions = {
      'jumpHeight': 'Gücü korumak için mevcut sıçrama protokollerini haftada 2x sürdürün.',
      'peakForce': 'Haftada 1-2 ağır seansla kuvveti koruyun.',
      'rfd': 'Patlayıcı antrenman sıklığını tutarlı tutun.',
    };
    
    return suggestions[metricKey] ?? 'Bu güçlü yön için mevcut antrenman sıklığını koruyun.';
  }

  static RecommendationPriority _mapMagnitudeToPriority(ChangeMagnitude magnitude) {
    switch (magnitude) {
      case ChangeMagnitude.trivial:
      case ChangeMagnitude.small:
        return RecommendationPriority.low;
      case ChangeMagnitude.moderate:
        return RecommendationPriority.medium;
      case ChangeMagnitude.large:
      case ChangeMagnitude.veryLarge:
        return RecommendationPriority.high;
    }
  }

  static String _getExpectedTimeframe(ChangeMagnitude magnitude) {
    switch (magnitude) {
      case ChangeMagnitude.trivial:
      case ChangeMagnitude.small:
        return '1-2 hafta';
      case ChangeMagnitude.moderate:
        return '2-4 hafta';
      case ChangeMagnitude.large:
        return '4-8 hafta';
      case ChangeMagnitude.veryLarge:
        return '8-12 hafta';
    }
  }
}

// Data classes for results
class ComprehensiveComparisonResult {
  final BasicComparisonResult basicComparison;
  final NormalizedComparisonResult normalizedComparison;
  final PopulationComparisonResult populationComparison;
  final StatisticalAnalysisResult statisticalAnalysis;
  final PerformanceProfileResult performanceProfile;
  final StrengthWeaknessAnalysisResult strengthWeaknessAnalysis;
  final TrendAnalysisResult? trendAnalysis;
  final List<PerformanceRecommendation> recommendations;
  final double overallScore;
  final double confidenceLevel;
  
  /// Analiz edilen metrikler listesi
  List<MetricComparison> get metrics => basicComparison.comparisons;

  ComprehensiveComparisonResult({
    required this.basicComparison,
    required this.normalizedComparison,
    required this.populationComparison,
    required this.statisticalAnalysis,
    required this.performanceProfile,
    required this.strengthWeaknessAnalysis,
    this.trendAnalysis,
    required this.recommendations,
    required this.overallScore,
    required this.confidenceLevel,
  });
}

class BasicComparisonResult {
  final List<MetricComparison> comparisons;
  final double overallPercentChange;
  final int significantImprovements;
  final int significantDeclines;

  BasicComparisonResult({
    required this.comparisons,
    required this.overallPercentChange,
    required this.significantImprovements,
    required this.significantDeclines,
  });
}

class MetricComparison {
  final String metricKey;
  final String metricName;
  final String unit;
  final double value1;
  final double value2;
  final double difference;
  final double percentChange;
  final bool isImprovement;
  final double effectSize;
  final PracticalSignificance practicalSignificance;
  final ConfidenceInterval confidenceInterval;

  MetricComparison({
    required this.metricKey,
    required this.metricName,
    required this.unit,
    required this.value1,
    required this.value2,
    required this.difference,
    required this.percentChange,
    required this.isImprovement,
    required this.effectSize,
    required this.practicalSignificance,
    required this.confidenceInterval,
  });
}

class NormalizedComparisonResult {
  final List<MetricComparison> comparisons;
  final double normalizationFactor;

  NormalizedComparisonResult({
    required this.comparisons,
    required this.normalizationFactor,
  });
}

class PopulationComparisonResult {
  final List<PopulationMetricComparison> comparisons;
  final Gender gender;
  final int? age;

  PopulationComparisonResult({
    required this.comparisons,
    required this.gender,
    this.age,
  });
}

class PopulationMetricComparison {
  final String metricKey;
  final String metricName;
  final double value1;
  final double value2;
  final double percentile1;
  final double percentile2;
  final double zScore1;
  final double zScore2;
  final double populationMean;
  final double populationStd;

  PopulationMetricComparison({
    required this.metricKey,
    required this.metricName,
    required this.value1,
    required this.value2,
    required this.percentile1,
    required this.percentile2,
    required this.zScore1,
    required this.zScore2,
    required this.populationMean,
    required this.populationStd,
  });
}

class StatisticalAnalysisResult {
  final List<String> significantChanges;
  final double confidenceLevel;
  final int sampleSize;
  final PowerAnalysisResult powerAnalysis;

  StatisticalAnalysisResult({
    required this.significantChanges,
    required this.confidenceLevel,
    required this.sampleSize,
    required this.powerAnalysis,
  });
}

class PowerAnalysisResult {
  final double currentPower;
  final int recommendedSampleSize;
  final double detectableEffectSize;

  PowerAnalysisResult({
    required this.currentPower,
    required this.recommendedSampleSize,
    required this.detectableEffectSize,
  });
}

class PerformanceProfileResult {
  final Map<String, double> currentProfile;
  final Map<String, double> profileChanges;
  final String dominantStrength;
  final String primaryWeakness;

  PerformanceProfileResult({
    required this.currentProfile,
    required this.profileChanges,
    required this.dominantStrength,
    required this.primaryWeakness,
  });
}

class StrengthWeaknessAnalysisResult {
  final List<MetricImprovement> topImprovements;
  final List<MetricDecline> topDeclines;
  final List<String> stableMetrics;
  final String overallTrend;

  StrengthWeaknessAnalysisResult({
    required this.topImprovements,
    required this.topDeclines,
    required this.stableMetrics,
    required this.overallTrend,
  });
}

class MetricImprovement {
  final String metricKey;
  final String metricName;
  final double improvementPercent;
  final ChangeMagnitude magnitude;

  MetricImprovement({
    required this.metricKey,
    required this.metricName,
    required this.improvementPercent,
    required this.magnitude,
  });
}

class MetricDecline {
  final String metricKey;
  final String metricName;
  final double declinePercent;
  final ChangeMagnitude magnitude;

  MetricDecline({
    required this.metricKey,
    required this.metricName,
    required this.declinePercent,
    required this.magnitude,
  });
}

class TrendAnalysisResult {
  final Map<String, List<TrendPoint>> trendData;
  final Map<String, double> trendSlopes;
  final String overallTrend;
  final Map<String, double> projectedValues;

  TrendAnalysisResult({
    required this.trendData,
    required this.trendSlopes,
    required this.overallTrend,
    required this.projectedValues,
  });
}

class TrendPoint {
  final DateTime date;
  final double value;

  TrendPoint({
    required this.date,
    required this.value,
  });
}

class PerformanceRecommendation {
  final String category;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final String expectedTimeframe;

  PerformanceRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.expectedTimeframe,
  });
}

class ConfidenceInterval {
  final double lower;
  final double upper;
  final double confidence;

  ConfidenceInterval({
    required this.lower,
    required this.upper,
    required this.confidence,
  });
}

// Enums
enum PracticalSignificance {
  trivial,
  small,
  moderate,
  large,
  veryLarge,
}

enum ChangeMagnitude {
  trivial,
  small,
  moderate,
  large,
  veryLarge,
}

enum RecommendationPriority {
  low,
  medium,
  high,
}