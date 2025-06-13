import '../entities/athlete.dart';

/// Sporcu domain repository interface
/// Clean Architecture - Domain katmanı repository contract'ı
abstract class AthleteRepository {
  /// Tüm sporcuları getir
  Future<List<Athlete>> getAllAthletes();

  /// Sporcu ID ile getir
  Future<Athlete?> getAthleteById(String id);

  /// Email ile sporcu ara
  Future<Athlete?> getAthleteByEmail(String email);

  /// Yeni sporcu ekle
  Future<String> addAthlete(Athlete athlete);

  /// Sporcu güncelle
  Future<void> updateAthlete(Athlete athlete);

  /// Sporcu sil
  Future<void> deleteAthlete(String id);

  /// Sporcuları arama
  Future<List<Athlete>> searchAthletes(String query);

  /// Spor dalına göre filtrele
  Future<List<Athlete>> getAthletesBySport(String sport);

  /// Seviyeye göre filtrele
  Future<List<Athlete>> getAthletesByLevel(String level);

  /// Yaş aralığına göre filtrele
  Future<List<Athlete>> getAthletesByAgeRange(int minAge, int maxAge);

  /// Aktif sporcuları getir (son 30 günde test yapan)
  Future<List<Athlete>> getActiveAthletes();

  /// En son eklenen sporcular
  Future<List<Athlete>> getRecentAthletes({int limit = 10});

  /// Sporcu istatistikleri
  Future<AthleteStatistics> getAthleteStatistics();

  /// Toplu sporcu silme
  Future<void> deleteMultipleAthletes(List<String> athleteIds);

  /// Sporcu var mı kontrolü
  Future<bool> athleteExists(String id);

  /// Email benzersizlik kontrolü
  Future<bool> isEmailUnique(String email, {String? excludeId});

  /// Veri yedekleme
  Future<List<Map<String, dynamic>>> exportAthletes();

  /// Veri geri yükleme
  Future<void> importAthletes(List<Map<String, dynamic>> athleteData);
}

/// Sporcu istatistikleri model (repository için)
class AthleteStatistics {
  final int totalCount;
  final int maleCount;
  final int femaleCount;
  final int activeCount;
  final Map<String, int> sportDistribution;
  final Map<String, int> levelDistribution;
  final Map<String, int> ageGroupDistribution;
  final double averageAge;
  final int completeProfilesCount;
  final double averageProfileCompletion;

  const AthleteStatistics({
    this.totalCount = 0,
    this.maleCount = 0,
    this.femaleCount = 0,
    this.activeCount = 0,
    this.sportDistribution = const {},
    this.levelDistribution = const {},
    this.ageGroupDistribution = const {},
    this.averageAge = 0.0,
    this.completeProfilesCount = 0,
    this.averageProfileCompletion = 0.0,
  });

  /// En popüler spor dalı
  String? get mostPopularSport {
    if (sportDistribution.isEmpty) return null;
    return sportDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Profil tamamlanma yüzdesi
  double get profileCompletionPercentage {
    return totalCount > 0 ? (completeProfilesCount / totalCount) * 100 : 0.0;
  }

  /// Cinsiyet dağılım yüzdeleri
  double get malePercentage => totalCount > 0 ? (maleCount / totalCount) * 100 : 0.0;
  double get femalePercentage => totalCount > 0 ? (femaleCount / totalCount) * 100 : 0.0;
  double get activePercentage => totalCount > 0 ? (activeCount / totalCount) * 100 : 0.0;
}