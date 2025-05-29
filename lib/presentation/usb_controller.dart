// lib/presentation/controllers/usb_controller.dart
import 'package:flutter/foundation.dart';
import 'package:izforce/data/repositories/usb_repository.dart';
import '../../domain/entities/force_data.dart';
import '../../core/enums/bluetooth_connection_state.dart';

class UsbController extends ChangeNotifier {
  final UsbRepository _usbRepository;

  UsbController(this._usbRepository);

  // State
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<String> _availableDevices = [];
  String? _connectedDeviceId;
  String? _errorMessage;
  ForceData? _latestForceData;
  
  // Getters
  BluetoothConnectionState get connectionState => _connectionState;
  List<String> get availableDevices => _availableDevices;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get errorMessage => _errorMessage;
  ForceData? get latestForceData => _latestForceData;
  bool get isConnected => _usbRepository.isConnected;
  
  // Real-time data stream
  Stream<ForceData>? get forceDataStream => _usbRepository.realTimeDataStream;

  // Initialize USB system
  Future<bool> initializeUsb() async {
    try {
      _setConnectionState(BluetoothConnectionState.connecting);
      
      final result = await _usbRepository.initialize();
      
      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (success) {
          if (success) {
            _setConnectionState(BluetoothConnectionState.disconnected);
            return true;
          } else {
            _setError('USB initialization failed');
            return false;
          }
        },
      );
    } catch (e) {
      _setError('USB initialization error: $e');
      return false;
    }
  }

  // Scan for available devices
  Future<void> scanForDevices() async {
    try {
      final result = await _usbRepository.getAvailableDevices();
      
      result.fold(
        (failure) => _setError(failure.message),
        (devices) {
          _availableDevices = devices;
          _clearError();
          notifyListeners();
        },
      );
    } catch (e) {
      _setError('Device scan failed: $e');
    }
  }

  // Connect to device
  Future<bool> connectToDevice(String deviceId) async {
    try {
      _setConnectionState(BluetoothConnectionState.connecting);
      
      final result = await _usbRepository.connectToDevice(deviceId);
      
      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (success) {
          if (success) {
            _connectedDeviceId = deviceId;
            _setConnectionState(BluetoothConnectionState.connected);
            _startListeningToForceData();
            return true;
          } else {
            _setError('Connection failed');
            return false;
          }
        },
      );
    } catch (e) {
      _setError('Connection error: $e');
      return false;
    }
  }

  // Start listening to real-time force data
  void _startListeningToForceData() {
    forceDataStream?.listen(
      (forceData) {
        _latestForceData = forceData;
        notifyListeners();
      },
      onError: (error) {
        _setError('Data stream error: $error');
      },
    );
  }

  // Disconnect
  Future<bool> disconnect() async {
    try {
      final result = await _usbRepository.disconnect();
      
      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (_) {
          _connectedDeviceId = null;
          _latestForceData = null;
          _setConnectionState(BluetoothConnectionState.disconnected);
          return true;
        },
      );
    } catch (e) {
      _setError('Disconnect error: $e');
      return false;
    }
  }

  // Helper methods
  void _setConnectionState(BluetoothConnectionState state) {
    _connectionState = state;
    if (state != BluetoothConnectionState.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _connectionState = BluetoothConnectionState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}