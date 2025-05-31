import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';
import 'athlete.dart';
import 'force_data.dart';

/// Test sonucu domain entity
class TestResult extends Equatable {
  final String id;
  final String sessionId;
  final String athleteId;
  final TestType testType;
  final DateTime testDate;
  final Duration duration;
  final TestStatus status;
  final Map<String, double> metrics;
  final Map<String, dynamic>? metadata;
  final String? notes;
  final DateTime createdAt;

  const TestResult({
    required this.id,
    required this.sessionId,
    required this.athleteId,
    required this.testType,
    required this.testDate,
    required this.duration,
    required this.status,
    required this.metrics,
    this.metadata,
    this.notes,
    required this.createdAt,
  });

  /// Test başarılı mı?
  bool get isSuccessful => status == TestStatus.completed && metrics.isNotEmpty;

  /// Test kalite skoru (0-100)
  double get qualityScore {
    if (!isSuccessful) return 0.0;
    
    double score = 100.0;
    
    // Duration check
    final expectedDuration = _getExpectedDuration();
    final durationRatio = duration.inSeconds / expectedDuration.inSeconds;
    if (durationRatio < 0.5 || durationRatio > 2.0) {
      score -= 20; // Çok kısa veya uzun test
    }
    
    // Asymmetry check
    final asymmetry = metrics['asymmetryIndex'] ?? 0.0;
    if (asymmetry > 20) {
      score -= 15; // Yüksek asimetri
    } else if (asymmetry > 10) {
      score -= 5;
    }
    
    // Force variability check (if available)
    final forceCV = metrics['forceCoefficientOfVariation'] ?? 0.0;
    if (forceCV > 0.15) {
      score -= 10; // Yüksek değişkenlik
    }
    
    // Test-specific quality checks
    score -= _getTestSpecificDeductions();
    
    return score.clamp(0.0, 100.0);
  }

  Duration _getExpectedDuration() {
    switch (testType) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        return const Duration(seconds: 5);
      case TestType.isometricMidThighPull:
      case TestType.isometricSquat:
        return const Duration(seconds: 8);
      case TestType.staticBalance:
      case TestType.singleLegBalance:
        return const Duration(seconds: 30);
      case TestType.dynamicBalance:
        return const Duration(seconds: 20);
      default:
        return const Duration(seconds: 10);
    }
  }

  double _getTestSpecificDeductions() {
    double deduction = 0.0;
    
    switch (testType) {
      case TestType.counterMovementJump:
        // CMJ specific checks
        final jumpHeight = metrics['jumpHeight'] ?? 0.0;
        final flightTime = metrics['flightTime'] ?? 0.0;
        
        if (jumpHeight < 10) deduction += 10; // Çok düşük sıçrama
        if (flightTime < 200) deduction += 5; // Çok kısa uçuş
        break;
        
      case TestType.staticBalance:
        // Balance specific checks
        final copRange = metrics['copRange'] ?? 0.0;
        if (copRange > 50) deduction += 10; // Çok fazla sallanma
        break;
        
      default:
        break;
    }
    
    return deduction;
  }

  /// Kalite durumu
  TestQuality get quality {
    final score = qualityScore;
    if (score >= 90) return TestQuality.excellent;
    if (score >= 75) return TestQuality.good;
    if (score >= 60) return TestQuality.fair;
    if (score >= 40) return TestQuality.poor;
    return TestQuality.invalid;
  }

  /// Ana metrikler (test türüne göre)
  Map<String, double> get primaryMetrics {
    switch (testType) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        return {
          'jumpHeight': metrics['jumpHeight'] ?? 0.0,
          'peakForce': metrics['peakForce'] ?? 0.0,
          'flightTime': metrics['flightTime'] ?? 0.0,
          'asymmetryIndex': metrics['asymmetryIndex'] ?? 0.0,
        };
        
      case TestType.isometricMidThighPull:
      case TestType.isometricSquat:
        return {
          'peakForce': metrics['peakForce'] ?? 0.0,
          'rfd': metrics['rfd'] ?? 0.0,
          'impulse': metrics['impulse'] ?? 0.0,
          'asymmetryIndex': metrics['asymmetryIndex'] ?? 0.0,
        };
        
      case TestType.staticBalance:
      case TestType.singleLegBalance:
      case TestType.dynamicBalance:
        return {
          'copRange': metrics['copRange'] ?? 0.0,
          'copVelocity': metrics['copVelocity'] ?? 0.0,
          'copArea': metrics['copArea'] ?? 0.0,
          'stabilityIndex': metrics['stabilityIndex'] ?? 0.0,
        };
        
      default:
        return Map.from(metrics);
    }
  }

  /// Performans kategorisi (sporcu yaşı ve cinsiyetine göre)
  PerformanceCategory getPerformanceCategory(Athlete athlete) {
    final jumpHeight = metrics['jumpHeight'];
    if (jumpHeight == null) return PerformanceCategory.average;
    
    // Yaş ve cinsiyet bazlı normlar (basit örnek)
    final age = athlete.age ?? 25;
    final isMale = athlete.gender == Gender.male;
    
    double excellentThreshold, goodThreshold, poorThreshold;
    
    if (isMale) {
      if (age < 20) {
        excellentThreshold = 45;
        goodThreshold = 35;
        poorThreshold = 25;
      } else if (age < 30) {
        excellentThreshold = 50;
        goodThreshold = 40;
        poorThreshold = 30;
      } else {
        excellentThreshold = 45;
        goodThreshold = 35;
        poorThreshold = 25;
      }
    } else {
      if (age < 20) {
        excellentThreshold = 35;
        goodThreshold = 28;
        poorThreshold = 20;
      } else if (age < 30) {
        excellentThreshold = 40;
        goodThreshold = 32;
        poorThreshold = 24;
      } else {
        excellentThreshold = 35;
        goodThreshold = 28;
        poorThreshold = 20;
      }
    }
    
    if (jumpHeight >= excellentThreshold) return PerformanceCategory.excellent;
    if (jumpHeight >= goodThreshold) return PerformanceCategory.good;
    if (jumpHeight >= poorThreshold) return PerformanceCategory.average;
    return PerformanceCategory.poor;
  }

  /// Metrik birimini getir
  String getMetricUnit(String metricName) {
    switch (metricName) {
      case 'jumpHeight':
        return 'cm';
      case 'flightTime':
      case 'contactTime':
      case 'timeToTakeoff':
        return 'ms';
      case 'peakForce':
      case 'averageForce':
      case 'impulse':
        return 'N';
      case 'peakPower':
      case 'averagePower':
        return 'W';
      case 'rfd':
        return 'N/s';
      case 'asymmetryIndex':
      case 'leftLoadPercentage':
      case 'rightLoadPercentage':
        return '%';
      case 'takeoffVelocity':
        return 'm/s';
      case 'copRange':
      case 'copVelocity':
      case 'copArea':
        return 'mm';
      case 'stabilityIndex':
        return 'score';
      default:
        return '';
    }
  }

  /// Metrik açıklamasını getir
  String getMetricDescription(String metricName) {
    switch (metricName) {
      case 'jumpHeight':
        return 'Sıçrama yüksekliği - düşey deplasmanın maksimum değeri';
      case 'flightTime':
        return 'Uçuş süresi - platformla temas kaybı süresi';
      case 'contactTime':
        return 'Temas süresi - platform ile temas halinde geçen süre';
      case 'peakForce':
        return 'Tepe kuvvet - test sırasında ulaşılan maksimum kuvvet';
      case 'averageForce':
        return 'Ortalama kuvvet - test boyunca ortalama kuvvet değeri';
      case 'rfd':
        return 'Kuvvet gelişim hızı - kuvvetin zamana göre değişim oranı';
      case 'impulse':
        return 'İmpuls - kuvvet-zaman eğrisi altında kalan alan';
      case 'asymmetryIndex':
        return 'Asimetri indeksi - sol ve sağ bacak arasındaki fark yüzdesi';
      case 'takeoffVelocity':
        return 'Kalkış hızı - platformdan ayrılma anındaki dikey hız';
      case 'copRange':
        return 'COP mesafesi - basınç merkezinin hareket aralığı';
      case 'stabilityIndex':
        return 'Stabilite indeksi - denge performansının genel değerlendirmesi';
      default:
        return metricName;
    }
  }

  /// Karşılaştırma (önceki testlerle)
  TestComparison? compareWith(TestResult previousResult) {
    if (testType != previousResult.testType) return null;
    
    final comparisons = <String, double>{};
    
    for (final key in primaryMetrics.keys) {
      final current = metrics[key];
      final previous = previousResult.metrics[key];
      
      if (current != null && previous != null && previous != 0) {
        final improvement = ((current - previous) / previous) * 100;
        comparisons[key] = improvement;
      }
    }
    
    return TestComparison(
      previousTest: previousResult,
      currentTest: this,
      improvements: comparisons,
    );
  }

  /// Copy with
  TestResult copyWith({
    String? id,
    String? sessionId,
    String? athleteId,
    TestType? testType,
    DateTime? testDate,
    Duration? duration,
    TestStatus? status,
    Map<String, double>? metrics,
    Map<String, dynamic>? metadata,
    String? notes,
    DateTime? createdAt,
  }) {
    return TestResult(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      athleteId: athleteId ?? this.athleteId,
      testType: testType ?? this.testType,
      testDate: testDate ?? this.testDate,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      metrics: metrics ?? Map.from(this.metrics),
      metadata: metadata ?? (this.metadata != null ? Map.from(this.metadata!) : null),
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Factory - create new result
  factory TestResult.create({
    required String sessionId,
    required String athleteId,
    required TestType testType,
    required Duration duration,
    required Map<String, double> metrics,
    Map<String, dynamic>? metadata,
    String? notes,
  }) {
    final now = DateTime.now();
    return TestResult(
      id: _generateId(),
      sessionId: sessionId,
      athleteId: athleteId,
      testType: testType,
      testDate: now,
      duration: duration,
      status: TestStatus.completed,
      metrics: Map.from(metrics),
      metadata: metadata != null ? Map.from(metadata) : null,
      notes: notes,
      createdAt: now,
    );
  }

  static String _generateId() {
    return 'result_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// To database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'athleteId': athleteId,
      'testType': testType.name,
      'testDate': testDate.toIso8601String(),
      'duration': duration.inMilliseconds,
      'status': status.name,
      'metrics': metrics,
      'metadata': metadata,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// From database map
  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      id: map['id'] as String,
      sessionId: map['sessionId'] as String,
      athleteId: map['athleteId'] as String,
      testType: TestType.values.firstWhere((e) => e.name == map['testType']),
      testDate: DateTime.parse(map['testDate'] as String),
      duration: Duration(milliseconds: map['duration'] as int),
      status: TestStatus.values.firstWhere((e) => e.name == map['status']),
      metrics: Map<String, double>.from(map['metrics'] as Map),
      metadata: map['metadata'] as Map<String, dynamic>?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() => toMap();

  /// From JSON
  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult.fromMap(json);

  @override
  List<Object?> get props => [
        id,
        sessionId,
        athleteId,
        testType,
        testDate,
        duration,
        status,
        metrics,
        metadata,
        notes,
        createdAt,
      ];

  @override
  String toString() {
    return 'TestResult(id: $id, type: ${testType.turkishName}, '
           'quality: ${quality.turkishName}, metrics: ${metrics.length})';
  }
}

/// Test kalitesi enum
enum TestQuality {
  excellent('Excellent', 'Mükemmel'),
  good('Good', 'İyi'),
  fair('Fair', 'Orta'),
  poor('Poor', 'Zayıf'),
  invalid('Invalid', 'Geçersiz');

  const TestQuality(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;

  /// Kalite rengi
  String get colorHex {
    switch (this) {
      case TestQuality.excellent:
        return '#4CAF50'; // Green
      case TestQuality.good:
        return '#8BC34A'; // Light Green
      case TestQuality.fair:
        return '#FF9800'; // Orange
      case TestQuality.poor:
        return '#FF5722'; // Deep Orange
      case TestQuality.invalid:
        return '#F44336'; // Red
    }
  }
}

/// Performans kategorisi
enum PerformanceCategory {
  excellent('Excellent', 'Mükemmel'),
  good('Good', 'İyi'),
  average('Average', 'Ortalama'),
  poor('Poor', 'Zayıf');

  const PerformanceCategory(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}

/// Test karşılaştırması
class TestComparison extends Equatable {
  final TestResult previousTest;
  final TestResult currentTest;
  final Map<String, double> improvements; // Yüzde değişim

  const TestComparison({
    required this.previousTest,
    required this.currentTest,
    required this.improvements,
  });

  /// Genel gelişim yüzdesi
  double get overallImprovement {
    if (improvements.isEmpty) return 0.0;
    return improvements.values.reduce((a, b) => a + b) / improvements.length;
  }

  /// Gelişim durumu
  ImprovementStatus get status {
    final improvement = overallImprovement;
    if (improvement > 5) return ImprovementStatus.significant;
    if (improvement > 0) return ImprovementStatus.slight;
    if (improvement > -5) return ImprovementStatus.stable;
    return ImprovementStatus.decline;
  }

  /// En çok gelişen metrik
  String? get mostImprovedMetric {
    if (improvements.isEmpty) return null;
    return improvements.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// En çok gerileyen metrik
  String? get mostDeclinedMetric {
    if (improvements.isEmpty) return null;
    return improvements.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  @override
  List<Object?> get props => [previousTest, currentTest, improvements];
}

/// Gelişim durumu
enum ImprovementStatus {
  significant('Significant', 'Önemli Gelişim'),
  slight('Slight', 'Hafif Gelişim'),
  stable('Stable', 'Stabil'),
  decline('Decline', 'Gerileme');

  const ImprovementStatus(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}

/// Mock test results
class MockTestResults {
  static List<TestResult> generateForAthlete(String athleteId, {int count = 5}) {
    final results = <TestResult>[];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final testDate = now.subtract(Duration(days: i * 7)); // Haftalık testler
      
      results.add(TestResult.create(
        sessionId: 'session_${testDate.millisecondsSinceEpoch}',
        athleteId: athleteId,
        testType: TestType.counterMovementJump,
        duration: Duration(seconds: 5 + i), // Slight variation
        metrics: {
          'jumpHeight': 35.0 + (i * 2) + (i % 2 == 0 ? 1 : -1), // Trend + noise
          'peakForce': 1200.0 + (i * 50),
          'flightTime': 450.0 + (i * 20),
          'asymmetryIndex': 8.0 + (i % 3),
          'rfd': 3500.0 + (i * 100),
        },
      ));
    }

    return results.reversed.toList(); // Oldest first
  }
}