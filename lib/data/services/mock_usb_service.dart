// lib/core/services/mock_usb_service.dart - DÜZELTİLMİŞ VERSİYON
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../domain/entities/force_data.dart';

class MockUsbService {
  Timer? _timer;
  StreamController<ForceData>? _streamController;
  bool _isConnected = false;
  String? _connectedDevice;
  String _currentScenario = 'sakin_durus';
  
  // ✅ Public getter for stream
  Stream<ForceData>? get forceDataStream => _streamController?.stream;
  
  // Device simulation
  final List<String> _mockDevices = [
    'IzForce Platform Pro - USB001',
    'IzForce Platform Lite - USB002',
    'Mock IzForce Device - TEST001',
  ];

  Future<void> initialize() async {
    debugPrint('🔌 Mock USB Service initialized');
  }

  Future<List<String>> getAvailableDevices() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate scan
    debugPrint('📱 Mock devices found: ${_mockDevices.length}');
    return _mockDevices;
  }

  Future<bool> connectToDevice(String deviceId) async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate connection
      
      _isConnected = true;
      _connectedDevice = deviceId;
      _streamController = StreamController<ForceData>.broadcast();
      
      _startDataGeneration();
      
      debugPrint('✅ Mock device connected: $deviceId');
      return true;
    } catch (e) {
      debugPrint('❌ Mock connection failed: $e');
      return false;
    }
  }

  void _startDataGeneration() {
    if (_timer?.isActive == true) {
      _timer!.cancel();
    }

    // ✅ UI performansı için veri hızını yavaşlat (50 Hz = 20ms)
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!_isConnected || _streamController?.isClosed == true) {
        timer.cancel();
        return;
      }

      final forceData = _generateForceData();
      _streamController?.add(forceData);
    });
    
    debugPrint('📊 Mock data generation started - 50 Hz (UI-friendly)');
  }

  ForceData _generateForceData() {
    final random = Random();
    final now = DateTime.now();
    
    // Senaryo bazlı veri üretimi
    double leftGRF, rightGRF, totalGRF;
    
    switch (_currentScenario) {
      case 'sakin_durus':
        leftGRF = 300 + random.nextDouble() * 100;
        rightGRF = 320 + random.nextDouble() * 100;
        break;
      case 'karsi_hareket_sicrami':
        final phase = (now.millisecondsSinceEpoch % 2000) / 2000.0;
        leftGRF = 200 + sin(phase * 2 * pi) * 800;
        rightGRF = 180 + sin(phase * 2 * pi + 0.1) * 850;
        break;
      case 'denge_testi':
        leftGRF = 250 + random.nextDouble() * 200;
        rightGRF = 280 + random.nextDouble() * 180;
        break;
      case 'izometrik_test':
        leftGRF = 400 + random.nextDouble() * 300;
        rightGRF = 420 + random.nextDouble() * 280;
        break;
      default:
        leftGRF = 300 + random.nextDouble() * 100;
        rightGRF = 300 + random.nextDouble() * 100;
    }
    
    totalGRF = leftGRF + rightGRF;
    
    return ForceData(
      timestamp: now,
      leftGRF: leftGRF,
      rightGRF: rightGRF,
      totalGRF: totalGRF,
      leftCoPX: -2.0 + random.nextDouble() * 4.0,
      leftCoPY: -3.0 + random.nextDouble() * 6.0,
      rightCoPX: -2.0 + random.nextDouble() * 4.0,
      rightCoPY: -3.0 + random.nextDouble() * 6.0,
      asymmetryIndex: (leftGRF - rightGRF).abs() / totalGRF,
      loadRate: random.nextDouble() * 100,
      stabilityIndex: 0.8 + random.nextDouble() * 0.2,
      samplingRate: 1000.0,
    );
  }

  // ✅ Scenario change method
  void changeScenario(String scenario) {
    _currentScenario = scenario;
    debugPrint('📊 Mock scenario changed to: $scenario');
  }

  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    
    await _streamController?.close();
    _streamController = null;
    
    _isConnected = false;
    _connectedDevice = null;
    _currentScenario = 'sakin_durus';
    
    debugPrint('🔌 Mock device disconnected');
  }

  void dispose() {
    disconnect();
  }
}