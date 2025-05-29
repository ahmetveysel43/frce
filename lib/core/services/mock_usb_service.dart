// lib/data/services/mock_usb_service.dart
import 'dart:async';
import 'dart:math' as math;
import '../../domain/entities/force_data.dart';

class MockUsbService {
  StreamController<ForceData>? _forceDataController;
  Timer? _dataTimer;
  bool _isConnected = false;
  int _sampleIndex = 0;
  
  bool get isConnected => _isConnected;
  Stream<ForceData>? get forceDataStream => _forceDataController?.stream;

  Future<bool> initialize() async {
    _forceDataController = StreamController<ForceData>.broadcast();
    return true;
  }

  Future<List<String>> getAvailableDevices() async {
    return [
      'IzForce Platform 001',
      'IzForce Platform 002', 
      'Mock Force Platform'
    ];
  }

  Future<bool> connectToDevice(String deviceId) async {
    await Future.delayed(const Duration(seconds: 1));
    _isConnected = true;
    _startMockDataGeneration();
    return true;
  }

  void _startMockDataGeneration() {
    _dataTimer = Timer.periodic(
      const Duration(milliseconds: 1), // 1000Hz için 1ms
      (timer) => _generateMockForceData(),
    );
  }

  void _generateMockForceData() {
    final now = DateTime.now();
    final time = _sampleIndex / 1000.0;
    
    // Realistic simulation
    final baseForce = 700.0 + 20 * math.sin(time * 2 * math.pi * 0.1);
    
    final leftForces = List.generate(4, (i) => baseForce / 8 + i * 2);
    final rightForces = List.generate(4, (i) => baseForce / 8 + i * 2);
    
    final forceData = ForceData(
      timestamp: now,
      leftPlateForces: leftForces,
      rightPlateForces: rightForces,
      samplingRate: 1000.0,
      sampleIndex: _sampleIndex,
    );
    
    _forceDataController?.add(forceData);
    _sampleIndex++;
  }

  Future<void> disconnect() async {
    _dataTimer?.cancel();
    _isConnected = false;
    _sampleIndex = 0;
  }

  void dispose() {
    disconnect();
    _forceDataController?.close();
  }
}