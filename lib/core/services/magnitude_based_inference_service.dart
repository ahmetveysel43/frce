import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../algorithms/statistics_helper.dart';

/// Magnitude-Based Inference Service - Hopkins et al. (2009)
/// Praktik anlamlılık değerlendirmesi için istatistiksel çıkarım
/// "Progressive statistics for studies in sports medicine and exercise science"
class MagnitudeBasedInferenceService {
  static final _stats = StatisticsHelper();
  
  /// Hopkins metodolojisi kullanarak pratik anlamlılık analizi
  static MBIResult analyzePracticalSignificance({
    required List<double> baseline,
    required List<double> current,
    required double smallestWorthwhileChange,
    double? typicalError,
    String testType = 'unknown',
  }) {
    debugPrint('🔬 MBI Analysis başlatıldı: ${baseline.length} baseline, ${current.length} current');
    
    if (baseline.isEmpty || current.isEmpty) {
      return MBIResult.error('Yetersiz veri: baseline=${baseline.length}, current=${current.length}');
    }

    // Calculate means and differences
    final baselineMean = _stats.calculateMean(baseline);
    final currentMean = _stats.calculateMean(current);
    final observedChange = currentMean - baselineMean;
    final percentChange = baselineMean != 0 ? (observedChange / baselineMean) * 100 : 0.0;

    // Calculate typical error if not provided
    final calculatedTE = typicalError ?? _calculateTypicalError(baseline, current);
    
    // Calculate change in error (uncertainty)
    final changeError = _calculateChangeError(baseline, current, calculatedTE);
    
    // Calculate probabilities using normal distribution
    final probabilities = _calculateProbabilities(observedChange, changeError, smallestWorthwhileChange);
    
    // Determine qualitative inference
    final qualitativeInference = _determineQualitativeInference(probabilities);
    
    // Calculate magnitude categories
    final magnitude = _calculateMagnitude(observedChange, smallestWorthwhileChange);
    
    // Generate clinical interpretation
    final interpretation = _generateInterpretation(
      qualitativeInference, 
      magnitude, 
      percentChange, 
      testType,
    );

    return MBIResult(
      observedChange: observedChange,
      percentChange: percentChange,
      smallestWorthwhileChange: smallestWorthwhileChange,
      typicalError: calculatedTE,
      changeError: changeError,
      probabilities: probabilities,
      qualitativeInference: qualitativeInference,
      magnitude: magnitude,
      interpretation: interpretation,
      confidence: _calculateConfidence(probabilities),
      isSignificant: qualitativeInference.category != MBICategory.unclear,
      sampleSizes: {
        'baseline': baseline.length,
        'current': current.length,
      },
    );
  }

  /// Multiple time points için trend analizi
  static MBITrendResult analyzeTrend({
    required List<List<double>> timePoints,
    required List<DateTime> dates,
    required double smallestWorthwhileChange,
    String testType = 'unknown',
  }) {
    debugPrint('🔬 MBI Trend Analysis başlatıldı: ${timePoints.length} time points');
    
    if (timePoints.length < 3) {
      return MBITrendResult.error('Trend analizi için minimum 3 zaman noktası gerekli');
    }

    final results = <MBIResult>[];
    
    // Sequential pairwise comparisons
    for (int i = 1; i < timePoints.length; i++) {
      final result = analyzePracticalSignificance(
        baseline: timePoints[i - 1],
        current: timePoints[i],
        smallestWorthwhileChange: smallestWorthwhileChange,
        testType: testType,
      );
      results.add(result);
    }
    
    // Overall trend analysis
    final overallTrend = _calculateOverallTrend(results);
    final consistency = _calculateTrendConsistency(results);
    final progressionRate = _calculateProgressionRate(results, dates);
    
    return MBITrendResult(
      pairwiseResults: results,
      overallTrend: overallTrend,
      consistency: consistency,
      progressionRate: progressionRate,
      recommendation: _generateTrendRecommendation(overallTrend, consistency),
    );
  }

  /// Group comparison için MBI analizi
  static MBIGroupResult compareGroups({
    required Map<String, List<double>> groups,
    required double smallestWorthwhileChange,
    String? referenceGroup,
  }) {
    debugPrint('🔬 MBI Group Comparison: ${groups.keys.join(', ')}');
    
    if (groups.length < 2) {
      return MBIGroupResult.error('En az 2 grup karşılaştırması gerekli');
    }

    final comparisons = <String, MBIResult>{};
    final reference = referenceGroup ?? groups.keys.first;
    final referenceData = groups[reference]!;
    
    for (final entry in groups.entries) {
      if (entry.key != reference) {
        final result = analyzePracticalSignificance(
          baseline: referenceData,
          current: entry.value,
          smallestWorthwhileChange: smallestWorthwhileChange,
        );
        comparisons['${entry.key} vs $reference'] = result;
      }
    }
    
    return MBIGroupResult(
      referenceGroup: reference,
      comparisons: comparisons,
      overallPattern: _analyzeGroupPattern(comparisons),
    );
  }

  // Helper Methods

  /// Typical Error hesaplama (within-subject SD)
  static double _calculateTypicalError(List<double> baseline, List<double> current) {
    // Pool within-subject standard deviations
    final baselineSD = _stats.calculateStandardDeviation(baseline);
    final currentSD = _stats.calculateStandardDeviation(current);
    
    // Pooled standard deviation
    final pooledSD = math.sqrt((math.pow(baselineSD, 2) + math.pow(currentSD, 2)) / 2);
    
    // Typical error is pooled SD divided by sqrt(2) for difference scores
    return pooledSD / math.sqrt(2);
  }

  /// Change Error hesaplama
  static double _calculateChangeError(List<double> baseline, List<double> current, double typicalError) {
    final n1 = baseline.length;
    final n2 = current.length;
    
    // Standard error of the difference
    return typicalError * math.sqrt((1 / n1) + (1 / n2));
  }

  /// Probability hesaplamaları (Hopkins formulae)
  static MBIProbabilities _calculateProbabilities(
    double observedChange, 
    double changeError, 
    double swc,
  ) {
    // Z-scores for beneficial and harmful thresholds
    final zBeneficial = (observedChange - swc) / changeError;
    final zHarmful = (observedChange + swc) / changeError;
    
    // Probabilities using cumulative normal distribution
    final probBeneficial = _normalCDF(zBeneficial) * 100;
    final probHarmful = (1 - _normalCDF(zHarmful)) * 100;
    final probTrivial = 100 - probBeneficial - probHarmful;
    
    return MBIProbabilities(
      beneficial: probBeneficial.clamp(0, 100),
      trivial: probTrivial.clamp(0, 100),
      harmful: probHarmful.clamp(0, 100),
    );
  }

  /// Qualitative inference belirleme (Hopkins criteria)
  static MBIQualitativeInference _determineQualitativeInference(MBIProbabilities prob) {
    final beneficial = prob.beneficial;
    final harmful = prob.harmful;
    final trivial = prob.trivial;
    
    // Hopkins' qualitative inference rules
    if (beneficial >= 99) {
      return MBIQualitativeInference(
        category: MBICategory.almostCertainlyBeneficial,
        description: 'Neredeyse kesinlikle faydalı',
        certainty: 'Çok olası',
      );
    } else if (beneficial >= 95 && harmful < 5) {
      return MBIQualitativeInference(
        category: MBICategory.veryLikelyBeneficial,
        description: 'Çok muhtemelen faydalı',
        certainty: 'Çok olası',
      );
    } else if (beneficial >= 75 && harmful < 25) {
      return MBIQualitativeInference(
        category: MBICategory.likelyBeneficial,
        description: 'Muhtemelen faydalı',
        certainty: 'Olası',
      );
    } else if (beneficial >= 50 && harmful < 25) {
      return MBIQualitativeInference(
        category: MBICategory.possiblyBeneficial,
        description: 'Olasılıkla faydalı',
        certainty: 'Mümkün',
      );
    } else if (harmful >= 99) {
      return MBIQualitativeInference(
        category: MBICategory.almostCertainlyHarmful,
        description: 'Neredeyse kesinlikle zararlı',
        certainty: 'Çok olası',
      );
    } else if (harmful >= 95 && beneficial < 5) {
      return MBIQualitativeInference(
        category: MBICategory.veryLikelyHarmful,
        description: 'Çok muhtemelen zararlı',
        certainty: 'Çok olası',
      );
    } else if (harmful >= 75 && beneficial < 25) {
      return MBIQualitativeInference(
        category: MBICategory.likelyHarmful,
        description: 'Muhtemelen zararlı',
        certainty: 'Olası',
      );
    } else if (harmful >= 50 && beneficial < 25) {
      return MBIQualitativeInference(
        category: MBICategory.possiblyHarmful,
        description: 'Olasılıkla zararlı',
        certainty: 'Mümkün',
      );
    } else if (trivial >= 90) {
      return MBIQualitativeInference(
        category: MBICategory.mostLikelyTrivial,
        description: 'Büyük olasılıkla önemsiz',
        certainty: 'Çok olası',
      );
    } else {
      return MBIQualitativeInference(
        category: MBICategory.unclear,
        description: 'Belirsiz - çelişkili kanıt',
        certainty: 'Belirsiz',
      );
    }
  }

  /// Magnitude hesaplama
  static MBIMagnitude _calculateMagnitude(double change, double swc) {
    final ratio = change.abs() / swc;
    
    if (ratio < 0.2) {
      return MBIMagnitude.trivial;
    } else if (ratio < 0.6) {
      return MBIMagnitude.small;
    } else if (ratio < 1.2) {
      return MBIMagnitude.moderate;
    } else if (ratio < 2.0) {
      return MBIMagnitude.large;
    } else if (ratio < 4.0) {
      return MBIMagnitude.veryLarge;
    } else {
      return MBIMagnitude.extremelyLarge;
    }
  }

  /// Clinical interpretation oluşturma
  static String _generateInterpretation(
    MBIQualitativeInference inference,
    MBIMagnitude magnitude,
    double percentChange,
    String testType,
  ) {
    final direction = percentChange >= 0 ? 'iyileşme' : 'kötüleşme';
    final magnitudeText = _getMagnitudeText(magnitude);
    
    return '${inference.description} $magnitudeText $direction '
           '(%${percentChange.abs().toStringAsFixed(1)}). '
           '${_getTestSpecificAdvice(testType, inference.category, magnitude)}';
  }

  static String _getMagnitudeText(MBIMagnitude magnitude) {
    switch (magnitude) {
      case MBIMagnitude.trivial: return 'önemsiz';
      case MBIMagnitude.small: return 'küçük';
      case MBIMagnitude.moderate: return 'orta';
      case MBIMagnitude.large: return 'büyük';
      case MBIMagnitude.veryLarge: return 'çok büyük';
      case MBIMagnitude.extremelyLarge: return 'aşırı büyük';
    }
  }

  static String _getTestSpecificAdvice(String testType, MBICategory category, MBIMagnitude magnitude) {
    if (category == MBICategory.unclear) {
      return 'Daha fazla veri toplanması öneriliyor.';
    }
    
    final isBeneficial = [
      MBICategory.possiblyBeneficial,
      MBICategory.likelyBeneficial,
      MBICategory.veryLikelyBeneficial,
      MBICategory.almostCertainlyBeneficial,
    ].contains(category);
    
    if (isBeneficial) {
      return 'Mevcut program devam ettirilebilir.';
    } else {
      return 'Program modifikasyonu düşünülmelidir.';
    }
  }

  /// Confidence hesaplama
  static double _calculateConfidence(MBIProbabilities probabilities) {
    final maxProb = [probabilities.beneficial, probabilities.trivial, probabilities.harmful]
        .reduce(math.max);
    return maxProb / 100;
  }

  /// Normal CDF approximation
  static double _normalCDF(double z) {
    return 0.5 * (1 + _erf(z / math.sqrt(2)));
  }

  /// Error function approximation
  static double _erf(double x) {
    final a1 = 0.254829592;
    final a2 = -0.284496736;
    final a3 = 1.421413741;
    final a4 = -1.453152027;
    final a5 = 1.061405429;
    final p = 0.3275911;
    
    final sign = x < 0 ? -1 : 1;
    x = x.abs();
    
    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);
    
    return sign * y;
  }

  // Trend analysis helpers
  static MBITrendDirection _calculateOverallTrend(List<MBIResult> results) {
    int beneficial = 0;
    int harmful = 0;
    int trivial = 0;
    
    for (final result in results) {
      switch (result.qualitativeInference.category) {
        case MBICategory.possiblyBeneficial:
        case MBICategory.likelyBeneficial:
        case MBICategory.veryLikelyBeneficial:
        case MBICategory.almostCertainlyBeneficial:
          beneficial++;
          break;
        case MBICategory.possiblyHarmful:
        case MBICategory.likelyHarmful:
        case MBICategory.veryLikelyHarmful:
        case MBICategory.almostCertainlyHarmful:
          harmful++;
          break;
        default:
          trivial++;
      }
    }
    
    if (beneficial > harmful && beneficial > trivial) {
      return MBITrendDirection.improving;
    } else if (harmful > beneficial && harmful > trivial) {
      return MBITrendDirection.declining;
    } else {
      return MBITrendDirection.stable;
    }
  }

  static double _calculateTrendConsistency(List<MBIResult> results) {
    if (results.isEmpty) return 0.0;
    
    final confidences = results.map((r) => r.confidence).toList();
    return _stats.calculateMean(confidences);
  }

  static double _calculateProgressionRate(List<MBIResult> results, List<DateTime> dates) {
    if (results.isEmpty || dates.length < 2) return 0.0;
    
    final changes = results.map((r) => r.percentChange).toList();
    final totalChange = changes.reduce((a, b) => a + b);
    final totalDays = dates.last.difference(dates.first).inDays;
    
    return totalDays > 0 ? totalChange / totalDays : 0.0;
  }

  static String _generateTrendRecommendation(MBITrendDirection trend, double consistency) {
    switch (trend) {
      case MBITrendDirection.improving:
        return consistency > 0.75 
            ? 'Tutarlı iyileşme gösteriliyor. Mevcut programı sürdürün.'
            : 'İyileşme eğilimi var ancak tutarsız. Program standardizasyonu gerekli.';
      case MBITrendDirection.declining:
        return 'Kötüleşme eğilimi. Program değişikliği ve dinlenme periyodu öneriliyor.';
      case MBITrendDirection.stable:
        return 'Stabil performans. Yeni stimulus veya program progressionu düşünülebilir.';
    }
  }

  static String _analyzeGroupPattern(Map<String, MBIResult> comparisons) {
    final beneficial = comparisons.values.where((r) => 
      [MBICategory.possiblyBeneficial, MBICategory.likelyBeneficial, 
       MBICategory.veryLikelyBeneficial, MBICategory.almostCertainlyBeneficial]
      .contains(r.qualitativeInference.category)).length;
    
    final total = comparisons.length;
    final percentage = beneficial / total * 100;
    
    if (percentage >= 75) {
      return 'Çoğunluk faydalı yanıt gösteriyor';
    } else if (percentage >= 50) {
      return 'Karışık yanıt profili';
    } else {
      return 'Çoğunluk faydalı yanıt göstermiyor';
    }
  }
}

// Data Models

class MBIResult {
  final double observedChange;
  final double percentChange;
  final double smallestWorthwhileChange;
  final double typicalError;
  final double changeError;
  final MBIProbabilities probabilities;
  final MBIQualitativeInference qualitativeInference;
  final MBIMagnitude magnitude;
  final String interpretation;
  final double confidence;
  final bool isSignificant;
  final Map<String, int> sampleSizes;
  final String? error;

  MBIResult({
    required this.observedChange,
    required this.percentChange,
    required this.smallestWorthwhileChange,
    required this.typicalError,
    required this.changeError,
    required this.probabilities,
    required this.qualitativeInference,
    required this.magnitude,
    required this.interpretation,
    required this.confidence,
    required this.isSignificant,
    required this.sampleSizes,
    this.error,
  });

  factory MBIResult.error(String message) {
    return MBIResult(
      observedChange: 0,
      percentChange: 0,
      smallestWorthwhileChange: 0,
      typicalError: 0,
      changeError: 0,
      probabilities: MBIProbabilities(beneficial: 0, trivial: 100, harmful: 0),
      qualitativeInference: MBIQualitativeInference(
        category: MBICategory.unclear,
        description: 'Error',
        certainty: 'Unknown',
      ),
      magnitude: MBIMagnitude.trivial,
      interpretation: message,
      confidence: 0,
      isSignificant: false,
      sampleSizes: {},
      error: message,
    );
  }

  bool get hasError => error != null;
}

class MBIProbabilities {
  final double beneficial;
  final double trivial;
  final double harmful;

  MBIProbabilities({
    required this.beneficial,
    required this.trivial,
    required this.harmful,
  });
}

class MBIQualitativeInference {
  final MBICategory category;
  final String description;
  final String certainty;

  MBIQualitativeInference({
    required this.category,
    required this.description,
    required this.certainty,
  });
}

enum MBICategory {
  almostCertainlyBeneficial,
  veryLikelyBeneficial,
  likelyBeneficial,
  possiblyBeneficial,
  mostLikelyTrivial,
  possiblyHarmful,
  likelyHarmful,
  veryLikelyHarmful,
  almostCertainlyHarmful,
  unclear,
}

enum MBIMagnitude {
  trivial,
  small,
  moderate,
  large,
  veryLarge,
  extremelyLarge,
}

class MBITrendResult {
  final List<MBIResult> pairwiseResults;
  final MBITrendDirection overallTrend;
  final double consistency;
  final double progressionRate;
  final String recommendation;
  final String? error;

  MBITrendResult({
    required this.pairwiseResults,
    required this.overallTrend,
    required this.consistency,
    required this.progressionRate,
    required this.recommendation,
    this.error,
  });

  factory MBITrendResult.error(String message) {
    return MBITrendResult(
      pairwiseResults: [],
      overallTrend: MBITrendDirection.stable,
      consistency: 0,
      progressionRate: 0,
      recommendation: message,
      error: message,
    );
  }

  bool get hasError => error != null;
}

enum MBITrendDirection {
  improving,
  stable,
  declining,
}

class MBIGroupResult {
  final String referenceGroup;
  final Map<String, MBIResult> comparisons;
  final String overallPattern;
  final String? error;

  MBIGroupResult({
    required this.referenceGroup,
    required this.comparisons,
    required this.overallPattern,
    this.error,
  });

  factory MBIGroupResult.error(String message) {
    return MBIGroupResult(
      referenceGroup: '',
      comparisons: {},
      overallPattern: message,
      error: message,
    );
  }

  bool get hasError => error != null;
}

class MBITrendComponent {
  final DateTime date;
  final double value;
  final MBIResult? comparison;

  MBITrendComponent({
    required this.date,
    required this.value,
    this.comparison,
  });
}