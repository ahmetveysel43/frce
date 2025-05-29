// lib/presentation/controllers/usb_controller.dart - VALD ForceDecks Optimized
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../domain/entities/force_data.dart';
import '../../core/enums/usb_connection_state.dart';

/// VALD ForceDecks benzeri dual force platform controller
/// 
/// Özellikler:
/// - Dual force platform simulation (Left + Right Deck)
/// - 8 load cell simulation (4+4)
/// - Real-time bilateral analysis
/// - VALD standardı metrics
/// - Asymmetry detection
class UsbController extends ChangeNotifier {
  // State
  UsbConnectionState _connectionState = UsbConnectionState.disconnected;
  List<String> _availableDevices = [
    'VALD ForceDecks Mini',
    'VALD ForceDecks Lite', 
    'VALD ForceDecks Max',
    'IzForce Platform Pro'
  ];
  String? _connectedDeviceId;
  String? _errorMessage;
  ForceData? _latestForceData;
  bool _isConnected = false;
  bool _disposed = false;
  
  // ✅ VALD ForceDecks simulation parameters
  Timer? _mockTimer;
  int _sampleIndex = 0;
  double _simulatedBodyWeight = 70.0; // kg
  double _simulatedAsymmetry = 5.0; // %
  String _currentTestScenario = 'quiet_standing';
  
  // ✅ Real-time metrics tracking
  final List<ForceData> _recentData = [];
  static const int maxRecentDataSize = 1000; // 1 saniye veri (1000Hz)
  
  // Getters
  UsbConnectionState get connectionState => _connectionState;
  List<String> get availableDevices => _availableDevices;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get errorMessage => _errorMessage;
  ForceData? get latestForceData => _latestForceData;
  bool get isConnected => _isConnected;
  List<ForceData> get recentData => List.unmodifiable(_recentData);
  
  // ✅ VALD ForceDecks specific getters
  double get simulatedBodyWeight => _simulatedBodyWeight;
  double get simulatedAsymmetry => _simulatedAsymmetry;
  String get currentTestScenario => _currentTestScenario;
  
  /// Current Force Symmetry Index (VALD standardı)
  double get currentSymmetryIndex => _latestForceData?.forceSymmetryIndex ?? 0.0;
  
  /// Is within VALD normal range (≤15% asymmetry)
  bool get isWithinNormalRange => currentSymmetryIndex <= 15.0;
  
  /// Real-time CoP sway
  double get currentCoPSway => _latestForceData?.medialLateralSway ?? 0.0;
  
  /// Average metrics from recent data (son 1 saniye)
  Map<String, double> get recentMetrics {
    if (_recentData.isEmpty) return {};
    
    final validData = _recentData.where((data) => data.isValidData).toList();
    if (validData.isEmpty) return {};
    
    return {
      'avgTotalForce': validData.map((d) => d.totalGRF).reduce((a, b) => a + b) / validData.length,
      'avgSymmetryIndex': validData.map((d) => d.forceSymmetryIndex).reduce((a, b) => a + b) / validData.length,
      'avgLeftForce': validData.map((d) => d.leftDeckTotal).reduce((a, b) => a + b) / validData.length,
      'avgRightForce': validData.map((d) => d.rightDeckTotal).reduce((a, b) => a + b) / validData.length,
      'avgCoPSway': validData.map((d) => d.medialLateralSway).reduce((a, b) => a + b) / validData.length,
      'dataQuality': validData.map((d) => d.dataQuality).reduce((a, b) => a + b) / validData.length,
    };
  }

  // Initialize USB system
  Future<bool> initializeUsb() async {
    if (_disposed) return false;
    
    try {
      print('🔧 VALD ForceDecks Controller: Initializing dual platform system...');
      _setConnectionState(UsbConnectionState.disconnected);
      return true;
    } catch (e) {
      _setError('VALD ForceDecks initialization error: $e');
      return false;
    }
  }

  // Connect to VALD ForceDecks device
  Future<bool> connectToDevice(String deviceId) async {
    if (_disposed) return false;
    
    try {
      print('🔗 VALD ForceDecks: Connecting to $deviceId...');
      _setConnectionState(UsbConnectionState.connecting);
      
      // Simulate device-specific connection
      await Future.delayed(const Duration(seconds: 2));
      
      if (_disposed) return false;
      
      _connectedDeviceId = deviceId;
      _isConnected = true;
      _setConnectionState(UsbConnectionState.connected);
      
      // ✅ Device-specific setup
      _setupDeviceParameters(deviceId);
      _startVALDDataGeneration();
      
      print('✅ VALD ForceDecks: Connected successfully to $deviceId');
      print('   - Dual Platform: Left + Right Deck');
      print('   - Load Cells: 8 (4+4)');
      print('   - Sampling Rate: 1000Hz');
      print('   - Body Weight: ${_simulatedBodyWeight}kg');
      
      return true;
    } catch (e) {
      _setError('VALD ForceDecks connection error: $e');
      return false;
    }
  }
  
  void _setupDeviceParameters(String deviceId) {
    // Device-specific parameters
    switch (deviceId) {
      case 'VALD ForceDecks Mini':
        _simulatedBodyWeight = 65.0; // Lighter user simulation
        _simulatedAsymmetry = 3.0;
        break;
      case 'VALD ForceDecks Lite':
        _simulatedBodyWeight = 75.0;
        _simulatedAsymmetry = 7.0;
        break;
      case 'VALD ForceDecks Max':
        _simulatedBodyWeight = 85.0;
        _simulatedAsymmetry = 4.0;
        break;
      default:
        _simulatedBodyWeight = 70.0;
        _simulatedAsymmetry = 5.0;
    }
  }

  // ✅ VALD ForceDecks data generation
  void _startVALDDataGeneration() {
    if (_disposed || !_isConnected) return;
    
    print('📊 VALD ForceDecks: Starting dual platform data stream (1000Hz)...');
    
    _mockTimer?.cancel();
    
    // 1000Hz simulation (her 1ms)
    _mockTimer = Timer.periodic(
      const Duration(milliseconds: 1),
      (timer) {
        if (_disposed || !_isConnected) {
          timer.cancel();
          return;
        }
        _generateVALDForceData();
      },
    );
  }

  void _generateVALDForceData() {
    if (_disposed || !_isConnected) return;
    
    final now = DateTime.now();
    final time = _sampleIndex / 1000.0; // seconds
    
    // ✅ Test scenario-based simulation
    ForceData forceData;
    
    switch (_currentTestScenario) {
      case 'quiet_standing':
        forceData = _generateQuietStandingData(now, time);
        break;
      case 'countermovement_jump':
        forceData = _generateCMJData(now, time);
        break;
      case 'balance_test':
        forceData = _generateBalanceTestData(now, time);
        break;
      case 'isometric_test':
        forceData = _generateIsometricTestData(now, time);
        break;
      default:
        forceData = _generateQuietStandingData(now, time);
    }
    
    _latestForceData = forceData;
    
    // ✅ Recent data tracking
    _recentData.add(forceData);
    if (_recentData.length > maxRecentDataSize) {
      _recentData.removeAt(0);
    }
    
    _sampleIndex++;
    
    if (!_disposed && _isConnected) {
      notifyListeners();
    }
  }
  
  ForceData _generateQuietStandingData(DateTime timestamp, double time) {
    // Quiet standing: minimal sway, stable force
    final baseWeight = _simulatedBodyWeight * 9.81; // Convert to Newtons
    final sway = 15.0 * math.sin(time * 2 * math.pi * 0.1); // Slow sway
    final noise = (math.Random().nextDouble() - 0.5) * 5; // Small noise
    
    return ForceData.mockVALDForceDecks(
      timestamp: timestamp,
      bodyWeight: (baseWeight + sway + noise) / 9.81,
      asymmetryPercent: _simulatedAsymmetry,
      sampleIndex: _sampleIndex,
    );
  }
  
  ForceData _generateCMJData(DateTime timestamp, double time) {
    // CMJ phases: loading -> unloading -> flight -> landing
    final phase = (time * 2) % 4; // 4 saniye cycle
    double forceMultiplier;
    
    if (phase < 1) {
      // Loading phase: force decreases
      forceMultiplier = 1.0 - (phase * 0.3);
    } else if (phase < 2) {
      // Propulsion phase: force increases dramatically
      forceMultiplier = 0.7 + ((phase - 1) * 2.5);
    } else if (phase < 3) {
      // Flight phase: minimal force
      forceMultiplier = 0.1;
    } else {
      // Landing phase: high impact force
      forceMultiplier = 1.0 + ((phase - 3) * 1.5);
    }
    
    return ForceData.mockJump(
      timestamp: timestamp,
      bodyWeight: _simulatedBodyWeight,
      jumpForceMultiplier: forceMultiplier,
      sampleIndex: _sampleIndex,
    );
  }
  
  ForceData _generateBalanceTestData(DateTime timestamp, double time) {
    // Balance test: increased sway and variability
    final swayX = 25.0 * math.sin(time * 2 * math.pi * 0.3);
    final swayY = 20.0 * math.cos(time * 2 * math.pi * 0.2);
    final totalSway = math.sqrt(swayX * swayX + swayY * swayY);
    
    return ForceData.mockVALDForceDecks(
      timestamp: timestamp,
      bodyWeight: _simulatedBodyWeight + (totalSway / 10),
      asymmetryPercent: _simulatedAsymmetry + (totalSway / 5),
      sampleIndex: _sampleIndex,
    );
  }
  
  ForceData _generateIsometricTestData(DateTime timestamp, double time) {
    // Isometric test: high, sustained force
    final effort = math.sin(time * 2 * math.pi * 0.05).abs(); // Slow variation
    final forceMultiplier = 1.5 + effort; // 1.5-2.5x body weight
    
    return ForceData.mockVALDForceDecks(
      timestamp: timestamp,
      bodyWeight: _simulatedBodyWeight * forceMultiplier,
      asymmetryPercent: _simulatedAsymmetry,
      sampleIndex: _sampleIndex,
    );
  }

  // ✅ VALD ForceDecks specific controls
  
  /// Test scenario değiştir
  void setTestScenario(String scenario) {
    if (_currentTestScenario != scenario) {
      _currentTestScenario = scenario;
      print('🎯 VALD ForceDecks: Test scenario changed to $_currentTestScenario');
      
      if (!_disposed) {
        notifyListeners();
      }
    }
  }
  
  /// Simulated body weight ayarla
  void setSimulatedBodyWeight(double weightKg) {
    if (_simulatedBodyWeight != weightKg) {
      _simulatedBodyWeight = weightKg;
      print('⚖️ VALD ForceDecks: Body weight set to ${weightKg}kg');
      
      if (!_disposed) {
        notifyListeners();
      }
    }
  }
  
  /// Simulated asymmetry ayarla
  void setSimulatedAsymmetry(double asymmetryPercent) {
    if (_simulatedAsymmetry != asymmetryPercent) {
      _simulatedAsymmetry = asymmetryPercent;
      print('⚖️ VALD ForceDecks: Asymmetry set to ${asymmetryPercent}%');
      
      if (!_disposed) {
        notifyListeners();
      }
    }
  }
  
  /// Zero/tare the platforms
  void zeroPlatforms() {
    _recentData.clear();
    _sampleIndex = 0;
    print('🔄 VALD ForceDecks: Platforms zeroed');
    
    if (!_disposed) {
      notifyListeners();
    }
  }
  
  /// Get platform calibration status
  Map<String, bool> get platformCalibrationStatus {
    return {
      'leftDeck': _isConnected,
      'rightDeck': _isConnected,
      'loadCells': _isConnected,
      'synchronization': _isConnected,
    };
  }

  // Disconnect
  Future<bool> disconnect() async {
    if (_disposed) return true;
    
    try {
      print('🔌 VALD ForceDecks: Disconnecting dual platform system...');
      
      _mockTimer?.cancel();
      _mockTimer = null;
      
      _connectedDeviceId = null;
      _latestForceData = null;
      _isConnected = false;
      _sampleIndex = 0;
      _recentData.clear();
      
      _setConnectionState(UsbConnectionState.disconnected);
      
      print('✅ VALD ForceDecks: Disconnected successfully');
      return true;
    } catch (e) {
      _setError('VALD ForceDecks disconnect error: $e');
      return false;
    }
  }

  // Helper methods
  void _setConnectionState(UsbConnectionState state) {
    if (_disposed) return;
    
    _connectionState = state;
    if (state != UsbConnectionState.error) {
      _errorMessage = null;
    }
    
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _setError(String message) {
    if (_disposed) return;
    
    print('❌ VALD ForceDecks Error: $message');
    _connectionState = UsbConnectionState.error;
    _errorMessage = message;
    
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    print('🗑️ VALD ForceDecks Controller: Disposing dual platform system...');
    _disposed = true;
    
    // Cancel timers
    _mockTimer?.cancel();
    _mockTimer = null;
    
    // Clear data
    _recentData.clear();
    _isConnected = false;
    _connectedDeviceId = null;
    _latestForceData = null;
    
    super.dispose();
  }
}