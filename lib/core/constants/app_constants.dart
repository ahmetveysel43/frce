class AppConstants {
  // Uygulama Bilgileri
  static const String appName = 'IzForce';
  static const String appVersion = '1.0.0';
  
  // Force Platform Ayarları
  static const int samplingRate = 1000; // Hz
  static const int loadCellCount = 8; // 4 sağ + 4 sol
  static const int plateCount = 2; // Sol ve sağ platform
  
  // Test Parametreleri
  static const Duration maxTestDuration = Duration(minutes: 5);
  static const Duration minTestDuration = Duration(seconds: 3);
  static const double noiseThreshold = 5.0; // Newton
  
  // Bluetooth Ayarları
  static const Duration bluetoothTimeout = Duration(seconds: 10);
  static const Duration reconnectInterval = Duration(seconds: 2);
  static const int maxReconnectAttempts = 5;
  
  // Veri İşleme
  static const int bufferSize = 1000; // Samples
  static const double filterCutoffFrequency = 40.0; // Hz
  
  // Private constructor (utility class)
  AppConstants._();
}