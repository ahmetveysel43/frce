// lib/presentation/controllers/test_controller.dart - Tamamen Düzeltilmiş
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../domain/entities/force_data.dart';
import '../../domain/usecases/calculate_metrics_usecase.dart';
import '../../domain/value_objects/test_parameters.dart';
import '../../core/constants/test_constants.dart';

enum TestState {
  idle,
  preparing,
  running,
  completed,
  failed,
  cancelled,
}

class TestController extends ChangeNotifier {
  final CalculateMetricsUseCase _calculateMetricsUseCase;

  TestController(this._calculateMetricsUseCase);

  // State
  TestState _state = TestState.idle;
  String? _currentTestId;
  String? _currentAthleteId;
  TestType? _currentTestType;
  TestParameters? _currentParameters;
  final List<ForceData> _currentData = [];
  Map<String, double> _currentMetrics = {};
  String? _errorMessage;
  double? _testProgress;
  Duration _elapsedTime = Duration.zero;
  
  // Mock timer for simulation
  Timer? _testTimer;
  Timer? _dataTimer;

  // Getters
  TestState get state => _state;
  String? get currentTestId => _currentTestId;
  String? get currentAthleteId => _currentAthleteId;
  TestType? get currentTestType => _currentTestType;
  TestParameters? get currentParameters => _currentParameters;
  List<ForceData> get currentData => _currentData;
  Map<String, double> get currentMetrics => _currentMetrics;
  String? get errorMessage => _errorMessage;
  double? get testProgress => _testProgress;
  Duration get elapsedTime => _elapsedTime;
  
  // State checks
  bool get isIdle => _state == TestState.idle;
  bool get isPreparing => _state == TestState.preparing;
  bool get isRunning => _state == TestState.running;
  bool get isCompleted => _state == TestState.completed;
  bool get hasFailed => _state == TestState.failed;
  bool get isCancelled => _state == TestState.cancelled;
  bool get canStartTest => _state == TestState.idle;
  bool get canStopTest => _state == TestState.running;
  
  // Test name
  String get currentTestName => 
      _currentTestType != null ? TestConstants.testNames[_currentTestType!] ?? '' : '';

  // Real-time metrics
  double get currentTotalForce => 
      _currentData.isEmpty ? 0.0 : _currentData.last.totalGRF;
  
  // ✅ FIXED: Use asymmetryIndex instead of forceSymmetryIndex
  double get currentAsymmetry => 
      _currentData.isEmpty ? 0.0 : _currentData.last.asymmetryIndex;

  // Start test (mock implementation)
  Future<bool> startTest({
    required String athleteId,
    required TestType testType,
    TestParameters? customParameters,
    String? notes,
  }) async {
    if (!canStartTest) return false;

    _setState(TestState.preparing);
    _currentAthleteId = athleteId;
    _currentTestType = testType;
    _currentParameters = customParameters ?? TestParameters.defaultForTest(testType);
    _currentData.clear();
    _currentMetrics.clear();
    _elapsedTime = Duration.zero;
    _currentTestId = 'test_${DateTime.now().millisecondsSinceEpoch}';

    // Mock preparation delay
    await Future.delayed(const Duration(seconds: 2));

    _startMockDataGeneration();
    _startTimer();
    _setState(TestState.running);
    
    return true;
  }

  // Stop test
  Future<bool> stopTest() async {
    if (!canStopTest) return false;

    _stopMockDataGeneration();
    _stopTimer();

    await _calculateFinalMetrics();
    _setState(TestState.completed);
    
    return true;
  }

  // Cancel test
  Future<bool> cancelTest() async {
    if (_currentTestId == null) return false;

    _stopMockDataGeneration();
    _stopTimer();
    _setState(TestState.cancelled);
    
    return true;
  }

  // Reset test
  void resetTest() {
    _stopMockDataGeneration();
    _stopTimer();
    
    _state = TestState.idle;
    _currentTestId = null;
    _currentAthleteId = null;
    _currentTestType = null;
    _currentParameters = null;
    _currentData.clear();
    _currentMetrics.clear();
    _errorMessage = null;
    _testProgress = null;
    _elapsedTime = Duration.zero;
    
    notifyListeners();
  }

  // Mock data generation
  void _startMockDataGeneration() {
    _dataTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_state != TestState.running) {
        timer.cancel();
        return;
      }

      // Generate mock force data
      final now = DateTime.now();
      final sampleIndex = _currentData.length;
      
      // Simple mock force simulation
      const baseForce = 700.0; // ~70kg body weight
      final time = sampleIndex / 1000.0; // seconds
      final phase = (time * 2 * math.pi * 0.5) % (2 * math.pi);
      
      double totalForce = baseForce;
      if (phase < math.pi) {
        totalForce = baseForce * (1 - 0.3 * (phase / math.pi));
      } else {
        totalForce = baseForce * (1 + 0.8 * ((phase - math.pi) / math.pi));
      }

      // Calculate left and right forces
      final leftForce = totalForce * 0.48; // Slight asymmetry
      final rightForce = totalForce * 0.52;
      
      // Calculate Center of Pressure (mock)
      final leftCoPX = math.sin(time * 2) * 5; // ±5mm oscillation
      final leftCoPY = math.cos(time * 1.5) * 8; // ±8mm oscillation
      final rightCoPX = math.sin(time * 1.8) * 6;
      final rightCoPY = math.cos(time * 2.2) * 7;
      
      // Calculate metrics
      final asymmetryIndex = (leftForce - rightForce).abs() / totalForce;
      final stabilityIndex = 0.8 + math.sin(time) * 0.15; // 0.65-0.95 range
      final loadRate = (totalForce - baseForce) * 10; // Mock load rate
      
      // Mock load cell forces (4 per platform)
      final leftDeckForces = List.generate(4, (i) => leftForce / 4 + (i * 2));
      final rightDeckForces = List.generate(4, (i) => rightForce / 4 + (i * 2));
      
      // ✅ FIXED: ForceData constructor with ALL required parameters
      final forceData = ForceData(
        timestamp: now,
        
        // Required parameters
        leftGRF: leftForce,
        leftCoPX: leftCoPX,
        leftCoPY: leftCoPY,
        rightGRF: rightForce,
        rightCoPX: rightCoPX,
        rightCoPY: rightCoPY,
        totalGRF: totalForce,
        asymmetryIndex: asymmetryIndex,
        stabilityIndex: stabilityIndex,
        loadRate: loadRate,
        
        // Optional parameters
        leftDeckForces: leftDeckForces,
        rightDeckForces: rightDeckForces,
        samplingRate: 1000.0,
        sampleIndex: sampleIndex,
      );
      
      _currentData.add(forceData);
      
      // Update progress
      if (_currentParameters != null) {
        final totalSamples = _currentParameters!.totalSamples;
        _testProgress = _currentData.length / totalSamples;
        
        // Auto stop when complete
        if (_testProgress! >= 1.0) {
          stopTest();
        }
      }
      
      notifyListeners();
    });
  }

  void _stopMockDataGeneration() {
    _dataTimer?.cancel();
    _dataTimer = null;
  }

  void _startTimer() {
    _testTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_state != TestState.running) {
        timer.cancel();
        return;
      }
      
      _elapsedTime = Duration(milliseconds: _elapsedTime.inMilliseconds + 100);
      
      // Auto-stop test if duration exceeded
      if (_currentParameters != null && 
          _elapsedTime >= _currentParameters!.duration) {
        stopTest();
      }
      
      notifyListeners();
    });
  }

  void _stopTimer() {
    _testTimer?.cancel();
    _testTimer = null;
  }

  Future<void> _calculateFinalMetrics() async {
    if (_currentData.isEmpty || _currentTestType == null) return;

    final result = await _calculateMetricsUseCase.calculateMetrics(
      _currentData,
      _currentTestType!,
    );

    result.fold(
      (failure) => debugPrint('Metric calculation error: ${failure.message}'),
      (metrics) {
        _currentMetrics = metrics;
      },
    );
  }

  void _setState(TestState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopMockDataGeneration();
    _stopTimer();
    super.dispose();
  }
}