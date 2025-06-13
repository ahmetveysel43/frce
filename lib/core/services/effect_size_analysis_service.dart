import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_logger.dart';
import '../../data/models/test_result_model.dart';

/// Research-grade Effect Size Analysis Service
/// Implements Hedge's g, Bootstrap CI, and advanced effect size calculations
/// Based on Cohen (1988), Hedges & Olkin (1985), and Cumming (2012)
class EffectSizeAnalysisService {
  static const String _tag = 'EffectSizeAnalysisService';

  /// Calculate comprehensive effect size analysis between two groups
  static Future<EffectSizeAnalysisResult> performEffectSizeAnalysis({
    required List<double> baseline,
    required List<double> comparison,
    String metricName = 'Performance',
    int bootstrapIterations = 1000,
    double confidenceLevel = 0.95,
  }) async {
    try {
      AppLogger.info(_tag, 'Starting effect size analysis for $metricName');

      // Basic descriptive statistics
      final baselineStats = _calculateDescriptiveStats(baseline);
      final comparisonStats = _calculateDescriptiveStats(comparison);

      // Cohen's d (traditional)
      final cohensD = _calculateCohensD(baseline, comparison);

      // Hedge's g (bias-corrected for small samples)
      final hedgesG = _calculateHedgesG(baseline, comparison);

      // Glass's delta (when variances differ significantly)
      final glassDelta = _calculateGlassDelta(baseline, comparison);

      // Bootstrap confidence intervals
      final bootstrapCI = await _calculateBootstrapCI(
        baseline, 
        comparison, 
        iterations: bootstrapIterations,
        confidenceLevel: confidenceLevel,
      );

      // Bayesian effect size estimation
      final bayesianES = _calculateBayesianEffectSize(baseline, comparison);

      // Practical significance assessment
      final practicalSignificance = _assessPracticalSignificance(hedgesG, metricName);

      // Effect size interpretation
      final interpretation = _interpretEffectSize(hedgesG, metricName);

      // Power analysis
      final powerAnalysis = _performEffectSizePowerAnalysis(
        baseline.length, 
        comparison.length, 
        hedgesG
      );

      final result = EffectSizeAnalysisResult(
        metricName: metricName,
        baselineStats: baselineStats,
        comparisonStats: comparisonStats,
        cohensD: cohensD,
        hedgesG: hedgesG,
        glassDelta: glassDelta,
        bootstrapCI: bootstrapCI,
        bayesianEffectSize: bayesianES,
        practicalSignificance: practicalSignificance,
        interpretation: interpretation,
        powerAnalysis: powerAnalysis,
        confidenceLevel: confidenceLevel,
        sampleSizes: SampleSizes(baseline: baseline.length, comparison: comparison.length),
      );

      AppLogger.success('Effect size analysis completed for $metricName');
      return result;

    } catch (e, stackTrace) {
      AppLogger.error('Error in effect size analysis: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Calculate multiple effect sizes for test result comparison
  static Future<Map<String, EffectSizeAnalysisResult>> analyzeTestResultEffectSizes({
    required List<TestResultModel> baselineTests,
    required List<TestResultModel> comparisonTests,
    List<String>? specificMetrics,
  }) async {
    final results = <String, EffectSizeAnalysisResult>{};

    // Get common metrics between both test sets
    final commonMetrics = _getCommonMetrics(baselineTests, comparisonTests);
    final metricsToAnalyze = specificMetrics ?? commonMetrics;

    for (final metricKey in metricsToAnalyze) {
      if (commonMetrics.contains(metricKey)) {
        final baselineValues = baselineTests
            .where((test) => test.metrics.containsKey(metricKey))
            .map((test) => test.metrics[metricKey]!)
            .toList();

        final comparisonValues = comparisonTests
            .where((test) => test.metrics.containsKey(metricKey))
            .map((test) => test.metrics[metricKey]!)
            .toList();

        if (baselineValues.length >= 3 && comparisonValues.length >= 3) {
          try {
            final analysis = await performEffectSizeAnalysis(
              baseline: baselineValues,
              comparison: comparisonValues,
              metricName: metricKey,
            );
            results[metricKey] = analysis;
          } catch (e) {
            AppLogger.warning(_tag, 'Failed to analyze effect size for $metricKey: $e');
          }
        }
      }
    }

    return results;
  }

  // CORE EFFECT SIZE CALCULATIONS

  /// Cohen's d - Traditional effect size measure
  static double _calculateCohensD(List<double> group1, List<double> group2) {
    if (group1.isEmpty || group2.isEmpty) return 0.0;

    final mean1 = group1.reduce((a, b) => a + b) / group1.length;
    final mean2 = group2.reduce((a, b) => a + b) / group2.length;

    final variance1 = _calculateVariance(group1, mean1);
    final variance2 = _calculateVariance(group2, mean2);

    final pooledSD = _calculatePooledStandardDeviation(
      group1.length, group2.length, variance1, variance2
    );

    return pooledSD > 0 ? (mean2 - mean1) / pooledSD : 0.0;
  }

  /// Hedge's g - Bias-corrected effect size for small samples (Hedges & Olkin, 1985)
  static double _calculateHedgesG(List<double> group1, List<double> group2) {
    final cohensD = _calculateCohensD(group1, group2);
    final df = group1.length + group2.length - 2;

    // Bias correction factor J (Hedges & Olkin, 1985)
    final j = 1 - (3 / (4 * df - 1));

    return cohensD * j;
  }

  /// Glass's delta - Uses control group SD only (Glass et al., 1981)
  static double _calculateGlassDelta(List<double> control, List<double> treatment) {
    if (control.isEmpty || treatment.isEmpty) return 0.0;

    final controlMean = control.reduce((a, b) => a + b) / control.length;
    final treatmentMean = treatment.reduce((a, b) => a + b) / treatment.length;
    final controlSD = math.sqrt(_calculateVariance(control, controlMean));

    return controlSD > 0 ? (treatmentMean - controlMean) / controlSD : 0.0;
  }

  // BOOTSTRAP CONFIDENCE INTERVALS

  /// Bootstrap confidence intervals for effect size (Efron & Tibshirani, 1993)
  static Future<BootstrapConfidenceInterval> _calculateBootstrapCI(
    List<double> group1,
    List<double> group2, {
    int iterations = 1000,
    double confidenceLevel = 0.95,
  }) async {
    final effectSizes = <double>[];
    final random = math.Random();

    for (int i = 0; i < iterations; i++) {
      // Bootstrap resampling
      final bootstrap1 = _bootstrapSample(group1, random);
      final bootstrap2 = _bootstrapSample(group2, random);

      // Calculate effect size for this bootstrap sample
      final es = _calculateHedgesG(bootstrap1, bootstrap2);
      effectSizes.add(es);
    }

    // Sort and calculate percentiles
    effectSizes.sort();
    final alpha = (1 - confidenceLevel) / 2;
    final lowerIndex = (alpha * iterations).floor();
    final upperIndex = ((1 - alpha) * iterations).floor() - 1;

    final lowerBound = effectSizes[lowerIndex];
    final upperBound = effectSizes[upperIndex];
    final meanES = effectSizes.reduce((a, b) => a + b) / effectSizes.length;

    return BootstrapConfidenceInterval(
      lowerBound: lowerBound,
      upperBound: upperBound,
      meanEffectSize: meanES,
      confidenceLevel: confidenceLevel,
      iterations: iterations,
    );
  }

  /// Bootstrap resampling with replacement
  static List<double> _bootstrapSample(List<double> data, math.Random random) {
    final sample = <double>[];
    for (int i = 0; i < data.length; i++) {
      sample.add(data[random.nextInt(data.length)]);
    }
    return sample;
  }

  // BAYESIAN EFFECT SIZE

  /// Bayesian effect size estimation (Kruschke, 2013)
  static BayesianEffectSize _calculateBayesianEffectSize(
    List<double> group1, 
    List<double> group2
  ) {
    // Simplified Bayesian estimation using conjugate priors
    final mean1 = group1.reduce((a, b) => a + b) / group1.length;
    final mean2 = group2.reduce((a, b) => a + b) / group2.length;
    
    final variance1 = _calculateVariance(group1, mean1);
    final variance2 = _calculateVariance(group2, mean2);
    
    // Prior parameters (weakly informative)
    const priorMean = 0.0;
    const priorVariance = 1.0;
    
    // Posterior calculations (simplified)
    final posteriorMean = _calculateBayesianPosteriorMean(
      priorMean, priorVariance, mean2 - mean1, 
      (variance1 + variance2) / (group1.length + group2.length)
    );
    
    final posteriorSD = math.sqrt(priorVariance * 0.5); // Simplified
    
    // Credible interval (95%)
    final credibleInterval = CredibleInterval(
      lower: posteriorMean - 1.96 * posteriorSD,
      upper: posteriorMean + 1.96 * posteriorSD,
      probability: 0.95,
    );

    return BayesianEffectSize(
      posteriorMean: posteriorMean,
      posteriorSD: posteriorSD,
      credibleInterval: credibleInterval,
      probabilityOfSuperiority: _calculateProbabilityOfSuperiority(posteriorMean, posteriorSD),
    );
  }

  static double _calculateBayesianPosteriorMean(
    double priorMean, double priorVar, double dataMean, double dataVar
  ) {
    final precision1 = 1 / priorVar;
    final precision2 = 1 / dataVar;
    final posteriorPrecision = precision1 + precision2;
    
    return (precision1 * priorMean + precision2 * dataMean) / posteriorPrecision;
  }

  static double _calculateProbabilityOfSuperiority(double mean, double sd) {
    // Probability that effect size > 0
    final z = mean / sd;
    return _normalCDF(z);
  }

  // PRACTICAL SIGNIFICANCE AND INTERPRETATION

  /// Assess practical significance based on context-specific thresholds
  static PracticalSignificanceResult _assessPracticalSignificance(
    double effectSize, 
    String metricName
  ) {
    final contextThresholds = _getContextSpecificThresholds(metricName);
    
    PracticalSignificanceLevel level;
    String interpretation;
    
    final absES = effectSize.abs();
    
    if (absES < contextThresholds.trivial) {
      level = PracticalSignificanceLevel.trivial;
      interpretation = 'Önemsiz etki - pratik olarak anlamlı olması olası değil';
    } else if (absES < contextThresholds.small) {
      level = PracticalSignificanceLevel.small;
      interpretation = 'Küçük etki - sınırlı pratik öneme sahip olabilir';
    } else if (absES < contextThresholds.moderate) {
      level = PracticalSignificanceLevel.moderate;
      interpretation = 'Orta etki - pratik olarak fark edilebilir olması muhtemel';
    } else if (absES < contextThresholds.large) {
      level = PracticalSignificanceLevel.large;
      interpretation = 'Büyük etki - güçlü pratik anlamlılık';
    } else {
      level = PracticalSignificanceLevel.veryLarge;
      interpretation = 'Çok büyük etki - olağanüstü pratik önem';
    }

    return PracticalSignificanceResult(
      level: level,
      interpretation: interpretation,
      thresholds: contextThresholds,
      isPositive: effectSize > 0,
    );
  }

  /// Context-specific effect size thresholds (Hopkins et al., 2009; Rhea, 2004)
  static EffectSizeThresholds _getContextSpecificThresholds(String metricName) {
    // Sport science specific thresholds (Hopkins et al., 2009)
    if (metricName.toLowerCase().contains('jump') || 
        metricName.toLowerCase().contains('power') ||
        metricName.toLowerCase().contains('force')) {
      return const EffectSizeThresholds(
        trivial: 0.2,
        small: 0.6,
        moderate: 1.2,
        large: 2.0,
      );
    }
    
    // Balance and stability metrics (more sensitive)
    if (metricName.toLowerCase().contains('balance') || 
        metricName.toLowerCase().contains('stability') ||
        metricName.toLowerCase().contains('cop')) {
      return const EffectSizeThresholds(
        trivial: 0.1,
        small: 0.3,
        moderate: 0.6,
        large: 1.0,
      );
    }
    
    // Default Cohen's thresholds
    return const EffectSizeThresholds(
      trivial: 0.2,
      small: 0.5,
      moderate: 0.8,
      large: 1.2,
    );
  }

  /// Comprehensive effect size interpretation
  static EffectSizeInterpretation _interpretEffectSize(double effectSize, String metricName) {
    final practicalSig = _assessPracticalSignificance(effectSize, metricName);
    final magnitude = practicalSig.level;
    
    String clinicalInterpretation;
    String trainingImplication;
    Color visualColor;
    
    switch (magnitude) {
      case PracticalSignificanceLevel.trivial:
        clinicalInterpretation = 'Performansta anlamlı değişiklik yok';
        trainingImplication = 'Mevcut antrenman yaklaşımı istikrarlı görünüyor';
        visualColor = const Color(0xFF9E9E9E); // Grey
        break;
      case PracticalSignificanceLevel.small:
        clinicalInterpretation = 'Küçük performans değişikliği tespit edildi';
        trainingImplication = 'Küçük antrenman ayarlamaları düşünün';
        visualColor = const Color(0xFF2196F3); // Blue
        break;
      case PracticalSignificanceLevel.moderate:
        clinicalInterpretation = 'Fark edilebilir performans iyileşmesi';
        trainingImplication = 'Antrenman yaklaşımı olumlu etkiler gösteriyor';
        visualColor = const Color(0xFF4CAF50); // Green
        break;
      case PracticalSignificanceLevel.large:
        clinicalInterpretation = 'Önemli performans artışı';
        trainingImplication = 'Oldukça etkili antrenman müdahalesi';
        visualColor = const Color(0xFFFF9800); // Orange
        break;
      case PracticalSignificanceLevel.veryLarge:
        clinicalInterpretation = 'Olağanüstü performans dönüşümü';
        trainingImplication = 'Mükemmel antrenman yanıtı';
        visualColor = const Color(0xFFF44336); // Red
        break;
    }

    return EffectSizeInterpretation(
      magnitude: magnitude,
      clinicalInterpretation: clinicalInterpretation,
      trainingImplication: trainingImplication,
      visualColor: visualColor,
      confidenceInInterpretation: _calculateInterpretationConfidence(effectSize, metricName),
    );
  }

  // POWER ANALYSIS

  /// Power analysis for effect size detection
  static PowerAnalysisResult _performEffectSizePowerAnalysis(
    int n1, int n2, double effectSize
  ) {
    final totalN = n1 + n2;
    final harmonicMean = 2.0 / ((1.0 / n1) + (1.0 / n2));
    
    // Simplified power calculation (Cohen, 1988)
    final lambda = effectSize * math.sqrt(harmonicMean / 2.0);
    final power = _calculateStatisticalPower(lambda);
    
    // Required sample size for 80% power
    final requiredN = _calculateRequiredSampleSize(effectSize, 0.8);
    
    return PowerAnalysisResult(
      currentPower: power,
      recommendedSampleSize: requiredN,
      detectableEffectSize: _calculateDetectableEffectSize(totalN, 0.8),
      actualSampleSize: totalN,
      adequatePower: power >= 0.8,
    );
  }

  // HELPER METHODS

  static List<String> _getCommonMetrics(
    List<TestResultModel> tests1, 
    List<TestResultModel> tests2
  ) {
    final metrics1 = tests1.expand((test) => test.metrics.keys).toSet();
    final metrics2 = tests2.expand((test) => test.metrics.keys).toSet();
    return metrics1.intersection(metrics2).toList();
  }

  static DescriptiveStatistics _calculateDescriptiveStats(List<double> data) {
    if (data.isEmpty) {
      return DescriptiveStatistics(
        mean: 0, median: 0, standardDeviation: 0, variance: 0,
        minimum: 0, maximum: 0, sampleSize: 0,
      );
    }

    final sorted = List<double>.from(data)..sort();
    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = _calculateVariance(data, mean);
    final sd = math.sqrt(variance);

    return DescriptiveStatistics(
      mean: mean,
      median: _calculateMedian(sorted),
      standardDeviation: sd,
      variance: variance,
      minimum: sorted.first,
      maximum: sorted.last,
      sampleSize: data.length,
    );
  }

  static double _calculateVariance(List<double> data, double mean) {
    if (data.length <= 1) return 0.0;
    final sumSquaredDeviations = data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b);
    return sumSquaredDeviations / (data.length - 1); // Sample variance
  }

  static double _calculatePooledStandardDeviation(
    int n1, int n2, double var1, double var2
  ) {
    final pooledVariance = ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2);
    return math.sqrt(pooledVariance);
  }

  static double _calculateMedian(List<double> sortedData) {
    final n = sortedData.length;
    if (n % 2 == 1) {
      return sortedData[n ~/ 2];
    } else {
      return (sortedData[n ~/ 2 - 1] + sortedData[n ~/ 2]) / 2;
    }
  }

  static double _normalCDF(double z) {
    // Simplified normal CDF approximation
    return 0.5 * (1 + _erf(z / math.sqrt(2)));
  }

  static double _erf(double x) {
    // Simplified error function approximation
    const a1 =  0.254829592;
    const a2 = -0.284496736;
    const a3 =  1.421413741;
    const a4 = -1.453152027;
    const a5 =  1.061405429;
    const p  =  0.3275911;

    final sign = x >= 0 ? 1 : -1;
    x = x.abs();

    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);

    return sign * y;
  }

  static double _calculateStatisticalPower(double lambda) {
    // Simplified power calculation
    return _normalCDF(lambda - 1.96) + _normalCDF(-lambda - 1.96);
  }

  static int _calculateRequiredSampleSize(double effectSize, double targetPower) {
    // Simplified sample size calculation for two groups
    const zAlpha = 1.96; // alpha = 0.05
    final zBeta = _inverseNormalCDF(targetPower);
    
    final n = 2 * math.pow((zAlpha + zBeta) / effectSize, 2);
    return math.max(10, n.ceil()); // Minimum 10 per group
  }

  static double _calculateDetectableEffectSize(int totalN, double targetPower) {
    const zAlpha = 1.96;
    final zBeta = _inverseNormalCDF(targetPower);
    
    return (zAlpha + zBeta) / math.sqrt(totalN / 4.0);
  }

  static double _inverseNormalCDF(double p) {
    // Simplified inverse normal CDF (approximation)
    if (p <= 0.5) {
      return -math.sqrt(-2 * math.log(p));
    } else {
      return math.sqrt(-2 * math.log(1 - p));
    }
  }

  static double _calculateInterpretationConfidence(double effectSize, String metricName) {
    // Higher confidence for larger effect sizes and more reliable metrics
    final absES = effectSize.abs();
    double baseConfidence = math.min(0.95, 0.5 + absES * 0.3);
    
    // Adjust based on metric reliability
    if (metricName.toLowerCase().contains('force') || 
        metricName.toLowerCase().contains('power')) {
      baseConfidence *= 1.1; // Force/power metrics are generally reliable
    }
    
    return math.min(0.95, baseConfidence);
  }
}

// DATA CLASSES

class EffectSizeAnalysisResult {
  final String metricName;
  final DescriptiveStatistics baselineStats;
  final DescriptiveStatistics comparisonStats;
  final double cohensD;
  final double hedgesG;
  final double glassDelta;
  final BootstrapConfidenceInterval bootstrapCI;
  final BayesianEffectSize bayesianEffectSize;
  final PracticalSignificanceResult practicalSignificance;
  final EffectSizeInterpretation interpretation;
  final PowerAnalysisResult powerAnalysis;
  final double confidenceLevel;
  final SampleSizes sampleSizes;

  EffectSizeAnalysisResult({
    required this.metricName,
    required this.baselineStats,
    required this.comparisonStats,
    required this.cohensD,
    required this.hedgesG,
    required this.glassDelta,
    required this.bootstrapCI,
    required this.bayesianEffectSize,
    required this.practicalSignificance,
    required this.interpretation,
    required this.powerAnalysis,
    required this.confidenceLevel,
    required this.sampleSizes,
  });
}

class DescriptiveStatistics {
  final double mean;
  final double median;
  final double standardDeviation;
  final double variance;
  final double minimum;
  final double maximum;
  final int sampleSize;

  DescriptiveStatistics({
    required this.mean,
    required this.median,
    required this.standardDeviation,
    required this.variance,
    required this.minimum,
    required this.maximum,
    required this.sampleSize,
  });
}

class BootstrapConfidenceInterval {
  final double lowerBound;
  final double upperBound;
  final double meanEffectSize;
  final double confidenceLevel;
  final int iterations;

  BootstrapConfidenceInterval({
    required this.lowerBound,
    required this.upperBound,
    required this.meanEffectSize,
    required this.confidenceLevel,
    required this.iterations,
  });
}

class BayesianEffectSize {
  final double posteriorMean;
  final double posteriorSD;
  final CredibleInterval credibleInterval;
  final double probabilityOfSuperiority;

  BayesianEffectSize({
    required this.posteriorMean,
    required this.posteriorSD,
    required this.credibleInterval,
    required this.probabilityOfSuperiority,
  });
}

class CredibleInterval {
  final double lower;
  final double upper;
  final double probability;

  CredibleInterval({
    required this.lower,
    required this.upper,
    required this.probability,
  });
}

class PracticalSignificanceResult {
  final PracticalSignificanceLevel level;
  final String interpretation;
  final EffectSizeThresholds thresholds;
  final bool isPositive;

  PracticalSignificanceResult({
    required this.level,
    required this.interpretation,
    required this.thresholds,
    required this.isPositive,
  });
}

class EffectSizeThresholds {
  final double trivial;
  final double small;
  final double moderate;
  final double large;

  const EffectSizeThresholds({
    required this.trivial,
    required this.small,
    required this.moderate,
    required this.large,
  });
}

class EffectSizeInterpretation {
  final PracticalSignificanceLevel magnitude;
  final String clinicalInterpretation;
  final String trainingImplication;
  final Color visualColor;
  final double confidenceInInterpretation;

  EffectSizeInterpretation({
    required this.magnitude,
    required this.clinicalInterpretation,
    required this.trainingImplication,
    required this.visualColor,
    required this.confidenceInInterpretation,
  });
}

class PowerAnalysisResult {
  final double currentPower;
  final int recommendedSampleSize;
  final double detectableEffectSize;
  final int actualSampleSize;
  final bool adequatePower;

  PowerAnalysisResult({
    required this.currentPower,
    required this.recommendedSampleSize,
    required this.detectableEffectSize,
    required this.actualSampleSize,
    required this.adequatePower,
  });
}

class SampleSizes {
  final int baseline;
  final int comparison;

  SampleSizes({
    required this.baseline,
    required this.comparison,
  });
}

// ENUMS

enum PracticalSignificanceLevel {
  trivial,
  small,
  moderate,
  large,
  veryLarge,
}

