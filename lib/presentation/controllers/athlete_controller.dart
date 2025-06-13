import 'dart:async';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/entities/test_result.dart';

/// izForce sporcu yönetimi controller
class AthleteController extends GetxController {
  // ===== STATE VARIABLES =====
  
  final _athletes = <Athlete>[].obs;
  final _filteredAthletes = <Athlete>[].obs;
  final _selectedAthlete = Rxn<Athlete>();
  final _athleteTestHistory = <TestResult>[].obs;
  
  // Search and filter
  final _searchQuery = ''.obs;
  final _selectedSport = Rxn<String>();
  final _selectedLevel = Rxn<AthleteLevel>();
  final _selectedGender = Rxn<Gender>();
  final _sortBy = AthleteSortBy.name.obs;
  final _sortAscending = true.obs;
  
  // Loading states
  final _isLoading = false.obs;
  final _isLoadingTestHistory = false.obs;
  final _isSaving = false.obs;
  
  // Error handling
  final _errorMessage = Rxn<String>();
  
  // Statistics
  final _athleteStats = const AthleteStatistics().obs;

  // ===== GETTERS =====
  
  List<Athlete> get athletes => _athletes.toList();
  List<Athlete> get filteredAthletes => _filteredAthletes.toList();
  Athlete? get selectedAthlete => _selectedAthlete.value;
  List<TestResult> get athleteTestHistory => _athleteTestHistory.toList();
  
  // Search and filter
  String get searchQuery => _searchQuery.value;
  String? get selectedSport => _selectedSport.value;
  AthleteLevel? get selectedLevel => _selectedLevel.value;
  Gender? get selectedGender => _selectedGender.value;
  AthleteSortBy get sortBy => _sortBy.value;
  bool get sortAscending => _sortAscending.value;
  
  // Loading states
  bool get isLoading => _isLoading.value;
  bool get isLoadingTestHistory => _isLoadingTestHistory.value;
  bool get isSaving => _isSaving.value;
  String? get errorMessage => _errorMessage.value;
  bool get isInitialized => true;
  
  // Statistics
  AthleteStatistics get athleteStats => _athleteStats.value;
  int get totalAthletes => _athletes.length;
  List<String> get availableSports => _athletes
      .where((a) => a.sport?.isNotEmpty == true)
      .map((a) => a.sport!)
      .toSet()
      .toList()..sort();

  // ===== LIFECYCLE =====
  
  @override
  void onInit() {
    super.onInit();
    AppLogger.info('👥 AthleteController başlatılıyor...');
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      await loadAthletes();
      _updateStatistics();
      AppLogger.success('✅ AthleteController başlatıldı');
    } catch (e, stackTrace) {
      AppLogger.error('AthleteController başlatma hatası', e, stackTrace);
      _setError('Controller başlatma hatası: $e');
    }
  }

  // ===== ATHLETE MANAGEMENT =====

  /// Sporcuları database'den yükle
  Future<void> loadAthletes() async {
    _setLoading(true);
    
    try {
      final db = DatabaseHelper.instance;
      final athleteData = await db.getAllAthletes();
      
      final loadedAthletes = athleteData
          .map((data) => Athlete.fromMap(data))
          .toList();
      
      _athletes.value = loadedAthletes;
      _applyFiltersAndSort();
      _updateStatistics();
      
      // GetBuilder için widget'ları güncelle
      update();
      
      AppLogger.info('👥 ${loadedAthletes.length} sporcu yüklendi');
      
    } catch (e) {
      AppLogger.dbError('loadAthletes', e.toString());
      _setError('Sporcular yüklenemedi: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Mock sporcuları yükle (geliştirme için)
  Future<void> loadMockAthletes() async {
    try {
      final mockAthletes = MockAthletes.sampleAthletes;
      
      // Database'e kaydet
      final db = DatabaseHelper.instance;
      for (final athlete in mockAthletes) {
        try {
          await db.insertAthlete(athlete.toMap());
        } catch (e) {
          // Duplicate key error - ignore
          AppLogger.debug('Mock sporcu zaten mevcut: ${athlete.fullName}');
        }
      }
      
      // Controller'a yükle
      _athletes.addAll(mockAthletes);
      _applyFiltersAndSort();
      _updateStatistics();
      
      // GetBuilder için widget'ları güncelle
      update();
      
      AppLogger.info('🎭 ${mockAthletes.length} mock sporcu yüklendi');
      
    } catch (e, stackTrace) {
      AppLogger.error('Mock sporcu yükleme hatası', e, stackTrace);
    }
  }

  /// Yeni sporcu ekle
  Future<bool> addAthlete(Athlete athlete) async {
    _setSaving(true);
    
    try {
      // Validation
      if (!athlete.isValid) {
        final errors = athlete.validationErrors;
        _setError('Geçersiz sporcu bilgileri: ${errors.join(', ')}');
        return false;
      }
      
      // Email tekrar kontrolü
      if (athlete.email != null && await _isEmailExists(athlete.email!)) {
        _setError('Bu email adresi zaten kullanımda: ${athlete.email}');
        return false;
      }
      
      // Database'e kaydet
      final db = DatabaseHelper.instance;
      await db.insertAthlete(athlete.toMap());
      
      // Controller'a ekle
      _athletes.add(athlete);
      _applyFiltersAndSort();
      _updateStatistics();
      
      // GetBuilder için widget'ları güncelle
      update();
      
      AppLogger.info('➕ Sporcu eklendi: ${athlete.fullName}');
      _clearError();
      return true;
      
    } catch (e) {
      AppLogger.dbError('addAthlete', e.toString());
      _setError('Sporcu eklenemedi: $e');
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Sporcu güncelle
  Future<bool> updateAthlete(Athlete athlete) async {
    _setSaving(true);
    
    try {
      // Validation
      if (!athlete.isValid) {
        final errors = athlete.validationErrors;
        _setError('Geçersiz sporcu bilgileri: ${errors.join(', ')}');
        return false;
      }
      
      // Update timestamp
      final updatedAthlete = athlete.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // Database'de güncelle
      final db = DatabaseHelper.instance;
      await db.updateAthlete(updatedAthlete.id, updatedAthlete.toMap());
      
      // Controller'da güncelle
      final index = _athletes.indexWhere((a) => a.id == athlete.id);
      if (index != -1) {
        _athletes[index] = updatedAthlete;
        _applyFiltersAndSort();
        
        // Selected athlete'i güncelle
        if (_selectedAthlete.value?.id == athlete.id) {
          _selectedAthlete.value = updatedAthlete;
        }
      }
      
      _updateStatistics();
      
      AppLogger.info('✏️ Sporcu güncellendi: ${updatedAthlete.fullName}');
      _clearError();
      return true;
      
    } catch (e) {
      AppLogger.dbError('updateAthlete', e.toString());
      _setError('Sporcu güncellenemedi: $e');
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Sporcu sil
  Future<bool> deleteAthlete(String athleteId) async {
    _setSaving(true);
    
    try {
      // Database'den sil
      final db = DatabaseHelper.instance;
      await db.deleteAthlete(athleteId);
      
      // Controller'dan sil
      _athletes.removeWhere((a) => a.id == athleteId);
      _applyFiltersAndSort();
      
      // Selected athlete'i temizle
      if (_selectedAthlete.value?.id == athleteId) {
        _selectedAthlete.value = null;
        _athleteTestHistory.clear();
      }
      
      _updateStatistics();
      
      AppLogger.info('🗑️ Sporcu silindi: $athleteId');
      _clearError();
      return true;
      
    } catch (e) {
      AppLogger.dbError('deleteAthlete', e.toString());
      _setError('Sporcu silinemedi: $e');
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Sporcu seç
  void selectAthlete(Athlete athlete) {
    _selectedAthlete.value = athlete;
    _clearError();
    AppLogger.info('👤 Sporcu seçildi: ${athlete.fullName}');
    
    // Test geçmişini yükle
    loadAthleteTestHistory(athlete.id);
  }

  /// Sporcu seçimini temizle
  void clearSelectedAthlete() {
    _selectedAthlete.value = null;
    _athleteTestHistory.clear();
    AppLogger.debug('👤 Sporcu seçimi temizlendi');
  }

  // ===== TEST HISTORY =====

  /// Sporcu test geçmişini yükle
  Future<void> loadAthleteTestHistory(String athleteId) async {
    _isLoadingTestHistory.value = true;
    
    try {
      final db = DatabaseHelper.instance;
      final testSessions = await db.getAthleteTestHistory(athleteId);
      
      final testResults = <TestResult>[];
      for (final session in testSessions) {
        // Safe null-aware database field extraction
        final sessionId = session['id']?.toString() ?? '';
        final testTypeStr = session['testType']?.toString() ?? 'UNKNOWN';
        final testDateStr = session['testDate']?.toString() ?? DateTime.now().toIso8601String();
        final durationMs = session['duration'] as int? ?? 0;
        final statusStr = session['status']?.toString() ?? 'PENDING';
        final createdAtStr = session['createdAt']?.toString() ?? DateTime.now().toIso8601String();
        
        // Skip sessions with invalid/null IDs
        if (sessionId.isEmpty) {
          AppLogger.warning('Skipping test session with null/empty ID for athlete: $athleteId');
          continue;
        }
        
        final metrics = await db.getTestResults(sessionId);
        
        final result = TestResult(
          id: sessionId,
          sessionId: sessionId,
          athleteId: athleteId,
          testType: _getTestTypeEnum(testTypeStr),
          testDate: DateTime.tryParse(testDateStr) ?? DateTime.now(),
          duration: Duration(milliseconds: durationMs),
          status: _getTestStatusEnum(statusStr),
          metrics: metrics,
          notes: session['notes']?.toString(),
          createdAt: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
        );
        
        testResults.add(result);
      }
      
      _athleteTestHistory.value = testResults;
      
      AppLogger.info('📊 ${testResults.length} test sonucu yüklendi');
      
    } catch (e) {
      AppLogger.dbError('loadAthleteTestHistory', e.toString());
      _setError('Test geçmişi yüklenemedi: $e');
    } finally {
      _isLoadingTestHistory.value = false;
    }
  }

  /// Test sonucu ekle
  void addTestResult(TestResult result) {
    if (_selectedAthlete.value?.id == result.athleteId) {
      _athleteTestHistory.insert(0, result); // En yeni test başta
      AppLogger.info('📊 Test sonucu eklendi: ${result.testType.turkishName}');
    }
  }

  // ===== SEARCH AND FILTER =====

  /// Arama sorgusu güncelle
  void updateSearchQuery(String query) {
    _searchQuery.value = query.toLowerCase();
    _applyFiltersAndSort();
  }

  /// Spor dalı filtresi
  void filterBySport(String? sport) {
    _selectedSport.value = sport;
    _applyFiltersAndSort();
  }

  /// Seviye filtresi
  void filterByLevel(AthleteLevel? level) {
    _selectedLevel.value = level;
    _applyFiltersAndSort();
  }

  /// Cinsiyet filtresi
  void filterByGender(Gender? gender) {
    _selectedGender.value = gender;
    _applyFiltersAndSort();
  }

  /// Tüm filtreleri temizle
  void clearFilters() {
    _searchQuery.value = '';
    _selectedSport.value = null;
    _selectedLevel.value = null;
    _selectedGender.value = null;
    _applyFiltersAndSort();
  }

  /// Sıralama türü güncelle
  void updateSortBy(AthleteSortBy sortBy) {
    if (_sortBy.value == sortBy) {
      _sortAscending.value = !_sortAscending.value;
    } else {
      _sortBy.value = sortBy;
      _sortAscending.value = true;
    }
    _applyFiltersAndSort();
  }

  /// Filtreleri ve sıralamayı uygula
  void _applyFiltersAndSort() {
    var filtered = _athletes.where((athlete) {
      // Search query filter
      if (_searchQuery.value.isNotEmpty) {
        final query = _searchQuery.value;
        final fullName = athlete.fullName.toLowerCase();
        final email = athlete.email?.toLowerCase() ?? '';
        final sport = athlete.sport?.toLowerCase() ?? '';
        
        if (!fullName.contains(query) && 
            !email.contains(query) && 
            !sport.contains(query)) {
          return false;
        }
      }
      
      // Sport filter
      if (_selectedSport.value != null && athlete.sport != _selectedSport.value) {
        return false;
      }
      
      // Level filter
      if (_selectedLevel.value != null && athlete.level != _selectedLevel.value) {
        return false;
      }
      
      // Gender filter
      if (_selectedGender.value != null && athlete.gender != _selectedGender.value) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy.value) {
        case AthleteSortBy.name:
          comparison = a.fullName.compareTo(b.fullName);
          break;
        case AthleteSortBy.sport:
          comparison = (a.sport ?? '').compareTo(b.sport ?? '');
          break;
        case AthleteSortBy.level:
          final aLevel = a.level?.index ?? -1;
          final bLevel = b.level?.index ?? -1;
          comparison = aLevel.compareTo(bLevel);
          break;
        case AthleteSortBy.age:
          final aAge = a.age ?? 0;
          final bAge = b.age ?? 0;
          comparison = aAge.compareTo(bAge);
          break;
        case AthleteSortBy.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case AthleteSortBy.profileCompletion:
          comparison = a.profileCompletion.compareTo(b.profileCompletion);
          break;
      }
      
      return _sortAscending.value ? comparison : -comparison;
    });
    
    _filteredAthletes.value = filtered;
  }

  // ===== HELPER METHODS =====
  
  /// Email'in zaten var olup olmadığını kontrol et
  Future<bool> _isEmailExists(String email) async {
    return _athletes.any((athlete) => athlete.email?.toLowerCase() == email.toLowerCase());
  }

  // ===== STATISTICS =====

  /// İstatistikleri güncelle
  void _updateStatistics() {
    if (_athletes.isEmpty) {
      _athleteStats.value = const AthleteStatistics();
      return;
    }
    
    final totalCount = _athletes.length;
    final maleCount = _athletes.where((a) => a.gender == Gender.male).length;
    final femaleCount = _athletes.where((a) => a.gender == Gender.female).length;
    
    // Sport distribution
    final sportMap = <String, int>{};
    for (final athlete in _athletes) {
      if (athlete.sport?.isNotEmpty == true) {
        sportMap[athlete.sport!] = (sportMap[athlete.sport!] ?? 0) + 1;
      }
    }
    
    // Level distribution
    final levelMap = <AthleteLevel, int>{};
    for (final athlete in _athletes) {
      if (athlete.level != null) {
        levelMap[athlete.level!] = (levelMap[athlete.level!] ?? 0) + 1;
      }
    }
    
    // Age groups
    final ageGroups = <String, int>{};
    for (final athlete in _athletes) {
      final ageGroup = athlete.ageGroup;
      ageGroups[ageGroup] = (ageGroups[ageGroup] ?? 0) + 1;
    }
    
    // Profile completion
    final completeProfiles = _athletes.where((a) => a.isProfileComplete).length;
    final avgCompletion = _athletes
        .map((a) => a.profileCompletion)
        .reduce((a, b) => a + b) / _athletes.length;
    
    _athleteStats.value = AthleteStatistics(
      totalCount: totalCount,
      maleCount: maleCount,
      femaleCount: femaleCount,
      sportDistribution: sportMap,
      levelDistribution: levelMap,
      ageGroupDistribution: ageGroups,
      completeProfilesCount: completeProfiles,
      avgProfileCompletion: avgCompletion,
    );
  }

  // ===== BULK OPERATIONS =====

  /// Seçili sporcuları sil
  Future<bool> deleteMultipleAthletes(List<String> athleteIds) async {
    _setSaving(true);
    
    try {
      final db = DatabaseHelper.instance;
      
      for (final id in athleteIds) {
        await db.deleteAthlete(id);
        _athletes.removeWhere((a) => a.id == id);
      }
      
      _applyFiltersAndSort();
      _updateStatistics();
      
      AppLogger.info('🗑️ ${athleteIds.length} sporcu toplu silindi');
      _clearError();
      return true;
      
    } catch (e) {
      AppLogger.dbError('deleteMultipleAthletes', e.toString());
      _setError('Toplu silme başarısız: $e');
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Export athletes to CSV/JSON
  Future<String> exportAthletes({String format = 'json'}) async {
    try {
      final athleteData = _athletes.map((a) => a.toJson()).toList();
      
      if (format == 'json') {
        // Return JSON string for file export
        return athleteData.toString();
      }
      
      // CSV format would be implemented here
      return 'CSV export not implemented yet';
      
    } catch (e, stackTrace) {
      AppLogger.error('Sporcu export hatası', e, stackTrace);
      throw Exception('Export başarısız: $e');
    }
  }

  // ===== UTILITY METHODS =====

  /// Sporcu bul (ID ile)
  Athlete? findAthleteById(String id) {
    try {
      return _athletes.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Sporcu bul (email ile)
  Athlete? findAthleteByEmail(String email) {
    try {
      return _athletes.firstWhere((a) => a.email == email);
    } catch (e) {
      return null;
    }
  }

  /// En son test yapan sporcular
  List<Athlete> getRecentlyTestedAthletes({int limit = 10}) {
    // This would require test history analysis
    // For now, return most recently created athletes
    final recent = List<Athlete>.from(_athletes);
    recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return recent.take(limit).toList();
  }

  /// Aktif sporcular (son 30 günde test yapan)
  List<Athlete> getActiveAthletes() {
    // This would require cross-referencing with test history
    // For now, return all athletes
    return _athletes.toList();
  }

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setSaving(bool saving) {
    _isSaving.value = saving;
  }

  void _setError(String message) {
    _errorMessage.value = message;
    AppLogger.error('👥 Athlete Controller Error: $message');
  }

  void _clearError() {
    _errorMessage.value = null;
  }

  /// Safe test type enum getter
  TestType _getTestTypeEnum(String testTypeStr) {
    // First try to match by enum name
    try {
      return TestType.values.firstWhere((e) => e.name == testTypeStr);
    } catch (e) {
      // If not found, try to match by code (CMJ, SJ, etc.)
      try {
        return TestType.values.firstWhere((e) => e.code == testTypeStr);
      } catch (e) {
        // If still not found, try case-insensitive matching
        try {
          return TestType.values.firstWhere((e) => 
            e.name.toLowerCase() == testTypeStr.toLowerCase() ||
            e.code.toLowerCase() == testTypeStr.toLowerCase()
          );
        } catch (e) {
          // Default to counterMovementJump if no match found
          return TestType.counterMovementJump;
        }
      }
    }
  }

  /// Safe test status enum getter
  TestStatus _getTestStatusEnum(String statusStr) {
    try {
      return TestStatus.values.firstWhere((e) => e.name == statusStr);
    } catch (e) {
      // Try case-insensitive matching
      try {
        return TestStatus.values.firstWhere((e) => 
          e.name.toLowerCase() == statusStr.toLowerCase() ||
          e.englishName.toLowerCase() == statusStr.toLowerCase()
        );
      } catch (e) {
        // Default to completed if no match found
        return TestStatus.completed;
      }
    }
  }
}

/// Sporcu sıralama türleri
enum AthleteSortBy {
  name('Name', 'İsim'),
  sport('Sport', 'Spor'),
  level('Level', 'Seviye'),
  age('Age', 'Yaş'),
  createdAt('Created', 'Oluşturma'),
  profileCompletion('Profile', 'Profil');

  const AthleteSortBy(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}

/// Sporcu istatistikleri
class AthleteStatistics {
  final int totalCount;
  final int maleCount;
  final int femaleCount;
  final Map<String, int> sportDistribution;
  final Map<AthleteLevel, int> levelDistribution;
  final Map<String, int> ageGroupDistribution;
  final int completeProfilesCount;
  final double avgProfileCompletion;

  const AthleteStatistics({
    this.totalCount = 0,
    this.maleCount = 0,
    this.femaleCount = 0,
    this.sportDistribution = const {},
    this.levelDistribution = const {},
    this.ageGroupDistribution = const {},
    this.completeProfilesCount = 0,
    this.avgProfileCompletion = 0.0,
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

  /// Cinsiyet dağılım yüzdesi
  double get malePercentage => totalCount > 0 ? (maleCount / totalCount) * 100 : 0.0;
  double get femalePercentage => totalCount > 0 ? (femaleCount / totalCount) * 100 : 0.0;
}