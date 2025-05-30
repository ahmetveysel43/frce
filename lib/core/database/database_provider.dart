import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/app_logger.dart';
import '../constants/app_constants.dart';

/// Database provider - Singleton pattern ile database yönetimi
/// Repository pattern'den farklı olarak, sadece database connection ve migration management
class DatabaseProvider {
  static final DatabaseProvider _instance = DatabaseProvider._internal();
  static Database? _database;
  static bool _isInitialized = false;

  factory DatabaseProvider() => _instance;
  DatabaseProvider._internal();

  /// Singleton instance
  static DatabaseProvider get instance => _instance;

  /// Database getter - lazy initialization
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    
    _database = await _initializeDatabase();
    return _database!;
  }

  /// Database başlatma durumu
  bool get isInitialized => _isInitialized;

  /// Database yolu
  Future<String> get databasePath async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, AppConstants.databaseName);
  }

  /// Database boyutu
  Future<int> get databaseSize async {
    try {
      final path = await databasePath;
      final file = File(path);
      
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      AppLogger.error('Database boyutu alınamadı: $e');
      return 0;
    }
  }

  /// Database'i başlat
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug('Database zaten başlatılmış');
      return;
    }

    try {
      AppLogger.info('🗄️ Database provider başlatılıyor...');
      
      _database = await _initializeDatabase();
      _isInitialized = true;
      
      AppLogger.success('✅ Database provider başlatıldı');
      
      // Database bilgilerini logla
      await _logDatabaseInfo();
      
    } catch (e, stackTrace) {
      AppLogger.error('Database provider başlatma hatası', e, stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  /// Database'i oluştur ve konfigüre et
  Future<Database> _initializeDatabase() async {
    try {
      final path = await databasePath;
      
      // Database dizinini oluştur
      final databaseDirectory = Directory(dirname(path));
      if (!await databaseDirectory.exists()) {
        await databaseDirectory.create(recursive: true);
      }

      AppLogger.debug('Database yolu: $path');

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: _onDowngrade,
        onConfigure: _onConfigure,
        onOpen: _onOpen,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Database initialization error', e, stackTrace);
      rethrow;
    }
  }

  /// Database konfigürasyonu
  Future<void> _onConfigure(Database db) async {
    try {
      AppLogger.debug('Database konfigüre ediliyor...');
      
      // Foreign key constraints'i aktif et
      await db.execute('PRAGMA foreign_keys = ON');
      
      // Journal mode WAL (Write-Ahead Logging) - daha iyi performans
      await db.execute('PRAGMA journal_mode = WAL');
      
      // Synchronous mode NORMAL - denge performans/güvenlik
      await db.execute('PRAGMA synchronous = NORMAL');
      
      // Cache size artır (10MB)
      await db.execute('PRAGMA cache_size = 10000');
      
      // Temp store memory'de tut
      await db.execute('PRAGMA temp_store = MEMORY');
      
      // Mmap size (64MB) - memory mapped I/O
      await db.execute('PRAGMA mmap_size = 67108864');
      
      AppLogger.debug('Database PRAGMA ayarları uygulandı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Database konfigürasyon hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Database ilk oluşturma
  Future<void> _onCreate(Database db, int version) async {
    try {
      AppLogger.info('📊 Database tabloları oluşturuluyor (v$version)...');
      
      final batch = db.batch();
      
      // Athletes tablosu
      batch.execute('''
        CREATE TABLE athletes (
          id TEXT PRIMARY KEY,
          firstName TEXT NOT NULL,
          lastName TEXT NOT NULL,
          email TEXT UNIQUE,
          dateOfBirth TEXT,
          gender TEXT,
          height REAL,
          weight REAL,
          sport TEXT,
          position TEXT,
          level TEXT,
          notes TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          isActive INTEGER DEFAULT 1,
          
          -- Constraints
          CHECK (height IS NULL OR (height >= 50 AND height <= 250)),
          CHECK (weight IS NULL OR (weight >= 20 AND weight <= 300)),
          CHECK (isActive IN (0, 1))
        )
      ''');

      // Test sessions tablosu
      batch.execute('''
        CREATE TABLE test_sessions (
          id TEXT PRIMARY KEY,
          athleteId TEXT NOT NULL,
          testType TEXT NOT NULL,
          testDate TEXT NOT NULL,
          duration INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          notes TEXT,
          createdAt TEXT NOT NULL,
          
          -- Foreign key
          FOREIGN KEY (athleteId) REFERENCES athletes (id) ON DELETE CASCADE,
          
          -- Constraints
          CHECK (duration >= 0),
          CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled'))
        )
      ''');

      // Force data tablosu (ham kuvvet verileri)
      batch.execute('''
        CREATE TABLE force_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sessionId TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          leftGRF REAL NOT NULL DEFAULT 0,
          rightGRF REAL NOT NULL DEFAULT 0,
          totalGRF REAL NOT NULL DEFAULT 0,
          leftCOP_x REAL,
          leftCOP_y REAL,
          rightCOP_x REAL,
          rightCOP_y REAL,
          
          -- Foreign key
          FOREIGN KEY (sessionId) REFERENCES test_sessions (id) ON DELETE CASCADE,
          
          -- Constraints
          CHECK (leftGRF >= 0),
          CHECK (rightGRF >= 0),
          CHECK (totalGRF >= 0)
        )
      ''');

      // Test results tablosu (hesaplanmış metrikler)
      batch.execute('''
        CREATE TABLE test_results (
          id TEXT PRIMARY KEY,
          sessionId TEXT NOT NULL,
          metricName TEXT NOT NULL,
          metricValue REAL NOT NULL,
          unit TEXT,
          category TEXT,
          calculatedAt TEXT NOT NULL,
          
          -- Foreign key
          FOREIGN KEY (sessionId) REFERENCES test_sessions (id) ON DELETE CASCADE,
          
          -- Unique constraint
          UNIQUE (sessionId, metricName)
        )
      ''');

      // Settings tablosu
      batch.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          dataType TEXT DEFAULT 'string',
          description TEXT,
          updatedAt TEXT NOT NULL,
          
          -- Constraints
          CHECK (dataType IN ('string', 'number', 'boolean', 'json'))
        )
      ''');

      // Calibrations tablosu
      batch.execute('''
        CREATE TABLE calibrations (
          id TEXT PRIMARY KEY,
          deviceId TEXT NOT NULL,
          leftZeroOffset REAL NOT NULL DEFAULT 0,
          rightZeroOffset REAL NOT NULL DEFAULT 0,
          leftGain REAL DEFAULT 1.0,
          rightGain REAL DEFAULT 1.0,
          calibrationDate TEXT NOT NULL,
          expiryDate TEXT,
          isActive INTEGER DEFAULT 1,
          notes TEXT,
          
          -- Constraints
          CHECK (isActive IN (0, 1)),
          CHECK (leftGain > 0),
          CHECK (rightGain > 0)
        )
      ''');

      // User sessions tablosu (login tracking)
      batch.execute('''
        CREATE TABLE user_sessions (
          id TEXT PRIMARY KEY,
          deviceInfo TEXT,
          appVersion TEXT,
          startTime TEXT NOT NULL,
          endTime TEXT,
          isActive INTEGER DEFAULT 1,
          
          -- Constraints
          CHECK (isActive IN (0, 1))
        )
      ''');

      // Database metadata tablosu
      batch.execute('''
        CREATE TABLE database_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');

      // Commit batch
      await batch.commit(noResult: true);
      
      // Index'leri oluştur
      await _createIndexes(db);
      
      // Trigger'ları oluştur
      await _createTriggers(db);
      
      // Varsayılan verileri ekle
      await _insertDefaultData(db);
      
      // Metadata'yı güncelle
      await _updateDatabaseMetadata(db, version);
      
      AppLogger.success('✅ Database tabloları oluşturuldu');
      
    } catch (e, stackTrace) {
      AppLogger.error('Database creation error', e, stackTrace);
      rethrow;
    }
  }

  /// Index'leri oluştur
  Future<void> _createIndexes(Database db) async {
    try {
      AppLogger.debug('Database index\'leri oluşturuluyor...');
      
      final indexQueries = [
        // Athletes indexes
        'CREATE INDEX idx_athletes_email ON athletes(email)',
        'CREATE INDEX idx_athletes_sport ON athletes(sport)',
        'CREATE INDEX idx_athletes_level ON athletes(level)',
        'CREATE INDEX idx_athletes_active ON athletes(isActive)',
        'CREATE INDEX idx_athletes_created ON athletes(createdAt)',
        
        // Test sessions indexes
        'CREATE INDEX idx_test_sessions_athlete ON test_sessions(athleteId)',
        'CREATE INDEX idx_test_sessions_type ON test_sessions(testType)',
        'CREATE INDEX idx_test_sessions_date ON test_sessions(testDate)',
        'CREATE INDEX idx_test_sessions_status ON test_sessions(status)',
        
        // Force data indexes
        'CREATE INDEX idx_force_data_session ON force_data(sessionId)',
        'CREATE INDEX idx_force_data_timestamp ON force_data(timestamp)',
        'CREATE INDEX idx_force_data_session_timestamp ON force_data(sessionId, timestamp)',
        
        // Test results indexes
        'CREATE INDEX idx_test_results_session ON test_results(sessionId)',
        'CREATE INDEX idx_test_results_metric ON test_results(metricName)',
        'CREATE INDEX idx_test_results_category ON test_results(category)',
        'CREATE INDEX idx_test_results_session_metric ON test_results(sessionId, metricName)',
        
        // Calibrations indexes
        'CREATE INDEX idx_calibrations_device ON calibrations(deviceId)',
        'CREATE INDEX idx_calibrations_active ON calibrations(isActive)',
        'CREATE INDEX idx_calibrations_date ON calibrations(calibrationDate)',
      ];
      
      for (final query in indexQueries) {
        await db.execute(query);
      }
      
      AppLogger.debug('${indexQueries.length} index oluşturuldu');
      
    } catch (e, stackTrace) {
      AppLogger.error('Index creation error', e, stackTrace);
      rethrow;
    }
  }

  /// Trigger'ları oluştur
  Future<void> _createTriggers(Database db) async {
    try {
      AppLogger.debug('Database trigger\'ları oluşturuluyor...');
      
      // Athletes updatedAt trigger
      await db.execute('''
        CREATE TRIGGER athletes_updated_at 
        AFTER UPDATE ON athletes
        BEGIN
          UPDATE athletes SET updatedAt = datetime('now') WHERE id = NEW.id;
        END
      ''');
      
      // Auto-calculate totalGRF trigger
      await db.execute('''
        CREATE TRIGGER force_data_total_grf
        BEFORE INSERT ON force_data
        BEGIN
          UPDATE force_data SET totalGRF = NEW.leftGRF + NEW.rightGRF 
          WHERE id = NEW.id;
        END
      ''');
      
      // Settings updatedAt trigger
      await db.execute('''
        CREATE TRIGGER settings_updated_at 
        AFTER UPDATE ON settings
        BEGIN
          UPDATE settings SET updatedAt = datetime('now') WHERE key = NEW.key;
        END
      ''');
      
      AppLogger.debug('Trigger\'lar oluşturuldu');
      
    } catch (e, stackTrace) {
      AppLogger.error('Trigger creation error', e, stackTrace);
      // Trigger hatası kritik değil, devam et
      AppLogger.warning('Trigger\'lar oluşturulamadı ama devam ediliyor');
    }
  }

  /// Varsayılan verileri ekle
  Future<void> _insertDefaultData(Database db) async {
    try {
      AppLogger.debug('Varsayılan veriler ekleniyor...');
      
      final batch = db.batch();
      final timestamp = DateTime.now().toIso8601String();
      
      // Default settings
      final defaultSettings = {
        'app_language': DefaultSettings.language,
        'dark_mode': DefaultSettings.darkMode.toString(),
        'sound_enabled': DefaultSettings.soundEnabled.toString(),
        'vibration_enabled': DefaultSettings.vibrationEnabled.toString(),
        'auto_save': DefaultSettings.autoSave.toString(),
        'mock_mode': DefaultSettings.mockMode.toString(),
        'sample_rate': AppConstants.sampleRate.toString(),
        'max_test_duration': AppConstants.maxTestDuration.toString(),
        'jump_threshold': AppConstants.jumpThreshold.toString(),
        'asymmetry_warning_limit': AppConstants.asymmetryWarningLimit.toString(),
      };
      
      for (final entry in defaultSettings.entries) {
        batch.insert('settings', {
          'key': entry.key,
          'value': entry.value,
          'dataType': _inferDataType(entry.value),
          'description': _getSettingDescription(entry.key),
          'updatedAt': timestamp,
        });
      }
      
      // Database version info
      batch.insert('database_metadata', {
        'key': 'version',
        'value': AppConstants.databaseVersion.toString(),
        'updatedAt': timestamp,
      });
      
      batch.insert('database_metadata', {
        'key': 'created_at',
        'value': timestamp,
        'updatedAt': timestamp,
      });
      
      batch.insert('database_metadata', {
        'key': 'last_migration',
        'value': AppConstants.databaseVersion.toString(),
        'updatedAt': timestamp,
      });
      
      await batch.commit(noResult: true);
      AppLogger.debug('Varsayılan veriler eklendi');
      
    } catch (e, stackTrace) {
      AppLogger.error('Default data insertion error', e, stackTrace);
      rethrow;
    }
  }

  String _inferDataType(String value) {
    if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
      return 'boolean';
    }
    
    if (double.tryParse(value) != null) {
      return 'number';
    }
    
    if (value.startsWith('{') || value.startsWith('[')) {
      return 'json';
    }
    
    return 'string';
  }

  String _getSettingDescription(String key) {
    switch (key) {
      case 'app_language':
        return 'Uygulama dili (tr/en)';
      case 'dark_mode':
        return 'Karanlık tema aktif/pasif';
      case 'sound_enabled':
        return 'Ses efektleri aktif/pasif';
      case 'vibration_enabled':
        return 'Titreşim geri bildirimi aktif/pasif';
      case 'auto_save':
        return 'Otomatik kaydetme aktif/pasif';
      case 'mock_mode':
        return 'Simülasyon modu aktif/pasif';
      case 'sample_rate':
        return 'Örnekleme hızı (Hz)';
      case 'max_test_duration':
        return 'Maksimum test süresi (saniye)';
      case 'jump_threshold':
        return 'Sıçrama algılama eşiği (N)';
      case 'asymmetry_warning_limit':
        return 'Asimetri uyarı sınırı (%)';
      default:
        return 'Ayar açıklaması mevcut değil';
    }
  }

  /// Database version güncelle
  Future<void> _updateDatabaseMetadata(Database db, int version) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      
      await db.insert('database_metadata', {
        'key': 'current_version',
        'value': version.toString(),
        'updatedAt': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      
    } catch (e, stackTrace) {
      AppLogger.error('Metadata update error', e, stackTrace);
    }
  }

  /// Database upgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      AppLogger.info('🔄 Database upgrade: v$oldVersion -> v$newVersion');
      
      // Version-specific migrations
      for (int version = oldVersion + 1; version <= newVersion; version++) {
        await _runMigration(db, version);
      }
      
      // Metadata güncelle
      await _updateDatabaseMetadata(db, newVersion);
      
      AppLogger.success('✅ Database upgrade tamamlandı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Database upgrade error', e, stackTrace);
      rethrow;
    }
  }

  /// Database downgrade (normalde olmamalı)
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.warning('⚠️ Database downgrade: v$oldVersion -> v$newVersion');
    
    // Downgrade genelde desteklenmez
    // Gerekirse backup'dan restore et
    throw DatabaseException('Database downgrade desteklenmiyor');
  }

  /// Database açıldığında
  Future<void> _onOpen(Database db) async {
    try {
      AppLogger.debug('Database açıldı');
      
      // Integrity check
      final integrityResults = await db.rawQuery('PRAGMA integrity_check');
      final isIntegrityOk = integrityResults.first.values.first == 'ok';
      
      if (!isIntegrityOk) {
        AppLogger.error('Database integrity check başarısız!');
        throw DatabaseException('Database bütünlüğü bozuk');
      }
      
      // Foreign key check
      final foreignKeyResults = await db.rawQuery('PRAGMA foreign_key_check');
      if (foreignKeyResults.isNotEmpty) {
        AppLogger.warning('Foreign key ihlalleri tespit edildi: ${foreignKeyResults.length}');
      }
      
      AppLogger.debug('Database integrity check başarılı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Database open check error', e, stackTrace);
    }
  }

  /// Migration çalıştır
  Future<void> _runMigration(Database db, int version) async {
    try {
      AppLogger.info('Migration v$version çalıştırılıyor...');
      
      switch (version) {
        case 2:
          await _migrationV2(db);
          break;
        case 3:
          await _migrationV3(db);
          break;
        // Yeni version'lar için case ekle
        default:
          AppLogger.warning('Migration v$version tanımlı değil');
      }
      
      AppLogger.success('Migration v$version tamamlandı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Migration v$version hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Migration v2 (örnek)
  Future<void> _migrationV2(Database db) async {
    // Örnek: Yeni bir kolon ekle
    await db.execute('ALTER TABLE athletes ADD COLUMN profilePicture TEXT');
    
    // Örnek: Yeni bir tablo ekle
    await db.execute('''
      CREATE TABLE athlete_notes (
        id TEXT PRIMARY KEY,
        athleteId TEXT NOT NULL,
        note TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (athleteId) REFERENCES athletes (id) ON DELETE CASCADE
      )
    ''');
    
    // Index ekle
    await db.execute('CREATE INDEX idx_athlete_notes_athlete ON athlete_notes(athleteId)');
  }

  /// Migration v3 (örnek)
  Future<void> _migrationV3(Database db) async {
    // Örnek: Test results tablosuna yeni kolonlar
    await db.execute('ALTER TABLE test_results ADD COLUMN confidence REAL DEFAULT 1.0');
    await db.execute('ALTER TABLE test_results ADD COLUMN isOutlier INTEGER DEFAULT 0');
  }

  /// Database bilgilerini logla
  Future<void> _logDatabaseInfo() async {
    try {
      final db = await database;
      
      // Database path ve boyut
      final path = await databasePath;
      final size = await databaseSize;
      
      // Version bilgisi
      final versionResult = await db.rawQuery('PRAGMA user_version');
      final version = versionResult.first.values.first;
      
      // Tablo sayıları
      final tablesResult = await db.rawQuery('''
        SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'
      ''');
      
      final tableCount = tablesResult.length;
      
      // Row counts
      final athleteCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM athletes')) ?? 0;
      final sessionCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM test_sessions')) ?? 0;
      
      AppLogger.info('''
🗄️ DATABASE INFO:
📍 Path: $path
📊 Size: ${(size / 1024).toStringAsFixed(1)} KB
🔢 Version: $version
📋 Tables: $tableCount
👥 Athletes: $athleteCount
🧪 Sessions: $sessionCount
      ''');
      
    } catch (e) {
      AppLogger.error('Database info logging error: $e');
    }
  }

  /// Database'i optimize et
  Future<void> optimize() async {
    try {
      AppLogger.info('🔧 Database optimize ediliyor...');
      
      final db = await database;
      
      // VACUUM - database'i sıkıştır ve defragment et
      await db.execute('VACUUM');
      
      // ANALYZE - query planner için istatistik güncelle
      await db.execute('ANALYZE');
      
      // WAL checkpoint - WAL dosyasını ana database'e merge et
      await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      
      final newSize = await databaseSize;
      AppLogger.success('✅ Database optimize edildi (${(newSize / 1024).toStringAsFixed(1)} KB)');
      
    } catch (e, stackTrace) {
      AppLogger.error('Database optimization error', e, stackTrace);
    }
  }

  /// Database'i backup al
  Future<String> createBackup() async {
    try {
      AppLogger.info('💾 Database backup oluşturuluyor...');
      
      final sourceFile = File(await databasePath);
      if (!await sourceFile.exists()) {
        throw Exception('Database dosyası bulunamadı');
      }
      
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(join(documentsDir.path, AppConstants.backupDirectory));
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = join(backupDir.path, 'izforce_backup_$timestamp.db');
      
      await sourceFile.copy(backupPath);
      
      AppLogger.success('✅ Database backup oluşturuldu: $backupPath');
      return backupPath;
      
    } catch (e, stackTrace) {
      AppLogger.error('Database backup error', e, stackTrace);
      rethrow;
    }
  }

  /// Backup'dan database'i restore et
  Future<void> restoreFromBackup(String backupPath) async {
    try {
      AppLogger.info('🔄 Database backup\'dan restore ediliyor...');
      
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('Backup dosyası bulunamadı: $backupPath');
      }
      
      // Mevcut database'i kapat
      await close();
      
      // Backup'ı ana konuma kopyala
      final targetPath = await databasePath;
      await backupFile.copy(targetPath);
      
      // Database'i yeniden aç
      await initialize();
      
      AppLogger.success('✅ Database backup\'dan restore edildi');
      
    } catch (e, stackTrace) {
      AppLogger.error('Database restore error', e, stackTrace);
      rethrow;
    }
  }

  /// Database'i temizle (factory reset)
  Future<void> reset() async {
    try {
      AppLogger.warning('🗑️ Database reset ediliyor...');
      
      // Database'i kapat
      await close();
      
      // Database dosyasını sil
      final dbFile = File(await databasePath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      
      // WAL ve SHM dosyalarını da sil
      final walFile = File('${await databasePath}-wal');
      final shmFile = File('${await databasePath}-shm');
      
      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();
      
      // Yeniden initialize et
      _isInitialized = false;
      await initialize();
      
      AppLogger.success('✅ Database reset tamamlandı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Database reset error', e, stackTrace);
      rethrow;
    }
  }

  /// Database'i kapat
  Future<void> close() async {
    try {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
        _isInitialized = false;
        AppLogger.info('Database bağlantısı kapatıldı');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Database close error', e, stackTrace);
    }
  }

  /// Database sağlık kontrolü
  Future<DatabaseHealthCheck> healthCheck() async {
    try {
      final db = await database;
      
      // Basic checks
      final integrityResults = await db.rawQuery('PRAGMA integrity_check');
      final isIntegrityOk = integrityResults.first.values.first == 'ok';
      
      final foreignKeyResults = await db.rawQuery('PRAGMA foreign_key_check');
      final hasForeignKeyIssues = foreignKeyResults.isNotEmpty;
      
      // Performance metrics
      final pageCount = Sqflite.firstIntValue(await db.rawQuery('PRAGMA page_count')) ?? 0;
      final pageSize = Sqflite.firstIntValue(await db.rawQuery('PRAGMA page_size')) ?? 0;
      final freelist = Sqflite.firstIntValue(await db.rawQuery('PRAGMA freelist_count')) ?? 0;
      
      final fragmentationPercentage = pageCount > 0 ? (freelist / pageCount) * 100 : 0.0;
      
      // Row counts
      final athleteCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM athletes')) ?? 0;
      final sessionCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM test_sessions')) ?? 0;
      final forceDataCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM force_data')) ?? 0;
      
      return DatabaseHealthCheck(
        isHealthy: isIntegrityOk && !hasForeignKeyIssues,
        integrityOk: isIntegrityOk,
        foreignKeyIssues: hasForeignKeyIssues,
        fragmentationPercentage: fragmentationPercentage,
        totalSize: await databaseSize,
        athleteCount: athleteCount,
        sessionCount: sessionCount,
        forceDataCount: forceDataCount,
        lastChecked: DateTime.now(),
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Database health check error', e, stackTrace);
      return DatabaseHealthCheck(
        isHealthy: false,
        integrityOk: false,
        foreignKeyIssues: true,
        fragmentationPercentage: 0.0,
        totalSize: 0,
        athleteCount: 0,
        sessionCount: 0,
        forceDataCount: 0,
        lastChecked: DateTime.now(),
        error: e.toString(),
      );
    }
  }
}

/// Database sağlık kontrolü sonucu
class DatabaseHealthCheck {
  final bool isHealthy;
  final bool integrityOk;
  final bool foreignKeyIssues;
  final double fragmentationPercentage;
  final int totalSize;
  final int athleteCount;
  final int sessionCount;
  final int forceDataCount;
  final DateTime lastChecked;
  final String? error;

  const DatabaseHealthCheck({
    required this.isHealthy,
    required this.integrityOk,
    required this.foreignKeyIssues,
    required this.fragmentationPercentage,
    required this.totalSize,
    required this.athleteCount,
    required this.sessionCount,
    required this.forceDataCount,
    required this.lastChecked,
    this.error,
  });

  /// Optimizasyon gerekli mi?
  bool get needsOptimization => fragmentationPercentage > 10.0;

  /// Backup önerilir mi?
  bool get shouldBackup => (athleteCount + sessionCount) > 100;

  /// Sağlık raporu
  String get healthReport {
    final buffer = StringBuffer();
    buffer.writeln('DATABASE HEALTH REPORT');
    buffer.writeln('=====================');
    buffer.writeln('Overall Health: ${isHealthy ? "✅ Healthy" : "❌ Issues Found"}');
    buffer.writeln('Integrity: ${integrityOk ? "✅ OK" : "❌ Corrupted"}');
    buffer.writeln('Foreign Keys: ${foreignKeyIssues ? "❌ Issues" : "✅ OK"}');
    buffer.writeln('Fragmentation: ${fragmentationPercentage.toStringAsFixed(1)}%');
    buffer.writeln('Size: ${(totalSize / 1024).toStringAsFixed(1)} KB');
    buffer.writeln('Athletes: $athleteCount');
    buffer.writeln('Test Sessions: $sessionCount');
    buffer.writeln('Force Data Records: $forceDataCount');
    
    if (needsOptimization) {
      buffer.writeln('\n⚠️ RECOMMENDATION: Database optimization needed');
    }
    
    if (shouldBackup) {
      buffer.writeln('\n💾 RECOMMENDATION: Create backup');
    }
    
    if (error != null) {
      buffer.writeln('\n❌ ERROR: $error');
    }
    
    return buffer.toString();
  }
}