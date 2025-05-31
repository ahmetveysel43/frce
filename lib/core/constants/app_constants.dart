import 'dart:math' as math;

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

/// Test türleri enum - DÜZELTME: category property eklendi
enum TestType {
  // Sıçrama testleri
  counterMovementJump('CMJ', 'Karşı Hareket Sıçrama', TestCategory.jump),
  squatJump('SJ', 'Çömelme Sıçraması', TestCategory.jump),
  dropJump('DJ', 'Düşme Sıçraması', TestCategory.jump),
  continuousJump('CJ', 'Sürekli Sıçrama', TestCategory.jump),
  
  // Kuvvet testleri
  isometricMidThighPull('IMTP', 'İzometrik Orta Uyluk Çekişi', TestCategory.strength),
  isometricSquat('IS', 'İzometrik Çömlek', TestCategory.strength),
  
  // Denge testleri
  staticBalance('SB', 'Statik Denge', TestCategory.balance),
  dynamicBalance('DB', 'Dinamik Denge', TestCategory.balance),
  singleLegBalance('SLB', 'Tek Ayak Denge', TestCategory.balance),
  
  // Çeviklik testleri
  lateralHop('LH', 'Yanal Sıçrama', TestCategory.agility),
  anteriorPosteriorHop('APH', 'Ön-Arka Sıçrama', TestCategory.agility),
  medialLateralHop('MLH', 'İç-Dış Sıçrama', TestCategory.agility);

  const TestType(this.code, this.turkishName, this.category);
  final String code;
  final String turkishName;
  final TestCategory category; // ✅ EKLENEN PROPERTY
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
    'relativePower', // ✅ DÜZELTME: Space kaldırıldı
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

/// Test constants - DÜZELTME: Broken syntax düzeltildi
class TestConstants {
  TestConstants._();

  // Gravity
  static const double gravity = 9.81; // m/s²

  // Platform dimensions (mm)
  static const double platformWidth = 400.0;
  static const double platformHeight = 600.0;
  static const double platformThickness = 100.0;

  // Force plate specifications
  static const double maxForce = 10000.0; // N
  static const double resolution = 0.1; // N
  static const double accuracy = 0.5; // %

  // Sampling
  static const int sampleRate = 1000; // Hz
  static const int bufferSize = 4096;

  // Signal processing
  static const double filterCutoff = 50.0; // Hz
  static const int filterOrder = 4;

  // Jump detection thresholds
  static const double jumpThreshold = 10.0; // N
  static const double landingThreshold = 50.0; // N
  static const double quietThreshold = 5.0; // N

  // Phase detection parameters
  static const double weightThreshold = 0.9; // Body weight ratio
  static const double takeoffVelocityThreshold = 0.1; // m/s
  static const double landingVelocityThreshold = -0.1; // m/s

  // Timing parameters
  static const Duration minQuietTime = Duration(milliseconds: 500);
  static const Duration maxTestDuration = Duration(seconds: 60);
  static const Duration stabilizationTime = Duration(seconds: 2);

  // Filtering parameters
  static final Map<String, dynamic> butterworthParams = {
    'order': 4,
    'cutoff': 50.0,
    'type': 'lowpass',
  };

  // Test-specific parameters
  static const Map<TestType, Map<String, dynamic>> testParameters = {
    TestType.counterMovementJump: {
      'minDepth': 0.1, // m
      'maxDepth': 0.8, // m
      'timeLimit': 10.0, // seconds
    },
    TestType.squatJump: {
      'holdTime': 2.0, // seconds
      'timeLimit': 8.0, // seconds
    },
    TestType.dropJump: {
      'dropHeight': 0.3, // m
      'contactTimeLimit': 0.25, // seconds
    },
  };

  // Calculation constants
  static const double pi = math.pi;
  static const double e = math.e;
  static const double sqrt2 = 1.4142135623730951;
}