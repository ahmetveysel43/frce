import 'dart:async';
import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../../domain/entities/force_data.dart';
import 'phase_detector.dart';

/// izForce gerçek zamanlı analiz motoru
/// 1000Hz force data'yı real-time işler ve feedback verir
class RealTimeAnalyzer {
  // Buffer parametreleri
  static const int _maxBufferSize = 10000; // 10 saniye @ 1000Hz
  static const int _movingAverageWindow = 10; // 10ms sliding window
  static const int _phaseDetectionWindow = 50; // 50ms için faz kontrolü
  static const int _feedbackUpdateInterval = 100; // 100ms feedback update
  
  // Kalite kontrol parametreleri
  static const double _minForceVariability = 0.1; // N
  static const double _maxAsymmetryThreshold = 25.0; // %
  static const double _signalQualityThreshold = 0.8; // 0-1
  
  // Internal state
  final StreamController<RealTimeMetrics> _metricsController = StreamController.broadcast();
  final StreamController<RealTimeFeedback> _feedbackController = StreamController.broadcast();
  final StreamController<QualityAssessment> _qualityController = StreamController.broadcast();
  
  final List<ForceData> _dataBuffer = [];
  final List<double> _movingAverageBuffer = [];
  final RealTimeState _state = RealTimeState();
  
  Timer? _analysisTimer;
  Timer? _feedbackTimer;
  
  bool _isAnalyzing = false;
  double _bodyWeightN = 700.0; // Default 70kg
  TestType _testType = TestType.counterMovementJump;
  PhaseDetectionParams? _phaseParams;

  // Streams
  Stream<RealTimeMetrics> get metricsStream => _metricsController.stream;
  Stream<RealTimeFeedback> get feedbackStream => _feedbackController.stream;
  Stream<QualityAssessment> get qualityStream => _qualityController.stream;

  /// Analizi başlat
  Future<void> startAnalysis({
    required double bodyWeight, // kg
    required TestType testType,
    PhaseDetectionParams? customPhaseParams,
  }) async {
    try {
      AppLogger.info('🔄 Real-time analiz başladı: ${testType.turkishName}');
      
      _isAnalyzing = true;
      _bodyWeightN = bodyWeight * 9.81;
      _testType = testType;
      _phaseParams = customPhaseParams ?? 
          AdaptiveThresholdCalculator.getInitialThresholds(
            testType: testType,
            bodyWeight: bodyWeight,
            age: 25, // Default
            level: AthleteLevel.amateur,
          );
      
      // Buffer'ları temizle
      _dataBuffer.clear();
      _movingAverageBuffer.clear();
      _state.reset();
      
      // Timer'ları başlat
      _startAnalysisTimer();
      _startFeedbackTimer();
      
      AppLogger.success('✅ Real-time analiz aktif');
      
    } catch (e, stackTrace) {
      AppLogger.error('Real-time analiz başlatma hatası', e, stackTrace);
    }
  }

  /// Analizi durdur
  Future<void> stopAnalysis() async {
    try {
      _isAnalyzing = false;
      
      _analysisTimer?.cancel();
      _feedbackTimer?.cancel();
      
      // Son analiz sonuçlarını gönder
      await _performFinalAnalysis();
      
      AppLogger.info('🛑 Real-time analiz durduruldu');
      
    } catch (e, stackTrace) {
      AppLogger.error('Real-time analiz durdurma hatası', e, stackTrace);
    }
  }

  /// Yeni force data ekle
  void addForceData(ForceData data) {
    if (!_isAnalyzing) return;
    
    try {
      // Buffer'a ekle
      _dataBuffer.add(data);
      
      // Buffer boyutunu kontrol et
      if (_dataBuffer.length > _maxBufferSize) {
        _dataBuffer.removeAt(0);
      }
      
      // Moving average güncelle
      _updateMovingAverage(data.totalGRF);
      
      // Temel kalite kontrolleri
      _performQualityChecks(data);
      
    } catch (e, stackTrace) {
      AppLogger.error('Force data ekleme hatası', e, stackTrace);
    }
  }

  /// Batch force data ekle (performans için)
  void addForceDataBatch(List<ForceData> dataList) {
    if (!_isAnalyzing || dataList.isEmpty) return;
    
    try {
      for (final data in dataList) {
        addForceData(data);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Batch force data ekleme hatası', e, stackTrace);
    }
  }

  // ===== PRIVATE METHODS =====

  /// Analiz timer'ını başlat
  void _startAnalysisTimer() {
    _analysisTimer = Timer.periodic(
      Duration(milliseconds: _feedbackUpdateInterval),
      (_) => _performRealTimeAnalysis(),
    );
  }

  /// Feedback timer'ını başlat
  void _startFeedbackTimer() {
    _feedbackTimer = Timer.periodic(
      const Duration(milliseconds: 50), // 20Hz feedback
      (_) => _generateRealTimeFeedback(),
    );
  }

  /// Moving average güncelle
  void _updateMovingAverage(double force) {
    _movingAverageBuffer.add(force);
    
    if (_movingAverageBuffer.length > _movingAverageWindow) {
      _movingAverageBuffer.removeAt(0);
    }
    
    // Current smoothed force
    _state.currentSmoothedForce = _movingAverageBuffer.isNotEmpty
        ? _movingAverageBuffer.reduce((a, b) => a + b) / _movingAverageBuffer.length
        : 0.0;
  }

  /// Kalite kontrolleri
  void _performQualityChecks(ForceData data) {
    // Signal quality assessment
    final signalQuality = _assessSignalQuality(data);
    
    // Asymmetry warning
    if (data.asymmetryIndex > _maxAsymmetryThreshold) {
      _state.hasAsymmetryWarning = true;
      _state.asymmetryWarningCount++;
    }
    
    // Force variability check
    if (_movingAverageBuffer.length >= _movingAverageWindow) {
      final variability = _calculateVariability(_movingAverageBuffer);
      _state.forceVariability = variability;
      
      if (variability < _minForceVariability) {
        _state.hasLowSignalWarning = true;
      }
    }
    
    // Update quality metrics
    _state.signalQuality = signalQuality;
    _state.overallQuality = _calculateOverallQuality();
    
    // Quality assessment stream
    _qualityController.add(QualityAssessment(
      signalQuality: signalQuality,
      asymmetryLevel: data.asymmetryIndex,
      forceVariability: _state.forceVariability,
      overallScore: _state.overallQuality,
      warnings: _getCurrentWarnings(),
    ));
  }

  /// Real-time analiz gerçekleştir
  void _performRealTimeAnalysis() {
    if (_dataBuffer.length < 10) return; // Minimum data requirement
    
    try {
      // Current data window
      final recentData = _dataBuffer.length > _phaseDetectionWindow
          ? _dataBuffer.skip(_dataBuffer.length - _phaseDetectionWindow).toList()
          : _dataBuffer.toList();
      
      // Phase detection
      final newPhase = PhaseDetector.detectRealTimePhase(
        currentData: _dataBuffer.last,
        recentHistory: recentData,
        bodyWeightN: _bodyWeightN,
        testType: _testType,
        currentPhase: _state.currentPhase,
      );
      
      // Phase transition
      if (newPhase != _state.currentPhase) {
        _handlePhaseTransition(_state.currentPhase, newPhase);
        _state.currentPhase = newPhase;
      }
      
      // Real-time metrics calculation
      final metrics = _calculateRealTimeMetrics();
      
      // Update state
      _state.lastMetrics = metrics;
      _state.analysisCount++;
      
      // Send metrics stream
      _metricsController.add(metrics);
      
    } catch (e, stackTrace) {
      AppLogger.error('Real-time analiz hatası', e, stackTrace);
    }
  }

  /// Faz geçişi işle
  void _handlePhaseTransition(JumpPhase? oldPhase, JumpPhase newPhase) {
    AppLogger.debug('🔄 Faz geçişi: ${oldPhase?.turkishName ?? 'None'} → ${newPhase.turkishName}');
    
    // Faz bazlı state güncellemeleri
    switch (newPhase) {
      case JumpPhase.unloading:
        _state.unloadingStartTime = DateTime.now();
        _state.hasStartedMovement = true;
        break;
      case JumpPhase.braking:
        _state.brakingStartTime = DateTime.now();
        break;
      case JumpPhase.propulsion:
        _state.propulsionStartTime = DateTime.now();
        break;
      case JumpPhase.flight:
        _state.flightStartTime = DateTime.now();
        _state.takeoffDetected = true;
        break;
      case JumpPhase.landing:
        _state.landingTime = DateTime.now();
        _state.landingDetected = true;
        break;
      default:
        break;
    }
    
    // Faz süreleri hesapla
    _updatePhaseDurations();
  }

  /// Real-time metrikler hesapla
  RealTimeMetrics _calculateRealTimeMetrics() {
    final currentData = _dataBuffer.last;
    final recentData = _dataBuffer.length > 100 
        ? _dataBuffer.skip(_dataBuffer.length - 100).toList() 
        : _dataBuffer.toList();
    
    // Basic metrics
    final peakForce = recentData.map((d) => d.totalGRF).reduce(math.max);
    final avgForce = recentData.map((d) => d.totalGRF).reduce((a, b) => a + b) / recentData.length;
    final currentAsymmetry = currentData.asymmetryIndex;
    
    // Phase-specific metrics
    double? jumpHeight;
    double? flightTime;
    double? contactTime;
    
    if (_state.takeoffDetected && _state.landingDetected) {
      flightTime = _state.landingTime!.difference(_state.flightStartTime!).inMilliseconds.toDouble();
      jumpHeight = _estimateJumpHeight(flightTime);
    }
    
    if (_state.hasStartedMovement) {
      contactTime = _calculateCurrentContactTime();
    }
    
    // Rate of Force Development
    final rfd = _calculateCurrentRFD(recentData);
    
    // Power estimation
    final power = _estimateCurrentPower(recentData);
    
    return RealTimeMetrics(
      timestamp: DateTime.now(),
      currentForce: currentData.totalGRF,
      smoothedForce: _state.currentSmoothedForce,
      peakForce: peakForce,
      averageForce: avgForce,
      asymmetryIndex: currentAsymmetry,
      currentPhase: _state.currentPhase,
      jumpHeight: jumpHeight,
      flightTime: flightTime,
      contactTime: contactTime,
      rfd: rfd,
      estimatedPower: power,
      leftGRF: currentData.leftGRF,
      rightGRF: currentData.rightGRF,
      leftLoadPercentage: currentData.leftLoadPercentage,
      rightLoadPercentage: currentData.rightLoadPercentage,
      copPosition: currentData.combinedCOP,
      sampleCount: _dataBuffer.length,
      testDuration: _getTestDuration(),
      qualityScore: _state.overallQuality,
    );
  }

  /// Real-time feedback oluştur
  void _generateRealTimeFeedback() {
    if (_dataBuffer.isEmpty) return;
    
    try {
      final feedback = _generatePhaseSpecificFeedback();
      _feedbackController.add(feedback);
    } catch (e, stackTrace) {
      AppLogger.error('Feedback oluşturma hatası', e, stackTrace);
    }
  }

  /// Faz bazlı feedback
  RealTimeFeedback _generatePhaseSpecificFeedback() {
    final phase = _state.currentPhase;
    String message = '';
    FeedbackType type = FeedbackType.info;
    FeedbackPriority priority = FeedbackPriority.low;
    
    switch (phase) {
      case JumpPhase.quietStanding:
        if (_state.overallQuality < 0.8) {
          message = 'Platformlarda sabit durun';
          type = FeedbackType.instruction;
          priority = FeedbackPriority.medium;
        } else {
          message = 'Hazır - teste başlayabilirsiniz';
          type = FeedbackType.ready;
          priority = FeedbackPriority.low;
        }
        break;
        
      case JumpPhase.unloading:
        if (_state.hasAsymmetryWarning) {
          message = 'Daha dengeli inin';
          type = FeedbackType.warning;
          priority = FeedbackPriority.medium;
        } else {
          message = 'İyi - devam edin';
          type = FeedbackType.positive;
          priority = FeedbackPriority.low;
        }
        break;
        
      case JumpPhase.braking:
        message = 'Kuvvet biriktiriliyor...';
        type = FeedbackType.info;
        priority = FeedbackPriority.low;
        break;
        
      case JumpPhase.propulsion:
        if (_dataBuffer.last.asymmetryIndex > 15) {
          message = 'İki ayağınızı eşit kullanın!';
          type = FeedbackType.warning;
          priority = FeedbackPriority.high;
        } else {
          message = 'Mükemmel - sıçrayın!';
          type = FeedbackType.positive;
          priority = FeedbackPriority.low;
        }
        break;
        
      case JumpPhase.flight:
        final estimatedHeight = _state.lastMetrics?.jumpHeight ?? 0;
        if (estimatedHeight > 30) {
          message = 'Harika sıçrama!';
          type = FeedbackType.positive;
        } else {
          message = 'Uçuş fazı...';
          type = FeedbackType.info;
        }
        priority = FeedbackPriority.low;
        break;
        
      case JumpPhase.landing:
        if (_dataBuffer.last.asymmetryIndex > 20) {
          message = 'Dikkatli inin!';
          type = FeedbackType.warning;
          priority = FeedbackPriority.high;
        } else {
          message = 'İyi iniş';
          type = FeedbackType.positive;
          priority = FeedbackPriority.low;
        }
        break;
    }
    
    // Additional warnings
    final warnings = <String>[];
    if (_state.hasAsymmetryWarning && _state.asymmetryWarningCount > 5) {
      warnings.add('Sürekli asimetri - tekniği kontrol edin');
    }
    if (_state.hasLowSignalWarning) {
      warnings.add('Sinyal kalitesi düşük');
    }
    
    return RealTimeFeedback(
      timestamp: DateTime.now(),
      phase: phase,
      message: message,
      type: type,
      priority: priority,
      warnings: warnings,
      actionRequired: priority == FeedbackPriority.high,
      estimatedPerformance: _estimatePerformanceLevel(),
    );
  }

  /// Signal quality değerlendirme
  double _assessSignalQuality(ForceData data) {
    double score = 1.0;
    
    // Force range check
    if (data.totalGRF < 50 || data.totalGRF > 5000) {
      score -= 0.3;
    }
    
    // Asymmetry check
    if (data.asymmetryIndex > 30) {
      score -= 0.2;
    }
    
    // Left/Right balance check
    if (data.leftGRF < 0 || data.rightGRF < 0) {
      score -= 0.4;
    }
    
    // Noise check (if available)
    if (_movingAverageBuffer.length >= 5) {
      final noise = _calculateNoise(_movingAverageBuffer);
      if (noise > 50) { // N
        score -= 0.1;
      }
    }
    
    return math.max(0.0, score);
  }

  /// Genel kalite skoru
  double _calculateOverallQuality() {
    double score = _state.signalQuality;
    
    // Asymmetry penalty
    if (_state.asymmetryWarningCount > 0) {
      score -= (_state.asymmetryWarningCount * 0.05).clamp(0.0, 0.3);
    }
    
    // Low signal penalty
    if (_state.hasLowSignalWarning) {
      score -= 0.2;
    }
    
    // Phase progression bonus
    if (_state.hasStartedMovement) {
      score += 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Mevcut uyarıları al
  List<String> _getCurrentWarnings() {
    final warnings = <String>[];
    
    if (_state.hasAsymmetryWarning) {
      warnings.add('Yüksek asimetri');
    }
    if (_state.hasLowSignalWarning) {
      warnings.add('Düşük sinyal kalitesi');
    }
    if (_state.signalQuality < _signalQualityThreshold) {
      warnings.add('Sinyal kalite sorunu');
    }
    
    return warnings;
  }

  /// Variability hesapla
  double _calculateVariability(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  /// Noise hesapla
  double _calculateNoise(List<double> values) {
    if (values.length < 3) return 0.0;
    
    double totalDiff = 0.0;
    for (int i = 1; i < values.length; i++) {
      totalDiff += (values[i] - values[i-1]).abs();
    }
    
    return totalDiff / (values.length - 1);
  }

  /// Faz sürelerini güncelle
  void _updatePhaseDurations() {
    final now = DateTime.now();
    
    if (_state.unloadingStartTime != null) {
      _state.unloadingDuration = now.difference(_state.unloadingStartTime!);
    }
    if (_state.brakingStartTime != null) {
      _state.brakingDuration = now.difference(_state.brakingStartTime!);
    }
    if (_state.propulsionStartTime != null) {
      _state.propulsionDuration = now.difference(_state.propulsionStartTime!);
    }
  }

  /// Jump height tahmini (flight time'dan)
  double _estimateJumpHeight(double flightTimeMs) {
    final flightTimeS = flightTimeMs / 1000.0;
    return ((9.81 * flightTimeS * flightTimeS) / 8) * 100; // cm
  }

  /// Mevcut contact time
  double? _calculateCurrentContactTime() {
    if (_state.hasStartedMovement && _state.flightStartTime != null) {
      return _state.flightStartTime!.difference(_state.unloadingStartTime!).inMilliseconds.toDouble();
    }
    return null;
  }

  /// Current RFD hesapla
  double _calculateCurrentRFD(List<ForceData> recentData) {
    if (recentData.length < 10) return 0.0;
    
    final startForce = recentData.first.totalGRF;
    final endForce = recentData.last.totalGRF;
    final deltaTime = (recentData.length - 1) / 1000.0; // Assume 1000Hz
    
    return deltaTime > 0 ? (endForce - startForce) / deltaTime : 0.0;
  }

  /// Current power tahmini
  double _estimateCurrentPower(List<ForceData> recentData) {
    // Simplified power estimation
    if (recentData.length < 2) return 0.0;
    
    final avgForce = recentData.map((d) => d.totalGRF).reduce((a, b) => a + b) / recentData.length;
    // Assume velocity based on force and body weight
    final estimatedVelocity = (avgForce - _bodyWeightN) / (_bodyWeightN / 9.81) * 0.1; // Simplified
    
    return avgForce * estimatedVelocity.abs();
  }

  /// Test süresi
  Duration _getTestDuration() {
    if (_dataBuffer.isEmpty) return Duration.zero;
    return Duration(milliseconds: _dataBuffer.length); // Assume 1000Hz = 1ms per sample
  }

  /// Performance level tahmini
  PerformanceLevel _estimatePerformanceLevel() {
    final jumpHeight = _state.lastMetrics?.jumpHeight ?? 0;
    final asymmetry = _dataBuffer.isNotEmpty ? _dataBuffer.last.asymmetryIndex : 0;
    
    if (jumpHeight > 40 && asymmetry < 5) return PerformanceLevel.excellent;
    if (jumpHeight > 30 && asymmetry < 10) return PerformanceLevel.good;
    if (jumpHeight > 20 && asymmetry < 15) return PerformanceLevel.average;
    return PerformanceLevel.poor;
  }

  /// Final analiz
  Future<void> _performFinalAnalysis() async {
    if (_dataBuffer.isEmpty) return;
    
    try {
      // Final metrics calculation
      final finalMetrics = _calculateRealTimeMetrics();
      
      // Send final metrics
      _metricsController.add(finalMetrics);
      
      // Final feedback
      final finalFeedback = RealTimeFeedback(
        timestamp: DateTime.now(),
        phase: _state.currentPhase,
        message: 'Test tamamlandı',
        type: FeedbackType.complete,
        priority: FeedbackPriority.low,
        warnings: [],
        actionRequired: false,
        estimatedPerformance: _estimatePerformanceLevel(),
      );
      
      _feedbackController.add(finalFeedback);
      
    } catch (e, stackTrace) {
      AppLogger.error('Final analiz hatası', e, stackTrace);
    }
  }

  /// Resources'leri temizle
  void dispose() {
    _analysisTimer?.cancel();
    _feedbackTimer?.cancel();
    
    _metricsController.close();
    _feedbackController.close();
    _qualityController.close();
    
    _dataBuffer.clear();
    _movingAverageBuffer.clear();
  }
}

// ===== DATA CLASSES =====

/// Real-time analyzer state
class RealTimeState {
  JumpPhase currentPhase = JumpPhase.quietStanding;
  double currentSmoothedForce = 0.0;
  double signalQuality = 1.0;
  double forceVariability = 0.0;
  double overallQuality = 1.0;
  int analysisCount = 0;
  
  // Phase timing
  DateTime? unloadingStartTime;
  DateTime? brakingStartTime;
  DateTime? propulsionStartTime;
  DateTime? flightStartTime;
  DateTime? landingTime;
  
  Duration? unloadingDuration;
  Duration? brakingDuration;
  Duration? propulsionDuration;
  
  // Flags
  bool hasStartedMovement = false;
  bool takeoffDetected = false;
  bool landingDetected = false;
  bool hasAsymmetryWarning = false;
  bool hasLowSignalWarning = false;
  
  int asymmetryWarningCount = 0;
  
  RealTimeMetrics? lastMetrics;
  
  void reset() {
    currentPhase = JumpPhase.quietStanding;
    currentSmoothedForce = 0.0;
    signalQuality = 1.0;
    forceVariability = 0.0;
    overallQuality = 1.0;
    analysisCount = 0;
    
    unloadingStartTime = null;
    brakingStartTime = null;
    propulsionStartTime = null;
    flightStartTime = null;
    landingTime = null;
    
    unloadingDuration = null;
    brakingDuration = null;
    propulsionDuration = null;
    
    hasStartedMovement = false;
    takeoffDetected = false;
    landingDetected = false;
    hasAsymmetryWarning = false;
    hasLowSignalWarning = false;
    
    asymmetryWarningCount = 0;
    lastMetrics = null;
  }
}

/// Real-time metrikler
class RealTimeMetrics {
  final DateTime timestamp;
  final double currentForce;
  final double smoothedForce;
  final double peakForce;
  final double averageForce;
  final double asymmetryIndex;
  final JumpPhase currentPhase;
  final double? jumpHeight;
  final double? flightTime;
  final double? contactTime;
  final double rfd;
  final double estimatedPower;
  final double leftGRF;
  final double rightGRF;
  final double leftLoadPercentage;
  final double rightLoadPercentage;
  final ({double x, double y})? copPosition;
  final int sampleCount;
  final Duration testDuration;
  final double qualityScore;

  const RealTimeMetrics({
    required this.timestamp,
    required this.currentForce,
    required this.smoothedForce,
    required this.peakForce,
    required this.averageForce,
    required this.asymmetryIndex,
    required this.currentPhase,
    this.jumpHeight,
    this.flightTime,
    this.contactTime,
    required this.rfd,
    required this.estimatedPower,
    required this.leftGRF,
    required this.rightGRF,
    required this.leftLoadPercentage,
    required this.rightLoadPercentage,
    this.copPosition,
    required this.sampleCount,
    required this.testDuration,
    required this.qualityScore,
  });
}

/// Real-time feedback
class RealTimeFeedback {
  final DateTime timestamp;
  final JumpPhase phase;
  final String message;
  final FeedbackType type;
  final FeedbackPriority priority;
  final List<String> warnings;
  final bool actionRequired;
  final PerformanceLevel estimatedPerformance;

  const RealTimeFeedback({
    required this.timestamp,
    required this.phase,
    required this.message,
    required this.type,
    required this.priority,
    required this.warnings,
    required this.actionRequired,
    required this.estimatedPerformance,
  });
}

/// Kalite değerlendirmesi
class QualityAssessment {
  final double signalQuality; // 0-1
  final double asymmetryLevel; // %
  final double forceVariability; // N
  final double overallScore; // 0-1
  final List<String> warnings;

  const QualityAssessment({
    required this.signalQuality,
    required this.asymmetryLevel,
    required this.forceVariability,
    required this.overallScore,
    required this.warnings,
  });
  
  bool get isGoodQuality => overallScore >= 0.8;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Feedback türleri
enum FeedbackType {
  info,
  instruction,
  warning,
  positive,
  ready,
  complete,
}

/// Feedback önceliği
enum FeedbackPriority {
  low,
  medium,
  high,
}

/// Performance seviyesi
enum PerformanceLevel {
  excellent,
  good,
  average,
  poor;
  
  String get turkishName {
    switch (this) {
      case PerformanceLevel.excellent:
        return 'Mükemmel';
      case PerformanceLevel.good:
        return 'İyi';
      case PerformanceLevel.average:
        return 'Ortalama';
      case PerformanceLevel.poor:
        return 'Zayıf';
    }
  }
}