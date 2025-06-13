import 'dart:math' as math;
import '../utils/app_logger.dart';

/// SWC calculation methods
enum SWCMethod {
  cohen,      // Cohen's d = 0.2
  hopkins,    // Hopkins: 0.3 × between-subject SD
  cv,         // CV-based: 0.5 × CV
  individual, // Individual response threshold
}

/// Force-Velocity deficit types
enum ForceVelocityDeficit {
  none,        // Balanced profile
  force,       // Force deficit
  velocity,    // Velocity deficit
  power,       // Power deficit
}

/// Research-grade istatistiksel hesaplamalar helper sınıfı
/// Smart Metrics'ten adapte edilmiş peer-reviewed metodolojiler
/// Hopkins et al. (2009), Atkinson & Batterham (2015) referansları
class StatisticsHelper {
  static const String _tag = 'StatisticsHelper';

  /// Intraclass Correlation Coefficient (ICC) hesaplama
  /// ICC(3,1) - Two-way mixed effects, consistency, single measurement
  /// Shrout & Fleiss (1979), McGraw & Wong (1996), Koo & Li (2016) metodolojisi
  /// 
  /// NOT: Gerçek ICC için test-retest verileri gereklidir.
  /// Bu implementasyon tek ölçümler için yaklaşık değer verir.
  double calculateICC(List<double> values) {
    if (values.length < 6) { // Minimum 6 değer gerekli (3 test-retest çifti)
      AppLogger.warning(_tag, 'Insufficient data for ICC calculation (minimum 6 values needed)');
      return 0.0;
    }

    try {
      final n = values.length;
      
      // İçin gerçek ICC hesaplama yapılabilir ancak test-retest çiftleri gerekli
      // Bu durumda split-half reliability yaklaşımı kullanıyoruz
      
      // Split data into two halves for test-retest simulation
      final firstHalf = values.take(n ~/ 2).toList();
      final secondHalf = values.skip(n ~/ 2).toList();
      
      if (firstHalf.length != secondHalf.length) {
        // Unequal halves - use smallest size
        final minSize = math.min(firstHalf.length, secondHalf.length);
        final half1 = firstHalf.take(minSize).toList();
        final half2 = secondHalf.take(minSize).toList();
        return _calculateTrueICC(half1, half2);
      }
      
      return _calculateTrueICC(firstHalf, secondHalf);
      
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating ICC', e, stackTrace);
      return 0.0;
    }
  }

  /// Gerçek ICC(3,1) hesaplama - Shrout & Fleiss (1979) formülü
  double _calculateTrueICC(List<double> test1, List<double> test2) {
    if (test1.length != test2.length || test1.length < 3) return 0.0;
    
    final n = test1.length; // subjects
    final k = 2; // raters/trials
    
    // Grand mean
    final grandMean = (calculateMean(test1) + calculateMean(test2)) / 2;
    
    // Subject means
    final subjectMeans = <double>[];
    for (int i = 0; i < n; i++) {
      subjectMeans.add((test1[i] + test2[i]) / 2);
    }
    
    // Mean Square calculations
    double msr = 0.0; // Mean Square for Rows (subjects)
    for (int i = 0; i < n; i++) {
      msr += math.pow(subjectMeans[i] - grandMean, 2);
    }
    msr = msr * k / (n - 1);
    
    double mse = 0.0; // Mean Square Error (within-subject)
    for (int i = 0; i < n; i++) {
      mse += math.pow(test1[i] - subjectMeans[i], 2);
      mse += math.pow(test2[i] - subjectMeans[i], 2);
    }
    mse = mse / (n * (k - 1));
    
    // ICC(3,1) = (MSR - MSE) / MSR
    if (msr == 0) return 0.0;
    final icc = (msr - mse) / msr;
    
    return icc.clamp(0.0, 1.0);
  }

  /// Minimal Detectable Change (MDC95) hesaplama
  /// Haley & Fragala-Pinkham (2006) metodolojisi
  double calculateMDC(List<double> values, double icc) {
    try {
      if (values.isEmpty || icc <= 0) return 0.0;
      
      final sem = calculateSEM(values, icc);
      final mdc95 = 1.96 * math.sqrt(2) * sem;
      
      return mdc95;
      
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating MDC', e, stackTrace);
      return 0.0;
    }
  }

  /// Standard Error of Measurement (SEM) hesaplama
  double calculateSEM(List<double> values, double icc) {
    try {
      final sd = calculateStandardDeviation(values);
      final sem = sd * math.sqrt(1 - icc);
      
      return sem;
      
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating SEM', e, stackTrace);
      return 0.0;
    }
  }

  /// Smallest Worthwhile Change (SWC) hesaplama
  /// Multiple methods: Cohen, Hopkins, CV-based, Anchor-based
  /// Hopkins et al. (2009), Turner et al. (2015), Swinton et al. (2018)
  double calculateSWC(List<double> values, {SWCMethod method = SWCMethod.cohen}) {
    try {
      if (values.isEmpty) return 0.0;
      
      switch (method) {
        case SWCMethod.cohen:
          // Cohen's d = 0.2 (small effect) - Cohen (1988)
          final sd = calculateStandardDeviation(values);
          return 0.2 * sd;
          
        case SWCMethod.hopkins:
          // Hopkins: 0.2 × between-subject SD (güncellenmiş - Hopkins 2017)
          // Eski 0.3 değeri çok büyük bulundu
          final sd = calculateStandardDeviation(values);
          return 0.2 * sd;
          
        case SWCMethod.cv:
          // CV-based: TE × 1.96 (Turner et al. 2015)
          // Measurement error approach
          final cv = calculateCoefficientOfVariation(values);
          final mean = calculateMean(values);
          final te = (cv / 100) * mean / math.sqrt(2); // Typical Error
          return te * 1.96; // 95% confidence
          
        case SWCMethod.individual:
          // Individual response threshold (Swinton et al. 2018)
          // SWC = 0.5 × SD_individual responses
          final sd = calculateStandardDeviation(values);
          return 0.5 * sd;
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating SWC', e, stackTrace);
      return 0.0;
    }
  }

  /// Distribution-based SWC using effect sizes (Revicki et al. 2008)
  double calculateDistributionBasedSWC(List<double> values, {double effectSize = 0.2}) {
    final sd = calculateStandardDeviation(values);
    return effectSize * sd;
  }

  /// Anchor-based SWC using external criteria (Turner et al. 2015)
  double calculateAnchorBasedSWC(List<double> values, List<double> anchorScores) {
    if (values.length != anchorScores.length || values.length < 5) return 0.0;
    
    // ROC curve analysis approach
    // Simplified version - full implementation would need sensitivity/specificity
    final correlation = _calculatePearsonCorrelation(values, anchorScores);
    final sdValues = calculateStandardDeviation(values);
    
    // Approximate SWC based on correlation with anchor
    return sdValues * math.sqrt(1 - math.pow(correlation, 2)) * 1.96;
  }

  /// Magnitude-Based Inference hesaplama (Hopkins et al., 2009)
  MagnitudeBasedInference calculateMBI(
    double observedEffect, 
    double standardError, 
    double swc
  ) {
    try {
      // Effect standardization
      final standardizedEffect = observedEffect / swc;
      
      // Probability calculations using normal distribution
      final beneficial = _probabilityBeneficial(standardizedEffect, standardError / swc);
      final trivial = _probabilityTrivial(standardizedEffect, standardError / swc);
      final harmful = _probabilityHarmful(standardizedEffect, standardError / swc);
      
      // Qualitative inference
      final inference = _determineMBIQualifier(beneficial, trivial, harmful);
      
      return MagnitudeBasedInference(
        beneficial: beneficial,
        trivial: trivial,
        harmful: harmful,
        qualitativeInference: inference,
        standardizedEffect: standardizedEffect,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating MBI', e, stackTrace);
      return MagnitudeBasedInference(
        beneficial: 0.0,
        trivial: 1.0,
        harmful: 0.0,
        qualitativeInference: 'Unclear',
        standardizedEffect: 0.0,
      );
    }
  }

  /// Individual Response Analysis (Hopkins, 2015)
  IndividualResponse calculateIndividualResponse(
    List<double> preValues,
    List<double> postValues,
    double swc,
  ) {
    try {
      if (preValues.length != postValues.length || preValues.isEmpty) {
        throw ArgumentError('Pre and post values must have same length');
      }

      final responses = <double>[];
      final responders = <bool>[];
      
      for (int i = 0; i < preValues.length; i++) {
        final individualChange = postValues[i] - preValues[i];
        responses.add(individualChange);
        
        // True responder if change > SWC
        responders.add(individualChange.abs() > swc);
      }
      
      final meanResponse = calculateMean(responses);
      final sdResponse = calculateStandardDeviation(responses);
      final responderRate = responders.where((r) => r).length / responders.length;
      
      // True response calculation (accounting for measurement error)
      final typicalError = calculateTypicalError(preValues, postValues);
      final trueSD = math.sqrt(math.max(0, math.pow(sdResponse, 2) - math.pow(typicalError, 2)));
      
      return IndividualResponse(
        meanResponse: meanResponse,
        sdResponse: sdResponse,
        trueSD: trueSD,
        responderRate: responderRate,
        individualResponses: responses,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating individual response', e, stackTrace);
      return IndividualResponse(
        meanResponse: 0.0,
        sdResponse: 0.0,
        trueSD: 0.0,
        responderRate: 0.0,
        individualResponses: [],
      );
    }
  }

  /// Typical Error (TE) hesaplama
  double calculateTypicalError(List<double> test1, List<double> test2) {
    try {
      if (test1.length != test2.length || test1.isEmpty) return 0.0;
      
      final differences = <double>[];
      for (int i = 0; i < test1.length; i++) {
        differences.add(test1[i] - test2[i]);
      }
      
      final sd = calculateStandardDeviation(differences);
      return sd / math.sqrt(2);
      
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating typical error', e, stackTrace);
      return 0.0;
    }
  }

  /// Performance Modeling - Exponential Decay Model
  PerformanceModel fitExponentialModel(List<double> timePoints, List<double> values) {
    try {
      if (timePoints.length != values.length || timePoints.length < 5) {
        return PerformanceModel(
          baseline: 0.0,
          amplitude: 0.0,
          decayRate: 0.0,
          rSquared: 0.0,
          predictions: [],
        );
      }

      // Log transformation for exponential model
      final logValues = values.map((v) => v > 0 ? math.log(v) : 0.0).toList();
      
      // Linear regression on log-transformed data
      final regression = performLinearRegression(timePoints, logValues);
      
      // Transform back to exponential parameters
      final baseline = math.exp(regression.intercept);
      final decayRate = -regression.slope;
      
      // Generate predictions
      final predictions = <double>[];
      for (final t in timePoints) {
        predictions.add(baseline * math.exp(-decayRate * t));
      }
      
      return PerformanceModel(
        baseline: baseline,
        amplitude: baseline,
        decayRate: decayRate,
        rSquared: regression.rSquared,
        predictions: predictions,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Error fitting exponential model', e, stackTrace);
      return PerformanceModel(
        baseline: 0.0,
        amplitude: 0.0,
        decayRate: 0.0,
        rSquared: 0.0,
        predictions: [],
      );
    }
  }

  /// Force-Velocity Profile Analysis (Samozino et al., 2016)
  ForceVelocityProfile analyzeFVProfile(
    List<double> forces,
    List<double> velocities,
    double bodyMass,
  ) {
    try {
      if (forces.length != velocities.length || forces.length < 3) {
        return ForceVelocityProfile(
          f0: 0.0,
          v0: 0.0,
          pMax: 0.0,
          slope: 0.0,
          rSquared: 0.0,
          deficit: ForceVelocityDeficit.none,
        );
      }

      // Linear regression F = F0 + slope * V
      final regression = performLinearRegression(velocities, forces);
      
      final f0 = regression.intercept; // Force intercept
      final slope = regression.slope; // F-V slope
      final v0 = -f0 / slope; // Velocity intercept
      final pMax = (f0 * v0) / 4; // Maximum power
      
      // Normalize to body mass
      final f0Rel = f0 / bodyMass;
      final v0Rel = v0;
      final pMaxRel = pMax / bodyMass;
      
      // Determine F-V deficit
      final deficit = _determineFVDeficit(f0Rel, v0Rel);
      
      return ForceVelocityProfile(
        f0: f0Rel,
        v0: v0Rel,
        pMax: pMaxRel,
        slope: slope,
        rSquared: regression.rSquared,
        deficit: deficit,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Error analyzing F-V profile', e, stackTrace);
      return ForceVelocityProfile(
        f0: 0.0,
        v0: 0.0,
        pMax: 0.0,
        slope: 0.0,
        rSquared: 0.0,
        deficit: ForceVelocityDeficit.none,
      );
    }
  }

  /// Reactive Strength Index (RSI) hesaplama
  double calculateRSI(double jumpHeight, double contactTime) {
    try {
      if (contactTime <= 0) return 0.0;
      
      // RSI = Jump Height (m) / Contact Time (s)
      return (jumpHeight / 100) / (contactTime / 1000);
      
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating RSI', e, stackTrace);
      return 0.0;
    }
  }

  /// Modified RSI (RSImod) hesaplama
  double calculateRSIModified(double jumpHeight, double contactTime, double flightTime) {
    try {
      if (contactTime <= 0) return 0.0;
      
      // RSImod = Flight Time / Contact Time
      return flightTime / contactTime;
      
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating RSI modified', e, stackTrace);
      return 0.0;
    }
  }

  /// Bootstrap Confidence Intervals
  BootstrapResult calculateBootstrapCI(
    List<double> data, 
    double Function(List<double>) statistic, 
    {int iterations = 1000, double confidence = 0.95}
  ) {
    try {
      if (data.isEmpty) {
        return BootstrapResult(
          originalStatistic: 0.0,
          lowerCI: 0.0,
          upperCI: 0.0,
          bootstrapMean: 0.0,
          bootstrapSD: 0.0,
        );
      }

      final random = math.Random();
      final bootstrapStats = <double>[];
      
      for (int i = 0; i < iterations; i++) {
        final bootstrapSample = <double>[];
        for (int j = 0; j < data.length; j++) {
          bootstrapSample.add(data[random.nextInt(data.length)]);
        }
        bootstrapStats.add(statistic(bootstrapSample));
      }
      
      bootstrapStats.sort();
      
      final alpha = (1 - confidence) / 2;
      final lowerIndex = (alpha * iterations).floor();
      final upperIndex = ((1 - alpha) * iterations).floor() - 1;
      
      return BootstrapResult(
        originalStatistic: statistic(data),
        lowerCI: bootstrapStats[lowerIndex],
        upperCI: bootstrapStats[upperIndex],
        bootstrapMean: calculateMean(bootstrapStats),
        bootstrapSD: calculateStandardDeviation(bootstrapStats),
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating bootstrap CI', e, stackTrace);
      return BootstrapResult(
        originalStatistic: 0.0,
        lowerCI: 0.0,
        upperCI: 0.0,
        bootstrapMean: 0.0,
        bootstrapSD: 0.0,
      );
    }
  }

  /// Temel istatistiksel hesaplamalar
  
  double calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle];
    }
  }

  double calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = calculateMean(values);
    final squaredDiffs = values.map((x) => math.pow(x - mean, 2));
    final variance = squaredDiffs.reduce((a, b) => a + b) / (values.length - 1);
    
    return math.sqrt(variance);
  }

  double calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = calculateMean(values);
    final squaredDiffs = values.map((x) => math.pow(x - mean, 2));
    
    return squaredDiffs.reduce((a, b) => a + b) / (values.length - 1);
  }

  double calculateCoefficientOfVariation(List<double> values) {
    final mean = calculateMean(values);
    final sd = calculateStandardDeviation(values);
    
    return mean != 0 ? (sd / mean) * 100 : 0.0;
  }

  double calculateSkewness(List<double> values) {
    if (values.length < 3) return 0.0;
    
    final mean = calculateMean(values);
    final sd = calculateStandardDeviation(values);
    final n = values.length;
    
    if (sd == 0) return 0.0;
    
    final skewness = values
        .map((x) => math.pow((x - mean) / sd, 3))
        .reduce((a, b) => a + b) * (n / ((n - 1) * (n - 2)));
    
    return skewness;
  }

  double calculateKurtosis(List<double> values) {
    if (values.length < 4) return 0.0;
    
    final mean = calculateMean(values);
    final sd = calculateStandardDeviation(values);
    final n = values.length;
    
    if (sd == 0) return 0.0;
    
    final kurtosis = values
        .map((x) => math.pow((x - mean) / sd, 4))
        .reduce((a, b) => a + b) * (n * (n + 1) / ((n - 1) * (n - 2) * (n - 3))) - 
        (3 * math.pow(n - 1, 2) / ((n - 2) * (n - 3)));
    
    return kurtosis;
  }

  /// Calculate Linear Regression for force-velocity analysis
  LinearRegressionResult calculateLinearRegression(List<double> x, List<double> y) {
    return performLinearRegression(x, y);
  }

  /// Calculate coefficient of variation
  double calculateCV(List<double> values) {
    return calculateCoefficientOfVariation(values);
  }

  /// Calculate correlation coefficient
  double calculateCorrelation(List<double> x, List<double> y) {
    return _calculatePearsonCorrelation(x, y);
  }

  LinearRegressionResult performLinearRegression(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) {
      return LinearRegressionResult(
        slope: 0.0,
        intercept: 0.0,
        rSquared: 0.0,
        standardError: 0.0,
      );
    }
    
    final n = x.length;
    final meanX = calculateMean(x);
    final meanY = calculateMean(y);
    
    double numerator = 0.0;
    double denominator = 0.0;
    
    for (int i = 0; i < n; i++) {
      numerator += (x[i] - meanX) * (y[i] - meanY);
      denominator += math.pow(x[i] - meanX, 2);
    }
    
    final slope = denominator != 0 ? numerator / denominator : 0.0;
    final intercept = meanY - slope * meanX;
    
    // Calculate R²
    double ssRes = 0.0;
    double ssTot = 0.0;
    
    for (int i = 0; i < n; i++) {
      final predicted = slope * x[i] + intercept;
      ssRes += math.pow(y[i] - predicted, 2);
      ssTot += math.pow(y[i] - meanY, 2);
    }
    
    final rSquared = ssTot != 0 ? 1 - (ssRes / ssTot) : 0.0;
    final standardError = n > 2 ? math.sqrt(ssRes / (n - 2)) : 0.0;
    
    return LinearRegressionResult(
      slope: slope,
      intercept: intercept,
      rSquared: rSquared.clamp(0.0, 1.0),
      standardError: standardError,
    );
  }

  List<double> removeOutliers(List<double> values, {double threshold = 1.5}) {
    if (values.length < 4) return values;
    
    final sorted = List<double>.from(values)..sort();
    final q1Index = (sorted.length * 0.25).floor();
    final q3Index = (sorted.length * 0.75).floor();
    
    final q1 = sorted[q1Index];
    final q3 = sorted[q3Index];
    final iqr = q3 - q1;
    
    final lowerBound = q1 - threshold * iqr;
    final upperBound = q3 + threshold * iqr;
    
    return values.where((v) => v >= lowerBound && v <= upperBound).toList();
  }

  double calculateZScore(double value, double mean, double standardDeviation) {
    return standardDeviation != 0 ? (value - mean) / standardDeviation : 0.0;
  }

  /// Pearson Correlation Coefficient hesaplama
  double _calculatePearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return 0.0;
    
    final n = x.length;
    final meanX = calculateMean(x);
    final meanY = calculateMean(y);
    
    double numerator = 0.0;
    double sumXSquared = 0.0;
    double sumYSquared = 0.0;
    
    for (int i = 0; i < n; i++) {
      final xDev = x[i] - meanX;
      final yDev = y[i] - meanY;
      numerator += xDev * yDev;
      sumXSquared += xDev * xDev;
      sumYSquared += yDev * yDev;
    }
    
    final denominator = math.sqrt(sumXSquared * sumYSquared);
    return denominator != 0 ? numerator / denominator : 0.0;
  }

  double calculatePercentile(List<double> values, double percentile) {
    if (values.isEmpty) return 0.0;
    
    final sorted = List<double>.from(values)..sort();
    final index = (percentile / 100) * (sorted.length - 1);
    
    if (index == index.floor()) {
      return sorted[index.toInt()];
    } else {
      final lower = sorted[index.floor()];
      final upper = sorted[index.ceil()];
      return lower + (upper - lower) * (index - index.floor());
    }
  }

  /// Independent t-test for comparing two groups
  TTestResult performTTest(List<double> group1, List<double> group2) {
    try {
      if (group1.isEmpty || group2.isEmpty) {
        return TTestResult(
          tStatistic: 0.0,
          pValue: 1.0,
          degreesOfFreedom: 0,
          meanDifference: 0.0,
          standardError: 0.0,
        );
      }

      final n1 = group1.length;
      final n2 = group2.length;
      final mean1 = calculateMean(group1);
      final mean2 = calculateMean(group2);
      final var1 = calculateVariance(group1);
      final var2 = calculateVariance(group2);
      
      // Welch's t-test (unequal variances)
      final se = math.sqrt((var1 / n1) + (var2 / n2));
      final tStat = (mean1 - mean2) / se;
      
      // Welch-Satterthwaite degrees of freedom
      final df = math.pow((var1 / n1) + (var2 / n2), 2) / 
                 (math.pow(var1 / n1, 2) / (n1 - 1) + math.pow(var2 / n2, 2) / (n2 - 1));
      
      // Approximate p-value using t-distribution
      final pValue = _calculateTTestPValue(tStat, df);
      
      return TTestResult(
        tStatistic: tStat,
        pValue: pValue,
        degreesOfFreedom: df,
        meanDifference: mean1 - mean2,
        standardError: se,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Error performing t-test', e, stackTrace);
      return TTestResult(
        tStatistic: 0.0,
        pValue: 1.0,
        degreesOfFreedom: 0,
        meanDifference: 0.0,
        standardError: 0.0,
      );
    }
  }

  /// Approximate p-value calculation for t-test
  double _calculateTTestPValue(double tStat, double df) {
    // Simplified approximation - in real implementation use proper t-distribution
    final absTStat = tStat.abs();
    
    // Use normal approximation for large df
    if (df > 30) {
      return 2 * (1 - _normalCDF(absTStat, 1.0));
    }
    
    // Rough approximation for small df
    if (absTStat > 3.0) return 0.01;
    if (absTStat > 2.5) return 0.02;
    if (absTStat > 2.0) return 0.05;
    if (absTStat > 1.5) return 0.15;
    if (absTStat > 1.0) return 0.30;
    return 0.50;
  }

  // Private helper methods

  double _probabilityBeneficial(double effect, double se) {
    return 1 - _normalCDF(0.2 - effect, se);
  }

  double _probabilityTrivial(double effect, double se) {
    return _normalCDF(0.2 - effect, se) - _normalCDF(-0.2 - effect, se);
  }

  double _probabilityHarmful(double effect, double se) {
    return _normalCDF(-0.2 - effect, se);
  }

  double _normalCDF(double x, double sd) {
    final z = x / sd;
    return 0.5 * (1 + _erf(z / math.sqrt(2)));
  }

  double _erf(double x) {
    // Approximation of error function
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final sign = x < 0 ? -1 : 1;
    x = x.abs();

    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);

    return sign * y;
  }

  String _determineMBIQualifier(double beneficial, double trivial, double harmful) {
    const threshold = 0.75;
    
    if (beneficial >= threshold && harmful < 0.05) return 'Çok muhtemelen faydalı';
    if (beneficial >= threshold && harmful < 0.25) return 'Muhtemelen faydalı';
    if (harmful >= threshold && beneficial < 0.05) return 'Çok muhtemelen zararlı';
    if (harmful >= threshold && beneficial < 0.25) return 'Muhtemelen zararlı';
    if (trivial >= threshold) return 'Büyük olasılıkla önemsiz';
    
    return 'Belirsiz';
  }

  ForceVelocityDeficit _determineFVDeficit(double f0, double v0) {
    // Güncellenmiş normative values (Jiménez-Reyes et al. 2017, 2019)
    // Gender-specific norms gerekli ancak genel değerler:
    
    // Elite sprinter norms (Jiménez-Reyes et al. 2019):
    // F0: 7.5-10.5 N/kg, V0: 8.5-12 m/s
    // Jump norms (Samozino et al. 2016):
    const f0Norm = 35.0; // N/kg (CMJ için güncellenmiş)
    const v0Norm = 4.0;  // m/s (CMJ için güncellenmiş)
    
    // Imbalance threshold: 40% difference (Jiménez-Reyes et al. 2017)
    const imbalanceThreshold = 0.40;
    
    
    // Calculate relative deficit (Jiménez-Reyes method)
    final f0Deficit = (f0Norm - f0) / f0Norm;
    final v0Deficit = (v0Norm - v0) / v0Norm;
    
    // Determine predominant deficit
    if (f0Deficit > v0Deficit && f0Deficit > imbalanceThreshold) {
      return ForceVelocityDeficit.force;
    } else if (v0Deficit > f0Deficit && v0Deficit > imbalanceThreshold) {
      return ForceVelocityDeficit.velocity;
    } else if (f0Deficit > 0.2 && v0Deficit > 0.2) {
      return ForceVelocityDeficit.power;
    }
    
    return ForceVelocityDeficit.none;
  }
}

// Supporting enums and classes

class MagnitudeBasedInference {
  final double beneficial;
  final double trivial;
  final double harmful;
  final String qualitativeInference;
  final double standardizedEffect;

  MagnitudeBasedInference({
    required this.beneficial,
    required this.trivial,
    required this.harmful,
    required this.qualitativeInference,
    required this.standardizedEffect,
  });
}

class IndividualResponse {
  final double meanResponse;
  final double sdResponse;
  final double trueSD;
  final double responderRate;
  final List<double> individualResponses;

  IndividualResponse({
    required this.meanResponse,
    required this.sdResponse,
    required this.trueSD,
    required this.responderRate,
    required this.individualResponses,
  });
}

class PerformanceModel {
  final double baseline;
  final double amplitude;
  final double decayRate;
  final double rSquared;
  final List<double> predictions;

  PerformanceModel({
    required this.baseline,
    required this.amplitude,
    required this.decayRate,
    required this.rSquared,
    required this.predictions,
  });
}

class ForceVelocityProfile {
  final double f0;      // Force intercept (N/kg)
  final double v0;      // Velocity intercept (m/s)
  final double pMax;    // Maximum power (W/kg)
  final double slope;   // F-V slope
  final double rSquared;
  final ForceVelocityDeficit deficit;

  ForceVelocityProfile({
    required this.f0,
    required this.v0,
    required this.pMax,
    required this.slope,
    required this.rSquared,
    required this.deficit,
  });
}

class LinearRegressionResult {
  final double slope;
  final double intercept;
  final double rSquared;
  final double standardError;

  LinearRegressionResult({
    required this.slope,
    required this.intercept,
    required this.rSquared,
    required this.standardError,
  });
}

class BootstrapResult {
  final double originalStatistic;
  final double lowerCI;
  final double upperCI;
  final double bootstrapMean;
  final double bootstrapSD;

  BootstrapResult({
    required this.originalStatistic,
    required this.lowerCI,
    required this.upperCI,
    required this.bootstrapMean,
    required this.bootstrapSD,
  });
}

class TTestResult {
  final double tStatistic;
  final double pValue;
  final double degreesOfFreedom;
  final double meanDifference;
  final double standardError;

  TTestResult({
    required this.tStatistic,
    required this.pValue,
    required this.degreesOfFreedom,
    required this.meanDifference,
    required this.standardError,
  });
}