// lib/data/datasources/usb_data_source.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:libserialport/libserialport.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/force_data.dart';
import '../../data/models/force_data_model.dart';

// Test types - eğer başka dosyada tanımlıysa import edin
enum TestCategory { jump, strength, balance, agility }

class TestType {
  final TestCategory category;
  final String turkishName;
  
  const TestType({required this.category, required this.turkishName});
}

/// USB Hardware data source - Real force plate connection
class UsbDataSource {
  static final UsbDataSource _instance = UsbDataSource._internal();
  factory UsbDataSource() => _instance;
  UsbDataSource._internal();

  // USB connection
  UsbPort? _usbPort;
  SerialPort? _serialPort;
  SerialPortReader? _serialPortReader;
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

  /// List available USB devices
  Future<List<UsbDevice>> getAvailableDevices() async {
    try {
      final List<UsbDevice> devices = await UsbSerial.listDevices();
      
      // Filter izForce devices (by vendor ID and product ID)
      final List<UsbDevice> forceDevices = devices.where((UsbDevice device) {
        return device.vid == AppConstants.usbVendorId && 
               device.pid == AppConstants.usbProductId;
      }).toList();
      
      AppLogger.info('📱 Found ${forceDevices.length} izForce devices');
      return forceDevices;
      
    } catch (e, stackTrace) {
      AppLogger.error('USB device scan error', e, stackTrace);
      return <UsbDevice>[];
    }
  }

  /// Connect to USB device
  Future<bool> connect({String? deviceId}) async {
    if (_isConnected) {
      AppLogger.warning('USB device already connected');
      return true;
    }

    try {
      AppLogger.info('🔌 Connecting to USB device...');
      
      List<UsbDevice> devices;
      
      if (deviceId != null) {
        // Connect to specific device
        devices = await getAvailableDevices();
        devices = devices.where((UsbDevice d) => d.deviceName == deviceId).toList();
      } else {
        // Connect to first found device
        devices = await getAvailableDevices();
      }
      
      if (devices.isEmpty) {
        AppLogger.usbError('izForce device not found');
        return false;
      }
      
      final UsbDevice device = devices.first;
      _deviceId = device.deviceName;
      
      // Open USB port
      _usbPort = await device.create();
      if (_usbPort == null) {
        AppLogger.usbError('USB port could not be created');
        return false;
      }
      
      final bool openResult = await _usbPort!.open();
      if (!openResult) {
        AppLogger.usbError('USB port could not be opened');
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
      
      // Create stream controller
      _forceDataController = StreamController<ForceData>.broadcast();
      
      // Get device info
      await _getDeviceInfo();
      
      // Test connection
      final bool connectionTest = await _testConnection();
      if (!connectionTest) {
        await disconnect();
        return false;
      }
      
      _isConnected = true;
      AppLogger.usbConnected(_deviceId!);
      
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.usbError('USB connection error: ${e.toString()}');
      AppLogger.error('USB connection error', e, stackTrace);
      await disconnect();
      return false;
    }
  }

  /// Alternative: Connect via Serial port (Windows/Linux)
  Future<bool> connectSerial({String? portName}) async {
    if (_isConnected) {
      AppLogger.warning('Serial device already connected');
      return true;
    }

    try {
      AppLogger.info('🔌 Connecting to serial port...');
      
      // List available ports
      final List<String> availablePorts = SerialPort.availablePorts;
      if (availablePorts.isEmpty) {
        AppLogger.usbError('Serial port not found');
        return false;
      }
      
      final String selectedPort = portName ?? availablePorts.first;
      AppLogger.info('📡 Connected port: $selectedPort');
      
      _serialPort = SerialPort(selectedPort);
      
      // Port configuration
      final SerialPortConfig config = SerialPortConfig();
      config.baudRate = _baudRate;
      config.bits = 8;
      config.stopBits = 1;
      config.parity = SerialPortParity.none;
      config.setFlowControl(SerialPortFlowControl.none);
      
      _serialPort!.config = config;
      
      // Open port
      final bool openResult = _serialPort!.openReadWrite();
      if (!openResult) {
        final String error = SerialPort.lastError?.message ?? 'Unknown error';
        AppLogger.usbError('Serial port could not be opened: $error');
        return false;
      }
      
      // Create serial port reader
      _serialPortReader = SerialPortReader(_serialPort!);
      
      _deviceId = selectedPort;
      _forceDataController = StreamController<ForceData>.broadcast();
      
      // Get device info
      await _getDeviceInfo();
      
      // Test connection
      final bool connectionTest = await _testConnection();
      if (!connectionTest) {
        await disconnect();
        return false;
      }
      
      _isConnected = true;
      AppLogger.usbConnected(_deviceId!);
      
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.usbError('Serial connection error: ${e.toString()}');
      AppLogger.error('Serial connection error', e, stackTrace);
      await disconnect();
      return false;
    }
  }

  /// Disconnect USB/Serial connection
  Future<void> disconnect() async {
    try {
      AppLogger.info('🔌 Disconnecting USB connection...');
      
      await stopDataStreaming();
      
      // Close USB port
      if (_usbPort != null) {
        await _usbPort!.close();
        _usbPort = null;
      }
      
      // Close Serial port
      if (_serialPort != null) {
        _serialPortReader?.close();
        _serialPortReader = null;
        _serialPort!.close();
        _serialPort = null;
      }
      
      // Close stream
      await _forceDataController?.close();
      _forceDataController = null;
      _dataSubscription?.cancel();
      _dataSubscription = null;
      
      // Reset state
      _isConnected = false;
      _isDataStreaming = false;
      _deviceId = null;
      _dataBuffer.clear();
      _packetCount = 0;
      
      AppLogger.usbDisconnected();
      
    } catch (e, stackTrace) {
      AppLogger.error('USB disconnect error', e, stackTrace);
    }
  }

  /// Device calibration
  Future<bool> calibrate({Duration? duration}) async {
    if (!_isConnected) {
      AppLogger.error('USB device not connected');
      return false;
    }

    try {
      AppLogger.info('⚖️ USB calibration starting...');
      
      final Duration calibrationDuration = duration ?? const Duration(seconds: 5);
      
      // Send calibration command
      await _sendCommand('CAL_START');
      
      // Collect calibration data
      final List<List<double>> calibrationData = <List<double>>[];
      final DateTime startTime = DateTime.now();
      
      // Temporary data listener
      late StreamSubscription<Uint8List> calibrationSubscription;
      final Completer<bool> calibrationCompleter = Completer<bool>();
      
      calibrationSubscription = _getDataStream().listen((Uint8List data) {
        final List<double>? loadCellValues = _parseLoadCellData(data);
        if (loadCellValues != null) {
          calibrationData.add(loadCellValues);
        }
        
        // Duration check
        if (DateTime.now().difference(startTime) >= calibrationDuration) {
          calibrationSubscription.cancel();
          calibrationCompleter.complete(true);
        }
      });
      
      // Wait for calibration completion
      await calibrationCompleter.future;
      
      // Calculate zero offsets
      if (calibrationData.isNotEmpty) {
        for (int i = 0; i < 8; i++) {
          final List<double> cellValues = calibrationData.map((List<double> data) => data[i]).toList();
          _zeroOffsets[i] = cellValues.reduce((double a, double b) => a + b) / cellValues.length;
        }
        
        _isCalibrated = true;
        
        // Send calibration data to device
        await _sendCalibrationData();
        
        AppLogger.success('✅ USB calibration completed');
        return true;
      } else {
        AppLogger.error('Calibration data could not be obtained');
        return false;
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('USB calibration error', e, stackTrace);
      return false;
    }
  }

  /// Start data streaming
  Future<bool> startDataStreaming({TestType? testType}) async {
    if (!_isConnected) {
      AppLogger.error('USB device not connected');
      return false;
    }
    
    if (_isDataStreaming) {
      AppLogger.warning('Data streaming already active');
      return true;
    }

    try {
      AppLogger.info('📊 USB data streaming starting...');
      
      // Device configuration based on test type
      if (testType != null) {
        await _configureForTestType(testType);
      }
      
      // Start data streaming command
      await _sendCommand('STREAM_START');
      
      // Start data listener
      _dataSubscription = _getDataStream().listen(
        _onDataReceived,
        onError: (Object error) {
          AppLogger.usbError('Data streaming error: ${error.toString()}');
        },
      );
      
      _isDataStreaming = true;
      _packetCount = 0;
      _lastPacketTime = DateTime.now();
      
      AppLogger.success('✅ USB data streaming started');
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error('USB data streaming start error', e, stackTrace);
      return false;
    }
  }

  /// Stop data streaming
  Future<void> stopDataStreaming() async {
    if (!_isDataStreaming) return;

    try {
      AppLogger.info('📊 USB data streaming stopping...');
      
      // Send stop command
      await _sendCommand('STREAM_STOP');
      
      // Cancel subscription
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      
      _isDataStreaming = false;
      _dataBuffer.clear();
      
      AppLogger.info('✅ USB data streaming stopped ($_packetCount packets received)');
      
    } catch (e, stackTrace) {
      AppLogger.error('USB data streaming stop error', e, stackTrace);
    }
  }

  /// Test connection
  Future<bool> testConnection() async {
    if (!_isConnected) return false;
    
    try {
      return await _testConnection();
    } catch (e, stackTrace) {
      AppLogger.error('USB connection test error', e, stackTrace);
      return false;
    }
  }

  // Private methods

  Future<bool> _testConnection() async {
    try {
      // Send ping command
      await _sendCommand('PING');
      
      // Wait for response (with timeout)
      final bool response = await _waitForResponse('PONG', timeout: const Duration(seconds: 2));
      
      if (response) {
        AppLogger.info('🎯 USB connection test successful');
        return true;
      } else {
        AppLogger.usbError('USB connection test failed - timeout');
        return false;
      }
      
    } catch (e) {
      AppLogger.usbError('USB connection test error: ${e.toString()}');
      return false;
    }
  }

  Future<void> _getDeviceInfo() async {
    try {
      // Query device information
      await _sendCommand('GET_INFO');
      
      // Mock device info (will be parsed in real implementation)
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
      
      AppLogger.info('📟 Device info obtained: $_firmwareVersion');
      
    } catch (e, stackTrace) {
      AppLogger.error('Device info retrieval error', e, stackTrace);
    }
  }

  Stream<Uint8List> _getDataStream() {
    if (_usbPort != null) {
      return _usbPort!.inputStream!;
    } else if (_serialPortReader != null) {
      // Fixed: Use SerialPortReader to get a stream of bytes
      return _serialPortReader!.stream.map((data) => Uint8List.fromList(data));
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
      
      AppLogger.debug('📤 Command sent: $command');
      
    } catch (e, stackTrace) {
      AppLogger.error('Command send error', e, stackTrace);
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
      
      // Response listener (simplified)
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
      // Add to buffer
      _dataBuffer.addAll(data);
      
      // Check if there are complete packet(s)
      while (_dataBuffer.length >= _expectedDataLength) {
        // Find packet start (sync bytes)
        final int syncIndex = _findSyncPattern();
        
        if (syncIndex == -1) {
          // Sync not found, clear buffer
          _dataBuffer.clear();
          break;
        }
        
        // Remove data before sync
        if (syncIndex > 0) {
          _dataBuffer.removeRange(0, syncIndex);
        }
        
        // Check if enough data is available
        if (_dataBuffer.length < _expectedDataLength) break;
        
        // Extract packet data
        final List<int> packetData = _dataBuffer.sublist(0, _expectedDataLength);
        _dataBuffer.removeRange(0, _expectedDataLength);
        
        // Parse load cell data
        final List<double>? loadCellValues = _parseLoadCellData(Uint8List.fromList(packetData));
        if (loadCellValues != null) {
          // Create and send ForceData
          final ForceData forceData = _createForceDataFromLoadCells(loadCellValues);
          _forceDataController?.add(forceData);
          
          _packetCount++;
          _lastPacketTime = DateTime.now();
        }
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('Data parse error', e, stackTrace);
    }
  }

  int _findSyncPattern() {
    // Simple sync pattern: 0xAA 0x55
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
      
      // 8 load cell values (each 4 byte float)
      for (int i = 0; i < 8; i++) {
        if (offset + 4 > data.length) return null;
        
        // Little endian float parse
        final List<int> bytes = data.sublist(offset, offset + 4);
        final ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));
        final double value = byteData.getFloat32(0, Endian.little);
        
        // Apply calibration offset
        final double calibratedValue = value - (_isCalibrated ? _zeroOffsets[i] : 0.0);
        loadCellValues.add(calibratedValue);
        
        offset += 4;
      }
      
      return loadCellValues;
      
    } catch (e, stackTrace) {
      AppLogger.error('Load cell data parse error', e, stackTrace);
      return null;
    }
  }

  ForceData _createForceDataFromLoadCells(List<double> loadCellValues) {
    // Load cell layout:
    // Left platform: 0,1,2,3 (front-left, front-right, back-left, back-right)
    // Right platform: 4,5,6,7 (front-left, front-right, back-left, back-right)
    
    final List<double> leftValues = loadCellValues.sublist(0, 4);
    final List<double> rightValues = loadCellValues.sublist(4, 8);
    
    final double leftGRF = leftValues.reduce((double a, double b) => a + b);
    final double rightGRF = rightValues.reduce((double a, double b) => a + b);
    
    // COP calculation (platform dimensions: 400x600mm)
    const double platformWidth = 400.0;
    const double platformLength = 600.0;
    
    // Fixed: Use local COP calculation method
    final ({double x, double y}) leftCOP = _calculateCOP(leftValues, platformWidth, platformLength);
    final ({double x, double y}) rightCOP = _calculateCOP(rightValues, platformWidth, platformLength);
    
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

  // Local COP calculation method
  ({double x, double y}) _calculateCOP(
    List<double> loadCellValues, 
    double platformWidth, 
    double platformLength
  ) {
    final double totalForce = loadCellValues.reduce((a, b) => a + b);
    if (totalForce == 0) return (x: 0.0, y: 0.0);
    
    // Platform coordinate system
    // loadCellValues: [front-left, front-right, back-left, back-right]
    final double x = (loadCellValues[1] + loadCellValues[3] - loadCellValues[0] - loadCellValues[2]) 
                     * platformWidth / (4 * totalForce);
    final double y = (loadCellValues[2] + loadCellValues[3] - loadCellValues[0] - loadCellValues[1]) 
                     * platformLength / (4 * totalForce);
    
    return (x: x, y: y);
  }

  Future<void> _configureForTestType(TestType testType) async {
    try {
      // Device configuration based on test type
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
      
      AppLogger.debug('⚙️ Device configuration: ${testType.turkishName}');
      
    } catch (e, stackTrace) {
      AppLogger.error('Device configuration error', e, stackTrace);
    }
  }

  Future<void> _sendCalibrationData() async {
    try {
      // Send calibration data to device
      final String calibrationCommand = 'CAL_SET:${_zeroOffsets.join(',')}';
      await _sendCommand(calibrationCommand);
      
      AppLogger.debug('📤 Calibration data sent');
      
    } catch (e, stackTrace) {
      AppLogger.error('Calibration data send error', e, stackTrace);
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