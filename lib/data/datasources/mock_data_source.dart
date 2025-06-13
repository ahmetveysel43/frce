import 'dart:async';
import 'dart:math' as math;

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/force_data.dart';
import '../../domain/entities/athlete.dart';

/// Mock veri kaynağı - Geliştirme ve test için simülasyon
class MockDataSource {
  static final MockDataSource _instance = MockDataSource._internal();
  factory MockDataSource() => _instance;
  MockDataSource._internal();

  // Stream controller for real-time data
  StreamController<ForceData>? _forceDataController;
  Timer? _dataGenerationTimer;
  
  // Mock device state
  bool _isConnected = false;
  bool _isGenerating = false;
  String _deviceId = 'MOCK_FORCE_PLATE_001';
  
  // Test simulation parameters
  TestType? _currentTestType;
  DateTime? _testStartTime;
  double _bodyWeight = 700.0; // Default body weight in Newtons
  int _sampleCount = 0;
  
  // Noise and variation parameters
  final _random = math.Random();
  double _asymmetryFactor = 0.08; // 8% default asymmetry
  
  // Calibration offsets
  double _leftZeroOffset = 0.0;
  double _rightZeroOffset = 0.0;

  // Getters
  bool get isConnected => _isConnected;
  bool get isGenerating => _isGenerating;
  String get deviceId => _deviceId;
  Stream<ForceData>? get forceDataStream => _forceDataController?.stream;

  /// Mock cihaza bağlan
  Future<bool> connect({String? deviceId}) async {
    try {
      AppLogger.info('🎭 Mock cihaza bağlanılıyor...');
      
      // Simulate connection delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (deviceId != null) {
        _deviceId = deviceId;
      }
      
      _isConnected = true;
      _forceDataController = StreamController<ForceData>.broadcast();
      
      AppLogger.usbConnected(_deviceId);
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.usbError('Mock bağlantı hatası: $e');
      AppLogger.error('Mock connection error', e, stackTrace);
      return false;
    }
  }

  /// Mock cihaz bağlantısını kes
  Future<void> disconnect() async {
    try {
      AppLogger.info('🎭 Mock cihaz bağlantısı kesiliyor...');
      
      await stopDataGeneration();
      
      _isConnected = false;
      await _forceDataController?.close();
      _forceDataController = null;
      
      AppLogger.usbDisconnected();
      
    } catch (e, stackTrace) {
      AppLogger.error('Mock disconnect error', e, stackTrace);
    }
  }

  /// Kalibrasyon yap
  Future<bool> calibrate({Duration? duration}) async {
    if (!_isConnected) {
      AppLogger.error('Mock cihaz bağlı değil - kalibrasyon yapılamaz');
      return false;
    }
    
    try {
      AppLogger.info('🎭 Mock kalibrasyon başlıyor...');
      
      final calibrationDuration = duration ?? const Duration(seconds: 3);
      
      // Simulate calibration data collection
      final calibrationData = <ForceData>[];
      final startTime = DateTime.now();
      
      while (DateTime.now().difference(startTime) < calibrationDuration) {
        final data = _generateCalibrationData();
        calibrationData.add(data);
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      // Calculate zero offsets from calibration data
      if (calibrationData.isNotEmpty) {
        _leftZeroOffset = calibrationData
            .map((d) => d.leftGRF)
            .reduce((a, b) => a + b) / calibrationData.length;
        
        _rightZeroOffset = calibrationData
            .map((d) => d.rightGRF)
            .reduce((a, b) => a + b) / calibrationData.length;
      }
      
      AppLogger.success('✅ Mock kalibrasyon tamamlandı (L: ${_leftZeroOffset.toStringAsFixed(1)}N, R: ${_rightZeroOffset.toStringAsFixed(1)}N)');
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error('Mock kalibrasyon hatası', e, stackTrace);
      return false;
    }
  }

  /// Ağırlık ölçümü başlat
  Future<double?> measureWeight({Duration? duration}) async {
    if (!_isConnected) {
      AppLogger.error('Mock cihaz bağlı değil - ağırlık ölçülemez');
      return null;
    }
    
    try {
      AppLogger.info('🎭 Mock ağırlık ölçümü başlıyor...');
      
      final measurementDuration = duration ?? const Duration(seconds: 3);
      final weightData = <double>[];
      final startTime = DateTime.now();
      
      while (DateTime.now().difference(startTime) < measurementDuration) {
        final data = _generateWeightMeasurementData();
        weightData.add(data.totalGRF);
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Calculate stable weight (average of last 1 second)
      final stableData = weightData.length > 10 
          ? weightData.sublist(weightData.length - 10)
          : weightData;
      
      final measuredWeight = stableData.reduce((a, b) => a + b) / stableData.length;
      _bodyWeight = measuredWeight;
      
      AppLogger.info('📏 Mock ağırlık ölçüldü: ${(measuredWeight / 9.81).toStringAsFixed(1)} kg');
      return measuredWeight / 9.81; // Convert to kg
      
    } catch (e, stackTrace) {
      AppLogger.error('Mock ağırlık ölçüm hatası', e, stackTrace);
      return null;
    }
  }

  /// Test veri üretimini başlat
  Future<bool> startDataGeneration({
    required TestType testType,
    Athlete? athlete,
    int sampleRate = 1000,
  }) async {
    if (!_isConnected) {
      AppLogger.error('Mock cihaz bağlı değil - veri üretimi başlatılamaz');
      return false;
    }
    
    if (_isGenerating) {
      AppLogger.warning('Mock veri üretimi zaten aktif');
      return true;
    }
    
    try {
      AppLogger.info('🎭 Mock veri üretimi başlıyor: ${testType.turkishName}');
      
      _currentTestType = testType;
      _testStartTime = DateTime.now();
      _sampleCount = 0;
      _isGenerating = true;
      
      // Athlete specific parameters
      if (athlete != null) {
        _bodyWeight = (athlete.weight ?? 70.0) * 9.81; // Convert kg to N
        _asymmetryFactor = 0.05 + (_random.nextDouble() * 0.10); // 5-15% asymmetry
      }
      
      // Start data generation timer
      final intervalMs = (1000 / sampleRate).round();
      _dataGenerationTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _generateAndSendData(),
      );
      
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error('Mock veri üretim başlatma hatası', e, stackTrace);
      return false;
    }
  }

  /// Test veri üretimini durdur
  Future<void> stopDataGeneration() async {
    if (!_isGenerating) return;
    
    try {
      AppLogger.info('🎭 Mock veri üretimi durduruluyor...');
      
      _dataGenerationTimer?.cancel();
      _dataGenerationTimer = null;
      _isGenerating = false;
      _currentTestType = null;
      _testStartTime = null;
      _sampleCount = 0;
      
      AppLogger.info('✅ Mock veri üretimi durduruldu');
      
    } catch (e, stackTrace) {
      AppLogger.error('Mock veri üretim durdurma hatası', e, stackTrace);
    }
  }

  /// Test connection
  Future<bool> testConnection() async {
    if (!_isConnected) return false;
    
    try {
      // Simulate connection test
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Generate test data
      final testData = _generateTestConnectionData();
      _forceDataController?.add(testData);
      
      AppLogger.info('🎭 Mock bağlantı testi başarılı');
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error('Mock bağlantı test hatası', e, stackTrace);
      return false;
    }
  }

  // Private methods

  void _generateAndSendData() {
    if (!_isConnected || !_isGenerating || _forceDataController == null) return;
    
    try {
      final data = _generateTestSpecificData();
      _forceDataController!.add(data);
      _sampleCount++;
      
    } catch (e, stackTrace) {
      AppLogger.error('Mock veri üretim hatası', e, stackTrace);
    }
  }

  ForceData _generateTestSpecificData() {
    final elapsedSeconds = _testStartTime != null 
        ? DateTime.now().difference(_testStartTime!).inMilliseconds / 1000.0
        : 0.0;
    
    switch (_currentTestType!) {
      case TestType.counterMovementJump:
        return _generateCMJData(elapsedSeconds);
      case TestType.squatJump:
        return _generateSJData(elapsedSeconds);
      case TestType.dropJump:
        return _generateDJData(elapsedSeconds);
      case TestType.isometricMidThighPull:
        return _generateIMTPData(elapsedSeconds);
      case TestType.isometricSquat:
        return _generateIsometricSquatData(elapsedSeconds);
      case TestType.staticBalance:
        return _generateStaticBalanceData(elapsedSeconds);
      case TestType.dynamicBalance:
        return _generateDynamicBalanceData(elapsedSeconds);
      case TestType.singleLegBalance:
        return _generateSingleLegBalanceData(elapsedSeconds);
      default:
        return _generateGenericData(elapsedSeconds);
    }
  }

  ForceData _generateCMJData(double timeSeconds) {
    double totalForce = _bodyWeight;
    
    if (timeSeconds < 1.0) {
      // Quiet standing phase
      totalForce = _bodyWeight + _generateNoise(20);
    } else if (timeSeconds < 1.8) {
      // Unloading phase
      final phase = (timeSeconds - 1.0) / 0.8;
      final unloadingDepth = 0.7 + (phase * 0.25); // 70-95% of body weight
      totalForce = _bodyWeight * unloadingDepth + _generateNoise(30);
    } else if (timeSeconds < 2.3) {
      // Braking phase (eccentric)
      final phase = (timeSeconds - 1.8) / 0.5;
      final brakeForce = 0.95 + (phase * 1.3); // 95-225% of body weight
      totalForce = _bodyWeight * brakeForce + _generateNoise(50);
    } else if (timeSeconds < 2.6) {
      // Propulsion phase (concentric)
      final phase = (timeSeconds - 2.3) / 0.3;
      final propulsionForce = 2.25 - (phase * 0.5); // 225-175% peak then decreasing
      totalForce = _bodyWeight * propulsionForce + _generateNoise(40);
    } else if (timeSeconds < 3.0) {
      // Flight phase
      totalForce = _generateNoise(15); // Minimal force, mostly noise
    } else if (timeSeconds < 3.8) {
      // Landing phase
      final phase = (timeSeconds - 3.0) / 0.8;
      final landingForce = 2.8 - (phase * 1.3); // High impact then settling
      totalForce = _bodyWeight * landingForce + _generateNoise(60);
    } else {
      // Recovery phase
      totalForce = _bodyWeight + _generateNoise(25);
    }
    
    return _createForceData(totalForce, timeSeconds);
  }

  ForceData _generateSJData(double timeSeconds) {
    // Squat jump - no counter movement
    double totalForce = _bodyWeight;
    
    if (timeSeconds < 1.5) {
      // Static squat position
      totalForce = _bodyWeight * 0.8 + _generateNoise(25);
    } else if (timeSeconds < 2.0) {
      // Propulsion phase
      final phase = (timeSeconds - 1.5) / 0.5;
      final propulsionForce = 0.8 + (phase * 1.6); // 80-240% of body weight
      totalForce = _bodyWeight * propulsionForce + _generateNoise(45);
    } else if (timeSeconds < 2.4) {
      // Flight phase
      totalForce = _generateNoise(12);
    } else if (timeSeconds < 3.2) {
      // Landing phase
      final phase = (timeSeconds - 2.4) / 0.8;
      final landingForce = 2.6 - (phase * 1.1);
      totalForce = _bodyWeight * landingForce + _generateNoise(55);
    } else {
      // Recovery
      totalForce = _bodyWeight + _generateNoise(20);
    }
    
    return _createForceData(totalForce, timeSeconds);
  }

  ForceData _generateDJData(double timeSeconds) {
    // Drop jump - includes pre-landing
    double totalForce = _bodyWeight;
    
    if (timeSeconds < 0.5) {
      // Initial drop (minimal force)
      totalForce = _generateNoise(10);
    } else if (timeSeconds < 1.0) {
      // Landing from drop
      final phase = (timeSeconds - 0.5) / 0.5;
      final landingForce = 3.2 - (phase * 1.7); // High impact landing
      totalForce = _bodyWeight * landingForce + _generateNoise(70);
    } else if (timeSeconds < 1.3) {
      // Amortization phase
      totalForce = _bodyWeight * 1.2 + _generateNoise(35);
    } else if (timeSeconds < 1.6) {
      // Propulsion phase
      final phase = (timeSeconds - 1.3) / 0.3;
      final propulsionForce = 1.2 + (phase * 1.0);
      totalForce = _bodyWeight * propulsionForce + _generateNoise(40);
    } else if (timeSeconds < 2.0) {
      // Flight phase
      totalForce = _generateNoise(15);
    } else if (timeSeconds < 2.8) {
      // Final landing
      final phase = (timeSeconds - 2.0) / 0.8;
      final finalLanding = 2.5 - (phase * 1.0);
      totalForce = _bodyWeight * finalLanding + _generateNoise(50);
    } else {
      // Recovery
      totalForce = _bodyWeight + _generateNoise(22);
    }
    
    return _createForceData(totalForce, timeSeconds);
  }

  ForceData _generateIMTPData(double timeSeconds) {
    // Isometric Mid-Thigh Pull
    double totalForce = _bodyWeight;
    
    if (timeSeconds < 1.0) {
      // Setup phase
      totalForce = _bodyWeight + _generateNoise(15);
    } else if (timeSeconds < 4.0) {
      // Force buildup phase
      final phase = (timeSeconds - 1.0) / 3.0;
      final buildupForce = 1.0 + (phase * 2.5); // Build to 350% body weight
      totalForce = _bodyWeight * buildupForce + _generateNoise(35);
    } else if (timeSeconds < 6.0) {
      // Maximal effort phase
      final maxForce = 3.5 + (_random.nextDouble() * 0.5 - 0.25); // 325-375% with variation
      totalForce = _bodyWeight * maxForce + _generateNoise(45);
    } else {
      // Release phase
      final phase = (timeSeconds - 6.0) / 1.0;
      final releaseForce = 3.5 - (phase * 2.5);
      totalForce = _bodyWeight * math.max(1.0, releaseForce) + _generateNoise(25);
    }
    
    return _createForceData(totalForce, timeSeconds);
  }

  ForceData _generateIsometricSquatData(double timeSeconds) {
    // Similar to IMTP but with different force profile
    double totalForce = _bodyWeight;
    
    if (timeSeconds < 1.0) {
      // Setup in squat position
      totalForce = _bodyWeight * 0.9 + _generateNoise(20);
    } else if (timeSeconds < 3.5) {
      // Force buildup
      final phase = (timeSeconds - 1.0) / 2.5;
      final buildupForce = 0.9 + (phase * 1.8); // Build to 270% body weight
      totalForce = _bodyWeight * buildupForce + _generateNoise(40);
    } else if (timeSeconds < 5.5) {
      // Maximal isometric effort
      final maxForce = 2.7 + (_random.nextDouble() * 0.4 - 0.2);
      totalForce = _bodyWeight * maxForce + _generateNoise(35);
    } else {
      // Release
      final phase = (timeSeconds - 5.5) / 1.0;
      final releaseForce = 2.7 - (phase * 1.8);
      totalForce = _bodyWeight * math.max(0.9, releaseForce) + _generateNoise(25);
    }
    
    return _createForceData(totalForce, timeSeconds);
  }

  ForceData _generateStaticBalanceData(double timeSeconds) {
    // Static balance - small variations around body weight
    final baseForce = _bodyWeight + _generateNoise(25);
    
    // Add slow oscillations for realistic sway
    final swayX = math.sin(timeSeconds * 0.5) * 15;
    final swayY = math.cos(timeSeconds * 0.3) * 12;
    
    return ForceData.create(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      leftGRF: (baseForce * (0.5 + _asymmetryFactor / 2)) - _leftZeroOffset,
      rightGRF: (baseForce * (0.5 - _asymmetryFactor / 2)) - _rightZeroOffset,
      leftCopX: swayX + _generateNoise(8),
      leftCopY: swayY + _generateNoise(10),
      rightCopX: -swayX + _generateNoise(8),
      rightCopY: swayY + _generateNoise(10),
    );
  }

  ForceData _generateDynamicBalanceData(double timeSeconds) {
    // Dynamic balance - larger variations and movements
    final baseForce = _bodyWeight + _generateNoise(40);
    
    // More dynamic sway patterns
    final swayX = math.sin(timeSeconds * 1.2) * 25 + math.cos(timeSeconds * 0.8) * 15;
    final swayY = math.cos(timeSeconds * 0.9) * 20 + math.sin(timeSeconds * 1.1) * 18;
    
    return ForceData.create(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      leftGRF: (baseForce * (0.5 + _asymmetryFactor / 2)) - _leftZeroOffset,
      rightGRF: (baseForce * (0.5 - _asymmetryFactor / 2)) - _rightZeroOffset,
      leftCopX: swayX + _generateNoise(15),
      leftCopY: swayY + _generateNoise(18),
      rightCopX: -swayX * 0.8 + _generateNoise(15),
      rightCopY: swayY * 0.9 + _generateNoise(18),
    );
  }

  ForceData _generateSingleLegBalanceData(double timeSeconds) {
    // Single leg balance - higher asymmetry, more variability
    final baseForce = _bodyWeight * 0.85 + _generateNoise(35); // Slightly less total force
    
    // Single leg has more sway
    final swayX = math.sin(timeSeconds * 1.5) * 35 + math.cos(timeSeconds * 0.6) * 20;
    final swayY = math.cos(timeSeconds * 1.1) * 30 + math.sin(timeSeconds * 0.7) * 25;
    
    // Simulate single leg (90% on one leg, 10% on other)
    final leftForce = baseForce * 0.9;
    final rightForce = baseForce * 0.1;
    
    return ForceData.create(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      leftGRF: leftForce - _leftZeroOffset,
      rightGRF: rightForce - _rightZeroOffset + _generateNoise(15),
      leftCopX: swayX + _generateNoise(20),
      leftCopY: swayY + _generateNoise(25),
      rightCopX: _generateNoise(30), // Minimal contact
      rightCopY: _generateNoise(30),
    );
  }

  ForceData _generateGenericData(double timeSeconds) {
    final totalForce = _bodyWeight + _generateNoise(30);
    return _createForceData(totalForce, timeSeconds);
  }

  ForceData _generateCalibrationData() {
    // Small random forces for calibration (should be close to zero)
    final leftForce = _generateNoise(10);
    final rightForce = _generateNoise(10);
    
    return ForceData.create(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      leftGRF: leftForce,
      rightGRF: rightForce,
      leftCopX: _generateNoise(5),
      leftCopY: _generateNoise(5),
      rightCopX: _generateNoise(5),
      rightCopY: _generateNoise(5),
    );
  }

  ForceData _generateWeightMeasurementData() {
    // Stable weight measurement with some variation
    final totalForce = _bodyWeight + _generateNoise(15);
    return _createForceData(totalForce, 0);
  }

  ForceData _generateTestConnectionData() {
    // Simple test data for connection verification
    final totalForce = 100.0 + _generateNoise(5);
    return _createForceData(totalForce, 0);
  }

  ForceData _createForceData(double totalForce, double timeSeconds) {
    // Apply asymmetry
    final leftForce = math.max(0, totalForce * (0.5 + _asymmetryFactor / 2) - _leftZeroOffset);
    final rightForce = math.max(0, totalForce * (0.5 - _asymmetryFactor / 2) - _rightZeroOffset);
    
    // Generate realistic COP values
    final copX = math.sin(timeSeconds * 2.1) * 30 + _generateNoise(15);
    final copY = math.cos(timeSeconds * 1.7) * 40 + _generateNoise(20);
    
    return ForceData.create(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      leftGRF: leftForce.toDouble(),
      rightGRF: rightForce.toDouble(),
      leftCopX: copX + _generateNoise(10),
      leftCopY: copY + _generateNoise(12),
      rightCopX: -copX * 0.8 + _generateNoise(10),
      rightCopY: copY * 0.9 + _generateNoise(12),
    );
  }

  double _generateNoise(double amplitude) {
    return (_random.nextDouble() - 0.5) * amplitude;
  }

  /// Get mock device info
  Map<String, dynamic> getDeviceInfo() {
    return {
      'deviceId': _deviceId,
      'isConnected': _isConnected,
      'isGenerating': _isGenerating,
      'sampleRate': AppConstants.sampleRate,
      'loadCells': AppConstants.loadCellCount,
      'firmwareVersion': 'MOCK_v1.0.0',
      'lastCalibration': DateTime.now().subtract(const Duration(hours: 1)),
      'leftZeroOffset': _leftZeroOffset,
      'rightZeroOffset': _rightZeroOffset,
      'bodyWeight': _bodyWeight,
      'asymmetryFactor': _asymmetryFactor,
      'sampleCount': _sampleCount,
    };
  }

  /// Update mock parameters
  void updateParameters({
    double? bodyWeight,
    double? asymmetryFactor,
  }) {
    if (bodyWeight != null) _bodyWeight = bodyWeight;
    if (asymmetryFactor != null) _asymmetryFactor = asymmetryFactor;
    
    AppLogger.info('🎭 Mock parametreler güncellendi: BW=${_bodyWeight.toStringAsFixed(1)}N, Asym=${(_asymmetryFactor*100).toStringAsFixed(1)}%');
  }

  /// Dispose resources
  void dispose() {
    _dataGenerationTimer?.cancel();
    _forceDataController?.close();
    AppLogger.info('🎭 Mock data source disposed');
  }
}