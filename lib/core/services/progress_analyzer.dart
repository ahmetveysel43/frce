import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/test_result_model.dart';
import '../../data/models/athlete_model.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// İlerleme analizi ve gelişmiş istatistiksel hesaplamalar servisi
/// Smart Metrics uygulamasından adapte edilmiş performans analizi
class ProgressAnalyzer {
  /// Sporcu için kapsamlı performans analizi
  static Future<PerformanceAnalysis> analyzePerformance({
    required String athleteId,
    required AthleteModel athlete,
    required List<TestResultModel> results,
    required TestType testType,
    String? metricKey,
    DateTimeRange? dateRange,
    int? lastNDays,
  }) async {
    try {
      AppLogger.info('🔬 Performans analizi başladı: ${athlete.firstName} ${athlete.lastName}');
      
      // Verileri filtrele
      var filteredResults = _filterResults(results, testType, dateRange, lastNDays);
      
      if (filteredResults.isEmpty) {
        return PerformanceAnalysis.empty(athleteId, testType);
      }
      
      // Ana metriği belirle
      final primaryMetric = metricKey ?? _getPrimaryMetricKey(testType);
      
      // Metrik değerlerini çıkar
      final metricValues = _extractMetricValues(filteredResults, primaryMetric);
      if (metricValues.isEmpty) {
        return PerformanceAnalysis.empty(athleteId, testType);
      }
      
      // Temel istatistikler
      final basicStats = _calculateBasicStatistics(metricValues);
      
      // Gelişmiş metrikler
      final advancedStats = await _calculateAdvancedMetrics(
        filteredResults, 
        metricValues, 
        primaryMetric,
        athlete,
      );
      
      // Trend analizi
      final trendAnalysis = _calculateTrendAnalysis(filteredResults, metricValues);
      
      // AI öngörüleri
      final insights = await _generatePerformanceInsights(
        filteredResults,
        metricValues,
        trendAnalysis,
        athlete,
        testType,
      );
      
      final analysis = PerformanceAnalysis(
        athleteId: athleteId,
        testType: testType,
        metricKey: primaryMetric,
        analysisDate: DateTime.now(),
        totalTests: filteredResults.length,
        dateRange: dateRange,
        
        // Temel istatistikler
        mean: basicStats['mean']!,
        standardDeviation: basicStats['stdDev']!,
        coefficientOfVariation: basicStats['cv']!,
        minimum: basicStats['min']!,
        maximum: basicStats['max']!,
        range: basicStats['range']!,
        median: basicStats['median']!,
        q25: basicStats['q25']!,
        q75: basicStats['q75']!,
        iqr: basicStats['iqr']!,
        
        // Gelişmiş metrikler
        swc: advancedStats['swc']!,
        mdc: advancedStats['mdc']!,
        typicalityIndex: advancedStats['typicalityIndex']!,
        testRetestReliability: advancedStats['testRetestReliability']!,
        icc: advancedStats['icc']!,
        
        // Trend analizi
        trendSlope: trendAnalysis['slope']!,
        trendRSquared: trendAnalysis['rSquared']!,
        trendStability: trendAnalysis['stability']!,
        recentChange: trendAnalysis['recentChange']!,
        recentChangePercent: trendAnalysis['recentChangePercent']!,
        
        // Performans değerlendirmesi
        performanceClass: _classifyPerformance(basicStats['mean']!, testType),
        performanceTrend: _classifyTrend(trendAnalysis['slope']!),
        momentum: _calculateMomentum(metricValues),
        
        // Ham veriler
        performanceValues: metricValues,
        testDates: filteredResults.map((r) => r.testDate).toList(),
        zScores: _calculateZScores(metricValues, basicStats['mean']!, basicStats['stdDev']!),
        
        // AI öngörüleri
        insights: insights,
        confidenceLevel: _calculateConfidenceLevel(filteredResults.length),
        
        // Benchmark karşılaştırması
        benchmarkData: await _getBenchmarkData(testType, athlete),
        
        // Öneriler
        recommendations: _generateRecommendations(trendAnalysis, insights, testType),
      );
      
      AppLogger.success('✅ Performans analizi tamamlandı: ${analysis.totalTests} test analiz edildi');
      return analysis;
      
    } catch (e, stackTrace) {
      AppLogger.error('Performans analizi hatası', e, stackTrace);
      return PerformanceAnalysis.empty(athleteId, testType);
    }
  }
  
  /// Çoklu sporcu karşılaştırması
  static Future<TeamPerformanceAnalysis> analyzeTeamPerformance({
    required List<String> athleteIds,
    required Map<String, AthleteModel> athletes,
    required List<TestResultModel> allResults,
    required TestType testType,
    DateTimeRange? dateRange,
  }) async {
    try {
      AppLogger.info('👥 Takım analizi başladı: ${athleteIds.length} sporcu');
      
      final athleteAnalyses = <String, PerformanceAnalysis>{};
      final teamMetrics = <String, double>{};
      
      // Her sporcu için analiz
      for (final athleteId in athleteIds) {
        final athlete = athletes[athleteId];
        if (athlete == null) continue;
        
        final athleteResults = allResults.where((r) => r.athleteId == athleteId).toList();
        
        final analysis = await analyzePerformance(
          athleteId: athleteId,
          athlete: athlete,
          results: athleteResults,
          testType: testType,
          dateRange: dateRange,
        );
        
        athleteAnalyses[athleteId] = analysis;
      }
      
      // Takım istatistikleri
      final teamValues = athleteAnalyses.values.where((a) => a.totalTests > 0).toList();
      if (teamValues.isNotEmpty) {
        final teamMeans = teamValues.map((a) => a.mean).toList();
        teamMetrics['teamAverage'] = teamMeans.reduce((a, b) => a + b) / teamMeans.length;
        teamMetrics['teamStdDev'] = _calculateStandardDeviation(teamMeans);
        teamMetrics['teamBest'] = teamMeans.reduce(math.max);
        teamMetrics['teamWorst'] = teamMeans.reduce(math.min);
        teamMetrics['teamRange'] = teamMetrics['teamBest']! - teamMetrics['teamWorst']!;
        teamMetrics['teamCV'] = teamMetrics['teamStdDev']! / teamMetrics['teamAverage']! * 100;
      }
      
      return TeamPerformanceAnalysis(
        athleteIds: athleteIds,
        testType: testType,
        analysisDate: DateTime.now(),
        dateRange: dateRange,
        athleteAnalyses: athleteAnalyses,
        teamMetrics: teamMetrics,
        rankings: _calculateRankings(athleteAnalyses),
        teamInsights: _generateTeamInsights(athleteAnalyses, teamMetrics),
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Takım analizi hatası', e, stackTrace);
      return TeamPerformanceAnalysis.empty(athleteIds, testType);
    }
  }
  
  /// Benchmark karşılaştırması
  static Future<BenchmarkComparison> compareToBenchmarks({
    required PerformanceAnalysis analysis,
    required AthleteModel athlete,
    required TestType testType,
  }) async {
    try {
      final benchmarks = await _getBenchmarkData(testType, athlete);
      
      if (benchmarks.isEmpty) {
        return BenchmarkComparison.empty();
      }
      
      final comparisons = <String, BenchmarkResult>{};
      
      for (final entry in benchmarks.entries) {
        final benchmarkType = entry.key;
        final benchmarkValue = entry.value;
        
        final percentile = _calculatePercentile(analysis.mean, benchmarkValue);
        final zScore = _calculateZScore(analysis.mean, benchmarkValue['mean'] ?? 0, benchmarkValue['stdDev'] ?? 1);
        
        comparisons[benchmarkType] = BenchmarkResult(
          benchmarkType: benchmarkType,
          athleteValue: analysis.mean,
          benchmarkMean: benchmarkValue['mean'] ?? 0,
          benchmarkStdDev: benchmarkValue['stdDev'] ?? 1,
          percentile: percentile,
          zScore: zScore,
          classification: _classifyBenchmarkPerformance(percentile),
          improvement: _calculateRequiredImprovement(analysis.mean, benchmarkValue),
        );
      }
      
      return BenchmarkComparison(
        testType: testType,
        athlete: athlete,
        comparisons: comparisons,
        overallRank: _calculateOverallRank(comparisons),
        strengthAreas: _identifyStrengths(comparisons),
        improvementAreas: _identifyImprovementAreas(comparisons),
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Benchmark karşılaştırma hatası', e, stackTrace);
      return BenchmarkComparison.empty();
    }
  }
  
  // ===== PRIVATE HELPER METHODS =====
  
  /// Sonuçları filtrele
  static List<TestResultModel> _filterResults(
    List<TestResultModel> results,
    TestType testType,
    DateTimeRange? dateRange,
    int? lastNDays,
  ) {
    var filtered = results.where((r) => 
        r.testTypeEnum == testType && 
        r.statusEnum == TestStatus.completed &&
        (r.qualityScore ?? 0) >= 40 // Minimum kalite skoru
    ).toList();
    
    if (dateRange != null) {
      filtered = filtered.where((r) => 
          r.testDate.isAfter(dateRange.start) && 
          r.testDate.isBefore(dateRange.end)
      ).toList();
    } else if (lastNDays != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: lastNDays));
      filtered = filtered.where((r) => r.testDate.isAfter(cutoffDate)).toList();
    }
    
    // Tarihe göre sırala
    filtered.sort((a, b) => a.testDate.compareTo(b.testDate));
    
    return filtered;
  }
  
  /// Ana metrik anahtarını belirle
  static String _getPrimaryMetricKey(TestType testType) {
    switch (testType) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        return 'jumpHeight';
      case TestType.isometricMidThighPull:
      case TestType.isometricSquat:
        return 'peakForce';
      case TestType.staticBalance:
      case TestType.singleLegBalance:
        return 'stabilityIndex';
      default:
        return 'peakForce';
    }
  }
  
  /// Metrik değerlerini çıkar
  static List<double> _extractMetricValues(List<TestResultModel> results, String metricKey) {
    return results
        .map((r) => r.metrics[metricKey])
        .where((value) => value != null)
        .cast<double>()
        .toList();
  }
  
  /// Temel istatistikler
  static Map<String, double> _calculateBasicStatistics(List<double> values) {
    if (values.isEmpty) return {};
    
    values.sort();
    final n = values.length;
    
    final mean = values.reduce((a, b) => a + b) / n;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / n;
    final stdDev = math.sqrt(variance);
    final cv = mean != 0 ? (stdDev / mean * 100) : 0.0;
    
    final min = values.first;
    final max = values.last;
    final range = max - min;
    
    final median = n % 2 == 1 ? values[n ~/ 2] : (values[n ~/ 2 - 1] + values[n ~/ 2]) / 2;
    final q25 = values[n ~/ 4];
    final q75 = values[(3 * n) ~/ 4];
    final iqr = q75 - q25;
    
    return {
      'mean': mean,
      'stdDev': stdDev,
      'cv': cv,
      'min': min,
      'max': max,
      'range': range,
      'median': median,
      'q25': q25,
      'q75': q75,
      'iqr': iqr,
    };
  }
  
  /// Gelişmiş metrikler
  static Future<Map<String, double>> _calculateAdvancedMetrics(
    List<TestResultModel> results,
    List<double> values,
    String metricKey,
    AthleteModel athlete,
  ) async {
    final n = values.length;
    final mean = values.reduce((a, b) => a + b) / n;
    final stdDev = _calculateStandardDeviation(values);
    
    // Smallest Worthwhile Change (SWC) - Hopkins methodology
    final swc = _calculateSWC(values, stdDev);
    
    // Minimal Detectable Change (MDC)
    final mdc = await _calculateMDC(results, metricKey);
    
    // Typicality Index (son testin normalliği)
    final typicalityIndex = values.isNotEmpty ? 
        100 - ((values.last - mean).abs() / stdDev * 100) : 0.0;
    
    // Test-retest reliability
    final testRetestReliability = await _calculateTestRetestReliability(results, metricKey);
    
    // Intraclass Correlation Coefficient (ICC)
    final icc = _calculateICC(values);
    
    return {
      'swc': swc,
      'mdc': mdc,
      'typicalityIndex': math.max(0, typicalityIndex),
      'testRetestReliability': testRetestReliability,
      'icc': icc,
    };
  }
  
  /// Trend analizi
  static Map<String, double> _calculateTrendAnalysis(
    List<TestResultModel> results,
    List<double> values,
  ) {
    if (values.length < 2) {
      return {
        'slope': 0.0,
        'rSquared': 0.0,
        'stability': 0.0,
        'recentChange': 0.0,
        'recentChangePercent': 0.0,
      };
    }
    
    // Linear regression
    final n = values.length;
    final xValues = List.generate(n, (i) => i.toDouble());
    
    final xMean = xValues.reduce((a, b) => a + b) / n;
    final yMean = values.reduce((a, b) => a + b) / n;
    
    double numerator = 0.0;
    double denominator = 0.0;
    
    for (int i = 0; i < n; i++) {
      final xDiff = xValues[i] - xMean;
      final yDiff = values[i] - yMean;
      numerator += xDiff * yDiff;
      denominator += xDiff * xDiff;
    }
    
    final slope = denominator != 0 ? numerator / denominator : 0.0;
    
    // R-squared
    double ssRes = 0.0;
    double ssTot = 0.0;
    
    for (int i = 0; i < n; i++) {
      final predicted = yMean + slope * (xValues[i] - xMean);
      ssRes += (values[i] - predicted) * (values[i] - predicted);
      ssTot += (values[i] - yMean) * (values[i] - yMean);
    }
    
    final rSquared = ssTot != 0 ? 1 - (ssRes / ssTot) : 0.0;
    final stability = math.max(0.0, rSquared * 100);
    
    // Son değişim
    final recentChange = values.last - values[math.max(0, values.length - 2)];
    final recentChangePercent = values.length > 1 && values[values.length - 2] != 0 
        ? (recentChange / values[values.length - 2]) * 100 
        : 0.0;
    
    return {
      'slope': slope,
      'rSquared': rSquared,
      'stability': stability,
      'recentChange': recentChange,
      'recentChangePercent': recentChangePercent,
    };
  }
  
  /// AI performans öngörüleri
  static Future<List<PerformanceInsight>> _generatePerformanceInsights(
    List<TestResultModel> results,
    List<double> values,
    Map<String, double> trendAnalysis,
    AthleteModel athlete,
    TestType testType,
  ) async {
    final insights = <PerformanceInsight>[];
    
    // Trend tabanlı öngörüler
    final slope = trendAnalysis['slope'] ?? 0.0;
    final rSquared = trendAnalysis['rSquared'] ?? 0.0;
    
    if (slope > 0.1 && rSquared > 0.3) {
      insights.add(PerformanceInsight(
        type: InsightType.performance,
        title: 'Olumlu Performans Trendi',
        description: 'Son testlerde tutarlı bir gelişim görülüyor. Bu trendi sürdürmek için mevcut antrenman programına devam edilmesi öneriliyor.',
        confidence: (rSquared * 100).round(),
        actionItems: ['Mevcut antrenman yoğunluğunu koruyun', 'İlerlemeyi haftalık takip edin'],
        priority: InsightPriority.medium,
      ));
    } else if (slope < -0.1 && rSquared > 0.3) {
      insights.add(PerformanceInsight(
        type: InsightType.warning,
        title: 'Performans Düşüşü Tespit Edildi',
        description: 'Son testlerde performansta azalma gözlemleniyor. Antrenman yükü ve toparlanma süreçleri gözden geçirilmeli.',
        confidence: (rSquared * 100).round(),
        actionItems: ['Antrenman yükünü azaltın', 'Dinlenme günlerini artırın', 'Beslenme planını gözden geçirin'],
        priority: InsightPriority.high,
      ));
    }
    
    // Tutarlılık analizi
    final cv = values.isNotEmpty ? _calculateStandardDeviation(values) / values.reduce((a, b) => a + b) * values.length * 100 : 0.0;
    
    if (cv > 15) {
      insights.add(PerformanceInsight(
        type: InsightType.technique,
        title: 'Performans Tutarlılığında Sorun',
        description: 'Test sonuçlarında yüksek değişkenlik var (%${cv.toStringAsFixed(1)} CV). Teknik tutarlılık üzerinde çalışılması gerekiyor.',
        confidence: 85,
        actionItems: ['Teknik antrenmanları artırın', 'Test protokolünü gözden geçirin', 'Isınma rutinini standardize edin'],
        priority: InsightPriority.medium,
      ));
    }
    
    // Yaş ve cinsiyete dayalı öngörüler
    if (athlete.dateOfBirth != null) {
      final age = DateTime.now().difference(athlete.dateOfBirth!).inDays ~/ 365;
      
      if (age < 18 && slope > 0) {
        insights.add(PerformanceInsight(
          type: InsightType.training,
          title: 'Gelişim Döneminde Olumlu İlerleme',
          description: 'Gelişim çağındaki hızlı ilerleme normaldir. Teknik gelişim ve yaralanma önleme öncelikli olmalı.',
          confidence: 75,
          actionItems: ['Teknik eğitime odaklanın', 'Aşırı yüklemeden kaçının', 'Çok yönlü antrenman yapın'],
          priority: InsightPriority.low,
        ));
      } else if (age > 30 && slope < 0) {
        insights.add(PerformanceInsight(
          type: InsightType.training,
          title: 'Yaşa Bağlı Performans Adaptasyonu',
          description: 'Yaş ilerledikçe performans korunması daha önemli hale gelir. Toparlanma ve sürdürülebilirlik odaklı plan gerekli.',
          confidence: 70,
          actionItems: ['Toparlanma süresini artırın', 'Kuvvet antrenmanına ağırlık verin', 'Esneklik çalışmalarını artırın'],
          priority: InsightPriority.medium,
        ));
      }
    }
    
    return insights;
  }
  
  /// Standard deviation hesaplama
  static double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }
  
  /// SWC hesaplama (Hopkins methodology)
  static double _calculateSWC(List<double> values, double stdDev) {
    // Population-based SWC (0.2 × between-subject SD)
    return stdDev * 0.2;
  }
  
  /// MDC hesaplama
  static Future<double> _calculateMDC(List<TestResultModel> results, String metricKey) async {
    // Test-retest reliability tabanlı MDC hesaplama
    // Simplified implementation - gerçek ICC değeri gerekli
    final reliability = await _calculateTestRetestReliability(results, metricKey);
    final sem = _calculateStandardDeviation(results.map((r) => r.metrics[metricKey] ?? 0.0).toList()) * math.sqrt(1 - reliability);
    return 1.96 * math.sqrt(2) * sem; // 95% confidence
  }
  
  /// Test-retest güvenilirlik
  static Future<double> _calculateTestRetestReliability(List<TestResultModel> results, String metricKey) async {
    // Consecutive day pairs'e dayalı reliability
    // Simplified - aynı gün tekrar testleri veya ardışık günler
    if (results.length < 2) return 0.0;
    
    final pairs = <List<double>>[];
    
    for (int i = 1; i < results.length; i++) {
      final current = results[i];
      final previous = results[i - 1];
      
      final daysDiff = current.testDate.difference(previous.testDate).inDays;
      if (daysDiff <= 3) { // 3 gün içindeki testler
        final currentValue = current.metrics[metricKey];
        final previousValue = previous.metrics[metricKey];
        
        if (currentValue != null && previousValue != null) {
          pairs.add([previousValue, currentValue]);
        }
      }
    }
    
    if (pairs.length < 3) return 0.0;
    
    // Pearson korelasyonu hesapla
    final x = pairs.map((p) => p[0]).toList();
    final y = pairs.map((p) => p[1]).toList();
    
    return _calculateCorrelation(x, y);
  }
  
  /// ICC hesaplama
  static double _calculateICC(List<double> values) {
    // Simplified ICC(2,1) - absolute agreement
    if (values.length < 3) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / (values.length - 1);
    
    // Simplified ICC calculation
    return math.max(0.0, math.min(1.0, (variance - (variance * 0.1)) / variance));
  }
  
  /// Korelasyon hesaplama
  static double _calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return 0.0;
    
    final n = x.length;
    final xMean = x.reduce((a, b) => a + b) / n;
    final yMean = y.reduce((a, b) => a + b) / n;
    
    double numerator = 0.0;
    double xVariance = 0.0;
    double yVariance = 0.0;
    
    for (int i = 0; i < n; i++) {
      final xDiff = x[i] - xMean;
      final yDiff = y[i] - yMean;
      
      numerator += xDiff * yDiff;
      xVariance += xDiff * xDiff;
      yVariance += yDiff * yDiff;
    }
    
    final denominator = math.sqrt(xVariance * yVariance);
    return denominator != 0 ? numerator / denominator : 0.0;
  }
  
  /// Z-score hesaplama
  static List<double> _calculateZScores(List<double> values, double mean, double stdDev) {
    if (stdDev == 0) return values.map((v) => 0.0).toList();
    return values.map((v) => (v - mean) / stdDev).toList();
  }
  
  /// Tek Z-score hesaplama
  static double _calculateZScore(double value, double mean, double stdDev) {
    return stdDev != 0 ? (value - mean) / stdDev : 0.0;
  }
  
  /// Performans sınıflandırması
  static String _classifyPerformance(double mean, TestType testType) {
    // Test türüne göre performans sınıfları
    // Bu değerler spor bilimi literatüründen alınmalı
    switch (testType) {
      case TestType.counterMovementJump:
        if (mean >= 60) return 'Elit';
        if (mean >= 45) return 'Çok İyi';
        if (mean >= 35) return 'İyi';
        if (mean >= 25) return 'Orta';
        return 'Geliştirilmeli';
      
      case TestType.isometricMidThighPull:
        final relativeForce = mean / 70; // Ortalama vücut ağırlığı varsayımı
        if (relativeForce >= 4.0) return 'Elit';
        if (relativeForce >= 3.0) return 'Çok İyi';
        if (relativeForce >= 2.5) return 'İyi';
        if (relativeForce >= 2.0) return 'Orta';
        return 'Geliştirilmeli';
      
      default:
        return 'Değerlendirilmedi';
    }
  }
  
  /// Trend sınıflandırması
  static String _classifyTrend(double slope) {
    if (slope > 0.1) return 'Gelişen';
    if (slope < -0.1) return 'Azalan';
    return 'Stabil';
  }
  
  /// Momentum hesaplama
  static double _calculateMomentum(List<double> values) {
    if (values.length < 3) return 0.0;
    
    // Son 3 testin momentumu
    final recent = values.sublist(math.max(0, values.length - 3));
    double momentum = 0.0;
    
    for (int i = 1; i < recent.length; i++) {
      final change = recent[i] - recent[i - 1];
      momentum += change * (i + 1); // Ağırlıklı değişim
    }
    
    return momentum / recent.length;
  }
  
  /// Güven seviyesi hesaplama
  static double _calculateConfidenceLevel(int sampleSize) {
    if (sampleSize >= 30) return 95.0;
    if (sampleSize >= 15) return 90.0;
    if (sampleSize >= 8) return 80.0;
    if (sampleSize >= 5) return 70.0;
    return 60.0;
  }
  
  /// Benchmark verileri
  static Future<Map<String, Map<String, double>>> _getBenchmarkData(TestType testType, AthleteModel athlete) async {
    // Normative data - gerçek uygulamada veritabanından gelecek
    final benchmarks = <String, Map<String, double>>{};
    
    // Age group is determined but not currently used in benchmark logic
    // Future enhancement: use ageGroup for age-specific normative data
    
    // Cinsiyete göre normlar
    final gender = athlete.gender?.toLowerCase() ?? 'male';
    
    switch (testType) {
      case TestType.counterMovementJump:
        if (gender == 'male') {
          benchmarks['recreational'] = {'mean': 35.0, 'stdDev': 8.0};
          benchmarks['trained'] = {'mean': 45.0, 'stdDev': 6.0};
          benchmarks['elite'] = {'mean': 60.0, 'stdDev': 5.0};
        } else {
          benchmarks['recreational'] = {'mean': 25.0, 'stdDev': 6.0};
          benchmarks['trained'] = {'mean': 35.0, 'stdDev': 5.0};
          benchmarks['elite'] = {'mean': 45.0, 'stdDev': 4.0};
        }
        break;
      
      case TestType.isometricMidThighPull:
        if (gender == 'male') {
          benchmarks['recreational'] = {'mean': 2000.0, 'stdDev': 400.0};
          benchmarks['trained'] = {'mean': 2800.0, 'stdDev': 350.0};
          benchmarks['elite'] = {'mean': 3500.0, 'stdDev': 300.0};
        } else {
          benchmarks['recreational'] = {'mean': 1400.0, 'stdDev': 300.0};
          benchmarks['trained'] = {'mean': 2000.0, 'stdDev': 250.0};
          benchmarks['elite'] = {'mean': 2500.0, 'stdDev': 200.0};
        }
        break;
      
      default:
        break;
    }
    
    return benchmarks;
  }
  
  /// Öneriler oluştur
  static List<String> _generateRecommendations(
    Map<String, double> trendAnalysis,
    List<PerformanceInsight> insights,
    TestType testType,
  ) {
    final recommendations = <String>[];
    
    final slope = trendAnalysis['slope'] ?? 0.0;
    final stability = trendAnalysis['stability'] ?? 0.0;
    
    // Trend tabanlı öneriler
    if (slope > 0.1) {
      recommendations.add('Mevcut antrenman programı etkili, devam edin');
      recommendations.add('İlerleme kaydını düzenli tutun');
    } else if (slope < -0.1) {
      recommendations.add('Antrenman yükünü ve toparlanmayı gözden geçirin');
      recommendations.add('Uzman danışmanlığı alın');
    }
    
    // Stabilite tabanlı öneriler
    if (stability < 50) {
      recommendations.add('Test tutarlılığını artırmak için protokolü standardize edin');
      recommendations.add('Isınma rutinini optimize edin');
    }
    
    // Test türü özel öneriler
    switch (testType) {
      case TestType.counterMovementJump:
        recommendations.add('Pliometrik antrenmanları artırın');
        recommendations.add('Alt ekstremite kuvvet çalışmaları yapın');
        break;
      case TestType.isometricMidThighPull:
        recommendations.add('Maksimal kuvvet antrenmanlarına odaklanın');
        recommendations.add('RFD geliştirici alıştırmalar ekleyin');
        break;
      default:
        break;
    }
    
    return recommendations;
  }
  
  /// Percentile hesaplama
  static double _calculatePercentile(double value, Map<String, double> benchmark) {
    final mean = benchmark['mean'] ?? 0.0;
    final stdDev = benchmark['stdDev'] ?? 1.0;
    
    final zScore = _calculateZScore(value, mean, stdDev);
    
    // Z-score'u percentile'a çevir (yaklaşık)
    if (zScore >= 2.0) return 98.0;
    if (zScore >= 1.5) return 93.0;
    if (zScore >= 1.0) return 84.0;
    if (zScore >= 0.5) return 69.0;
    if (zScore >= 0.0) return 50.0;
    if (zScore >= -0.5) return 31.0;
    if (zScore >= -1.0) return 16.0;
    if (zScore >= -1.5) return 7.0;
    if (zScore >= -2.0) return 2.0;
    return 1.0;
  }
  
  /// Benchmark performans sınıflandırması
  static String _classifyBenchmarkPerformance(double percentile) {
    if (percentile >= 90) return 'Üstün';
    if (percentile >= 75) return 'İyi';
    if (percentile >= 50) return 'Ortalama';
    if (percentile >= 25) return 'Ortalama Altı';
    return 'Düşük';
  }
  
  /// Gerekli gelişim hesaplama
  static double _calculateRequiredImprovement(double currentValue, Map<String, double> benchmark) {
    final targetValue = (benchmark['mean'] ?? 0.0) + (benchmark['stdDev'] ?? 0.0); // +1 SD hedefi
    return math.max(0, targetValue - currentValue);
  }
  
  /// Takım sıralaması
  static Map<String, int> _calculateRankings(Map<String, PerformanceAnalysis> analyses) {
    final rankings = <String, int>{};
    
    final sortedEntries = analyses.entries
        .where((entry) => entry.value.totalTests > 0)
        .toList()
      ..sort((a, b) => b.value.mean.compareTo(a.value.mean));
    
    for (int i = 0; i < sortedEntries.length; i++) {
      rankings[sortedEntries[i].key] = i + 1;
    }
    
    return rankings;
  }
  
  /// Takım öngörüleri
  static List<String> _generateTeamInsights(
    Map<String, PerformanceAnalysis> analyses,
    Map<String, double> teamMetrics,
  ) {
    final insights = <String>[];
    
    final teamCV = teamMetrics['teamCV'] ?? 0.0;
    if (teamCV > 20) {
      insights.add('Takımda yüksek performans değişkenliği var - bireysel yaklaşım gerekli');
    } else if (teamCV < 10) {
      insights.add('Takım performansı homojen - grup antrenmanları etkili olabilir');
    }
    
    final improvingCount = analyses.values
        .where((a) => a.performanceTrend == 'Gelişen')
        .length;
    
    final totalCount = analyses.values.where((a) => a.totalTests > 0).length;
    
    if (improvingCount / totalCount > 0.7) {
      insights.add('Takımın %${((improvingCount / totalCount) * 100).round()}\'i gelişme gösteriyor');
    }
    
    return insights;
  }
  
  /// Güçlü alanları tespit et
  static List<String> _identifyStrengths(Map<String, BenchmarkResult> comparisons) {
    return comparisons.entries
        .where((entry) => entry.value.percentile >= 75)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Gelişim alanları tespit et
  static List<String> _identifyImprovementAreas(Map<String, BenchmarkResult> comparisons) {
    return comparisons.entries
        .where((entry) => entry.value.percentile < 50)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Genel sıralama hesaplama
  static double _calculateOverallRank(Map<String, BenchmarkResult> comparisons) {
    if (comparisons.isEmpty) return 0.0;
    
    final avgPercentile = comparisons.values
        .map((r) => r.percentile)
        .reduce((a, b) => a + b) / comparisons.length;
    
    return avgPercentile;
  }

  /// Gelişmiş analitik hesaplamalar
  static Future<Map<String, dynamic>> calculateAdvancedAnalytics(
    List<TestResultModel> testResults,
    String athleteId,
  ) async {
    try {
      if (testResults.isEmpty) {
        return {
          'icc': 0.0,
          'sem': 0.0,
          'mdc': 0.0,
          'swc': 0.0,
          'cv': 0.0,
          'reliability': 0.0,
        };
      }

      // Extract primary metric values
      final primaryMetric = testResults.isNotEmpty 
          ? _getPrimaryMetricKey(testResults.first.testTypeEnum)
          : 'peakForce';
      
      final values = testResults
          .map((r) => r.metrics[primaryMetric])
          .where((value) => value != null)
          .cast<double>()
          .toList();

      if (values.isEmpty) {
        return {
          'icc': 0.0,
          'sem': 0.0,
          'mdc': 0.0,
          'swc': 0.0,
          'cv': 0.0,
          'reliability': 0.0,
        };
      }

      // Calculate advanced metrics
      final mean = values.reduce((a, b) => a + b) / values.length;
      final stdDev = _calculateStandardDeviation(values);
      final cv = mean != 0 ? (stdDev / mean * 100) : 0.0;
      final icc = _calculateICC(values);
      final swc = _calculateSWC(values, stdDev);
      
      // Calculate SEM and MDC
      final sem = stdDev * math.sqrt(1 - icc);
      final mdc = 1.96 * math.sqrt(2) * sem;
      
      // Test-retest reliability
      final reliability = await _calculateTestRetestReliability(testResults, primaryMetric);

      return {
        'icc': icc,
        'sem': sem,
        'mdc': mdc,
        'swc': swc,
        'cv': cv,
        'reliability': reliability,
      };

    } catch (e, stackTrace) {
      AppLogger.error('Advanced analytics calculation error', e, stackTrace);
      return {
        'icc': 0.0,
        'sem': 0.0,
        'mdc': 0.0,
        'swc': 0.0,
        'cv': 0.0,
        'reliability': 0.0,
      };
    }
  }
}

// ===== DATA CLASSES =====

/// Performans analizi sonucu
class PerformanceAnalysis {
  final String athleteId;
  final TestType testType;
  final String metricKey;
  final DateTime analysisDate;
  final int totalTests;
  final DateTimeRange? dateRange;
  
  // Temel istatistikler
  final double mean;
  final double standardDeviation;
  final double coefficientOfVariation;
  final double minimum;
  final double maximum;
  final double range;
  final double median;
  final double q25;
  final double q75;
  final double iqr;
  
  // Gelişmiş metrikler
  final double swc;
  final double mdc;
  final double typicalityIndex;
  final double testRetestReliability;
  final double icc;
  
  // Trend analizi
  final double trendSlope;
  final double trendRSquared;
  final double trendStability;
  final double recentChange;
  final double recentChangePercent;
  
  // Performans değerlendirmesi
  final String performanceClass;
  final String performanceTrend;
  final double momentum;
  
  // Ham veriler
  final List<double> performanceValues;
  final List<DateTime> testDates;
  final List<double> zScores;
  
  // AI öngörüleri
  final List<PerformanceInsight> insights;
  final double confidenceLevel;
  
  // Benchmark karşılaştırması
  final Map<String, Map<String, double>> benchmarkData;
  
  // Öneriler
  final List<String> recommendations;

  const PerformanceAnalysis({
    required this.athleteId,
    required this.testType,
    required this.metricKey,
    required this.analysisDate,
    required this.totalTests,
    this.dateRange,
    required this.mean,
    required this.standardDeviation,
    required this.coefficientOfVariation,
    required this.minimum,
    required this.maximum,
    required this.range,
    required this.median,
    required this.q25,
    required this.q75,
    required this.iqr,
    required this.swc,
    required this.mdc,
    required this.typicalityIndex,
    required this.testRetestReliability,
    required this.icc,
    required this.trendSlope,
    required this.trendRSquared,
    required this.trendStability,
    required this.recentChange,
    required this.recentChangePercent,
    required this.performanceClass,
    required this.performanceTrend,
    required this.momentum,
    required this.performanceValues,
    required this.testDates,
    required this.zScores,
    required this.insights,
    required this.confidenceLevel,
    required this.benchmarkData,
    required this.recommendations,
  });
  
  factory PerformanceAnalysis.empty(String athleteId, TestType testType) {
    return PerformanceAnalysis(
      athleteId: athleteId,
      testType: testType,
      metricKey: '',
      analysisDate: DateTime.now(),
      totalTests: 0,
      mean: 0.0,
      standardDeviation: 0.0,
      coefficientOfVariation: 0.0,
      minimum: 0.0,
      maximum: 0.0,
      range: 0.0,
      median: 0.0,
      q25: 0.0,
      q75: 0.0,
      iqr: 0.0,
      swc: 0.0,
      mdc: 0.0,
      typicalityIndex: 0.0,
      testRetestReliability: 0.0,
      icc: 0.0,
      trendSlope: 0.0,
      trendRSquared: 0.0,
      trendStability: 0.0,
      recentChange: 0.0,
      recentChangePercent: 0.0,
      performanceClass: 'Veri Yok',
      performanceTrend: 'Belirsiz',
      momentum: 0.0,
      performanceValues: [],
      testDates: [],
      zScores: [],
      insights: [],
      confidenceLevel: 0.0,
      benchmarkData: {},
      recommendations: [],
    );
  }
}

/// Performans öngörüsü
class PerformanceInsight {
  final InsightType type;
  final String title;
  final String description;
  final int confidence;
  final List<String> actionItems;
  final InsightPriority priority;

  const PerformanceInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    required this.actionItems,
    required this.priority,
  });
}

/// Öngörü türleri
enum InsightType {
  performance,
  technique,
  training,
  injury,
  nutrition,
  warning,
}

/// Öngörü öncelikleri
enum InsightPriority {
  low,
  medium,
  high,
}

/// Takım performans analizi
class TeamPerformanceAnalysis {
  final List<String> athleteIds;
  final TestType testType;
  final DateTime analysisDate;
  final DateTimeRange? dateRange;
  final Map<String, PerformanceAnalysis> athleteAnalyses;
  final Map<String, double> teamMetrics;
  final Map<String, int> rankings;
  final List<String> teamInsights;

  const TeamPerformanceAnalysis({
    required this.athleteIds,
    required this.testType,
    required this.analysisDate,
    this.dateRange,
    required this.athleteAnalyses,
    required this.teamMetrics,
    required this.rankings,
    required this.teamInsights,
  });
  
  factory TeamPerformanceAnalysis.empty(List<String> athleteIds, TestType testType) {
    return TeamPerformanceAnalysis(
      athleteIds: athleteIds,
      testType: testType,
      analysisDate: DateTime.now(),
      athleteAnalyses: {},
      teamMetrics: {},
      rankings: {},
      teamInsights: [],
    );
  }
}

/// Benchmark karşılaştırması
class BenchmarkComparison {
  final TestType testType;
  final AthleteModel athlete;
  final Map<String, BenchmarkResult> comparisons;
  final double overallRank;
  final List<String> strengthAreas;
  final List<String> improvementAreas;

  const BenchmarkComparison({
    required this.testType,
    required this.athlete,
    required this.comparisons,
    required this.overallRank,
    required this.strengthAreas,
    required this.improvementAreas,
  });
  
  factory BenchmarkComparison.empty() {
    return BenchmarkComparison(
      testType: TestType.counterMovementJump,
      athlete: AthleteModel(
        id: '',
        firstName: '',
        lastName: '',
        dateOfBirth: null,
        gender: null,
        height: null,
        weight: null,
        position: null,
        team: null,
        notes: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      comparisons: {},
      overallRank: 0.0,
      strengthAreas: [],
      improvementAreas: [],
    );
  }
}

/// Benchmark sonucu
class BenchmarkResult {
  final String benchmarkType;
  final double athleteValue;
  final double benchmarkMean;
  final double benchmarkStdDev;
  final double percentile;
  final double zScore;
  final String classification;
  final double improvement;

  const BenchmarkResult({
    required this.benchmarkType,
    required this.athleteValue,
    required this.benchmarkMean,
    required this.benchmarkStdDev,
    required this.percentile,
    required this.zScore,
    required this.classification,
    required this.improvement,
  });
}