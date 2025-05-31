// lib/data/repositories/athlete_repository_impl.dart

import '../../domain/entities/athlete.dart';
import '../../domain/repositories/athlete_repository.dart';
import '../datasources/mock_data_source.dart';
import '../models/athlete_model.dart';
import '../../core/database/database_helper.dart';

class AthleteRepositoryImpl implements AthleteRepository {
  final DatabaseHelper _databaseHelper;
  final MockDataSource _mockDataSource;

  AthleteRepositoryImpl({
    required DatabaseHelper databaseHelper,
    required MockDataSource mockDataSource,
  })  : _databaseHelper = databaseHelper,
        _mockDataSource = mockDataSource;

  @override
  Future<List<Athlete>> getAllAthletes() async {
    try {
      final athleteMaps = await _databaseHelper.getAllAthletes();
      return athleteMaps.map((map) => AthleteModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      // Hata durumunda mock data döndür
      print('Database error, using mock data: $e');
      final mockAthletes = await _mockDataSource.getMockAthletes();
      return mockAthletes.map((model) => model.toEntity()).toList();
    }
  }

  @override
  Future<Athlete?> getAthleteById(String id) async {
    try {
      final athleteMap = await _databaseHelper.getAthleteById(id);
      return athleteMap != null ? AthleteModel.fromMap(athleteMap).toEntity() : null;
    } catch (e) {
      print('Database error: $e');
      return null;
    }
  }

  @override
  Future<Athlete?> getAthleteByEmail(String email) async {
    try {
      final athleteMaps = await _databaseHelper.getAllAthletes();
      final athleteMap = athleteMaps.where((map) => map['email'] == email).firstOrNull;
      return athleteMap != null ? AthleteModel.fromMap(athleteMap).toEntity() : null;
    } catch (e) {
      print('Error getting athlete by email: $e');
      return null;
    }
  }

  @override
  Future<String> addAthlete(Athlete athlete) async {
    try {
      final athleteModel = AthleteModel.fromEntity(athlete);
      final id = await _databaseHelper.insertAthlete(athleteModel.toMap());
      return id;
    } catch (e) {
      print('Error adding athlete: $e');
      throw Exception('Failed to add athlete');
    }
  }

  @override
  Future<void> updateAthlete(Athlete athlete) async {
    try {
      final athleteModel = AthleteModel.fromEntity(athlete);
      await _databaseHelper.updateAthlete(athlete.id, athleteModel.toMap());
    } catch (e) {
      print('Error updating athlete: $e');
      throw Exception('Failed to update athlete');
    }
  }

  @override
  Future<void> deleteAthlete(String id) async {
    try {
      await _databaseHelper.deleteAthlete(id);
    } catch (e) {
      print('Error deleting athlete: $e');
      throw Exception('Failed to delete athlete');
    }
  }

  @override
  Future<List<Athlete>> searchAthletes(String query) async {
    try {
      final athletes = await _databaseHelper.searchAthletes(query);
      return athletes.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  @override
  Future<List<Athlete>> getAthletesBySport(String sport) async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      final filtered = athletes.where((a) => a.sport == sport).toList();
      return filtered.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting athletes by sport: $e');
      return [];
    }
  }

  @override
  Future<List<Athlete>> getAthletesByLevel(String level) async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      final filtered = athletes.where((a) => a.level == level).toList();
      return filtered.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting athletes by level: $e');
      return [];
    }
  }

  @override
  Future<List<Athlete>> getAthletesByAgeRange(int minAge, int maxAge) async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      final now = DateTime.now();
      final filtered = athletes.where((a) {
        if (a.dateOfBirth == null) return false;
        final age = now.year - a.dateOfBirth!.year;
        return age >= minAge && age <= maxAge;
      }).toList();
      return filtered.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting athletes by age range: $e');
      return [];
    }
  }

  @override
  Future<List<Athlete>> getActiveAthletes() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: 30));
      final athletes = await _databaseHelper.getAllAthletes();
      final active = athletes.where((a) => 
        a.lastTestDate != null && a.lastTestDate!.isAfter(cutoffDate)
      ).toList();
      return active.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting active athletes: $e');
      return [];
    }
  }

  @override
  Future<List<Athlete>> getRecentAthletes({int limit = 10}) async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      athletes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recent = athletes.take(limit).toList();
      return recent.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting recent athletes: $e');
      return [];
    }
  }

  @override
  Future<AthleteStatistics> getAthleteStatistics() async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      
      final totalCount = athletes.length;
      final maleCount = athletes.where((a) => a.gender == 'male').length;
      final femaleCount = athletes.where((a) => a.gender == 'female').length;
      
      final cutoffDate = DateTime.now().subtract(Duration(days: 30));
      final activeCount = athletes.where((a) => 
        a.lastTestDate != null && a.lastTestDate!.isAfter(cutoffDate)
      ).length;
      
      // Sport distribution
      final sportCounts = <String, int>{};
      for (final athlete in athletes) {
        if (athlete.sport != null) {
          sportCounts[athlete.sport!] = (sportCounts[athlete.sport!] ?? 0) + 1;
        }
      }
      
      // Level distribution  
      final levelCounts = <String, int>{};
      for (final athlete in athletes) {
        if (athlete.level != null) {
          levelCounts[athlete.level!] = (levelCounts[athlete.level!] ?? 0) + 1;
        }
      }
      
      // Age groups
      final ageGroupCounts = <String, int>{};
      final now = DateTime.now();
      for (final athlete in athletes) {
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
      
      final ages = athletes
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
    } catch (e) {
      print('Error getting athlete statistics: $e');
      return const AthleteStatistics();
    }
  }

  @override
  Future<void> deleteMultipleAthletes(List<String> athleteIds) async {
    try {
      for (final id in athleteIds) {
        await _databaseHelper.deleteAthlete(id);
      }
    } catch (e) {
      print('Error deleting multiple athletes: $e');
      throw Exception('Failed to delete athletes');
    }
  }

  @override
  Future<bool> athleteExists(String id) async {
    try {
      final athlete = await _databaseHelper.getAthleteById(id);
      return athlete != null;
    } catch (e) {
      print('Error checking athlete existence: $e');
      return false;
    }
  }

  @override
  Future<bool> isEmailUnique(String email, {String? excludeId}) async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      final existing = athletes.where((a) => 
        a.email == email && (excludeId == null || a.id != excludeId)
      ).toList();
      return existing.isEmpty;
    } catch (e) {
      print('Error checking email uniqueness: $e');
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> exportAthletes() async {
    try {
      final athletes = await _databaseHelper.getAllAthletes();
      return athletes.map((a) => a.toMap()).toList();
    } catch (e) {
      print('Error exporting athletes: $e');
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
    } catch (e) {
      print('Error importing athletes: $e');
      throw Exception('Failed to import athletes');
    }
  }
}