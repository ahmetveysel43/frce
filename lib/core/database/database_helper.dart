// lib/core/database/database_helper.dart

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
  static Completer<Database>? _initCompleter;
  
  Future<Database> get database async {
    // Eğer database zaten açıksa direkt döndür
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    
    // Eğer initialization devam ediyorsa bekle
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    
    // Yeni initialization başlat
    _initCompleter = Completer<Database>();
    try {
      _database = await _initDatabase();
      _initCompleter!.complete(_database!);
      return _database!;
    } catch (e) {
      _initCompleter!.completeError(e);
      rethrow;
    } finally {
      _initCompleter = null;
    }
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

      final db = await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
      
      // Apply performance optimizations after database is opened
      await _applyPerformanceOptimizations(db);
      
      return db;
    } catch (e, stackTrace) {
      AppLogger.error('Database oluşturma hatası', e, stackTrace);
      rethrow;
    }
  }
  
  /// Apply performance optimizations
  Future<void> _applyPerformanceOptimizations(Database db) async {
    try {
      // Performance optimizations
      await db.execute('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA synchronous = NORMAL');
      await db.execute('PRAGMA cache_size = 10000');
      await db.execute('PRAGMA temp_store = MEMORY');
      await db.execute('PRAGMA mmap_size = 268435456'); // 256MB
      
      AppLogger.debug('Database performance optimizations applied');
    } catch (e) {
      AppLogger.warning('Could not apply some database optimizations: $e');
    }
  }

  /// Database konfigürasyonu
  Future<void> _onConfigure(Database db) async {
    // Foreign key'leri aktif et
    await db.execute('PRAGMA foreign_keys = ON');
    
    AppLogger.debug('Database foreign keys enabled');
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

    // Optimized indexes
    batch.execute('CREATE INDEX idx_athletes_email ON athletes(email)');
    batch.execute('CREATE INDEX idx_athletes_active ON athletes(isActive)');
    batch.execute('CREATE INDEX idx_test_sessions_athlete ON test_sessions(athleteId)');
    batch.execute('CREATE INDEX idx_test_sessions_date ON test_sessions(testDate)');
    batch.execute('CREATE INDEX idx_test_sessions_type ON test_sessions(testType)');
    batch.execute('CREATE INDEX idx_test_sessions_status ON test_sessions(status)');
    batch.execute('CREATE INDEX idx_force_data_session ON force_data(sessionId)');
    batch.execute('CREATE INDEX idx_force_data_timestamp ON force_data(timestamp)');
    batch.execute('CREATE INDEX idx_test_results_session ON test_results(sessionId)');
    batch.execute('CREATE INDEX idx_test_results_metric ON test_results(metricName)');
    
    // Composite indexes for common queries
    batch.execute('CREATE INDEX idx_test_sessions_athlete_date ON test_sessions(athleteId, testDate)');
    batch.execute('CREATE INDEX idx_test_sessions_athlete_type ON test_sessions(athleteId, testType)');
    batch.execute('CREATE INDEX idx_test_results_session_metric ON test_results(sessionId, metricName)');

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
      
      AppLogger.success('Database migrationları tamamlandı');
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      AppLogger.dbError('deleteAthlete', e.toString());
      rethrow;
    }
  }

  /// Sporcu getir
  Future<Map<String, dynamic>?> getAthleteById(String id) async {
    try {
      final db = await database;
      
      final results = await db.query(
        'athletes',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      AppLogger.dbError('getAthleteById', e.toString());
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
    } catch (e) {
      AppLogger.dbError('getAllAthletes', e.toString());
      return [];
    }
  }

  /// Sporcuları arama
  Future<List<Map<String, dynamic>>> searchAthletes(String query) async {
    try {
      final db = await database;
      final searchQuery = '%${query.toLowerCase()}%';
      
      final results = await db.query(
        'athletes',
        where: 'LOWER(firstName) LIKE ? OR LOWER(lastName) LIKE ? OR LOWER(email) LIKE ? OR LOWER(sport) LIKE ?',
        whereArgs: [searchQuery, searchQuery, searchQuery, searchQuery],
        orderBy: 'firstName, lastName',
      );
      
      return results;
    } catch (e) {
      AppLogger.dbError('searchAthletes', e.toString());
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
    } catch (e) {
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
    } catch (e) {
      AppLogger.dbError('updateTestSession', e.toString());
      rethrow;
    }
  }

  /// Sporcu test geçmişi (optimized with filters and caching)
  Future<List<Map<String, dynamic>>> getAthleteTestHistory(
    String athleteId, {
    String? testType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final db = await database;
      
      final whereConditions = <String>['athleteId = ?'];
      final whereArgs = <dynamic>[athleteId];
      
      if (testType != null && testType != 'Tümü') {
        whereConditions.add('testType = ?');
        whereArgs.add(testType);
      }
      
      if (startDate != null) {
        whereConditions.add('testDate >= ?');
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereConditions.add('testDate <= ?');
        whereArgs.add(endDate.toIso8601String());
      }
      
      // Use composite index and limit early for better performance
      final results = await db.query(
        'test_sessions',
        columns: ['id', 'athleteId', 'testType', 'testDate', 'duration', 'status', 'notes'], // Specify only needed columns
        where: whereConditions.join(' AND '),
        whereArgs: whereArgs,
        orderBy: 'testDate DESC',
        limit: limit ?? 100, // Default limit to prevent large queries
      );
      
      return results;
    } catch (e) {
      AppLogger.dbError('getAthleteTestHistory', e.toString());
      return [];
    }
  }

  /// Optimized batch query for multiple athletes (for dashboard)
  Future<Map<String, List<Map<String, dynamic>>>> getMultipleAthleteTestHistory(
    List<String> athleteIds, {
    String? testType,
    DateTime? startDate,
    DateTime? endDate,
    int? limitPerAthlete,
  }) async {
    try {
      final db = await database;
      final results = <String, List<Map<String, dynamic>>>{};
      
      // Build optimized batch query
      final placeholders = athleteIds.map((_) => '?').join(',');
      final whereConditions = <String>['athleteId IN ($placeholders)'];
      final whereArgs = <dynamic>[...athleteIds];
      
      if (testType != null && testType != 'Tümü') {
        whereConditions.add('testType = ?');
        whereArgs.add(testType);
      }
      
      if (startDate != null) {
        whereConditions.add('testDate >= ?');
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereConditions.add('testDate <= ?');
        whereArgs.add(endDate.toIso8601String());
      }
      
      final dbResults = await db.query(
        'test_sessions',
        columns: ['id', 'athleteId', 'testType', 'testDate', 'duration', 'status'],
        where: whereConditions.join(' AND '),
        whereArgs: whereArgs,
        orderBy: 'athleteId, testDate DESC',
        limit: (limitPerAthlete ?? 50) * athleteIds.length,
      );
      
      // Group results by athlete
      for (final row in dbResults) {
        final athleteId = row['athleteId'] as String;
        if (!results.containsKey(athleteId)) {
          results[athleteId] = [];
        }
        if (results[athleteId]!.length < (limitPerAthlete ?? 50)) {
          results[athleteId]!.add(row);
        }
      }
      
      return results;
    } catch (e) {
      AppLogger.dbError('getMultipleAthleteTestHistory', e.toString());
      return {};
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      AppLogger.dbError('insertTestResultsBatch', e.toString());
      rethrow;
    }
  }

  /// Test sonuçlarını getir (cached)
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
        final metricValue = result['metricValue'];
        if (metricValue != null) {
          final doubleValue = metricValue is double ? metricValue : (metricValue as num).toDouble();
          if (doubleValue.isFinite) {
            final metricName = result['metricName'] as String?;
            if (metricName != null && metricName.isNotEmpty) {
              metrics[metricName] = doubleValue;
            }
          }
        }
      }
      
      return metrics;
    } catch (e) {
      AppLogger.dbError('getTestResults', e.toString());
      return {};
    }
  }
  
  /// Get aggregated metrics for athlete comparison
  Future<Map<String, dynamic>> getAthleteAggregatedMetrics(
    String athleteId, {
    String? testType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await database;
      
      final whereConditions = <String>[
        'ts.athleteId = ?',
        'tr.sessionId = ts.id',
      ];
      final whereArgs = <dynamic>[athleteId];
      
      if (testType != null && testType != 'Tümü') {
        whereConditions.add('ts.testType = ?');
        whereArgs.add(testType);
      }
      
      if (startDate != null) {
        whereConditions.add('ts.testDate >= ?');
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereConditions.add('ts.testDate <= ?');
        whereArgs.add(endDate.toIso8601String());
      }
      
      final query = '''
        SELECT 
          tr.metricName,
          COUNT(tr.metricValue) as count,
          AVG(tr.metricValue) as mean,
          MIN(tr.metricValue) as min,
          MAX(tr.metricValue) as max,
          MAX(ts.testDate) as lastTest
        FROM test_results tr
        INNER JOIN test_sessions ts ON tr.sessionId = ts.id
        WHERE ${whereConditions.join(' AND ')}
        GROUP BY tr.metricName
        ORDER BY tr.metricName
      ''';
      
      final results = await db.rawQuery(query, whereArgs);
      
      final aggregated = <String, dynamic>{};
      for (final result in results) {
        final metricName = result['metricName'] as String;
        aggregated[metricName] = {
          'count': result['count'],
          'mean': result['mean'],
          'min': result['min'],
          'max': result['max'],
          'lastTest': result['lastTest'],
        };
      }
      
      return aggregated;
    } catch (e) {
      AppLogger.dbError('getAthleteAggregatedMetrics', e.toString());
      return {};
    }
  }
  
  /// Get performance trends for a specific metric
  Future<List<Map<String, dynamic>>> getMetricTrend(
    String athleteId,
    String metricName, {
    String? testType,
    int? limitDays,
  }) async {
    try {
      final db = await database;
      
      final whereConditions = <String>[
        'ts.athleteId = ?',
        'tr.sessionId = ts.id',
        'tr.metricName = ?',
      ];
      final whereArgs = <dynamic>[athleteId, metricName];
      
      if (testType != null && testType != 'Tümü') {
        whereConditions.add('ts.testType = ?');
        whereArgs.add(testType);
      }
      
      if (limitDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
        whereConditions.add('ts.testDate >= ?');
        whereArgs.add(cutoffDate.toIso8601String());
      }
      
      final query = '''
        SELECT 
          tr.metricValue,
          ts.testDate,
          ts.testType,
          ts.id as sessionId
        FROM test_results tr
        INNER JOIN test_sessions ts ON tr.sessionId = ts.id
        WHERE ${whereConditions.join(' AND ')}
        ORDER BY ts.testDate ASC
      ''';
      
      final results = await db.rawQuery(query, whereArgs);
      return results;
    } catch (e) {
      AppLogger.dbError('getMetricTrend', e.toString());
      return [];
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      AppLogger.dbError('clearTestData', e.toString());
      rethrow;
    }
  }

  // ===== DATABASE STATISTICS =====
  
  /// Get comprehensive database statistics
  Future<Map<String, dynamic>> getDatabaseStatistics() async {
    try {
      final db = await database;
      final stats = <String, dynamic>{};
      
      // Athletes count
      final athletesResult = await db.rawQuery('SELECT COUNT(*) as count FROM athletes');
      stats['totalAthletes'] = athletesResult.first['count'];
      
      // Test sessions count
      final sessionsResult = await db.rawQuery('SELECT COUNT(*) as count FROM test_sessions');
      stats['totalTestSessions'] = sessionsResult.first['count'];
      
      // Test results (metrics) count
      final resultsResult = await db.rawQuery('SELECT COUNT(*) as count FROM test_results');
      stats['totalTestResults'] = resultsResult.first['count'];
      
      // Force data points count
      final forceDataResult = await db.rawQuery('SELECT COUNT(*) as count FROM force_data');
      stats['totalForceDataPoints'] = forceDataResult.first['count'];
      
      // Test types breakdown
      final testTypesResult = await db.rawQuery('''
        SELECT testType, COUNT(*) as count 
        FROM test_sessions 
        GROUP BY testType 
        ORDER BY count DESC
      ''');
      stats['testTypeBreakdown'] = testTypesResult;
      
      // Unique metrics breakdown
      final metricsResult = await db.rawQuery('''
        SELECT metricName, COUNT(*) as count 
        FROM test_results 
        GROUP BY metricName 
        ORDER BY count DESC
      ''');
      stats['metricBreakdown'] = metricsResult;
      
      // Date range
      final dateRangeResult = await db.rawQuery('''
        SELECT 
          MIN(testDate) as earliestTest,
          MAX(testDate) as latestTest
        FROM test_sessions
      ''');
      if (dateRangeResult.isNotEmpty && dateRangeResult.first['earliestTest'] != null) {
        stats['dateRange'] = {
          'earliest': dateRangeResult.first['earliestTest'],
          'latest': dateRangeResult.first['latestTest'],
        };
      }
      
      // Athletes with most tests
      final topAthletesResult = await db.rawQuery('''
        SELECT 
          ts.athleteId,
          a.firstName || ' ' || a.lastName as athleteName,
          COUNT(*) as testCount
        FROM test_sessions ts
        LEFT JOIN athletes a ON ts.athleteId = a.id
        GROUP BY ts.athleteId, a.firstName, a.lastName
        ORDER BY testCount DESC
        LIMIT 10
      ''');
      stats['topAthletes'] = topAthletesResult;
      
      return stats;
    } catch (e) {
      AppLogger.dbError('getDatabaseStatistics', e.toString());
      return {};
    }
  }
  
  /// Print database statistics to console
  Future<void> printDatabaseStatistics() async {
    try {
      final stats = await getDatabaseStatistics();
      
      AppLogger.info('📊 DATABASE STATISTICS 📊');
      AppLogger.info('═══════════════════════════════════');
      AppLogger.info('👥 Total Athletes: ${stats['totalAthletes']}');
      AppLogger.info('🏃 Total Test Sessions: ${stats['totalTestSessions']}');
      AppLogger.info('📈 Total Test Results (Metrics): ${stats['totalTestResults']}');
      AppLogger.info('📊 Total Force Data Points: ${stats['totalForceDataPoints']}');
      
      if (stats['dateRange'] != null) {
        AppLogger.info('📅 Date Range: ${stats['dateRange']['earliest']} → ${stats['dateRange']['latest']}');
      }
      
      AppLogger.info('');
      AppLogger.info('🏆 TEST TYPES BREAKDOWN:');
      final testTypes = stats['testTypeBreakdown'] as List<Map<String, dynamic>>;
      for (final testType in testTypes.take(10)) {
        AppLogger.info('  ${testType['testType']}: ${testType['count']} tests');
      }
      
      AppLogger.info('');
      AppLogger.info('📊 METRICS BREAKDOWN:');
      final metrics = stats['metricBreakdown'] as List<Map<String, dynamic>>;
      for (final metric in metrics.take(15)) {
        AppLogger.info('  ${metric['metricName']}: ${metric['count']} values');
      }
      
      AppLogger.info('');
      AppLogger.info('🏅 TOP ATHLETES (by test count):');
      final topAthletes = stats['topAthletes'] as List<Map<String, dynamic>>;
      for (final athlete in topAthletes.take(5)) {
        AppLogger.info('  ${athlete['athleteName']}: ${athlete['testCount']} tests');
      }
      
      AppLogger.info('═══════════════════════════════════');
      
    } catch (e) {
      AppLogger.error('Error printing database statistics', e);
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