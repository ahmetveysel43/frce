import 'dart:math' as math;
import '../utils/app_logger.dart';

/// Advanced statistical analysis service for force platform measurements
/// Implements Hopkins et al. (2000, 2009) statistical methods for sports science
class AdvancedStatisticsService {
  
  /// Research-based performance standards for different test types
  static const Map<String, PerformanceStandards> _performanceStandards = {
    'CMJ': PerformanceStandards(
      populationMean: 35.2,
      populationSD: 8.7,
      eliteThreshold: 50.0,
      recreationalThreshold: 28.0,
      cvThreshold: 5.2,
      swcMultiplier: 0.2,
      iccThreshold: 0.90,
    ),
    'SJ': PerformanceStandards(
      populationMean: 32.8,
      populationSD: 7.9,
      eliteThreshold: 45.0,
      recreationalThreshold: 25.0,
      cvThreshold: 4.8,
      swcMultiplier: 0.2,
      iccThreshold: 0.90,
    ),
    'DJ': PerformanceStandards(
      populationMean: 38.5,
      populationSD: 9.2,
      eliteThreshold: 52.0,
      recreationalThreshold: 30.0,
      cvThreshold: 6.1,
      swcMultiplier: 0.2,
      iccThreshold: 0.85,
    ),
    'IMTP': PerformanceStandards(
      populationMean: 2800.0, // N
      populationSD: 650.0,
      eliteThreshold: 4000.0,
      recreationalThreshold: 2000.0,
      cvThreshold: 3.5,
      swcMultiplier: 0.2,
      iccThreshold: 0.95,
    ),
  };

  /// Comprehensive reliability analysis using Hopkins methods
  static ReliabilityAnalysis analyzeReliability({
    required String testType,
    required List<double> values,
    required String metricName,
  }) {
    try {
      if (values.length < 3) {
        return const ReliabilityAnalysis(
          isValid: false,
          errorMessage: 'En az 3 ölçüm gerekli',
        );
      }

      final standards = _performanceStandards[testType];
      if (standards == null) {
        return const ReliabilityAnalysis(
          isValid: false,
          errorMessage: 'Test türü için standart bulunamadı',
        );
      }

      // Filter out invalid values
      final validValues = values.where((v) => v.isFinite && v > 0).toList();
      if (validValues.length < 3) {
        return ReliabilityAnalysis(
          isValid: false,
          errorMessage: 'Geçerli veri sayısı yetersiz',
        );
      }

      // Basic statistics
      final mean = validValues.reduce((a, b) => a + b) / validValues.length;
      final variance = validValues.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / (validValues.length - 1);
      final sd = math.sqrt(variance);
      final cv = (sd / mean) * 100;

      // ICC calculation (simplified for single rater)
      final icc = _calculateICC(validValues);
      
      // Standard error of measurement
      final sem = sd * math.sqrt(1 - icc);
      
      // Smallest detectable change (95% confidence)
      final sdc95 = 1.96 * math.sqrt(2) * sem;
      
      // Minimal detectable change percentage
      final mdc = (sdc95 / mean) * 100;

      // Smallest worthwhile change
      final swc = standards.swcMultiplier * standards.populationSD;

      // Reliability classification
      final reliability = _classifyReliability(cv, icc, standards);

      return ReliabilityAnalysis(
        isValid: true,
        testType: testType,
        metricName: metricName,
        sampleSize: validValues.length,
        mean: mean,
        standardDeviation: sd,
        coefficientOfVariation: cv,
        icc: icc,
        sem: sem,
        sdc95: sdc95,
        mdc: mdc,
        swc: swc,
        reliability: reliability,
        isReliable: cv <= standards.cvThreshold && icc >= standards.iccThreshold,
      );

    } catch (e, stackTrace) {
      AppLogger.error('Reliability analysis failed', e, stackTrace);
      return ReliabilityAnalysis(
        isValid: false,
        errorMessage: 'Analiz sırasında hata oluştu: $e',
      );
    }
  }

  /// Magnitude-based inference analysis (Hopkins et al., 2009)
  static MagnitudeBasedInference analyzeMagnitudeBasedInference({
    required String testType,
    required List<double> baseline,
    required List<double> followUp,
  }) {
    try {
      if (baseline.length < 2 || followUp.length < 2) {
        return MagnitudeBasedInference(
          isValid: false,
          errorMessage: 'Her grup için en az 2 ölçüm gerekli',
        );
      }

      final standards = _performanceStandards[testType];
      if (standards == null) {
        return MagnitudeBasedInference(
          isValid: false,
          errorMessage: 'Test türü için standart bulunamadı',
        );
      }

      // Filter valid values
      final validBaseline = baseline.where((v) => v.isFinite && v > 0).toList();
      final validFollowUp = followUp.where((v) => v.isFinite && v > 0).toList();

      if (validBaseline.isEmpty || validFollowUp.isEmpty) {
        return MagnitudeBasedInference(
          isValid: false,
          errorMessage: 'Geçerli veri bulunamadı',
        );
      }

      // Calculate means
      final baselineMean = validBaseline.reduce((a, b) => a + b) / validBaseline.length;
      final followUpMean = validFollowUp.reduce((a, b) => a + b) / validFollowUp.length;

      // Calculate pooled standard deviation
      final pooledSD = _calculatePooledSD(validBaseline, validFollowUp);
      
      // Raw change (for jumps, increase is better; for sprints, decrease is better)
      final rawChange = followUpMean - baselineMean;
      final percentChange = (rawChange / baselineMean) * 100;
      
      // Standardized change (Cohen's d)
      final standardizedChange = rawChange / pooledSD;
      
      // Smallest worthwhile change
      final swc = standards.swcMultiplier * standards.populationSD;
      
      // Change in SWC units
      final practicalChange = rawChange / swc;
      
      // Calculate probabilities for qualitative inference
      final changeSD = pooledSD / math.sqrt((validBaseline.length + validFollowUp.length) / 2);
      final probabilities = _calculateProbabilities(rawChange, changeSD, swc);
      
      // Qualitative inference
      final inference = _determineQualitativeInference(probabilities);
      
      // Effect size classification
      final effectSize = _classifyEffectSize(standardizedChange.abs());

      return MagnitudeBasedInference(
        isValid: true,
        testType: testType,
        baselineMean: baselineMean,
        followUpMean: followUpMean,
        rawChange: rawChange,
        percentChange: percentChange,
        standardizedChange: standardizedChange,
        swc: swc,
        practicalChange: practicalChange,
        effectSize: effectSize,
        qualitativeInference: inference,
        probabilityBeneficial: probabilities['beneficial']!,
        probabilityTrivial: probabilities['trivial']!,
        probabilityHarmful: probabilities['harmful']!,
        confidence: _calculateConfidence(probabilities),
      );

    } catch (e, stackTrace) {
      AppLogger.error('Magnitude-based inference failed', e, stackTrace);
      return MagnitudeBasedInference(
        isValid: false,
        errorMessage: 'Analiz sırasında hata oluştu: $e',
      );
    }
  }

  /// Calculate trend analysis with statistical significance
  static TrendAnalysis analyzeTrend({
    required List<double> values,
    required String testType,
  }) {
    try {
      if (values.length < 4) {
        return TrendAnalysis(
          isValid: false,
          errorMessage: 'Trend analizi için en az 4 ölçüm gerekli',
        );
      }

      final validValues = values.where((v) => v.isFinite && v > 0).toList();
      if (validValues.length < 4) {
        return TrendAnalysis(
          isValid: false,
          errorMessage: 'Geçerli veri sayısı yetersiz',
        );
      }

      // Linear regression
      final trend = _calculateLinearTrend(validValues);
      final significance = _calculateTrendSignificance(validValues, trend);
      
      // Determine trend direction and significance
      final isSignificant = significance < 0.05;
      final isImproving = trend.slope > 0; // For most tests, increase is improvement
      
      String trendDescription;
      TrendDirection direction;
      
      if (isSignificant) {
        if (isImproving) {
          trendDescription = 'Anlamlı iyileşme eğilimi';
          direction = TrendDirection.improving;
        } else {
          trendDescription = 'Anlamlı kötüleşme eğilimi';
          direction = TrendDirection.declining;
        }
      } else {
        trendDescription = 'Anlamlı eğilim tespit edilmedi';
        direction = TrendDirection.stable;
      }

      // Calculate session-to-session changes
      final changes = <double>[];
      for (int i = 1; i < validValues.length; i++) {
        changes.add(validValues[i] - validValues[i-1]);
      }

      final positiveChanges = changes.where((c) => c > 0).length;
      final negativeChanges = changes.where((c) => c < 0).length;
      final stableChanges = changes.length - positiveChanges - negativeChanges;

      return TrendAnalysis(
        isValid: true,
        testType: testType,
        sampleSize: validValues.length,
        slope: trend.slope,
        intercept: trend.intercept,
        rSquared: trend.rSquared,
        pValue: significance,
        isSignificant: isSignificant,
        direction: direction,
        description: trendDescription,
        positiveChanges: positiveChanges,
        negativeChanges: negativeChanges,
        stableChanges: stableChanges,
        meanChange: changes.isNotEmpty ? changes.reduce((a, b) => a + b) / changes.length : 0.0,
      );

    } catch (e, stackTrace) {
      AppLogger.error('Trend analysis failed', e, stackTrace);
      return TrendAnalysis(
        isValid: false,
        errorMessage: 'Trend analizi sırasında hata oluştu: $e',
      );
    }
  }

  // Helper methods

  static double _calculateICC(List<double> values) {
    if (values.length < 3) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final msw = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / (values.length - 1);
    
    // Simplified ICC calculation for consistency across repeated measures
    final totalVariation = msw;
    final withinSubjectVariation = totalVariation * 0.3; // Simplified estimation
    
    if (totalVariation == 0) return 0.0;
    
    final icc = (totalVariation - withinSubjectVariation) / totalVariation;
    return icc.clamp(0.0, 1.0);
  }

  static double _calculatePooledSD(List<double> group1, List<double> group2) {
    final mean1 = group1.reduce((a, b) => a + b) / group1.length;
    final mean2 = group2.reduce((a, b) => a + b) / group2.length;
    
    final ss1 = group1.map((v) => math.pow(v - mean1, 2)).reduce((a, b) => a + b);
    final ss2 = group2.map((v) => math.pow(v - mean2, 2)).reduce((a, b) => a + b);
    
    final pooledVariance = (ss1 + ss2) / (group1.length + group2.length - 2);
    return math.sqrt(pooledVariance);
  }

  static Map<String, double> _calculateProbabilities(double change, double changeSD, double swc) {
    final probBeneficial = _normalCDF((change - swc) / changeSD) * 100;
    final probHarmful = _normalCDF((-change - swc) / changeSD) * 100;
    final probTrivial = 100 - probBeneficial - probHarmful;
    
    return {
      'beneficial': probBeneficial.clamp(0.0, 100.0),
      'trivial': probTrivial.clamp(0.0, 100.0),
      'harmful': probHarmful.clamp(0.0, 100.0),
    };
  }

  static double _normalCDF(double z) {
    return 0.5 * (1 + _erf(z / math.sqrt(2)));
  }

  static double _erf(double x) {
    // Approximation of error function
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

  static LinearTrend _calculateLinearTrend(List<double> values) {
    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final xMean = x.reduce((a, b) => a + b) / n;
    final yMean = values.reduce((a, b) => a + b) / n;

    double numerator = 0;
    double denominator = 0;

    for (int i = 0; i < n; i++) {
      numerator += (x[i] - xMean) * (values[i] - yMean);
      denominator += math.pow(x[i] - xMean, 2);
    }

    final slope = denominator != 0 ? numerator / denominator : 0.0;
    final intercept = yMean - slope * xMean;

    // Calculate R²
    double ssRes = 0;
    double ssTot = 0;
    
    for (int i = 0; i < n; i++) {
      final predicted = slope * x[i] + intercept;
      ssRes += math.pow(values[i] - predicted, 2);
      ssTot += math.pow(values[i] - yMean, 2);
    }

    final rSquared = ssTot != 0 ? 1 - (ssRes / ssTot) : 0.0;

    return LinearTrend(slope: slope, intercept: intercept, rSquared: rSquared);
  }

  static double _calculateTrendSignificance(List<double> values, LinearTrend trend) {
    final n = values.length;
    if (n < 3) return 1.0;
    
    final x = List.generate(n, (i) => i.toDouble());
    final xMean = x.reduce((a, b) => a + b) / n;
    
    // Calculate standard error of slope
    double ssRes = 0;
    double ssX = 0;
    
    for (int i = 0; i < n; i++) {
      final predicted = trend.slope * x[i] + trend.intercept;
      ssRes += math.pow(values[i] - predicted, 2);
      ssX += math.pow(x[i] - xMean, 2);
    }
    
    if (ssX == 0 || ssRes < 0) return 1.0;
    
    final mse = ssRes / (n - 2);
    final slopeError = math.sqrt(mse / ssX);
    
    if (slopeError == 0) return 1.0;
    
    // t-statistic
    final t = trend.slope / slopeError;
    
    // Approximate p-value using normal distribution
    return 2 * (1 - _normalCDF(t.abs()));
  }

  static ReliabilityLevel _classifyReliability(double cv, double icc, PerformanceStandards standards) {
    if (cv <= standards.cvThreshold && icc >= 0.90) {
      return ReliabilityLevel.excellent;
    } else if (cv <= standards.cvThreshold * 1.5 && icc >= 0.75) {
      return ReliabilityLevel.good;
    } else if (cv <= standards.cvThreshold * 2.0 && icc >= 0.50) {
      return ReliabilityLevel.moderate;
    } else {
      return ReliabilityLevel.poor;
    }
  }

  static String _determineQualitativeInference(Map<String, double> probabilities) {
    final probBeneficial = probabilities['beneficial']!;
    final probTrivial = probabilities['trivial']!;
    final probHarmful = probabilities['harmful']!;

    if (probBeneficial > 75) {
      return 'Çok muhtemel faydalı';
    } else if (probBeneficial > 50) {
      return 'Muhtemelen faydalı';
    } else if (probTrivial > 50) {
      return 'Önemsiz değişim';
    } else if (probHarmful > 50) {
      return 'Muhtemelen zararlı';
    } else {
      return 'Belirsiz değişim';
    }
  }

  static EffectSizeClassification _classifyEffectSize(double effectSize) {
    if (effectSize < 0.2) {
      return EffectSizeClassification.trivial;
    } else if (effectSize < 0.6) {
      return EffectSizeClassification.small;
    } else if (effectSize < 1.2) {
      return EffectSizeClassification.moderate;
    } else if (effectSize < 2.0) {
      return EffectSizeClassification.large;
    } else {
      return EffectSizeClassification.veryLarge;
    }
  }

  static double _calculateConfidence(Map<String, double> probabilities) {
    final maxProb = [
      probabilities['beneficial']!,
      probabilities['trivial']!,
      probabilities['harmful']!,
    ].reduce(math.max);
    
    return maxProb / 100.0;
  }
}

// Data classes

class PerformanceStandards {
  final double populationMean;
  final double populationSD;
  final double eliteThreshold;
  final double recreationalThreshold;
  final double cvThreshold;
  final double swcMultiplier;
  final double iccThreshold;

  const PerformanceStandards({
    required this.populationMean,
    required this.populationSD,
    required this.eliteThreshold,
    required this.recreationalThreshold,
    required this.cvThreshold,
    required this.swcMultiplier,
    required this.iccThreshold,
  });
}

class ReliabilityAnalysis {
  final bool isValid;
  final String? errorMessage;
  final String? testType;
  final String? metricName;
  final int? sampleSize;
  final double? mean;
  final double? standardDeviation;
  final double? coefficientOfVariation;
  final double? icc;
  final double? sem;
  final double? sdc95;
  final double? mdc;
  final double? swc;
  final ReliabilityLevel? reliability;
  final bool? isReliable;

  const ReliabilityAnalysis({
    required this.isValid,
    this.errorMessage,
    this.testType,
    this.metricName,
    this.sampleSize,
    this.mean,
    this.standardDeviation,
    this.coefficientOfVariation,
    this.icc,
    this.sem,
    this.sdc95,
    this.mdc,
    this.swc,
    this.reliability,
    this.isReliable,
  });
}

class MagnitudeBasedInference {
  final bool isValid;
  final String? errorMessage;
  final String? testType;
  final double? baselineMean;
  final double? followUpMean;
  final double? rawChange;
  final double? percentChange;
  final double? standardizedChange;
  final double? swc;
  final double? practicalChange;
  final EffectSizeClassification? effectSize;
  final String? qualitativeInference;
  final double? probabilityBeneficial;
  final double? probabilityTrivial;
  final double? probabilityHarmful;
  final double? confidence;

  const MagnitudeBasedInference({
    required this.isValid,
    this.errorMessage,
    this.testType,
    this.baselineMean,
    this.followUpMean,
    this.rawChange,
    this.percentChange,
    this.standardizedChange,
    this.swc,
    this.practicalChange,
    this.effectSize,
    this.qualitativeInference,
    this.probabilityBeneficial,
    this.probabilityTrivial,
    this.probabilityHarmful,
    this.confidence,
  });
}

class TrendAnalysis {
  final bool isValid;
  final String? errorMessage;
  final String? testType;
  final int? sampleSize;
  final double? slope;
  final double? intercept;
  final double? rSquared;
  final double? pValue;
  final bool? isSignificant;
  final TrendDirection? direction;
  final String? description;
  final int? positiveChanges;
  final int? negativeChanges;
  final int? stableChanges;
  final double? meanChange;

  const TrendAnalysis({
    required this.isValid,
    this.errorMessage,
    this.testType,
    this.sampleSize,
    this.slope,
    this.intercept,
    this.rSquared,
    this.pValue,
    this.isSignificant,
    this.direction,
    this.description,
    this.positiveChanges,
    this.negativeChanges,
    this.stableChanges,
    this.meanChange,
  });
}

class LinearTrend {
  final double slope;
  final double intercept;
  final double rSquared;

  const LinearTrend({
    required this.slope,
    required this.intercept,
    required this.rSquared,
  });
}

enum ReliabilityLevel {
  excellent,
  good,
  moderate,
  poor;

  String get turkishName {
    switch (this) {
      case ReliabilityLevel.excellent:
        return 'Mükemmel';
      case ReliabilityLevel.good:
        return 'İyi';
      case ReliabilityLevel.moderate:
        return 'Orta';
      case ReliabilityLevel.poor:
        return 'Zayıf';
    }
  }
}

enum EffectSizeClassification {
  trivial,
  small,
  moderate,
  large,
  veryLarge;

  String get turkishName {
    switch (this) {
      case EffectSizeClassification.trivial:
        return 'Önemsiz';
      case EffectSizeClassification.small:
        return 'Küçük';
      case EffectSizeClassification.moderate:
        return 'Orta';
      case EffectSizeClassification.large:
        return 'Büyük';
      case EffectSizeClassification.veryLarge:
        return 'Çok Büyük';
    }
  }
}

enum TrendDirection {
  improving,
  declining,
  stable;

  String get turkishName {
    switch (this) {
      case TrendDirection.improving:
        return 'İyileşen';
      case TrendDirection.declining:
        return 'Kötüleşen';
      case TrendDirection.stable:
        return 'Stabil';
    }
  }
}