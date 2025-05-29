// lib/core/services/mock_usb_service.dart - Tam Düzeltilmiş
import 'dart:async';
import 'dart:math' as math;
import '../../domain/entities/force_data.dart';

class MockUsbService {
  StreamController<ForceData>? _forceDataController;
  Timer? _dataTimer;
  bool _isConnected = false;
  int _sampleIndex = 0;
  final math.Random _random = math.Random();
  
  // Test senaryoları için
  String _currentScenario = 'quiet_stance'; // sakin duruş
  
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
      'Mock Force Platform - Test'
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
    final time = _sampleIndex / 1000.0; // Saniye cinsinden zaman
    
    // 🎯 Gerçekçi simülasyon - farklı senaryolara göre
    final baseWeight = 700.0; // Ortalama kişi ağırlığı (Newton)
    
    double leftForce, rightForce;
    double leftCoPX, leftCoPY, rightCoPX, rightCoPY;
    
    switch (_currentScenario) {
      case 'quiet_stance': // Sakin duruş
        leftForce = baseWeight * 0.48 + _random.nextDouble() * 20 - 10;
        rightForce = baseWeight * 0.52 + _random.nextDouble() * 20 - 10;
        
        leftCoPX = _random.nextDouble() * 6 - 3;  // ±3mm
        leftCoPY = _random.nextDouble() * 8 - 4;  // ±4mm
        rightCoPX = _random.nextDouble() * 6 - 3;
        rightCoPY = _random.nextDouble() * 8 - 4;
        break;
        
      case 'balance_challenge': // Denge testi
        final sway = 15 * math.sin(time * 2 * math.pi * 0.5); // 0.5Hz sallanma
        leftForce = baseWeight * 0.5 + sway + _random.nextDouble() * 30 - 15;
        rightForce = baseWeight * 0.5 - sway + _random.nextDouble() * 30 - 15;
        
        leftCoPX = sway * 0.8 + _random.nextDouble() * 20 - 10;
        leftCoPY = _random.nextDouble() * 25 - 12.5;
        rightCoPX = -sway * 0.8 + _random.nextDouble() * 20 - 10;
        rightCoPY = _random.nextDouble() * 25 - 12.5;
        break;
        
      case 'jump_landing': // Sıçrama iniş
        if (time % 3.0 < 0.2) { // Her 3 saniyede bir sıçrama
          final jumpPhase = (time % 3.0) / 0.2;
          final jumpForce = baseWeight * (1 + 2 * math.sin(jumpPhase * math.pi));
          leftForce = jumpForce * 0.5 + _random.nextDouble() * 100 - 50;
          rightForce = jumpForce * 0.5 + _random.nextDouble() * 100 - 50;
        } else {
          leftForce = baseWeight * 0.5 + _random.nextDouble() * 30 - 15;
          rightForce = baseWeight * 0.5 + _random.nextDouble() * 30 - 15;
        }
        
        leftCoPX = _random.nextDouble() * 30 - 15;
        leftCoPY = _random.nextDouble() * 40 - 20;
        rightCoPX = _random.nextDouble() * 30 - 15;
        rightCoPY = _random.nextDouble() * 40 - 20;
        break;
        
      default:
        leftForce = baseWeight * 0.5;
        rightForce = baseWeight * 0.5;
        leftCoPX = leftCoPY = rightCoPX = rightCoPY = 0.0;
    }
    
    // Negatif kuvvet kontrolü
    leftForce = math.max(0, leftForce);
    rightForce = math.max(0, rightForce);
    
    final totalForce = leftForce + rightForce;
    
    // Hesaplanan metrikler
    final asymmetryIndex = totalForce > 0 ? (leftForce - rightForce).abs() / totalForce : 0.0;
    final stabilityIndex = math.max(0.0, math.min(1.0, 1.0 - (asymmetryIndex + _random.nextDouble() * 0.1)));
    final loadRate = (totalForce - (baseWeight)) * 10; // N/s yaklaşık
    
    // 4+4 Load cell simülasyonu (VALD ForceDecks benzeri)
    final leftDeckForces = [
      leftForce * 0.23 + _random.nextDouble() * 5, // Ön sol
      leftForce * 0.27 + _random.nextDouble() * 5, // Ön sağ  
      leftForce * 0.25 + _random.nextDouble() * 5, // Arka sol
      leftForce * 0.25 + _random.nextDouble() * 5, // Arka sağ
    ];
    
    final rightDeckForces = [
      rightForce * 0.24 + _random.nextDouble() * 5, // Ön sol
      rightForce * 0.26 + _random.nextDouble() * 5, // Ön sağ
      rightForce * 0.25 + _random.nextDouble() * 5, // Arka sol
      rightForce * 0.25 + _random.nextDouble() * 5, // Arka sağ
    ];
    
    // ✅ ForceData - Tüm required parametreler dahil
    final forceData = ForceData(
      timestamp: now,
      
      // Required parametreler
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
      
      // Optional parametreler
      leftDeckForces: leftDeckForces,
      rightDeckForces: rightDeckForces,
      samplingRate: 1000.0,
      sampleIndex: _sampleIndex,
    );
    
    _forceDataController?.add(forceData);
    _sampleIndex++;
  }

  // Test senaryosu değiştirme
  void changeScenario(String scenario) {
    _currentScenario = scenario;
    print('📊 Test senaryosu değiştirildi: $scenario');
  }

  Future<void> disconnect() async {
    _dataTimer?.cancel();
    _isConnected = false;
    _sampleIndex = 0;
    print('🔌 Mock USB bağlantısı kesildi');
  }

  void dispose() {
    disconnect();
    _forceDataController?.close();
  }

  // Test için manuel veri üretimi
  ForceData generateTestData() {
    _generateMockForceData();
    return ForceData(
      timestamp: DateTime.now(),
      leftGRF: 350.0,
      leftCoPX: 0.0,
      leftCoPY: 0.0,
      rightGRF: 350.0,
      rightCoPX: 0.0,
      rightCoPY: 0.0,
      totalGRF: 700.0,
      asymmetryIndex: 0.0,
      stabilityIndex: 1.0,
      loadRate: 0.0,
    );
  }
}