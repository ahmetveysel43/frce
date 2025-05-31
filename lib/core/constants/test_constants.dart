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
    'CMJ': TestDuration(min: 3, max: 10, typical: 5),
    'SJ': TestDuration(min: 3, max: 8, typical: 5),
    'DJ': TestDuration(min: 3, max: 10, typical: 6),
    'CJ': TestDuration(min: 10, max: 30, typical: 15),
    'IMTP': TestDuration(min: 5, max: 8, typical: 6),
    'IS': TestDuration(min: 5, max: 10, typical: 7),
    'SB': TestDuration(min: 20, max: 60, typical: 30),
    'DB': TestDuration(min: 15, max: 45, typical: 20),
    'SLB': TestDuration(min: 20, max: 60, typical: 30),
    'LH': TestDuration(min: 5, max: 15, typical: 10),
    'APH': TestDuration(min: 5, max: 15, typical: 10),
    'MLH': TestDuration(min: 5, max: 15, typical: 10),
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
  
  /// Popülasyon normları (yaş ve cinsiyet bazlı)
  static const Map<String, PopulationNorms> populationNorms = {
    'CMJ_jumpHeight': PopulationNorms(
      maleMean: 35.0, maleStd: 8.0,
      femaleMean: 28.0, femaleStd: 6.0,
      unit: 'cm',
    ),
    'CMJ_peakForce': PopulationNorms(
      maleMean: 2200.0, maleStd: 400.0,
      femaleMean: 1600.0, femaleStd: 300.0,
      unit: 'N',
    ),
    'IMTP_peakForce': PopulationNorms(
      maleMean: 3000.0, maleStd: 600.0,
      femaleMean: 2000.0, femaleStd: 400.0,
      unit: 'N',
    ),
    'SB_copRange': PopulationNorms(
      maleMean: 25.0, maleStd: 8.0,
      femaleMean: 22.0, femaleStd: 7.0,
      unit: 'mm',
    ),
  };

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
    'asymmetryIndex': MetricInfo(
      name: 'Asimetri İndeksi',
      description: 'Sol ve sağ bacak arasındaki fark yüzdesi',
      unit: '%',
      category: 'Symmetry',
      formula: '|FL-FR|/(FL+FR)×100',
    ),
    'takeoffVelocity': MetricInfo(
      name: 'Kalkış Hızı',
      description: 'Platform ayrılma anındaki dikey hız',
      unit: 'm/s',
      category: 'Jump Performance',
      formula: 'v = √(2gh)',
    ),
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
    final a = 0.3275911;
    final t = 1.0 / (1.0 + a * x.abs());
    final result = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * math.exp(-x * x);
    return x >= 0 ? result : -result;
  }
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