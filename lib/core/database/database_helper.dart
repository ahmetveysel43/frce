import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';
import '../constants/app_constants.dart';

/// izForce SQLite database helper
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  /// Singleton instance
  static DatabaseHelper get instance => _instance;

  /// Database getter
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Database'i başlat
  Future<void> initialize() async {
    try {
      _database = await _initDatabase();
      AppLogger.success('SQLite database başlatıldı');
    } catch (e, stackTrace) {
      AppLogger.error('Database başlatma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Database'i oluştur
  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, AppConstants.databaseName);

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Database oluşturma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Database konfigürasyonu
  Future<void> _onConfigure(Database db) async {
    // Foreign key'leri aktif et
    await db.execute('PRAGMA foreign_keys = ON');
    AppLogger.debug('Database foreign keys aktif');
  }

  /// Database oluşturma
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    AppLogger.info('Database tabloları oluşturuluyor...');

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
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Test sessions tablosu
    batch.execute('''
      CREATE TABLE test_sessions (
        id TEXT PRIMARY KEY,
        athleteId TEXT NOT NULL,
        testType TEXT NOT NULL,
        testDate TEXT NOT NULL,
        duration INTEGER,
        status TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (athleteId) REFERENCES athletes (id) ON DELETE CASCADE
      )
    ''');

    // Force data tablosu (ham veri)
    batch.execute('''
      CREATE TABLE force_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        leftGRF REAL NOT NULL,
        rightGRF REAL NOT NULL,
        totalGRF REAL NOT NULL,
        leftCOP_x REAL,
        leftCOP_y REAL,
        rightCOP_x REAL,
        rightCOP_y REAL,
        FOREIGN KEY (sessionId) REFERENCES test_sessions (id) ON DELETE CASCADE
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
        FOREIGN KEY (sessionId) REFERENCES test_sessions (id) ON DELETE CASCADE
      )
    ''');

    // Settings tablosu
    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Calibration data tablosu
    batch.execute('''
      CREATE TABLE calibrations (
        id TEXT PRIMARY KEY,
        deviceId TEXT NOT NULL,
        leftZeroOffset REAL NOT NULL,
        rightZeroOffset REAL NOT NULL,
        calibrationDate TEXT NOT NULL,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Index'ler
    batch.execute('CREATE INDEX idx_athletes_email ON athletes(email)');
    batch.execute('CREATE INDEX idx_test_sessions_athlete ON test_sessions(athleteId)');
    batch.execute('CREATE INDEX idx_test_sessions_date ON test_sessions(testDate)');
    batch.execute('CREATE INDEX idx_force_data_session ON force_data(sessionId)');
    batch.execute('CREATE INDEX idx_force_data_timestamp ON force_data(timestamp)');
    batch.execute('CREATE INDEX idx_test_results_session ON test_results(sessionId)');
    batch.execute('CREATE INDEX idx_test_results_metric ON test_results(metricName)');

    await batch.commit();
    AppLogger.success('Database tabloları oluşturuldu');

    // Varsayılan ayarları ekle
    await _insertDefaultSettings(db);
  }

  /// Database güncelleme
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Database güncelleniyor: v$oldVersion -> v$newVersion');

    // Gelecekteki version güncellemeleri için
    if (oldVersion < 2) {
      // Version 2 güncellemeleri
    }
  }

  /// Varsayılan ayarları ekle
  Future<void> _insertDefaultSettings(Database db) async {
    final settings = {
      'language': DefaultSettings.language,
      'darkMode': DefaultSettings.darkMode.toString(),
      'soundEnabled': DefaultSettings.soundEnabled.toString(),
      'vibrationEnabled': DefaultSettings.vibrationEnabled.toString(),
      'autoSave': DefaultSettings.autoSave.toString(),
      'mockMode': DefaultSettings.mockMode.toString(),
    };

    final batch = db.batch();
    final timestamp = DateTime.now().toIso8601String();

    for (final entry in settings.entries) {
      batch.insert('settings', {
        'key': entry.key,
        'value': entry.value,
        'updatedAt': timestamp,
      });
    }

    await batch.commit();
    AppLogger.debug('Varsayılan ayarlar eklendi');
  }

  /// Migration'ları çalıştır
  Future<void> runMigrations() async {
    try {
      final db = await database;
      
      // Data integrity check
      await _checkDataIntegrity(db);
      
      AppLogger.success('Database migration'ları tamamlandı');
    } catch (e, stackTrace) {
      AppLogger.error('Migration hatası', e, stackTrace);
    }
  }

  /// Veri bütünlüğünü kontrol et
  Future<void> _checkDataIntegrity(Database db) async {
    // Orphaned records kontrolü
    final orphanedForceData = await db.rawQuery('''
      SELECT COUNT(*) as count FROM force_data fd
      LEFT JOIN test_sessions ts ON fd.sessionId = ts.id
      WHERE ts.id IS NULL
    ''');

    final orphanedResults = await db.rawQuery('''
      SELECT COUNT(*) as count FROM test_results tr
      LEFT JOIN test_sessions ts ON tr.sessionId = ts.id
      WHERE ts.id IS NULL
    ''');

    final forceDataCount = orphanedForceData.first['count'] as int;
    final resultsCount = orphanedResults.first['count'] as int;

    if (forceDataCount > 0) {
      AppLogger.warning('$forceDataCount orphaned force data kayıtları bulundu');
    }

    if (resultsCount > 0) {
      AppLogger.warning('$resultsCount orphaned test result kayıtları bulundu');
    }
  }

  // ===== ATHLETE OPERATIONS =====

  /// Sporcu ekle
  Future<String> insertAthlete(Map<String, dynamic> athlete) async {
    try {
      final db = await database;
      final id = athlete['id'] as String;
      
      await db.insert('athletes', athlete);
      AppLogger.dbOperation('INSERT', 'athletes');
      
      return id;
    } catch (e, stackTrace) {
      AppLogger.dbError('insertAthlete', e.toString());
      rethrow;
    }
  }

  /// Sporcu güncelle
  Future<void> updateAthlete(String id, Map<String, dynamic> athlete) async {
    try {
      final db = await database;
      
      await db.update(
        'athletes',
        athlete,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      AppLogger.dbOperation('UPDATE', 'athletes');
    } catch (e, stackTrace) {
      AppLogger.dbError('updateAthlete', e.toString());
      rethrow;
    }
  }

  /// Sporcu sil
  Future<void> deleteAthlete(String id) async {
    try {
      final db = await database;
      
      await db.delete(
        'athletes',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      AppLogger.dbOperation('DELETE', 'athletes');
    } catch (e, stackTrace) {
      AppLogger.dbError('deleteAthlete', e.toString());
      rethrow;
    }
  }

  /// Sporcu getir
  Future<Map<String, dynamic>?> getAthlete(String id) async {
    try {
      final db = await database;
      
      final results = await db.query(
        'athletes',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return results.isNotEmpty ? results.first : null;
    } catch (e, stackTrace) {
      AppLogger.dbError('getAthlete', e.toString());
      return null;
    }
  }

  /// Tüm sporcuları getir
  Future<List<Map<String, dynamic>>> getAllAthletes() async {
    try {
      final db = await database;
      
      final results = await db.query(
        'athletes',
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'firstName, lastName',
      );
      
      return results;
    } catch (e, stackTrace) {
      AppLogger.dbError('getAllAthletes', e.toString());
      return [];
    }
  }

  // ===== TEST SESSION OPERATIONS =====

  /// Test session ekle
  Future<String> insertTestSession(Map<String, dynamic> session) async {
    try {
      final db = await database;
      final id = session['id'] as String;
      
      await db.insert('test_sessions', session);
      AppLogger.dbOperation('INSERT', 'test_sessions');
      
      return id;
    } catch (e, stackTrace) {
      AppLogger.dbError('insertTestSession', e.toString());
      rethrow;
    }
  }

  /// Test session güncelle
  Future<void> updateTestSession(String id, Map<String, dynamic> session) async {
    try {
      final db = await database;
      
      await db.update(
        'test_sessions',
        session,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      AppLogger.dbOperation('UPDATE', 'test_sessions');
    } catch (e, stackTrace) {
      AppLogger.dbError('updateTestSession', e.toString());
      rethrow;
    }
  }

  /// Sporcu test geçmişi
  Future<List<Map<String, dynamic>>> getAthleteTestHistory(String athleteId) async {
    try {
      final db = await database;
      
      final results = await db.query(
        'test_sessions',
        where: 'athleteId = ?',
        whereArgs: [athleteId],
        orderBy: 'testDate DESC',
      );
      
      return results;
    } catch (e, stackTrace) {
      AppLogger.dbError('getAthleteTestHistory', e.toString());
      return [];
    }
  }

  // ===== FORCE DATA OPERATIONS =====

  /// Force data batch insert (yüksek performans)
  Future<void> insertForceDataBatch(String sessionId, List<Map<String, dynamic>> forceDataList) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final data in forceDataList) {
        batch.insert('force_data', {
          ...data,
          'sessionId': sessionId,
        });
      }

      await batch.commit(noResult: true);
      AppLogger.dbOperation('BATCH INSERT', 'force_data (${forceDataList.length} records)');
    } catch (e, stackTrace) {
      AppLogger.dbError('insertForceDataBatch', e.toString());
      rethrow;
    }
  }

  /// Test force data getir
  Future<List<Map<String, dynamic>>> getSessionForceData(String sessionId) async {
    try {
      final db = await database;
      
      final results = await db.query(
        'force_data',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp',
      );
      
      return results;
    } catch (e, stackTrace) {
      AppLogger.dbError('getSessionForceData', e.toString());
      return [];
    }
  }

  // ===== TEST RESULTS OPERATIONS =====

  /// Test result batch insert
  Future<void> insertTestResultsBatch(String sessionId, Map<String, double> metrics) async {
    try {
      final db = await database;
      final batch = db.batch();
      final timestamp = DateTime.now().toIso8601String();

      for (final entry in metrics.entries) {
        batch.insert('test_results', {
          'id': '${sessionId}_${entry.key}',
          'sessionId': sessionId,
          'metricName': entry.key,
          'metricValue': entry.value,
          'calculatedAt': timestamp,
        });
      }

      await batch.commit();
      AppLogger.dbOperation('BATCH INSERT', 'test_results (${metrics.length} metrics)');
    } catch (e, stackTrace) {
      AppLogger.dbError('insertTestResultsBatch', e.toString());
      rethrow;
    }
  }

  /// Test sonuçlarını getir
  Future<Map<String, double>> getTestResults(String sessionId) async {
    try {
      final db = await database;
      
      final results = await db.query(
        'test_results',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
      );
      
      final metrics = <String, double>{};
      for (final result in results) {
        metrics[result['metricName'] as String] = result['metricValue'] as double;
      }
      
      return metrics;
    } catch (e, stackTrace) {
      AppLogger.dbError('getTestResults', e.toString());
      return {};
    }
  }

  // ===== SETTINGS OPERATIONS =====

  /// Ayar değeri getir
  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      
      final results = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );
      
      return results.isNotEmpty ? results.first['value'] as String : null;
    } catch (e, stackTrace) {
      AppLogger.dbError('getSetting', e.toString());
      return null;
    }
  }

  /// Ayar değeri kaydet
  Future<void> setSetting(String key, String value) async {
    try {
      final db = await database;
      
      await db.insert(
        'settings',
        {
          'key': key,
          'value': value,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      AppLogger.dbOperation('UPSERT', 'settings');
    } catch (e, stackTrace) {
      AppLogger.dbError('setSetting', e.toString());
      rethrow;
    }
  }

  // ===== UTILITY OPERATIONS =====

  /// Database boyutunu getir
  Future<int> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, AppConstants.databaseName);
      final file = File(path);
      
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      AppLogger.error('Database boyutu alma hatası: $e');
      return 0;
    }
  }

  /// Database'i temizle (test verilerini sil)
  Future<void> clearTestData() async {
    try {
      final db = await database;
      final batch = db.batch();

      batch.delete('force_data');
      batch.delete('test_results');
      batch.delete('test_sessions');

      await batch.commit();
      AppLogger.success('Test verileri temizlendi');
    } catch (e, stackTrace) {
      AppLogger.dbError('clearTestData', e.toString());
      rethrow;
    }
  }

  /// Database'i kapat
  Future<void> close() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        AppLogger.info('Database bağlantısı kapatıldı');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Database kapatma hatası', e, stackTrace);
    }
  }
}