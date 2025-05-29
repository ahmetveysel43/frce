// lib/data/services/usb_serial_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/force_data.dart';

class UsbSerialService {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _dataSubscription; // ✅ Uint8List olarak düzeltildi
  StreamController<ForceData>? _forceDataController;
  
  bool get isConnected => _port != null;
  Stream<ForceData>? get forceDataStream => _forceDataController?.stream;

  // C4 Load Cell kalibrasyonu (her sensör için)
// mV/V
// V
// bit
  
  Future<bool> initialize() async {
    try {
      // Permission kontrolü
      if (!await _requestPermissions()) {
        throw const PermissionException('USB izinleri alınamadı');
      }
      
      _forceDataController = StreamController<ForceData>.broadcast();
      return true;
    } catch (e) {
      throw BluetoothException('USB Serial başlatılamadı: $e');
    }
  }

  Future<List<UsbDevice>> getAvailableDevices() async {
    return await UsbSerial.listDevices();
  }

  Future<bool> connectToDevice(UsbDevice device) async {
    try {
      _port = await device.create();
      
      if (_port == null) {
        throw const BluetoothException('Port oluşturulamadı');
      }

      // 1000Hz için optimal USB Serial ayarları
      await _port!.open();
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        115200, // Baud rate - 1000Hz için yeterli
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _startDataListening();
      return true;
    } catch (e) {
      throw BluetoothException('Cihaza bağlanılamadı: $e');
    }
  }

  void _startDataListening() {
    _dataSubscription = _port!.inputStream?.listen(
      _processRawData,
      onError: (error) {
        throw DataProcessingException('Veri okuma hatası: $error');
      },
    );
  }

  void _processRawData(Uint8List data) {
    try {
      // 8 load cell (4 sol + 4 sağ) x 4 byte = 32 byte per sample
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
      throw DataProcessingException('Ham veri işlenemedi: $e');
    }
  }

  ForceData? _parseForceData(Uint8List rawData) {
    try {
      final byteData = ByteData.sublistView(rawData);
      
      // Timestamp (ilk 8 byte)
      final timestampMs = byteData.getUint64(0, Endian.little);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      
      // Load cell değerleri (8 x 4 byte = 32 byte)
      final leftForces = <double>[];
      final rightForces = <double>[];
      
      // Sol platform load cell'leri (offset 8-24)
      for (int i = 0; i < 4; i++) {
        final rawValue = byteData.getInt32(8 + (i * 4), Endian.little);
        final force = _convertRawToForce(rawValue);
        leftForces.add(force);
      }
      
      // Sağ platform load cell'leri (offset 24-40)
      for (int i = 0; i < 4; i++) {
        final rawValue = byteData.getInt32(24 + (i * 4), Endian.little);
        final force = _convertRawToForce(rawValue);
        rightForces.add(force);
      }
      
      return ForceData(
        timestamp: timestamp,
        leftPlateForces: leftForces,
        rightPlateForces: rightForces,
        samplingRate: AppConstants.samplingRate.toDouble(),
        sampleIndex: 0, // Gerçek implementasyonda counter olacak
      );
    } catch (e) {
      return null; // Corrupt data ignore
    }
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
      // Kalibrasyon komutu gönder
      const command = 'CAL_START\n'; // ✅ const olarak düzeltildi
      await _port!.write(Uint8List.fromList(command.codeUnits));
      
      // Kalibrasyon yanıtı bekle (basitleştirilmiş)
      await Future.delayed(const Duration(seconds: 5));
      return true;
    } catch (e) {
      throw CalibrationException('Kalibrasyon başarısız: $e');
    }
  }

  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    await _port?.close();
    _port = null;
    await _forceDataController?.close();
  }

  Future<bool> _requestPermissions() async {
    // Android için USB permissions
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  void dispose() {
    disconnect();
  }
}