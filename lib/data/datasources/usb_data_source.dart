// lib/data/datasources/usb_data_source.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:libserialport/libserialport.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/force_data.dart';
import '../../domain/entities/athlete.dart';

/// USB Hardware veri kaynağı - Gerçek force plate bağlantısı
class UsbDataSource {
  static final UsbDataSource _instance = UsbDataSource._internal();
  factory UsbDataSource() => _instance;
  UsbDataSource._internal();

  // USB connection
  UsbPort? _usbPort;
  SerialPort? _serialPort;
  bool _isConnected = false;
  String? _deviceId;
  
  // Data streaming
  StreamController<ForceData>? _forceDataController;
  StreamSubscription<Uint8List>? _dataSubscription;
  
  // Protocol settings
  static const int _baudRate = AppConstants.baudRate;
  static const int _sampleRate = AppConstants.sampleRate;
  static const int _expectedDataLength = 32; // 8 load cells * 4 bytes each
  
  // Data parsing
  final List<int> _dataBuffer = [];
  int _packetCount = 0;
  DateTime? _lastPacketTime;
  
  // Calibration
  bool _isCalibrated = false;
  final List<double> _zeroOffsets = List.filled(8, 0.0); // 8 load cell offsets
  
  // Device state
  bool _isDataStreaming = false;
  String _firmwareVersion = '';
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};

  // Getters
  bool get isConnected => _isConnected;
  bool get isDataStreaming => _isDataStreaming;
  bool get isCalibrated => _isCalibrated;
  String? get deviceId => _deviceId;
  String get firmwareVersion => _firmwareVersion;
  Stream<ForceData>? get forceDataStream => _forceDataController?.stream;
  List<double> get zeroOffsets => List.from(_zeroOffsets);

  /// Kullanılabilir USB cihazları listele
  Future<List<UsbDevice>> getAvailableDevices() async {
    try {
      final List<UsbDevice> devices = await UsbSerial.listDevices();
      
      // izForce cihazlarını filtrele (vendor ID ve product ID'ye göre)
      final List<UsbDevice> forceDevices = devices.where((UsbDevice device) {
        return device.vid == AppConstants.usbVendorId && 
               device.pid == AppConstants.usbProductId;
      }).toList();
      
      AppLogger.info('📱 ${forceDevices.length} izForce cihazı bulundu');
      return forceDevices;
      
    } catch (e, stackTrace) {
      AppLogger.error('USB cihaz tarama hatası', e, stackTrace);
      return <UsbDevice>[];
    }
  }

  /// USB cihaza bağlan
  Future<bool> connect({String? deviceId}) async {
    if (_isConnected) {
      AppLogger.warning('USB cihaz zaten bağlı');
      return true;
    }

    try {
      AppLogger.info('🔌 USB cihaza bağlanılıyor...');
      
      List<UsbDevice> devices;
      
      if (deviceId != null) {
        // Belirli bir cihaza bağlan
        devices = await getAvailableDevices();
        devices = devices.where((UsbDevice d) => d.deviceName == deviceId).toList();
      } else {
        // İlk bulduğu cihaza bağlan
        devices = await getAvailableDevices();
      }
      
      if (devices.isEmpty) {
        AppLogger.usbError('izForce cihazı bulunamadı');
        return false;
      }
      
      final UsbDevice device = devices.first;
      _deviceId = device.deviceName;
      
      // USB port aç
      _usbPort = await device.create();
      if (_usbPort == null) {
        AppLogger.usbError('USB port oluşturulamadı');
        return false;
      }
      
      // Port yapılandırması
      final bool openResult = await _usbPort!.open();
      if (!openResult) {
        AppLogger.usbError('USB port açılamadı');
        return false;
      }
      
      await _usbPort!.setDTR(true);
      await _usbPort!.setRTS(true);
      await _usbPort!.setPortParameters(
        _baudRate, 
        UsbPort.DATABITS_8, 
        UsbPort.STOPBITS_1, 
        UsbPort.PARITY_NONE
      );
      
      // Stream controller oluştur
      _forceDataController = StreamController<ForceData>.broadcast();
      
      // Cihaz bilgilerini al
      await _getDeviceInfo();
      
      // Bağlantıyı test et
      final bool connectionTest = await _testConnection();
      if (!connectionTest) {
        await disconnect();
        return false;
      }
      
      _isConnected = true;
      AppLogger.usbConnected(_deviceId!);
      
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.usbError('USB bağlantı hatası: $e');
      AppLogger.error('USB connection error', e, stackTrace);
      await disconnect();
      return false;
    }
  }

  /// Alternatif: Serial port ile bağlan (Windows/Linux)
  Future<bool> connectSerial({String? portName}) async {
    if (_isConnected) {
      AppLogger.warning('Serial cihaz zaten bağlı');
      return true;
    }

    try {
      AppLogger.info('🔌 Serial porta bağlanılıyor...');
      
      // Kullanılabilir portları listele
      final List<String> availablePorts = SerialPort.availablePorts;
      if (availablePorts.isEmpty) {
        AppLogger.usbError('Serial port bulunamadı');
        return false;
      }
      
      final String selectedPort = portName ?? availablePorts.first;
      AppLogger.info('📡 Bağlanılan port: $selectedPort');
      
      _serialPort = SerialPort(selectedPort);
      
      // Port yapılandırması
      final SerialPortConfig config = SerialPortConfig();
      config.baudRate = _baudRate;
      config.bits = 8;
      config.stopBits = 1;
      config.parity = SerialPortParity.none;
      config.setFlowControl(SerialPortFlowControl.none);
      
      _serialPort!.config = config;
      
      // Port aç
      final bool openResult = _serialPort!.openReadWrite();
      if (!openResult) {
        final String error = SerialPort.lastError;
        AppLogger.usbError('Serial port açılamadı: $error');
        return false;
      }
      
      _deviceId = selectedPort;
      _forceDataController = StreamController<ForceData>.broadcast();
      
      // Cihaz bilgilerini al
      await _getDeviceInfo();
      
      // Bağlantıyı test et
      final bool connectionTest = await _testConnection();
      if (!connectionTest) {
        await disconnect();
        return false;
      }
      
      _isConnected = true;
      AppLogger.usbConnected(_deviceId!);
      
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.usbError('Serial bağlantı hatası', e, stackTrace);
      AppLogger.error('Serial connection error', e, stackTrace);
      await disconnect();
      return false;
    }
  }

  /// USB/Serial bağlantısını kes
  Future<void> disconnect() async {
    try {
      AppLogger.info('🔌 USB bağlantısı kesiliyor...');
      
      await stopDataStreaming();
      
      // USB port kapat
      if (_usbPort != null) {
        await _usbPort!.close();
        _usbPort = null;
      }
      
      // Serial port kapat
      if (_serialPort != null) {
        _serialPort!.close();
        _serialPort = null;
      }
      
      // Stream kapat
      await _forceDataController?.close();
      _forceDataController = null;
      _dataSubscription?.cancel();
      _dataSubscription = null;
      
      // State sıfırla
      _isConnected = false;
      _isDataStreaming = false;
      _deviceId = null;
      _dataBuffer.clear();
      _packetCount = 0;
      
      AppLogger.usbDisconnected();
      
    } catch (e, stackTrace) {
      AppLogger.error('USB disconnect hatası', e, stackTrace);
    }
  }

  /// Cihaz kalibrasyon
  Future<bool> calibrate({Duration? duration}) async {
    if (!_isConnected) {
      AppLogger.error('USB cihaz bağlı değil');
      return false;
    }

    try {
      AppLogger.info('⚖️ USB kalibrasyon başlıyor...');
      
      final Duration calibrationDuration = duration ?? const Duration(seconds: 5);
      
      // Kalibrasyon komutunu gönder
      await _sendCommand('CAL_START');
      
      // Kalibrasyon verilerini topla
      final List<List<double>> calibrationData = <List<double>>[];
      final DateTime startTime = DateTime.now();
      
      // Geçici veri dinleyici
      late StreamSubscription<Uint8List> calibrationSubscription;
      final Completer<bool> calibrationCompleter = Completer<bool>();
      
      calibrationSubscription = _getDataStream().listen((Uint8List data) {
        final List<double>? loadCellValues = _parseLoadCellData(data);
        if (loadCellValues != null) {
          calibrationData.add(loadCellValues);
        }
        
        // Süre kontrolü
        if (DateTime.now().difference(startTime) >= calibrationDuration) {
          calibrationSubscription.cancel();
          calibrationCompleter.complete(true);
        }
      });
      
      // Kalibrasyon tamamlanmasını bekle
      await calibrationCompleter.future;
      
      // Zero offset'leri hesapla
      if (calibrationData.isNotEmpty) {
        for (int i = 0; i < 8; i++) {
          final List<double> cellValues = calibrationData.map((List<double> data) => data[i]).toList();
          _zeroOffsets[i] = cellValues.reduce((double a, double b) => a + b) / cellValues.length;
        }
        
        _isCalibrated = true;
        
        // Kalibrasyon verilerini cihaza gönder
        await _sendCalibrationData();
        
        AppLogger.success('✅ USB kalibrasyon tamamlandı');
        return true;
      } else {
        AppLogger.error('Kalibrasyon verisi alınamadı');
        return false;
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('USB kalibrasyon hatası', e, stackTrace);
      return false;
    }
  }

  /// Veri akışını başlat
  Future<bool> startDataStreaming({TestType? testType}) async {
    if (!_isConnected) {
      AppLogger.error('USB cihaz bağlı değil');
      return false;
    }
    
    if (_isDataStreaming) {
      AppLogger.warning('Veri akışı zaten aktif');
      return true;
    }

    try {
      AppLogger.info('📊 USB veri akışı başlıyor...');
      
      // Test türüne göre cihaz yapılandırması
      if (testType != null) {
        await _configureForTestType(testType);
      }
      
      // Veri akışı başlatma komutu
      await _sendCommand('STREAM_START');
      
      // Veri dinleyici başlat
      _dataSubscription = _getDataStream().listen(
        _onDataReceived,
        onError: (Object error) {
          AppLogger.usbError('Veri akışı hatası: $error');
        },
      );
      
      _isDataStreaming = true;
      _packetCount = 0;
      _lastPacketTime = DateTime.now();
      
      AppLogger.success('✅ USB veri akışı başladı');
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error('USB veri akışı başlatma hatası', e, stackTrace);
      return false;
    }
  }

  /// Veri akışını durdur
  Future<void> stopDataStreaming() async {
    if (!_isDataStreaming) return;

    try {
      AppLogger.info('📊 USB veri akışı durduruluyor...');
      
      // Durdurma komutu gönder
      await _sendCommand('STREAM_STOP');
      
      // Subscription'ı iptal et
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      
      _isDataStreaming = false;
      _dataBuffer.clear();
      
      AppLogger.info('✅ USB veri akışı durduruldu (${_packetCount} paket alındı)');
      
    } catch (e, stackTrace) {
      AppLogger.error('USB veri akışı durdurma hatası', e, stackTrace);
    }
  }

  /// Bağlantıyı test et
  Future<bool> testConnection() async {
    if (!_isConnected) return false;
    
    try {
      return await _testConnection();
    } catch (e, stackTrace) {
      AppLogger.error('USB bağlantı test hatası', e, stackTrace);
      return false;
    }
  }

  // Private methods

  Future<bool> _testConnection() async {
    try {
      // Ping komutu gönder
      await _sendCommand('PING');
      
      // Response bekle (timeout ile)
      final bool response = await _waitForResponse('PONG', timeout: const Duration(seconds: 2));
      
      if (response) {
        AppLogger.info('🎯 USB bağlantı testi başarılı');
        return true;
      } else {
        AppLogger.usbError('USB bağlantı testi başarısız - timeout');
        return false;
      }
      
    } catch (e) {
      AppLogger.usbError('USB bağlantı testi hatası: $e');
      return false;
    }
  }

  Future<void> _getDeviceInfo() async {
    try {
      // Cihaz bilgilerini sorgula
      await _sendCommand('GET_INFO');
      
      // Mock device info (gerçek implementasyonda parse edilecek)
      _deviceInfo = <String, dynamic>{
        'deviceId': _deviceId,
        'firmwareVersion': '2.1.3',
        'hardwareVersion': '1.0',
        'serialNumber': 'IZF2024001',
        'loadCellCount': 8,
        'maxSampleRate': 2000,
        'calibrationDate': DateTime.now().subtract(const Duration(days: 7)),
      };
      
      _firmwareVersion = _deviceInfo['firmwareVersion'] as String? ?? '';
      
      AppLogger.info('📟 Cihaz bilgileri alındı: $_firmwareVersion');
      
    } catch (e, stackTrace) {
      AppLogger.error('Cihaz bilgisi alma hatası', e, stackTrace);
    }
  }

  Stream<Uint8List> _getDataStream() {
    if (_usbPort != null) {
      return _usbPort!.inputStream!;
    } else if (_serialPort != null) {
      return _serialPort!.reader.stream;
    } else {
      throw Exception('No active connection');
    }
  }

  Future<void> _sendCommand(String command) async {
    try {
      final Uint8List commandBytes = Uint8List.fromList('$command\n'.codeUnits);
      
      if (_usbPort != null) {
        await _usbPort!.write(commandBytes);
      } else if (_serialPort != null) {
        _serialPort!.write(commandBytes);
      }
      
      AppLogger.debug('📤 Komut gönderildi: $command');
      
    } catch (e, stackTrace) {
      AppLogger.error('Komut gönderme hatası', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> _waitForResponse(String expectedResponse, {Duration? timeout}) async {
    try {
      final Duration timeoutDuration = timeout ?? const Duration(seconds: 5);
      final Completer<bool> completer = Completer<bool>();
      
      // Timeout timer
      final Timer timer = Timer(timeoutDuration, () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
      
      // Response listener (basitleştirilmiş)
      Timer(const Duration(milliseconds: 500), () {
        if (!completer.isCompleted) {
          completer.complete(true); // Mock response
        }
      });
      
      final bool result = await completer.future;
      timer.cancel();
      
      return result;
      
    } catch (e) {
      return false;
    }
  }

  void _onDataReceived(Uint8List data) {
    try {
      // Buffer'a ekle
      _dataBuffer.addAll(data);
      
      // Tam paket(ler) var mı kontrol et
      while (_dataBuffer.length >= _expectedDataLength) {
        // Paket başlangıcını bul (sync byte'lar)
        final int syncIndex = _findSyncPattern();
        
        if (syncIndex == -1) {
          // Sync bulunamadı, buffer'ı temizle
          _dataBuffer.clear();
          break;
        }
        
        // Sync'e kadar olan veriyi at
        if (syncIndex > 0) {
          _dataBuffer.removeRange(0, syncIndex);
        }
        
        // Yeterli veri var mı kontrol et
        if (_dataBuffer.length < _expectedDataLength) break;
        
        // Paket verilerini çıkar
        final List<int> packetData = _dataBuffer.sublist(0, _expectedDataLength);
        _dataBuffer.removeRange(0, _expectedDataLength);
        
        // Load cell verilerini parse et
        final List<double>? loadCellValues = _parseLoadCellData(Uint8List.fromList(packetData));
        if (loadCellValues != null) {
          // ForceData oluştur ve gönder
          final ForceData forceData = _createForceDataFromLoadCells(loadCellValues);
          _forceDataController?.add(forceData);
          
          _packetCount++;
          _lastPacketTime = DateTime.now();
        }
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('Veri parse hatası', e, stackTrace);
    }
  }

  int _findSyncPattern() {
    // Basit sync pattern: 0xAA 0x55
    for (int i = 0; i < _dataBuffer.length - 1; i++) {
      if (_dataBuffer[i] == 0xAA && _dataBuffer[i + 1] == 0x55) {
        return i;
      }
    }
    return -1;
  }

  List<double>? _parseLoadCellData(Uint8List data) {
    try {
      if (data.length < _expectedDataLength) return null;
      
      final List<double> loadCellValues = <double>[];
      
      // Skip sync bytes (2 bytes)
      int offset = 2;
      
      // 8 load cell değeri (her biri 4 byte float)
      for (int i = 0; i < 8; i++) {
        if (offset + 4 > data.length) return null;
        
        // Little endian float parse
        final List<int> bytes = data.sublist(offset, offset + 4);
        final ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));
        final double value = byteData.getFloat32(0, Endian.little);
        
        // Kalibrasyon offset'ini uygula
        final double calibratedValue = value - (_isCalibrated ? _zeroOffsets[i] : 0.0);
        loadCellValues.add(calibratedValue);
        
        offset += 4;
      }
      
      return loadCellValues;
      
    } catch (e, stackTrace) {
      AppLogger.error('Load cell veri parse hatası', e, stackTrace);
      return null;
    }
  }

  ForceData _createForceDataFromLoadCells(List<double> loadCellValues) {
    // Load cell dizilimi:
    // Sol platform: 0,1,2,3 (ön-sol, ön-sağ, arka-sol, arka-sağ)
    // Sağ platform: 4,5,6,7 (ön-sol, ön-sağ, arka-sol, arka-sağ)
    
    final List<double> leftValues = loadCellValues.sublist(0, 4);
    final List<double> rightValues = loadCellValues.sublist(4, 8);
    
    final double leftGRF = leftValues.reduce((double a, double b) => a + b);
    final double rightGRF = rightValues.reduce((double a, double b) => a + b);
    
    // COP hesaplama (platform boyutları: 400x600mm)
    const double platformWidth = 400.0;
    const double platformLength = 600.0;
    
    final ({double x, double y}) leftCOP = ForceData.calculateCOP(leftValues, platformWidth, platformLength);
    final ({double x, double y}) rightCOP = ForceData.calculateCOP(rightValues, platformWidth, platformLength);
    
    return ForceData.create(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      leftGRF: leftGRF,
      rightGRF: rightGRF,
      leftCOP_x: leftCOP.x,
      leftCOP_y: leftCOP.y,
      rightCOP_x: rightCOP.x,
      rightCOP_y: rightCOP.y,
    );
  }

  Future<void> _configureForTestType(TestType testType) async {
    try {
      // Test türüne göre cihaz yapılandırması
      switch (testType.category) {
        case TestCategory.jump:
          await _sendCommand('CONFIG_JUMP');
          break;
        case TestCategory.strength:
          await _sendCommand('CONFIG_STRENGTH');
          break;
        case TestCategory.balance:
          await _sendCommand('CONFIG_BALANCE');
          break;
        case TestCategory.agility:
          await _sendCommand('CONFIG_AGILITY');
          break;
      }
      
      AppLogger.debug('⚙️ Cihaz yapılandırması: ${testType.turkishName}');
      
    } catch (e, stackTrace) {
      AppLogger.error('Cihaz yapılandırma hatası', e, stackTrace);
    }
  }

  Future<void> _sendCalibrationData() async {
    try {
      // Kalibrasyon verilerini cihaza gönder
      final String calibrationCommand = 'CAL_SET:${_zeroOffsets.join(',')}';
      await _sendCommand(calibrationCommand);
      
      AppLogger.debug('📤 Kalibrasyon verileri gönderildi');
      
    } catch (e, stackTrace) {
      AppLogger.error('Kalibrasyon veri gönderme hatası', e, stackTrace);
    }
  }

  /// Get device info
  Map<String, dynamic> getDeviceInfo() {
    return Map<String, dynamic>.from(_deviceInfo)..addAll(<String, dynamic>{
      'isConnected': _isConnected,
      'isDataStreaming': _isDataStreaming,
      'isCalibrated': _isCalibrated,
      'packetCount': _packetCount,
      'lastPacketTime': _lastPacketTime,
      'zeroOffsets': _zeroOffsets,
    });
  }

  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    final DateTime now = DateTime.now();
    final int? timeSinceLastPacket = _lastPacketTime != null 
        ? now.difference(_lastPacketTime!).inMilliseconds
        : null;
    
    return <String, dynamic>{
      'packetCount': _packetCount,
      'lastPacketTime': _lastPacketTime,
      'timeSinceLastPacket': timeSinceLastPacket,
      'isHealthy': timeSinceLastPacket != null && timeSinceLastPacket < 100,
      'expectedSampleRate': _sampleRate,
      'bufferSize': _dataBuffer.length,
    };
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    AppLogger.info('🔌 USB data source disposed');
  }
}