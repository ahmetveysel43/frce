// lib/data/repositories/athlete_repository_impl.dart

import '../../domain/entities/athlete.dart';
import '../../domain/repositories/athlete_repository.dart';
// import '../datasources/mock_data_source.dart'; // Removed as no longer used
import '../models/athlete_model.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/app_logger.dart'; // Import AppLogger

class AthleteRepositoryImpl implements AthleteRepository {
  final DatabaseHelper _databaseHelper;
  // final MockDataSource _mockDataSource; // Removed as no longer used

  AthleteRepositoryImpl({
    required DatabaseHelper databaseHelper,
    // MockDataSource mockDataSource, // Removed as no longer used
  })  : _databaseHelper = databaseHelper;
        // _mockDataSource = mockDataSource; // Removed as no longer used

  @override
  Future<List<Athlete>> getAllAthletes() async {
    try {
      final athleteMaps = await _databaseHelper.getAllAthletes();
      return athleteMaps.map((map) => AthleteModel.fromMap(map).toEntity()).toList();
    } catch (e, stackTrace) {
      // Hata durumunda mock data döndür
      AppLogger.error('Database error, using mock data: $e', e, stackTrace);
      // Directly using MockAthletes for fallback, as MockDataSource instance was unused
      final mockAthleteModels = MockAthletes.sampleAthletes.map((e) => AthleteModel.fromEntity(e)).toList();
      return mockAthleteModels.map((model) => model.toEntity()).toList();
    }
  }

  @override
  Future<Athlete?> getAthleteById(String id) async {
    try {
      final athleteMap = await _databaseHelper.getAthleteById(id);
      return athleteMap != null ? AthleteModel.fromMap(athleteMap).toEntity() : null;
    } catch (e, stackTrace) {
      AppLogger.error('Database error getting athlete by ID: $e', e, stackTrace);
      return null;
    }
  }

  @override
  Future<Athlete?> getAthleteByEmail(String email) async {
    try {
      final athleteMaps = await _databaseHelper.getAllAthletes();
      final athleteMap = athleteMaps.where((map) => AthleteModel.fromMap(map).email == email).firstOrNull;
      return athleteMap != null ? AthleteModel.fromMap(athleteMap).toEntity() : null;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting athlete by email: $e', e, stackTrace);
      return null;
    }
  }

  @override
  Future<String> addAthlete(Athlete athlete) async {
    try {
      final athleteModel = AthleteModel.fromEntity(athlete);
      final id = await _databaseHelper.insertAthlete(athleteModel.toMap());
      return id;
    } catch (e, stackTrace) {
      AppLogger.error('Error adding athlete: $e', e, stackTrace);
      throw Exception('Failed to add athlete');
    }
  }

  @override
  Future<void> updateAthlete(Athlete athlete) async {
    try {
      final athleteModel = AthleteModel.fromEntity(athlete);
      await _databaseHelper.updateAthlete(athlete.id, athleteModel.toMap());
    } catch (e, stackTrace) {
      AppLogger.error('Error updating athlete: $e', e, stackTrace);
      throw Exception('Failed to update athlete');
    }
  }

  @override
  Future<void> deleteAthlete(String id) async {
    try {
      await _databaseHelper.deleteAthlete(id);
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting athlete: $e', e, stackTrace);
      throw Exception('Failed to delete athlete');
    }
  }

  @override
  Future<List<Athlete>> searchAthletes(String query) async {
    try {
      final athletes = await _databaseHelper.searchAthletes(query);
      return athletes.map((map) => AthleteModel.fromMap(map).toEntity()).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Search error: $e', e, stackTrace);
      return [];
    }
  }

  @override
  Future<List<Athlete>> getAthletesBySport(String sport) async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      final filtered = athletes.where((map) => AthleteModel.fromMap(map).sport == sport).toList();
      return filtered.map((map) => AthleteModel.fromMap(map).toEntity()).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting athletes by sport: $e', e, stackTrace);
      return [];
    }
  }

  @override
  Future<List<Athlete>> getAthletesByLevel(String level) async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      final filtered = athletes.where((map) => AthleteModel.fromMap(map).level == level).toList();
      return filtered.map((map) => AthleteModel.fromMap(map).toEntity()).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting athletes by level: $e', e, stackTrace);
      return [];
    }
  }

  @override
  Future<List<Athlete>> getAthletesByAgeRange(int minAge, int maxAge) async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      final now = DateTime.now();
      final filtered = athletes.where((map) {
        final athleteModel = AthleteModel.fromMap(map);
        if (athleteModel.dateOfBirth == null) return false;
        final age = now.year - athleteModel.dateOfBirth!.year;
        return age >= minAge && age <= maxAge;
      }).toList();
      return filtered.map((map) => AthleteModel.fromMap(map).toEntity()).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting athletes by age range: $e', e, stackTrace);
      return [];
    }
  }

  @override
  Future<List<Athlete>> getActiveAthletes() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: 30));
      final athletes = await _databaseHelper.getAllAthletes();
      final active = athletes.where((map) {
        final athleteModel = AthleteModel.fromMap(map);
        return athleteModel.lastTestDate != null && athleteModel.lastTestDate!.isAfter(cutoffDate);
      }).toList();
      return active.map((map) => AthleteModel.fromMap(map).toEntity()).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting active athletes: $e', e, stackTrace);
      return [];
    }
  }

  @override
  Future<List<Athlete>> getRecentAthletes({int limit = 10}) async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      final athleteModels = athletes.map((map) => AthleteModel.fromMap(map)).toList();
      athleteModels.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recent = athleteModels.take(limit).toList();
      return recent.map((model) => model.toEntity()).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting recent athletes: $e', e, stackTrace);
      return [];
    }
  }

  @override
  Future<AthleteStatistics> getAthleteStatistics() async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      final athleteModels = athletes.map((map) => AthleteModel.fromMap(map)).toList();
      
      final totalCount = athleteModels.length;
      final maleCount = athleteModels.where((a) => a.gender == 'male').length;
      final femaleCount = athleteModels.where((a) => a.gender == 'female').length;
      
      final cutoffDate = DateTime.now().subtract(Duration(days: 30));
      final activeCount = athleteModels.where((a) => 
        a.lastTestDate != null && a.lastTestDate!.isAfter(cutoffDate)
      ).length;
      
      // Sport distribution
      final sportCounts = <String, int>{};
      for (final athlete in athleteModels) {
        if (athlete.sport != null) {
          sportCounts[athlete.sport!] = (sportCounts[athlete.sport!] ?? 0) + 1;
        }
      }
      
      // Level distribution  
      final levelCounts = <String, int>{};
      for (final athlete in athleteModels) {
        if (athlete.level != null) {
          levelCounts[athlete.level!] = (levelCounts[athlete.level!] ?? 0) + 1;
        }
      }
      
      // Age groups
      final ageGroupCounts = <String, int>{};
      final now = DateTime.now();
      for (final athlete in athleteModels) {
        if (athlete.dateOfBirth != null) {
          final age = now.year - athlete.dateOfBirth!.year;
          String ageGroup;
          if (age < 18) ageGroup = 'Under 18';
          else if (age < 25) ageGroup = '18-24';
          else if (age < 35) ageGroup = '25-34';
          else ageGroup = '35+';
          ageGroupCounts[ageGroup] = (ageGroupCounts[ageGroup] ?? 0) + 1;
        }
      }
      
      final ages = athleteModels
          .where((a) => a.dateOfBirth != null)
          .map((a) => now.year - a.dateOfBirth!.year)
          .toList();
      final averageAge = ages.isEmpty ? 0.0 : ages.reduce((a, b) => a + b) / ages.length;
      
      return AthleteStatistics(
        totalCount: totalCount,
        maleCount: maleCount,
        femaleCount: femaleCount,
        activeCount: activeCount,
        sportDistribution: sportCounts,
        levelDistribution: levelCounts,
        ageGroupDistribution: ageGroupCounts,
        averageAge: averageAge,
        completeProfilesCount: totalCount, // Simplified
        averageProfileCompletion: 100.0, // Simplified
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error getting athlete statistics: $e', e, stackTrace);
      return const AthleteStatistics();
    }
  }

  @override
  Future<void> deleteMultipleAthletes(List<String> athleteIds) async {
    try {
      for (final id in athleteIds) {
        await _databaseHelper.deleteAthlete(id);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting multiple athletes: $e', e, stackTrace);
      throw Exception('Failed to delete athletes');
    }
  }

  @override
  Future<bool> athleteExists(String id) async {
    try {
      final athlete = await _databaseHelper.getAthleteById(id);
      return athlete != null;
    } catch (e, stackTrace) {
      AppLogger.error('Error checking athlete existence: $e', e, stackTrace);
      return false;
    }
  }

  @override
  Future<bool> isEmailUnique(String email, {String? excludeId}) async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      final existing = athletes.where((map) 
        {
          final athleteModel = AthleteModel.fromMap(map);
          return athleteModel.email == email && (excludeId == null || athleteModel.id != excludeId);
        }
      ).toList();
      return existing.isEmpty;
    } catch (e, stackTrace) {
      AppLogger.error('Error checking email uniqueness: $e', e, stackTrace);
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> exportAthletes() async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      return athletes.map((a) => AthleteModel.fromMap(a).toMap()).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error exporting athletes: $e', e, stackTrace);
      return [];
    }
  }

  @override
  Future<void> importAthletes(List<Map<String, dynamic>> athleteData) async {
    try {
      for (final data in athleteData) {
        final athlete = AthleteModel.fromMap(data);
        await _databaseHelper.insertAthlete(athlete.toMap());
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error importing athletes: $e', e, stackTrace);
      throw Exception('Failed to import athletes');
    }
  }
}