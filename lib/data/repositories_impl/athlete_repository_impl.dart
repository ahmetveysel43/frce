// lib/data/repositories_impl/athlete_repository_impl.dart
import 'dart:convert';
import '../../domain/entities/athlete.dart';
import '../../domain/repositories/athlete_repository.dart';
import '../../core/errors/failures.dart';

class AthleteRepositoryImpl implements AthleteRepository {
  // In-memory storage (shared_preferences yerine)
  static final Map<String, String> _storage = {};
  static const String _athletesKey = 'athletes';
  
  List<Athlete> _cachedAthletes = [];
  bool _isInitialized = false;

  // Singleton pattern
  static final AthleteRepositoryImpl _instance = AthleteRepositoryImpl._internal();
  factory AthleteRepositoryImpl() => _instance;
  AthleteRepositoryImpl._internal();

  // Initialize
  Future<void> _initialize() async {
    if (!_isInitialized) {
      await _loadAthletes();
      _isInitialized = true;
    }
  }

  // Load athletes from storage
  Future<void> _loadAthletes() async {
    try {
      final athletesJson = _storage[_athletesKey];
      if (athletesJson != null && athletesJson.isNotEmpty) {
        final List<dynamic> athletesList = jsonDecode(athletesJson);
        _cachedAthletes = athletesList
            .map((json) => Athlete.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _cachedAthletes = [];
      }
    } catch (e) {
      print('Error loading athletes: $e');
      _cachedAthletes = [];
    }
  }

  // Save athletes to storage
  Future<void> _saveAthletes() async {
    try {
      final athletesJson = jsonEncode(
        _cachedAthletes.map((athlete) => athlete.toJson()).toList(),
      );
      _storage[_athletesKey] = athletesJson;
    } catch (e) {
      print('Error saving athletes: $e');
      throw Exception('Atletler kaydedilemedi');
    }
  }

  @override
  Future<Either<Failure, List<Athlete>>> getAllAthletes() async {
    try {
      await _initialize();
      _cachedAthletes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Right(List.from(_cachedAthletes));
    } catch (e) {
      return Left(DatabaseFailure('Atletler getirilemedi: $e'));
    }
  }

  @override
  Future<Either<Failure, Athlete?>> getAthleteById(String id) async {
    try {
      await _initialize();
      final athlete = _cachedAthletes.where((athlete) => athlete.id == id).firstOrNull;
      return Right(athlete);
    } catch (e) {
      return Left(DatabaseFailure('Atlet getirilemedi: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveAthlete(Athlete athlete) async {
    try {
      await _initialize();
      
      final existingIndex = _cachedAthletes.indexWhere((a) => a.id == athlete.id);
      if (existingIndex != -1) {
        return const Left(ValidationFailure('Bu ID ile bir atlet zaten mevcut'));
      }

      _cachedAthletes.add(athlete);
      await _saveAthletes();
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Atlet kaydedilemedi: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAthlete(Athlete athlete) async {
    try {
      await _initialize();
      
      final index = _cachedAthletes.indexWhere((a) => a.id == athlete.id);
      if (index == -1) {
        return const Left(DatabaseFailure('Güncellenecek atlet bulunamadı'));
      }

      _cachedAthletes[index] = athlete.copyWith(updatedAt: DateTime.now());
      await _saveAthletes();
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Atlet güncellenemedi: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAthlete(String id) async {
    try {
      await _initialize();
      
      final initialLength = _cachedAthletes.length;
      _cachedAthletes.removeWhere((athlete) => athlete.id == id);
      
      if (_cachedAthletes.length == initialLength) {
        return const Left(DatabaseFailure('Silinecek atlet bulunamadı'));
      }

      await _saveAthletes();
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Atlet silinemedi: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Athlete>>> searchAthletes(String query) async {
    try {
      await _initialize();
      
      if (query.isEmpty) {
        return getAllAthletes();
      }

      final lowerQuery = query.toLowerCase();
      final filteredAthletes = _cachedAthletes.where((athlete) {
        return athlete.firstName.toLowerCase().contains(lowerQuery) ||
            athlete.lastName.toLowerCase().contains(lowerQuery) ||
            athlete.fullName.toLowerCase().contains(lowerQuery) ||
            (athlete.sport?.toLowerCase().contains(lowerQuery) ?? false) ||
            (athlete.position?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();

      filteredAthletes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Right(filteredAthletes);
    } catch (e) {
      return Left(DatabaseFailure('Atlet araması başarısız: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Athlete>>> getRecentlyUpdatedAthletes(int limit) async {
    try {
      await _initialize();
      
      final sortedAthletes = List<Athlete>.from(_cachedAthletes);
      sortedAthletes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      final limitedAthletes = sortedAthletes.take(limit).toList();
      return Right(limitedAthletes);
    } catch (e) {
      return Left(DatabaseFailure('Son güncellenmiş atletler getirilemedi: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getAthleteCount() async {
    try {
      await _initialize();
      return Right(_cachedAthletes.length);
    } catch (e) {
      return Left(DatabaseFailure('Atlet sayısı alınamadı: $e'));
    }
  }

  // Mock data ekleme için
  Future<void> addMockData() async {
    await _initialize();
    
    if (_cachedAthletes.isEmpty) {
      final now = DateTime.now();
      _cachedAthletes = [
        Athlete(
          id: '1',
          firstName: 'Ahmet',
          lastName: 'Yılmaz',
          age: 25,
          gender: 'M',
          height: 180.0,
          weight: 75.0,
          sport: 'Futbol',
          position: 'Orta Saha',
          phone: '+90 555 123 45 67',
          email: 'ahmet.yilmaz@email.com',
          notes: 'Sol ayağı çok güçlü',
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
        Athlete(
          id: '2',
          firstName: 'Elif',
          lastName: 'Kaya',
          age: 22,
          gender: 'F',
          height: 165.0,
          weight: 58.0,
          sport: 'Basketbol',
          position: 'Guard',
          phone: '+90 555 987 65 43',
          email: 'elif.kaya@email.com',
          notes: 'Çok hızlı ve çevik',
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        Athlete(
          id: '3',
          firstName: 'Mehmet',
          lastName: 'Demir',
          age: 28,
          gender: 'M',
          height: 175.0,
          weight: 80.0,
          sport: 'Voleybol',
          position: 'Libero',
          phone: '+90 555 456 78 90',
          email: 'mehmet.demir@email.com',
          notes: 'Savunma uzmanı',
          createdAt: now.subtract(const Duration(days: 15)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ];
      await _saveAthletes();
    }
  }

  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

// Extension for nullable firstWhere
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}