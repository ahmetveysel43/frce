// lib/presentation/controllers/usb_controller.dart - Constructor düzeltmesi
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../domain/entities/force_data.dart';
import '../../core/enums/usb_connection_state.dart';

class UsbController extends ChangeNotifier {
  // ✅ Constructor'ı basitleştir - repository dependency'sini kaldır
  UsbController();

  // State
  UsbConnectionState _connectionState = UsbConnectionState.disconnected;
  List<String> _availableDevices = [];
  String? _connectedDeviceId;
  String? _errorMessage;
  ForceData? _latestForceData;
  bool _isConnected = false;
  
  // Mock service
  Timer? _mockTimer;
  int _sampleIndex = 0;
  
  // Getters
  UsbConnectionState get connectionState => _connectionState;
  List<String> get availableDevices => _availableDevices;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get errorMessage => _errorMessage;
  ForceData? get latestForceData => _latestForceData;
  bool get isConnected => _isConnected;

  // Initialize USB system
  Future<bool> initializeUsb() async {
    try {
      _setConnectionState(UsbConnectionState.disconnected);
      return true;
    } catch (e) {
      _setError('USB initialization error: $e');
      return false;
    }
  }

  // Connect to device (Mock implementation)
  Future<bool> connectToDevice(String deviceId) async {
    try {
      _setConnectionState(UsbConnectionState.connecting);
      
      // Mock connection delay
      await Future.delayed(const Duration(seconds: 1));
      
      _connectedDeviceId = deviceId;
      _isConnected = true;
      _setConnectionState(UsbConnectionState.connected);
      _startMockDataGeneration();
      
      return true;
    } catch (e) {
      _setError('Connection error: $e');
      return false;
    }
  }

  void _startMockDataGeneration() {
    _mockTimer = Timer.periodic(
      const Duration(milliseconds: 10), // 100Hz için demo (1000Hz çok hızlı UI için)
      (timer) => _generateMockForceData(),
    );
  }

  void _generateMockForceData() {
    final now = DateTime.now();
    final time = _sampleIndex / 100.0; // 100Hz
    
    // Realistic simulation
    final baseForce = 700.0 + 20 * math.sin(time * 2 * math.pi * 0.1);
    
    final leftForces = List.generate(4, (i) => baseForce / 8 + i * 2);
    final rightForces = List.generate(4, (i) => baseForce / 8 + i * 2);
    
    _latestForceData = ForceData(
      timestamp: now,
      leftPlateForces: leftForces,
      rightPlateForces: rightForces,
      samplingRate: 1000.0,
      sampleIndex: _sampleIndex,
    );
    
    _sampleIndex++;
    notifyListeners();
  }

  // Disconnect
  Future<bool> disconnect() async {
    try {
      _mockTimer?.cancel();
      _connectedDeviceId = null;
      _latestForceData = null;
      _isConnected = false;
      _sampleIndex = 0;
      _setConnectionState(UsbConnectionState.disconnected);
      return true;
    } catch (e) {
      _setError('Disconnect error: $e');
      return false;
    }
  }

  // Helper methods
  void _setConnectionState(UsbConnectionState state) {
    _connectionState = state;
    if (state != UsbConnectionState.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _connectionState = UsbConnectionState.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    super.dispose();
  }
}