// lib/domain/usecases/manage_athlete_usecase.dart
import '../entities/athlete.dart';
import '../repositories/athlete_repository.dart';
import '../../core/errors/failures.dart';

enum Gender {
  male,
  female,
}

class ManageAthleteUseCase {
  final AthleteRepository _repository;

  const ManageAthleteUseCase(this._repository);

  /// Yeni sporcu oluştur
  Future<Either<Failure, void>> createAthlete({
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required Gender gender,
    required double height,
    required double weight,
    String? sport,
    String? position,
    String? notes,
  }) async {
    // Validation
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      return const Left(ValidationFailure('İsim ve soyisim boş olamaz'));
    }

    if (height <= 0 || height > 300) {
      return const Left(ValidationFailure('Geçerli bir boy değeri girin (cm)'));
    }

    if (weight <= 0 || weight > 500) {
      return const Left(ValidationFailure('Geçerli bir kilo değeri girin (kg)'));
    }

    final age = DateTime.now().year - birthDate.year;
    if (age < 5 || age > 100) {
      return const Left(ValidationFailure('Geçerli bir doğum tarihi girin'));
    }

    // Create athlete
    final athlete = Athlete(
      id: _generateId(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      age: age,
      gender: gender == Gender.male ? 'M' : 'F',
      height: height,
      weight: weight,
      sport: sport?.trim(),
      position: position?.trim(),
      notes: notes?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await _repository.saveAthlete(athlete);
  }

  /// Sporcu bilgilerini güncelle
  Future<Either<Failure, void>> updateAthlete(Athlete athlete) async {
    // Validation
    if (athlete.firstName.trim().isEmpty || athlete.lastName.trim().isEmpty) {
      return const Left(ValidationFailure('İsim ve soyisim boş olamaz'));
    }

    final updatedAthlete = athlete.copyWith(
      updatedAt: DateTime.now(),
    );

    return await _repository.updateAthlete(updatedAthlete);
  }

  /// Sporcu sil
  Future<Either<Failure, void>> deleteAthlete(String athleteId) async {
    if (athleteId.trim().isEmpty) {
      return const Left(ValidationFailure('Geçerli bir sporcu ID gerekli'));
    }

    return await _repository.deleteAthlete(athleteId);
  }

  /// Sporcu getir
  Future<Either<Failure, Athlete?>> getAthlete(String athleteId) async {
    if (athleteId.trim().isEmpty) {
      return const Left(ValidationFailure('Geçerli bir sporcu ID gerekli'));
    }

    return await _repository.getAthleteById(athleteId);
  }

  /// Tüm sporcuları getir
  Future<Either<Failure, List<Athlete>>> getAllAthletes() async {
    return await _repository.getAllAthletes();
  }

  /// Sporcu ara
  Future<Either<Failure, List<Athlete>>> searchAthletes(String query) async {
    if (query.trim().isEmpty) {
      return await getAllAthletes();
    }

    return await _repository.searchAthletes(query.trim());
  }

  /// Sporcu istatistiklerini getir
  Future<Either<Failure, AthleteStats>> getAthleteStats(String athleteId) async {
    final athleteResult = await _repository.getAthleteById(athleteId);
    
    return athleteResult.fold(
      (failure) => Left(failure),
      (athlete) {
        if (athlete == null) {
          return const Left(DatabaseFailure('Atlet bulunamadı'));
        }

        // BMI hesaplaması
        final bmi = athlete.bmi ?? 0.0;
        String bmiCategory;
        if (bmi < 18.5) {
          bmiCategory = 'Zayıf';
        } else if (bmi < 25) {
          bmiCategory = 'Normal';
        } else if (bmi < 30) {
          bmiCategory = 'Fazla Kilolu';
        } else {
          bmiCategory = 'Obez';
        }

        final stats = AthleteStats(
          athlete: athlete,
          bmi: bmi,
          bmiCategory: bmiCategory,
          totalTests: 0, // Bu test repository'den gelecek
          lastTestDate: null, // Bu test repository'den gelecek
        );

        return Right(stats);
      },
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

class AthleteStats {
  final Athlete athlete;
  final double bmi;
  final String bmiCategory;
  final int totalTests;
  final DateTime? lastTestDate;

  const AthleteStats({
    required this.athlete,
    required this.bmi,
    required this.bmiCategory,
    required this.totalTests,
    this.lastTestDate,
  });
}