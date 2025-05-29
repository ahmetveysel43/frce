// lib/app/app_controller.dart
import 'package:flutter/foundation.dart';
import '../domain/entities/athlete.dart';
import '../domain/repositories/athlete_repository.dart';

enum AppState {
  loading,
  ready,
  error,
}

enum BluetoothConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class AppController extends ChangeNotifier {
  final AthleteRepository _athleteRepository;

  AppController(this._athleteRepository);

  // State
  AppState _state = AppState.loading;
  String? _errorMessage;
  List<Athlete> _athletes = [];
  BluetoothConnectionState _bluetoothState = BluetoothConnectionState.disconnected;
  int _athleteCount = 0;

  // Getters
  AppState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Athlete> get athletes => _athletes;
  BluetoothConnectionState get bluetoothState => _bluetoothState;
  int get athleteCount => _athleteCount;
  bool get isLoading => _state == AppState.loading;
  bool get hasError => _state == AppState.error;
  bool get isReady => _state == AppState.ready;
  bool get isBluetoothConnected => _bluetoothState == BluetoothConnectionState.connected;

  // Initialize app
  Future<void> initialize() async {
    _setState(AppState.loading);

    try {
      // Mock bluetooth state (gerçek bluetooth repository eklendiğinde değiştirilecek)
      _bluetoothState = BluetoothConnectionState.disconnected;

      // Sporcu sayısını yükle
      await _loadAthleteCount();

      // Son sporcuları yükle (preview için)
      await _loadRecentAthletes();

      _setState(AppState.ready);
    } catch (e) {
      _setError('Uygulama başlatılamadı: $e');
    }
  }

  // Load recent athletes for preview
  Future<void> _loadRecentAthletes() async {
    final result = await _athleteRepository.getRecentlyUpdatedAthletes(5);
    
    result.fold(
      (failure) {
        debugPrint('Recent athletes yüklenemedi: ${failure.message}');
      },
      (athletes) {
        _athletes = athletes;
      },
    );
  }

  // Load athlete count
  Future<void> _loadAthleteCount() async {
    final result = await _athleteRepository.getAthleteCount();
    
    result.fold(
      (failure) {
        debugPrint('Athlete count alınamadı: ${failure.message}');
        _athleteCount = 0;
      },
      (count) {
        _athleteCount = count;
      },
    );
  }

  // Refresh data
  Future<void> refresh() async {
    if (_state == AppState.loading) return;

    try {
      await _loadAthleteCount();
      await _loadRecentAthletes();
      notifyListeners();
    } catch (e) {
      debugPrint('Yenileme hatası: $e');
    }
  }

  // Mock bluetooth connection toggle (test için)
  void toggleBluetoothConnection() {
    if (_bluetoothState == BluetoothConnectionState.connected) {
      _bluetoothState = BluetoothConnectionState.disconnected;
    } else {
      _bluetoothState = BluetoothConnectionState.connected;
    }
    notifyListeners();
  }

  // Private methods
  void _setState(AppState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = AppState.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}