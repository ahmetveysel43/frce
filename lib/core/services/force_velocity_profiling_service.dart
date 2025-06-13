import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../algorithms/statistics_helper.dart';
import '../../data/models/athlete_model.dart';
import '../../data/models/test_result_model.dart';

/// Force-Velocity Profiling Service
/// Samozino et al. (2016) metodolojisi ile güç-hız profilleme
/// "A simple method for measuring power, force, velocity properties, and mechanical effectiveness in sprint running"
class ForceVelocityProfilingService {
  static final _stats = StatisticsHelper();
  
  /// Sprint force-velocity profil analizi
  static FVProfilingResult analyzeSprintFVProfile({
    required AthleteModel athlete,
    required List<TestResultModel> sprintResults,
    double? bodyMass,
    int minDataPoints = 3,
  }) {
    debugPrint('🏃‍♂️ Sprint F-V Profil analizi başlatıldı: ${athlete.fullName}');
    
    if (sprintResults.length < minDataPoints) {
      return FVProfilingResult.error(
        'F-V profil analizi için minimum $minDataPoints sprint testi gerekli (mevcut: ${sprintResults.length})'
      );
    }

    // Sprint verilerini filtrele ve sırala
    final validSprints = sprintResults
        .where((test) => test.testType.toLowerCase().contains('sprint'))
        .where((test) => test.score != null && test.score! > 0)
        .toList();
    
    if (validSprints.length < minDataPoints) {
      return FVProfilingResult.error('Geçerli sprint verisi yetersiz');
    }

    // Varsayılan vücut ağırlığı (75kg) kullan eğer belirtilmemişse
    final mass = bodyMass ?? 75.0;
    
    // Sprint split verilerini çıkar
    final sprintData = _extractSprintSplitData(validSprints);
    
    if (sprintData.isEmpty) {
      return FVProfilingResult.error('Sprint split verileri bulunamadı');
    }

    // En iyi sprint performansını seç
    final bestSprint = _selectBestSprintRun(sprintData);
    
    // F-V profil hesaplama
    final fvProfile = _calculateForceVelocityProfile(bestSprint, mass);
    
    // Mekanik etkililik hesaplama
    final mechanicalEffectiveness = _calculateMechanicalEffectiveness(fvProfile);
    
    // Sprint kinematiği analizi
    final sprintKinematics = _analyzeSprintKinematics(bestSprint);
    
    // Profil karşılaştırması
    final profileComparison = _compareWithNormativeData(fvProfile, athlete);
    
    // İyileştirme önerileri
    final recommendations = _generateFVRecommendations(fvProfile, mechanicalEffectiveness, athlete);

    return FVProfilingResult(
      athleteId: athlete.id,
      athleteName: athlete.fullName,
      bodyMass: mass,
      forceVelocityProfile: fvProfile,
      mechanicalEffectiveness: mechanicalEffectiveness,
      sprintKinematics: sprintKinematics,
      profileComparison: profileComparison,
      recommendations: recommendations,
      analysisDate: DateTime.now(),
    );
  }

  /// Jump force-velocity profil analizi
  static FVProfilingResult analyzeJumpFVProfile({
    required AthleteModel athlete,
    required List<TestResultModel> jumpResults,
    double? bodyMass,
    int minDataPoints = 4,
  }) {
    debugPrint('🦘 Jump F-V Profil analizi başlatıldı: ${athlete.fullName}');
    
    if (jumpResults.length < minDataPoints) {
      return FVProfilingResult.error(
        'Jump F-V profil analizi için minimum $minDataPoints farklı yük testi gerekli'
      );
    }

    // Farklı yüklerle yapılan sıçrama testlerini grupla
    final loadedJumps = _groupJumpsByLoad(jumpResults);
    
    if (loadedJumps.length < 3) {
      return FVProfilingResult.error('En az 3 farklı yük kondisyonu gerekli');
    }

    final mass = bodyMass ?? 75.0;
    
    // Her yük kondisyonu için güç hesaplama
    final powerValues = <double, double>{}; // yük -> güç
    final velocityValues = <double, double>{}; // yük -> hız
    final forceValues = <double, double>{}; // yük -> kuvvet
    
    for (final entry in loadedJumps.entries) {
      final load = entry.key;
      final jumps = entry.value;
      
      final avgJumpHeight = _stats.calculateMean(
        jumps.map((j) => j.score!).toList()
      );
      
      // Samozino et al. formülleri
      final velocity = _calculateJumpVelocity(avgJumpHeight);
      final force = _calculateJumpForce(mass, load, avgJumpHeight);
      final power = force * velocity;
      
      powerValues[load] = power;
      velocityValues[load] = velocity;
      forceValues[load] = force;
    }

    // F-V profil regresyonu
    final fvProfile = _calculateJumpFVProfile(forceValues, velocityValues, mass);
    
    // Optimal yük belirleme
    final optimalLoad = _calculateOptimalLoad(fvProfile);
    
    // Güç-yük profili
    final powerLoadProfile = _calculatePowerLoadProfile(powerValues);
    
    // Profil karşılaştırması
    final profileComparison = _compareJumpProfileWithNorms(fvProfile, athlete);
    
    // İyileştirme önerileri
    final recommendations = _generateJumpFVRecommendations(fvProfile, optimalLoad, athlete);

    return FVProfilingResult(
      athleteId: athlete.id,
      athleteName: athlete.fullName,
      bodyMass: mass,
      forceVelocityProfile: fvProfile,
      jumpPowerProfile: powerLoadProfile,
      optimalLoad: optimalLoad,
      profileComparison: profileComparison,
      recommendations: recommendations,
      analysisDate: DateTime.now(),
    );
  }

  /// Multi-modal F-V profil analizi (sprint + jump kombinasyonu)
  static ComprehensiveFVResult analyzeComprehensiveFVProfile({
    required AthleteModel athlete,
    required List<TestResultModel> sprintResults,
    required List<TestResultModel> jumpResults,
    double? bodyMass,
  }) {
    debugPrint('🔄 Kapsamlı F-V Profil analizi başlatıldı: ${athlete.fullName}');
    
    final sprintProfile = analyzeSprintFVProfile(
      athlete: athlete,
      sprintResults: sprintResults,
      bodyMass: bodyMass,
    );
    
    final jumpProfile = analyzeJumpFVProfile(
      athlete: athlete,
      jumpResults: jumpResults,
      bodyMass: bodyMass,
    );

    // Cross-modal analiz
    final crossModalAnalysis = _performCrossModalAnalysis(sprintProfile, jumpProfile);
    
    // Entegre öneriler
    final integratedRecommendations = _generateIntegratedRecommendations(
      sprintProfile, 
      jumpProfile, 
      crossModalAnalysis,
    );

    return ComprehensiveFVResult(
      athleteId: athlete.id,
      athleteName: athlete.fullName,
      sprintProfile: sprintProfile.hasError ? null : sprintProfile,
      jumpProfile: jumpProfile.hasError ? null : jumpProfile,
      crossModalAnalysis: crossModalAnalysis,
      integratedRecommendations: integratedRecommendations,
      analysisDate: DateTime.now(),
    );
  }

  // Private helper methods

  /// Sprint split verilerini çıkar
  static List<SprintSplitData> _extractSprintSplitData(List<TestResultModel> sprints) {
    final sprintData = <SprintSplitData>[];
    
    for (final sprint in sprints) {
      final splits = <double, double>{}; // mesafe -> süre
      
      // Sprint kapı verilerini çıkar
      for (int gate = 1; gate <= 7; gate++) {
        final gateTime = sprint.metrics['kapi$gate'];
        if (gateTime != null && gateTime > 0) {
          final distance = gate * 10.0; // 10m aralıklarla
          splits[distance] = gateTime;
        }
      }
      
      if (splits.length >= 3) {
        sprintData.add(SprintSplitData(
          testId: sprint.id,
          testDate: sprint.testDate,
          splits: splits,
        ));
      }
    }
    
    return sprintData;
  }

  /// En iyi sprint koşusunu seç
  static SprintSplitData _selectBestSprintRun(List<SprintSplitData> sprintData) {
    // En hızlı 40m süresine sahip koşuyu seç
    return sprintData.reduce((best, current) {
      final bestTime = best.splits[40.0] ?? double.infinity;
      final currentTime = current.splits[40.0] ?? double.infinity;
      return currentTime < bestTime ? current : best;
    });
  }

  /// Sprint için F-V profil hesaplama (Samozino et al., 2016)
  static ForceVelocityProfile _calculateForceVelocityProfile(SprintSplitData sprintData, double mass) {
    // Hız-zaman verilerini hesapla
    final velocityData = <double, double>{}; // zaman -> hız
    final accelerationData = <double, double>{}; // zaman -> ivme
    
    final times = sprintData.splits.values.toList()..sort();
    final distances = sprintData.splits.keys.toList()..sort();
    
    // Hız hesaplama (ardışık kapılar arası)
    for (int i = 1; i < distances.length; i++) {
      final deltaDistance = distances[i] - distances[i-1];
      final deltaTime = times[i] - times[i-1];
      final avgTime = (times[i] + times[i-1]) / 2;
      final velocity = deltaDistance / deltaTime;
      
      velocityData[avgTime] = velocity;
    }

    // İvme hesaplama
    final velocityTimes = velocityData.keys.toList()..sort();
    for (int i = 1; i < velocityTimes.length; i++) {
      final deltaVelocity = velocityData[velocityTimes[i]]! - velocityData[velocityTimes[i-1]]!;
      final deltaTime = velocityTimes[i] - velocityTimes[i-1];
      final avgTime = (velocityTimes[i] + velocityTimes[i-1]) / 2;
      final acceleration = deltaVelocity / deltaTime;
      
      accelerationData[avgTime] = acceleration;
    }

    // F-V profil parametreleri (Samozino metodolojisi)
    final maxVelocity = _estimateMaxVelocity(velocityData);
    final maxForce = _estimateMaxForce(accelerationData, mass);
    final maxPower = (maxForce * maxVelocity) / 4; // Optimal güç
    
    // Güç-hız eğrisi denklemi: P = F0 * v * (1 - v/v0)
    final fvSlope = -maxForce / maxVelocity;
    
    // Profil dengesi
    final rfvIndex = _calculateRFVIndex(maxForce, maxVelocity, mass);

    return ForceVelocityProfile(
      maxForce: maxForce,
      maxVelocity: maxVelocity,
      maxPower: maxPower,
      fvSlope: fvSlope,
      rfvIndex: rfvIndex,
      velocityData: velocityData,
      accelerationData: accelerationData,
    );
  }

  /// Maksimum hız tahmini
  static double _estimateMaxVelocity(Map<double, double> velocityData) {
    final velocities = velocityData.values.toList();
    
    // Exponential plateau modeli fit et
    // v(t) = vmax * (1 - exp(-t/tau))
    final maxObservedVelocity = velocities.reduce(math.max);
    
    // Basit tahmin: gözlenen maksimum hızın %110'u
    return maxObservedVelocity * 1.1;
  }

  /// Maksimum kuvvet tahmini  
  static double _estimateMaxForce(Map<double, double> accelerationData, double mass) {
    if (accelerationData.isEmpty) return 0.0;
    
    // En yüksek ivme değerini kullan (başlangıç ivmesi)
    final maxAcceleration = accelerationData.values.reduce(math.max);
    
    // F = ma + mg (yer çekimi dahil)
    return mass * (maxAcceleration + 9.81);
  }

  /// RFV Index hesaplama (Jiménez-Reyes et al., 2017)
  static double _calculateRFVIndex(double maxForce, double maxVelocity, double mass) {
    // Optimal teorik profil
    final theoreticalSlope = -(mass * 9.81) / maxVelocity;
    final actualSlope = -maxForce / maxVelocity;
    
    // RFV = 100 * (1 - |Sfv - Sfvopt| / Sfvopt)
    return 100 * (1 - (actualSlope - theoreticalSlope).abs() / theoreticalSlope.abs());
  }

  /// Mekanik etkililik hesaplama
  static MechanicalEffectiveness _calculateMechanicalEffectiveness(ForceVelocityProfile profile) {
    // DRF (Ratio of Force) - horizontal/total force ratio
    final drf = _calculateDRF(profile);
    
    // Güç çıkış etkinliği
    final powerEfficiency = profile.maxPower / (profile.maxForce * profile.maxVelocity / 4);
    
    // Optimal hız oranı
    final optimalVelocityRatio = 0.5; // Teorik optimal
    final actualOptimalRatio = profile.maxPower / (profile.maxForce * profile.maxVelocity);
    
    return MechanicalEffectiveness(
      drf: drf,
      powerEfficiency: powerEfficiency,
      velocityOptimality: 1.0 - (actualOptimalRatio - optimalVelocityRatio).abs(),
      overallEffectiveness: (drf + powerEfficiency) / 2,
    );
  }

  /// DRF hesaplama (horizontal force effectiveness)
  static double _calculateDRF(ForceVelocityProfile profile) {
    // Basitleştirilmiş DRF tahmini
    // Gerçek implementasyonda 3D force platform verileri gerekir
    final rfvNormalized = profile.rfvIndex / 100;
    return 0.6 + (rfvNormalized * 0.3); // 0.6-0.9 arası
  }

  /// Sprint kinematiği analizi
  static SprintKinematics _analyzeSprintKinematics(SprintSplitData sprintData) {
    final splits = sprintData.splits;
    
    // Faz analizleri
    final accelerationPhase = _analyzeAccelerationPhase(splits);
    final maxVelocityPhase = _analyzeMaxVelocityPhase(splits);
    final velocityMaintenance = _analyzeVelocityMaintenance(splits);
    
    return SprintKinematics(
      accelerationPhase: accelerationPhase,
      maxVelocityPhase: maxVelocityPhase,
      velocityMaintenance: velocityMaintenance,
      totalTime40m: splits[40.0] ?? 0.0,
    );
  }

  /// İvme fazı analizi (0-20m)
  static AccelerationPhase _analyzeAccelerationPhase(Map<double, double> splits) {
    final time10m = splits[10.0] ?? 0.0;
    final time20m = splits[20.0] ?? 0.0;
    
    final avgAcceleration = time20m > 0 ? 20.0 / math.pow(time20m, 2) : 0.0;
    final accelerationConsistency = time10m > 0 && time20m > 0 
        ? 1.0 - ((time20m - 2 * time10m).abs() / time20m)
        : 0.0;
    
    return AccelerationPhase(
      time10m: time10m,
      time20m: time20m,
      avgAcceleration: avgAcceleration,
      consistency: accelerationConsistency,
    );
  }

  /// Maksimum hız fazı analizi (20-30m)
  static MaxVelocityPhase _analyzeMaxVelocityPhase(Map<double, double> splits) {
    final time20m = splits[20.0] ?? 0.0;
    final time30m = splits[30.0] ?? 0.0;
    
    final maxVelocity = time20m > 0 && time30m > 0 
        ? 10.0 / (time30m - time20m)
        : 0.0;
    
    return MaxVelocityPhase(
      splitTime20_30m: time30m - time20m,
      maxVelocity: maxVelocity,
      velocityIndex: maxVelocity > 0 ? maxVelocity / 12.0 : 0.0, // 12 m/s referans
    );
  }

  /// Hız koruma fazı analizi (30-40m)
  static VelocityMaintenance _analyzeVelocityMaintenance(Map<double, double> splits) {
    final time20m = splits[20.0] ?? 0.0;
    final time30m = splits[30.0] ?? 0.0;
    final time40m = splits[40.0] ?? 0.0;
    
    if (time20m <= 0 || time30m <= 0 || time40m <= 0) {
      return VelocityMaintenance(
        splitTime30_40m: 0.0,
        velocityDecrement: 0.0,
        maintenanceIndex: 0.0,
      );
    }
    
    final velocity20_30 = 10.0 / (time30m - time20m);
    final velocity30_40 = 10.0 / (time40m - time30m);
    final velocityDecrement = (velocity20_30 - velocity30_40) / velocity20_30;
    
    return VelocityMaintenance(
      splitTime30_40m: time40m - time30m,
      velocityDecrement: velocityDecrement,
      maintenanceIndex: 1.0 - velocityDecrement,
    );
  }

  /// Normatif verilerle karşılaştırma
  static ProfileComparison _compareWithNormativeData(ForceVelocityProfile profile, AthleteModel athlete) {
    // Elit sporcu normları (literatür tabanlı)
    final eliteNorms = _getEliteNorms(athlete.ageGroup ?? 'senior', athlete.gender ?? 'erkek');
    
    final forcePercentile = _calculatePercentile(profile.maxForce, eliteNorms.forceDistribution);
    final velocityPercentile = _calculatePercentile(profile.maxVelocity, eliteNorms.velocityDistribution);
    final powerPercentile = _calculatePercentile(profile.maxPower, eliteNorms.powerDistribution);
    
    return ProfileComparison(
      forcePercentile: forcePercentile,
      velocityPercentile: velocityPercentile,
      powerPercentile: powerPercentile,
      overallRanking: (forcePercentile + velocityPercentile + powerPercentile) / 3,
      strengthLevel: _categorizeStrengthLevel(forcePercentile),
      speedLevel: _categorizeSpeedLevel(velocityPercentile),
      powerLevel: _categorizePowerLevel(powerPercentile),
    );
  }

  /// F-V profil önerilerini oluştur
  static List<FVRecommendation> _generateFVRecommendations(
    ForceVelocityProfile profile,
    MechanicalEffectiveness effectiveness,
    AthleteModel athlete,
  ) {
    final recommendations = <FVRecommendation>[];
    
    // Kuvvet eksikliği analizi
    if (profile.maxForce < _getForceThreshold(athlete)) {
      recommendations.add(FVRecommendation(
        category: RecommendationCategory.force,
        priority: RecommendationPriority.high,
        title: 'Maksimum Kuvvet Geliştirme',
        description: 'Düşük F0 değeri tespit edildi (${profile.maxForce.toStringAsFixed(0)}N)',
        specificActions: [
          'Ağır squat çalışmaları (%85-95 1RM)',
          'İzometrik kuvvet antrenmanları',
          'Plyometric kontrastı antrenmanlar',
        ],
        expectedImprovement: 'F0 değerinde %8-15 artış',
        timeframe: '8-12 hafta',
      ));
    }
    
    // Hız eksikliği analizi
    if (profile.maxVelocity < _getVelocityThreshold(athlete)) {
      recommendations.add(FVRecommendation(
        category: RecommendationCategory.velocity,
        priority: RecommendationPriority.high,
        title: 'Maksimum Hız Geliştirme',
        description: 'Düşük V0 değeri tespit edildi (${profile.maxVelocity.toStringAsFixed(1)} m/s)',
        specificActions: [
          'Maksimum hız sprint antrenmanları (95-100%)',
          'Overspeed antrenmanları',
          'Teknik odaklı sprint drilleri',
        ],
        expectedImprovement: 'V0 değerinde %3-8 artış',
        timeframe: '6-10 hafta',
      ));
    }
    
    // Profil dengesizliği
    if (profile.rfvIndex < 90) {
      recommendations.add(FVRecommendation(
        category: RecommendationCategory.balance,
        priority: RecommendationPriority.medium,
        title: 'F-V Profil Optimizasyonu',
        description: 'Profil dengesizliği (RFV: ${profile.rfvIndex.toStringAsFixed(1)}%)',
        specificActions: [
          'Dengeli F-V antrenman dağılımı',
          'Zayıf kalite odaklı çalışma',
          'Profil-spesifik egzersizler',
        ],
        expectedImprovement: 'RFV indexinde %5-10 artış',
        timeframe: '4-8 hafta',
      ));
    }
    
    // Mekanik etkililik
    if (effectiveness.overallEffectiveness < 0.75) {
      recommendations.add(FVRecommendation(
        category: RecommendationCategory.efficiency,
        priority: RecommendationPriority.medium,
        title: 'Mekanik Etkililik Geliştirme',
        description: 'Düşük mekanik etkililik (%${(effectiveness.overallEffectiveness * 100).toStringAsFixed(0)})',
        specificActions: [
          'Sprint teknik çalışması',
          'Horizontal güç antrenmanı',
          'Koşu kinematiği optimizasyonu',
        ],
        expectedImprovement: 'Mekanik etkililik %5-12 artış',
        timeframe: '6-12 hafta',
      ));
    }
    
    return recommendations;
  }

  // Jump-specific helper methods

  /// Sıçramaları yüke göre grupla
  static Map<double, List<TestResultModel>> _groupJumpsByLoad(List<TestResultModel> jumps) {
    final grouped = <double, List<TestResultModel>>{};
    
    for (final jump in jumps) {
      final load = jump.metrics['additional_load'] ?? 0.0;
      grouped.putIfAbsent(load, () => []).add(jump);
    }
    
    return grouped;
  }

  /// Sıçrama hızı hesaplama
  static double _calculateJumpVelocity(double jumpHeight) {
    // v = sqrt(2 * g * h)
    return math.sqrt(2 * 9.81 * jumpHeight / 100); // cm -> m dönüşümü
  }

  /// Sıçrama kuvveti hesaplama
  static double _calculateJumpForce(double bodyMass, double additionalLoad, double jumpHeight) {
    final totalMass = bodyMass + additionalLoad;
    final velocity = _calculateJumpVelocity(jumpHeight);
    
    // F = m * (g + v²/2h)
    return totalMass * (9.81 + (velocity * velocity) / (2 * jumpHeight / 100));
  }

  /// Jump F-V profil hesaplama
  static ForceVelocityProfile _calculateJumpFVProfile(
    Map<double, double> forceValues,
    Map<double, double> velocityValues,
    double mass,
  ) {
    // Linear regression F-V ilişkisi
    final forces = forceValues.values.toList();
    final velocities = velocityValues.values.toList();
    
    final regression = _stats.performLinearRegression(forces, velocities);
    final fvSlope = regression.slope;
    final intercept = regression.intercept;
    
    // F0 (y-intercept) ve V0 (x-intercept) 
    final maxForce = -intercept / fvSlope;
    final maxVelocity = intercept;
    final maxPower = (maxForce * maxVelocity) / 4;
    
    // RFV index hesaplama
    final rfvIndex = _calculateRFVIndex(maxForce, maxVelocity, mass);
    
    return ForceVelocityProfile(
      maxForce: maxForce,
      maxVelocity: maxVelocity,
      maxPower: maxPower,
      fvSlope: fvSlope,
      rfvIndex: rfvIndex,
    );
  }

  /// Optimal yük hesaplama
  static OptimalLoad _calculateOptimalLoad(ForceVelocityProfile profile) {
    // Optimal yük = maksimum güç çıkışında yük
    final optimalForce = profile.maxForce / 2; // Maksimum güçte F = F0/2
    final optimalVelocity = profile.maxVelocity / 2; // Maksimum güçte V = V0/2
    
    // Yük = (optimal force - body weight) / g
    final optimalLoadKg = (optimalForce - 75 * 9.81) / 9.81; // 75kg varsayılan vücut ağırlığı
    
    return OptimalLoad(
      loadKg: math.max(0, optimalLoadKg),
      optimalForce: optimalForce,
      optimalVelocity: optimalVelocity,
      expectedPower: optimalForce * optimalVelocity,
    );
  }

  /// Güç-yük profili hesaplama
  static PowerLoadProfile _calculatePowerLoadProfile(Map<double, double> powerValues) {
    final loads = powerValues.keys.toList()..sort();
    final powers = loads.map((load) => powerValues[load]!).toList();
    
    final maxPowerIndex = powers.indexOf(powers.reduce(math.max));
    final maxPower = powers[maxPowerIndex];
    final maxPowerLoad = loads[maxPowerIndex];
    
    return PowerLoadProfile(
      powerValues: powerValues,
      maxPower: maxPower,
      maxPowerLoad: maxPowerLoad,
      powerDeficit: _calculatePowerDeficit(powerValues),
    );
  }

  /// Güç açığı hesaplama
  static double _calculatePowerDeficit(Map<double, double> powerValues) {
    final bodyweightPower = powerValues[0.0] ?? 0.0;
    final maxPower = powerValues.values.reduce(math.max);
    
    return bodyweightPower > 0 ? (maxPower - bodyweightPower) / bodyweightPower : 0.0;
  }

  // Cross-modal analysis methods

  /// Modaliteler arası analiz
  static CrossModalAnalysis _performCrossModalAnalysis(
    FVProfilingResult sprintProfile,
    FVProfilingResult jumpProfile,
  ) {
    if (sprintProfile.hasError || jumpProfile.hasError) {
      return CrossModalAnalysis(
        correlation: 0.0,
        consistency: 0.0,
        transferability: 0.0,
        modalSpecificity: {},
        recommendations: ['Çapraz modal analiz için her iki test türünde de yeterli veri gerekli'],
      );
    }

    final sprintFV = sprintProfile.forceVelocityProfile!;
    final jumpFV = jumpProfile.forceVelocityProfile!;
    
    // F-V profil korelasyonu
    final forceCorr = _calculateCorrelation(sprintFV.maxForce, jumpFV.maxForce);
    final velocityCorr = _calculateCorrelation(sprintFV.maxVelocity, jumpFV.maxVelocity);
    final powerCorr = _calculateCorrelation(sprintFV.maxPower, jumpFV.maxPower);
    
    final avgCorrelation = (forceCorr + velocityCorr + powerCorr) / 3;
    
    // Profil tutarlılığı
    final forceConsistency = 1.0 - (sprintFV.maxForce - jumpFV.maxForce).abs() / math.max(sprintFV.maxForce, jumpFV.maxForce);
    final velocityConsistency = 1.0 - (sprintFV.maxVelocity - jumpFV.maxVelocity).abs() / math.max(sprintFV.maxVelocity, jumpFV.maxVelocity);
    
    final avgConsistency = (forceConsistency + velocityConsistency) / 2;
    
    // Transfer edilebilirlik
    final transferability = _calculateTransferability(sprintFV, jumpFV);
    
    return CrossModalAnalysis(
      correlation: avgCorrelation,
      consistency: avgConsistency,
      transferability: transferability,
      modalSpecificity: {
        'sprint_force_dominance': sprintFV.maxForce > jumpFV.maxForce,
        'jump_power_dominance': jumpFV.maxPower > sprintFV.maxPower,
      },
      recommendations: _generateCrossModalRecommendations(avgCorrelation, avgConsistency, transferability),
    );
  }

  /// Basit korelasyon hesaplama
  static double _calculateCorrelation(double value1, double value2) {
    // Basitleştirilmiş korelasyon - gerçek implementasyonda daha fazla veri noktası gerekir
    final ratio = math.min(value1, value2) / math.max(value1, value2);
    return ratio; // 0-1 arası değer
  }

  /// Transfer edilebilirlik hesaplama
  static double _calculateTransferability(ForceVelocityProfile sprint, ForceVelocityProfile jump) {
    // RFV index benzerliği
    final rfvSimilarity = 1.0 - (sprint.rfvIndex - jump.rfvIndex).abs() / 100;
    
    // Güç profil benzerliği
    final powerRatio = math.min(sprint.maxPower, jump.maxPower) / math.max(sprint.maxPower, jump.maxPower);
    
    return (rfvSimilarity + powerRatio) / 2;
  }

  /// Çapraz modal öneriler
  static List<String> _generateCrossModalRecommendations(double correlation, double consistency, double transferability) {
    final recommendations = <String>[];
    
    if (correlation < 0.6) {
      recommendations.add('Modal spesifik antrenman gerekli - düşük korelasyon tespit edildi');
    }
    
    if (consistency < 0.7) {
      recommendations.add('F-V profil tutarlılığını artırmak için kombine antrenman protokolleri');
    }
    
    if (transferability > 0.8) {
      recommendations.add('Yüksek transfer kapasitesi - çapraz antrenman etkili olacaktır');
    } else if (transferability < 0.6) {
      recommendations.add('Düşük transfer kapasitesi - modalite spesifik antrenman odağı');
    }
    
    return recommendations;
  }

  // Utility methods

  /// Elite normları getir
  static EliteNorms _getEliteNorms(String ageGroup, String gender) {
    // Literatür tabanlı normlar (basitleştirilmiş)
    if (gender.toLowerCase() == 'erkek') {
      return EliteNorms(
        forceDistribution: [800, 900, 1000, 1100, 1200], // N
        velocityDistribution: [8.5, 9.0, 9.5, 10.0, 10.5], // m/s
        powerDistribution: [1800, 2000, 2250, 2500, 2750], // W
      );
    } else {
      return EliteNorms(
        forceDistribution: [600, 700, 800, 900, 1000], // N
        velocityDistribution: [7.5, 8.0, 8.5, 9.0, 9.5], // m/s
        powerDistribution: [1300, 1500, 1700, 1900, 2100], // W
      );
    }
  }

  /// Persentil hesaplama
  static double _calculatePercentile(double value, List<double> distribution) {
    distribution.sort();
    final index = distribution.indexWhere((d) => d >= value);
    if (index == -1) return 100.0;
    return (index / distribution.length) * 100;
  }

  /// Kategori belirleyiciler
  static String _categorizeStrengthLevel(double percentile) {
    if (percentile >= 90) return 'Elit';
    if (percentile >= 75) return 'Çok İyi';
    if (percentile >= 50) return 'İyi';
    if (percentile >= 25) return 'Orta';
    return 'Geliştirilmeli';
  }

  static String _categorizeSpeedLevel(double percentile) {
    if (percentile >= 90) return 'Çok Hızlı';
    if (percentile >= 75) return 'Hızlı';
    if (percentile >= 50) return 'Orta Hızlı';
    if (percentile >= 25) return 'Orta';
    return 'Yavaş';
  }

  static String _categorizePowerLevel(double percentile) {
    if (percentile >= 90) return 'Çok Güçlü';
    if (percentile >= 75) return 'Güçlü';
    if (percentile >= 50) return 'Orta Güçlü';
    if (percentile >= 25) return 'Orta';
    return 'Zayıf';
  }

  /// Eşik değerler
  static double _getForceThreshold(AthleteModel athlete) {
    // Yaş ve cinsiyete göre minimum force eşikleri
    final age = athlete.age ?? 25; // Default age
    final gender = athlete.gender?.toLowerCase() ?? 'erkek';
    
    if (gender == 'erkek') {
      return age < 20 ? 800.0 : 900.0;
    } else {
      return age < 20 ? 600.0 : 700.0;
    }
  }

  static double _getVelocityThreshold(AthleteModel athlete) {
    // Yaş ve cinsiyete göre minimum velocity eşikleri
    final age = athlete.age ?? 25; // Default age
    final gender = athlete.gender?.toLowerCase() ?? 'erkek';
    
    if (gender == 'erkek') {
      return age < 20 ? 8.5 : 9.0;
    } else {
      return age < 20 ? 7.5 : 8.0;
    }
  }

  // İntegre öneriler
  static List<IntegratedRecommendation> _generateIntegratedRecommendations(
    FVProfilingResult sprintProfile,
    FVProfilingResult jumpProfile,
    CrossModalAnalysis crossModal,
  ) {
    final recommendations = <IntegratedRecommendation>[];
    
    // Genel antrenman stratejisi
    if (crossModal.transferability > 0.7) {
      recommendations.add(IntegratedRecommendation(
        category: 'Genel Strateji',
        priority: 'Yüksek',
        title: 'Kombine F-V Antrenman Yaklaşımı',
        description: 'Yüksek transfer kapasitesi nedeniyle kombine antrenman etkili olacaktır',
        actions: [
          'Sprint ve jump antrenmanlarını aynı seansda kombine edin',
          'F-V profil hedefli periodizasyon uygulayın',
          'Çapraz modal test protokolleri kullanın',
        ],
      ));
    }
    
    return recommendations;
  }

  // Jump specific recommendation methods
  static List<FVRecommendation> _generateJumpFVRecommendations(
    ForceVelocityProfile profile,
    OptimalLoad optimalLoad,
    AthleteModel athlete,
  ) {
    final recommendations = <FVRecommendation>[];
    
    // Optimal yük antrenmanı
    recommendations.add(FVRecommendation(
      category: RecommendationCategory.optimalLoad,
      priority: RecommendationPriority.high,
      title: 'Optimal Yük Antrenmanı',
      description: 'Maksimum güç için ${optimalLoad.loadKg.toStringAsFixed(1)}kg ek yük kullanın',
      specificActions: [
        'Weighted jump squats ${optimalLoad.loadKg.toStringAsFixed(1)}kg ile',
        'Jump squats with optimal load 3x5 tekrar',
        'Haftalık 2-3 optimal yük seansı',
      ],
      expectedImprovement: 'Maksimum güçte %5-12 artış',
      timeframe: '6-8 hafta',
    ));
    
    return recommendations;
  }

  static ProfileComparison _compareJumpProfileWithNorms(ForceVelocityProfile profile, AthleteModel athlete) {
    // Jump-specific normative comparison
    return _compareWithNormativeData(profile, athlete);
  }
}

// Data Models

class FVProfilingResult {
  final String athleteId;
  final String athleteName;
  final double bodyMass;
  final ForceVelocityProfile? forceVelocityProfile;
  final MechanicalEffectiveness? mechanicalEffectiveness;
  final SprintKinematics? sprintKinematics;
  final PowerLoadProfile? jumpPowerProfile;
  final OptimalLoad? optimalLoad;
  final ProfileComparison? profileComparison;
  final List<FVRecommendation> recommendations;
  final DateTime analysisDate;
  final String? error;

  FVProfilingResult({
    required this.athleteId,
    required this.athleteName,
    required this.bodyMass,
    this.forceVelocityProfile,
    this.mechanicalEffectiveness,
    this.sprintKinematics,
    this.jumpPowerProfile,
    this.optimalLoad,
    this.profileComparison,
    required this.recommendations,
    required this.analysisDate,
    this.error,
  });

  factory FVProfilingResult.error(String message) {
    return FVProfilingResult(
      athleteId: '',
      athleteName: '',
      bodyMass: 0,
      recommendations: [],
      analysisDate: DateTime.now(),
      error: message,
    );
  }

  bool get hasError => error != null;
}

class ForceVelocityProfile {
  final double maxForce; // F0 (N)
  final double maxVelocity; // V0 (m/s)
  final double maxPower; // Pmax (W)
  final double fvSlope; // F-V slope
  final double rfvIndex; // RFV index (%)
  final Map<double, double>? velocityData;
  final Map<double, double>? accelerationData;

  ForceVelocityProfile({
    required this.maxForce,
    required this.maxVelocity,
    required this.maxPower,
    required this.fvSlope,
    required this.rfvIndex,
    this.velocityData,
    this.accelerationData,
  });
}

class MechanicalEffectiveness {
  final double drf; // Ratio of horizontal force
  final double powerEfficiency;
  final double velocityOptimality;
  final double overallEffectiveness;

  MechanicalEffectiveness({
    required this.drf,
    required this.powerEfficiency,
    required this.velocityOptimality,
    required this.overallEffectiveness,
  });
}

class SprintKinematics {
  final AccelerationPhase accelerationPhase;
  final MaxVelocityPhase maxVelocityPhase;
  final VelocityMaintenance velocityMaintenance;
  final double totalTime40m;

  SprintKinematics({
    required this.accelerationPhase,
    required this.maxVelocityPhase,
    required this.velocityMaintenance,
    required this.totalTime40m,
  });
}

class AccelerationPhase {
  final double time10m;
  final double time20m;
  final double avgAcceleration;
  final double consistency;

  AccelerationPhase({
    required this.time10m,
    required this.time20m,
    required this.avgAcceleration,
    required this.consistency,
  });
}

class MaxVelocityPhase {
  final double splitTime20_30m;
  final double maxVelocity;
  final double velocityIndex;

  MaxVelocityPhase({
    required this.splitTime20_30m,
    required this.maxVelocity,
    required this.velocityIndex,
  });
}

class VelocityMaintenance {
  final double splitTime30_40m;
  final double velocityDecrement;
  final double maintenanceIndex;

  VelocityMaintenance({
    required this.splitTime30_40m,
    required this.velocityDecrement,
    required this.maintenanceIndex,
  });
}

class PowerLoadProfile {
  final Map<double, double> powerValues; // load -> power
  final double maxPower;
  final double maxPowerLoad;
  final double powerDeficit;

  PowerLoadProfile({
    required this.powerValues,
    required this.maxPower,
    required this.maxPowerLoad,
    required this.powerDeficit,
  });
}

class OptimalLoad {
  final double loadKg;
  final double optimalForce;
  final double optimalVelocity;
  final double expectedPower;

  OptimalLoad({
    required this.loadKg,
    required this.optimalForce,
    required this.optimalVelocity,
    required this.expectedPower,
  });
}

class ProfileComparison {
  final double forcePercentile;
  final double velocityPercentile;
  final double powerPercentile;
  final double overallRanking;
  final String strengthLevel;
  final String speedLevel;
  final String powerLevel;

  ProfileComparison({
    required this.forcePercentile,
    required this.velocityPercentile,
    required this.powerPercentile,
    required this.overallRanking,
    required this.strengthLevel,
    required this.speedLevel,
    required this.powerLevel,
  });
}

class FVRecommendation {
  final RecommendationCategory category;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final List<String> specificActions;
  final String expectedImprovement;
  final String timeframe;

  FVRecommendation({
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.specificActions,
    required this.expectedImprovement,
    required this.timeframe,
  });
}

class ComprehensiveFVResult {
  final String athleteId;
  final String athleteName;
  final FVProfilingResult? sprintProfile;
  final FVProfilingResult? jumpProfile;
  final CrossModalAnalysis crossModalAnalysis;
  final List<IntegratedRecommendation> integratedRecommendations;
  final DateTime analysisDate;

  ComprehensiveFVResult({
    required this.athleteId,
    required this.athleteName,
    this.sprintProfile,
    this.jumpProfile,
    required this.crossModalAnalysis,
    required this.integratedRecommendations,
    required this.analysisDate,
  });
}

class CrossModalAnalysis {
  final double correlation;
  final double consistency;
  final double transferability;
  final Map<String, dynamic> modalSpecificity;
  final List<String> recommendations;

  CrossModalAnalysis({
    required this.correlation,
    required this.consistency,
    required this.transferability,
    required this.modalSpecificity,
    required this.recommendations,
  });
}

class IntegratedRecommendation {
  final String category;
  final String priority;
  final String title;
  final String description;
  final List<String> actions;

  IntegratedRecommendation({
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.actions,
  });
}

class SprintSplitData {
  final String testId;
  final DateTime testDate;
  final Map<double, double> splits; // distance -> time

  SprintSplitData({
    required this.testId,
    required this.testDate,
    required this.splits,
  });
}

class EliteNorms {
  final List<double> forceDistribution;
  final List<double> velocityDistribution;
  final List<double> powerDistribution;

  EliteNorms({
    required this.forceDistribution,
    required this.velocityDistribution,
    required this.powerDistribution,
  });
}

enum RecommendationCategory {
  force,
  velocity,
  balance,
  efficiency,
  optimalLoad,
}

enum RecommendationPriority {
  high,
  medium,
  low,
}