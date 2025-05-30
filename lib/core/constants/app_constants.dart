/// izForce - Uygulama sabitleri ve konfigürasyon
class AppConstants {
  AppConstants._();

  // Uygulama bilgileri
  static const String appName = 'izForce';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Türkiye\'nin özgün Force Plate analiz sistemi';
  static const String companyName = 'Turkish Engineering';

  // Database
  static const String databaseName = 'izforce.db';
  static const int databaseVersion = 1;
  
  // Hive boxes
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';
  static const String athleteBox = 'athletes';

  // USB Hardware
  static const int usbVendorId = 0x1234;
  static const int usbProductId = 0x5678;
  static const int baudRate = 115200;
  static const int sampleRate = 1000; // 1000 Hz
  static const int loadCellCount = 8; // 4 per platform

  // Test timing
  static const int maxTestDuration = 60; // seconds
  static const int minTestDuration = 3;
  static const int calibrationDuration = 3;
  static const int weightStabilityDuration = 2;

  // Thresholds
  static const double weightStabilityThreshold = 0.5; // kg
  static const double jumpThreshold = 10.0; // N
  static const double landingThreshold = 50.0; // N
  static const double asymmetryWarningLimit = 10.0; // %

  // File paths
  static const String exportDirectory = 'izforce_exports';
  static const String backupDirectory = 'izforce_backups';
  static const String logDirectory = 'logs';

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Colors (hex)
  static const int primaryColorValue = 0xFF00BCD4;
  static const int accentColorValue = 0xFF4CAF50;
  static const int errorColorValue = 0xFFF44336;
  static const int warningColorValue = 0xFFFF9800;
}

/// Test türleri enum
enum TestType {
  // Sıçrama testleri
  counterMovementJump('CMJ', 'Karşı Hareket Sıçrama'),
  squatJump('SJ', 'Çömelme Sıçraması'),
  dropJump('DJ', 'Düşme Sıçraması'),
  continuousJump('CJ', 'Sürekli Sıçrama'),
  
  // Kuvvet testleri
  isometricMidThighPull('IMTP', 'İzometrik Orta Uyluk Çekişi'),
  isometricSquat('IS', 'İzometrik Çömlek'),
  
  // Denge testleri
  staticBalance('SB', 'Statik Denge'),
  dynamicBalance('DB', 'Dinamik Denge'),
  singleLegBalance('SLB', 'Tek Ayak Denge'),
  
  // Çeviklik testleri
  lateralHop('LH', 'Yanal Sıçrama'),
  anteriorPosteriorHop('APH', 'Ön-Arka Sıçrama'),
  medialLateralHop('MLH', 'İç-Dış Sıçrama');

  const TestType(this.code, this.turkishName);
  final String code;
  final String turkishName;
}

/// Test kategorileri
enum TestCategory {
  jump('Jump', 'Sıçrama'),
  strength('Strength', 'Kuvvet'),
  balance('Balance', 'Denge'),
  agility('Agility', 'Çeviklik');

  const TestCategory(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}

/// Sıçrama fazları
enum JumpPhase {
  quietStanding('Quiet Standing', 'Sakin Duruş'),
  unloading('Unloading', 'Yük Azaltma'),
  braking('Braking', 'Fren'),
  propulsion('Propulsion', 'İtme'),
  flight('Flight', 'Uçuş'),
  landing('Landing', 'İniş');

  const JumpPhase(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}

/// Platform tarafları
enum PlatformSide {
  left('Left', 'Sol'),
  right('Right', 'Sağ'),
  both('Both', 'İkisi');

  const PlatformSide(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}

/// Sporcu cinsiyet
enum Gender {
  male('Male', 'Erkek'),
  female('Female', 'Kadın'),
  other('Other', 'Diğer');

  const Gender(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}

/// Sporcu seviyesi
enum AthleteLevel {
  recreational('Recreational', 'Rekreasyonel'),
  amateur('Amateur', 'Amatör'),
  semipro('Semi-Professional', 'Yarı Profesyonel'),
  professional('Professional', 'Profesyonel'),
  elite('Elite', 'Elite');

  const AthleteLevel(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}

/// Test sonuç durumu
enum TestStatus {
  pending('Pending', 'Bekliyor'),
  running('Running', 'Çalışıyor'),
  completed('Completed', 'Tamamlandı'),
  failed('Failed', 'Başarısız'),
  cancelled('Cancelled', 'İptal Edildi');

  const TestStatus(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}

/// Bağlantı durumu
enum ConnectionStatus {
  disconnected('Disconnected', 'Bağlantı Kesildi'),
  connecting('Connecting', 'Bağlanıyor'),
  connected('Connected', 'Bağlandı'),
  error('Error', 'Hata');

  const ConnectionStatus(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}

/// Metrik kategorileri
class MetricCategories {
  static const List<String> jump = [
    'jumpHeight',
    'flightTime',
    'contactTime',
    'takeoffVelocity',
  ];

  static const List<String> force = [
    'peakForce',
    'averageForce',
    'rfd',
    'impulse',
  ];

  static const List<String> power = [
    'peakPower',
    'averagePower',
    'relativeP ower',
  ];

  static const List<String> asymmetry = [
    'forceAsymmetry',
    'impulseAsymmetry',
    'rfdAsymmetry',
  ];

  static const List<String> balance = [
    'copRange',
    'copVelocity',
    'copArea',
    'stabilityIndex',
  ];
}

/// Varsayılan ayarlar
class DefaultSettings {
  static const String language = 'tr';
  static const bool darkMode = true;
  static const bool soundEnabled = true;
  static const bool vibrationEnabled = true;
  static const bool autoSave = true;
  static const int maxAthletes = 1000;
  static const int maxTestResults = 10000;
  static const bool mockMode = true; // Geliştirme için
}

/// Dosya formatları
enum ExportFormat {
  pdf('PDF', '.pdf'),
  excel('Excel', '.xlsx'),
  csv('CSV', '.csv'),
  json('JSON', '.json');

  const ExportFormat(this.name, this.extension);
  final String name;
  final String extension;
}

/// Hata kodları
class ErrorCodes {
  static const String usbConnectionFailed = 'USB_CONNECTION_FAILED';
  static const String databaseError = 'DATABASE_ERROR';
  static const String testTimeout = 'TEST_TIMEOUT';
  static const String invalidData = 'INVALID_DATA';
  static const String calibrationFailed = 'CALIBRATION_FAILED';
  static const String insufficientData = 'INSUFFICIENT_DATA';
  static const String fileOperationFailed = 'FILE_OPERATION_FAILED';
}