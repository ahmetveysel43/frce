import 'dart:math' as math;

/// izForce test protokolleri ve sabitler
class TestConstants {
  TestConstants._();

  // ===== GENEL TEST PARAMETRELERİ =====
  
  /// Platform boyutları (mm)
  static const double platformWidth = 400.0;
  static const double platformLength = 600.0;
  static const double platformSeparation = 20.0; // Platformlar arası mesafe
  
  /// Örnekleme parametreleri
  static const int sampleRate = 1000; // Hz
  static const int minSampleCount = 1000; // Minimum örnek sayısı
  static const int maxSampleCount = 60000; // Maksimum örnek sayısı (60 saniye)
  
  /// Kalibrasyon parametreleri
  static const int calibrationDuration = 5; // saniye
  static const int calibrationSamples = calibrationDuration * sampleRate;
  static const double maxCalibrationDeviation = 10.0; // N
  
  /// Ağırlık ölçümü parametreleri
  static const int weightStabilityDuration = 3; // saniye
  static const double weightStabilityThreshold = 2.0; // kg
  static const int weightStabilitySamples = weightStabilityDuration * sampleRate;
  
  // ===== TEST TÜRLERİ VE SÜRELERİ =====
  
  /// Test süreleri (saniye)
  static const Map<String, TestDuration> testDurations = {
    // JUMP TESTS
    'CMJ': TestDuration(min: 3, max: 10, typical: 5),
    'CMJ_LOADED': TestDuration(min: 3, max: 10, typical: 5),
    'ABALAKOV': TestDuration(min: 3, max: 10, typical: 5),
    'SJ': TestDuration(min: 3, max: 8, typical: 5),
    'SJ_LOADED': TestDuration(min: 3, max: 8, typical: 5),
    'SINGLE_LEG_CMJ': TestDuration(min: 3, max: 8, typical: 5),
    'DJ': TestDuration(min: 3, max: 10, typical: 6),
    'SINGLE_LEG_DJ': TestDuration(min: 3, max: 8, typical: 5),
    'CMJ_REBOUND': TestDuration(min: 10, max: 30, typical: 15),
    'SINGLE_LEG_CMJ_REBOUND': TestDuration(min: 10, max: 30, typical: 15),
    'LAND_AND_HOLD': TestDuration(min: 5, max: 15, typical: 8),
    'SINGLE_LEG_LAND_AND_HOLD': TestDuration(min: 5, max: 15, typical: 8),
    'HOP_TEST': TestDuration(min: 3, max: 10, typical: 5),
    'SINGLE_LEG_HOP': TestDuration(min: 3, max: 10, typical: 5),
    'HOP_AND_RETURN': TestDuration(min: 5, max: 15, typical: 8),
    
    // FUNCTIONAL TESTS
    'SQUAT_ASSESSMENT': TestDuration(min: 5, max: 15, typical: 8),
    'SINGLE_LEG_SQUAT': TestDuration(min: 5, max: 15, typical: 8),
    'PUSH_UP': TestDuration(min: 3, max: 10, typical: 5),
    'SIT_TO_STAND': TestDuration(min: 5, max: 15, typical: 8),
    
    // ISOMETRIC TESTS
    'IMTP': TestDuration(min: 5, max: 8, typical: 6),
    'IS': TestDuration(min: 5, max: 10, typical: 7),
    'ISOMETRIC_SHOULDER': TestDuration(min: 5, max: 10, typical: 7),
    'SINGLE_LEG_ISOMETRIC': TestDuration(min: 5, max: 10, typical: 7),
    'CUSTOM_ISOMETRIC': TestDuration(min: 5, max: 15, typical: 10),
    
    // BALANCE TESTS
    'QUIET_STAND': TestDuration(min: 20, max: 60, typical: 30),
    'SINGLE_LEG_STAND': TestDuration(min: 15, max: 45, typical: 20),
    'SINGLE_LEG_RANGE_OF_STABILITY': TestDuration(min: 10, max: 30, typical: 15),
    
    // LEGACY NAMES (backward compatibility)
    'CJ': TestDuration(min: 10, max: 30, typical: 15), // CMJ_REBOUND
    'SB': TestDuration(min: 20, max: 60, typical: 30), // QUIET_STAND
    'DB': TestDuration(min: 15, max: 45, typical: 20), // Dynamic balance
    'SLB': TestDuration(min: 20, max: 60, typical: 30), // SINGLE_LEG_STAND
    'LH': TestDuration(min: 5, max: 15, typical: 10), // Lateral hop
    'APH': TestDuration(min: 5, max: 15, typical: 10), // Anterior-posterior hop
    'MLH': TestDuration(min: 5, max: 15, typical: 10), // Medial-lateral hop
  };

  // ===== SIÇRAMA TESTLERİ =====
  
  /// Countermovement Jump (CMJ) parametreleri
  static const CMJParameters cmj = CMJParameters();
  
  /// Squat Jump (SJ) parametreleri
  static const SJParameters sj = SJParameters();
  
  /// Drop Jump (DJ) parametreleri
  static const DJParameters dj = DJParameters();
  
  /// Continuous Jump (CJ) parametreleri
  static const CJParameters cj = CJParameters();
  
  // ===== YENİ SIÇRAMA TESTLERİ =====
  
  /// Loaded CMJ parametreleri
  static const LoadedCMJParameters loadedCmj = LoadedCMJParameters();
  
  /// Abalakov Jump parametreleri
  static const AbalakovParameters abalakov = AbalakovParameters();
  
  /// Single Leg CMJ parametreleri
  static const SingleLegCMJParameters singleLegCmj = SingleLegCMJParameters();
  
  /// Single Leg Drop Jump parametreleri
  static const SingleLegDJParameters singleLegDj = SingleLegDJParameters();
  
  /// CMJ Rebound parametreleri
  static const CMJReboundParameters cmjRebound = CMJReboundParameters();
  
  /// Land and Hold parametreleri
  static const LandHoldParameters landHold = LandHoldParameters();
  
  /// Hop Test parametreleri
  static const HopTestParameters hopTest = HopTestParameters();

  // ===== KUVVET TESTLERİ =====
  
  /// Isometric Mid-Thigh Pull (IMTP) parametreleri
  static const IMTPParameters imtp = IMTPParameters();
  


  // ===== DENGE TESTLERİ =====
  
  /// Static Balance (SB) parametreleri
  static const SBParameters sb = SBParameters();
  
  /// Dynamic Balance (DB) parametreleri
  static const DBParameters db = DBParameters();
  
  /// Single Leg Balance (SLB) parametreleri
  static const SLBParameters slb = SLBParameters();

  // ===== ÇEVİKLİK TESTLERİ =====
  
  /// Lateral Hop (LH) parametreleri
  static const LHParameters lh = LHParameters();

  // ===== FAZ DETECTION PARAMETRES =====
  
  /// Faz geçiş eşikleri
  static const PhaseThresholds phaseThresholds = PhaseThresholds();

  // ===== METRİK HESAPLAMA PARAMETRELERİ =====
  
  /// Filtre parametreleri
  static const FilterParameters filters = FilterParameters();
  
  /// Metrik eşikleri
  static const MetricThresholds metricThresholds = MetricThresholds();

  // ===== KALİTE KONTROL PARAMETRELERİ =====
  
  /// Test kalitesi kriterleri
  static const QualityThresholds quality = QualityThresholds();

  // ===== REFERANS DEĞERLER =====
  
  // Popülasyon normları extension'da tanımlanmıştır

  // ===== HATA KODLARI =====
  
  /// Test hata kodları
  static const Map<String, String> errorCodes = {
    'INSUFFICIENT_DATA': 'Yetersiz veri - Test tekrarlanmalı',
    'EXCESSIVE_MOVEMENT': 'Aşırı hareket - Sabit durun',
    'CALIBRATION_FAILED': 'Kalibrasyon başarısız',
    'WEIGHT_UNSTABLE': 'Ağırlık kararsız',
    'FORCE_TOO_LOW': 'Kuvvet çok düşük',
    'FORCE_TOO_HIGH': 'Kuvvet çok yüksek - Dikkat',
    'ASYMMETRY_HIGH': 'Yüksek asimetri tespit edildi',
    'PHASE_DETECTION_FAILED': 'Faz tespiti başarısız',
    'OUTLIER_DETECTED': 'Anormal değer tespit edildi',
    'INCOMPLETE_MOVEMENT': 'Hareket tamamlanmadı',
  };

  // ===== METRİK AÇIKLAMALARI =====
  
  /// Metrik açıklamaları ve birimleri
  static const Map<String, MetricInfo> metricInfo = {
    // ===== BASIC JUMP METRICS =====
    'jumpHeight': MetricInfo(
      name: 'Sıçrama Yüksekliği',
      description: 'Kütle merkezinin maksimum düşey deplasmanı',
      unit: 'cm',
      category: 'Jump Performance',
      formula: 'h = v²/(2×g)',
    ),
    'flightTime': MetricInfo(
      name: 'Uçuş Süresi',
      description: 'Platform ile temas kaybı süresi',
      unit: 'ms',
      category: 'Jump Timing',
      formula: 't = 2×√(2h/g)',
    ),
    'contactTime': MetricInfo(
      name: 'Temas Süresi',
      description: 'Platform ile temas halinde geçen süre',
      unit: 'ms',
      category: 'Jump Timing',
      formula: 'Ground contact duration',
    ),
    'takeoffVelocity': MetricInfo(
      name: 'Kalkış Hızı',
      description: 'Platform ayrılma anındaki dikey hız',
      unit: 'm/s',
      category: 'Jump Performance',
      formula: 'v = √(2gh)',
    ),
    
    // ===== FORCE METRICS =====
    'peakForce': MetricInfo(
      name: 'Tepe Kuvvet',
      description: 'Test sırasında ulaşılan maksimum kuvvet',
      unit: 'N',
      category: 'Force',
      formula: 'max(F(t))',
    ),
    'averageForce': MetricInfo(
      name: 'Ortalama Kuvvet',
      description: 'Hareket boyunca ortalama kuvvet',
      unit: 'N',
      category: 'Force',
      formula: '∫F(t)dt / Δt',
    ),
    'rfd': MetricInfo(
      name: 'Kuvvet Gelişim Hızı',
      description: 'Kuvvetin zamana göre maksimum değişim oranı',
      unit: 'N/s',
      category: 'Force',
      formula: 'max(dF/dt)',
    ),
    'impulse': MetricInfo(
      name: 'İmpuls',
      description: 'Kuvvet-zaman eğrisi altında kalan alan',
      unit: 'N⋅s',
      category: 'Force',
      formula: '∫F(t)dt',
    ),
    'peakPower': MetricInfo(
      name: 'Tepe Güç',
      description: 'Maksimum güç çıkışı',
      unit: 'W',
      category: 'Power',
      formula: 'max(F(t) × v(t))',
    ),
    'averagePower': MetricInfo(
      name: 'Ortalama Güç',
      description: 'Ortalama güç çıkışı',
      unit: 'W',
      category: 'Power',
      formula: '∫(F(t) × v(t))dt / Δt',
    ),
    
    // ===== PHASE-SPECIFIC METRICS =====
    'eccentricRfd': MetricInfo(
      name: 'Eksantrik RFD',
      description: 'Eksantrik faz kuvvet gelişim hızı',
      unit: 'N/s',
      category: 'Phase Analysis',
      formula: 'max(dF/dt) during eccentric phase',
    ),
    'concentricRfd': MetricInfo(
      name: 'Konsantrik RFD',
      description: 'Konsantrik faz kuvvet gelişim hızı',
      unit: 'N/s',
      category: 'Phase Analysis',
      formula: 'max(dF/dt) during concentric phase',
    ),
    'brakingRfd': MetricInfo(
      name: 'Frenleme RFD',
      description: 'Frenleme fazı kuvvet gelişim hızı',
      unit: 'N/s',
      category: 'Phase Analysis',
      formula: 'RFD during braking phase',
    ),
    'propulsiveRfd': MetricInfo(
      name: 'İtme RFD',
      description: 'İtme fazı kuvvet gelişim hızı',
      unit: 'N/s',
      category: 'Phase Analysis',
      formula: 'RFD during propulsive phase',
    ),
    'brakingImpulse': MetricInfo(
      name: 'Frenleme İmpulsu',
      description: 'Frenleme fazı impuls değeri',
      unit: 'N⋅s',
      category: 'Phase Analysis',
      formula: '∫F(t)dt during braking',
    ),
    'propulsiveImpulse': MetricInfo(
      name: 'İtme İmpulsu',
      description: 'İtme fazı impuls değeri',
      unit: 'N⋅s',
      category: 'Phase Analysis',
      formula: '∫F(t)dt during propulsion',
    ),
    'eccentricDuration': MetricInfo(
      name: 'Eksantrik Süre',
      description: 'Eksantrik faz süresi',
      unit: 'ms',
      category: 'Phase Timing',
      formula: 'Duration of eccentric phase',
    ),
    'concentricDuration': MetricInfo(
      name: 'Konsantrik Süre',
      description: 'Konsantrik faz süresi',
      unit: 'ms',
      category: 'Phase Timing',
      formula: 'Duration of concentric phase',
    ),
    'brakingPhaseDuration': MetricInfo(
      name: 'Frenleme Fazı Süresi',
      description: 'Frenleme fazının süresi',
      unit: 'ms',
      category: 'Phase Timing',
      formula: 'Duration of braking phase',
    ),
    'propulsivePhaseDuration': MetricInfo(
      name: 'İtme Fazı Süresi',
      description: 'İtme fazının süresi',
      unit: 'ms',
      category: 'Phase Timing',
      formula: 'Duration of propulsive phase',
    ),
    
    // ===== ASYMMETRY METRICS =====
    'asymmetryIndex': MetricInfo(
      name: 'Asimetri İndeksi',
      description: 'Sol ve sağ bacak arasındaki fark yüzdesi',
      unit: '%',
      category: 'Symmetry',
      formula: '|FL-FR|/(FL+FR)×100',
    ),
    'takeoffAsymmetry': MetricInfo(
      name: 'Kalkış Asimetrisi',
      description: 'Kalkış anında asimetri',
      unit: '%',
      category: 'Symmetry',
      formula: 'Asymmetry at takeoff moment',
    ),
    'landingAsymmetry': MetricInfo(
      name: 'İniş Asimetrisi',
      description: 'İniş anında asimetri',
      unit: '%',
      category: 'Symmetry',
      formula: 'Asymmetry during landing',
    ),
    'forceAsymmetry': MetricInfo(
      name: 'Kuvvet Asimetrisi',
      description: 'Maksimum kuvvet asimetrisi',
      unit: '%',
      category: 'Symmetry',
      formula: 'Peak force asymmetry',
    ),
    'impulseAsymmetry': MetricInfo(
      name: 'İmpuls Asimetrisi',
      description: 'İmpuls değerlerindeki asimetri',
      unit: '%',
      category: 'Symmetry',
      formula: 'Impulse asymmetry between legs',
    ),
    
    // ===== REACTIVE STRENGTH METRICS =====
    'rsi': MetricInfo(
      name: 'Reaktif Güç İndeksi',
      description: 'Sıçrama yüksekliği / temas süresi',
      unit: 'm/s',
      category: 'Reactive Strength',
      formula: 'jump height / contact time',
    ),
    'rsiMod': MetricInfo(
      name: 'Modifiye RSI',
      description: 'Uçuş süresi / temas süresi',
      unit: 'ratio',
      category: 'Reactive Strength',
      formula: 'flight time / contact time',
    ),
    
    // ===== ADVANCED COMPOSITE METRICS =====
    'dsi': MetricInfo(
      name: 'Dinamik Güç İndeksi',
      description: 'Balistik kuvvet / İzometrik kuvvet oranı',
      unit: 'ratio',
      category: 'Composite',
      formula: 'Ballistic peak force / IMTP peak force',
    ),
    'spartaLoad': MetricInfo(
      name: 'Sparta Load',
      description: 'Eksantrik güç üretim kapasitesi',
      unit: 'score',
      category: 'Sparta Metrics',
      formula: 'Eccentric loading capability',
    ),
    'spartaExplode': MetricInfo(
      name: 'Sparta Explode',
      description: 'Konsantrik kuvvet üretim kapasitesi',
      unit: 'score',
      category: 'Sparta Metrics',
      formula: 'Concentric force production',
    ),
    'spartaDrive': MetricInfo(
      name: 'Sparta Drive',
      description: 'Yerden kopuş itiş kapasitesi',
      unit: 'score',
      category: 'Sparta Metrics',
      formula: 'Takeoff drive capability',
    ),
    
    // ===== LANDING & STABILIZATION METRICS =====
    'landingHeight': MetricInfo(
      name: 'İniş Yüksekliği',
      description: 'İniş öncesi düşey mesafe',
      unit: 'cm',
      category: 'Landing',
      formula: 'Height before landing contact',
    ),
    'landingPhaseDuration': MetricInfo(
      name: 'İniş Fazı Süresi',
      description: 'İnişten stabilizasyona süre',
      unit: 'ms',
      category: 'Landing',
      formula: 'Time from contact to stabilization',
    ),
    'landingPerformanceIndex': MetricInfo(
      name: 'İniş Performans İndeksi',
      description: 'İniş yüksekliği / stabilizasyon süresi',
      unit: 'ratio',
      category: 'Landing',
      formula: 'landing height / stabilization time',
    ),
    'timeToStabilization': MetricInfo(
      name: 'Stabilizasyon Süresi',
      description: 'Dengeye gelme süresi',
      unit: 'ms',
      category: 'Stabilization',
      formula: 'Time to reach stability after landing',
    ),
    'peakLandingForce': MetricInfo(
      name: 'Pik İniş Kuvveti',
      description: 'İniş sırasında maksimum kuvvet',
      unit: 'N',
      category: 'Landing',
      formula: 'Maximum force during landing',
    ),
    'brakingForce': MetricInfo(
      name: 'Frenleme Kuvveti',
      description: 'İniş frenleme kuvveti',
      unit: 'N',
      category: 'Landing',
      formula: 'Braking force during landing',
    ),
    
    // ===== BALANCE & COP METRICS =====
    'copRange': MetricInfo(
      name: 'COP Mesafesi',
      description: 'Basınç merkezinin maksimum hareket mesafesi',
      unit: 'mm',
      category: 'Balance',
      formula: 'max(distance from center)',
    ),
    'copVelocity': MetricInfo(
      name: 'COP Hızı',
      description: 'Basınç merkezinin ortalama hareket hızı',
      unit: 'mm/s',
      category: 'Balance',
      formula: 'total path / time',
    ),
    'copArea': MetricInfo(
      name: 'COP Alanı',
      description: 'Basınç merkezinin kapsadığı alan',
      unit: 'mm²',
      category: 'Balance',
      formula: 'Ellipse area (95% confidence)',
    ),
    'stabilityIndex': MetricInfo(
      name: 'Stabilite İndeksi',
      description: 'Genel denge performansı skoru',
      unit: 'score',
      category: 'Balance',
      formula: 'Composite stability measure',
    ),
    'copPathLength': MetricInfo(
      name: 'COP Yol Uzunluğu',
      description: 'Basınç merkezi toplam hareket mesafesi',
      unit: 'mm',
      category: 'Balance',
      formula: 'Total distance traveled by CoP',
    ),
    'copFrequency': MetricInfo(
      name: 'COP Frekansı',
      description: 'Basınç merkezi salınım frekansı',
      unit: 'Hz',
      category: 'Balance',
      formula: 'Dominant frequency of CoP movement',
    ),
    'weightDistributionAsymmetry': MetricInfo(
      name: 'Ağırlık Dağılım Asimetrisi',
      description: 'Sol-sağ ağırlık dağılım farkı',
      unit: '%',
      category: 'Balance',
      formula: 'Weight distribution asymmetry',
    ),
    
    // ===== MULTI-DIRECTIONAL FORCE METRICS =====
    'lateralForce': MetricInfo(
      name: 'Yanal Kuvvet',
      description: 'Medial-lateral yöndeki kuvvet',
      unit: 'N',
      category: 'Multi-directional',
      formula: 'Force in medial-lateral direction',
    ),
    'anteriorPosteriorForce': MetricInfo(
      name: 'Ön-Arka Kuvvet',
      description: 'Anterior-posterior yöndeki kuvvet',
      unit: 'N',
      category: 'Multi-directional',
      formula: 'Force in anterior-posterior direction',
    ),
    'resultantForce': MetricInfo(
      name: 'Bileşke Kuvvet',
      description: 'Tüm eksenlerdeki toplam kuvvet',
      unit: 'N',
      category: 'Multi-directional',
      formula: '√(Fx² + Fy² + Fz²)',
    ),
    'forceAngle': MetricInfo(
      name: 'Kuvvet Açısı',
      description: 'Kuvvet vektörünün dikey eksene açısı',
      unit: 'degrees',
      category: 'Multi-directional',
      formula: 'arctan(√(Fx² + Fy²) / Fz)',
    ),
    
    // ===== FATIGUE & VARIABILITY METRICS =====
    'fatigueIndex': MetricInfo(
      name: 'Yorgunluk İndeksi',
      description: 'Performans düşüş yüzdesi',
      unit: '%',
      category: 'Fatigue',
      formula: '(first_jump - last_jump) / first_jump × 100',
    ),
    'coefficientOfVariation': MetricInfo(
      name: 'Değişkenlik Katsayısı',
      description: 'Performans tutarlılığı',
      unit: '%',
      category: 'Variability',
      formula: '(std_dev / mean) × 100',
    ),
    'sampleEntropy': MetricInfo(
      name: 'Örnek Entropi',
      description: 'Hareket karmaşıklığı',
      unit: 'score',
      category: 'Variability',
      formula: 'Sample entropy of force signal',
    ),
    'movementComplexity': MetricInfo(
      name: 'Hareket Karmaşıklığı',
      description: 'Hareket örüntü karmaşıklığı',
      unit: 'score',
      category: 'Variability',
      formula: 'Movement pattern complexity',
    ),
    
    // ===== PERFORMANCE INDICES =====
    'overallPerformance': MetricInfo(
      name: 'Genel Performans',
      description: 'Birleşik performans skoru',
      unit: 'score',
      category: 'Performance Index',
      formula: 'Composite performance measure',
    ),
    'consistencyScore': MetricInfo(
      name: 'Tutarlılık Skoru',
      description: 'Performans tutarlılık skoru',
      unit: 'score',
      category: 'Performance Index',
      formula: 'Performance consistency measure',
    ),
    'improvementRate': MetricInfo(
      name: 'Gelişim Oranı',
      description: 'Zaman içindeki gelişim oranı',
      unit: '%/week',
      category: 'Performance Index',
      formula: 'Rate of performance improvement',
    ),
    'qualityScore': MetricInfo(
      name: 'Kalite Skoru',
      description: 'Test kalitesi skoru',
      unit: 'score',
      category: 'Quality',
      formula: 'Test execution quality score',
    ),
  };

  // ===== TEST TALİMATLARI =====
  
  /// Test talimatları
  static const Map<String, TestInstructions> instructions = {
    'CMJ': TestInstructions(
      preparation: [
        'Platformlara çıkın, ayaklar omuz genişliğinde',
        'Eller belde, rahat duruş',
        'Hazır olduğunuzda başlayın'
      ],
      execution: [
        'Sakin durun (2 saniye)',
        'Hızlıca çömelin',
        'Maksimum güçle sıçrayın',
        'İki ayakla inin'
      ],
      safety: [
        'Ani hareketlerden kaçının',
        'Dengeyi koruyun',
        'Ağrı hissetmeniz durumunda durun'
      ],
    ),
    'IMTP': TestInstructions(
      preparation: [
        'Platformlara çıkın',
        'Eller belde, dik duruş',
        'Nefes alın ve hazırlanın'
      ],
      execution: [
        'Sakin durun (2 saniye)',
        'Yavaşça kuvvet artırın',
        'Maksimum kuvveti koruyun (3 saniye)',
        'Yavaşça gevşeyin'
      ],
      safety: [
        'Ani kuvvet artışı yapmayın',
        'Nefes tutmayın',
        'Ağrı durumunda hemen bırakın'
      ],
    ),
    'SB': TestInstructions(
      preparation: [
        'Platformlara çıkın',
        'Doğal duruş pozisyonu',
        'Gözler karşıya bakıyor'
      ],
      execution: [
        'Olabildiğince sabit durun',
        'Minimum sallanma',
        '30 saniye boyunca devam edin'
      ],
      safety: [
        'Düşme riski varsa test durdurun',
        'Baş dönmesi durumunda oturun'
      ],
    ),
  };
}

// ===== YENİ TEST PARAMETER SINIFLARI =====

/// Loaded CMJ test parametreleri
class LoadedCMJParameters {
  final double minJumpHeight = 3.0;           // cm
  final double maxJumpHeight = 60.0;          // cm
  final List<double> availableLoads = const [10, 20, 30, 40, 50]; // kg
  final double defaultLoad = 20.0;            // kg
  final double maxLoadPercentage = 50.0;      // % of body weight
  final double unloadingThreshold = 0.85;     // BW multiplier (lower due to load)
  final double takeoffThreshold = 0.15;       // BW multiplier
  final int quietStandingDuration = 3000;     // ms (longer for loaded)
  final int maxMovementDuration = 4000;       // ms

  const LoadedCMJParameters();
}

/// Abalakov Jump test parametreleri
class AbalakovParameters {
  final double minJumpHeight = 5.0;           // cm
  final double maxJumpHeight = 90.0;          // cm (higher due to arm swing)
  final double armSwingBonus = 5.0;           // cm (expected improvement)
  final double maxArmSwingTime = 2000.0;      // ms
  final double takeoffThreshold = 0.1;        // BW multiplier
  final int preparationTime = 3000;          // ms
  final bool requiresArmMovement = true;

  const AbalakovParameters();
}

/// Single Leg CMJ test parametreleri
class SingleLegCMJParameters {
  final double minJumpHeight = 2.0;           // cm (lower for single leg)
  final double maxJumpHeight = 40.0;          // cm
  final double stabilityThreshold = 5.0;      // degrees (ankle angle)
  final double minContactTime = 200.0;        // ms
  final double maxContactTime = 1000.0;       // ms
  final int maxTrials = 3;                    // per leg
  final List<String> legOrder = const ['dominant', 'non_dominant'];
  final double restBetweenLegs = 30.0;        // seconds

  const SingleLegCMJParameters();
}

/// Single Leg Drop Jump test parametreleri
class SingleLegDJParameters {
  final double dropHeight = 20.0;             // cm (lower for single leg)
  final List<double> availableHeights = const [15, 20, 25, 30]; // cm
  final double maxContactTime = 400.0;        // ms
  final double minReactiveIndex = 0.5;        // m/s (lower for single leg)
  final double landingThreshold = 1.5;        // BW multiplier
  final double stabilityRequirement = 2.0;    // seconds stable landing
  final int maxTrials = 3;                    // per leg per height

  const SingleLegDJParameters();
}

/// CMJ Rebound test parametreleri
class CMJReboundParameters {
  final int minJumps = 3;
  final int maxJumps = 10;
  final double targetFrequency = 2.0;         // Hz
  final double frequencyTolerance = 0.3;      // Hz
  final double minJumpHeight = 8.0;           // cm
  final double maxContactTime = 350.0;        // ms
  final double fatigueThreshold = 10.0;       // % height loss
  final double consistencyThreshold = 15.0;   // % CV
  final int restBetweenSets = 60;             // seconds

  const CMJReboundParameters();
}

/// Land and Hold test parametreleri
class LandHoldParameters {
  final double dropHeight = 30.0;             // cm
  final List<double> availableHeights = const [20, 30, 40, 50]; // cm
  final double holdDuration = 3.0;            // seconds
  final double stabilityThreshold = 5.0;      // % force variation
  final double maxLandingForce = 4.0;         // BW multiplier
  final double timeToStabilization = 1.0;     // seconds max
  final double balanceThreshold = 2.0;        // degrees
  final int maxTrials = 3;

  const LandHoldParameters();
}

/// Hop Test parametreleri
class HopTestParameters {
  final double targetDistance = 50.0;         // cm
  final double distanceTolerance = 10.0;      // cm
  final int repetitions = 5;
  final double maxContactTime = 300.0;        // ms
  final double minFlightTime = 150.0;         // ms
  final double restBetweenHops = 2.0;         // seconds
  final List<String> directions = const ['forward', 'lateral', 'backward'];
  final double asymmetryThreshold = 15.0;     // %

  const HopTestParameters();
}

/// Asymmetry Analysis parametreleri
class AsymmetryParameters {
  final double warningThreshold = 10.0;       // %
  final double errorThreshold = 15.0;         // %
  final double criticalThreshold = 25.0;      // %
  final int minSamplesForAnalysis = 100;      // samples
  final double confidenceLevel = 0.95;        // for statistical tests
  final List<String> analysisPhases = const [
    'eccentric', 'concentric', 'braking', 'propulsive', 'takeoff', 'landing'
  ];
  final bool useStatisticalTesting = true;

  const AsymmetryParameters();
}

/// Advanced Metrics parametreleri
class AdvancedMetricsParameters {
  // DSI calculation
  final double dsiTimeWindow = 0.25;          // seconds for RFD
  final double isometricHoldDuration = 3.0;   // seconds
  final double minDSIValue = 0.3;             // minimum valid DSI
  final double maxDSIValue = 1.2;             // maximum valid DSI
  
  // Sparta metrics
  final bool enableSpartaMetrics = true;
  final double spartaNormalizationFactor = 100.0;
  final Map<String, double> spartaWeights = const {
    'load': 0.33,
    'explode': 0.33,
    'drive': 0.34,
  };
  
  // Landing Performance Index
  final double lpiMinHeight = 10.0;           // cm
  final double lpiMaxStabilizationTime = 2.0; // seconds
  final double lpiWeightingFactor = 1.0;
  
  // Fatigue analysis
  final int fatigueAnalysisWindow = 5;        // jumps
  final double fatigueThreshold = 5.0;        // % performance decline
  final bool enableTrendAnalysis = true;
  
  const AdvancedMetricsParameters();
}

// ===== VERİ SINIFLAR =====

/// Test süresi parametreleri
class TestDuration {
  final int min;        // Minimum süre (saniye)
  final int max;        // Maksimum süre (saniye)
  final int typical;    // Tipik süre (saniye)

  const TestDuration({
    required this.min,
    required this.max,
    required this.typical,
  });
}

/// CMJ test parametreleri
class CMJParameters {
  final double minJumpHeight = 5.0;           // cm
  final double maxJumpHeight = 80.0;          // cm
  final double minFlightTime = 100.0;         // ms
  final double maxFlightTime = 800.0;         // ms
  final double unloadingThreshold = 0.9;      // BW multiplier
  final double takeoffThreshold = 0.1;        // BW multiplier
  final double landingThreshold = 0.5;        // BW multiplier
  final int quietStandingDuration = 2000;     // ms
  final int maxMovementDuration = 3000;       // ms

  const CMJParameters();
}

/// SJ test parametreleri
class SJParameters {
  final double minJumpHeight = 5.0;           // cm
  final double maxJumpHeight = 70.0;          // cm
  final double holdPositionDuration = 2.0;    // saniye
  final double squatDepth = 90.0;             // derece (diz açısı)
  final double takeoffThreshold = 0.1;        // BW multiplier
  final int maxHoldVariation = 50;            // N

  const SJParameters();
}

/// DJ test parametreleri
class DJParameters {
  final double dropHeight = 30.0;             // cm (default)
  final List<double> availableHeights = const [20, 30, 40, 50, 60]; // cm
  final double maxContactTime = 300.0;        // ms
  final double minReactiveIndex = 1.0;        // m/s
  final double landingThreshold = 2.0;        // BW multiplier

  const DJParameters();
}

/// CJ test parametreleri
class CJParameters {
  final int minJumps = 5;
  final int maxJumps = 20;
  final double targetFrequency = 2.2;         // Hz
  final double frequencyTolerance = 0.2;      // Hz
  final double minJumpHeight = 10.0;          // cm
  final double maxContactTime = 300.0;        // ms

  const CJParameters();
}

/// IMTP test parametreleri
class IMTPParameters {
  final double rampDuration = 3.0;            // saniye
  final double holdDuration = 3.0;            // saniye
  final double minPeakForce = 500.0;          // N
  final double maxPeakForce = 5000.0;         // N
  final double rfdTimeWindow = 0.25;          // saniye
  final double onsetThreshold = 75.0;         // N (BW * 0.1 tipik)

  const IMTPParameters();
}

/// IS test parametreleri
class ISParameters {
  final double squatAngle = 90.0;             // derece
  final double holdDuration = 5.0;            // saniye
  final double stabilityThreshold = 5.0;      // % CV
  final double minForce = 300.0;              // N
  final double maxForce = 4000.0;             // N

  const ISParameters();
}

/// SB test parametreleri
class SBParameters {
  final double testDuration = 30.0;           // saniye
  final double samplingRate = 100.0;          // Hz
  final double maxCOPRange = 100.0;           // mm
  final double stationaryThreshold = 2.0;     // mm/s
  final List<String> conditions = const ['eyes_open', 'eyes_closed', 'foam'];

  const SBParameters();
}

/// DB test parametreleri
class DBParameters {
  final double testDuration = 20.0;           // saniye
  final double targetAmplitude = 50.0;        // mm
  final double targetFrequency = 0.5;         // Hz
  final double trackingError = 10.0;          // mm (max allowed)

  const DBParameters();
}

/// SLB test parametreleri
class SLBParameters {
  final double testDuration = 30.0;           // saniye
  final double maxCOPRange = 80.0;            // mm
  final double failureThreshold = 150.0;      // mm (platform edge)
  final List<String> conditions = const ['dominant', 'non_dominant'];

  const SLBParameters();
}

/// LH test parametreleri
class LHParameters {
  final double targetDistance = 40.0;         // cm
  final int repetitions = 10;
  final double maxContactTime = 400.0;        // ms
  final double minFlightTime = 100.0;         // ms
  final double restBetweenHops = 1.0;         // saniye

  const LHParameters();
}

/// Faz geçiş eşikleri
class PhaseThresholds {
  final double quietStandingCV = 5.0;         // % (force CV)
  final double unloadingThreshold = 0.9;      // BW multiplier
  final double brakingThreshold = 1.2;        // BW multiplier
  final double propulsionThreshold = 1.0;     // BW multiplier
  final double takeoffThreshold = 0.1;        // BW multiplier
  final double landingThreshold = 0.5;        // BW multiplier
  final int minPhaseDuration = 50;            // ms

  const PhaseThresholds();
}

/// Filtre parametreleri
class FilterParameters {
  final double lowPassCutoff = 50.0;          // Hz
  final double highPassCutoff = 0.5;          // Hz
  final int butterworthOrder = 4;             // ✅ DÜZELTME: Tek field
  final double notchFrequency = 50.0;         // Hz (power line)
  final bool enableAntiAliasing = true;

  const FilterParameters();
}

/// Metrik eşikleri
class MetricThresholds {
  final double minValidJumpHeight = 2.0;      // cm
  final double maxValidJumpHeight = 100.0;    // cm
  final double maxAsymmetry = 50.0;           // %
  final double minFlightTime = 50.0;          // ms
  final double maxFlightTime = 1000.0;        // ms
  final double maxRFD = 10000.0;              // N/s
  final double maxCOPVelocity = 500.0;        // mm/s

  const MetricThresholds();
}

/// Kalite kontrol eşikleri
class QualityThresholds {
  final double minTestDurationRatio = 0.5;    // Min duration / expected
  final double maxTestDurationRatio = 2.0;    // Max duration / expected
  final double maxForceNoiseLevel = 10.0;     // N RMS
  final double minSampleRate = 500.0;         // Hz
  final double maxMissingSamples = 5.0;       // %
  final double maxAsymmetryWarning = 15.0;    // %
  final double maxAsymmetryError = 30.0;      // %

  const QualityThresholds();
}


/// Metrik bilgisi
class MetricInfo {
  final String name;
  final String description;
  final String unit;
  final String category;
  final String formula;

  const MetricInfo({
    required this.name,
    required this.description,
    required this.unit,
    required this.category,
    required this.formula,
  });
}

/// Popülasyon normları
class PopulationNorms {
  final double maleMean;
  final double maleStd;
  final double femaleMean;
  final double femaleStd;
  final String unit;

  const PopulationNorms({
    required this.maleMean,
    required this.maleStd,
    required this.femaleMean,
    required this.femaleStd,
    required this.unit,
  });

  /// Z-score hesapla
  double calculateZScore(double value, bool isMale) {
    final mean = isMale ? maleMean : femaleMean;
    final std = isMale ? maleStd : femaleStd;
    if (std <= 0) return 0.0;
    return (value - mean) / std;
  }

  /// Persentil hesapla (yaklaşık)
  double calculatePercentile(double value, bool isMale) {
    final zScore = calculateZScore(value, isMale);
    // Simplified normal distribution CDF approximation
    return 50 + 50 * _erf(zScore / 1.414213562373095);
  }

  double _erf(double x) {
    // Simplified error function approximation
    const a = 0.3275911;
    final t = 1.0 / (1.0 + a * x.abs());
    final result = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * math.exp(-x * x);
    return x >= 0 ? result : -result;
  }
}

/// Test talimatları
class TestInstructions {
  final List<String> preparation;
  final List<String> execution;
  final List<String> safety;

  const TestInstructions({
    required this.preparation,
    required this.execution,
    required this.safety,
  });
}

/// Metrik bilgileri
extension TestConstantsMetrics on TestConstants {
  /// Metrik bilgileri haritası
  static const Map<String, MetricInfo> metricInfo = {
    'jumpHeight': MetricInfo(
      name: 'Sıçrama Yüksekliği',
      description: 'Maksimum sıçrama yüksekliği',
      unit: 'cm',
      category: 'Jump',
      formula: 'v²/(2*g)',
    ),
    'flightTime': MetricInfo(
      name: 'Uçuş Süresi',
      description: 'Havada kalma süresi',
      unit: 's',
      category: 'Jump',
      formula: '2*sqrt(2*h/g)',
    ),
    'contactTime': MetricInfo(
      name: 'Temas Süresi',
      description: 'Zeminde temas süresi',
      unit: 's',
      category: 'Jump',
      formula: 'landing_time - takeoff_time',
    ),
    'peakForce': MetricInfo(
      name: 'Pik Kuvvet',
      description: 'Maksimum kuvvet değeri',
      unit: 'N',
      category: 'Force',
      formula: 'max(force)',
    ),
    'averageForce': MetricInfo(
      name: 'Ortalama Kuvvet',
      description: 'Ortalama kuvvet değeri',
      unit: 'N',
      category: 'Force',
      formula: 'mean(force)',
    ),
    'rfd': MetricInfo(
      name: 'Kuvvet Gelişim Hızı',
      description: 'Kuvvetin gelişim hızı',
      unit: 'N/s',
      category: 'Force',
      formula: 'Δforce/Δtime',
    ),
    'peakPower': MetricInfo(
      name: 'Pik Güç',
      description: 'Maksimum güç değeri',
      unit: 'W',
      category: 'Power',
      formula: 'force * velocity',
    ),
    'takeoffVelocity': MetricInfo(
      name: 'Kalkış Hızı',
      description: 'Kalkış anındaki hız',
      unit: 'm/s',
      category: 'Jump',
      formula: 'velocity_at_takeoff',
    ),
    'impulse': MetricInfo(
      name: 'İmpuls',
      description: 'Kuvvet-zaman integrali',
      unit: 'N*s',
      category: 'Force',
      formula: '∫force*dt',
    ),
    'asymmetryIndex': MetricInfo(
      name: 'Asimetri İndeksi',
      description: 'Sağ-sol asimetri yüzdesi',
      unit: '%',
      category: 'Asymmetry',
      formula: '|left-right|/max(left,right)*100',
    ),
    'stabilityIndex': MetricInfo(
      name: 'Stabilite İndeksi',
      description: 'Denge stabilite ölçümü',
      unit: 'score',
      category: 'Balance',
      formula: 'sqrt(var(cop_x) + var(cop_y))',
    ),
    'copRange': MetricInfo(
      name: 'COP Aralığı',
      description: 'Basınç merkezi aralığı',
      unit: 'mm',
      category: 'Balance',
      formula: 'max(cop) - min(cop)',
    ),
    'copVelocity': MetricInfo(
      name: 'COP Hızı',
      description: 'Basınç merkezi hızı',
      unit: 'mm/s',
      category: 'Balance',
      formula: 'mean(|Δcop/Δt|)',
    ),
  };

  /// Popülasyon normları
  static const Map<String, PopulationNorms> populationNorms = {
    'CMJ_jumpHeight': PopulationNorms(
      maleMean: 45.0, maleStd: 8.0,
      femaleMean: 35.0, femaleStd: 6.0,
      unit: 'cm',
    ),
    'CMJ_peakForce': PopulationNorms(
      maleMean: 2500.0, maleStd: 400.0,
      femaleMean: 2000.0, femaleStd: 300.0,
      unit: 'N',
    ),
    'CMJ_flightTime': PopulationNorms(
      maleMean: 0.55, maleStd: 0.08,
      femaleMean: 0.48, femaleStd: 0.06,
      unit: 's',
    ),
    'SJ_jumpHeight': PopulationNorms(
      maleMean: 40.0, maleStd: 7.0,
      femaleMean: 32.0, femaleStd: 5.0,
      unit: 'cm',
    ),
    'SJ_peakForce': PopulationNorms(
      maleMean: 2800.0, maleStd: 450.0,
      femaleMean: 2200.0, femaleStd: 350.0,
      unit: 'N',
    ),
    'IMTP_peakForce': PopulationNorms(
      maleMean: 3500.0, maleStd: 600.0,
      femaleMean: 2500.0, femaleStd: 450.0,
      unit: 'N',
    ),
    'rfd': PopulationNorms(
      maleMean: 4500.0, maleStd: 800.0,
      femaleMean: 3500.0, femaleStd: 600.0,
      unit: 'N/s',
    ),
    'asymmetryIndex': PopulationNorms(
      maleMean: 5.0, maleStd: 3.0,
      femaleMean: 5.5, femaleStd: 3.2,
      unit: '%',
    ),
  };
  
  /// Yeni test talimatları - Genişletilmiş protokoller
  static const Map<String, TestInstructions> testInstructions = {
    // ===== SIÇRAMA TESTLERİ =====
    
    'CMJ_LOADED': TestInstructions(
      preparation: [
        'Sporcu yüklü yelek/barbell ile donatılmalı (vücut ağırlığının %20-40\'ı)',
        'Platformlarda ayaklar omuz genişliğinde konumlandır',
        'Elleri belde veya yanlarda serbest bırak',
        'Başlangıç pozisyonunda 2 saniye bekle',
        'Ağırlık dağılımını kontrol et'
      ],
      execution: [
        'Countermovement fazında hızlı çök (diz açısı ~90°)',
        'Hiç durmadan maksimum güçle sıçra',
        'Kolları serbestçe kullan',
        'Çift ayak olarak aynı anda inin',
        'İniş sonrası 2 saniye sabit kal',
        'Yükle 3-5 tekrar yap'
      ],
      safety: [
        'Yüklü atlama güvenlik önlemleri alın',
        'Progresif yük artışı yapın',
        'Yorgunluk durumunda durdurun',
        'Güvenli iniş teknikleri uygulayın'
      ],
    ),
    
    'ABALAKOV': TestInstructions(
      preparation: [
        'Sporcu ayakta, kollar yukarıya doğru uzatılmış',
        'Parmak uçları ile duvara veya tahtaya ulaşım mesafesi ölç',
        'Bu mesafe Abalakov jump yüksekliği referansı',
        'Platformlarda ayaklar omuz genişliğinde',
        'Rahat duruş pozisyonu al'
      ],
      execution: [
        'Kolları hızla aşağı-arkaya savur',
        'Aynı anda çök ve momentum oluştur',
        'Maksimum güçle sıçrayarak kolları yukarı savur',
        'Sıçrama sırasında tek el ile maksimum uzanım',
        'İniş sonrası final pozisyonda ölçüm al',
        '3 tekrar yapıp en iyisini al'
      ],
      safety: [
        'Kol hareketi kontrolü sağlayın',
        'Denge kaybı durumunda destek verin',
        'Omuz esnekliği uygun olmalı'
      ],
    ),
    
    'SINGLE_LEG_CMJ': TestInstructions(
      preparation: [
        'Tek ayak platformda (sağ/sol ayrı test)',
        'Karşı bacak hafif çekili veya arkada',
        'Kollar serbest hareket edebilir',
        'Denge kurulana kadar bekle',
        'Test bacağında tam ağırlık'
      ],
      execution: [
        'Tek bacakla countermovement yap',
        'Hızlı çök, hiç durmadan sıçra',
        'Kolları aktif kullan',
        'Aynı ayakla inin',
        'İniş sonrası denge kur (2 saniye)',
        'Her bacak için 3\'er tekrar'
      ],
      safety: [
        'Denge kaybında yardım edin',
        'Zayıf bacak önce test edilmemeli',
        'Yeterli ısınma yapılmalı'
      ],
    ),
    
    'CMJ_REBOUND': TestInstructions(
      preparation: [
        'Sürekli sıçrama protokolü (15 saniye)',
        'Metronom veya sayaç hazırla (2.5 Hz)',
        'Başlangıç CMJ pozisyonu al',
        'Ritim çalıştır',
        'Konsantrasyon sağla'
      ],
      execution: [
        'Belirtilen ritimde sürekli sıçra',
        'Her sıçrama maksimum eforu',
        'Minimum temas süresi hedefle',
        'Kol koordinasyonu koru',
        'Ritimden sapma olmasın',
        '15 saniye boyunca devam et'
      ],
      safety: [
        'Yorgunluk takibi yapın',
        'Ritim kaybında durdurun',
        'Aşırı yüklenme önleyin'
      ],
    ),
    
    'LAND_AND_HOLD': TestInstructions(
      preparation: [
        'Drop yüksekliği belirle (20-60 cm)',
        'İniş platformları hazırla',
        'Sporcu başlangıç pozisyonunda',
        'Hold süresi belirle (2-5 saniye)',
        'İniş tekniği hatırlat'
      ],
      execution: [
        'Belirlenen yükseklikten atla',
        'Çift ayak simultane iniş yap',
        'İniş anında yumuşak landing',
        'Belirtilen süre boyunca sabit kal',
        'Hareket etmeden hold pozisyonu koru',
        '3 tekrar gerçekleştir'
      ],
      safety: [
        'Progresif yükseklik artışı',
        'İniş tekniği güvenliği',
        'Hold süresi yeteneğe uygun'
      ],
    ),
    
    // ===== İZOMETRİK TESTLERİ =====
    
    'IMTP': TestInstructions(
      preparation: [
        'İsometric Mid-Thigh Pull setup hazırla',
        'Bar yüksekliği diz üstü 5cm (mid-thigh)',
        'Ayaklar omuz genişliğinde',
        'Eller overhand grip',
        'Sırt düz, göğüs açık pozisyon'
      ],
      execution: [
        'Başlangıçta bar\'a hafif temas',
        '3-2-1 komutunda maksimum çek',
        '3-5 saniye maksimum kuvvet uygula',
        'Hiç gevşemeden sürdür',
        'Kademeli olarak bırak',
        '2 dakika dinlenme arası ile 2-3 tekrar'
      ],
      safety: [
        'Sırt güvenliği öncelik',
        'Aşamalı kuvvet artışı',
        'Nefes kontrolü sağla'
      ],
    ),
    
    'ISOMETRIC_SQUAT': TestInstructions(
      preparation: [
        'Wall squat veya squat rack setup',
        'Diz açısı 90° pozisyona ayarla',
        'Sırt duvara dik temas',
        'Ayaklar platformda sabit',
        'Kol pozisyonu belirle'
      ],
      execution: [
        'Belirlenen pozisyonda sabit dur',
        'Maksimum kuvvet uygulamaya başla',
        '5 saniye boyunca maksimum eforu sürdür',
        'Pozisyon değişimi yapma',
        'Kademeli kuvvet azalt',
        '2 tekrar yap'
      ],
      safety: [
        'Diz stabilitesi kontrol et',
        'Aşırı yüklenme önle',
        'Pozisyon konforu sağla'
      ],
    ),
    
    // ===== FONKSİYONEL TESTLERİ =====
    
    'SQUAT_ASSESSMENT': TestInstructions(
      preparation: [
        'Bodyweight squat değerlendirmesi',
        'Ayaklar omuz genişliğinde',
        'Kollar ileriye uzatılı',
        'Başlangıç duruş pozisyonu',
        'Hareket kalitesi gözlem hazırlığı'
      ],
      execution: [
        'Kontrollü olarak aşağı çök',
        'Diz açısı minimum 90° hedefle',
        'Topuk yerden kalkmamalı',
        'Sırt düz pozisyon koru',
        '2 saniye hold pozisyonu',
        'Kontrollü olarak yukarı çık',
        '5 tekrar yap'
      ],
      safety: [
        'Hareket amplitüdü kademeli artır',
        'Diz valgus kontrolü',
        'Denge güvenliği'
      ],
    ),
    
    'SINGLE_LEG_SQUAT': TestInstructions(
      preparation: [
        'Tek bacak squat değerlendirmesi',
        'Test bacağı platformda',
        'Karşı bacak havada',
        'Kollar denge için serbest',
        'Başlangıç tek ayak duruş'
      ],
      execution: [
        'Tek bacakla kontrollü çök',
        'Mümkün olduğunca aşağı in',
        'Diz kontrolü ve stabilite koru',
        'Hold pozisyonu (2 saniye)',
        'Kontrollü geri dön',
        'Her bacak 3\'er tekrar'
      ],
      safety: [
        'Denge desteği hazır ol',
        'Gradual progression uygula',
        'Diz güvenliği öncelik'
      ],
    ),
    
    // ===== DENGE TESTLERİ =====
    
    'QUIET_STAND': TestInstructions(
      preparation: [
        'Çift ayak sakin duruş testi',
        'Ayaklar omuz genişliğinde',
        'Kollar yanlar da rahat',
        'Gözler ileriye odaklanmış',
        'Minimal hareket hedefi'
      ],
      execution: [
        '30 saniye hareketsiz dur',
        'Minimal postural salınım',
        'Gözler sabit nokta odaklı',
        'Doğal nefes al',
        'Kasılma olmadan rahat dur',
        '2 tekrar yap (gözler açık/kapalı)'
      ],
      safety: [
        'Düşme riski değerlendir',
        'Çevresel güvenlik sağla',
        'Maksimum test süresi 60 saniye'
      ],
    ),
    
    'SINGLE_LEG_STAND': TestInstructions(
      preparation: [
        'Tek ayak denge testi',
        'Test bacağı platformda',
        'Karşı bacak hafif çekili',
        'Kollar denge için kullanılabilir',
        'Gözler ileriye odaklı'
      ],
      execution: [
        'Tek ayak üzerinde denge kur',
        'Maksimum 30 saniye dur',
        'Minimal salınım hedefle',
        'Diğer ayak yere değmemeli',
        'Her bacak test et',
        'Gözler açık/kapalı versiyonlar'
      ],
      safety: [
        'Düşme önlemi al',
        'Yardım hazır beklet',
        'Test süresini kademeli artır'
      ],
    ),
    
    // ===== ÇEVİKLİK TESTLERİ =====
    
    'HOP_TEST': TestInstructions(
      preparation: [
        'Çoklu yön hop testi',
        'Başlangıç pozisyonu işaretle',
        'Hop mesafesi/kalitesi değerlendirme',
        'Güvenlik alanı belirle',
        'Test yönü planla (ileri/yan/çapraz)'
      ],
      execution: [
        'Belirlenen yönde hop gerçekleştir',
        'Maksimum mesafe/hız hedefle',
        'Kontrollü iniş yap',
        'Her yön için 3 tekrar',
        'En iyi performansı kaydet',
        'Bilateral/unilateral varyasyonlar'
      ],
      safety: [
        'Hop alanı güvenliği',
        'İniş yüzeyi uygun',
        'Progresif hop mesafesi'
      ],
    ),
    
    'HOP_AND_RETURN': TestInstructions(
      preparation: [
        'İleri hop + geri dönüş testi',
        'Başlangıç çizgisi işaretle',
        'Hop mesafesi belirle',
        'Dönüş zamanı ölçüm hazırlığı',
        'Test protokolü açıkla'
      ],
      execution: [
        'İleri doğru maksimum hop yap',
        'Landing sonrası hızla dön',
        'Geri başlangıç pozisyonuna hop',
        'Total time ve kalite değerlendir',
        '3 tekrar yap',
        'En hızlı ve kaliteli performans seç'
      ],
      safety: [
        'Dönüş manevrası güvenliği',
        'Çarpışma riski önle',
        'Uygun alan boyutu'
      ],
    ),
  };
}