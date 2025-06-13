import 'dart:async';
import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../../domain/entities/force_data.dart';

/// Otomatik test algılama sistemi
/// VALD ForceDecks benzeri hareket tanıma
class AutomaticTestDetector {
  // Detection parameters
  static const double _quietStandingThreshold = 50.0; // N variation
  static const double _movementStartThreshold = 100.0; // N deviation
  static const int _quietStandingDuration = 500; // ms
  static const int _movementConfirmationTime = 100; // ms
  
  // Test pattern signatures
  static const Map<TestType, TestSignature> _testSignatures = {
    TestType.counterMovementJump: TestSignature(
      name: 'CMJ',
      hasUnloadingPhase: true,
      unloadingDepth: 0.8, // 80% of body weight
      hasFlight: true,
      minFlightTime: 100, // ms
      hasCounterMovement: true,
      peakForceRange: (1.5, 4.0), // x body weight
    ),
    TestType.squatJump: TestSignature(
      name: 'SJ',
      hasUnloadingPhase: false,
      unloadingDepth: 0.95,
      hasFlight: true,
      minFlightTime: 100,
      hasCounterMovement: false,
      peakForceRange: (1.3, 3.5),
    ),
    TestType.dropJump: TestSignature(
      name: 'DJ',
      hasUnloadingPhase: true,
      unloadingDepth: 0.5, // Deep due to landing
      hasFlight: true,
      minFlightTime: 50,
      hasCounterMovement: true,
      peakForceRange: (2.0, 5.0), // Higher due to drop
    ),
    TestType.isometricMidThighPull: TestSignature(
      name: 'IMTP',
      hasUnloadingPhase: false,
      unloadingDepth: 1.0,
      hasFlight: false,
      minFlightTime: 0,
      hasCounterMovement: false,
      peakForceRange: (2.0, 4.0),
    ),
  };
  
  // Internal state
  final StreamController<TestDetectionEvent> _detectionController = StreamController.broadcast();
  final List<ForceData> _buffer = [];
  final Map<TestType, double> _confidenceScores = {};
  
  TestDetectionState _state = TestDetectionState.waitingForStability;
  DateTime? _quietStandingStart;
  DateTime? _movementStart;
  double _bodyWeightN = 0.0;
  double _baselineForce = 0.0;
  TestType? _detectedTestType;
  
  // Public stream
  Stream<TestDetectionEvent> get detectionStream => _detectionController.stream;
  
  /// Başlat
  void startDetection() {
    AppLogger.info('🔍 Otomatik test algılama başlatıldı');
    _reset();
    _state = TestDetectionState.waitingForStability;
  }
  
  /// Durdur
  void stopDetection() {
    AppLogger.info('🛑 Otomatik test algılama durduruldu');
    _state = TestDetectionState.inactive;
  }
  
  /// Force data ekle
  void addForceData(ForceData data) {
    if (_state == TestDetectionState.inactive) return;
    
    _buffer.add(data);
    if (_buffer.length > 5000) { // 5 saniye @ 1000Hz
      _buffer.removeAt(0);
    }
    
    _processDetection(data);
  }
  
  /// Ana detection logic
  void _processDetection(ForceData currentData) {
    switch (_state) {
      case TestDetectionState.waitingForStability:
        _checkForStability(currentData);
        break;
        
      case TestDetectionState.detectingBodyWeight:
        _detectBodyWeight(currentData);
        break;
        
      case TestDetectionState.waitingForMovement:
        _checkForMovementStart(currentData);
        break;
        
      case TestDetectionState.analyzingMovement:
        _analyzeMovementPattern();
        break;
        
      case TestDetectionState.testDetected:
      case TestDetectionState.inactive:
        break;
    }
  }
  
  /// Stabilite kontrolü
  void _checkForStability(ForceData data) {
    final recentData = _getRecentData(500); // Son 500ms
    if (recentData.isEmpty) return;
    
    final forces = recentData.map((d) => d.totalGRF).toList();
    final mean = _calculateMean(forces);
    final std = _calculateStandardDeviation(forces, mean);
    
    if (std < _quietStandingThreshold) {
      _quietStandingStart ??= DateTime.now();
      
      if (DateTime.now().difference(_quietStandingStart!).inMilliseconds >= _quietStandingDuration) {
        AppLogger.debug('✅ Stabilite sağlandı');
        _state = TestDetectionState.detectingBodyWeight;
        _detectionController.add(TestDetectionEvent(
          type: DetectionEventType.stabilityAchieved,
          message: 'Platform stabilize oldu',
        ));
      }
    } else {
      _quietStandingStart = null;
    }
  }
  
  /// Vücut ağırlığı tespiti
  void _detectBodyWeight(ForceData data) {
    final recentData = _getRecentData(1000); // Son 1 saniye
    if (recentData.isEmpty) return;
    
    final forces = recentData.map((d) => d.totalGRF).toList();
    final mean = _calculateMean(forces);
    final std = _calculateStandardDeviation(forces, mean);
    
    if (std < _quietStandingThreshold) {
      _bodyWeightN = mean;
      _baselineForce = mean;
      
      AppLogger.info('📏 Vücut ağırlığı tespit edildi: ${(_bodyWeightN / 9.81).toStringAsFixed(1)} kg');
      
      _state = TestDetectionState.waitingForMovement;
      _detectionController.add(TestDetectionEvent(
        type: DetectionEventType.bodyWeightDetected,
        message: 'Vücut ağırlığı: ${(_bodyWeightN / 9.81).toStringAsFixed(1)} kg',
        bodyWeight: _bodyWeightN / 9.81,
      ));
    }
  }
  
  /// Hareket başlangıcı kontrolü
  void _checkForMovementStart(ForceData data) {
    final deviation = (data.totalGRF - _baselineForce).abs();
    
    if (deviation > _movementStartThreshold) {
      _movementStart ??= DateTime.now();
      
      if (DateTime.now().difference(_movementStart!).inMilliseconds >= _movementConfirmationTime) {
        AppLogger.debug('🏃 Hareket başladı');
        _state = TestDetectionState.analyzingMovement;
        
        _detectionController.add(TestDetectionEvent(
          type: DetectionEventType.movementStarted,
          message: 'Test hareketi başladı',
        ));
        
        // Start pattern analysis after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (_state == TestDetectionState.analyzingMovement) {
            _analyzeMovementPattern();
          }
        });
      }
    } else {
      _movementStart = null;
    }
  }
  
  /// Hareket pattern analizi
  void _analyzeMovementPattern() {
    if (_buffer.length < 1000) return; // En az 1 saniye data
    
    final movementStartTimestamp = _movementStart!.millisecondsSinceEpoch;
    final movementData = _buffer.where((d) => 
      d.timestamp > movementStartTimestamp
    ).toList();
    
    if (movementData.isEmpty) return;
    
    // Extract movement features
    final features = _extractMovementFeatures(movementData);
    
    // Calculate confidence scores for each test type
    _confidenceScores.clear();
    
    for (final entry in _testSignatures.entries) {
      final testType = entry.key;
      final signature = entry.value;
      final confidence = _calculateConfidence(features, signature);
      _confidenceScores[testType] = confidence;
    }
    
    // Find best match
    final bestMatch = _confidenceScores.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    if (bestMatch.value > 0.7) { // 70% confidence threshold
      _detectedTestType = bestMatch.key;
      _state = TestDetectionState.testDetected;
      
      AppLogger.success('🎯 Test algılandı: ${_detectedTestType!.turkishName} (Güven: ${(bestMatch.value * 100).toStringAsFixed(0)}%)');
      
      _detectionController.add(TestDetectionEvent(
        type: DetectionEventType.testDetected,
        message: '${_detectedTestType!.turkishName} testi algılandı',
        detectedTest: _detectedTestType,
        confidence: bestMatch.value,
        allConfidences: Map.from(_confidenceScores),
      ));
    }
  }
  
  /// Hareket özelliklerini çıkar
  MovementFeatures _extractMovementFeatures(List<ForceData> movementData) {
    final forces = movementData.map((d) => d.totalGRF).toList();
    
    // Basic statistics
    final maxForce = forces.reduce(math.max);
    final minForce = forces.reduce(math.min);
    final avgForce = _calculateMean(forces);
    
    // Unloading detection
    final unloadingDepth = minForce / _bodyWeightN;
    final hasUnloading = unloadingDepth < 0.95;
    
    // Flight detection
    final flightThreshold = _bodyWeightN * 0.1;
    final flightSamples = forces.where((f) => f < flightThreshold).length;
    final hasFlight = flightSamples > 50; // 50ms @ 1000Hz
    
    // Counter movement detection
    final firstQuarter = forces.take(forces.length ~/ 4).toList();
    final hasCounterMovement = firstQuarter.any((f) => f < _bodyWeightN * 0.9);
    
    // Rate of force development
    final rfd = _calculateMaxRFD(movementData);
    
    // Duration
    final durationMs = movementData.last.timestamp - movementData.first.timestamp;
    final duration = Duration(milliseconds: durationMs);
    
    return MovementFeatures(
      maxForce: maxForce,
      minForce: minForce,
      avgForce: avgForce,
      maxForceRelative: maxForce / _bodyWeightN,
      unloadingDepth: unloadingDepth,
      hasUnloading: hasUnloading,
      hasFlight: hasFlight,
      flightDuration: flightSamples,
      hasCounterMovement: hasCounterMovement,
      maxRFD: rfd,
      totalDuration: duration,
      forceVariability: _calculateStandardDeviation(forces, avgForce),
    );
  }
  
  /// Test signature ile confidence hesapla
  double _calculateConfidence(MovementFeatures features, TestSignature signature) {
    double score = 0.0;
    double maxScore = 0.0;
    
    // Unloading phase check (weight: 20%)
    maxScore += 20;
    if (features.hasUnloading == signature.hasUnloadingPhase) {
      score += 20;
      
      // Unloading depth similarity
      if (features.hasUnloading) {
        final depthDiff = (features.unloadingDepth - signature.unloadingDepth).abs();
        score -= depthDiff * 10; // Penalty for difference
      }
    }
    
    // Flight phase check (weight: 30%)
    maxScore += 30;
    if (features.hasFlight == signature.hasFlight) {
      score += 30;
      
      // Flight time check
      if (features.hasFlight && features.flightDuration >= signature.minFlightTime) {
        score += 10; // Bonus
      }
    }
    
    // Counter movement check (weight: 20%)
    maxScore += 20;
    if (features.hasCounterMovement == signature.hasCounterMovement) {
      score += 20;
    }
    
    // Peak force range check (weight: 30%)
    maxScore += 30;
    final (minPeak, maxPeak) = signature.peakForceRange;
    if (features.maxForceRelative >= minPeak && features.maxForceRelative <= maxPeak) {
      score += 30;
    } else {
      // Partial score based on proximity
      final distance = features.maxForceRelative < minPeak 
          ? minPeak - features.maxForceRelative
          : features.maxForceRelative - maxPeak;
      score += math.max(0, 30 - distance * 10);
    }
    
    return (score / maxScore).clamp(0.0, 1.0);
  }
  
  /// Max RFD hesapla
  double _calculateMaxRFD(List<ForceData> data) {
    if (data.length < 50) return 0.0;
    
    double maxRFD = 0.0;
    const windowSize = 50; // 50ms window
    
    for (int i = 0; i < data.length - windowSize; i++) {
      final startForce = data[i].totalGRF;
      final endForce = data[i + windowSize].totalGRF;
      const deltaTime = windowSize / 1000.0; // seconds
      
      final rfd = (endForce - startForce) / deltaTime;
      maxRFD = math.max(maxRFD, rfd);
    }
    
    return maxRFD;
  }
  
  // Helper methods
  List<ForceData> _getRecentData(int milliseconds) {
    if (_buffer.isEmpty) return [];
    
    final cutoffTimestamp = DateTime.now().subtract(Duration(milliseconds: milliseconds)).millisecondsSinceEpoch;
    return _buffer.where((d) => d.timestamp > cutoffTimestamp).toList();
  }
  
  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  double _calculateStandardDeviation(List<double> values, double mean) {
    if (values.length < 2) return 0.0;
    
    final sumSquaredDiff = values
        .map((v) => math.pow(v - mean, 2))
        .reduce((a, b) => a + b);
    
    return math.sqrt(sumSquaredDiff / values.length);
  }
  
  void _reset() {
    _buffer.clear();
    _confidenceScores.clear();
    _quietStandingStart = null;
    _movementStart = null;
    _bodyWeightN = 0.0;
    _baselineForce = 0.0;
    _detectedTestType = null;
  }
  
  void dispose() {
    _detectionController.close();
  }
}

// ===== DATA CLASSES =====

/// Test detection states
enum TestDetectionState {
  inactive,
  waitingForStability,
  detectingBodyWeight,
  waitingForMovement,
  analyzingMovement,
  testDetected,
}

/// Test signature for pattern matching
class TestSignature {
  final String name;
  final bool hasUnloadingPhase;
  final double unloadingDepth; // % of body weight
  final bool hasFlight;
  final int minFlightTime; // ms
  final bool hasCounterMovement;
  final (double, double) peakForceRange; // min, max as x body weight
  
  const TestSignature({
    required this.name,
    required this.hasUnloadingPhase,
    required this.unloadingDepth,
    required this.hasFlight,
    required this.minFlightTime,
    required this.hasCounterMovement,
    required this.peakForceRange,
  });
}

/// Movement features extracted from force data
class MovementFeatures {
  final double maxForce;
  final double minForce;
  final double avgForce;
  final double maxForceRelative; // x body weight
  final double unloadingDepth; // % of body weight
  final bool hasUnloading;
  final bool hasFlight;
  final int flightDuration; // samples
  final bool hasCounterMovement;
  final double maxRFD;
  final Duration totalDuration;
  final double forceVariability;
  
  const MovementFeatures({
    required this.maxForce,
    required this.minForce,
    required this.avgForce,
    required this.maxForceRelative,
    required this.unloadingDepth,
    required this.hasUnloading,
    required this.hasFlight,
    required this.flightDuration,
    required this.hasCounterMovement,
    required this.maxRFD,
    required this.totalDuration,
    required this.forceVariability,
  });
}

/// Detection event
class TestDetectionEvent {
  final DetectionEventType type;
  final String message;
  final DateTime timestamp;
  final double? bodyWeight;
  final TestType? detectedTest;
  final double? confidence;
  final Map<TestType, double>? allConfidences;
  
  TestDetectionEvent({
    required this.type,
    required this.message,
    this.bodyWeight,
    this.detectedTest,
    this.confidence,
    this.allConfidences,
  }) : timestamp = DateTime.now();
}

/// Detection event types
enum DetectionEventType {
  stabilityAchieved,
  bodyWeightDetected,
  movementStarted,
  testDetected,
  detectionFailed,
}