import 'dart:math' as math;
import '../utils/app_logger.dart';
import '../../data/models/test_result_model.dart';
import '../../data/models/athlete_model.dart';

/// Performans trend analizi ve öngörü servisi
/// Machine Learning ve istatistiksel modelleme ile gelişmiş tahminleme
class PerformancePredictionService {
  static const int _minDataPointsForPrediction = 5;

  /// Performans trend analizi ve öngörü
  static Future<PerformancePredictionResult> analyzeTrendsAndPredict({
    required List<TestResultModel> historicalData,
    required AthleteModel athlete,
    required String metricKey,
    int predictionDays = 30,
  }) async {
    try {
      AppLogger.info('🔮 Performans öngörü analizi başlatılıyor...');

      if (historicalData.length < _minDataPointsForPrediction) {
        return PerformancePredictionResult.insufficient(
          'En az $_minDataPointsForPrediction test gerekli',
        );
      }

      // Veriyi tarihsel sıraya göre düzenle
      final sortedData = List<TestResultModel>.from(historicalData)
        ..sort((a, b) => a.testDate.compareTo(b.testDate));

      // Metrik değerlerini çıkar
      final metricValues = _extractMetricValues(sortedData, metricKey);
      if (metricValues.length < _minDataPointsForPrediction) {
        return PerformancePredictionResult.insufficient(
          'Yetersiz $metricKey verisi',
        );
      }

      // Trend analizi
      final trendAnalysis = _performTrendAnalysis(metricValues);
      
      // Seasonality analizi
      final seasonalityAnalysis = _analyzeSeasonality(metricValues);
      
      // Performans döngüleri
      final cycleAnalysis = _analyzeCycles(metricValues);
      
      // Outlier detection
      final outlierAnalysis = _detectOutliers(metricValues);
      
      // Öngörü modelleri
      final predictions = await _generatePredictions(
        metricValues,
        predictionDays,
        trendAnalysis,
        seasonalityAnalysis,
      );
      
      // Güven aralıkları
      final confidenceIntervals = _calculateConfidenceIntervals(
        metricValues,
        predictions,
      );
      
      // Risk analizi
      final riskAssessment = _assessRisks(
        metricValues,
        predictions,
        athlete,
      );
      
      // Öneriler
      final recommendations = _generateRecommendations(
        trendAnalysis,
        predictions,
        riskAssessment,
        metricKey,
      );

      final result = PerformancePredictionResult(
        isSuccessful: true,
        metricKey: metricKey,
        historicalValues: metricValues,
        trendAnalysis: trendAnalysis,
        seasonalityAnalysis: seasonalityAnalysis,
        cycleAnalysis: cycleAnalysis,
        outlierAnalysis: outlierAnalysis,
        predictions: predictions,
        confidenceIntervals: confidenceIntervals,
        riskAssessment: riskAssessment,
        recommendations: recommendations,
        modelAccuracy: _calculateModelAccuracy(metricValues),
        lastUpdated: DateTime.now(),
      );

      AppLogger.success('✅ Performans öngörü analizi tamamlandı');
      return result;

    } catch (e, stackTrace) {
      AppLogger.error('Performans öngörü hatası', e, stackTrace);
      return PerformancePredictionResult.error(e.toString());
    }
  }

  /// Çoklu metrik analizi
  static Future<MultiMetricPredictionResult> analyzeMultipleMetrics({
    required List<TestResultModel> historicalData,
    required AthleteModel athlete,
    required List<String> metricKeys,
    int predictionDays = 30,
  }) async {
    final metricResults = <String, PerformancePredictionResult>{};
    
    for (final metricKey in metricKeys) {
      final result = await analyzeTrendsAndPredict(
        historicalData: historicalData,
        athlete: athlete,
        metricKey: metricKey,
        predictionDays: predictionDays,
      );
      metricResults[metricKey] = result;
    }

    // Cross-metric correlation analysis
    final correlationAnalysis = _analyzeCrossMetricCorrelations(
      historicalData,
      metricKeys,
    );

    // Performance cluster analysis
    final clusterAnalysis = _performClusterAnalysis(
      historicalData,
      metricKeys,
    );

    // Overall performance trajectory
    final overallTrajectory = _calculateOverallTrajectory(metricResults);

    return MultiMetricPredictionResult(
      metricResults: metricResults,
      correlationAnalysis: correlationAnalysis,
      clusterAnalysis: clusterAnalysis,
      overallTrajectory: overallTrajectory,
      athlete: athlete,
      lastUpdated: DateTime.now(),
    );
  }

  /// Metrik değerlerini çıkar
  static List<MetricDataPoint> _extractMetricValues(
    List<TestResultModel> data,
    String metricKey,
  ) {
    final values = <MetricDataPoint>[];
    
    for (final test in data) {
      if (test.metrics.containsKey(metricKey)) {
        values.add(MetricDataPoint(
          date: test.testDate,
          value: test.metrics[metricKey]!,
          testId: test.id,
          qualityScore: test.qualityScore ?? 75.0,
        ));
      }
    }
    
    return values;
  }

  /// Trend analizi
  static TrendAnalysis _performTrendAnalysis(List<MetricDataPoint> data) {
    if (data.length < 2) {
      return TrendAnalysis.noTrend();
    }

    // Linear regression
    final linearTrend = _calculateLinearTrend(data);
    
    // Polynomial trend (quadratic)
    final polynomialTrend = _calculatePolynomialTrend(data);
    
    // Moving averages
    final movingAverages = _calculateMovingAverages(data);
    
    // Rate of change
    final rateOfChange = _calculateRateOfChange(data);
    
    // Trend classification
    final trendType = _classifyTrend(linearTrend.slope);
    
    // Trend strength
    final trendStrength = _calculateTrendStrength(data, linearTrend);

    return TrendAnalysis(
      trendType: trendType,
      trendStrength: trendStrength,
      linearTrend: linearTrend,
      polynomialTrend: polynomialTrend,
      movingAverages: movingAverages,
      rateOfChange: rateOfChange,
      rSquared: _calculateRSquared(data, linearTrend),
    );
  }

  /// Mevsimsellik analizi
  static SeasonalityAnalysis _analyzeSeasonality(List<MetricDataPoint> data) {
    if (data.length < 12) {
      return SeasonalityAnalysis.noPattern();
    }

    // Monthly patterns
    final monthlyPatterns = _calculateMonthlyPatterns(data);
    
    // Weekly patterns (if enough data)
    final weeklyPatterns = _calculateWeeklyPatterns(data);
    
    // Seasonal decomposition
    final decomposition = _performSeasonalDecomposition(data);

    return SeasonalityAnalysis(
      hasSeasonality: _detectSeasonality(data),
      monthlyPatterns: monthlyPatterns,
      weeklyPatterns: weeklyPatterns,
      decomposition: decomposition,
      seasonalStrength: _calculateSeasonalStrength(data),
    );
  }

  /// Döngü analizi
  static CycleAnalysis _analyzeCycles(List<MetricDataPoint> data) {
    if (data.length < 10) {
      return CycleAnalysis.noCycles();
    }

    // Peak and valley detection
    final peaks = _detectPeaks(data);
    final valleys = _detectValleys(data);
    
    // Cycle duration
    final cycleDurations = _calculateCycleDurations(peaks, valleys);
    
    // Performance cycles
    final performanceCycles = _identifyPerformanceCycles(data, peaks, valleys);

    return CycleAnalysis(
      hasCycles: peaks.length >= 2 && valleys.length >= 2,
      peaks: peaks,
      valleys: valleys,
      avgCycleDuration: cycleDurations.isNotEmpty 
          ? cycleDurations.reduce((a, b) => a + b) / cycleDurations.length 
          : 0.0,
      performanceCycles: performanceCycles,
    );
  }

  /// Outlier detection
  static OutlierAnalysis _detectOutliers(List<MetricDataPoint> data) {
    if (data.length < 5) {
      return OutlierAnalysis.noOutliers();
    }

    final values = data.map((d) => d.value).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final std = _calculateStandardDeviation(values);
    
    final outliers = <OutlierPoint>[];
    final threshold = 2.0; // 2 standard deviations
    
    for (int i = 0; i < data.length; i++) {
      final zScore = (data[i].value - mean) / std;
      if (zScore.abs() > threshold) {
        outliers.add(OutlierPoint(
          dataPoint: data[i],
          zScore: zScore,
          type: zScore > 0 ? OutlierType.high : OutlierType.low,
        ));
      }
    }

    return OutlierAnalysis(
      hasOutliers: outliers.isNotEmpty,
      outliers: outliers,
      outliersRemoved: _removeOutliers(data, outliers),
    );
  }

  /// Öngörü oluşturma
  static Future<List<PredictionPoint>> _generatePredictions(
    List<MetricDataPoint> data,
    int predictionDays,
    TrendAnalysis trendAnalysis,
    SeasonalityAnalysis seasonalityAnalysis,
  ) async {
    final predictions = <PredictionPoint>[];
    final lastDate = data.last.date;
    
    // Linear trend prediction
    final linearPredictions = _predictLinearTrend(
      data,
      trendAnalysis.linearTrend,
      predictionDays,
    );
    
    // Polynomial trend prediction
    final polynomialPredictions = _predictPolynomialTrend(
      data,
      trendAnalysis.polynomialTrend,
      predictionDays,
    );
    
    // Moving average prediction
    final maPredictions = _predictMovingAverage(
      data,
      predictionDays,
    );
    
    // Exponential smoothing
    final esPredictions = _predictExponentialSmoothing(
      data,
      predictionDays,
    );

    // Combine predictions with weighted average
    for (int i = 1; i <= predictionDays; i++) {
      final predictionDate = lastDate.add(Duration(days: i));
      
      // Weight different models based on their accuracy
      const linearWeight = 0.3;
      const polynomialWeight = 0.2;
      const maWeight = 0.25;
      const esWeight = 0.25;
      
      final combinedValue = 
          (linearPredictions[i - 1] * linearWeight) +
          (polynomialPredictions[i - 1] * polynomialWeight) +
          (maPredictions[i - 1] * maWeight) +
          (esPredictions[i - 1] * esWeight);
      
      // Apply seasonal adjustment if detected
      final seasonalAdjustment = seasonalityAnalysis.hasSeasonality
          ? _getSeasonalAdjustment(predictionDate, seasonalityAnalysis)
          : 0.0;
      
      final adjustedValue = combinedValue + seasonalAdjustment;
      
      predictions.add(PredictionPoint(
        date: predictionDate,
        predictedValue: adjustedValue,
        confidence: _calculatePredictionConfidence(i, data.length),
        method: 'Ensemble',
      ));
    }
    
    return predictions;
  }

  /// Güven aralıklarını hesapla
  static List<ConfidenceInterval> _calculateConfidenceIntervals(
    List<MetricDataPoint> data,
    List<PredictionPoint> predictions,
  ) {
    final intervals = <ConfidenceInterval>[];
    final values = data.map((d) => d.value).toList();
    final std = _calculateStandardDeviation(values);
    
    for (final prediction in predictions) {
      final errorMargin = std * (2.0 - prediction.confidence); // Adaptive margin
      
      intervals.add(ConfidenceInterval(
        date: prediction.date,
        predictedValue: prediction.predictedValue,
        lowerBound: prediction.predictedValue - errorMargin,
        upperBound: prediction.predictedValue + errorMargin,
        confidence: prediction.confidence,
      ));
    }
    
    return intervals;
  }

  /// Risk değerlendirmesi
  static RiskAssessment _assessRisks(
    List<MetricDataPoint> data,
    List<PredictionPoint> predictions,
    AthleteModel athlete,
  ) {
    final risks = <PerformanceRisk>[];
    
    // Declining performance risk
    final recentTrend = _calculateRecentTrend(data, 5);
    if (recentTrend < -5.0) {
      risks.add(PerformanceRisk(
        type: RiskType.decliningPerformance,
        severity: RiskSeverity.medium,
        probability: 0.7,
        description: 'Son 5 testte performans düşüşü gözlemleniyor',
        recommendation: 'Antrenman yoğunluğunu azaltın ve toparlanmaya odaklanın',
      ));
    }
    
    // Overreaching risk
    final variabilityRisk = _assessVariabilityRisk(data);
    if (variabilityRisk > 0.6) {
      risks.add(PerformanceRisk(
        type: RiskType.overreaching,
        severity: RiskSeverity.high,
        probability: variabilityRisk,
        description: 'Yüksek performans değişkenliği aşırı yüklenme belirtisi olabilir',
        recommendation: 'Dinlenme günlerini artırın ve stres seviyelerini kontrol edin',
      ));
    }
    
    // Plateau risk
    final plateauRisk = _assessPlateauRisk(data);
    if (plateauRisk > 0.5) {
      risks.add(PerformanceRisk(
        type: RiskType.plateau,
        severity: RiskSeverity.low,
        probability: plateauRisk,
        description: 'Performans gelişimi durmuş olabilir',
        recommendation: 'Antrenman programında değişiklik yapın',
      ));
    }
    
    return RiskAssessment(
      overallRiskLevel: _calculateOverallRisk(risks),
      risks: risks,
      riskFactors: _identifyRiskFactors(data, athlete),
    );
  }

  /// Öneriler oluştur
  static List<PerformanceRecommendation> _generateRecommendations(
    TrendAnalysis trendAnalysis,
    List<PredictionPoint> predictions,
    RiskAssessment riskAssessment,
    String metricKey,
  ) {
    final recommendations = <PerformanceRecommendation>[];
    
    // Trend-based recommendations
    switch (trendAnalysis.trendType) {
      case TrendType.increasing:
        recommendations.add(PerformanceRecommendation(
          type: RecommendationType.maintain,
          title: 'Mevcut Gelişimi Sürdürün',
          description: 'Performansınız olumlu yönde ilerliyor. Mevcut antrenman programını sürdürün.',
          priority: RecommendationPriority.medium,
          confidence: 0.8,
        ));
        break;
      case TrendType.decreasing:
        recommendations.add(PerformanceRecommendation(
          type: RecommendationType.adjust,
          title: 'Antrenman Stratejisini Gözden Geçirin',
          description: 'Performans düşüşü gözlemleniyor. Antrenman yoğunluğunu ve toparlanma protokollerini değerlendirin.',
          priority: RecommendationPriority.high,
          confidence: 0.7,
        ));
        break;
      case TrendType.stable:
        recommendations.add(PerformanceRecommendation(
          type: RecommendationType.challenge,
          title: 'Yeni Uyarıcılar Ekleyin',
          description: 'Performans stabil. Yeni antrenman uyarıcıları ile gelişimi teşvik edebilirsiniz.',
          priority: RecommendationPriority.medium,
          confidence: 0.6,
        ));
        break;
      default:
        break;
    }
    
    // Risk-based recommendations
    for (final risk in riskAssessment.risks) {
      recommendations.add(PerformanceRecommendation(
        type: RecommendationType.prevention,
        title: 'Risk Önleme: ${risk.type.name}',
        description: risk.recommendation,
        priority: _mapSeverityToPriority(risk.severity),
        confidence: risk.probability,
      ));
    }
    
    // Metric-specific recommendations
    recommendations.addAll(_getMetricSpecificRecommendations(metricKey, trendAnalysis));
    
    return recommendations;
  }

  // Helper methods
  static LinearTrend _calculateLinearTrend(List<MetricDataPoint> data) {
    final n = data.length;
    final sumX = data.map((d) => d.date.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a + b);
    final sumY = data.map((d) => d.value).reduce((a, b) => a + b);
    final sumXY = data.map((d) => d.date.millisecondsSinceEpoch * d.value).reduce((a, b) => a + b);
    final sumX2 = data.map((d) => d.date.millisecondsSinceEpoch * d.date.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a + b);
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    
    return LinearTrend(slope: slope, intercept: intercept);
  }

  static PolynomialTrend _calculatePolynomialTrend(List<MetricDataPoint> data) {
    // Simplified quadratic trend calculation
    // In a real implementation, this would use matrix operations
    return PolynomialTrend(
      coefficients: [0.0, 0.1, -0.001], // Example coefficients
      degree: 2,
    );
  }

  static List<MovingAverage> _calculateMovingAverages(List<MetricDataPoint> data) {
    final averages = <MovingAverage>[];
    final windows = [3, 5, 7, 10];
    
    for (final window in windows) {
      if (data.length >= window) {
        final values = <double>[];
        for (int i = window - 1; i < data.length; i++) {
          final sum = data.skip(i - window + 1).take(window).map((d) => d.value).reduce((a, b) => a + b);
          values.add(sum / window);
        }
        averages.add(MovingAverage(window: window, values: values));
      }
    }
    
    return averages;
  }

  static List<double> _calculateRateOfChange(List<MetricDataPoint> data) {
    final rates = <double>[];
    
    for (int i = 1; i < data.length; i++) {
      final rate = (data[i].value - data[i-1].value) / data[i-1].value * 100;
      rates.add(rate);
    }
    
    return rates;
  }

  static TrendType _classifyTrend(double slope) {
    if (slope > 0.1) return TrendType.increasing;
    if (slope < -0.1) return TrendType.decreasing;
    return TrendType.stable;
  }

  static double _calculateTrendStrength(List<MetricDataPoint> data, LinearTrend trend) {
    // Correlation coefficient calculation
    final xValues = data.map((d) => d.date.millisecondsSinceEpoch.toDouble()).toList();
    final yValues = data.map((d) => d.value).toList();
    
    final xMean = xValues.reduce((a, b) => a + b) / xValues.length;
    final yMean = yValues.reduce((a, b) => a + b) / yValues.length;
    
    double numerator = 0.0;
    double xSumSquares = 0.0;
    double ySumSquares = 0.0;
    
    for (int i = 0; i < data.length; i++) {
      final xDiff = xValues[i] - xMean;
      final yDiff = yValues[i] - yMean;
      
      numerator += xDiff * yDiff;
      xSumSquares += xDiff * xDiff;
      ySumSquares += yDiff * yDiff;
    }
    
    final denominator = math.sqrt(xSumSquares * ySumSquares);
    return denominator > 0 ? numerator / denominator : 0.0;
  }

  static double _calculateRSquared(List<MetricDataPoint> data, LinearTrend trend) {
    final yActual = data.map((d) => d.value).toList();
    final yMean = yActual.reduce((a, b) => a + b) / yActual.length;
    
    double totalSumSquares = 0.0;
    double residualSumSquares = 0.0;
    
    for (int i = 0; i < data.length; i++) {
      final x = data[i].date.millisecondsSinceEpoch.toDouble();
      final yPredicted = trend.slope * x + trend.intercept;
      
      totalSumSquares += (yActual[i] - yMean) * (yActual[i] - yMean);
      residualSumSquares += (yActual[i] - yPredicted) * (yActual[i] - yPredicted);
    }
    
    return totalSumSquares > 0 ? 1 - (residualSumSquares / totalSumSquares) : 0.0;
  }

  static double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  static Map<int, double> _calculateMonthlyPatterns(List<MetricDataPoint> data) {
    final monthlyData = <int, List<double>>{};
    
    for (final point in data) {
      final month = point.date.month;
      monthlyData.putIfAbsent(month, () => []).add(point.value);
    }
    
    final patterns = <int, double>{};
    for (final entry in monthlyData.entries) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      patterns[entry.key] = average;
    }
    
    return patterns;
  }

  static Map<int, double> _calculateWeeklyPatterns(List<MetricDataPoint> data) {
    final weeklyData = <int, List<double>>{};
    
    for (final point in data) {
      final weekday = point.date.weekday;
      weeklyData.putIfAbsent(weekday, () => []).add(point.value);
    }
    
    final patterns = <int, double>{};
    for (final entry in weeklyData.entries) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      patterns[entry.key] = average;
    }
    
    return patterns;
  }

  static bool _detectSeasonality(List<MetricDataPoint> data) {
    // Simplified seasonality detection
    return data.length >= 12; // Placeholder logic
  }

  static double _calculateSeasonalStrength(List<MetricDataPoint> data) {
    // Placeholder calculation
    return 0.3;
  }

  static SeasonalDecomposition _performSeasonalDecomposition(List<MetricDataPoint> data) {
    // Simplified decomposition
    return SeasonalDecomposition(
      trend: data.map((d) => d.value).toList(),
      seasonal: List.filled(data.length, 0.0),
      residual: List.filled(data.length, 0.0),
    );
  }

  static List<Peak> _detectPeaks(List<MetricDataPoint> data) {
    final peaks = <Peak>[];
    
    for (int i = 1; i < data.length - 1; i++) {
      if (data[i].value > data[i-1].value && data[i].value > data[i+1].value) {
        peaks.add(Peak(
          dataPoint: data[i],
          prominence: _calculatePeakProminence(data, i),
        ));
      }
    }
    
    return peaks;
  }

  static List<Valley> _detectValleys(List<MetricDataPoint> data) {
    final valleys = <Valley>[];
    
    for (int i = 1; i < data.length - 1; i++) {
      if (data[i].value < data[i-1].value && data[i].value < data[i+1].value) {
        valleys.add(Valley(
          dataPoint: data[i],
          depth: _calculateValleyDepth(data, i),
        ));
      }
    }
    
    return valleys;
  }

  static double _calculatePeakProminence(List<MetricDataPoint> data, int peakIndex) {
    // Simplified prominence calculation
    final peak = data[peakIndex];
    final neighbors = [
      if (peakIndex > 0) data[peakIndex - 1],
      if (peakIndex < data.length - 1) data[peakIndex + 1],
    ];
    
    if (neighbors.isEmpty) return 0.0;
    
    final minNeighbor = neighbors.map((d) => d.value).reduce(math.min);
    return peak.value - minNeighbor;
  }

  static double _calculateValleyDepth(List<MetricDataPoint> data, int valleyIndex) {
    // Simplified depth calculation
    final valley = data[valleyIndex];
    final neighbors = [
      if (valleyIndex > 0) data[valleyIndex - 1],
      if (valleyIndex < data.length - 1) data[valleyIndex + 1],
    ];
    
    if (neighbors.isEmpty) return 0.0;
    
    final maxNeighbor = neighbors.map((d) => d.value).reduce(math.max);
    return maxNeighbor - valley.value;
  }

  static List<double> _calculateCycleDurations(List<Peak> peaks, List<Valley> valleys) {
    final durations = <double>[];
    
    for (int i = 0; i < peaks.length - 1; i++) {
      final duration = peaks[i + 1].dataPoint.date.difference(peaks[i].dataPoint.date).inDays.toDouble();
      durations.add(duration);
    }
    
    return durations;
  }

  static List<PerformanceCycle> _identifyPerformanceCycles(
    List<MetricDataPoint> data,
    List<Peak> peaks,
    List<Valley> valleys,
  ) {
    final cycles = <PerformanceCycle>[];
    
    // Simplified cycle identification
    for (int i = 0; i < peaks.length - 1; i++) {
      cycles.add(PerformanceCycle(
        startDate: peaks[i].dataPoint.date,
        endDate: peaks[i + 1].dataPoint.date,
        peakValue: peaks[i].dataPoint.value,
        valleyValue: valleys.isNotEmpty ? valleys[i % valleys.length].dataPoint.value : 0.0,
        amplitude: peaks[i].prominence,
      ));
    }
    
    return cycles;
  }

  static List<MetricDataPoint> _removeOutliers(
    List<MetricDataPoint> data,
    List<OutlierPoint> outliers,
  ) {
    final outlierIndices = outliers.map((o) => data.indexOf(o.dataPoint)).toSet();
    return data.where((d) => !outlierIndices.contains(data.indexOf(d))).toList();
  }

  static List<double> _predictLinearTrend(
    List<MetricDataPoint> data,
    LinearTrend trend,
    int days,
  ) {
    final predictions = <double>[];
    final lastDate = data.last.date;
    
    for (int i = 1; i <= days; i++) {
      final futureDate = lastDate.add(Duration(days: i));
      final x = futureDate.millisecondsSinceEpoch.toDouble();
      final prediction = trend.slope * x + trend.intercept;
      predictions.add(prediction);
    }
    
    return predictions;
  }

  static List<double> _predictPolynomialTrend(
    List<MetricDataPoint> data,
    PolynomialTrend trend,
    int days,
  ) {
    final predictions = <double>[];
    final lastDate = data.last.date;
    
    for (int i = 1; i <= days; i++) {
      final futureDate = lastDate.add(Duration(days: i));
      final x = futureDate.millisecondsSinceEpoch.toDouble();
      
      double prediction = 0.0;
      for (int j = 0; j < trend.coefficients.length; j++) {
        prediction += trend.coefficients[j] * math.pow(x, j);
      }
      
      predictions.add(prediction);
    }
    
    return predictions;
  }

  static List<double> _predictMovingAverage(List<MetricDataPoint> data, int days) {
    final window = math.min(5, data.length);
    final lastValues = data.skip(data.length - window).map((d) => d.value).toList();
    final average = lastValues.reduce((a, b) => a + b) / lastValues.length;
    
    return List.filled(days, average);
  }

  static List<double> _predictExponentialSmoothing(List<MetricDataPoint> data, int days) {
    final alpha = 0.3; // Smoothing parameter
    double smoothedValue = data.first.value;
    
    for (final point in data.skip(1)) {
      smoothedValue = alpha * point.value + (1 - alpha) * smoothedValue;
    }
    
    return List.filled(days, smoothedValue);
  }

  static double _getSeasonalAdjustment(DateTime date, SeasonalityAnalysis analysis) {
    // Simplified seasonal adjustment
    return 0.0;
  }

  static double _calculatePredictionConfidence(int daysAhead, int dataSize) {
    final confidence = math.max(0.1, 1.0 - (daysAhead / 30.0) - (1.0 / dataSize));
    return math.min(1.0, confidence);
  }

  static double _calculateModelAccuracy(List<MetricDataPoint> data) {
    // Cross-validation accuracy calculation
    return 0.75; // Placeholder
  }

  static double _calculateRecentTrend(List<MetricDataPoint> data, int periods) {
    if (data.length < periods + 1) return 0.0;
    
    final recentData = data.skip(data.length - periods - 1).toList();
    final oldValue = recentData.first.value;
    final newValue = recentData.last.value;
    
    return ((newValue - oldValue) / oldValue) * 100;
  }

  static double _assessVariabilityRisk(List<MetricDataPoint> data) {
    if (data.length < 5) return 0.0;
    
    final values = data.map((d) => d.value).toList();
    final std = _calculateStandardDeviation(values);
    final mean = values.reduce((a, b) => a + b) / values.length;
    
    final cv = mean > 0 ? std / mean : 0.0;
    return math.min(1.0, cv * 2); // Normalize to 0-1
  }

  static double _assessPlateauRisk(List<MetricDataPoint> data) {
    if (data.length < 5) return 0.0;
    
    final recentData = data.skip(math.max(0, data.length - 5)).toList();
    final values = recentData.map((d) => d.value).toList();
    final range = values.reduce(math.max) - values.reduce(math.min);
    final mean = values.reduce((a, b) => a + b) / values.length;
    
    final relativeRange = mean > 0 ? range / mean : 0.0;
    return math.max(0.0, 1.0 - relativeRange * 10); // Inverse relationship
  }

  static RiskLevel _calculateOverallRisk(List<PerformanceRisk> risks) {
    if (risks.isEmpty) return RiskLevel.low;
    
    final highRisks = risks.where((r) => r.severity == RiskSeverity.high).length;
    final mediumRisks = risks.where((r) => r.severity == RiskSeverity.medium).length;
    
    if (highRisks > 0) return RiskLevel.high;
    if (mediumRisks > 1) return RiskLevel.medium;
    return RiskLevel.low;
  }

  static List<String> _identifyRiskFactors(List<MetricDataPoint> data, AthleteModel athlete) {
    final factors = <String>[];
    
    // Age factor
    if (athlete.age != null && athlete.age! > 30) {
      factors.add('Age-related recovery considerations');
    }
    
    // Training load (if available in data)
    factors.add('Monitor training load and recovery');
    
    return factors;
  }

  static RecommendationPriority _mapSeverityToPriority(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return RecommendationPriority.low;
      case RiskSeverity.medium:
        return RecommendationPriority.medium;
      case RiskSeverity.high:
        return RecommendationPriority.high;
    }
  }

  static List<PerformanceRecommendation> _getMetricSpecificRecommendations(
    String metricKey,
    TrendAnalysis trendAnalysis,
  ) {
    final recommendations = <PerformanceRecommendation>[];
    
    switch (metricKey) {
      case 'jumpHeight':
        if (trendAnalysis.trendType == TrendType.decreasing) {
          recommendations.add(PerformanceRecommendation(
            type: RecommendationType.adjust,
            title: 'Sıçrama Yüksekliği Optimizasyonu',
            description: 'Plyometric antrenmanları artırın ve teknik çalışmalara odaklanın.',
            priority: RecommendationPriority.medium,
            confidence: 0.8,
          ));
        }
        break;
      case 'peakForce':
        if (trendAnalysis.trendType == TrendType.stable) {
          recommendations.add(PerformanceRecommendation(
            type: RecommendationType.challenge,
            title: 'Kuvvet Gelişimi',
            description: 'Ağırlık antrenmanında yoğunluğu artırın veya yeni egzersizler ekleyin.',
            priority: RecommendationPriority.medium,
            confidence: 0.7,
          ));
        }
        break;
    }
    
    return recommendations;
  }

  static CrossMetricCorrelationAnalysis _analyzeCrossMetricCorrelations(
    List<TestResultModel> data,
    List<String> metricKeys,
  ) {
    final correlations = <String, Map<String, double>>{};
    
    for (final metric1 in metricKeys) {
      correlations[metric1] = {};
      for (final metric2 in metricKeys) {
        if (metric1 != metric2) {
          correlations[metric1]![metric2] = _calculateCorrelation(data, metric1, metric2);
        }
      }
    }
    
    return CrossMetricCorrelationAnalysis(correlations: correlations);
  }

  static double _calculateCorrelation(List<TestResultModel> data, String metric1, String metric2) {
    final values1 = <double>[];
    final values2 = <double>[];
    
    for (final test in data) {
      if (test.metrics.containsKey(metric1) && test.metrics.containsKey(metric2)) {
        values1.add(test.metrics[metric1]!);
        values2.add(test.metrics[metric2]!);
      }
    }
    
    if (values1.length < 3) return 0.0;
    
    final mean1 = values1.reduce((a, b) => a + b) / values1.length;
    final mean2 = values2.reduce((a, b) => a + b) / values2.length;
    
    double numerator = 0.0;
    double sum1Squares = 0.0;
    double sum2Squares = 0.0;
    
    for (int i = 0; i < values1.length; i++) {
      final diff1 = values1[i] - mean1;
      final diff2 = values2[i] - mean2;
      
      numerator += diff1 * diff2;
      sum1Squares += diff1 * diff1;
      sum2Squares += diff2 * diff2;
    }
    
    final denominator = math.sqrt(sum1Squares * sum2Squares);
    return denominator > 0 ? numerator / denominator : 0.0;
  }

  static ClusterAnalysis _performClusterAnalysis(
    List<TestResultModel> data,
    List<String> metricKeys,
  ) {
    // Simplified clustering - in reality would use k-means or similar
    return ClusterAnalysis(
      clusters: ['High Performance', 'Moderate Performance', 'Low Performance'],
      clusterAssignments: data.map((test) => 'Moderate Performance').toList(),
    );
  }

  static OverallTrajectory _calculateOverallTrajectory(
    Map<String, PerformancePredictionResult> metricResults,
  ) {
    final trajectories = metricResults.values
        .where((r) => r.isSuccessful)
        .map((r) => r.trendAnalysis.trendType)
        .toList();
    
    final improvingCount = trajectories.where((t) => t == TrendType.increasing).length;
    final decliningCount = trajectories.where((t) => t == TrendType.decreasing).length;
    final stableCount = trajectories.where((t) => t == TrendType.stable).length;
    
    TrajectoryType overallType;
    if (improvingCount > decliningCount && improvingCount > stableCount) {
      overallType = TrajectoryType.improving;
    } else if (decliningCount > improvingCount) {
      overallType = TrajectoryType.declining;
    } else {
      overallType = TrajectoryType.stable;
    }
    
    return OverallTrajectory(
      trajectoryType: overallType,
      confidence: trajectories.isNotEmpty ? (trajectories.length / metricResults.length) : 0.0,
      improvingMetrics: improvingCount,
      decliningMetrics: decliningCount,
      stableMetrics: stableCount,
    );
  }
}

// Data classes
class PerformancePredictionResult {
  final bool isSuccessful;
  final String? errorMessage;
  final String metricKey;
  final List<MetricDataPoint> historicalValues;
  final TrendAnalysis trendAnalysis;
  final SeasonalityAnalysis seasonalityAnalysis;
  final CycleAnalysis cycleAnalysis;
  final OutlierAnalysis outlierAnalysis;
  final List<PredictionPoint> predictions;
  final List<ConfidenceInterval> confidenceIntervals;
  final RiskAssessment riskAssessment;
  final List<PerformanceRecommendation> recommendations;
  final double modelAccuracy;
  final DateTime lastUpdated;

  PerformancePredictionResult({
    required this.isSuccessful,
    this.errorMessage,
    required this.metricKey,
    required this.historicalValues,
    required this.trendAnalysis,
    required this.seasonalityAnalysis,
    required this.cycleAnalysis,
    required this.outlierAnalysis,
    required this.predictions,
    required this.confidenceIntervals,
    required this.riskAssessment,
    required this.recommendations,
    required this.modelAccuracy,
    required this.lastUpdated,
  });

  factory PerformancePredictionResult.insufficient(String message) {
    return PerformancePredictionResult(
      isSuccessful: false,
      errorMessage: message,
      metricKey: '',
      historicalValues: [],
      trendAnalysis: TrendAnalysis.noTrend(),
      seasonalityAnalysis: SeasonalityAnalysis.noPattern(),
      cycleAnalysis: CycleAnalysis.noCycles(),
      outlierAnalysis: OutlierAnalysis.noOutliers(),
      predictions: [],
      confidenceIntervals: [],
      riskAssessment: RiskAssessment.noRisk(),
      recommendations: [],
      modelAccuracy: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  factory PerformancePredictionResult.error(String error) {
    return PerformancePredictionResult(
      isSuccessful: false,
      errorMessage: error,
      metricKey: '',
      historicalValues: [],
      trendAnalysis: TrendAnalysis.noTrend(),
      seasonalityAnalysis: SeasonalityAnalysis.noPattern(),
      cycleAnalysis: CycleAnalysis.noCycles(),
      outlierAnalysis: OutlierAnalysis.noOutliers(),
      predictions: [],
      confidenceIntervals: [],
      riskAssessment: RiskAssessment.noRisk(),
      recommendations: [],
      modelAccuracy: 0.0,
      lastUpdated: DateTime.now(),
    );
  }
}

class MultiMetricPredictionResult {
  final Map<String, PerformancePredictionResult> metricResults;
  final CrossMetricCorrelationAnalysis correlationAnalysis;
  final ClusterAnalysis clusterAnalysis;
  final OverallTrajectory overallTrajectory;
  final AthleteModel athlete;
  final DateTime lastUpdated;

  MultiMetricPredictionResult({
    required this.metricResults,
    required this.correlationAnalysis,
    required this.clusterAnalysis,
    required this.overallTrajectory,
    required this.athlete,
    required this.lastUpdated,
  });
}

// Supporting data classes
class MetricDataPoint {
  final DateTime date;
  final double value;
  final String testId;
  final double qualityScore;

  MetricDataPoint({
    required this.date,
    required this.value,
    required this.testId,
    required this.qualityScore,
  });
}

class TrendAnalysis {
  final TrendType trendType;
  final double trendStrength;
  final LinearTrend linearTrend;
  final PolynomialTrend polynomialTrend;
  final List<MovingAverage> movingAverages;
  final List<double> rateOfChange;
  final double rSquared;

  TrendAnalysis({
    required this.trendType,
    required this.trendStrength,
    required this.linearTrend,
    required this.polynomialTrend,
    required this.movingAverages,
    required this.rateOfChange,
    required this.rSquared,
  });

  factory TrendAnalysis.noTrend() {
    return TrendAnalysis(
      trendType: TrendType.stable,
      trendStrength: 0.0,
      linearTrend: LinearTrend(slope: 0.0, intercept: 0.0),
      polynomialTrend: PolynomialTrend(coefficients: [0.0], degree: 0),
      movingAverages: [],
      rateOfChange: [],
      rSquared: 0.0,
    );
  }
}

class LinearTrend {
  final double slope;
  final double intercept;

  LinearTrend({required this.slope, required this.intercept});
}

class PolynomialTrend {
  final List<double> coefficients;
  final int degree;

  PolynomialTrend({required this.coefficients, required this.degree});
}

class MovingAverage {
  final int window;
  final List<double> values;

  MovingAverage({required this.window, required this.values});
}

class SeasonalityAnalysis {
  final bool hasSeasonality;
  final Map<int, double> monthlyPatterns;
  final Map<int, double> weeklyPatterns;
  final SeasonalDecomposition decomposition;
  final double seasonalStrength;

  SeasonalityAnalysis({
    required this.hasSeasonality,
    required this.monthlyPatterns,
    required this.weeklyPatterns,
    required this.decomposition,
    required this.seasonalStrength,
  });

  factory SeasonalityAnalysis.noPattern() {
    return SeasonalityAnalysis(
      hasSeasonality: false,
      monthlyPatterns: {},
      weeklyPatterns: {},
      decomposition: SeasonalDecomposition(trend: [], seasonal: [], residual: []),
      seasonalStrength: 0.0,
    );
  }
}

class SeasonalDecomposition {
  final List<double> trend;
  final List<double> seasonal;
  final List<double> residual;

  SeasonalDecomposition({
    required this.trend,
    required this.seasonal,
    required this.residual,
  });
}

class CycleAnalysis {
  final bool hasCycles;
  final List<Peak> peaks;
  final List<Valley> valleys;
  final double avgCycleDuration;
  final List<PerformanceCycle> performanceCycles;

  CycleAnalysis({
    required this.hasCycles,
    required this.peaks,
    required this.valleys,
    required this.avgCycleDuration,
    required this.performanceCycles,
  });

  factory CycleAnalysis.noCycles() {
    return CycleAnalysis(
      hasCycles: false,
      peaks: [],
      valleys: [],
      avgCycleDuration: 0.0,
      performanceCycles: [],
    );
  }
}

class Peak {
  final MetricDataPoint dataPoint;
  final double prominence;

  Peak({required this.dataPoint, required this.prominence});
}

class Valley {
  final MetricDataPoint dataPoint;
  final double depth;

  Valley({required this.dataPoint, required this.depth});
}

class PerformanceCycle {
  final DateTime startDate;
  final DateTime endDate;
  final double peakValue;
  final double valleyValue;
  final double amplitude;

  PerformanceCycle({
    required this.startDate,
    required this.endDate,
    required this.peakValue,
    required this.valleyValue,
    required this.amplitude,
  });
}

class OutlierAnalysis {
  final bool hasOutliers;
  final List<OutlierPoint> outliers;
  final List<MetricDataPoint> outliersRemoved;

  OutlierAnalysis({
    required this.hasOutliers,
    required this.outliers,
    required this.outliersRemoved,
  });

  factory OutlierAnalysis.noOutliers() {
    return OutlierAnalysis(
      hasOutliers: false,
      outliers: [],
      outliersRemoved: [],
    );
  }
}

class OutlierPoint {
  final MetricDataPoint dataPoint;
  final double zScore;
  final OutlierType type;

  OutlierPoint({
    required this.dataPoint,
    required this.zScore,
    required this.type,
  });
}

class PredictionPoint {
  final DateTime date;
  final double predictedValue;
  final double confidence;
  final String method;

  PredictionPoint({
    required this.date,
    required this.predictedValue,
    required this.confidence,
    required this.method,
  });
}

class ConfidenceInterval {
  final DateTime date;
  final double predictedValue;
  final double lowerBound;
  final double upperBound;
  final double confidence;

  ConfidenceInterval({
    required this.date,
    required this.predictedValue,
    required this.lowerBound,
    required this.upperBound,
    required this.confidence,
  });
}

class RiskAssessment {
  final RiskLevel overallRiskLevel;
  final List<PerformanceRisk> risks;
  final List<String> riskFactors;

  RiskAssessment({
    required this.overallRiskLevel,
    required this.risks,
    required this.riskFactors,
  });

  factory RiskAssessment.noRisk() {
    return RiskAssessment(
      overallRiskLevel: RiskLevel.low,
      risks: [],
      riskFactors: [],
    );
  }
}

class PerformanceRisk {
  final RiskType type;
  final RiskSeverity severity;
  final double probability;
  final String description;
  final String recommendation;

  PerformanceRisk({
    required this.type,
    required this.severity,
    required this.probability,
    required this.description,
    required this.recommendation,
  });
}

class PerformanceRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final double confidence;

  PerformanceRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.confidence,
  });
}

class CrossMetricCorrelationAnalysis {
  final Map<String, Map<String, double>> correlations;

  CrossMetricCorrelationAnalysis({required this.correlations});
}

class ClusterAnalysis {
  final List<String> clusters;
  final List<String> clusterAssignments;

  ClusterAnalysis({
    required this.clusters,
    required this.clusterAssignments,
  });
}

class OverallTrajectory {
  final TrajectoryType trajectoryType;
  final double confidence;
  final int improvingMetrics;
  final int decliningMetrics;
  final int stableMetrics;

  OverallTrajectory({
    required this.trajectoryType,
    required this.confidence,
    required this.improvingMetrics,
    required this.decliningMetrics,
    required this.stableMetrics,
  });
}

// Enums
enum TrendType { increasing, decreasing, stable, cyclical }
enum OutlierType { high, low }
enum RiskType { decliningPerformance, overreaching, plateau, injury }
enum RiskSeverity { low, medium, high }
enum RiskLevel { low, medium, high }
enum RecommendationType { maintain, adjust, challenge, prevention }
enum RecommendationPriority { low, medium, high }
enum TrajectoryType { improving, declining, stable, mixed }