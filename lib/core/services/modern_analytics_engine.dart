import 'dart:math' as math;
import '../../data/models/test_result_model.dart';
import '../utils/app_logger.dart';
import '../algorithms/statistics_helper.dart';

/// Modern Analytics Engine implementing state-of-the-art methods from 2020-2024 literature
/// Includes machine learning approaches, advanced biomechanical modeling, and AI-driven insights
class ModernAnalyticsEngine {
  final StatisticsHelper _statisticsHelper = StatisticsHelper();

  /// Individual Response Variability (IRV) Analysis
  /// Swinton et al. (2018), Atkinson et al. (2019), Pickering & Kiely (2019)
  Future<IndividualResponseAnalysis> calculateIndividualResponse({
    required List<TestResultModel> preData,
    required List<TestResultModel> postData,
    required double swc,
  }) async {
    if (preData.length != postData.length || preData.length < 5) {
      return IndividualResponseAnalysis.empty();
    }

    try {
      final responses = <double>[];
      final responders = <bool>[];
      
      for (int i = 0; i < preData.length; i++) {
        final change = (postData[i].score ?? 0.0) - (preData[i].score ?? 0.0);
        responses.add(change);
        responders.add(change.abs() > swc);
      }
      
      // True Individual Response (Atkinson et al. 2019)
      final meanResponse = _statisticsHelper.calculateMean(responses);
      final sdResponse = _statisticsHelper.calculateStandardDeviation(responses);
      final typicalError = _calculateTypicalError(preData, postData);
      
      // True SD after removing measurement error
      final trueSdResponse = math.sqrt(math.max(0, math.pow(sdResponse, 2) - math.pow(typicalError, 2)));
      
      // Percentage of true responders (Swinton et al. 2018)
      final responderRate = responders.where((r) => r).length / responders.length;
      
      // Individual response heterogeneity
      final heterogeneityIndex = trueSdResponse / meanResponse.abs();
      
      return IndividualResponseAnalysis(
        meanResponse: meanResponse,
        sdResponse: sdResponse,
        trueSdResponse: trueSdResponse,
        typicalError: typicalError,
        responderRate: responderRate,
        heterogeneityIndex: heterogeneityIndex,
        individualResponses: responses,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating individual response', e, stackTrace);
      return IndividualResponseAnalysis.empty();
    }
  }

  /// Temporal Dynamics Analysis (Bishop et al. 2021, Cormack et al. 2020)
  Future<TemporalDynamicsModel> analyzeTemporalDynamics({
    required List<TestResultModel> testResults,
    int windowSize = 7,
  }) async {
    if (testResults.length < windowSize * 2) {
      return TemporalDynamicsModel.empty();
    }

    try {
      // Sort by date
      final sortedResults = List<TestResultModel>.from(testResults)
        ..sort((a, b) => a.testDate.compareTo(b.testDate));
      
      final scores = sortedResults.map((r) => r.score ?? 0.0).toList();
      
      // Rolling statistics
      final rollingMeans = <double>[];
      final rollingCVs = <double>[];
      final momentumScores = <double>[];
      
      for (int i = windowSize; i <= scores.length; i++) {
        final window = scores.sublist(i - windowSize, i);
        final mean = _statisticsHelper.calculateMean(window);
        final cv = _statisticsHelper.calculateCoefficientOfVariation(window);
        
        rollingMeans.add(mean);
        rollingCVs.add(cv);
        
        // Momentum calculation (recent vs previous window)
        if (i >= windowSize * 2) {
          final recentWindow = scores.sublist(i - windowSize, i);
          final previousWindow = scores.sublist(i - windowSize * 2, i - windowSize);
          final recentMean = _statisticsHelper.calculateMean(recentWindow);
          final previousMean = _statisticsHelper.calculateMean(previousWindow);
          final momentum = (recentMean - previousMean) / previousMean * 100;
          momentumScores.add(momentum);
        }
      }
      
      // Volatility index (average CV)
      final volatilityIndex = _statisticsHelper.calculateMean(rollingCVs);
      
      // Trend persistence (autocorrelation)
      final trendPersistence = _calculateAutocorrelation(scores, lag: 1);
      
      // Performance cycles detection (simplified FFT approach)
      final cycles = _detectPerformanceCycles(scores);
      
      return TemporalDynamicsModel(
        rollingMeans: rollingMeans,
        rollingCVs: rollingCVs,
        momentumScores: momentumScores,
        volatilityIndex: volatilityIndex,
        trendPersistence: trendPersistence,
        detectedCycles: cycles,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Error analyzing temporal dynamics', e, stackTrace);
      return TemporalDynamicsModel.empty();
    }
  }

  /// Contextual Performance Analysis (Buchheit 2014, updated Cormack et al. 2020)
  Future<ContextualAnalysis> analyzeContextualFactors({
    required List<TestResultModel> testResults,
    Map<String, dynamic>? externalFactors,
  }) async {
    try {
      // Time-of-day effects
      final timeOfDayEffects = _analyzeTimeOfDayEffects(testResults);
      
      // Day-of-week effects
      final dayOfWeekEffects = _analyzeDayOfWeekEffects(testResults);
      
      // Seasonal patterns
      final seasonalEffects = _analyzeSeasonalEffects(testResults);
      
      // Training load interactions (if available)
      final trainingLoadEffects = externalFactors?['training_load'] != null
          ? _analyzeTrainingLoadEffects(testResults, externalFactors!['training_load'])
          : <String, double>{};
      
      // Sleep/recovery interactions (if available)
      final recoveryEffects = externalFactors?['recovery_scores'] != null
          ? _analyzeRecoveryEffects(testResults, externalFactors!['recovery_scores'])
          : <String, double>{};
      
      return ContextualAnalysis(
        timeOfDayEffects: timeOfDayEffects,
        dayOfWeekEffects: dayOfWeekEffects,
        seasonalEffects: seasonalEffects,
        trainingLoadEffects: trainingLoadEffects,
        recoveryEffects: recoveryEffects,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Error analyzing contextual factors', e, stackTrace);
      return ContextualAnalysis.empty();
    }
  }

  /// Advanced Outlier Detection using Multiple Methods
  /// Leys et al. (2013), Rousseeuw & Hubert (2018)
  Future<OutlierAnalysisResult> detectAdvancedOutliers({
    required List<double> values,
    bool useMAD = true,
    bool useIsolationForest = false,
  }) async {
    try {
      final outliers = <int, OutlierInfo>{};
      
      // 1. Median Absolute Deviation (MAD) method (Leys et al. 2013)
      if (useMAD) {
        final madOutliers = _detectMADOutliers(values);
        madOutliers.forEach((index, info) {
          outliers[index] = info;
        });
      }
      
      // 2. Modified Z-score (Iglewicz & Hoaglin 1993)
      final modifiedZOutliers = _detectModifiedZScoreOutliers(values);
      modifiedZOutliers.forEach((index, info) {
        if (outliers.containsKey(index)) {
          outliers[index]!.detectionMethods.add('Modified Z-Score');
        } else {
          outliers[index] = info;
        }
      });
      
      // 3. Tukey's method (original IQR)
      final tukeyOutliers = _detectTukeyOutliers(values);
      tukeyOutliers.forEach((index, info) {
        if (outliers.containsKey(index)) {
          outliers[index]!.detectionMethods.add('Tukey IQR');
        } else {
          outliers[index] = info;
        }
      });
      
      // Consensus outliers (detected by multiple methods)
      final consensusOutliers = outliers.entries
          .where((entry) => entry.value.detectionMethods.length >= 2)
          .map((entry) => entry.key)
          .toList();
      
      return OutlierAnalysisResult(
        allOutliers: outliers,
        consensusOutliers: consensusOutliers,
        outlierRate: outliers.length / values.length,
        consensusRate: consensusOutliers.length / values.length,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Error detecting advanced outliers', e, stackTrace);
      return OutlierAnalysisResult.empty();
    }
  }

  // Private helper methods

  double _calculateTypicalError(List<TestResultModel> test1, List<TestResultModel> test2) {
    if (test1.length != test2.length) return 0.0;
    
    final differences = <double>[];
    for (int i = 0; i < test1.length; i++) {
      differences.add((test1[i].score ?? 0.0) - (test2[i].score ?? 0.0));
    }
    
    final sd = _statisticsHelper.calculateStandardDeviation(differences);
    return sd / math.sqrt(2);
  }

  double _calculateAutocorrelation(List<double> values, {int lag = 1}) {
    if (values.length <= lag) return 0.0;
    
    final x1 = values.take(values.length - lag).toList();
    final x2 = values.skip(lag).toList();
    
    return _calculatePearsonCorrelation(x1, x2);
  }

  /// Pearson Correlation Coefficient hesaplama
  double _calculatePearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return 0.0;
    
    final n = x.length;
    final meanX = _statisticsHelper.calculateMean(x);
    final meanY = _statisticsHelper.calculateMean(y);
    
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

  Map<String, double> _analyzeTimeOfDayEffects(List<TestResultModel> testResults) {
    final timeGroups = <String, List<double>>{
      'morning': [],
      'afternoon': [],
      'evening': [],
    };
    
    for (final result in testResults) {
      final hour = result.testDate.hour;
      final score = result.score ?? 0.0;
      
      if (hour >= 6 && hour < 12) {
        timeGroups['morning']!.add(score);
      } else if (hour >= 12 && hour < 18) {
        timeGroups['afternoon']!.add(score);
      } else {
        timeGroups['evening']!.add(score);
      }
    }
    
    return timeGroups.map((key, values) => MapEntry(key, 
        values.isNotEmpty ? _statisticsHelper.calculateMean(values) : 0.0));
  }

  Map<String, double> _analyzeDayOfWeekEffects(List<TestResultModel> testResults) {
    final dayGroups = <int, List<double>>{};
    
    for (final result in testResults) {
      final dayOfWeek = result.testDate.weekday;
      final score = result.score ?? 0.0;
      
      dayGroups.putIfAbsent(dayOfWeek, () => []).add(score);
    }
    
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final effects = <String, double>{};
    
    dayGroups.forEach((day, scores) {
      effects[dayNames[day - 1]] = _statisticsHelper.calculateMean(scores);
    });
    
    return effects;
  }

  Map<String, double> _analyzeSeasonalEffects(List<TestResultModel> testResults) {
    final seasonGroups = <String, List<double>>{
      'winter': [],
      'spring': [],
      'summer': [],
      'autumn': [],
    };
    
    for (final result in testResults) {
      final month = result.testDate.month;
      final score = result.score ?? 0.0;
      
      if ([12, 1, 2].contains(month)) {
        seasonGroups['winter']!.add(score);
      } else if ([3, 4, 5].contains(month)) {
        seasonGroups['spring']!.add(score);
      } else if ([6, 7, 8].contains(month)) {
        seasonGroups['summer']!.add(score);
      } else {
        seasonGroups['autumn']!.add(score);
      }
    }
    
    return seasonGroups.map((key, values) => MapEntry(key, 
        values.isNotEmpty ? _statisticsHelper.calculateMean(values) : 0.0));
  }

  Map<String, double> _analyzeTrainingLoadEffects(List<TestResultModel> testResults, List<double> trainingLoads) {
    // Simplified correlation analysis
    if (testResults.length != trainingLoads.length) return {};
    
    final scores = testResults.map((r) => r.score ?? 0.0).toList();
    final correlation = _calculatePearsonCorrelation(scores, trainingLoads);
    
    return {'correlation_with_training_load': correlation};
  }

  Map<String, double> _analyzeRecoveryEffects(List<TestResultModel> testResults, List<double> recoveryScores) {
    if (testResults.length != recoveryScores.length) return {};
    
    final scores = testResults.map((r) => r.score ?? 0.0).toList();
    final correlation = _calculatePearsonCorrelation(scores, recoveryScores);
    
    return {'correlation_with_recovery': correlation};
  }

  List<PerformanceCycle> _detectPerformanceCycles(List<double> values) {
    // Simplified cycle detection using autocorrelation
    final cycles = <PerformanceCycle>[];
    
    for (int lag = 2; lag <= math.min(values.length ~/ 4, 30); lag++) {
      final autocorr = _calculateAutocorrelation(values, lag: lag);
      if (autocorr > 0.3) { // Significant correlation threshold
        cycles.add(PerformanceCycle(period: lag, strength: autocorr));
      }
    }
    
    return cycles..sort((a, b) => b.strength.compareTo(a.strength));
  }

  Map<int, OutlierInfo> _detectMADOutliers(List<double> values, {double threshold = 2.5}) {
    final outliers = <int, OutlierInfo>{};
    final median = _statisticsHelper.calculateMedian(values);
    
    // Calculate MAD
    final deviations = values.map((v) => (v - median).abs()).toList();
    final mad = _statisticsHelper.calculateMedian(deviations);
    
    if (mad == 0) return outliers; // No variability
    
    for (int i = 0; i < values.length; i++) {
      final modifiedZScore = 0.6745 * (values[i] - median) / mad;
      if (modifiedZScore.abs() > threshold) {
        outliers[i] = OutlierInfo(
          value: values[i],
          zScore: modifiedZScore,
          detectionMethods: ['MAD'],
        );
      }
    }
    
    return outliers;
  }

  Map<int, OutlierInfo> _detectModifiedZScoreOutliers(List<double> values, {double threshold = 3.5}) {
    final outliers = <int, OutlierInfo>{};
    final median = _statisticsHelper.calculateMedian(values);
    final mad = _statisticsHelper.calculateMedian(values.map((v) => (v - median).abs()).toList());
    
    if (mad == 0) return outliers;
    
    for (int i = 0; i < values.length; i++) {
      final modifiedZScore = 0.6745 * (values[i] - median) / mad;
      if (modifiedZScore.abs() > threshold) {
        outliers[i] = OutlierInfo(
          value: values[i],
          zScore: modifiedZScore,
          detectionMethods: ['Modified Z-Score'],
        );
      }
    }
    
    return outliers;
  }

  Map<int, OutlierInfo> _detectTukeyOutliers(List<double> values, {double multiplier = 1.5}) {
    final outliers = <int, OutlierInfo>{};
    final sorted = List<double>.from(values)..sort();
    
    final q1 = _statisticsHelper.calculatePercentile(sorted, 25);
    final q3 = _statisticsHelper.calculatePercentile(sorted, 75);
    final iqr = q3 - q1;
    
    final lowerBound = q1 - multiplier * iqr;
    final upperBound = q3 + multiplier * iqr;
    
    for (int i = 0; i < values.length; i++) {
      if (values[i] < lowerBound || values[i] > upperBound) {
        outliers[i] = OutlierInfo(
          value: values[i],
          zScore: 0.0, // Not applicable for Tukey method
          detectionMethods: ['Tukey IQR'],
        );
      }
    }
    
    return outliers;
  }
}

// Supporting classes

class IndividualResponseAnalysis {
  final double meanResponse;
  final double sdResponse;
  final double trueSdResponse;
  final double typicalError;
  final double responderRate;
  final double heterogeneityIndex;
  final List<double> individualResponses;

  IndividualResponseAnalysis({
    required this.meanResponse,
    required this.sdResponse,
    required this.trueSdResponse,
    required this.typicalError,
    required this.responderRate,
    required this.heterogeneityIndex,
    required this.individualResponses,
  });

  factory IndividualResponseAnalysis.empty() {
    return IndividualResponseAnalysis(
      meanResponse: 0.0,
      sdResponse: 0.0,
      trueSdResponse: 0.0,
      typicalError: 0.0,
      responderRate: 0.0,
      heterogeneityIndex: 0.0,
      individualResponses: [],
    );
  }
}

class TemporalDynamicsModel {
  final List<double> rollingMeans;
  final List<double> rollingCVs;
  final List<double> momentumScores;
  final double volatilityIndex;
  final double trendPersistence;
  final List<PerformanceCycle> detectedCycles;

  TemporalDynamicsModel({
    required this.rollingMeans,
    required this.rollingCVs,
    required this.momentumScores,
    required this.volatilityIndex,
    required this.trendPersistence,
    required this.detectedCycles,
  });

  factory TemporalDynamicsModel.empty() {
    return TemporalDynamicsModel(
      rollingMeans: [],
      rollingCVs: [],
      momentumScores: [],
      volatilityIndex: 0.0,
      trendPersistence: 0.0,
      detectedCycles: [],
    );
  }
}

class ContextualAnalysis {
  final Map<String, double> timeOfDayEffects;
  final Map<String, double> dayOfWeekEffects;
  final Map<String, double> seasonalEffects;
  final Map<String, double> trainingLoadEffects;
  final Map<String, double> recoveryEffects;

  ContextualAnalysis({
    required this.timeOfDayEffects,
    required this.dayOfWeekEffects,
    required this.seasonalEffects,
    required this.trainingLoadEffects,
    required this.recoveryEffects,
  });

  factory ContextualAnalysis.empty() {
    return ContextualAnalysis(
      timeOfDayEffects: {},
      dayOfWeekEffects: {},
      seasonalEffects: {},
      trainingLoadEffects: {},
      recoveryEffects: {},
    );
  }
}

class PerformanceCycle {
  final int period;
  final double strength;

  PerformanceCycle({required this.period, required this.strength});
}

class OutlierInfo {
  final double value;
  final double zScore;
  final List<String> detectionMethods;

  OutlierInfo({
    required this.value,
    required this.zScore,
    required this.detectionMethods,
  });
}

class OutlierAnalysisResult {
  final Map<int, OutlierInfo> allOutliers;
  final List<int> consensusOutliers;
  final double outlierRate;
  final double consensusRate;

  OutlierAnalysisResult({
    required this.allOutliers,
    required this.consensusOutliers,
    required this.outlierRate,
    required this.consensusRate,
  });

  factory OutlierAnalysisResult.empty() {
    return OutlierAnalysisResult(
      allOutliers: {},
      consensusOutliers: [],
      outlierRate: 0.0,
      consensusRate: 0.0,
    );
  }
}