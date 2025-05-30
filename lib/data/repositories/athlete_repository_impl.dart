import '../../core/database/database_helper.dart';
import '../../core/utils/app_logger.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/repositories/athlete_repository.dart';

/// Sporcu repository implementation
/// Clean Architecture - Data katmanı
class AthleteRepositoryImpl implements AthleteRepository {
  final DatabaseHelper _databaseHelper;

  AthleteRepositoryImpl({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Athlete>> getAllAthletes() async {
    try {
      final athleteData = await _databaseHelper.getAllAthletes();
      return athleteData.map((data) => Athlete.fromMap(data)).toList();
    } catch (e, stackTrace) {
      AppLogger.dbError('getAllAthletes', e.toString());
      throw AthleteRepositoryException('Sporcular getirilemedi: $e', originalError: e);
    }
  }

  @override
  Future<Athlete?> getAthleteById(String id) async {
    try {
      final athleteData = await _databaseHelper.getAthlete(id);
      return athleteData != null ? Athlete.fromMap(athleteData) : null;
    } catch (e, stackTrace) {
      AppLogger.dbError('getAthleteById', e.toString());
      throw AthleteRepositoryException('Sporcu getirilemedi: $e', originalError: e);
    }
  }

  @override
  Future<Athlete?> getAthleteByEmail(String email) async {
    try {
      final db = await _databaseHelper.database;
      final results = await db.query(
        'athletes',
        where: 'email = ? AND isActive = ?',
        whereArgs: [email, 1],
      );
      
      return results.isNotEmpty ? Athlete.fromMap(results.first) : null;
    } catch (e, stackTrace) {
      AppLogger.dbError('getAthleteByEmail', e.toString());
      throw AthleteRepositoryException('Email ile sporcu bulunamadı: $e', originalError: e);
    }
  }

  @override
  Future<String> addAthlete(Athlete athlete) async {
    try {
      // Email benzersizlik kontrolü
      if (athlete.email != null && athlete.email!.isNotEmpty) {
        final existingAthlete = await getAthleteByEmail(athlete.email!);
        if (existingAthlete != null) {
          throw AthleteRepositoryException('Bu email adresi zaten kullanılıyor');
        }
      }

      await _databaseHelper.insertAthlete(athlete.toMap());
      AppLogger.dbOperation('INSERT', 'athletes');
      return athlete.id;
    } catch (e, stackTrace) {
      AppLogger.dbError('addAthlete', e.toString());
      if (e is AthleteRepositoryException) rethrow;
      throw AthleteRepositoryException('Sporcu eklenemedi: $e', originalError: e);
    }
  }

  @override
  Future<void> updateAthlete(Athlete athlete) async {
    try {
      // Email benzersizlik kontrolü (kendi ID'si hariç)
      if (athlete.email != null && athlete.email!.isNotEmpty) {
        final isUnique = await isEmailUnique(athlete.email!, excludeId: athlete.id);
        if (!isUnique) {
          throw AthleteRepositoryException('Bu email adresi başka bir sporcu tarafından kullanılıyor');
        }
      }

      await _databaseHelper.updateAthlete(athlete.id, athlete.toMap());
      AppLogger.dbOperation('UPDATE', 'athletes');
    } catch (e, stackTrace) {
      AppLogger.dbError('updateAthlete', e.toString());
      if (e is AthleteRepositoryException) rethrow;
      throw AthleteRepositoryException('Sporcu güncellenemedi: $e', originalError: e);
    }
  }

  @override
  Future<void> deleteAthlete(String id) async {
    try {
      await _databaseHelper.deleteAthlete(id);
      AppLogger.dbOperation('DELETE', 'athletes');
    } catch (e, stackTrace) {
      AppLogger.dbError('deleteAthlete', e.toString());
      throw AthleteRepositoryException('Sporcu silinemedi: $e', originalError: e);
    }
  }

  @override
  Future<List<Athlete>> searchAthletes(String query) async {
    try {
      final db = await _databaseHelper.database;
      final searchQuery = '%${query.toLowerCase()}%';
      
      final results = await db.query(
        'athletes',
        where: '''
          (LOWER(firstName) LIKE ? OR 
           LOWER(lastName) LIKE ? OR 
           LOWER(email) LIKE ? OR 
           LOWER(sport) LIKE ?) AND 
          isActive = ?
        ''',
        whereArgs: [searchQuery, searchQuery, searchQuery, searchQuery, 1],
        orderBy: 'firstName, lastName',
      );
      
      return results.map((data) => Athlete.fromMap(data)).toList();
    } catch (e, stackTrace) {
      AppLogger.dbError('searchAthletes', e.toString());
      throw AthleteRepositoryException('Sporcu araması başarısız: $e', originalError: e);
    }
  }

  @override
  Future<List<Athlete>> getAthletesBySport(String sport) async {
    try {
      final db = await _databaseHelper.database;
      final results = await db.query(
        'athletes',
        where: 'sport = ? AND isActive = ?',
        whereArgs: [sport, 1],
        orderBy: 'firstName, lastName',
      );
      
      return results.map((data) => Athlete.fromMap(data)).toList();
    } catch (e, stackTrace) {
      AppLogger.dbError('getAthletesBySport', e.toString());
      throw AthleteRepositoryException('Spor dalına göre sporcular getirilemedi: $e', originalError: e);
    }
  }

  @override
  Future<List<Athlete>> getAthletesByLevel(String level) async {
    try {
      final db = await _databaseHelper.database;
      final results = await db.query(
        'athletes',
        where: 'level = ? AND isActive = ?',
        whereArgs: [level, 1],
        orderBy: 'firstName, lastName',
      );
      
      return results.map((data) => Athlete.fromMap(data)).toList();
    } catch (e, stackTrace) {
      AppLogger.dbError('getAthletesByLevel', e.toString());
      throw AthleteRepositoryException('Seviyeye göre sporcular getirilemedi: $e', originalError: e);
    }
  }

  @override
  Future<List<Athlete>> getAthletesByAgeRange(int minAge, int maxAge) async {
    try {
      final now = DateTime.now();
      final maxBirthDate = DateTime(now.year - minAge, now.month, now.day);
      final minBirthDate = DateTime(now.year - maxAge, now.month, now.day);
      
      final db = await _databaseHelper.database;
      final results = await db.query(
        'athletes',
        where: 'dateOfBirth BETWEEN ? AND ? AND isActive = ?',
        whereArgs: [
          minBirthDate.toIso8601String(),
          maxBirthDate.toIso8601String(),
          1,
        ],
        orderBy: 'dateOfBirth DESC',
      );
      
      return results.map((data) => Athlete.fromMap(data)).toList();
    } catch (e, stackTrace) {
      AppLogger.dbError('getAthletesByAgeRange', e.toString());
      throw AthleteRepositoryException('Yaş aralığına göre sporcular getirilemedi: $e', originalError: e);
    }
  }

  @override
  Future<List<Athlete>> getActiveAthletes() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      final db = await _databaseHelper.database;
      final results = await db.rawQuery('''
        SELECT DISTINCT a.* FROM athletes a
        INNER JOIN test_sessions ts ON a.id = ts.athleteId
        WHERE ts.testDate >= ? AND a.isActive = ?
        ORDER BY ts.testDate DESC
      ''', [cutoffDate.toIso8601String(), 1]);
      
      return results.map((data) => Athlete.fromMap(data)).toList();
    } catch (e, stackTrace) {
      AppLogger.dbError('getActiveAthletes', e.toString());
      throw AthleteRepositoryException('Aktif sporcular getirilemedi: $e', originalError: e);
    }
  }

  @override
  Future<List<Athlete>> getRecentAthletes({int limit = 10}) async {
    try {
      final db = await _databaseHelper.database;
      final results = await db.query(
        'athletes',
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'createdAt DESC',
        limit: limit,
      );
      
      return results.map((data) => Athlete.fromMap(data)).toList();
    } catch (e, stackTrace) {
      AppLogger.dbError('getRecentAthletes', e.toString());
      throw AthleteRepositoryException('Son sporcular getirilemedi: $e', originalError: e);
    }
  }

  @override
  Future<AthleteStatistics> getAthleteStatistics() async {
    try {
      final db = await _databaseHelper.database;
      
      // Temel sayılar
      final countResults = await db.rawQuery('''
        SELECT 
          COUNT(*) as totalCount,
          SUM(CASE WHEN gender = 'male' THEN 1 ELSE 0 END) as maleCount,
          SUM(CASE WHEN gender = 'female' THEN 1 ELSE 0 END) as femaleCount
        FROM athletes 
        WHERE isActive = 1
      ''');
      
      final counts = countResults.first;
      final totalCount = counts['totalCount'] as int;
      final maleCount = counts['maleCount'] as int;
      final femaleCount = counts['femaleCount'] as int;
      
      // Aktif sporcular (son 30 günde test yapan)
      final activeResults = await db.rawQuery('''
        SELECT COUNT(DISTINCT a.id) as activeCount
        FROM athletes a
        INNER JOIN test_sessions ts ON a.id = ts.athleteId
        WHERE ts.testDate >= ? AND a.isActive = 1
      ''', [DateTime.now().subtract(const Duration(days: 30)).toIso8601String()]);
      
      final activeCount = activeResults.first['activeCount'] as int;
      
      // Spor dağılımı
      final sportResults = await db.rawQuery('''
        SELECT sport, COUNT(*) as count
        FROM athletes 
        WHERE sport IS NOT NULL AND sport != '' AND isActive = 1
        GROUP BY sport
        ORDER BY count DESC
      ''');
      
      final sportDistribution = <String, int>{};
      for (final row in sportResults) {
        sportDistribution[row['sport'] as String] = row['count'] as int;
      }
      
      // Seviye dağılımı
      final levelResults = await db.rawQuery('''
        SELECT level, COUNT(*) as count
        FROM athletes 
        WHERE level IS NOT NULL AND isActive = 1
        GROUP BY level
      ''');
      
      final levelDistribution = <String, int>{};
      for (final row in levelResults) {
        levelDistribution[row['level'] as String] = row['count'] as int;
      }
      
      // Yaş grupları
      final athletes = await getAllAthletes();
      final ageGroups = <String, int>{};
      double totalAge = 0;
      int ageCount = 0;
      
      for (final athlete in athletes) {
        final ageGroup = athlete.ageGroup;
        ageGroups[ageGroup] = (ageGroups[ageGroup] ?? 0) + 1;
        
        if (athlete.age != null) {
          totalAge += athlete.age!;
          ageCount++;
        }
      }
      
      final averageAge = ageCount > 0 ? totalAge / ageCount : 0.0;
      
      // Profil tamamlanma
      int completeProfiles = 0;
      double totalCompletion = 0;
      
      for (final athlete in athletes) {
        if (athlete.isProfileComplete) completeProfiles++;
        totalCompletion += athlete.profileCompletion;
      }
      
      final averageCompletion = totalCount > 0 ? totalCompletion / totalCount : 0.0;
      
      return AthleteStatistics(
        totalCount: totalCount,
        maleCount: maleCount,
        femaleCount: femaleCount,
        activeCount: activeCount,
        sportDistribution: sportDistribution,
        levelDistribution: levelDistribution,
        ageGroupDistribution: ageGroups,
        averageAge: averageAge,
        completeProfilesCount: completeProfiles,
        averageProfileCompletion: averageCompletion,
      );
    } catch (e, stackTrace) {
      AppLogger.dbError('getAthleteStatistics', e.toString());
      throw AthleteRepositoryException('Sporcu istatistikleri alınamadı: $e', originalError: e);
    }
  }

  @override
  Future<void> deleteMultipleAthletes(List<String> athleteIds) async {
    try {
      final db = await _databaseHelper.database;
      final batch = db.batch();
      
      for (final id in athleteIds) {
        batch.delete('athletes', where: 'id = ?', whereArgs: [id]);
      }
      
      await batch.commit();
      AppLogger.dbOperation('BULK DELETE', 'athletes (${athleteIds.length} records)');
    } catch (e, stackTrace) {
      AppLogger.dbError('deleteMultipleAthletes', e.toString());
      throw AthleteRepositoryException('Toplu sporcu silme başarısız: $e', originalError: e);
    }
  }

  @override
  Future<bool> athleteExists(String id) async {
    try {
      final db = await _databaseHelper.database;
      final results = await db.query(
        'athletes',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return results.isNotEmpty;
    } catch (e, stackTrace) {
      AppLogger.dbError('athleteExists', e.toString());
      return false;
    }
  }

  @override
  Future<bool> isEmailUnique(String email, {String? excludeId}) async {
    try {
      final db = await _databaseHelper.database;
      
      String whereClause = 'email = ? AND isActive = ?';
      List<dynamic> whereArgs = [email, 1];
      
      if (excludeId != null) {
        whereClause += ' AND id != ?';
        whereArgs.add(excludeId);
      }
      
      final results = await db.query(
        'athletes',
        columns: ['id'],
        where: whereClause,
        whereArgs: whereArgs,
      );
      
      return results.isEmpty;
    } catch (e, stackTrace) {
      AppLogger.dbError('isEmailUnique', e.toString());
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> exportAthletes() async {
    try {
      final athletes = await getAllAthletes();
      return athletes.map((athlete) => athlete.toJson()).toList();
    } catch (e, stackTrace) {
      AppLogger.dbError('exportAthletes', e.toString());
      throw AthleteRepositoryException('Sporcu export başarısız: $e', originalError: e);
    }
  }

  @override
  Future<void> importAthletes(List<Map<String, dynamic>> athleteData) async {
    try {
      final db = await _databaseHelper.database;
      final batch = db.batch();
      
      for (final data in athleteData) {
        try {
          final athlete = Athlete.fromJson(data);
          
          // ID çakışmasını önle
          final exists = await athleteExists(athlete.id);
          final finalAthlete = exists 
              ? athlete.copyWith(id: Athlete._generateId())
              : athlete;
          
          batch.insert('athletes', finalAthlete.toMap());
        } catch (e) {
          AppLogger.warning('Geçersiz sporcu verisi atlandi: $e');
        }
      }
      
      await batch.commit();
      AppLogger.dbOperation('BULK INSERT', 'athletes (${athleteData.length} records)');
    } catch (e, stackTrace) {
      AppLogger.dbError('importAthletes', e.toString());
      throw AthleteRepositoryException('Sporcu import başarısız: $e', originalError: e);
    }
  }
}

/// Sporcu repository exception'ları
class AthleteRepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AthleteRepositoryException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AthleteRepositoryException: $message';
}