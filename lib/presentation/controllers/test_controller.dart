import 'dart:async';
import 'dart:math' as math;
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/entities/force_data.dart';
import '../../domain/entities/test_result.dart';

/// izForce test controller - Ana test yönetimi
class TestController extends GetxController {
  // ===== STATE VARIABLES =====
  
  // Connection state
  final _connectionStatus = ConnectionStatus.disconnected.obs;
  final _connectedDevice = Rxn<String>();
  
  // Test flow state
  final _currentStep = TestStep.deviceConnection.obs;
  final _selectedAthlete = Rxn<Athlete>();
  final _selectedTestType = Rxn<TestType>();
  
  // Calibration state
  final _isCalibrated = false.obs;
  final _leftZeroOffset = 0.0.obs;
  final _rightZeroOffset = 0.0.obs;
  final _calibrationProgress = 0.0.obs;
  
  // Weight measurement state
  final _measuredWeight = Rxn<double>();
  final _isWeightStable = false.obs;
  final _weightSamples = <double>[].obs;
  
  // Test execution state
  final _isTestRunning = false.obs;
  final _testStartTime = Rxn<DateTime>();
  final _testDuration = Duration.zero.obs;
  final _currentPhase = JumpPhase.quietStanding.obs;
  
  // Real-time data
  final _forceData = <ForceData>[].obs;
  final _liveMetrics = <String, double>{}.obs;
  
  // Results
  final _testResults = Rxn<TestResult>();
  final _isProcessingResults = false.obs;
  
  // Mock mode
  final _isMockMode = true.obs;
  Timer? _mockDataTimer;
  Timer? _testTimer;
  Timer? _weightTimer;
  
  // Error handling
  final _errorMessage = Rxn<String>();
  final _isLoading = false.obs;

  // ===== GETTERS =====
  
  // Connection
  ConnectionStatus get connectionStatus => _connectionStatus.value;
  String? get connectedDevice => _connectedDevice.value;
  bool get isConnected => _connectionStatus.value == ConnectionStatus.connected;
  
  // Test flow
  TestStep get currentStep => _currentStep.value;
  Athlete? get selectedAthlete => _selectedAthlete.value;
  TestType? get selectedTestType => _selectedTestType.value;
  
  // Calibration
  bool get isCalibrated => _isCalibrated.value;
  double get calibrationProgress => _calibrationProgress.value;
  
  // Weight
  double? get measuredWeight => _measuredWeight.value;
  bool get isWeightStable => _isWeightStable.value;
  String get weightStatus {
    if (_measuredWeight.value == null) return 'Platformlara çıkın';
    if (!_isWeightStable.value) return 'Sabit durun...';
    return 'Ağırlık: ${_measuredWeight.value!.toStringAsFixed(1)} kg';
  }
  
  // Test execution
  bool get isTestRunning => _isTestRunning.value;
  Duration get testDuration => _testDuration.value;
  JumpPhase get currentPhase => _currentPhase.value;
  int get sampleCount => _forceData.length;
  
  // Results
  TestResult? get testResults => _testResults.value;
  bool get isProcessingResults => _isProcessingResults.value;
  Map<String, double> get liveMetrics => Map.from(_liveMetrics);
  
  // Status
  String? get errorMessage => _errorMessage.value;
  bool get isLoading => _isLoading.value;
  bool get isMockMode => _isMockMode.value;
  bool get isInitialized => true;

  // Force data getter
  List<ForceData> get forceData => List.from(_forceData);

  // Progress calculation
  double get overallProgress {
    switch (_currentStep.value) {
      case TestStep.deviceConnection:
        return isConnected ? 0.16 : 0.0;
      case TestStep.athleteSelection:
        return _selectedAthlete.value != null ? 0.32 : 0.16;
      case TestStep.testSelection:
        return _selectedTestType.value != null ? 0.48 : 0.32;
      case TestStep.calibration:
        return _isCalibrated.value ? 0.64 : 0.48;
      case TestStep.weightMeasurement:
        return _isWeightStable.value ? 0.80 : 0.64;
      case TestStep.testExecution:
        return 0.95;
      case TestStep.results:
        return 1.0;
    }
  }

  // ===== LIFECYCLE =====
  
  @override
  void onInit() {
    super.onInit();
    AppLogger.info('🎮 TestController başlatılıyor...');
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      // Mock mode'u aktif et (geliştirme için)
      if (_isMockMode.value) {
        _simulateDeviceConnection();
      }
      
      AppLogger.success('✅ TestController başlatıldı');
    } catch (e) {
      AppLogger.error('TestController başlatma hatası', e);
      _setError('Controller başlatma hatası: $e');
    }
  }

  @override
  void onClose() {
    _cancelAllTimers();
    super.onClose();
  }

  // ===== PUBLIC METHODS =====

  /// Mock mode'u aktif/pasif et
  void enableMockMode() {
    _isMockMode.value = true;
    AppLogger.info('🎭 Mock mode aktif');
  }

  void disableMockMode() {
    _isMockMode.value = false;
    AppLogger.info('🔧 Hardware mode aktif');
  }

  /// Test'i duraklat (app lifecycle için)
  void pauseIfRunning() {
    if (_isTestRunning.value) {
      AppLogger.info('⏸️ Test duraklatıldı (app paused)');
      _cancelAllTimers();
    }
  }

  /// Test'i devam ettir
  void resumeIfPaused() {
    if (_testStartTime.value != null && !_isTestRunning.value) {
      AppLogger.info('▶️ Test devam etti (app resumed)');
      _startTestTimer();
    }
  }

  /// Tüm testleri durdur
  void stopAllTests() {
    if (_isTestRunning.value) {
      AppLogger.info('🛑 Tüm testler durduruldu');
      _stopTest();
    }
  }

  // ===== STEP 1: DEVICE CONNECTION =====

  Future<bool> connectToDevice(String deviceId) async {
    _setLoading(true);
    _connectionStatus.value = ConnectionStatus.connecting;
    
    try {
      await Future.delayed(const Duration(seconds: 2)); // Simulate connection
      
      if (_isMockMode.value) {
        _connectedDevice.value = 'Mock Device ($deviceId)';
        _connectionStatus.value = ConnectionStatus.connected;
        AppLogger.usbConnected(deviceId);
        
        // Connection başarılı olduğunda step güncellenmemeli
        // _goToNextStep(); // KALDIRILDI
        return true;
      } else {
        // TODO: Real USB connection logic
        throw UnimplementedError('Hardware connection not implemented');
      }
    } catch (e) {
      AppLogger.usbError(e.toString());
      _connectionStatus.value = ConnectionStatus.error;
      _setError('Bağlantı hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void disconnectDevice() {
    _connectedDevice.value = null;
    _connectionStatus.value = ConnectionStatus.disconnected;
    _resetTestFlow();
    AppLogger.usbDisconnected();
  }

  void _simulateDeviceConnection() {
    Future.delayed(const Duration(seconds: 1), () {
      _connectedDevice.value = 'izForce Mock Device';
      _connectionStatus.value = ConnectionStatus.connected;
      AppLogger.info('🔌 Mock device connected');
    });
  }

  // ===== STEP 2: ATHLETE SELECTION =====

  void selectAthlete(Athlete athlete) {
    _selectedAthlete.value = athlete;
    _clearError();
    AppLogger.info('👤 Sporcu seçildi: ${athlete.fullName}');
    
    // Athlete seçildiğinde step'i güncelle
    if (_currentStep.value == TestStep.deviceConnection || _currentStep.value == TestStep.athleteSelection) {
      _currentStep.value = TestStep.athleteSelection;
    }
  }

  void proceedToAthleteSelection() {
    if (!isConnected) {
      _setError('Önce cihaza bağlanın');
      return;
    }
    _currentStep.value = TestStep.athleteSelection;
    update(); // GetBuilder'ı güncelle
    AppLogger.info('👤 Sporcu seçim adımına geçildi');
  }

  void proceedToTestSelection() {
    if (_selectedAthlete.value == null) {
      _setError('Lütfen bir sporcu seçin');
      return;
    }
    _currentStep.value = TestStep.testSelection;
    update(); // GetBuilder'ı güncelle
    AppLogger.info('🏃 Test seçim adımına geçildi');
  }

  // ===== STEP 3: TEST SELECTION =====

  void selectTestType(TestType testType) {
    _selectedTestType.value = testType;
    _clearError();
    AppLogger.info('🏃 Test türü seçildi: ${testType.turkishName}');
    
    // Test seçildiğinde otomatik olarak calibration'a geç
    _currentStep.value = TestStep.testSelection;
  }

  void proceedToCalibration() {
    if (_selectedTestType.value == null) {
      _setError('Lütfen bir test türü seçin');
      return;
    }
    _currentStep.value = TestStep.calibration;
    _isCalibrated.value = false; // Reset calibration
    update(); // GetBuilder'ı güncelle
    AppLogger.info('⚖️ Kalibrasyon adımına geçildi');
  }

  // ===== STEP 4: CALIBRATION =====

  Future<bool> startCalibration() async {
    _setLoading(true);
    _calibrationProgress.value = 0.0;
    
    try {
      AppLogger.info('⚖️ Kalibrasyon başladı');
      
      // 3 saniye kalibrasyon simülasyonu
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 150));
        _calibrationProgress.value = i / 100.0;
      }
      
      // Mock kalibrasyon değerleri
      _leftZeroOffset.value = 5.0 + (math.Random().nextDouble() - 0.5) * 2;
      _rightZeroOffset.value = 5.2 + (math.Random().nextDouble() - 0.5) * 2;
      
      _isCalibrated.value = true;
      _clearError();
      
      AppLogger.success('✅ Kalibrasyon tamamlandı');
      
      // Kalibrasyon tamamlandığında otomatik olarak bir sonraki adıma geç
      await Future.delayed(const Duration(milliseconds: 500)); // Kısa bekleme
      proceedToWeightMeasurement();
      
      return true;
      
    } catch (e) {
      AppLogger.error('Kalibrasyon hatası', e);
      _setError('Kalibrasyon başarısız: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void proceedToWeightMeasurement() {
    if (!_isCalibrated.value) {
      _setError('Kalibrasyon gerekli');
      return;
    }
    _currentStep.value = TestStep.weightMeasurement;
    _initializeStep(TestStep.weightMeasurement); // Weight measurement'ı başlat
    update(); // GetBuilder'ı güncelle
    AppLogger.info('⚖️ Ağırlık ölçümü adımına geçildi');
  }

  // ===== STEP 5: WEIGHT MEASUREMENT =====

  void startWeightMeasurement() {
    _weightSamples.clear();
    _measuredWeight.value = null;
    _isWeightStable.value = false;
    
    _weightTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _updateWeightMeasurement();
    });
    
    AppLogger.info('⚖️ Ağırlık ölçümü başladı');
  }

  void _updateWeightMeasurement() {
    if (_currentStep.value != TestStep.weightMeasurement) {
      _weightTimer?.cancel();
      return;
    }
    
    // Mock weight measurement
    final athlete = _selectedAthlete.value;
    final targetWeight = athlete?.weight ?? 70.0;
    final mockWeight = targetWeight + (math.Random().nextDouble() - 0.5) * 4;
    
    _weightSamples.add(mockWeight);
    
    // Keep last 50 samples (5 seconds)
    if (_weightSamples.length > 50) {
      _weightSamples.removeAt(0);
    }
    
    // Calculate stability
    if (_weightSamples.length >= 20) {
      final recent = _weightSamples.sublist(_weightSamples.length - 20);
      final mean = recent.reduce((a, b) => a + b) / recent.length;
      final variance = recent.map((w) => (w - mean) * (w - mean)).reduce((a, b) => a + b) / recent.length;
      final stdDev = math.sqrt(variance);
      
      _measuredWeight.value = mean;
      _isWeightStable.value = stdDev < AppConstants.weightStabilityThreshold;
    }
  }

  /// Debug için manuel weight stability fonksiyonu - EKLENEN METOD
  void forceWeightStable() {
    final athlete = _selectedAthlete.value;
    final targetWeight = athlete?.weight ?? 70.0;
    
    _measuredWeight.value = targetWeight;
    _isWeightStable.value = true;
    _weightTimer?.cancel();
    
    AppLogger.info('🔧 Debug: Ağırlık stabilite manuel olarak sağlandı');
  }

  void proceedToTestExecution() {
    if (!_isWeightStable.value) {
      _setError('Stabil ağırlık ölçümü gerekli');
      return;
    }
    
    _weightTimer?.cancel();
    _currentStep.value = TestStep.testExecution;
    update(); // GetBuilder'ı güncelle
    AppLogger.info('🏃 Test yürütme adımına geçildi');
  }

  // ===== STEP 6: TEST EXECUTION =====

  void startTest() {
    if (!_canStartTest()) {
      _setError('Test başlatılamaz - koşullar sağlanmadı');
      return;
    }
    
    _isTestRunning.value = true;
    _testStartTime.value = DateTime.now();
    _testDuration.value = Duration.zero;
    _forceData.clear();
    _liveMetrics.clear();
    _currentPhase.value = JumpPhase.quietStanding;
    
    _startTestTimer();
    _startMockDataGeneration();
    
    AppLogger.testStart(_selectedTestType.value!.turkishName, _selectedAthlete.value!.fullName);
  }

  bool _canStartTest() {
    return _currentStep.value == TestStep.testExecution &&
           _selectedTestType.value != null &&
           _selectedAthlete.value != null &&
           _measuredWeight.value != null &&
           _isCalibrated.value &&
           !_isTestRunning.value;
  }

  void _startTestTimer() {
    _testTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isTestRunning.value) {
        timer.cancel();
        return;
      }
      
      _testDuration.value = DateTime.now().difference(_testStartTime.value!);
      
      // Auto-stop test based on type
      final maxDuration = _getMaxTestDuration();
      if (_testDuration.value >= maxDuration) {
        _stopTest();
      }
      
      // Update live metrics
      _updateLiveMetrics();
    });
  }

  Duration _getMaxTestDuration() {
    switch (_selectedTestType.value!) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        return const Duration(seconds: 10);
      case TestType.isometricMidThighPull:
        return const Duration(seconds: 8);
      case TestType.staticBalance:
        return const Duration(seconds: 30);
      default:
        return const Duration(seconds: 15);
    }
  }

  void _startMockDataGeneration() {
    if (!_isMockMode.value) return;
    
    _mockDataTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!_isTestRunning.value) {
        timer.cancel();
        return;
      }
      
      _generateMockForceData();
    });
  }

  void _generateMockForceData() {
    final elapsed = _testDuration.value.inMilliseconds / 1000.0; // seconds
    final bodyWeight = (_measuredWeight.value ?? 70.0) * 9.81; // Convert to Newtons
    
    final mockData = _generateTestSpecificData(elapsed, bodyWeight);
    _forceData.add(mockData);
    
    // Limit data size for performance
    if (_forceData.length > 5000) {
      _forceData.removeAt(0);
    }
    
    // Update phase detection
    _updatePhaseDetection(mockData);
  }

  ForceData _generateTestSpecificData(double timeSeconds, double bodyWeight) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    switch (_selectedTestType.value!) {
      case TestType.counterMovementJump:
        return _generateCMJData(timestamp, timeSeconds, bodyWeight);
      case TestType.squatJump:
        return _generateSJData(timestamp, timeSeconds, bodyWeight);
      case TestType.staticBalance:
        return _generateBalanceData(timestamp, timeSeconds, bodyWeight);
      default:
        return _generateGenericData(timestamp, timeSeconds, bodyWeight);
    }
  }

  ForceData _generateCMJData(int timestamp, double t, double bodyWeight) {
    double totalForce = bodyWeight;
    
    if (t < 1.0) {
      // Quiet standing
      totalForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 20;
    } else if (t < 2.0) {
      // Unloading phase
      final phase = (t - 1.0) / 1.0;
      totalForce = bodyWeight * (1.0 - 0.3 * phase);
      _currentPhase.value = JumpPhase.unloading;
    } else if (t < 2.5) {
      // Braking phase
      final phase = (t - 2.0) / 0.5;
      totalForce = bodyWeight * (0.7 + 1.8 * phase);
      _currentPhase.value = JumpPhase.braking;
    } else if (t < 2.8) {
      // Propulsion phase
      final phase = (t - 2.5) / 0.3;
      totalForce = bodyWeight * (2.5 - 0.5 * phase);
      _currentPhase.value = JumpPhase.propulsion;
    } else if (t < 3.2) {
      // Flight phase
      totalForce = math.Random().nextDouble() * 20;
      _currentPhase.value = JumpPhase.flight;
    } else if (t < 4.0) {
      // Landing phase
      final phase = (t - 3.2) / 0.8;
      totalForce = bodyWeight * (0.5 + 2.0 * (1 - phase));
      _currentPhase.value = JumpPhase.landing;
    } else {
      // Recovery
      totalForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 30;
      _currentPhase.value = JumpPhase.quietStanding;
    }
    
    // Add noise
    totalForce += (math.Random().nextDouble() - 0.5) * 40;
    totalForce = math.max(0, totalForce);
    
    // Simulate asymmetry (5-15%)
    final asymmetry = 0.05 + math.Random().nextDouble() * 0.10;
    final leftGRF = totalForce * (0.5 + asymmetry/2);
    final rightGRF = totalForce * (0.5 - asymmetry/2);
    
    return ForceData.create(
      timestamp: timestamp,
      leftGRF: math.max(0, leftGRF - _leftZeroOffset.value),
      rightGRF: math.max(0, rightGRF - _rightZeroOffset.value),
      leftCOP_x: (math.Random().nextDouble() - 0.5) * 100,
      leftCOP_y: (math.Random().nextDouble() - 0.5) * 150,
      rightCOP_x: (math.Random().nextDouble() - 0.5) * 100,
      rightCOP_y: (math.Random().nextDouble() - 0.5) * 150,
    );
  }

  ForceData _generateSJData(int timestamp, double t, double bodyWeight) {
    // Similar to CMJ but without unloading phase
    return _generateCMJData(timestamp, t + 1.0, bodyWeight); // Skip unloading
  }

  ForceData _generateBalanceData(int timestamp, double t, double bodyWeight) {
    final baseForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 50;
    final asymmetry = 0.02 + math.Random().nextDouble() * 0.06; // Lower asymmetry for balance
    
    return ForceData.create(
      timestamp: timestamp,
      leftGRF: baseForce * (0.5 + asymmetry/2),
      rightGRF: baseForce * (0.5 - asymmetry/2),
      leftCOP_x: math.sin(t * 2) * 30 + (math.Random().nextDouble() - 0.5) * 20,
      leftCOP_y: math.cos(t * 1.5) * 40 + (math.Random().nextDouble() - 0.5) * 25,
      rightCOP_x: math.sin(t * 2.2) * 25 + (math.Random().nextDouble() - 0.5) * 15,
      rightCOP_y: math.cos(t * 1.8) * 35 + (math.Random().nextDouble() - 0.5) * 20,
    );
  }

  ForceData _generateGenericData(int timestamp, double t, double bodyWeight) {
    final totalForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 100;
    final asymmetry = 0.05 + math.Random().nextDouble() * 0.10;
    
    return ForceData.create(
      timestamp: timestamp,
      leftGRF: totalForce * (0.5 + asymmetry/2),
      rightGRF: totalForce * (0.5 - asymmetry/2),
      leftCOP_x: (math.Random().nextDouble() - 0.5) * 80,
      leftCOP_y: (math.Random().nextDouble() - 0.5) * 120,
      rightCOP_x: (math.Random().nextDouble() - 0.5) * 80,
      rightCOP_y: (math.Random().nextDouble() - 0.5) * 120,
    );
  }

  void _updatePhaseDetection(ForceData data) {
    // Basic phase detection logic
    final totalForce = data.totalGRF;
    final bodyWeight = (_measuredWeight.value ?? 70.0) * 9.81;
    
    if (totalForce < bodyWeight * 0.1) {
      _currentPhase.value = JumpPhase.flight;
    } else if (totalForce > bodyWeight * 1.5) {
      if (_currentPhase.value == JumpPhase.unloading) {
        _currentPhase.value = JumpPhase.braking;
      } else if (_currentPhase.value == JumpPhase.braking) {
        _currentPhase.value = JumpPhase.propulsion;
      } else {
        _currentPhase.value = JumpPhase.landing;
      }
    }
  }

  void _updateLiveMetrics() {
    if (_forceData.isEmpty) return;
    
    final recentData = _forceData.length > 100 
        ? _forceData.sublist(_forceData.length - 100)
        : _forceData.toList();
    
    final collection = ForceDataCollection(recentData);
    
    _liveMetrics.value = {
      'peakForce': collection.peakTotalGRF.toDouble(),
      'averageForce': collection.avgTotalGRF.toDouble(),
      'asymmetryIndex': collection.overallAsymmetry.toDouble(),
      'sampleCount': _forceData.length.toDouble(),
      'currentForce': _forceData.last.totalGRF.toDouble(),
    };
  }

  void stopTest() {
    if (!_isTestRunning.value) return;
    
    AppLogger.info('🛑 Test manuel olarak durduruldu');
    _stopTest();
  }

  void _stopTest() {
    _isTestRunning.value = false;
    _cancelAllTimers();
    
    final duration = _testDuration.value;
    AppLogger.testComplete(
      _selectedTestType.value!.turkishName, 
      _selectedAthlete.value!.fullName, 
      duration
    );
    
    _processTestResults();
  }

  // ===== STEP 7: RESULTS PROCESSING =====

  Future<void> _processTestResults() async {
    _isProcessingResults.value = true;
    
    try {
      AppLogger.info('📊 Test sonuçları işleniyor...');
      
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      final metrics = await _calculateMetrics();
      
      final result = TestResult.create(
        sessionId: 'session_${_testStartTime.value!.millisecondsSinceEpoch}',
        athleteId: _selectedAthlete.value!.id,
        testType: _selectedTestType.value!,
        duration: _testDuration.value,
        metrics: metrics,
        metadata: {
          'sampleCount': _forceData.length,
          'sampleRate': _calculateSampleRate(),
          'bodyWeight': (_measuredWeight.value ?? 0.0).toDouble(),
          'leftZeroOffset': _leftZeroOffset.value.toDouble(),
          'rightZeroOffset': _rightZeroOffset.value.toDouble(),
        },
      );
      
      _testResults.value = result;
      
      // Save to database
      await _saveTestResult(result);
      
      _currentStep.value = TestStep.results;
      update(); // GetBuilder'ı güncelle
      AppLogger.success('✅ Test sonuçları hazır');
      
    } catch (e) {
      AppLogger.error('Test sonuç işleme hatası', e);
      _setError('Sonuç işleme hatası: $e');
    } finally {
      _isProcessingResults.value = false;
    }
  }

  Future<Map<String, double>> _calculateMetrics() async {
    if (_forceData.isEmpty) return {};
    
    final collection = ForceDataCollection(_forceData.toList());
    final bodyWeight = (_measuredWeight.value ?? 70.0) * 9.81;
    
    // Basic metrics calculation
    final metrics = <String, double>{
      'peakForce': collection.peakTotalGRF,
      'averageForce': collection.avgTotalGRF,
      'asymmetryIndex': collection.overallAsymmetry,
      'testDuration': _testDuration.value.inMilliseconds.toDouble(),
      'sampleCount': _forceData.length.toDouble(),
    };
    
    // Test-specific metrics
    switch (_selectedTestType.value!) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        metrics.addAll(await _calculateJumpMetrics(collection, bodyWeight));
        break;
      case TestType.staticBalance:
        metrics.addAll(await _calculateBalanceMetrics(collection));
        break;
      default:
        break;
    }
    
    AppLogger.metricsCalculated(_selectedTestType.value!.turkishName, metrics.length);
    return metrics;
  }

  Future<Map<String, double>> _calculateJumpMetrics(ForceDataCollection collection, double bodyWeight) async {
    // Simplified jump metrics calculation
    final peakForce = collection.peakTotalGRF;
    final avgForce = collection.avgTotalGRF;
    
    // Estimate jump height using simplified formula
    final forceAboveBodyweight = math.max(0, peakForce - bodyWeight);
    final jumpHeight = (forceAboveBodyweight / bodyWeight) * 20; // Simplified estimation
    
    // Estimate flight time
    final flightTime = math.sqrt(2 * jumpHeight / 100) * 1000; // Convert to ms
    
    return {
      'jumpHeight': jumpHeight,
      'flightTime': flightTime,
      
      'relativeForce': peakForce / bodyWeight,
      'impulse': avgForce * _testDuration.value.inMilliseconds,
      'rfd': forceAboveBodyweight / (_testDuration.value.inMilliseconds / 1000), // Simplified RFD
    };
  }

  Future<Map<String, double>> _calculateBalanceMetrics(ForceDataCollection collection) async {
    final data = collection.data;
    if (data.isEmpty) return {};
    
    // Calculate COP metrics
    final copDisplacements = data
        .map((d) => d.copDisplacement ?? 0.0)
        .toList();
    
    final copRange = copDisplacements.isNotEmpty 
        ? copDisplacements.reduce(math.max) - copDisplacements.reduce(math.min)
        : 0.0;
    
    final copAvg = copDisplacements.isNotEmpty
        ? copDisplacements.reduce((a, b) => a + b) / copDisplacements.length
        : 0.0;
    
    return {
      'copRange': copRange,
      'copAverage': copAvg,
      'copArea': copRange * copRange, // Simplified area calculation
      'stabilityIndex': 100 - (copRange * 2), // Higher is better
    };
  }

  double _calculateSampleRate() {
    if (_forceData.length < 2) return 0.0;
    final durationMs = _forceData.last.timestamp - _forceData.first.timestamp;
    return (_forceData.length - 1) * 1000.0 / durationMs;
  }

  Future<void> _saveTestResult(TestResult result) async {
    try {
      final db = DatabaseHelper.instance;
      
      // Save test session
      await db.insertTestSession({
        'id': result.sessionId,
        'athleteId': result.athleteId,
        'testType': result.testType.name,
        'testDate': result.testDate.toIso8601String(),
        'duration': result.duration.inMilliseconds,
        'status': result.status.name,
        'notes': result.notes,
        'createdAt': result.createdAt.toIso8601String(),
      });
      
      // Save force data (sample for performance)
      final sampledData = _forceData.length > 1000 
          ? ForceDataCollection(_forceData.toList()).downsample(10).data
          : _forceData.toList();
      
      await db.insertForceDataBatch(
        result.sessionId,
        sampledData.map((d) => d.toMap()).toList(),
      );
      
      // Save metrics
      await db.insertTestResultsBatch(result.sessionId, result.metrics);
      
      AppLogger.success('💾 Test sonuçları kaydedildi');
      
    } catch (e) {
      AppLogger.dbError('saveTestResult', e.toString());
      // Don't throw - results are still available in memory
    }
  }

  // ===== NAVIGATION =====

  void goToPreviousStep() {
    final currentIndex = TestStep.values.indexOf(_currentStep.value);
    if (currentIndex > 0) {
      _cancelAllTimers();
      final previousStep = TestStep.values[currentIndex - 1];
      _currentStep.value = previousStep;
      
      // Önceki adıma giderken state'i reset et
      _resetStepState(previousStep);
      
      AppLogger.info('⬅️ Önceki adıma geçildi: ${previousStep.turkishName}');
    }
  }

  void _resetStepState(TestStep step) {
    _clearError();
    
    switch (step) {
      case TestStep.calibration:
        // Kalibrasyon adımına geri dönüldüğünde state'i sıfırla
        _isCalibrated.value = false;
        _calibrationProgress.value = 0.0;
        _leftZeroOffset.value = 0.0;
        _rightZeroOffset.value = 0.0;
        break;
      case TestStep.weightMeasurement:
        // Ağırlık ölçümü adımına geri dönüldüğünde state'i sıfırla
        _measuredWeight.value = null;
        _isWeightStable.value = false;
        _weightSamples.clear();
        break;
      case TestStep.testExecution:
        // Test yürütme adımına geri dönüldüğünde state'i sıfırla
        _isTestRunning.value = false;
        _testResults.value = null;
        _forceData.clear();
        _liveMetrics.clear();
        _currentPhase.value = JumpPhase.quietStanding;
        break;
      default:
        break;
    }
  }

  void goToStep(TestStep step) {
    _cancelAllTimers();
    _currentStep.value = step;
    _initializeStep(step);
    AppLogger.info('➡️ Adıma geçildi: ${step.turkishName}');
  }

  void _initializeStep(TestStep step) {
    _clearError();
    
    switch (step) {
      case TestStep.weightMeasurement:
        // Ağırlık ölçümü adımında otomatik olarak ölçümü başlat
        startWeightMeasurement();
        break;
      case TestStep.calibration:
        // Kalibrasyon adımında state'i hazırla ama otomatik başlatma
        _isCalibrated.value = false;
        _calibrationProgress.value = 0.0;
        break;
      case TestStep.testExecution:
        // Test yürütme adımında state'i hazırla
        _isTestRunning.value = false;
        _testResults.value = null;
        _forceData.clear();
        _liveMetrics.clear();
        break;
      default:
        break;
    }
  }

  void restartTestFlow() {
    _resetTestFlow();
    _currentStep.value = TestStep.deviceConnection;
    update(); // GetBuilder'ı güncelle
    AppLogger.info('🔄 Test akışı yeniden başlatıldı');
  }

  void _resetTestFlow() {
    _cancelAllTimers();
    
    // Reset all state except connection and athlete/test selection
    _isCalibrated.value = false;
    _measuredWeight.value = null;
    _isWeightStable.value = false;
    _isTestRunning.value = false;
    _testResults.value = null;
    _forceData.clear();
    _liveMetrics.clear();
    _currentPhase.value = JumpPhase.quietStanding;
    
    _clearError();
  }

  // ===== UTILITY METHODS =====

  void _cancelAllTimers() {
    _testTimer?.cancel();
    _mockDataTimer?.cancel();
    _weightTimer?.cancel();
  }

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String message) {
    _errorMessage.value = message;
    AppLogger.error('🚫 Controller Error: $message');
  }

  void _clearError() {
    _errorMessage.value = null;
  }
}

/// Test akış adımları
enum TestStep {
  deviceConnection('Device Connection', 'Cihaz Bağlantısı'),
  athleteSelection('Athlete Selection', 'Sporcu Seçimi'),
  testSelection('Test Selection', 'Test Seçimi'),
  calibration('Calibration', 'Kalibrasyon'),
  weightMeasurement('Weight Measurement', 'Ağırlık Ölçümü'),
  testExecution('Test Execution', 'Test Uygulama'),
  results('Results', 'Sonuçlar');

  const TestStep(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}
