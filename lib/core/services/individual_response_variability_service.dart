import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../algorithms/statistics_helper.dart';
import '../../data/models/athlete_model.dart';
import '../../data/models/test_result_model.dart';

/// Individual Response Variability Service
/// Atkinson & Batterham (2015) metodolojisi
/// "True and false interindividual differences in the physiological response to an intervention"
class IndividualResponseVariabilityService {
  static final _stats = StatisticsHelper();
  
  /// Bireysel yanıt değişkenliği analizi
  static IRVAnalysisResult analyzeIndividualResponse({
    required AthleteModel athlete,
    required List<TestResultModel> testResults,
    required PopulationNorms populationNorms,
    String? specificTestType,
    int minDataPoints = 3,
  }) {
    debugPrint('🧬 IRV Analysis başlatıldı: ${athlete.fullName}, ${testResults.length} test');
    
    if (testResults.length < minDataPoints) {
      return IRVAnalysisResult.error(
        'IRV analizi için minimum $minDataPoints test gerekli (mevcut: ${testResults.length})'
      );
    }

    // Filter by test type if specified
    final filteredResults = specificTestType != null 
        ? testResults.where((t) => t.testType == specificTestType).toList()
        : testResults;

    if (filteredResults.length < minDataPoints) {
      return IRVAnalysisResult.error(
        'Test türü "$specificTestType" için yetersiz veri (${filteredResults.length}/$minDataPoints)'
      );
    }

    // Extract performance values
    final values = filteredResults.map((t) => t.score ?? 0.0).where((v) => v > 0).toList();
    
    if (values.length < minDataPoints) {
      return IRVAnalysisResult.error('Geçerli performans değeri yetersiz');
    }

    // Sort by date for temporal analysis
    filteredResults.sort((a, b) => a.testDate.compareTo(b.testDate));
    final sortedValues = filteredResults.map((t) => t.score ?? 0.0).toList();

    // Calculate individual statistics
    final individualStats = _calculateIndividualStatistics(sortedValues);
    
    // Calculate true individual response
    final trueResponse = _calculateTrueIndividualResponse(
      individualStats, 
      populationNorms,
      specificTestType ?? 'general',
    );
    
    // Classify response type
    final responseClassification = _classifyIndividualResponse(trueResponse, individualStats);
    
    // Calculate response consistency
    final consistency = _calculateResponseConsistency(sortedValues);
    
    // Generate personalized insights
    final insights = _generatePersonalizedInsights(
      athlete,
      individualStats,
      trueResponse,
      responseClassification,
      consistency,
    );

    // Calculate adaptation potential
    final adaptationPotential = _calculateAdaptationPotential(
      athlete,
      individualStats,
      trueResponse,
      populationNorms,
    );

    return IRVAnalysisResult(
      athleteId: athlete.id,
      athleteName: athlete.fullName,
      testType: specificTestType ?? 'mixed',
      individualStatistics: individualStats,
      trueIndividualResponse: trueResponse,
      responseClassification: responseClassification,
      consistency: consistency,
      adaptationPotential: adaptationPotential,
      personalizedInsights: insights,
      sampleSize: values.length,
      analysisDate: DateTime.now(),
    );
  }

  /// Multiple test types için comprehensive IRV analysis
  static ComprehensiveIRVResult analyzeMultipleTestTypes({
    required AthleteModel athlete,
    required Map<String, List<TestResultModel>> testsByType,
    required Map<String, PopulationNorms> populationNormsByType,
    int minDataPoints = 3,
  }) {
    debugPrint('🧬 Comprehensive IRV Analysis: ${testsByType.keys.join(', ')}');
    
    final results = <String, IRVAnalysisResult>{};
    final crossTestCorrelations = <String, double>{};
    
    // Analyze each test type
    for (final entry in testsByType.entries) {
      final testType = entry.key;
      final tests = entry.value;
      final norms = populationNormsByType[testType];
      
      if (norms != null && tests.length >= minDataPoints) {
        final result = analyzeIndividualResponse(
          athlete: athlete,
          testResults: tests,
          populationNorms: norms,
          specificTestType: testType,
          minDataPoints: minDataPoints,
        );
        
        if (!result.hasError) {
          results[testType] = result;
        }
      }
    }
    
    // Calculate cross-test correlations
    if (results.length >= 2) {
      crossTestCorrelations.addAll(_calculateCrossTestCorrelations(results));
    }
    
    // Generate comprehensive profile
    final profile = _generateComprehensiveProfile(results, crossTestCorrelations);
    
    return ComprehensiveIRVResult(
      athleteId: athlete.id,
      athleteName: athlete.fullName,
      testTypeResults: results,
      crossTestCorrelations: crossTestCorrelations,
      comprehensiveProfile: profile,
      analysisDate: DateTime.now(),
    );
  }

  /// Population comparison için IRV analysis
  static PopulationIRVComparison compareWithPopulation({
    required List<AthleteModel> athletes,
    required Map<String, List<TestResultModel>> allTestResults,
    required PopulationNorms populationNorms,
    String testType = 'general',
  }) {
    debugPrint('🧬 Population IRV Comparison: ${athletes.length} athletes');
    
    final individualResults = <String, IRVAnalysisResult>{};
    final populationMetrics = <String, double>{};
    
    // Analyze each athlete
    for (final athlete in athletes) {
      final athleteTests = allTestResults[athlete.id] ?? [];
      
      if (athleteTests.length >= 3) {
        final result = analyzeIndividualResponse(
          athlete: athlete,
          testResults: athleteTests,
          populationNorms: populationNorms,
          specificTestType: testType,
        );
        
        if (!result.hasError) {
          individualResults[athlete.id] = result;
        }
      }
    }
    
    // Calculate population-level metrics
    if (individualResults.isNotEmpty) {
      populationMetrics.addAll(_calculatePopulationMetrics(individualResults.values.toList()));
    }
    
    return PopulationIRVComparison(
      testType: testType,
      individualResults: individualResults,
      populationMetrics: populationMetrics,
      analysisDate: DateTime.now(),
    );
  }

  // Helper Methods

  /// Individual statistics hesaplama
  static IndividualStatistics _calculateIndividualStatistics(List<double> values) {
    final mean = _stats.calculateMean(values);
    final sd = _stats.calculateStandardDeviation(values);
    final cv = _stats.calculateCV(values);
    
    // Calculate trend
    final trend = _calculateLinearTrend(values);
    
    // Calculate reliability (ICC approximation)
    final reliability = _calculateIndividualReliability(values);
    
    // Calculate typical error
    final typicalError = _calculateIndividualTypicalError(values);
    
    return IndividualStatistics(
      mean: mean,
      standardDeviation: sd,
      coefficientOfVariation: cv,
      trend: trend,
      reliability: reliability,
      typicalError: typicalError,
      sampleSize: values.length,
    );
  }

  /// True individual response hesaplama (Atkinson & Batterham, 2015)
  static TrueIndividualResponse _calculateTrueIndividualResponse(
    IndividualStatistics individualStats,
    PopulationNorms populationNorms,
    String testType,
  ) {
    // Individual change (trend slope)
    final individualChange = individualStats.trend;
    
    // Population typical response
    final populationChange = populationNorms.typicalResponse;
    
    // Individual typical error
    final individualTE = individualStats.typicalError;
    
    // Population typical error
    final populationTE = populationNorms.typicalError;
    
    // True individual response = sqrt(individual_variance - population_variance)
    final individualVariance = math.pow(individualTE, 2);
    final populationVariance = math.pow(populationTE, 2);
    final trueResponseVariance = math.max(0, individualVariance - populationVariance);
    final trueResponse = math.sqrt(trueResponseVariance);
    
    // Response magnitude relative to SWC
    final swc = populationNorms.smallestWorthwhileChange;
    final responseMagnitude = trueResponse / swc;
    
    // Confidence in individual response
    final confidence = _calculateResponseConfidence(
      individualStats.sampleSize,
      individualStats.reliability,
      responseMagnitude,
    );
    
    return TrueIndividualResponse(
      value: trueResponse,
      magnitude: responseMagnitude,
      confidence: confidence,
      isSignificant: responseMagnitude >= 1.0, // >= 1 SWC
      individualChange: individualChange,
      populationChange: populationChange,
    );
  }

  /// Response classification
  static ResponseClassification _classifyIndividualResponse(
    TrueIndividualResponse trueResponse,
    IndividualStatistics individualStats,
  ) {
    final magnitude = trueResponse.magnitude;
    final confidence = trueResponse.confidence;
    final trend = individualStats.trend;
    
    ResponseType type;
    String description;
    
    if (magnitude < 0.5) {
      type = ResponseType.nonResponder;
      description = 'Yanıtsız: Minimal bireysel yanıt tespit edildi';
    } else if (magnitude < 1.0) {
      type = ResponseType.lowResponder;
      description = 'Düşük yanıtlı: Küçük ama ölçülebilir bireysel yanıt';
    } else if (magnitude < 2.0) {
      type = ResponseType.moderateResponder;
      description = 'Orta yanıtlı: Net bireysel yanıt deseni';
    } else {
      type = ResponseType.highResponder;
      description = 'Yüksek yanıtlı: Güçlü bireysel yanıt deseni';
    }
    
    // Determine direction
    ResponseDirection direction;
    if (trend > 0.1) {
      direction = ResponseDirection.positive;
    } else if (trend < -0.1) {
      direction = ResponseDirection.negative;
    } else {
      direction = ResponseDirection.neutral;
    }
    
    return ResponseClassification(
      type: type,
      direction: direction,
      description: description,
      confidence: confidence,
    );
  }

  /// Response consistency hesaplama
  static ResponseConsistency _calculateResponseConsistency(List<double> values) {
    if (values.length < 4) {
      return ResponseConsistency(
        score: 0.5,
        level: ConsistencyLevel.insufficient,
        description: 'Yetersiz veri noktası',
      );
    }
    
    // Calculate rolling correlations between adjacent windows
    final windowSize = math.min(5, values.length ~/ 2);
    final correlations = <double>[];
    
    for (int i = 0; i <= values.length - 2 * windowSize; i++) {
      final window1 = values.sublist(i, i + windowSize);
      final window2 = values.sublist(i + windowSize, i + 2 * windowSize);
      
      final correlation = _stats.calculateCorrelation(window1, window2);
      if (!correlation.isNaN) {
        correlations.add(correlation.abs());
      }
    }
    
    final consistencyScore = correlations.isEmpty 
        ? 0.5 
        : correlations.reduce((a, b) => a + b) / correlations.length;
    
    ConsistencyLevel level;
    String description;
    
    if (consistencyScore >= 0.8) {
      level = ConsistencyLevel.high;
      description = 'Yüksek tutarlılık: Güvenilir bireysel yanıt';
    } else if (consistencyScore >= 0.6) {
      level = ConsistencyLevel.moderate;
      description = 'Orta tutarlılık: Genel eğilim belirgin';
    } else if (consistencyScore >= 0.4) {
      level = ConsistencyLevel.low;
      description = 'Düşük tutarlılık: Değişken yanıt';
    } else {
      level = ConsistencyLevel.veryLow;
      description = 'Çok düşük tutarlılık: Düzensiz yanıt';
    }
    
    return ResponseConsistency(
      score: consistencyScore,
      level: level,
      description: description,
    );
  }

  /// Personalized insights generation
  static List<PersonalizedInsight> _generatePersonalizedInsights(
    AthleteModel athlete,
    IndividualStatistics stats,
    TrueIndividualResponse trueResponse,
    ResponseClassification classification,
    ResponseConsistency consistency,
  ) {
    final insights = <PersonalizedInsight>[];
    
    // Response type insight
    insights.add(PersonalizedInsight(
      category: InsightCategory.responsePattern,
      title: 'Bireysel Yanıt Profili',
      description: classification.description,
      recommendation: _getResponseTypeRecommendation(classification.type),
      confidence: classification.confidence,
      priority: InsightPriority.high,
    ));
    
    // Consistency insight
    insights.add(PersonalizedInsight(
      category: InsightCategory.consistency,
      title: 'Yanıt Tutarlılığı',
      description: consistency.description,
      recommendation: _getConsistencyRecommendation(consistency.level),
      confidence: 0.9,
      priority: consistency.level == ConsistencyLevel.high 
          ? InsightPriority.medium 
          : InsightPriority.high,
    ));
    
    // Training adaptation insight
    if (trueResponse.isSignificant) {
      insights.add(PersonalizedInsight(
        category: InsightCategory.adaptation,
        title: 'Antrenman Adaptasyonu',
        description: 'Anlamlı bireysel adaptasyon tespit edildi',
        recommendation: 'Mevcut antrenman yaklaşımı bu sporcular için etkili görünüyor',
        confidence: trueResponse.confidence,
        priority: InsightPriority.medium,
      ));
    }
    
    // Age-specific insight
    insights.add(_generateAgeSpecificInsight(athlete, stats, trueResponse));
    
    return insights;
  }

  /// Adaptation potential hesaplama
  static AdaptationPotential _calculateAdaptationPotential(
    AthleteModel athlete,
    IndividualStatistics stats,
    TrueIndividualResponse trueResponse,
    PopulationNorms populationNorms,
  ) {
    // Age factor
    final ageFactor = _calculateAgeFactor(athlete.age ?? 25);
    
    // Training history factor (simplified)
    final trainingFactor = math.min(1.2, 1.0 + (stats.sampleSize * 0.02));
    
    // Response magnitude factor
    final responseFactor = math.min(1.0, trueResponse.magnitude / 2.0);
    
    // Overall potential
    final potential = (ageFactor + trainingFactor + responseFactor) / 3;
    
    String description;
    if (potential >= 0.8) {
      description = 'Yüksek adaptasyon potansiyeli';
    } else if (potential >= 0.6) {
      description = 'Orta düzey adaptasyon potansiyeli';
    } else {
      description = 'Sınırlı adaptasyon potansiyeli';
    }
    
    return AdaptationPotential(
      score: potential,
      description: description,
      ageFactor: ageFactor,
      trainingFactor: trainingFactor,
      responseFactor: responseFactor,
    );
  }

  // Statistical helper methods
  static double _calculateLinearTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final regression = _stats.performLinearRegression(x, values);
    
    return regression.slope;
  }

  static double _calculateIndividualReliability(List<double> values) {
    if (values.length < 3) return 0.5;
    
    // Simplified ICC calculation
    final mean = _stats.calculateMean(values);
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / (values.length - 1);
    final withinSubjectVariance = variance * 0.3; // Simplified estimation
    
    return math.max(0, (variance - withinSubjectVariance) / variance);
  }

  static double _calculateIndividualTypicalError(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final differences = <double>[];
    for (int i = 1; i < values.length; i++) {
      differences.add((values[i] - values[i-1]).abs());
    }
    
    final meanDifference = _stats.calculateMean(differences);
    return meanDifference / math.sqrt(2); // Convert to typical error
  }

  static double _calculateResponseConfidence(int sampleSize, double reliability, double magnitude) {
    final sampleFactor = math.min(1.0, sampleSize / 10.0);
    final reliabilityFactor = reliability;
    final magnitudeFactor = math.min(1.0, magnitude / 2.0);
    
    return (sampleFactor + reliabilityFactor + magnitudeFactor) / 3;
  }

  static double _calculateAgeFactor(int age) {
    if (age < 18) return 1.2; // Young athletes
    if (age < 25) return 1.0; // Prime adaptation years
    if (age < 30) return 0.9; // Slightly reduced
    if (age < 35) return 0.8; // Moderately reduced
    return 0.7; // Older athletes
  }

  static String _getResponseTypeRecommendation(ResponseType type) {
    switch (type) {
      case ResponseType.highResponder:
        return 'Mevcut antrenman programını sürdürün ve ilerlemeli yükleme uygulayın';
      case ResponseType.moderateResponder:
        return 'Programı kişiselleştirin ve yanıt paternlerini yakından takip edin';
      case ResponseType.lowResponder:
        return 'Alternatif antrenman modalitelerini deneyin ve stimulus çeşitliliğini artırın';
      case ResponseType.nonResponder:
        return 'Kapsamlı program değişikliği gerekli, farklı yaklaşımları test edin';
    }
  }

  static String _getConsistencyRecommendation(ConsistencyLevel level) {
    switch (level) {
      case ConsistencyLevel.high:
        return 'Mükemmel tutarlılık - mevcut yaklaşımı koruyun';
      case ConsistencyLevel.moderate:
        return 'İyi tutarlılık - antrenman standardizasyonunu artırın';
      case ConsistencyLevel.low:
        return 'Düşük tutarlılık - çevresel faktörleri kontrol edin';
      case ConsistencyLevel.veryLow:
        return 'Çok düşük tutarlılık - test protokolünü gözden geçirin';
      case ConsistencyLevel.insufficient:
        return 'Daha fazla veri toplayın';
    }
  }

  static PersonalizedInsight _generateAgeSpecificInsight(
    AthleteModel athlete,
    IndividualStatistics stats,
    TrueIndividualResponse trueResponse,
  ) {
    final age = athlete.age ?? 25; // Default age if null
    String description;
    String recommendation;
    
    if (age < 18) {
      description = 'Genç sporcu - yüksek adaptasyon kapasitesi';
      recommendation = 'Çok yönlü gelişim odaklı antrenman programları tercih edin';
    } else if (age < 25) {
      description = 'Optimal adaptasyon dönemi';
      recommendation = 'Yoğun ve spesifik antrenman programları uygulanabilir';
    } else if (age < 30) {
      description = 'Deneyimli sporcu profili';
      recommendation = 'Toparlanmaya odaklı periodizasyon uygulayın';
    } else {
      description = 'Master sporcu kategorisi';
      recommendation = 'Yaralanma önleme ve sürdürülebilir gelişim odaklı yaklaşım';
    }
    
    return PersonalizedInsight(
      category: InsightCategory.ageSpecific,
      title: 'Yaş Grubuna Özel Analiz',
      description: description,
      recommendation: recommendation,
      confidence: 0.8,
      priority: InsightPriority.medium,
    );
  }

  static Map<String, double> _calculateCrossTestCorrelations(Map<String, IRVAnalysisResult> results) {
    final correlations = <String, double>{};
    final testTypes = results.keys.toList();
    
    for (int i = 0; i < testTypes.length; i++) {
      for (int j = i + 1; j < testTypes.length; j++) {
        final type1 = testTypes[i];
        final type2 = testTypes[j];
        
        final response1 = results[type1]!.trueIndividualResponse.magnitude;
        final response2 = results[type2]!.trueIndividualResponse.magnitude;
        
        // Simplified correlation calculation
        final correlation = (response1 + response2) / 2; // Placeholder
        correlations['$type1-$type2'] = correlation;
      }
    }
    
    return correlations;
  }

  static ComprehensiveProfile _generateComprehensiveProfile(
    Map<String, IRVAnalysisResult> results,
    Map<String, double> crossTestCorrelations,
  ) {
    if (results.isEmpty) {
      return ComprehensiveProfile(
        overallResponseType: ResponseType.nonResponder,
        dominantPattern: 'Yetersiz veri',
        crossTestConsistency: 0.0,
        recommendations: ['Daha fazla test verisi toplayın'],
      );
    }
    
    // Calculate overall metrics
    final responseMagnitudes = results.values.map((r) => r.trueIndividualResponse.magnitude).toList();
    final avgMagnitude = _stats.calculateMean(responseMagnitudes);
    
    ResponseType overallType;
    if (avgMagnitude >= 2.0) {
      overallType = ResponseType.highResponder;
    } else if (avgMagnitude >= 1.0) {
      overallType = ResponseType.moderateResponder;
    } else if (avgMagnitude >= 0.5) {
      overallType = ResponseType.lowResponder;
    } else {
      overallType = ResponseType.nonResponder;
    }
    
    final crossTestConsistency = crossTestCorrelations.values.isEmpty 
        ? 0.5 
        : _stats.calculateMean(crossTestCorrelations.values.toList());
    
    return ComprehensiveProfile(
      overallResponseType: overallType,
      dominantPattern: _identifyDominantPattern(results),
      crossTestConsistency: crossTestConsistency,
      recommendations: _generateComprehensiveRecommendations(overallType, crossTestConsistency),
    );
  }

  static String _identifyDominantPattern(Map<String, IRVAnalysisResult> results) {
    final highResponders = results.values.where((r) => 
        r.responseClassification.type == ResponseType.highResponder).length;
    final total = results.length;
    
    if (highResponders / total >= 0.7) {
      return 'Çok responsif profil';
    } else if (highResponders / total >= 0.4) {
      return 'Orta responsif profil';
    } else {
      return 'Düşük responsif profil';
    }
  }

  static List<String> _generateComprehensiveRecommendations(
    ResponseType overallType,
    double crossTestConsistency,
  ) {
    final recommendations = <String>[];
    
    switch (overallType) {
      case ResponseType.highResponder:
        recommendations.add('Agresif antrenman programları uygulanabilir');
        recommendations.add('Düzenli izleme ile overreaching\'i önleyin');
        break;
      case ResponseType.moderateResponder:
        recommendations.add('Kişiselleştirilmiş antrenman yaklaşımı');
        recommendations.add('Çeşitli stimulusları test edin');
        break;
      case ResponseType.lowResponder:
        recommendations.add('Alternatif metodolojileri araştırın');
        recommendations.add('Beslenme ve dinlenme protokollerini optimize edin');
        break;
      case ResponseType.nonResponder:
        recommendations.add('Kapsamlı yaklaşım değişikliği gerekli');
        recommendations.add('Medikal değerlendirme düşünün');
    }
    
    if (crossTestConsistency < 0.5) {
      recommendations.add('Test tutarlılığını artırmaya odaklanın');
    }
    
    return recommendations;
  }

  static Map<String, double> _calculatePopulationMetrics(List<IRVAnalysisResult> results) {
    final responseMagnitudes = results.map((r) => r.trueIndividualResponse.magnitude).toList();
    final consistencyScores = results.map((r) => r.consistency.score).toList();
    
    return {
      'mean_response_magnitude': _stats.calculateMean(responseMagnitudes),
      'sd_response_magnitude': _stats.calculateStandardDeviation(responseMagnitudes),
      'mean_consistency': _stats.calculateMean(consistencyScores),
      'responder_percentage': results.where((r) => r.trueIndividualResponse.isSignificant).length / results.length * 100,
    };
  }
}

// Data Models

class IRVAnalysisResult {
  final String athleteId;
  final String athleteName;
  final String testType;
  final IndividualStatistics individualStatistics;
  final TrueIndividualResponse trueIndividualResponse;
  final ResponseClassification responseClassification;
  final ResponseConsistency consistency;
  final AdaptationPotential adaptationPotential;
  final List<PersonalizedInsight> personalizedInsights;
  final int sampleSize;
  final DateTime analysisDate;
  final String? error;

  IRVAnalysisResult({
    required this.athleteId,
    required this.athleteName,
    required this.testType,
    required this.individualStatistics,
    required this.trueIndividualResponse,
    required this.responseClassification,
    required this.consistency,
    required this.adaptationPotential,
    required this.personalizedInsights,
    required this.sampleSize,
    required this.analysisDate,
    this.error,
  });

  factory IRVAnalysisResult.error(String message) {
    return IRVAnalysisResult(
      athleteId: '',
      athleteName: '',
      testType: '',
      individualStatistics: IndividualStatistics(
        mean: 0, standardDeviation: 0, coefficientOfVariation: 0,
        trend: 0, reliability: 0, typicalError: 0, sampleSize: 0,
      ),
      trueIndividualResponse: TrueIndividualResponse(
        value: 0, magnitude: 0, confidence: 0, isSignificant: false,
        individualChange: 0, populationChange: 0,
      ),
      responseClassification: ResponseClassification(
        type: ResponseType.nonResponder,
        direction: ResponseDirection.neutral,
        description: message,
        confidence: 0,
      ),
      consistency: ResponseConsistency(
        score: 0, level: ConsistencyLevel.insufficient, description: message,
      ),
      adaptationPotential: AdaptationPotential(
        score: 0, description: message, ageFactor: 0, trainingFactor: 0, responseFactor: 0,
      ),
      personalizedInsights: [],
      sampleSize: 0,
      analysisDate: DateTime.now(),
      error: message,
    );
  }

  bool get hasError => error != null;
}

class IndividualStatistics {
  final double mean;
  final double standardDeviation;
  final double coefficientOfVariation;
  final double trend;
  final double reliability;
  final double typicalError;
  final int sampleSize;

  IndividualStatistics({
    required this.mean,
    required this.standardDeviation,
    required this.coefficientOfVariation,
    required this.trend,
    required this.reliability,
    required this.typicalError,
    required this.sampleSize,
  });
}

class TrueIndividualResponse {
  final double value;
  final double magnitude;
  final double confidence;
  final bool isSignificant;
  final double individualChange;
  final double populationChange;

  TrueIndividualResponse({
    required this.value,
    required this.magnitude,
    required this.confidence,
    required this.isSignificant,
    required this.individualChange,
    required this.populationChange,
  });
}

class ResponseClassification {
  final ResponseType type;
  final ResponseDirection direction;
  final String description;
  final double confidence;

  ResponseClassification({
    required this.type,
    required this.direction,
    required this.description,
    required this.confidence,
  });
}

class ResponseConsistency {
  final double score;
  final ConsistencyLevel level;
  final String description;

  ResponseConsistency({
    required this.score,
    required this.level,
    required this.description,
  });
}

class AdaptationPotential {
  final double score;
  final String description;
  final double ageFactor;
  final double trainingFactor;
  final double responseFactor;

  AdaptationPotential({
    required this.score,
    required this.description,
    required this.ageFactor,
    required this.trainingFactor,
    required this.responseFactor,
  });
}

class PersonalizedInsight {
  final InsightCategory category;
  final String title;
  final String description;
  final String recommendation;
  final double confidence;
  final InsightPriority priority;

  PersonalizedInsight({
    required this.category,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.confidence,
    required this.priority,
  });
}

class PopulationNorms {
  final double typicalResponse;
  final double typicalError;
  final double smallestWorthwhileChange;
  final double populationMean;
  final double populationSD;
  final int sampleSize;

  PopulationNorms({
    required this.typicalResponse,
    required this.typicalError,
    required this.smallestWorthwhileChange,
    required this.populationMean,
    required this.populationSD,
    required this.sampleSize,
  });
}

class ComprehensiveIRVResult {
  final String athleteId;
  final String athleteName;
  final Map<String, IRVAnalysisResult> testTypeResults;
  final Map<String, double> crossTestCorrelations;
  final ComprehensiveProfile comprehensiveProfile;
  final DateTime analysisDate;

  ComprehensiveIRVResult({
    required this.athleteId,
    required this.athleteName,
    required this.testTypeResults,
    required this.crossTestCorrelations,
    required this.comprehensiveProfile,
    required this.analysisDate,
  });
}

class ComprehensiveProfile {
  final ResponseType overallResponseType;
  final String dominantPattern;
  final double crossTestConsistency;
  final List<String> recommendations;

  ComprehensiveProfile({
    required this.overallResponseType,
    required this.dominantPattern,
    required this.crossTestConsistency,
    required this.recommendations,
  });
}

class PopulationIRVComparison {
  final String testType;
  final Map<String, IRVAnalysisResult> individualResults;
  final Map<String, double> populationMetrics;
  final DateTime analysisDate;

  PopulationIRVComparison({
    required this.testType,
    required this.individualResults,
    required this.populationMetrics,
    required this.analysisDate,
  });
}

// Enums
enum ResponseType {
  nonResponder,
  lowResponder,
  moderateResponder,
  highResponder,
}

enum ResponseDirection {
  positive,
  neutral,
  negative,
}

enum ConsistencyLevel {
  veryLow,
  low,
  moderate,
  high,
  insufficient,
}

enum InsightCategory {
  responsePattern,
  consistency,
  adaptation,
  ageSpecific,
  crossTest,
}

enum InsightPriority {
  low,
  medium,
  high,
  critical,
}