// lib/core/services/usb_serial_service.dart - Tamamen Yeniden Yazılmış
import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/force_data.dart';

class UsbSerialService {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _dataSubscription;
  StreamController<ForceData>? _forceDataController;
  int _sampleIndex = 0;
  
  bool get isConnected => _port != null;
  Stream<ForceData>? get forceDataStream => _forceDataController?.stream;

  Future<bool> initialize() async {
    try {
      // Permission check
      if (!await _requestPermissions()) {
        throw const PermissionException('USB permissions failed');
      }
      
      _forceDataController = StreamController<ForceData>.broadcast();
      return true;
    } catch (e) {
      throw BluetoothException('USB Serial initialization failed: $e');
    }
  }

  Future<List<UsbDevice>> getAvailableDevices() async {
    return await UsbSerial.listDevices();
  }

  Future<bool> connectToDevice(UsbDevice device) async {
    try {
      _port = await device.create();
      
      if (_port == null) {
        throw const BluetoothException('Port creation failed');
      }

      // Optimal USB Serial settings for 1000Hz
      await _port!.open();
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        115200, // Baud rate - sufficient for 1000Hz
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _startDataListening();
      return true;
    } catch (e) {
      throw BluetoothException('Device connection failed: $e');
    }
  }

  void _startDataListening() {
    _dataSubscription = _port!.inputStream?.listen(
      _processRawData,
      onError: (error) {
        throw DataProcessingException('Data reading error: $error');
      },
    );
  }

  void _processRawData(Uint8List data) {
    try {
      // 8 load cell (4 left + 4 right) x 4 byte = 32 byte per sample
      // + timestamp (8 byte) = 40 byte total per sample
      const int bytesPerSample = 40;
      
      for (int i = 0; i <= data.length - bytesPerSample; i += bytesPerSample) {
        final sampleData = data.sublist(i, i + bytesPerSample);
        final forceData = _parseForceData(sampleData);
        
        if (forceData != null) {
          _forceDataController?.add(forceData);
        }
      }
    } catch (e) {
      throw DataProcessingException('Raw data processing failed: $e');
    }
  }

  ForceData? _parseForceData(Uint8List rawData) {
    try {
      final byteData = ByteData.sublistView(rawData);
      
      // Timestamp (first 8 bytes)
      final timestampMs = byteData.getUint64(0, Endian.little);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      
      // Load cell values (8 x 4 byte = 32 byte)
      final leftDeckForces = <double>[];
      final rightDeckForces = <double>[];
      
      // Left platform load cells (offset 8-24)
      for (int i = 0; i < 4; i++) {
        final rawValue = byteData.getInt32(8 + (i * 4), Endian.little);
        final force = _convertRawToForce(rawValue);
        leftDeckForces.add(force);
      }
      
      // Right platform load cells (offset 24-40)
      for (int i = 0; i < 4; i++) {
        final rawValue = byteData.getInt32(24 + (i * 4), Endian.little);
        final force = _convertRawToForce(rawValue);
        rightDeckForces.add(force);
      }
      
      // Calculate required parameters from raw load cells
      final leftGRF = leftDeckForces.reduce((a, b) => a + b);   // Total left force
      final rightGRF = rightDeckForces.reduce((a, b) => a + b); // Total right force
      final totalGRF = leftGRF + rightGRF;                      // Total force
      
      // Calculate Center of Pressure
      final leftCoPX = _calculateCoPX(leftDeckForces);   // Center of Pressure X
      final leftCoPY = _calculateCoPY(leftDeckForces);   // Center of Pressure Y
      final rightCoPX = _calculateCoPX(rightDeckForces); // Center of Pressure X
      final rightCoPY = _calculateCoPY(rightDeckForces); // Center of Pressure Y
      
      // Calculate metrics
      final asymmetryIndex = totalGRF > 0 ? (leftGRF - rightGRF).abs() / totalGRF : 0.0;
      final stabilityIndex = 0.8; // Placeholder - real calculation needs multiple samples
      final loadRate = 0.0;       // Placeholder - real calculation needs time derivative
      
      // FIXED ForceData constructor with ALL required parameters
      return ForceData(
        timestamp: timestamp,
        
        // Required parameters
        leftGRF: leftGRF,
        leftCoPX: leftCoPX,
        leftCoPY: leftCoPY,
        rightGRF: rightGRF,
        rightCoPX: rightCoPX,
        rightCoPY: rightCoPY,
        totalGRF: totalGRF,
        asymmetryIndex: asymmetryIndex,
        stabilityIndex: stabilityIndex,
        loadRate: loadRate,
        
        // Optional parameters
        leftDeckForces: leftDeckForces,
        rightDeckForces: rightDeckForces,
        samplingRate: 1000.0,
        sampleIndex: _sampleIndex++,
      );
    } catch (e) {
      return null; // Ignore corrupt data
    }
  }

  // Center of Pressure hesaplama metodları
  double _calculateCoPX(List<double> loadCellForces) {
    if (loadCellForces.length != 4) return 0.0;
    
    // Load cell X positions (example for 40x60cm platform)
    // [front-left, front-right, back-left, back-right]
    const positions = [-100.0, 100.0, -100.0, 100.0]; // mm
    
    final totalForce = loadCellForces.reduce((a, b) => a + b);
    if (totalForce == 0) return 0.0;
    
    double momentX = 0.0;
    for (int i = 0; i < 4; i++) {
      momentX += loadCellForces[i] * positions[i];
    }
    
    return momentX / totalForce; // mm
  }

  double _calculateCoPY(List<double> loadCellForces) {
    if (loadCellForces.length != 4) return 0.0;
    
    // Load cell Y positions (example)
    // [front-left, front-right, back-left, back-right] 
    const positions = [150.0, 150.0, -150.0, -150.0]; // mm
    
    final totalForce = loadCellForces.reduce((a, b) => a + b);
    if (totalForce == 0) return 0.0;
    
    double momentY = 0.0;
    for (int i = 0; i < 4; i++) {
      momentY += loadCellForces[i] * positions[i];
    }
    
    return momentY / totalForce; // mm
  }

  double _convertRawToForce(int rawValue) {
    // 24-bit ADC: -8,388,608 to 8,388,607
    // C4 Load Cell: ±50kg (±500N) nominal
    const double maxForce = 500.0; // Newton
    const int maxRawValue = 8388607;
    
    return (rawValue / maxRawValue) * maxForce;
  }

  Future<bool> startCalibration() async {
    if (!isConnected) return false;
    
    try {
      // Send calibration command
      const command = 'CAL_START\n';
      await _port!.write(Uint8List.fromList(command.codeUnits));
      
      // Wait for calibration response (simplified)
      await Future.delayed(const Duration(seconds: 5));
      return true;
    } catch (e) {
      throw CalibrationException('Calibration failed: $e');
    }
  }

  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    await _port?.close();
    _port = null;
    await _forceDataController?.close();
    _sampleIndex = 0;
  }

  Future<bool> _requestPermissions() async {
    // Android USB permissions
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  void dispose() {
    disconnect();
  }
}