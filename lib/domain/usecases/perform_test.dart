import 'dart:async';
import 'dart:math' as math;

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../entities/athlete.dart';
import '../entities/force_data.dart';
import '../entities/test_result.dart';
import '../repositories/test_repository.dart';
import '../repositories/athlete_repository.dart';
import 'calculate_metrics.dart';

/// Test gerçekleştirme use case
/// Clean Architecture - Domain business logic
class PerformTestUseCase {
  final TestRepository _testRepository;
  final AthleteRepository _athleteRepository;
  final CalculateMetricsUseCase _calculateMetricsUseCase;

  PerformTestUseCase({
    required TestRepository testRepository,
    required AthleteRepository athleteRepository,
    required CalculateMetricsUseCase calculateMetricsUseCase,
  })  : _testRepository = testRepository,
        _athleteRepository = athleteRepository,
        _calculateMetricsUseCase = calculateMetricsUseCase;

  /// Test gerçekleştir ve sonuçları kaydet
  Future<TestExecutionResult> execute(TestExecutionParams params) async {
    try {
      AppLogger.testStart(params.testType.turkishName, params.athlete.fullName);
      
      // 1. Validation
      final validationResult = await _validateTestParams(params);
      if (!validationResult.isValid) {
        return TestExecutionResult.failure(
          error: TestExecutionError.validation,
          message: validationResult.errorMessage!,
        );
      }

      // 2. Pre-test setup
      final sessionId = _generateSessionId();
      final testStartTime = DateTime.now();

      // 3. Force data collection simulation
      final forceDataCollection = await _collectForceData(params, sessionId);
      
      if (forceDataCollection.isEmpty) {
        return TestExecutionResult.failure(
          error: TestExecutionError.dataCollection,
          message: 'Force data toplanamadı',
        );
      }

      // 4. Metrics calculation
      final metricsResult = await _calculateMetricsUseCase.execute(
        MetricsCalculationParams(
          forceData: forceDataCollection,
          testType: params.testType,
          athlete: params.athlete,
          bodyWeight: params.bodyWeight,
          sampleRate: params.sampleRate,
        ),
      );

      if (!metricsResult.isSuccess) {
        return TestExecutionResult.failure(
          error: TestExecutionError.metricsCalculation,
          message: 'Metrik hesaplama başarısız: ${metricsResult.errorMessage}',
        );
      }

      // 5. Test result creation
      final testDuration = DateTime.now().difference(testStartTime);
      final testResult = TestResult.create(
        sessionId: sessionId,
        athleteId: params.athlete.id,
        testType: params.testType,
        duration: testDuration,
        metrics: metricsResult.metrics!,
        metadata: {
          'sampleRate': params.sampleRate,
          'bodyWeight': params.bodyWeight,
          'platformConfiguration': params.platformConfiguration.name,
          'testProtocol': params.testProtocol?.name,
          'calibrationData': params.calibrationData,
        },
        notes: params.notes,
      );

      // 6. Quality assessment
      final qualityAssessment = _assessTestQuality(testResult, forceDataCollection);
      final finalTestResult = testResult.copyWith(
        metadata: {
          ...testResult.metadata ?? {},
          'qualityScore': qualityAssessment.score,
          'qualityReasons': qualityAssessment.reasons,
          'recommendedActions': qualityAssessment.recommendedActions,
        },
      );

      // 7. Save to repository
      await _testRepository.saveTestResult(finalTestResult);
      await _testRepository.saveForceDataBatch(sessionId, forceDataCollection.data);

      // 8. Update athlete statistics
      await _updateAthleteTestCount(params.athlete.id);

      AppLogger.testComplete(params.testType.turkishName, params.athlete.fullName, testDuration);

      return TestExecutionResult.success(
        testResult: finalTestResult,
        forceData: forceDataCollection,
        qualityAssessment: qualityAssessment,
        executionTime: testDuration,
      );

    } catch (e, stackTrace) {
      AppLogger.testError(params.testType.turkishName, e.toString());
      return TestExecutionResult.failure(
        error: TestExecutionError.unknown,
        message: 'Beklenmedik hata: $e',
      );
    }
  }

  /// Test parametrelerini doğrula
  Future<ValidationResult> _validateTestParams(TestExecutionParams params) async {
    final errors = <String>[];

    // Athlete validation
    if (!params.athlete.isValid) {
      errors.addAll(params.athlete.validationErrors);
    }

    // Body weight validation
    if (params.bodyWeight <= 0 || params.bodyWeight > 300) {
      errors.add('Geçersiz vücut ağırlığı: ${params.bodyWeight} kg');
    }

    // Sample rate validation
    if (params.sampleRate < 100 || params.sampleRate > 2000) {
      errors.add('Geçersiz örnekleme hızı: ${params.sampleRate} Hz');
    }

    // Test type specific validation
    final testSpecificErrors = _validateTestTypeSpecific(params);
    errors.addAll(testSpecificErrors);

    // Athlete last test check (minimum interval)
    final lastTestDate = await _testRepository.getAthleteLastTestDate(params.athlete.id);
    if (lastTestDate != null) {
      final timeSinceLastTest = DateTime.now().difference(lastTestDate);
      if (timeSinceLastTest.inMinutes < 5) {
        errors.add('Son testten en az 5 dakika beklemeniz gerekiyor');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errorMessage: errors.isNotEmpty ? errors.join('; ') : null,
    );
  }

  List<String> _validateTestTypeSpecific(TestExecutionParams params) {
    final errors = <String>[];

    switch (params.testType) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        // Jump test validations
        if (params.athlete.age != null && params.athlete.age! < 12) {
          errors.add('Sıçrama testleri 12 yaş altı için uygun değil');
        }
        break;

      case TestType.isometricMidThighPull:
        // IMTP validations
        if (params.bodyWeight < 40) {
          errors.add('IMTP testi minimum 40 kg vücut ağırlığı gerektirir');
        }
        break;

      case TestType.staticBalance:
      case TestType.singleLegBalance:
        // Balance test validations
        if (params.testProtocol?.duration != null && 
            params.testProtocol!.duration!.inSeconds > 60) {
          errors.add('Denge testleri maksimum 60 saniye olmalı');
        }
        break;

      default:
        break;
    }

    return errors;
  }

  /// Force data toplama simülasyonu
  Future<ForceDataCollection> _collectForceData(
    TestExecutionParams params,
    String sessionId,
  ) async {
    final forceData = <ForceData>[];
    final testDuration = params.testProtocol?.duration ?? 
        _getDefaultTestDuration(params.testType);
    
    final samples = (testDuration.inMilliseconds * params.sampleRate / 1000).round();
    final startTime = DateTime.now().millisecondsSinceEpoch;

    AppLogger.info('Force data toplama başladı: $samples sample');

    for (int i = 0; i < samples; i++) {
      final timestamp = startTime + (i * 1000 / params.sampleRate).round();
      final timeSeconds = i / params.sampleRate;
      
      final forceDataPoint = _generateTestSpecificForceData(
        params.testType,
        timestamp,
        timeSeconds,
        params.bodyWeight,
        params.athlete,
      );

      forceData.add(forceDataPoint);

      // Simulate real-time collection delay
      if (i % 100 == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    AppLogger.success('Force data toplama tamamlandı: ${forceData.length} sample');
    return ForceDataCollection(forceData);
  }

  ForceData _generateTestSpecificForceData(
    TestType testType,
    int timestamp,
    double timeSeconds,
    double bodyWeight,
    Athlete athlete,
  ) {
    final bodyWeightN = bodyWeight * 9.81; // Convert to Newtons

    switch (testType) {
      case TestType.counterMovementJump:
        return _generateCMJForceData(timestamp, timeSeconds, bodyWeightN, athlete);
      
      case TestType.squatJump:
        return _generateSJForceData(timestamp, timeSeconds, bodyWeightN, athlete);
      
      case TestType.dropJump:
        return _generateDJForceData(timestamp, timeSeconds, bodyWeightN, athlete);
      
      case TestType.isometricMidThighPull:
        return _generateIMTPForceData(timestamp, timeSeconds, bodyWeightN, athlete);
      
      case TestType.staticBalance:
        return _generateBalanceForceData(timestamp, timeSeconds, bodyWeightN, athlete);
      
      default:
        return _generateGenericForceData(timestamp, timeSeconds, bodyWeightN);
    }
  }

  ForceData _generateCMJForceData(int timestamp, double t, double bodyWeight, Athlete athlete) {
    // Realistic CMJ force curve
    double totalForce = bodyWeight;
    
    // Performance scaling based on athlete level
    final performanceMultiplier = _getPerformanceMultiplier(athlete);
    
    if (t < 1.0) {
      // Quiet standing
      totalForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 20;
    } else if (t < 1.8) {
      // Unloading phase
      final phase = (t - 1.0) / 0.8;
      totalForce = bodyWeight * (1.0 - 0.25 * phase) + 
                  (math.Random().nextDouble() - 0.5) * 30;
    } else if (t < 2.3) {
      // Braking phase
      final phase = (t - 1.8) / 0.5;
      final maxBraking = 1.8 * performanceMultiplier;
      totalForce = bodyWeight * (0.75 + maxBraking * phase) + 
                  (math.Random().nextDouble() - 0.5) * 50;
    } else if (t < 2.6) {
      // Propulsion phase
      final phase = (t - 2.3) / 0.3;
      final maxPropulsion = 2.5 * performanceMultiplier;
      totalForce = bodyWeight * (maxPropulsion - 0.5 * phase) + 
                  (math.Random().nextDouble() - 0.5) * 40;
    } else if (t < 3.0) {
      // Flight phase
      totalForce = (math.Random().nextDouble() - 0.5) * 15;
    } else if (t < 3.5) {
      // Landing phase
      final phase = (t - 3.0) / 0.5;
      final landingForce = 2.2 * performanceMultiplier;
      totalForce = bodyWeight * (0.3 + landingForce * (1 - phase)) + 
                  (math.Random().nextDouble() - 0.5) * 60;
    } else {
      // Recovery
      totalForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 25;
    }

    return _createForceDataWithAsymmetry(timestamp, totalForce, athlete);
  }

  ForceData _generateSJForceData(int timestamp, double t, double bodyWeight, Athlete athlete) {
    // Squat jump - no countermovement
    double totalForce = bodyWeight;
    final performanceMultiplier = _getPerformanceMultiplier(athlete);
    
    if (t < 1.0) {
      // Quiet standing
      totalForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 20;
    } else if (t < 1.5) {
      // Squat position hold
      totalForce = bodyWeight * 0.8 + (math.Random().nextDouble() - 0.5) * 30;
    } else if (t < 2.0) {
      // Propulsion phase
      final phase = (t - 1.5) / 0.5;
      final maxPropulsion = 2.8 * performanceMultiplier;
      totalForce = bodyWeight * (0.8 + maxPropulsion * phase) + 
                  (math.Random().nextDouble() - 0.5) * 50;
    } else if (t < 2.4) {
      // Flight phase
      totalForce = (math.Random().nextDouble() - 0.5) * 12;
    } else if (t < 3.0) {
      // Landing
      final phase = (t - 2.4) / 0.6;
      totalForce = bodyWeight * (0.4 + 2.0 * (1 - phase)) + 
                  (math.Random().nextDouble() - 0.5) * 70;
    } else {
      // Recovery
      totalForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 30;
    }

    return _createForceDataWithAsymmetry(timestamp, totalForce, athlete);
  }

  ForceData _generateDJForceData(int timestamp, double t, double bodyWeight, Athlete athlete) {
    // Drop jump - includes landing impact
    double totalForce = bodyWeight;
    final performanceMultiplier = _getPerformanceMultiplier(athlete);
    
    if (t < 0.5) {
      // Flight from drop
      totalForce = (math.Random().nextDouble() - 0.5) * 10;
    } else if (t < 0.8) {
      // Landing impact
      final phase = (t - 0.5) / 0.3;
      final impactForce = 3.5 * performanceMultiplier;
      totalForce = bodyWeight * (0.2 + impactForce * phase) + 
                  (math.Random().nextDouble() - 0.5) * 80;
    } else if (t < 1.0) {
      // Absorption
      final phase = (t - 0.8) / 0.2;
      totalForce = bodyWeight * (3.7 - 2.5 * phase) + 
                  (math.Random().nextDouble() - 0.5) * 60;
    } else if (t < 1.3) {
      // Propulsion
      final phase = (t - 1.0) / 0.3;
      final propulsionForce = 3.0 * performanceMultiplier;
      totalForce = bodyWeight * (1.2 + propulsionForce * phase) + 
                  (math.Random().nextDouble() - 0.5) * 50;
    } else if (t < 1.7) {
      // Second flight
      totalForce = (math.Random().nextDouble() - 0.5) * 15;
    } else {
      // Final landing
      totalForce = bodyWeight * (1.5 + math.Random().nextDouble()) + 
                  (math.Random().nextDouble() - 0.5) * 40;
    }

    return _createForceDataWithAsymmetry(timestamp, totalForce, athlete);
  }

  ForceData _generateIMTPForceData(int timestamp, double t, double bodyWeight, Athlete athlete) {
    // Isometric mid-thigh pull
    double totalForce = bodyWeight;
    final performanceMultiplier = _getPerformanceMultiplier(athlete);
    
    if (t < 1.0) {
      // Setup
      totalForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 30;
    } else if (t < 1.5) {
      // Force buildup
      final phase = (t - 1.0) / 0.5;
      final maxForce = bodyWeight * (2.5 * performanceMultiplier);
      totalForce = bodyWeight + maxForce * phase + 
                  (math.Random().nextDouble() - 0.5) * 50;
    } else if (t < 4.0) {
      // Peak force maintenance
      final maxForce = bodyWeight * (2.5 * performanceMultiplier);
      final fatigue = math.max(0.0, (t - 1.5) / 2.5 * 0.15); // 15% fatigue over time
      totalForce = bodyWeight + maxForce * (1.0 - fatigue) + 
                  (math.Random().nextDouble() - 0.5) * 40;
    } else {
      // Force decrease
      final phase = math.min(1.0, (t - 4.0) / 1.0);
      final maxForce = bodyWeight * (2.5 * performanceMultiplier);
      totalForce = bodyWeight + maxForce * (1.0 - phase) + 
                  (math.Random().nextDouble() - 0.5) * 35;
    }

    return _createForceDataWithAsymmetry(timestamp, totalForce, athlete);
  }

  ForceData _generateBalanceForceData(int timestamp, double t, double bodyWeight, Athlete athlete) {
    // Static balance - subtle weight shifts
    final baseForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 30;
    
    // Add natural sway patterns
    final swayX = math.sin(t * 0.8) * 15 + math.sin(t * 2.3) * 8;
    final swayY = math.cos(t * 1.1) * 12 + math.cos(t * 1.9) * 6;
    
    // Asymmetry based on balance ability
    final balanceSkill = _getBalanceSkill(athlete);
    final asymmetry = (0.02 + math.Random().nextDouble() * 0.03) / balanceSkill;
    
    return ForceData.create(
      timestamp: timestamp,
      leftGRF: baseForce * (0.5 + asymmetry / 2),
      rightGRF: baseForce * (0.5 - asymmetry / 2),
      leftCOP_x: swayX + (math.Random().nextDouble() - 0.5) * 8,
      leftCOP_y: swayY + (math.Random().nextDouble() - 0.5) * 10,
      rightCOP_x: swayX + (math.Random().nextDouble() - 0.5) * 8,
      rightCOP_y: swayY + (math.Random().nextDouble() - 0.5) * 10,
    );
  }

  ForceData _generateGenericForceData(int timestamp, double t, double bodyWeight) {
    final totalForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 50;
    final asymmetry = 0.05 + math.Random().nextDouble() * 0.10;
    
    return ForceData.create(
      timestamp: timestamp,
      leftGRF: totalForce * (0.5 + asymmetry / 2),
      rightGRF: totalForce * (0.5 - asymmetry / 2),
      leftCOP_x: (math.Random().nextDouble() - 0.5) * 60,
      leftCOP_y: (math.Random().nextDouble() - 0.5) * 80,
      rightCOP_x: (math.Random().nextDouble() - 0.5) * 60,
      rightCOP_y: (math.Random().nextDouble() - 0.5) * 80,
    );
  }

  ForceData _createForceDataWithAsymmetry(int timestamp, double totalForce, Athlete athlete) {
    // Realistic asymmetry based on athlete characteristics
    final baseAsymmetry = _getBaseAsymmetry(athlete);
    final currentAsymmetry = baseAsymmetry + (math.Random().nextDouble() - 0.5) * 0.02;
    
    final leftGRF = math.max(0, totalForce * (0.5 + currentAsymmetry / 2));
    final rightGRF = math.max(0, totalForce * (0.5 - currentAsymmetry / 2));
    
    return ForceData.create(
      timestamp: timestamp,
      leftGRF: leftGRF,
      rightGRF: rightGRF,
      leftCOP_x: (math.Random().nextDouble() - 0.5) * 80,
      leftCOP_y: (math.Random().nextDouble() - 0.5) * 100,
      rightCOP_x: (math.Random().nextDouble() - 0.5) * 80,
      rightCOP_y: (math.Random().nextDouble() - 0.5) * 100,
    );
  }

  double _getPerformanceMultiplier(Athlete athlete) {
    switch (athlete.level) {
      case AthleteLevel.recreational:
        return 0.8;
      case AthleteLevel.amateur:
        return 0.9;
      case AthleteLevel.semipro:
        return 1.0;
      case AthleteLevel.professional:
        return 1.15;
      case AthleteLevel.elite:
        return 1.3;
      default:
        return 1.0;
    }
  }

  double _getBaseAsymmetry(Athlete athlete) {
    // Lower asymmetry for higher level athletes
    switch (athlete.level) {
      case AthleteLevel.recreational:
        return 0.08; // 8%
      case AthleteLevel.amateur:
        return 0.06; // 6%
      case AthleteLevel.semipro:
        return 0.05; // 5%
      case AthleteLevel.professional:
        return 0.04; // 4%
      case AthleteLevel.elite:
        return 0.03; // 3%
      default:
        return 0.06;
    }
  }

  double _getBalanceSkill(Athlete athlete) {
    // Balance skill multiplier
    switch (athlete.level) {
      case AthleteLevel.recreational:
        return 0.7;
      case AthleteLevel.amateur:
        return 0.85;
      case AthleteLevel.semipro:
        return 1.0;
      case AthleteLevel.professional:
        return 1.2;
      case AthleteLevel.elite:
        return 1.4;
      default:
        return 1.0;
    }
  }

  Duration _getDefaultTestDuration(TestType testType) {
    switch (testType) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        return const Duration(seconds: 5);
      case TestType.isometricMidThighPull:
        return const Duration(seconds: 6);
      case TestType.staticBalance:
        return const Duration(seconds: 30);
      case TestType.singleLegBalance:
        return const Duration(seconds: 20);
      default:
        return const Duration(seconds: 10);
    }
  }

  TestQualityAssessment _assessTestQuality(
    TestResult testResult,
    ForceDataCollection forceData,
  ) {
    final reasons = <String>[];
    final recommendedActions = <String>[];
    double score = 100.0;

    // Duration assessment
    final expectedDuration = _getDefaultTestDuration(testResult.testType);
    final durationRatio = testResult.duration.inMilliseconds / expectedDuration.inMilliseconds;
    
    if (durationRatio < 0.5) {
      score -= 20;
      reasons.add('Test çok kısa sürdü');
      recommendedActions.add('Test süresini artırın');
    } else if (durationRatio > 2.0) {
      score -= 15;
      reasons.add('Test çok uzun sürdü');
      recommendedActions.add('Test süresini kısaltın');
    }

    // Force data quality
    if (forceData.length < 100) {
      score -= 25;
      reasons.add('Yetersiz veri noktası');
      recommendedActions.add('Örnekleme hızını artırın');
    }

    // Asymmetry assessment
    final asymmetry = testResult.metrics['asymmetryIndex'] ?? 0.0;
    if (asymmetry > 20) {
      score -= 15;
      reasons.add('Çok yüksek asimetri');
      recommendedActions.add('Bilateral değerlendirme yapın');
    } else if (asymmetry > 10) {
      score -= 5;
      reasons.add('Orta seviye asimetri');
    }

    // Test type specific assessments
    score -= _assessTestTypeSpecificQuality(testResult, reasons, recommendedActions);

    // Signal quality (coefficient of variation)
    final forceCV = _calculateForceCV(forceData);
    if (forceCV > 0.15) {
      score -= 10;
      reasons.add('Yüksek sinyal değişkenliği');
      recommendedActions.add('Ölçüm ortamını iyileştirin');
    }

    return TestQualityAssessment(
      score: score.clamp(0.0, 100.0),
      reasons: reasons,
      recommendedActions: recommendedActions,
    );
  }

  double _assessTestTypeSpecificQuality(
    TestResult testResult,
    List<String> reasons,
    List<String> recommendedActions,
  ) {
    double deduction = 0.0;

    switch (testResult.testType) {
      case TestType.counterMovementJump:
        final jumpHeight = testResult.metrics['jumpHeight'] ?? 0.0;
        final flightTime = testResult.metrics['flightTime'] ?? 0.0;
        
        if (jumpHeight < 10) {
          deduction += 10;
          reasons.add('Düşük sıçrama yüksekliği');
          recommendedActions.add('Teknik analiz yapın');
        }
        
        if (flightTime < 200) {
          deduction += 5;
          reasons.add('Kısa uçuş süresi');
        }
        break;

      case TestType.staticBalance:
        final copRange = testResult.metrics['copRange'] ?? 0.0;
        if (copRange > 50) {
          deduction += 10;
          reasons.add('Aşırı postural sallanma');
          recommendedActions.add('Denge antrenmanı önerilen');
        }
        break;

      default:
        break;
    }

    return deduction;
  }

  double _calculateForceCV(ForceDataCollection forceData) {
    if (forceData.isEmpty) return 0.0;
    
    final forces = forceData.data.map((d) => d.totalGRF).toList();
    final mean = forces.reduce((a, b) => a + b) / forces.length;
    
    if (mean == 0) return 0.0;
    
    final variance = forces.map((f) => (f - mean) * (f - mean)).reduce((a, b) => a + b) / forces.length;
    final stdDev = math.sqrt(variance);
    
    return stdDev / mean;
  }

  Future<void> _updateAthleteTestCount(String athleteId) async {
    try {
      // This could update athlete's last test date, test count, etc.
      // For now, just log the activity
      AppLogger.info('Sporcu test sayısı güncellendi: $athleteId');
    } catch (e) {
      AppLogger.warning('Sporcu test sayısı güncellenemedi: $e');
    }
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }
}

/// Test execution parameters
class TestExecutionParams {
  final Athlete athlete;
  final TestType testType;
  final double bodyWeight; // kg
  final int sampleRate; // Hz
  final PlatformConfiguration platformConfiguration;
  final TestProtocol? testProtocol;
  final Map<String, dynamic>? calibrationData;
  final String? notes;

  const TestExecutionParams({
    required this.athlete,
    required this.testType,
    required this.bodyWeight,
    this.sampleRate = 1000,
    this.platformConfiguration = PlatformConfiguration.dual,
    this.testProtocol,
    this.calibrationData,
    this.notes,
  });
}

/// Platform configuration
enum PlatformConfiguration {
  single,
  dual,
  quad,
}

/// Test protocol
class TestProtocol {
  final String name;
  final Duration? duration;
  final Map<String, dynamic> parameters;

  const TestProtocol({
    required this.name,
    this.duration,
    this.parameters = const {},
  });
}

/// Test execution result
class TestExecutionResult {
  final bool isSuccess;
  final TestResult? testResult;
  final ForceDataCollection? forceData;
  final TestQualityAssessment? qualityAssessment;
  final Duration? executionTime;
  final TestExecutionError? error;
  final String? message;

  const TestExecutionResult._({
    required this.isSuccess,
    this.testResult,
    this.forceData,
    this.qualityAssessment,
    this.executionTime,
    this.error,
    this.message,
  });

  factory TestExecutionResult.success({
    required TestResult testResult,
    required ForceDataCollection forceData,
    required TestQualityAssessment qualityAssessment,
    required Duration executionTime,
  }) {
    return TestExecutionResult._(
      isSuccess: true,
      testResult: testResult,
      forceData: forceData,
      qualityAssessment: qualityAssessment,
      executionTime: executionTime,
    );
  }

  factory TestExecutionResult.failure({
    required TestExecutionError error,
    required String message,
  }) {
    return TestExecutionResult._(
      isSuccess: false,
      error: error,
      message: message,
    );
  }
}

/// Test execution errors
enum TestExecutionError {
  validation,
  dataCollection,
  metricsCalculation,
  saveError,
  unknown,
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

/// Test quality assessment
class TestQualityAssessment {
  final double score; // 0-100
  final List<String> reasons;
  final List<String> recommendedActions;

  const TestQualityAssessment({
    required this.score,
    required this.reasons,
    required this.recommendedActions,
  });

  TestQuality get quality {
    if (score >= 90) return TestQuality.excellent;
    if (score >= 75) return TestQuality.good;
    if (score >= 60) return TestQuality.fair;
    if (score >= 40) return TestQuality.poor;
    return TestQuality.invalid;
  }
}