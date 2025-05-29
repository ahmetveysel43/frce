// lib/domain/repositories/athlete_repository.dart
import '../entities/athlete.dart';
import '../../core/errors/failures.dart';

// Either type için dartz paketini kullanıyoruz
abstract class Either<L, R> {
  const Either();
  
  bool get isLeft;
  bool get isRight;
  L get left;
  R get right;
  
  T fold<T>(T Function(L) leftFunction, T Function(R) rightFunction);
}

class Left<L, R> extends Either<L, R> {
  final L _value;
  
  const Left(this._value);
  
  @override
  bool get isLeft => true;
  
  @override
  bool get isRight => false;
  
  @override
  L get left => _value;
  
  @override
  R get right => throw Exception('Right called on Left');
  
  @override
  T fold<T>(T Function(L) leftFunction, T Function(R) rightFunction) {
    return leftFunction(_value);
  }
}

class Right<L, R> extends Either<L, R> {
  final R _value;
  
  const Right(this._value);
  
  @override
  bool get isLeft => false;
  
  @override
  bool get isRight => true;
  
  @override
  L get left => throw Exception('Left called on Right');
  
  @override
  R get right => _value;
  
  @override
  T fold<T>(T Function(L) leftFunction, T Function(R) rightFunction) {
    return rightFunction(_value);
  }
}

abstract class AthleteRepository {
  Future<Either<Failure, List<Athlete>>> getAllAthletes();
  Future<Either<Failure, Athlete?>> getAthleteById(String id);
  Future<Either<Failure, void>> saveAthlete(Athlete athlete);
  Future<Either<Failure, void>> updateAthlete(Athlete athlete);
  Future<Either<Failure, void>> deleteAthlete(String id);
  Future<Either<Failure, List<Athlete>>> searchAthletes(String query);
  Future<Either<Failure, List<Athlete>>> getRecentlyUpdatedAthletes(int limit);
  Future<Either<Failure, int>> getAthleteCount();
}