import 'dart:math' as math;

import '../constants/app_constants.dart';
import '../database/database_helper.dart';
import '../utils/app_logger.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/entities/test_result.dart';

/// Demo data yöneticisi - Uygulamayı öğrenmek için kapsamlı demo verileri sağlar
class DemoDataManager {
  
  /// Demo verilerinin yüklü olup olmadığını kontrol et
  static Future<bool> isDemoDataLoaded() async {
    try {
      final db = DatabaseHelper.instance;
      final athletes = await db.getAllAthletes();
      return athletes.any((athlete) => athlete['email']?.toString().contains('@demo.izforce') == true);
    } catch (e) {
      return false;
    }
  }
  
  /// Demo verileri yükle
  static Future<bool> loadDemoData() async {
    try {
      AppLogger.info('🎭 Demo verileri yükleniyor...');
      
      // Önce eski mock sporcuları temizle
      await clearOldMockAthletes();
      
      // Demo sporcuları oluştur
      final demoAthletes = _createDemoAthletes();
      
      // Sporcuları database'e kaydet
      final db = DatabaseHelper.instance;
      final athleteIds = <String>[];
      
      for (final athlete in demoAthletes) {
        try {
          await db.insertAthlete(athlete.toMap());
          athleteIds.add(athlete.id);
          AppLogger.debug('Demo sporcu eklendi: ${athlete.fullName}');
        } catch (e) {
          AppLogger.warning('Demo sporcu zaten mevcut: ${athlete.fullName}');
          athleteIds.add(athlete.id);
        }
      }
      
      // Her sporcu için comprehensive test results oluştur
      for (int i = 0; i < athleteIds.length; i++) {
        final athleteId = athleteIds[i];
        final athlete = demoAthletes[i];
        
        final testResults = _generateComprehensiveTestResults(athleteId, athlete);
        
        for (final result in testResults) {
          try {
            // Test session'ı kaydet
            await db.insertTestSession({
              'id': result.sessionId,
              'athleteId': athleteId,
              'testType': result.testType.name,
              'testDate': result.testDate.toIso8601String(),
              'duration': result.duration.inMilliseconds,
              'status': result.status.name,
              'notes': result.notes,
              'createdAt': result.createdAt.toIso8601String(),
            });
            
            // Test metrics'lerini kaydet
            await db.insertTestResultsBatch(result.sessionId, result.metrics);
          } catch (e) {
            AppLogger.debug('Test result zaten mevcut: ${result.id}');
          }
        }
      }
      
      AppLogger.success('✅ Demo verileri başarıyla yüklendi');
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error('Demo data yükleme hatası', e, stackTrace);
      return false;
    }
  }
  
  /// Demo verileri temizle
  static Future<bool> clearDemoData() async {
    try {
      AppLogger.info('🗑️ Demo verileri temizleniyor...');
      
      final db = DatabaseHelper.instance;
      final athletes = await db.getAllAthletes();
      
      int deletedCount = 0;
      for (final athlete in athletes) {
        final email = athlete['email']?.toString() ?? '';
        if (email.contains('@demo.izforce')) {
          final athleteId = athlete['id'] as String;
          
          // Sporcu ve ilgili tüm test verilerini sil
          await db.deleteAthlete(athleteId);
          deletedCount++;
        }
      }
      
      AppLogger.success('✅ $deletedCount demo sporcu ve verileri temizlendi');
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error('Demo data temizleme hatası', e, stackTrace);
      return false;
    }
  }

  /// Eski mock sporcuları temizle
  static Future<bool> clearOldMockAthletes() async {
    try {
      AppLogger.info('🧹 Eski mock sporcuları temizleniyor...');
      
      final db = DatabaseHelper.instance;
      final athletes = await db.getAllAthletes();
      
      // Bilinen eski mock sporcu isimleri
      final oldMockNames = [
        'Ahmet Yılmaz',
        'Fatma Kaya', 
        'Mehmet Demir',
        'Ayşe Özkan',
        'Can Arslan'
      ];
      
      int deletedCount = 0;
      for (final athlete in athletes) {
        final firstName = athlete['firstName']?.toString() ?? '';
        final lastName = athlete['lastName']?.toString() ?? '';
        final fullName = '$firstName $lastName';
        
        if (oldMockNames.contains(fullName)) {
          final athleteId = athlete['id'] as String;
          await db.deleteAthlete(athleteId);
          deletedCount++;
          AppLogger.debug('Eski mock sporcu silindi: $fullName');
        }
      }
      
      AppLogger.success('✅ $deletedCount eski mock sporcu temizlendi');
      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error('Eski mock data temizleme hatası', e, stackTrace);
      return false;
    }
  }
  
  /// Demo sporcuları oluştur - Genişletilmiş profiller
  static List<Athlete> _createDemoAthletes() {
    return [
      // 1. Profesyonel basketbolcu - Elite performans
      Athlete.create(
        firstName: 'Emre',
        lastName: 'Yıldırım',
        email: 'emre.yildirim@demo.izforce',
        dateOfBirth: DateTime(1994, 3, 15),
        gender: Gender.male,
        height: 195,
        weight: 88,
        sport: 'Basketbol',
        position: 'Power Forward',
        level: AthleteLevel.professional,
        notes: 'Demo veri - Elit seviye basketbol oyuncusu. Güçlü sıçrama ve explosif güç.',
      ),
      
      // 2. Kadın voleybolcu - Deneyimli sporcu
      Athlete.create(
        firstName: 'Zehra',
        lastName: 'Güneş',
        email: 'zehra.gunes@demo.izforce',
        dateOfBirth: DateTime(1997, 7, 7),
        gender: Gender.female,
        height: 188,
        weight: 72,
        sport: 'Voleybol',
        position: 'Orta Oyuncu',
        level: AthleteLevel.elite,
        notes: 'Demo veri - Milli takım seviyesi voleybolcu. Dikey sıçrama uzmanı.',
      ),
      
      // 3. Genç futbolcu - Gelişen yetenek
      Athlete.create(
        firstName: 'Arda',
        lastName: 'Kılıç',
        email: 'arda.kilic@demo.izforce',
        dateOfBirth: DateTime(2001, 11, 22),
        gender: Gender.male,
        height: 178,
        weight: 71,
        sport: 'Futbol',
        position: 'Kanat Oyuncusu',
        level: AthleteLevel.semipro,
        notes: 'Demo veri - Genç yetenek. Sürat ve çeviklik odaklı gelişim programında.',
      ),

      // 4. Atletizm sporcusu - Kuvvet ve hız odaklı
      Athlete.create(
        firstName: 'Burcu',
        lastName: 'Çelik',
        email: 'burcu.celik@demo.izforce',
        dateOfBirth: DateTime(1999, 9, 12),
        gender: Gender.female,
        height: 168,
        weight: 58,
        sport: 'Atletizm',
        position: '100m Sprint',
        level: AthleteLevel.elite,
        notes: 'Demo veri - Sprint uzmanı. Reaktif güç ve çeviklik odaklı.',
      ),

      // 5. Genç amerikan futbolu oyuncusu
      Athlete.create(
        firstName: 'Kemal',
        lastName: 'Arslan',
        email: 'kemal.arslan@demo.izforce',
        dateOfBirth: DateTime(1995, 1, 8),
        gender: Gender.male,
        height: 185,
        weight: 95,
        sport: 'Amerikan Futbolu',
        position: 'Linebacker',
        level: AthleteLevel.semipro,
        notes: 'Demo veri - Güç ve explosivite odaklı sporcu. Fonksiyonel testler.',
      ),

      // 6. Rekreasyonel sporcu - Fitness
      Athlete.create(
        firstName: 'Ayşe',
        lastName: 'Demir',
        email: 'ayse.demir@demo.izforce',
        dateOfBirth: DateTime(1988, 5, 20),
        gender: Gender.female,
        height: 165,
        weight: 63,
        sport: 'Fitness',
        position: 'Genel Kondisyon',
        level: AthleteLevel.recreational,
        notes: 'Demo veri - Rekreasyonel sporcu. Denge ve fonksiyonel hareket odaklı.',
      ),

      // 7. Yaşlı sporcu - Masters kategorisi
      Athlete.create(
        firstName: 'Mehmet',
        lastName: 'Öz',
        email: 'mehmet.oz@demo.izforce',
        dateOfBirth: DateTime(1965, 11, 3),
        gender: Gender.male,
        height: 175,
        weight: 78,
        sport: 'Tenis',
        position: 'Rekreasyonel',
        level: AthleteLevel.amateur,
        notes: 'Demo veri - Masters kategorisi sporcu. Denge ve mobilite testleri.',
      ),

      // 8. Sakatlanma rehabilitasyon hastası
      Athlete.create(
        firstName: 'Selin',
        lastName: 'Kaya',
        email: 'selin.kaya@demo.izforce',
        dateOfBirth: DateTime(1996, 4, 18),
        gender: Gender.female,
        height: 172,
        weight: 65,
        sport: 'Rehabilitasyon',
        position: 'Diz Cerrahisi Post-Op',
        level: AthleteLevel.recreational,
        notes: 'Demo veri - ACL rekonstrüksiyon sonrası rehabilitasyon. Asimetri takibi.',
      ),
    ];
  }
  
  /// Kapsamlı test sonuçları oluştur
  static List<TestResult> _generateComprehensiveTestResults(String athleteId, Athlete athlete) {
    final results = <TestResult>[];
    final random = math.Random(42); // Sabit seed ile tutarlı sonuçlar
    final now = DateTime.now();
    
    // Sporcu profiline göre base değerler
    final baseValues = _getAthleteBaseValues(athlete);
    
    // Son 12 ay boyunca test sonuçları - TÜM TEST TÜRLERİ DAHİL
    // İlk 6 ay: sık testler (haftalık 4-6 test)
    // Son 6 ay: orta sıklık (2 haftada bir 2-4 test)
    final totalWeeks = 48; // 12 ay
    
    // SPORCU PROFİLİNE GÖRE TEST SEÇİMİ
    final testProfile = _getAthleteTestProfile(athlete);
    
    for (int week = 0; week < totalWeeks; week++) {
      final testDate = now.subtract(Duration(days: week * 7));
      
      // İlk 6 ayda daha sık ve çeşitli testler
      if (week < 24) {
        // Haftalık test sayısı (4-6 test)
        final weeklyTestCount = 4 + (week % 3);
        final testTypes = _selectWeeklyTests(testProfile, week, weeklyTestCount, athleteId);
        
        _addWeeklyTests(results, testTypes, testDate, week, baseValues, random, athleteId, totalWeeks);
      } else if (week % 2 == 0) {
        // Son 6 ayda 2 haftada bir - odaklanmış testler
        final testTypes = _selectFocusedTests(testProfile, week, athleteId);
        
        _addWeeklyTests(results, testTypes, testDate, week, baseValues, random, athleteId, totalWeeks);
      }
    }
    
    return results;
  }
  
  static void _addWeeklyTests(
    List<TestResult> results,
    List<TestType> testTypes,
    DateTime testDate,
    int week,
    Map<String, double> baseValues,
    math.Random random,
    String athleteId,
    int totalWeeks,
  ) {
      
      for (final testType in testTypes) {
        // Progress simulation - zamanla gelişim
        final progressFactor = (totalWeeks - week) / totalWeeks.toDouble();
        final sessionMetrics = _generateRealisticMetrics(
          testType, 
          baseValues, 
          progressFactor, 
          random,
          week,
        );
        
        final result = TestResult.create(
          sessionId: 'demo_session_${testDate.millisecondsSinceEpoch}_${testType.name}',
          athleteId: athleteId,
          testType: testType,
          testDate: testDate,
          duration: _getTestDuration(testType, random),
          metrics: sessionMetrics,
          notes: _getTestNotes(week, testType),
        );
        
        results.add(result);
      }
  }
  
  /// Test notları oluştur
  static String _getTestNotes(int week, TestType testType) {
    if (week < 4) {
      return 'Demo veri - Son ay ${testType.turkishName} testi';
    } else if (week < 12) {
      return 'Demo veri - Son 3 ay performans takibi';
    } else if (week < 24) {
      return 'Demo veri - 6 aylık gelişim programı';
    } else {
      return 'Demo veri - Baseline ölçüm';
    }
  }
  
  /// Sporcu profiline göre base değerler
  static Map<String, double> _getAthleteBaseValues(Athlete athlete) {
    // Cinsiyet, spor dalı ve seviyeye göre temel değerler
    final isMale = athlete.gender == Gender.male;
    final level = athlete.level ?? AthleteLevel.recreational;
    final sport = athlete.sport?.toLowerCase() ?? '';
    
    double jumpHeightBase = isMale ? 40.0 : 32.0;
    double peakForceBase = isMale ? 2200.0 : 1600.0;
    double rfdBase = isMale ? 4500.0 : 3200.0;
    
    // Spor dalına göre ayarlama
    if (sport.contains('basketbol') || sport.contains('voleybol')) {
      jumpHeightBase *= 1.15; // Sıçrama sporları
      rfdBase *= 1.10;
    } else if (sport.contains('futbol')) {
      jumpHeightBase *= 1.05;
      peakForceBase *= 1.08;
    }
    
    // Seviyeye göre ayarlama
    switch (level) {
      case AthleteLevel.elite:
      case AthleteLevel.professional:
        jumpHeightBase *= 1.20;
        peakForceBase *= 1.25;
        rfdBase *= 1.30;
        break;
      case AthleteLevel.semipro:
        jumpHeightBase *= 1.10;
        peakForceBase *= 1.15;
        rfdBase *= 1.20;
        break;
      case AthleteLevel.amateur:
        jumpHeightBase *= 1.05;
        peakForceBase *= 1.10;
        rfdBase *= 1.15;
        break;
      default:
        break;
    }
    
    return {
      'jumpHeight': jumpHeightBase,
      'peakForce': peakForceBase,
      'rfd': rfdBase,
      'flightTime': _calculateFlightTime(jumpHeightBase),
      'asymmetryIndex': 5.0 + (athlete.level?.index ?? 0) * 2.0,
    };
  }
  
  /// Gerçekçi metrikler oluştur - TÜM TEST TİPLERİ İÇİN
  static Map<String, double> _generateRealisticMetrics(
    TestType testType,
    Map<String, double> baseValues,
    double progressFactor,
    math.Random random,
    int weekNumber,
  ) {
    final metrics = <String, double>{};
    
    // Progress ve noise faktörleri
    final progress = progressFactor * 0.15; // %15'e kadar gelişim
    final noise = (random.nextDouble() - 0.5) * 0.1; // ±%5 günlük varyasyon
    final fatigue = weekNumber % 4 == 0 ? -0.05 : 0.0; // Her 4 haftada yorgunluk
    
    switch (testType) {
      case TestType.counterMovementJump:
        // CMJ - EN KAPSAMLI TEST (39 metrik)
        final jumpHeight = baseValues['jumpHeight']! * (1 + progress + noise + fatigue);
        final peakForce = baseValues['peakForce']! * (1 + progress + noise * 0.5);
        final rfd = baseValues['rfd']! * (1 + progress + noise * 0.3);
        final flightTime = _calculateFlightTime(jumpHeight);
        
        // Basic metrics
        metrics.addAll({
          'jumpHeight': jumpHeight.clamp(20.0, 80.0),
          'peakForce': peakForce.clamp(800.0, 4000.0),
          'flightTime': flightTime,
          'contactTime': 800 + random.nextDouble() * 400, // 800-1200ms
          'rfd': rfd.clamp(2000.0, 8000.0),
          'impulse': peakForce * 0.25,
          'asymmetryIndex': (baseValues['asymmetryIndex']! * (1 + noise * 0.5)).clamp(2.0, 20.0),
          'leftLoadPercentage': 45 + random.nextDouble() * 10, // 45-55%
          'rightLoadPercentage': 45 + random.nextDouble() * 10,
          'takeoffVelocity': math.sqrt(2 * 9.81 * jumpHeight / 100),
          'peakPower': peakForce * math.sqrt(2 * 9.81 * jumpHeight / 100),
          'averageForce': peakForce * 0.65,
          'averagePower': peakForce * 0.65 * math.sqrt(2 * 9.81 * jumpHeight / 100) * 0.8,
          
          // Phase-specific metrics
          'eccentricPeakForce': peakForce * 0.85,
          'eccentricRFD': rfd * 0.75,
          'eccentricDuration': 250 + random.nextDouble() * 100,
          'concentricPeakForce': peakForce,
          'concentricRFD': rfd,
          'concentricDuration': 280 + random.nextDouble() * 80,
          'braking_rfd': rfd * 0.9,
          'braking_impulse': peakForce * 0.15,
          'propulsive_rfd': rfd * 1.1,
          'propulsive_impulse': peakForce * 0.2,
          
          // Time-specific forces
          'forceAt50ms': peakForce * 0.45,
          'forceAt100ms': peakForce * 0.65,
          'forceAt200ms': peakForce * 0.85,
          
          // Additional performance metrics
          'reactive_strength_index': jumpHeight / (280 + random.nextDouble() * 80),
          'movement_velocity_ratio': 0.85 + random.nextDouble() * 0.15,
          'forceCoefficientOfVariation': 0.05 + random.nextDouble() * 0.05,
          'startWeight': 80.0 + random.nextDouble() * 40.0,
          'peakVelocity': math.sqrt(2 * 9.81 * jumpHeight / 100) * 0.95,
          'timeToTakeoff': 580 + random.nextDouble() * 200,
          'landingRFD': rfd * 0.6,
          'peakLandingForce': peakForce * 1.8,
          'concentricWork': peakForce * jumpHeight * 0.01,
          'eccentricWork': peakForce * jumpHeight * 0.008,
          'netImpulse': peakForce * 0.3,
          'modifiedReactiveStrengthIndex': jumpHeight / flightTime,
        });
        break;
        
      case TestType.squatJump:
        // SJ - 7 metrik
        final jumpHeight = baseValues['jumpHeight']! * 0.92 * (1 + progress + noise);
        final peakForce = baseValues['peakForce']! * 1.05 * (1 + progress + noise * 0.5);
        
        metrics.addAll({
          'jumpHeight': jumpHeight.clamp(18.0, 75.0),
          'peakForce': peakForce.clamp(900.0, 4200.0),
          'flightTime': _calculateFlightTime(jumpHeight),
          'concentric_rfd': baseValues['rfd']! * 1.1 * (1 + progress),
          'asymmetryIndex': (baseValues['asymmetryIndex']! * 1.1 * (1 + noise * 0.5)).clamp(3.0, 25.0),
          'takeoffVelocity': math.sqrt(2 * 9.81 * jumpHeight / 100),
          'peakPower': peakForce * math.sqrt(2 * 9.81 * jumpHeight / 100),
        });
        break;
        
      case TestType.dropJump:
        // DJ - 11 metrik
        final jumpHeight = baseValues['jumpHeight']! * 0.95 * (1 + progress + noise);
        final peakForce = baseValues['peakForce']! * 2.2 * (1 + progress + noise * 0.5); // Higher landing forces
        final contactTime = 200 + random.nextDouble() * 100; // 200-300ms
        
        metrics.addAll({
          'jumpHeight': jumpHeight.clamp(20.0, 75.0),
          'contactTime': contactTime,
          'reactive_strength_index': jumpHeight / contactTime,
          'peakLandingForce': peakForce,
          'peakTakeoffForce': peakForce * 0.8,
          'landingRFD': baseValues['rfd']! * 2.5 * (1 + progress),
          'takeoffRFD': baseValues['rfd']! * 1.3 * (1 + progress),
          'landingAsymmetry': (baseValues['asymmetryIndex']! * 1.2).clamp(3.0, 25.0),
          'dropHeight': 40.0, // 40cm standard
          'landingImpulse': peakForce * 0.08,
          'flightTime': _calculateFlightTime(jumpHeight),
        });
        break;
        
      case TestType.isometricMidThighPull:
        // IMTP - 11 metrik
        final peakForce = baseValues['peakForce']! * 1.8 * (1 + progress + noise); // IMTP higher forces
        final rfd = baseValues['rfd']! * 1.2 * (1 + progress);
        
        metrics.addAll({
          'peakForce': peakForce.clamp(1500.0, 6000.0),
          'rfd_0_50': rfd * 0.7,
          'rfd_0_100': rfd * 0.85,
          'rfd_0_200': rfd,
          'impulse_0_100': peakForce * 0.08,
          'impulse_0_200': peakForce * 0.15,
          'asymmetryIndex': (baseValues['asymmetryIndex']! * 0.8 * (1 + noise * 0.3)).clamp(2.0, 15.0),
          'forceAt50ms': peakForce * 0.45,
          'forceAt100ms': peakForce * 0.6,
          'forceAt200ms': peakForce * 0.8,
          'averageForce': peakForce * 0.75,
          'relativeForce': peakForce / 80.0, // N/kg assuming 80kg
        });
        break;
        
      case TestType.staticBalance:
        final baseStability = 85.0 + (baseValues['asymmetryIndex']! * -2); // Better asymmetry = better balance
        
        metrics.addAll({
          'copRange': (15 + random.nextDouble() * 10) * (2 - progressFactor), // mm
          'copVelocity': (8 + random.nextDouble() * 6) * (2 - progressFactor), // mm/s
          'copArea': (120 + random.nextDouble() * 80) * (2 - progressFactor), // mm²
          'stabilityIndex': (baseStability * (1 + progress * 0.1)).clamp(60.0, 100.0),
          'mediolateralSway': 3 + random.nextDouble() * 4, // mm
          'anteroposteriorSway': 4 + random.nextDouble() * 5, // mm
          'eyesClosedRatio': 1.5 + random.nextDouble() * 0.8, // Eyes closed / open ratio
        });
        break;
        
      case TestType.isometricSquat:
        final peakForce = baseValues['peakForce']! * 1.4 * (1 + progress + noise);
        
        metrics.addAll({
          'peakForce': peakForce.clamp(1200.0, 5000.0),
          'rfd_0_100': baseValues['rfd']! * 0.9 * (1 + progress),
          'rfd_0_200': baseValues['rfd']! * 1.1 * (1 + progress),
          'impulse_0_200': peakForce * 0.12,
          'asymmetryIndex': (baseValues['asymmetryIndex']! * 0.9 * (1 + noise * 0.3)).clamp(2.0, 18.0),
          'forceAt100ms': peakForce * 0.65,
          'averageForce': peakForce * 0.85,
        });
        break;
        
      case TestType.dynamicBalance:
        final baseStability = 75.0 + (baseValues['asymmetryIndex']! * -1.5);
        
        metrics.addAll({
          'copRange': (25 + random.nextDouble() * 15) * (2 - progressFactor), // mm
          'copVelocity': (15 + random.nextDouble() * 10) * (2 - progressFactor), // mm/s
          'copArea': (200 + random.nextDouble() * 120) * (2 - progressFactor), // mm²
          'stabilityIndex': (baseStability * (1 + progress * 0.15)).clamp(50.0, 95.0),
          'mediolateralSway': 8 + random.nextDouble() * 6, // mm
          'anteroposteriorSway': 10 + random.nextDouble() * 8, // mm
          'dynamicStabilityIndex': 65 + random.nextDouble() * 25, // Custom metric
        });
        break;
        
      case TestType.singleLegBalance:
        // Tek bacak denge - 7 metrik
        final baseStability = 70.0 + (baseValues['asymmetryIndex']! * -3);
        
        metrics.addAll({
          'copRange': (35 + random.nextDouble() * 20) * (2 - progressFactor), // mm
          'copVelocity': (20 + random.nextDouble() * 15) * (2 - progressFactor), // mm/s
          'copArea': (300 + random.nextDouble() * 200) * (2 - progressFactor), // mm²
          'stabilityIndex': (baseStability * (1 + progress * 0.2)).clamp(40.0, 90.0),
          'mediolateralSway': 12 + random.nextDouble() * 10, // mm
          'anteroposteriorSway': 15 + random.nextDouble() * 12, // mm
          'timeToStabilization': 2.5 + random.nextDouble() * 2.0, // seconds
        });
        break;
        
      case TestType.singleLegCmj:
        // Tek bacak CMJ - 6 metrik
        final jumpHeight = baseValues['jumpHeight']! * 0.65 * (1 + progress + noise); // Single leg ~65% of bilateral
        final peakForce = baseValues['peakForce']! * 0.55 * (1 + progress + noise * 0.5);
        
        metrics.addAll({
          'jumpHeight': jumpHeight.clamp(12.0, 50.0),
          'peakForce': peakForce.clamp(500.0, 2500.0),
          'flightTime': _calculateFlightTime(jumpHeight),
          'contactTime': 900 + random.nextDouble() * 500, // 900-1400ms
          'bilateralDeficit': 25 + random.nextDouble() * 15, // % difference from bilateral
          'stabilityIndex': 65 + random.nextDouble() * 20,
        });
        break;
        
      case TestType.abalakov:
        // Abalakov (arm swing) - 6 metrik
        final jumpHeight = baseValues['jumpHeight']! * 1.15 * (1 + progress + noise); // +15% with arms
        final peakForce = baseValues['peakForce']! * 0.95 * (1 + progress + noise * 0.5);
        
        metrics.addAll({
          'jumpHeight': jumpHeight.clamp(25.0, 90.0),
          'peakForce': peakForce.clamp(800.0, 3800.0),
          'flightTime': _calculateFlightTime(jumpHeight),
          'armContribution': 12 + random.nextDouble() * 8, // % contribution from arms
          'takeoffVelocity': math.sqrt(2 * 9.81 * jumpHeight / 100),
          'peakPower': peakForce * math.sqrt(2 * 9.81 * jumpHeight / 100),
        });
        break;
        
      case TestType.squatAssessment:
        // Squat Assessment - 5 metrik
        final stability = 75 + random.nextDouble() * 20;
        
        metrics.addAll({
          'depthAchieved': 85 + random.nextDouble() * 15, // % of full depth
          'kneeValgusAngle': 5 + random.nextDouble() * 10, // degrees
          'trunkLeanAngle': 15 + random.nextDouble() * 15, // degrees
          'movementQualityScore': stability,
          'asymmetryIndex': (baseValues['asymmetryIndex']! * 0.8).clamp(2.0, 15.0),
        });
        break;
        
      case TestType.hopTest:
        // Hop Test - 5 metrik
        final hopDistance = 180 + random.nextDouble() * 60; // cm
        
        metrics.addAll({
          'hopDistance': hopDistance * (1 + progress * 0.1),
          'landingStability': 70 + random.nextDouble() * 25,
          'limbSymmetryIndex': 90 + random.nextDouble() * 10, // %
          'contactTime': 250 + random.nextDouble() * 150, // ms
          'hopHeight': hopDistance * 0.15, // Estimated from distance
        });
        break;

      // ===== YENİ TEST TÜRLERİ =====

      case TestType.cmjLoaded:
        // CMJ Loaded - 8 metrik
        final jumpHeight = baseValues['jumpHeight']! * 0.85 * (1 + progress + noise); // Reduced due to load
        final peakForce = baseValues['peakForce']! * 1.4 * (1 + progress + noise * 0.5); // Higher due to load
        final loadWeight = 15 + random.nextDouble() * 25; // 15-40kg
        
        metrics.addAll({
          'jumpHeight': jumpHeight.clamp(15.0, 65.0),
          'peakForce': peakForce.clamp(1200.0, 5000.0),
          'flightTime': _calculateFlightTime(jumpHeight),
          'loadWeight': loadWeight,
          'relativeJumpHeight': jumpHeight / (baseValues['jumpHeight']! * 0.01), // % of unloaded
          'forceToWeightRatio': peakForce / (80 + loadWeight), // Force per kg total weight
          'powerOutput': peakForce * math.sqrt(2 * 9.81 * jumpHeight / 100),
          'asymmetryIndex': (baseValues['asymmetryIndex']! * 1.2).clamp(3.0, 20.0),
        });
        break;

      case TestType.singleLegDj:
        // Single Leg Drop Jump - 9 metrik
        final jumpHeight = baseValues['jumpHeight']! * 0.55 * (1 + progress + noise); // Lower for single leg
        final contactTime = 250 + random.nextDouble() * 150; // ms
        final peakForce = baseValues['peakForce']! * 1.8 * (1 + progress);
        
        metrics.addAll({
          'jumpHeight': jumpHeight.clamp(10.0, 35.0),
          'contactTime': contactTime,
          'reactiveStrengthIndex': jumpHeight / contactTime,
          'peakLandingForce': peakForce,
          'landingRFD': baseValues['rfd']! * 2.0,
          'stabilityIndex': 60 + random.nextDouble() * 25,
          'dropHeight': 30.0, // cm
          'bilateralDeficit': 35 + random.nextDouble() * 20, // % difference
          'timeToStabilization': 1.5 + random.nextDouble() * 1.0, // seconds
        });
        break;

      case TestType.singleLegSquat:
        // Single Leg Squat - 6 metrik
        final stability = 65 + random.nextDouble() * 25;
        
        metrics.addAll({
          'depthAchieved': 70 + random.nextDouble() * 20, // % (lower than bilateral)
          'kneeStability': stability,
          'hipStability': stability * 0.9,
          'movementQualityScore': stability,
          'completionRate': 80 + random.nextDouble() * 20, // % successful reps
          'asymmetryIndex': (baseValues['asymmetryIndex']! * 1.5).clamp(5.0, 30.0),
        });
        break;

      case TestType.pushUp:
        // Push Up - 6 metrik
        final peakForce = baseValues['peakForce']! * 0.3 * (1 + progress); // Upper body force
        
        metrics.addAll({
          'peakForce': peakForce.clamp(200.0, 800.0),
          'averageForce': peakForce * 0.7,
          'forceSymmetry': 85 + random.nextDouble() * 15, // % left-right symmetry
          'movementVelocity': 0.5 + random.nextDouble() * 0.3, // m/s
          'rangeOfMotion': 85 + random.nextDouble() * 15, // % full ROM
          'powerOutput': peakForce * 0.3, // Watts
        });
        break;

      case TestType.sitToStand:
        // Sit to Stand - 7 metrik
        final transitionTime = 1.5 + random.nextDouble() * 1.0; // seconds
        final peakForce = baseValues['peakForce']! * 0.8 * (1 + progress);
        
        metrics.addAll({
          'transitionTime': transitionTime,
          'peakForce': peakForce.clamp(800.0, 2500.0),
          'rfd': baseValues['rfd']! * 0.6,
          'asymmetryIndex': (baseValues['asymmetryIndex']! * 0.9).clamp(3.0, 18.0),
          'stabilityPhaseTime': 0.5 + random.nextDouble() * 0.5, // seconds
          'movementEfficiency': 70 + random.nextDouble() * 25, // score
          'completionSuccess': 90 + random.nextDouble() * 10, // % success rate
        });
        break;

      case TestType.isometricShoulder:
        // Isometric Shoulder - 6 metrik
        final peakForce = baseValues['peakForce']! * 0.4 * (1 + progress); // Shoulder specific
        
        metrics.addAll({
          'peakForce': peakForce.clamp(300.0, 1200.0),
          'rfd_0_100': baseValues['rfd']! * 0.5,
          'holdTime': 4.5 + random.nextDouble() * 1.0, // seconds
          'forceStability': 85 + random.nextDouble() * 15, // % CV
          'asymmetryIndex': (baseValues['asymmetryIndex']! * 1.1).clamp(3.0, 20.0),
          'fatigueIndex': 5 + random.nextDouble() * 15, // % force decline
        });
        break;

      case TestType.singleLegIsometric:
        // Single Leg Isometric - 7 metrik
        final peakForce = baseValues['peakForce']! * 0.6 * (1 + progress);
        
        metrics.addAll({
          'peakForce': peakForce.clamp(600.0, 2000.0),
          'rfd_0_100': baseValues['rfd']! * 0.7,
          'holdTime': 4.0 + random.nextDouble() * 2.0,
          'stabilityIndex': 65 + random.nextDouble() * 25,
          'bilateralDeficit': 20 + random.nextDouble() * 25, // %
          'forceVariability': 8 + random.nextDouble() * 12, // % CV
          'timeToTarget': 1.5 + random.nextDouble() * 1.0, // seconds
        });
        break;

      case TestType.customIsometric:
        // Custom Isometric - 5 metrik
        final peakForce = baseValues['peakForce']! * (0.7 + random.nextDouble() * 0.6);
        
        metrics.addAll({
          'peakForce': peakForce.clamp(500.0, 3500.0),
          'averageForce': peakForce * 0.8,
          'rfd': baseValues['rfd']! * (0.8 + random.nextDouble() * 0.4),
          'holdTime': 3.0 + random.nextDouble() * 5.0,
          'qualityScore': 70 + random.nextDouble() * 25,
        });
        break;

      case TestType.singleLegRangeOfStability:
        // Single Leg Range of Stability - 8 metrik
        final baseStability = 60.0 + (baseValues['asymmetryIndex']! * -2);
        
        metrics.addAll({
          'anteriorReach': 65 + random.nextDouble() * 25, // % leg length
          'posteriorReach': 55 + random.nextDouble() * 20,
          'medialReach': 45 + random.nextDouble() * 15,
          'lateralReach': 50 + random.nextDouble() * 20,
          'overallStability': (baseStability * (1 + progress * 0.2)).clamp(40.0, 90.0),
          'asymmetryIndex': (baseValues['asymmetryIndex']! * 1.8).clamp(8.0, 40.0),
          'timeToComplete': 45 + random.nextDouble() * 30, // seconds
          'errorRate': 5 + random.nextDouble() * 15, // % failed reaches
        });
        break;

      case TestType.anteriorPosteriorHop:
        // Anterior Posterior Hop - 6 metrik
        final hopDistance = 120 + random.nextDouble() * 40; // cm (AP direction)
        
        metrics.addAll({
          'hopDistanceForward': hopDistance * (1 + progress * 0.1),
          'hopDistanceBackward': hopDistance * 0.85, // Typically less backward
          'contactTime': 220 + random.nextDouble() * 120, // ms
          'limbSymmetryIndex': 88 + random.nextDouble() * 12, // %
          'stabilityIndex': 70 + random.nextDouble() * 25,
          'directionControlScore': 75 + random.nextDouble() * 20,
        });
        break;

      case TestType.medialLateralHop:
        // Medial Lateral Hop - 6 metrik
        final hopDistance = 100 + random.nextDouble() * 30; // cm (ML direction)
        
        metrics.addAll({
          'hopDistanceMedial': hopDistance * (1 + progress * 0.1),
          'hopDistanceLateral': hopDistance * 1.1, // Typically more lateral
          'contactTime': 240 + random.nextDouble() * 140, // ms
          'limbSymmetryIndex': 85 + random.nextDouble() * 15, // %
          'stabilityIndex': 65 + random.nextDouble() * 25,
          'directionControlScore': 70 + random.nextDouble() * 25,
        });
        break;

      case TestType.cmjRebound:
        // CMJ Rebound - 8 metrik
        final avgJumpHeight = baseValues['jumpHeight']! * 0.9 * (1 + progress);
        final jumpCount = 8 + random.nextInt(7); // 8-15 jumps
        
        metrics.addAll({
          'averageJumpHeight': avgJumpHeight.clamp(20.0, 70.0),
          'peakJumpHeight': avgJumpHeight * 1.15,
          'lowestJumpHeight': avgJumpHeight * 0.75,
          'jumpCount': jumpCount.toDouble(),
          'averageContactTime': 250 + random.nextDouble() * 100, // ms
          'fatigueIndex': 8 + random.nextDouble() * 15, // % decline
          'consistencyIndex': 85 + random.nextDouble() * 12, // % CV
          'reactiveStrengthIndex': avgJumpHeight / (250 + random.nextDouble() * 100),
        });
        break;

      case TestType.landAndHold:
        // Land and Hold - 7 metrik
        final peakForce = baseValues['peakForce']! * 2.5 * (1 + progress); // High landing forces
        
        metrics.addAll({
          'peakLandingForce': peakForce.clamp(1500.0, 6000.0),
          'timeToStabilization': 1.2 + random.nextDouble() * 1.5, // seconds
          'stabilityIndex': 70 + random.nextDouble() * 25,
          'asymmetryIndex': (baseValues['asymmetryIndex']! * 1.3).clamp(5.0, 25.0),
          'dropHeight': 40.0, // cm
          'holdDuration': 3.0, // seconds (required hold)
          'landingControlScore': 75 + random.nextDouble() * 20,
        });
        break;

      case TestType.singleLegLandAndHold:
        // Single Leg Land and Hold - 8 metrik
        final peakForce = baseValues['peakForce']! * 1.8 * (1 + progress); // Single leg landing
        
        metrics.addAll({
          'peakLandingForce': peakForce.clamp(800.0, 3500.0),
          'timeToStabilization': 2.0 + random.nextDouble() * 2.0, // seconds (longer for single leg)
          'stabilityIndex': 55 + random.nextDouble() * 30,
          'dropHeight': 30.0, // cm (lower for single leg)
          'holdDuration': 3.0, // seconds
          'balanceQuality': 60 + random.nextDouble() * 30,
          'bilateralDeficit': 25 + random.nextDouble() * 20, // %
          'completionRate': 75 + random.nextDouble() * 20, // % successful attempts
        });
        break;

      case TestType.singleLegHop:
        // Single Leg Hop - 7 metrik
        final hopDistance = 150 + random.nextDouble() * 50; // cm
        
        metrics.addAll({
          'hopDistance': hopDistance * (1 + progress * 0.1),
          'hopHeight': hopDistance * 0.2, // Estimated
          'contactTime': 280 + random.nextDouble() * 180, // ms
          'flightTime': 300 + random.nextDouble() * 150, // ms
          'stabilityIndex': 65 + random.nextDouble() * 25,
          'bilateralDeficit': 20 + random.nextDouble() * 25, // %
          'landingQuality': 70 + random.nextDouble() * 25,
        });
        break;

      case TestType.hopAndReturn:
        // Hop and Return - 6 metrik
        final totalTime = 3.5 + random.nextDouble() * 1.5; // seconds
        
        metrics.addAll({
          'totalTime': totalTime,
          'outboundTime': totalTime * 0.45, // seconds
          'returnTime': totalTime * 0.55, // seconds (typically slower)
          'maxDistance': 200 + random.nextDouble() * 80, // cm
          'directionChangeTime': 0.8 + random.nextDouble() * 0.4, // seconds
          'accuracyScore': 80 + random.nextDouble() * 18, // % target accuracy
        });
        break;

      case TestType.continuousJump:
        // Continuous Jump - 9 metrik
        final avgHeight = baseValues['jumpHeight']! * 0.85;
        final frequency = 2.0 + random.nextDouble() * 0.8; // Hz
        
        metrics.addAll({
          'averageJumpHeight': avgHeight * (1 + progress),
          'jumpFrequency': frequency,
          'totalJumps': (15 * frequency).round().toDouble(),
          'averageContactTime': 280 + random.nextDouble() * 120, // ms
          'averageFlightTime': _calculateFlightTime(avgHeight),
          'heightDecline': 12 + random.nextDouble() * 15, // % fatigue
          'rhythmConsistency': 85 + random.nextDouble() * 12, // %
          'powerMaintenance': 80 + random.nextDouble() * 15, // %
          'finalJumpHeight': avgHeight * 0.8, // After fatigue
        });
        break;
        
      default:
        // Default metrics for any other test types
        metrics.addAll({
          'value': 100 + random.nextDouble() * 50,
          'score': 70 + random.nextDouble() * 25,
          'qualityIndex': 75 + random.nextDouble() * 20,
        });
    }
    
    // Tüm testlere quality score ekle
    final qualityScore = _calculateTestQuality(metrics, testType);
    metrics['qualityScore'] = qualityScore;
    
    return metrics;
  }
  
  /// Sporcu test profili belirle
  static Map<String, dynamic> _getAthleteTestProfile(Athlete athlete) {
    final sport = athlete.sport?.toLowerCase() ?? '';
    final level = athlete.level ?? AthleteLevel.recreational;
    final age = athlete.age ?? 25;
    
    // Spor dalına göre test öncelikleri
    List<TestType> primaryTests = [];
    List<TestType> secondaryTests = [];
    List<TestType> specializedTests = [];
    
    if (sport.contains('basketbol') || sport.contains('voleybol')) {
      primaryTests = [
        TestType.counterMovementJump,
        TestType.squatJump,
        TestType.dropJump,
        TestType.abalakov,
        TestType.singleLegCmj,
      ];
      secondaryTests = [
        TestType.isometricMidThighPull,
        TestType.isometricSquat,
        TestType.staticBalance,
        TestType.cmjRebound,
        TestType.landAndHold,
      ];
      specializedTests = [
        TestType.cmjLoaded,
        TestType.singleLegDj,
        TestType.hopTest,
        TestType.squatAssessment,
      ];
    } else if (sport.contains('futbol')) {
      primaryTests = [
        TestType.counterMovementJump,
        TestType.squatJump,
        TestType.lateralHop,
        TestType.anteriorPosteriorHop,
        TestType.hopTest,
      ];
      secondaryTests = [
        TestType.singleLegCmj,
        TestType.staticBalance,
        TestType.singleLegBalance,
        TestType.squatAssessment,
        TestType.isometricMidThighPull,
      ];
      specializedTests = [
        TestType.dropJump,
        TestType.singleLegSquat,
        TestType.medialLateralHop,
        TestType.dynamicBalance,
      ];
    } else if (sport.contains('atletizm') || sport.contains('sprint')) {
      primaryTests = [
        TestType.counterMovementJump,
        TestType.squatJump,
        TestType.dropJump,
        TestType.isometricMidThighPull,
        TestType.lateralHop,
      ];
      secondaryTests = [
        TestType.singleLegCmj,
        TestType.anteriorPosteriorHop,
        TestType.hopTest,
        TestType.cmjRebound,
        TestType.staticBalance,
      ];
      specializedTests = [
        TestType.abalakov,
        TestType.singleLegDj,
        TestType.medialLateralHop,
        TestType.isometricSquat,
      ];
    } else if (sport.contains('rehabilitasyon') || age > 50) {
      primaryTests = [
        TestType.staticBalance,
        TestType.singleLegBalance,
        TestType.squatAssessment,
        TestType.sitToStand,
        TestType.singleLegSquat,
      ];
      secondaryTests = [
        TestType.counterMovementJump,
        TestType.squatJump,
        TestType.isometricSquat,
        TestType.dynamicBalance,
        TestType.singleLegRangeOfStability,
      ];
      specializedTests = [
        TestType.singleLegCmj,
        TestType.hopTest,
        TestType.landAndHold,
      ];
    } else {
      // Genel sporcu profili
      primaryTests = [
        TestType.counterMovementJump,
        TestType.squatJump,
        TestType.staticBalance,
        TestType.isometricMidThighPull,
        TestType.squatAssessment,
      ];
      secondaryTests = [
        TestType.dropJump,
        TestType.singleLegCmj,
        TestType.singleLegBalance,
        TestType.hopTest,
        TestType.isometricSquat,
      ];
      specializedTests = [
        TestType.abalakov,
        TestType.lateralHop,
        TestType.singleLegSquat,
        TestType.pushUp,
      ];
    }

    return {
      'primaryTests': primaryTests,
      'secondaryTests': secondaryTests,
      'specializedTests': specializedTests,
      'testFrequency': level.index + 1, // 1-5 (recreational to elite)
      'sport': sport,
      'level': level,
      'age': age,
    };
  }

  /// Haftalık test seçimi
  static List<TestType> _selectWeeklyTests(
    Map<String, dynamic> profile,
    int week,
    int testCount,
    String athleteId,
  ) {
    final primaryTests = List<TestType>.from(profile['primaryTests']);
    final secondaryTests = List<TestType>.from(profile['secondaryTests']);
    final specializedTests = List<TestType>.from(profile['specializedTests']);
    final random = math.Random(athleteId.hashCode + week);
    
    final selectedTests = <TestType>[];
    
    // %60 primary, %30 secondary, %10 specialized
    final primaryCount = (testCount * 0.6).round().clamp(1, primaryTests.length);
    final secondaryCount = ((testCount - primaryCount) * 0.75).round();
    final specializedCount = testCount - primaryCount - secondaryCount;
    
    // Primary tests seç
    final shuffledPrimary = List<TestType>.from(primaryTests)..shuffle(random);
    selectedTests.addAll(shuffledPrimary.take(primaryCount));
    
    // Secondary tests seç
    if (secondaryCount > 0) {
      final shuffledSecondary = List<TestType>.from(secondaryTests)..shuffle(random);
      selectedTests.addAll(shuffledSecondary.take(secondaryCount));
    }
    
    // Specialized tests seç
    if (specializedCount > 0) {
      final shuffledSpecialized = List<TestType>.from(specializedTests)..shuffle(random);
      selectedTests.addAll(shuffledSpecialized.take(specializedCount));
    }
    
    return selectedTests;
  }

  /// Odaklanmış test seçimi (son 6 ay)
  static List<TestType> _selectFocusedTests(
    Map<String, dynamic> profile,
    int week,
    String athleteId,
  ) {
    final primaryTests = List<TestType>.from(profile['primaryTests']);
    final random = math.Random(athleteId.hashCode + week);
    
    // Son 6 ayda daha az ama odaklanmış testler
    final testCount = 2 + (week % 3); // 2-4 test
    
    // Primary testlerden seç
    final shuffledPrimary = List<TestType>.from(primaryTests)..shuffle(random);
    return shuffledPrimary.take(testCount).toList();
  }

  /// Test kalite skoru hesapla
  static double _calculateTestQuality(Map<String, double> metrics, TestType testType) {
    double quality = 75.0; // Base quality
    
    // Test tipine göre kalite değerlendirmesi
    switch (testType) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
        if (metrics['asymmetryIndex'] != null && metrics['asymmetryIndex']! < 10) quality += 10;
        if (metrics['forceCoefficientOfVariation'] != null && metrics['forceCoefficientOfVariation']! < 0.1) quality += 5;
        if (metrics['jumpHeight'] != null && metrics['jumpHeight']! > 30) quality += 5;
        break;
        
      case TestType.isometricMidThighPull:
      case TestType.isometricSquat:
        if (metrics['asymmetryIndex'] != null && metrics['asymmetryIndex']! < 8) quality += 10;
        if (metrics['peakForce'] != null && metrics['peakForce']! > 2000) quality += 5;
        break;
        
      case TestType.staticBalance:
      case TestType.singleLegBalance:
        if (metrics['stabilityIndex'] != null && metrics['stabilityIndex']! > 80) quality += 15;
        if (metrics['copVelocity'] != null && metrics['copVelocity']! < 10) quality += 10;
        break;
        
      default:
        // Generic quality based on available metrics
        if (metrics.length > 5) quality += 5;
        if (metrics.containsKey('asymmetryIndex') && metrics['asymmetryIndex']! < 15) quality += 5;
    }
    
    return quality.clamp(0.0, 100.0);
  }
  
  /// Flight time hesapla (jump height'tan)
  static double _calculateFlightTime(double jumpHeight) {
    // t = 2 * sqrt(2h/g) * 1000 (milliseconds)
    return 2 * math.sqrt(2 * jumpHeight / 100 / 9.81) * 1000;
  }
  
  /// Test süresini hesapla
  static Duration _getTestDuration(TestType testType, math.Random random) {
    switch (testType) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
        return Duration(milliseconds: 4000 + random.nextInt(2000)); // 4-6s
      case TestType.isometricMidThighPull:
        return Duration(milliseconds: 5000 + random.nextInt(3000)); // 5-8s
      case TestType.staticBalance:
        return Duration(milliseconds: 30000 + random.nextInt(10000)); // 30-40s
      default:
        return Duration(milliseconds: 5000 + random.nextInt(5000)); // 5-10s
    }
  }
}