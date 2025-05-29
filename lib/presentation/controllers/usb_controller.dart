// lib/presentation/controllers/usb_controller.dart - Eksik özellikler eklendi
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/mock_usb_service.dart';
import '../../core/services/usb_serial_service.dart';
import '../../domain/entities/force_data.dart';
import '../../core/enums/usb_connection_state.dart';

class UsbController extends ChangeNotifier {
  // Services
  MockUsbService? _mockUsbService;
  UsbSerialService? _usbSerialService;
  StreamSubscription<ForceData>? _dataSubscription;
  
  // State
  bool _isConnected = false;
  String? _connectedDeviceId;
  ForceData? _latestForceData;
  String? _errorMessage;
  List<String> _availableDevices = [];
  String _currentTestScenario = 'sakin_durus'; // ✅ Eklendi
  
  // Connection state tracking
  UsbConnectionState _connectionState = UsbConnectionState.disconnected;
  
  // Getters
  bool get isConnected => _isConnected;
  String? get connectedDeviceId => _connectedDeviceId;
  ForceData? get latestForceData => _latestForceData;
  String? get errorMessage => _errorMessage;
  List<String> get availableDevices => _availableDevices;
  UsbConnectionState get connectionState => _connectionState;
  String get currentTestScenario => _currentTestScenario; // ✅ Eklendi
  
  // ✅ Eksik getter - Data akışı kontrolü
  bool get isDataFlowing => _isConnected && _latestForceData != null;
  
  // ✅ Data stream status
  bool get hasRecentData {
    if (_latestForceData == null) return false;
    final now = DateTime.now();
    final dataAge = now.difference(_latestForceData!.timestamp);
    return dataAge.inSeconds < 2; // Son 2 saniyede veri var mı?
  }

  // Initialization
  Future<void> initialize() async {
    try {
      _mockUsbService = MockUsbService();
      _usbSerialService = UsbSerialService();
      
      await _mockUsbService!.initialize();
      await _usbSerialService!.initialize();
      
      await _scanForDevices();
      
      debugPrint('🔌 USB Controller initialized successfully');
    } catch (e) {
      _errorMessage = 'Initialization failed: $e';
      debugPrint('❌ USB Controller initialization error: $e');
      notifyListeners();
    }
  }

  // Scan for available devices
  Future<void> _scanForDevices() async {
    try {
      final mockDevices = await _mockUsbService!.getAvailableDevices();
      final realDevices = await _usbSerialService!.getAvailableDevices();
      
      _availableDevices = [
        ...mockDevices,
        ...realDevices.map((device) => device.toString()),
      ];
      
      debugPrint('📱 Found ${_availableDevices.length} available devices');
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Device scan error: $e');
    }
  }

  // Connect to device
  Future<bool> connectToDevice(String deviceId) async {
    try {
      _setConnectionState(UsbConnectionState.connecting);
      _errorMessage = null;
      
      bool success = false;
      
      // Try mock service first (for testing)
      if (deviceId.contains('Mock') || deviceId.contains('IzForce')) {
        success = await _mockUsbService!.connectToDevice(deviceId);
        if (success) {
          _startMockDataStream();
        }
      } else {
        // Try real USB serial connection
        // success = await _usbSerialService!.connectToDevice(deviceId);
        // if (success) {
        //   _startRealDataStream();
        // }
      }
      
      if (success) {
        _isConnected = true;
        _connectedDeviceId = deviceId;
        _setConnectionState(UsbConnectionState.connected);
        debugPrint('✅ Connected to device: $deviceId');
      } else {
        _setConnectionState(UsbConnectionState.error);
        _errorMessage = 'Connection failed';
        debugPrint('❌ Connection failed: $deviceId');
      }
      
      return success;
    } catch (e) {
      _setConnectionState(UsbConnectionState.error);
      _errorMessage = 'Connection error: $e';
      debugPrint('💥 Connection error: $e');
      return false;
    }
  }

  // ✅ Test senaryosu değiştirme method'u
  void changeTestScenario(String scenario) {
    if (!_isConnected) {
      debugPrint('⚠️ Cannot change scenario: Not connected');
      return;
    }
    
    _currentTestScenario = scenario;
    debugPrint('📊 Test senaryosu değiştirildi: $scenario');
    
    // Mock service'e senaryo değişikliği gönder
    try {
      _mockUsbService?.changeScenario(scenario);
    } catch (e) {
      debugPrint('⚠️ Scenario change error: $e');
    }
    
    // UI'yi güncelle
    notifyListeners();
  }

  // Start mock data stream
  void _startMockDataStream() {
    final stream = _mockUsbService!.forceDataStream;
    if (stream != null) {
      _dataSubscription = stream.listen(
        (forceData) {
          _latestForceData = forceData;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Data stream error: $error';
          debugPrint('📊 Data stream error: $error');
          notifyListeners();
        },
      );
      debugPrint('📊 Mock data stream started');
    }
  }

  // Start real data stream (placeholder)

  // Disconnect
  Future<void> disconnect() async {
    try {
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      
      if (_mockUsbService != null) {
        await _mockUsbService!.disconnect();
      }
      
      if (_usbSerialService != null) {
        await _usbSerialService!.disconnect();
      }
      
      _isConnected = false;
      _connectedDeviceId = null;
      _latestForceData = null;
      _errorMessage = null;
      _currentTestScenario = 'sakin_durus'; // Reset to default
      _setConnectionState(UsbConnectionState.disconnected);
      
      debugPrint('🔌 Disconnected from USB device');
    } catch (e) {
      _errorMessage = 'Disconnect error: $e';
      debugPrint('💥 Disconnect error: $e');
      notifyListeners();
    }
  }

  // ✅ Connection state helper
  void _setConnectionState(UsbConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }

  // ✅ Manual refresh devices
  Future<void> refreshDevices() async {
    debugPrint('🔄 Refreshing device list...');
    await _scanForDevices();
  }

  // ✅ Get connection status text
  String get connectionStatusText {
    switch (_connectionState) {
      case UsbConnectionState.connected:
        return 'Bağlandı';
      case UsbConnectionState.connecting:
        return 'Bağlanıyor...';
      case UsbConnectionState.disconnected:
        return 'Bağlantı Kesildi';
      case UsbConnectionState.error:
        return 'Bağlantı Hatası';
    }
  }

  // ✅ Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ✅ Get data quality score
  double get dataQualityScore {
    if (_latestForceData == null) return 0.0;
    
    // Simple quality calculation
    if (!hasRecentData) return 0.0;
    if (_latestForceData!.totalGRF < 0) return 0.5;
    if (_latestForceData!.asymmetryIndex > 0.5) return 0.7;
    
    return 1.0; // Perfect quality
  }

  // ✅ Get sampling rate info
  String get samplingRateText {
    if (!_isConnected) return 'Bağlantı Yok';
    if (!isDataFlowing) return 'Veri Bekleniyor';
    
    final rate = _latestForceData?.samplingRate ?? 1000.0;
    return '${rate.toInt()} Hz';
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _mockUsbService?.dispose();
    _usbSerialService?.dispose();
    super.dispose();
  }
}