import 'dart:async';
import 'dart:math' as math;

import '../../core/utils/app_logger.dart';
import '../../domain/entities/force_data.dart';

/// USB Data Source - Geçici Mock Implementation
/// Gerçek USB implementasyonu için gerekli kütüphaneler eklendikten sonra geliştirilecek
class UsbDataSource {
  static final UsbDataSource _instance = UsbDataSource._internal();
  factory UsbDataSource() => _instance;
  UsbDataSource._internal();

  // Mock device state
  bool _isConnected = false;
  bool _isGenerating = false;
  String _deviceId = 'USB_MOCK_DEVICE';
  
  // Stream controller for real-time data
  StreamController<ForceData>? _forceDataController;
  Timer? _dataGenerationTimer;
  
  // Mock calibration offsets
  final List<double> _zeroOffsets = List.filled(8, 0.0);
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isGenerating => _isGenerating;
  String get deviceId => _deviceId;
  Stream<ForceData>? get forceDataStream => _forceDataController?.stream;

  /// Mock USB cihaza bağlan
  Future<bool> connect({String? deviceId}) async {
    try {
      AppLogger.info('🔌 USB Mock cihaza bağlanılıyor...');
      
      // Simulate connection delay
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (deviceId != null) {
        _deviceId = deviceId;
      }
      
      _isConnected = true;
      _forceDataController = StreamController<ForceData>.broadcast();
      
      AppLogger.usbConnected(_deviceId);
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.usbError('USB Mock bağlantı hatası: $e');
      AppLogger.error('USB Mock connection error', e, stackTrace);
      return false;
    }
  }

  /// USB cihaz bağlantısını kes
  Future<void> disconnect() async {
    try {
      AppLogger.info('🔌 USB Mock cihaz bağlantısı kesiliyor...');
      
      await stopDataGeneration();
      
      _isConnected = false;
      await _forceDataController?.close();
      _forceDataController = null;
      
      AppLogger.usbDisconnected();
      
    } catch (e, stackTrace) {
      AppLogger.error('USB Mock disconnect error', e, stackTrace);
    }
  }

  /// Kalibrasyon yap
  Future<bool> calibrate({Duration? duration}) async {
    if (!_isConnected) {
      AppLogger.error('USB Mock cihaz bağlı değil - kalibrasyon yapılamaz');
      return false;
    }
    
    try {
      AppLogger.info('🔧 USB Mock kalibrasyon başlıyor...');
      
      final calibrationDuration = duration ?? const Duration(seconds: 5);
      
      // Mock calibration data collection
      await Future.delayed(calibrationDuration);
      
      // Set mock zero offsets
      for (int i = 0; i < _zeroOffsets.length; i++) {
        _zeroOffsets[i] = (math.Random().nextDouble() - 0.5) * 20; // -10 to +10 N
      }
      
      AppLogger.success('✅ USB Mock kalibrasyon tamamlandı');
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error('USB Mock kalibrasyon hatası', e, stackTrace);
      return false;
    }
  }

  /// Veri üretimini başlat
  Future<bool> startDataGeneration({int sampleRate = 1000}) async {
    if (!_isConnected) {
      AppLogger.error('USB Mock cihaz bağlı değil - veri üretimi başlatılamaz');
      return false;
    }
    
    if (_isGenerating) {
      AppLogger.warning('USB Mock veri üretimi zaten aktif');
      return true;
    }
    
    try {
      AppLogger.info('📊 USB Mock veri üretimi başlıyor...');
      
      _isGenerating = true;
      
      // Start data generation timer
      final intervalMs = (1000 / sampleRate).round();
      _dataGenerationTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _generateAndSendMockData(),
      );
      
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error('USB Mock veri üretim başlatma hatası', e, stackTrace);
      return false;
    }
  }

  /// Veri üretimini durdur
  Future<void> stopDataGeneration() async {
    if (!_isGenerating) return;
    
    try {
      AppLogger.info('📊 USB Mock veri üretimi durduruluyor...');
      
      _dataGenerationTimer?.cancel();
      _dataGenerationTimer = null;
      _isGenerating = false;
      
      AppLogger.info('✅ USB Mock veri üretimi durduruldu');
      
    } catch (e, stackTrace) {
      AppLogger.error('USB Mock veri üretim durdurma hatası', e, stackTrace);
    }
  }

  /// Test connection
  Future<bool> testConnection() async {
    if (!_isConnected) return false;
    
    try {
      // Simulate connection test
      await Future.delayed(const Duration(milliseconds: 500));
      
      AppLogger.info('🔌 USB Mock bağlantı testi başarılı');
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error('USB Mock bağlantı test hatası', e, stackTrace);
      return false;
    }
  }

  // Private methods

  void _generateAndSendMockData() {
    if (!_isConnected || !_isGenerating || _forceDataController == null) return;
    
    try {
      final data = _generateMockForceData();
      _forceDataController!.add(data);
      
    } catch (e, stackTrace) {
      AppLogger.error('USB Mock veri üretim hatası', e, stackTrace);
    }
  }

  ForceData _generateMockForceData() {
    final random = math.Random();
    
    // Generate mock load cell data (8 load cells)
    final leftF1 = 100 + (random.nextDouble() - 0.5) * 50 - _zeroOffsets[0];
    final leftF2 = 100 + (random.nextDouble() - 0.5) * 50 - _zeroOffsets[1];
    final leftF3 = 100 + (random.nextDouble() - 0.5) * 50 - _zeroOffsets[2];
    final leftF4 = 100 + (random.nextDouble() - 0.5) * 50 - _zeroOffsets[3];
    
    final rightF1 = 100 + (random.nextDouble() - 0.5) * 50 - _zeroOffsets[4];
    final rightF2 = 100 + (random.nextDouble() - 0.5) * 50 - _zeroOffsets[5];
    final rightF3 = 100 + (random.nextDouble() - 0.5) * 50 - _zeroOffsets[6];
    final rightF4 = 100 + (random.nextDouble() - 0.5) * 50 - _zeroOffsets[7];
    
    // Calculate total forces
    final leftGRF = math.max(0, leftF1 + leftF2 + leftF3 + leftF4);
    final rightGRF = math.max(0, rightF1 + rightF2 + rightF3 + rightF4);
    
    // Generate mock COP values
    final leftCOPX = (random.nextDouble() - 0.5) * 60; // -30 to +30 mm
    final leftCOPY = (random.nextDouble() - 0.5) * 80; // -40 to +40 mm
    final rightCOPX = (random.nextDouble() - 0.5) * 60;
    final rightCOPY = (random.nextDouble() - 0.5) * 80;
    
    return ForceData.create(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      leftGRF: leftGRF,
      rightGRF: rightGRF,
      leftCOP_x: leftCOPX,
      leftCOP_y: leftCOPY,
      rightCOP_x: rightCOPX,
      rightCOP_y: rightCOPY,
    );
  }

  /// Get mock device info
  Map<String, dynamic> getDeviceInfo() {
    return {
      'deviceId': _deviceId,
      'isConnected': _isConnected,
      'isGenerating': _isGenerating,
      'sampleRate': 1000,
      'loadCells': 8,
      'firmwareVersion': 'USB_MOCK_v1.0.0',
      'lastCalibration': DateTime.now().subtract(const Duration(hours: 2)),
      'zeroOffsets': _zeroOffsets,
    };
  }

  /// Dispose resources
  void dispose() {
    _dataGenerationTimer?.cancel();
    _forceDataController?.close();
    AppLogger.info('🔌 USB Mock data source disposed');
  }
}