import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../../domain/entities/force_data.dart';
// ✅ En üste ekle

/// izForce faz tespit algoritması
/// Gerçek zamanlı ve post-processing faz tespiti
class PhaseDetector {
  // Faz tespit parametreleri
  static const Map<TestType, PhaseDetectionParams> _phaseParams = {
    TestType.counterMovementJump: PhaseDetectionParams(
      quietThresholdMultiplier: 0.02, // ±2% vücut ağırlığı
      unloadingThresholdMultiplier: 0.9, // 90% vücut ağırlığı
      brakingThresholdMultiplier: 1.1, // 110% vücut ağırlığı
      propulsionThresholdMultiplier: 1.2, // 120% vücut ağırlığı
      takeoffThresholdMultiplier: 0.1, // 10% vücut ağırlığı
      landingThresholdMultiplier: 0.5, // 50% vücut ağırlığı
      minimumPhaseDuration: 0.05, // 50ms
      smoothingWindow: 5,
    ),
    TestType.squatJump: PhaseDetectionParams(
      quietThresholdMultiplier: 0.02,
      unloadingThresholdMultiplier: 0.95, // Daha az unloading
      brakingThresholdMultiplier: 1.1,
      propulsionThresholdMultiplier: 1.15,
      takeoffThresholdMultiplier: 0.1,
      landingThresholdMultiplier: 0.5,
      minimumPhaseDuration: 0.03,
      smoothingWindow: 3,
    ),
    TestType.dropJump: PhaseDetectionParams(
      quietThresholdMultiplier: 0.02,
      unloadingThresholdMultiplier: 0.8, // Daha agresif unloading
      brakingThresholdMultiplier: 1.5, // Yüksek braking forces
      propulsionThresholdMultiplier: 1.3,
      takeoffThresholdMultiplier: 0.1,
      landingThresholdMultiplier: 0.8, // Yüksek landing threshold
      minimumPhaseDuration: 0.02,
      smoothingWindow: 3,
    ),
  };

  /// Gerçek zamanlı faz tespiti
  static JumpPhase detectRealTimePhase({
    required ForceData currentData,
    required List<ForceData> recentHistory,
    required double bodyWeightN,
    required TestType testType,
    JumpPhase? currentPhase,
  }) {
    try {
      final params = _phaseParams[testType] ?? _phaseParams[TestType.counterMovementJump]!;
      
      // Mevcut faz yoksa quiet standing'den başla
      currentPhase ??= JumpPhase.quietStanding;
      
      // Smoothed force value
      final smoothedForce = _applySmoothingFilter(recentHistory, params.smoothingWindow);
      
      // Faz geçiş kontrolü
      final newPhase = _checkPhaseTransition(
        currentPhase: currentPhase,
        currentForce: smoothedForce,
        recentHistory: recentHistory,
        bodyWeightN: bodyWeightN,
        params: params,
        testType: testType,
      );
      
      if (newPhase != currentPhase) {
        AppLogger.debug('🔄 Faz geçişi: ${currentPhase.turkishName} → ${newPhase.turkishName}');
      }
      
      return newPhase;
      
    } catch (e, stackTrace) {
      AppLogger.error('Real-time faz tespit hatası', e, stackTrace);
      return currentPhase ?? JumpPhase.quietStanding;
    }
  }

  /// Post-processing detaylı faz analizi
  static PhaseAnalysisResult analyzePhases({
    required ForceDataCollection forceData,
    required double bodyWeightN,
    required TestType testType,
  }) {
    try {
      AppLogger.info('🔍 Detaylı faz analizi başladı: ${testType.turkishName}');
      
      final params = _phaseParams[testType] ?? _phaseParams[TestType.counterMovementJump]!;
      final data = forceData.data;
      
      // Veriyi smooth et
      final smoothedData = _smoothForceData(data, params.smoothingWindow);
      
      // Ana faz tespiti
      final phases = _detectAllPhases(smoothedData, bodyWeightN, params, testType);
      
      // Faz kalitesi değerlendirmesi
      final quality = _evaluatePhaseQuality(phases, smoothedData, bodyWeightN, params);
      
      // Faz istatistikleri
      final statistics = _calculatePhaseStatistics(phases, smoothedData, forceData.sampleRate);
      
      final result = PhaseAnalysisResult(
        phases: phases,
        quality: quality,
        statistics: statistics,
        detectionConfidence: _calculateDetectionConfidence(phases, quality),
      );
      
      AppLogger.success('✅ Faz analizi tamamlandı: ${phases.length} faz tespit edildi');
      return result;
      
    } catch (e, stackTrace) {
      AppLogger.error('Faz analizi hatası', e, stackTrace);
      return PhaseAnalysisResult.empty();
    }
  }

  /// Adaptif faz tespiti (sporcuya özel)
  static PhaseDetectionParams adaptParametersForAthlete({
    required PhaseDetectionParams baseParams,
    required double bodyWeight,
    required int age,
    required AthleteLevel level,
    required String? sport,
  }) {
    var params = baseParams;
    
    // Yaş bazlı adaptasyon
    if (age < 18) {
      // Genç sporcular - daha hassas thresholds
      params = params.copyWith(
        quietThresholdMultiplier: params.quietThresholdMultiplier * 0.8,
        minimumPhaseDuration: params.minimumPhaseDuration * 0.8,
      );
    } else if (age > 35) {
      // Master sporcular - daha toleranslı thresholds
      params = params.copyWith(
        quietThresholdMultiplier: params.quietThresholdMultiplier * 1.2,
        minimumPhaseDuration: params.minimumPhaseDuration * 1.2,
      );
    }
    
    // Seviye bazlı adaptasyon
    switch (level) {
      case AthleteLevel.recreational:
        params = params.copyWith(
          smoothingWindow: params.smoothingWindow + 2,
          minimumPhaseDuration: params.minimumPhaseDuration * 1.5,
        );
        break;
      case AthleteLevel.elite:
        params = params.copyWith(
          smoothingWindow: math.max(3, params.smoothingWindow - 1),
          minimumPhaseDuration: params.minimumPhaseDuration * 0.7,
        );
        break;
      default:
        break;
    }
    
    // Spor dalı bazlı adaptasyon
    if (sport != null) {
      final sportLower = sport.toLowerCase();
      if (sportLower.contains('halter') || sportLower.contains('güreş')) {
        // Güç sporları - yüksek force thresholds
        params = params.copyWith(
          brakingThresholdMultiplier: params.brakingThresholdMultiplier * 1.2,
          propulsionThresholdMultiplier: params.propulsionThresholdMultiplier * 1.2,
        );
      } else if (sportLower.contains('jimnastik') || sportLower.contains('dans')) {
        // Estetik sporlar - hassas timing
        params = params.copyWith(
          minimumPhaseDuration: params.minimumPhaseDuration * 0.6,
          smoothingWindow: math.max(3, params.smoothingWindow - 2),
        );
      }
    }
    
    return params;
  }

  // ===== PRIVATE METHODS =====

  /// Smoothing filter uygula
  static double _applySmoothingFilter(List<ForceData> data, int windowSize) {
    if (data.isEmpty) return 0.0;
    if (data.length < windowSize) return data.last.totalGRF;
    
    final recentData = data.skip(math.max(0, data.length - windowSize)).toList();
    return recentData.map((d) => d.totalGRF).reduce((a, b) => a + b) / recentData.length;
  }

  /// Force data'yı smooth et
  static List<ForceData> _smoothForceData(List<ForceData> data, int windowSize) {
    if (windowSize <= 1) return data;
    
    final smoothedData = <ForceData>[];
    
    for (int i = 0; i < data.length; i++) {
      final start = math.max(0, i - windowSize ~/ 2);
      final end = math.min(data.length, i + windowSize ~/ 2 + 1);
      
      double sumLeft = 0, sumRight = 0, sumTotal = 0;
      for (int j = start; j < end; j++) {
        sumLeft += data[j].leftGRF;
        sumRight += data[j].rightGRF;
        sumTotal += data[j].totalGRF;
      }
      
      final count = end - start;
      smoothedData.add(data[i].copyWith(
        leftGRF: sumLeft / count,
        rightGRF: sumRight / count,
        totalGRF: sumTotal / count,
      ));
    }
    
    return smoothedData;
  }

  /// Faz geçiş kontrolü
  static JumpPhase _checkPhaseTransition({
    required JumpPhase currentPhase,
    required double currentForce,
    required List<ForceData> recentHistory,
    required double bodyWeightN,
    required PhaseDetectionParams params,
    required TestType testType,
  }) {
    final thresholds = _calculateThresholds(bodyWeightN, params);
    
    switch (currentPhase) {
      case JumpPhase.quietStanding:
        return _checkQuietStandingTransition(currentForce, recentHistory, thresholds, testType);
      
      case JumpPhase.unloading:
        return _checkUnloadingTransition(currentForce, recentHistory, thresholds);
      
      case JumpPhase.braking:
        return _checkBrakingTransition(currentForce, recentHistory, thresholds);
      
      case JumpPhase.propulsion:
        return _checkPropulsionTransition(currentForce, recentHistory, thresholds);
      
      case JumpPhase.flight:
        return _checkFlightTransition(currentForce, recentHistory, thresholds);
      
      case JumpPhase.landing:
        return _checkLandingTransition(currentForce, recentHistory, thresholds);
    }
  }

  /// Threshold değerlerini hesapla
  static PhaseThresholds _calculateThresholds(double bodyWeightN, PhaseDetectionParams params) {
    return PhaseThresholds(
      quietUpper: bodyWeightN * (1 + params.quietThresholdMultiplier),
      quietLower: bodyWeightN * (1 - params.quietThresholdMultiplier),
      unloading: bodyWeightN * params.unloadingThresholdMultiplier,
      braking: bodyWeightN * params.brakingThresholdMultiplier,
      propulsion: bodyWeightN * params.propulsionThresholdMultiplier,
      takeoff: bodyWeightN * params.takeoffThresholdMultiplier,
      landing: bodyWeightN * params.landingThresholdMultiplier,
    );
  }

  /// Quiet standing geçiş kontrolü
  static JumpPhase _checkQuietStandingTransition(
    double currentForce,
    List<ForceData> recentHistory,
    PhaseThresholds thresholds,
    TestType testType,
  ) {
    // Squat jump için unloading fazı yok
    if (testType == TestType.squatJump) {
      if (currentForce > thresholds.braking) {
        return JumpPhase.braking;
      }
    } else {
      // Unloading tespiti
      if (currentForce < thresholds.unloading) {
        return JumpPhase.unloading;
      }
      
      // Direkt braking'e geçiş (aggressive start)
      if (currentForce > thresholds.braking) {
        return JumpPhase.braking;
      }
    }
    
    return JumpPhase.quietStanding;
  }

  /// Unloading geçiş kontrolü
  static JumpPhase _checkUnloadingTransition(
    double currentForce,
    List<ForceData> recentHistory,
    PhaseThresholds thresholds,
  ) {
    // Braking fazına geçiş
    if (currentForce > thresholds.braking) {
      return JumpPhase.braking;
    }
    
    // Quiet standing'e geri dönüş (false unloading)
    if (currentForce > thresholds.quietUpper) {
      return JumpPhase.quietStanding;
    }
    
    return JumpPhase.unloading;
  }

  /// Braking geçiş kontrolü
  static JumpPhase _checkBrakingTransition(
    double currentForce,
    List<ForceData> recentHistory,
    PhaseThresholds thresholds,
  ) {
    // Propulsion fazına geçiş (peak force geçildi mi?)
    if (_isForceDecreasing(recentHistory) && currentForce > thresholds.propulsion) {
      return JumpPhase.propulsion;
    }
    
    return JumpPhase.braking;
  }

  /// Propulsion geçiş kontrolü
  static JumpPhase _checkPropulsionTransition(
    double currentForce,
    List<ForceData> recentHistory,
    PhaseThresholds thresholds,
  ) {
    // Take-off tespiti
    if (currentForce < thresholds.takeoff) {
      return JumpPhase.flight;
    }
    
    return JumpPhase.propulsion;
  }

  /// Flight geçiş kontrolü
  static JumpPhase _checkFlightTransition(
    double currentForce,
    List<ForceData> recentHistory,
    PhaseThresholds thresholds,
  ) {
    // Landing tespiti
    if (currentForce > thresholds.landing) {
      return JumpPhase.landing;
    }
    
    return JumpPhase.flight;
  }

  /// Landing geçiş kontrolü
  static JumpPhase _checkLandingTransition(
    double currentForce,
    List<ForceData> recentHistory,
    PhaseThresholds thresholds,
  ) {
    // Recovery'ye geçiş (stabilize oldu mu?)
    if (_isForceStable(recentHistory, thresholds.quietLower, thresholds.quietUpper)) {
      return JumpPhase.quietStanding;
    }
    
    return JumpPhase.landing;
  }

  /// Kuvvetin azalıp azalmadığını kontrol et
  static bool _isForceDecreasing(List<ForceData> history) {
    if (history.length < 3) return false;
    
    final recent = history.sublist(math.max(0, history.length - 20));
    return recent.length >= 3 && 
           recent[recent.length - 1].totalGRF < recent[recent.length - 2].totalGRF && 
           recent[recent.length - 2].totalGRF < recent[recent.length - 3].totalGRF;
  }

  /// Kuvvetin stabil olup olmadığını kontrol et
  static bool _isForceStable(List<ForceData> history, double lowerBound, double upperBound) {
    if (history.length < 5) return false;
    
    final recent = history.sublist(math.max(0, history.length - 20));
    return recent.every((d) => d.totalGRF >= lowerBound && d.totalGRF <= upperBound);
  }

  /// Tüm fazları tespit et (post-processing)
  static Map<JumpPhase, PhaseInfo> _detectAllPhases(
    List<ForceData> smoothedData,
    double bodyWeightN,
    PhaseDetectionParams params,
    TestType testType,
  ) {
    final phases = <JumpPhase, PhaseInfo>{};
    final thresholds = _calculateThresholds(bodyWeightN, params);
    
    // State machine ile faz tespiti
    var currentPhase = JumpPhase.quietStanding;
    var phaseStartIndex = 0;
    
    for (int i = 0; i < smoothedData.length; i++) {
      final force = smoothedData[i].totalGRF;
      
      final newPhase = _determinePhaseFromForce(
        force: force,
        currentPhase: currentPhase,
        thresholds: thresholds,
        testType: testType,
        dataIndex: i,
        smoothedData: smoothedData,
      );
      
      // Faz değişimi
      if (newPhase != currentPhase) {
        // Önceki fazı kaydet
        if (i - phaseStartIndex >= params.minimumPhaseDuration * 1000) { // Sample bazında
          phases[currentPhase] = PhaseInfo(
            startIndex: phaseStartIndex,
            endIndex: i - 1,
            duration: (i - phaseStartIndex) / 1000.0, // Approximate
            peakForce: _getPhaseMaxForce(smoothedData, phaseStartIndex, i - 1),
            avgForce: _getPhaseAvgForce(smoothedData, phaseStartIndex, i - 1),
          );
        }
        
        currentPhase = newPhase;
        phaseStartIndex = i;
      }
    }
    
    // Son fazı kaydet
    if (smoothedData.length - phaseStartIndex >= params.minimumPhaseDuration * 1000) {
      phases[currentPhase] = PhaseInfo(
        startIndex: phaseStartIndex,
        endIndex: smoothedData.length - 1,
        duration: (smoothedData.length - phaseStartIndex) / 1000.0,
        peakForce: _getPhaseMaxForce(smoothedData, phaseStartIndex, smoothedData.length - 1),
        avgForce: _getPhaseAvgForce(smoothedData, phaseStartIndex, smoothedData.length - 1),
      );
    }
    
    return phases;
  }

  /// Force değerinden faz belirleme
  static JumpPhase _determinePhaseFromForce({
    required double force,
    required JumpPhase currentPhase,
    required PhaseThresholds thresholds,
    required TestType testType,
    required int dataIndex,
    required List<ForceData> smoothedData,
  }) {
    // Basit threshold-based phase detection
    if (force < thresholds.takeoff) {
      return JumpPhase.flight;
    } else if (force > thresholds.propulsion) {
      if (currentPhase == JumpPhase.braking && _isAtPeakForceRegion(smoothedData, dataIndex)) {
        return JumpPhase.propulsion;
      } else if (force > thresholds.braking) {
        return JumpPhase.braking;
      }
    } else if (force < thresholds.unloading && testType != TestType.squatJump) {
      return JumpPhase.unloading;
    } else if (force >= thresholds.quietLower && force <= thresholds.quietUpper) {
      return JumpPhase.quietStanding;
    }
    
    return currentPhase; // Faz değişimi yok
  }

  /// Peak force bölgesinde mi kontrolü
  static bool _isAtPeakForceRegion(List<ForceData> data, int index) {
    if (index < 2 || index >= data.length - 2) return false;
    
    final current = data[index].totalGRF;
    final prev1 = data[index - 1].totalGRF;
    final prev2 = data[index - 2].totalGRF;
    final next1 = data[index + 1].totalGRF;
    final next2 = data[index + 2].totalGRF;
    
    // Peak civarı mı? (önceki değerlerden büyük, sonraki değerlerden büyük/eşit)
    return current >= prev1 && current >= prev2 && current >= next1 && current >= next2;
  }

  /// Faz kalitesi değerlendirme
  static Map<JumpPhase, PhaseQuality> _evaluatePhaseQuality(
    Map<JumpPhase, PhaseInfo> phases,
    List<ForceData> data,
    double bodyWeightN,
    PhaseDetectionParams params,
  ) {
    final quality = <JumpPhase, PhaseQuality>{};
    
    for (final entry in phases.entries) {
      final phase = entry.key;
      final info = entry.value;
      
      // Faz süresine göre kalite
      double durationScore = 1.0;
      if (info.duration < params.minimumPhaseDuration * 2) {
        durationScore = 0.5; // Çok kısa
      } else if (info.duration > params.minimumPhaseDuration * 10) {
        durationScore = 0.7; // Çok uzun
      }
      
      // Force consistency'ye göre kalite
      final phaseData = data.skip(info.startIndex).take(info.endIndex - info.startIndex + 1);
      final forces = phaseData.map((d) => d.totalGRF).toList();
      final cv = _calculateCV(forces);
      double consistencyScore = math.max(0.0, 1.0 - cv); // Lower CV = better
      
      // Genel kalite skoru
      final overallScore = (durationScore + consistencyScore) / 2;
      
      if (overallScore > 0.8) {
        quality[phase] = PhaseQuality.excellent;
      } else if (overallScore > 0.6) {
        quality[phase] = PhaseQuality.good;
      } else if (overallScore > 0.4) {
        quality[phase] = PhaseQuality.fair;
      } else {
        quality[phase] = PhaseQuality.poor;
      }
    }
    
    return quality;
  }

  /// Faz istatistikleri hesapla
  static PhaseStatistics _calculatePhaseStatistics(
    Map<JumpPhase, PhaseInfo> phases,
    List<ForceData> data,
    double sampleRate,
  ) {
    final stats = <JumpPhase, Map<String, double>>{};
    
    for (final entry in phases.entries) {
      final phase = entry.key;
      final info = entry.value;
      
      final phaseData = data.skip(info.startIndex).take(info.endIndex - info.startIndex + 1);
      final forces = phaseData.map((d) => d.totalGRF).toList();
      final asymmetries = phaseData.map((d) => d.asymmetryIndex).toList();
      
      stats[phase] = {
        'duration': info.duration,
        'peakForce': info.peakForce,
        'avgForce': info.avgForce,
        'minForce': forces.isNotEmpty ? forces.reduce(math.min) : 0.0,
        'forceCV': _calculateCV(forces),
        'avgAsymmetry': asymmetries.isNotEmpty ? asymmetries.reduce((a, b) => a + b) / asymmetries.length : 0.0,
        'maxAsymmetry': asymmetries.isNotEmpty ? asymmetries.reduce(math.max) : 0.0,
        'sampleCount': forces.length.toDouble(),
      };
    }
    
    return PhaseStatistics(stats);
  }

  /// Detection confidence hesapla
  static double _calculateDetectionConfidence(
    Map<JumpPhase, PhaseInfo> phases,
    Map<JumpPhase, PhaseQuality> quality,
  ) {
    if (phases.isEmpty) return 0.0;
    
    // Beklenen fazların varlığını kontrol et
    final expectedPhases = [
      JumpPhase.quietStanding,
      JumpPhase.braking,
      JumpPhase.propulsion,
      JumpPhase.flight,
    ];
    
    int foundPhases = 0;
    double qualitySum = 0.0;
    
    for (final phase in expectedPhases) {
      if (phases.containsKey(phase)) {
        foundPhases++;
        final phaseQuality = quality[phase] ?? PhaseQuality.poor;
        qualitySum += _qualityToScore(phaseQuality);
      }
    }
    
    final completenessScore = foundPhases / expectedPhases.length;
    final avgQualityScore = foundPhases > 0 ? qualitySum / foundPhases : 0.0;
    
    return (completenessScore + avgQualityScore) / 2;
  }

  /// Helper methods
  static double _getPhaseMaxForce(List<ForceData> data, int start, int end) {
    if (start >= end || end >= data.length) return 0.0;
    return data.skip(start).take(end - start + 1).map((d) => d.totalGRF).reduce(math.max);
  }

  static double _getPhaseAvgForce(List<ForceData> data, int start, int end) {
    if (start >= end || end >= data.length) return 0.0;
    final forces = data.skip(start).take(end - start + 1).map((d) => d.totalGRF).toList();
    return forces.isNotEmpty ? forces.reduce((a, b) => a + b) / forces.length : 0.0;
  }

  static double _calculateCV(List<double> values) {
    if (values.isEmpty || values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean == 0) return 0.0;
    
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);
    
    return stdDev / mean;
  }

  static double _qualityToScore(PhaseQuality quality) {
    switch (quality) {
      case PhaseQuality.excellent:
        return 1.0;
      case PhaseQuality.good:
        return 0.8;
      case PhaseQuality.fair:
        return 0.6;
      case PhaseQuality.poor:
        return 0.4;
    }
  }
}

// ===== DATA CLASSES =====

/// Faz tespit parametreleri
class PhaseDetectionParams {
  final double quietThresholdMultiplier;
  final double unloadingThresholdMultiplier;
  final double brakingThresholdMultiplier;
  final double propulsionThresholdMultiplier;
  final double takeoffThresholdMultiplier;
  final double landingThresholdMultiplier;
  final double minimumPhaseDuration; // seconds
  final int smoothingWindow;

  const PhaseDetectionParams({
    required this.quietThresholdMultiplier,
    required this.unloadingThresholdMultiplier,
    required this.brakingThresholdMultiplier,
    required this.propulsionThresholdMultiplier,
    required this.takeoffThresholdMultiplier,
    required this.landingThresholdMultiplier,
    required this.minimumPhaseDuration,
    required this.smoothingWindow,
  });

  PhaseDetectionParams copyWith({
    double? quietThresholdMultiplier,
    double? unloadingThresholdMultiplier,
    double? brakingThresholdMultiplier,
    double? propulsionThresholdMultiplier,
    double? takeoffThresholdMultiplier,
    double? landingThresholdMultiplier,
    double? minimumPhaseDuration,
    int? smoothingWindow,
  }) {
    return PhaseDetectionParams(
      quietThresholdMultiplier: quietThresholdMultiplier ?? this.quietThresholdMultiplier,
      unloadingThresholdMultiplier: unloadingThresholdMultiplier ?? this.unloadingThresholdMultiplier,
      brakingThresholdMultiplier: brakingThresholdMultiplier ?? this.brakingThresholdMultiplier,
      propulsionThresholdMultiplier: propulsionThresholdMultiplier ?? this.propulsionThresholdMultiplier,
      takeoffThresholdMultiplier: takeoffThresholdMultiplier ?? this.takeoffThresholdMultiplier,
      landingThresholdMultiplier: landingThresholdMultiplier ?? this.landingThresholdMultiplier,
      minimumPhaseDuration: minimumPhaseDuration ?? this.minimumPhaseDuration,
      smoothingWindow: smoothingWindow ?? this.smoothingWindow,
    );
  }
}

/// Faz threshold değerleri
class PhaseThresholds {
  final double quietUpper;
  final double quietLower;
  final double unloading;
  final double braking;
  final double propulsion;
  final double takeoff;
  final double landing;

  const PhaseThresholds({
    required this.quietUpper,
    required this.quietLower,
    required this.unloading,
    required this.braking,
    required this.propulsion,
    required this.takeoff,
    required this.landing,
  });
}

/// Faz bilgisi
class PhaseInfo {
  final int startIndex;
  final int endIndex;
  final double duration; // seconds
  final double peakForce;
  final double avgForce;

  const PhaseInfo({
    required this.startIndex,
    required this.endIndex,
    required this.duration,
    required this.peakForce,
    required this.avgForce,
  });
}

/// Faz kalitesi
enum PhaseQuality {
  excellent,
  good,
  fair,
  poor;

  String get turkishName {
    switch (this) {
      case PhaseQuality.excellent:
        return 'Mükemmel';
      case PhaseQuality.good:
        return 'İyi';
      case PhaseQuality.fair:
        return 'Orta';
      case PhaseQuality.poor:
        return 'Zayıf';
    }
  }
}

/// Faz istatistikleri
class PhaseStatistics {
  final Map<JumpPhase, Map<String, double>> data;

  const PhaseStatistics(this.data);

  /// Specific phase stats
  Map<String, double>? getPhaseStats(JumpPhase phase) => data[phase];
  
  /// Total test duration
  double get totalDuration {
    return data.values
        .map((stats) => stats['duration'] ?? 0.0)
        .fold(0.0, (a, b) => a + b);
  }
  
  /// Phase distribution (percentages)
  Map<JumpPhase, double> get phaseDistribution {
    final total = totalDuration;
    if (total == 0) return {};
    
    return data.map((phase, stats) => 
        MapEntry(phase, ((stats['duration'] ?? 0.0) / total) * 100));
  }
}

/// Faz analizi sonucu
class PhaseAnalysisResult {
  final Map<JumpPhase, PhaseInfo> phases;
  final Map<JumpPhase, PhaseQuality> quality;
  final PhaseStatistics statistics;
  final double detectionConfidence; // 0.0 - 1.0

  const PhaseAnalysisResult({
    required this.phases,
    required this.quality,
    required this.statistics,
    required this.detectionConfidence,
  });

  factory PhaseAnalysisResult.empty() {
    return const PhaseAnalysisResult(
      phases: {},
      quality: {},
      statistics: PhaseStatistics({}),
      detectionConfidence: 0.0,
    );
  }

  /// Faz var mı kontrolü
  bool hasPhase(JumpPhase phase) => phases.containsKey(phase);
  
  /// Faz süresi
  double getPhaseDuration(JumpPhase phase) => phases[phase]?.duration ?? 0.0;
  
  /// Faz kalitesi
  PhaseQuality getPhaseQuality(JumpPhase phase) => quality[phase] ?? PhaseQuality.poor;
  
  /// Genel test kalitesi
  PhaseQuality get overallQuality {
    if (detectionConfidence > 0.8) return PhaseQuality.excellent;
    if (detectionConfidence > 0.6) return PhaseQuality.good;
    if (detectionConfidence > 0.4) return PhaseQuality.fair;
    return PhaseQuality.poor;
  }
  
  /// Test başarılı mı?
  bool get isValidTest => detectionConfidence > 0.5 && phases.length >= 3;
}

/// Adaptive threshold calculator
class AdaptiveThresholdCalculator {
  /// Geçmiş testlere göre threshold'ları güncelle
  static PhaseDetectionParams updateThresholds({
    required PhaseDetectionParams currentParams,
    required List<PhaseAnalysisResult> previousTests,
    required double targetConfidence,
  }) {
    if (previousTests.length < 3) return currentParams;
    
    final avgConfidence = previousTests
        .map((test) => test.detectionConfidence)
        .reduce((a, b) => a + b) / previousTests.length;
    
    // Confidence düşükse threshold'ları relax et
    if (avgConfidence < targetConfidence) {
      return currentParams.copyWith(
        quietThresholdMultiplier: currentParams.quietThresholdMultiplier * 1.1,
        minimumPhaseDuration: currentParams.minimumPhaseDuration * 1.1,
        smoothingWindow: currentParams.smoothingWindow + 1,
      );
    }
    
    // Confidence yüksekse threshold'ları sıkılaştır
    if (avgConfidence > targetConfidence + 0.1) {
      return currentParams.copyWith(
        quietThresholdMultiplier: currentParams.quietThresholdMultiplier * 0.9,
        minimumPhaseDuration: currentParams.minimumPhaseDuration * 0.95,
        smoothingWindow: math.max(3, currentParams.smoothingWindow - 1),
      );
    }
    
    return currentParams;
  }
  
  /// Sporcu profiline göre başlangıç threshold'ları
  static PhaseDetectionParams getInitialThresholds({
    required TestType testType,
    required double bodyWeight,
    required int age,
    required AthleteLevel level,
    String? sport,
  }) {
    final baseParams = PhaseDetector._phaseParams[testType] ?? 
                     PhaseDetector._phaseParams[TestType.counterMovementJump]!;
    
    return PhaseDetector.adaptParametersForAthlete(
      baseParams: baseParams,
      bodyWeight: bodyWeight,
      age: age,
      level: level,
      sport: sport,
    );
  }
}