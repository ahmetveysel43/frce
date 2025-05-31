import 'dart:math' as math;

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../entities/athlete.dart';
import '../entities/force_data.dart';

/// Metrik hesaplama use case
/// Clean Architecture - Domain business logic
class CalculateMetricsUseCase {
  
  /// Metrikleri hesapla
  Future<MetricsCalculationResult> execute(MetricsCalculationParams params) async {
    try {
      AppLogger.info('🧮 Metrik hesaplama başladı: ${params.testType.turkishName}');
      
      // Validation
      if (params.forceData.isEmpty) {
        return MetricsCalculationResult.failure('Force data boş');
      }

      if (params.bodyWeight <= 0) {
        return MetricsCalculationResult.failure('Geçersiz vücut ağırlığı');
      }

      // Calculate metrics based on test type
      final metrics = <String, double>{};
      
      // Common metrics for all test types
      metrics.addAll(await _calculateCommonMetrics(params));
      
      // Test type specific metrics
      switch (params.testType) {
        case TestType.counterMovementJump:
          metrics.addAll(await _calculateCMJMetrics(params));
          break;
        case TestType.squatJump:
          metrics.addAll(await _calculateSJMetrics(params));
          break;
        case TestType.dropJump:
          metrics.addAll(await _calculateDJMetrics(params));
          break;
        case TestType.isometricMidThighPull:
          metrics.addAll(await _calculateIMTPMetrics(params));
          break;
        case TestType.staticBalance:
        case TestType.singleLegBalance:
        case TestType.dynamicBalance:
          metrics.addAll(await _calculateBalanceMetrics(params));
          break;
        default:
          metrics.addAll(await _calculateGenericMetrics(params));
      }

      AppLogger.metricsCalculated(params.testType.turkishName, metrics.length);
      
      return MetricsCalculationResult.success(
        metrics: metrics,
        calculationTime: DateTime.now().difference(DateTime.now()), // Will be updated
      );

    } catch (e, stackTrace) {
      AppLogger.metricsError(e.toString());
      return MetricsCalculationResult.failure('Metrik hesaplama hatası: $e');
    }
  }

  /// Tüm test türleri için ortak metrikler
  Future<Map<String, double>> _calculateCommonMetrics(MetricsCalculationParams params) async {
    final data = params.forceData;
    final bodyWeightN = params.bodyWeight * 9.81; // Convert to Newtons
    
    return {
      // Basic force metrics
      'peakForce': data.peakTotalGRF,
      'averageForce': data.avgTotalGRF,
      'peakForceLeft': data.peakLeftGRF,
      'peakForceRight': data.peakRightGRF,
      'averageForceLeft': data.avgLeftGRF,
      'averageForceRight': data.avgRightGRF,
      
      // Asymmetry
      'asymmetryIndex': data.overallAsymmetry,
      'leftLoadPercentage': _calculateLeftLoadPercentage(data),
      'rightLoadPercentage': _calculateRightLoadPercentage(data),
      
      // Relative metrics
      'peakForceRelativeBW': data.peakTotalGRF / bodyWeightN,
      'averageForceRelativeBW': data.avgTotalGRF / bodyWeightN,
      
      // Time metrics
      'sampleCount': data.length.toDouble(),
      'sampleRate': data.sampleRate,
      'testDuration': data.duration.inMilliseconds.toDouble(),
      
      // Body weight reference
      'bodyWeightN': bodyWeightN,
      'bodyWeightKg': params.bodyWeight,
    };
  }

  /// Counter Movement Jump metrikleri
  Future<Map<String, double>> _calculateCMJMetrics(MetricsCalculationParams params) async {
    final data = params.forceData;
    final bodyWeightN = params.bodyWeight * 9.81;
    
    // Phase detection
    final phases = _detectJumpPhases(data, bodyWeightN);
    
    // Jump height calculation
    final jumpHeight = _calculateJumpHeightImpulse(data, bodyWeightN, phases);
    
    // Flight time calculation
    final flightTime = _calculateFlightTime(data, bodyWeightN);
    
    // Contact time
    final contactTime = _calculateContactTime(data, bodyWeightN);
    
    // Takeoff velocity
    final takeoffVelocity = _calculateTakeoffVelocity(jumpHeight);
    
    // Rate of Force Development (RFD)
    final rfd = _calculateRFD(data, phases);
    
    // Impulse calculations
    final impulses = _calculateImpulses(data, bodyWeightN, phases);
    
    // Power calculations
    final powerMetrics = _calculatePowerMetrics(data, bodyWeightN, params.athlete);
    
    return {
      // Primary jump metrics
      'jumpHeight': jumpHeight,
      'flightTime': flightTime,
      'contactTime': contactTime,
      'takeoffVelocity': takeoffVelocity,
      
      // Phase durations (ms)
      'quietStandingDuration': phases['quietStanding']?.duration.inMilliseconds.toDouble() ?? 0.0,
      'unloadingDuration': phases['unloading']?.duration.inMilliseconds.toDouble() ?? 0.0,
      'brakingDuration': phases['braking']?.duration.inMilliseconds.toDouble() ?? 0.0,
      'propulsionDuration': phases['propulsion']?.duration.inMilliseconds.toDouble() ?? 0.0,
      
      // RFD metrics
      'rfd': rfd['rfd'] ?? 0.0,
      'rfd50': rfd['rfd50'] ?? 0.0,
      'rfd100': rfd['rfd100'] ?? 0.0,
      'rfd200': rfd['rfd200'] ?? 0.0,
      'timeToTakeoff': rfd['timeToTakeoff'] ?? 0.0,
      
      // Impulse metrics
      'netImpulse': impulses['net'] ?? 0.0,
      'brakingImpulse': impulses['braking'] ?? 0.0,
      'propulsionImpulse': impulses['propulsion'] ?? 0.0,
      
      // Power metrics
      'peakPower': powerMetrics['peak'] ?? 0.0,
      'averagePower': powerMetrics['average'] ?? 0.0,
      'relativePeakPower': powerMetrics['relativePeak'] ?? 0.0,
      'relativeAveragePower': powerMetrics['relativeAverage'] ?? 0.0,
      
      // CMJ specific
      'eccentricPeakForce': _getPhaseMaxForce(data, phases['braking']),
      'concentricPeakForce': _getPhaseMaxForce(data, phases['propulsion']),
      'eccentricRate': _getPhaseForceRate(data, phases['braking'], bodyWeightN),
      'concentricRate': _getPhaseForceRate(data, phases['propulsion'], bodyWeightN),
    };
  }

  /// Squat Jump metrikleri
  Future<Map<String, double>> _calculateSJMetrics(MetricsCalculationParams params) async {
    final data = params.forceData;
    final bodyWeightN = params.bodyWeight * 9.81;
    
    // SJ has no eccentric phase
    final phases = _detectSJPhases(data, bodyWeightN);
    
    // Similar calculations to CMJ but without eccentric phase
    final jumpHeight = _calculateJumpHeightImpulse(data, bodyWeightN, phases);
    final flightTime = _calculateFlightTime(data, bodyWeightN);
    final contactTime = _calculateContactTime(data, bodyWeightN);
    final takeoffVelocity = _calculateTakeoffVelocity(jumpHeight);
    final rfd = _calculateRFD(data, phases);
    final impulses = _calculateImpulses(data, bodyWeightN, phases);
    final powerMetrics = _calculatePowerMetrics(data, bodyWeightN, params.athlete);
    
    return {
      'jumpHeight': jumpHeight,
      'flightTime': flightTime,
      'contactTime': contactTime,
      'takeoffVelocity': takeoffVelocity,
      
      // SJ specific phases
      'squatHoldDuration': phases['squatHold']?.duration.inMilliseconds.toDouble() ?? 0.0,
      'propulsionDuration': phases['propulsion']?.duration.inMilliseconds.toDouble() ?? 0.0,
      
      // RFD metrics
      'rfd': rfd['rfd'] ?? 0.0,
      'rfd50': rfd['rfd50'] ?? 0.0,
      'rfd100': rfd['rfd100'] ?? 0.0,
      'timeToTakeoff': rfd['timeToTakeoff'] ?? 0.0,
      
      // Impulse
      'netImpulse': impulses['net'] ?? 0.0,
      'propulsionImpulse': impulses['propulsion'] ?? 0.0,
      
      // Power
      'peakPower': powerMetrics['peak'] ?? 0.0,
      'averagePower': powerMetrics['average'] ?? 0.0,
      'relativePeakPower': powerMetrics['relativePeak'] ?? 0.0,
    };
  }

  /// Drop Jump metrikleri
  Future<Map<String, double>> _calculateDJMetrics(MetricsCalculationParams params) async {
    final data = params.forceData;
    final bodyWeightN = params.bodyWeight * 9.81;
    
    final phases = _detectDJPhases(data, bodyWeightN);
    
    // DJ specific calculations
    final jumpHeight = _calculateJumpHeightImpulse(data, bodyWeightN, phases);
    final groundContactTime = _calculateGroundContactTime(data, phases);
    final reactiveStrengthIndex = _calculateReactiveStrengthIndex(jumpHeight, groundContactTime);
    
    return {
      'jumpHeight': jumpHeight,
      'groundContactTime': groundContactTime,
      'reactiveStrengthIndex': reactiveStrengthIndex,
      
      // Landing metrics
      'landingPeakForce': _getPhaseMaxForce(data, phases['landing']),
      'landingRate': _getPhaseForceRate(data, phases['landing'], bodyWeightN),
      'landingImpulse': _getPhaseImpulse(data, phases['landing'], bodyWeightN),
      
      // Takeoff metrics
      'takeoffPeakForce': _getPhaseMaxForce(data, phases['takeoff']),
      'takeoffRate': _getPhaseForceRate(data, phases['takeoff'], bodyWeightN),
      'takeoffImpulse': _getPhaseImpulse(data, phases['takeoff'], bodyWeightN),
      
      // DJ efficiency
      'djEfficiency': jumpHeight / groundContactTime, // Height per contact time
    };
  }

  /// Isometric Mid-Thigh Pull metrikleri
  Future<Map<String, double>> _calculateIMTPMetrics(MetricsCalculationParams params) async {
    final data = params.forceData;
    final bodyWeightN = params.bodyWeight * 9.81;
    
    // IMTP specific analysis
    final forceOnset = _detectForceOnset(data, bodyWeightN);
    final peakForce = data.peakTotalGRF;
    final timeToPeak = _calculateTimeToPeakForce(data, forceOnset);
    
    // RFD calculations at different time intervals
    final rfdMetrics = _calculateIMTPRFD(data, forceOnset);
    
    // Force at specific time points
    final forceAtTimes = _calculateForceAtTimePoints(data, forceOnset);
    
    // Impulse calculations
    final impulse = _calculateIMTPImpulse(data, bodyWeightN, forceOnset);
    
    return {
      'peakForce': peakForce,
      'peakForceRelative': peakForce / bodyWeightN,
      'timeToPeakForce': timeToPeak, // ✅ FIXED: Added comma
      'forceOnsetTime': forceOnset.toDouble(),
      
      // RFD at different time intervals
      'rfd0_50': rfdMetrics['rfd0_50'] ?? 0.0,
      'rfd0_100': rfdMetrics['rfd0_100'] ?? 0.0,
      'rfd0_150': rfdMetrics['rfd0_150'] ?? 0.0,
      'rfd0_200': rfdMetrics['rfd0_200'] ?? 0.0,
      'rfd0_250': rfdMetrics['rfd0_250'] ?? 0.0,
      
      // Force at specific time points
      'force50': forceAtTimes['f50'] ?? 0.0,
      'force100': forceAtTimes['f100'] ?? 0.0,
      'force150': forceAtTimes['f150'] ?? 0.0,
      'force200': forceAtTimes['f200'] ?? 0.0,
      'force250': forceAtTimes['f250'] ?? 0.0,
      
      // Impulse metrics
      'impulse0_100': impulse['i0_100'] ?? 0.0,
      'impulse0_200': impulse['i0_200'] ?? 0.0,
      'impulse0_300': impulse['i0_300'] ?? 0.0,
      
      // IMTP specific
      'maxRFD': rfdMetrics['maxRFD'] ?? 0.0,
      'timeToMaxRFD': rfdMetrics['timeToMaxRFD'] ?? 0.0,
    };
  }

  /// Denge test metrikleri
  Future<Map<String, double>> _calculateBalanceMetrics(MetricsCalculationParams params) async {
    final data = params.forceData;
    
    // Center of Pressure calculations
    final copMetrics = _calculateCOPMetrics(data);
    
    // Sway metrics
    final swayMetrics = _calculateSwayMetrics(data);
    
    // Stability indices
    final stabilityMetrics = _calculateStabilityMetrics(data);
    
    return {
      // COP metrics
      'copRangeX': copMetrics['rangeX'] ?? 0.0,
      'copRangeY': copMetrics['rangeY'] ?? 0.0,
      'copRange': copMetrics['range'] ?? 0.0,
      'copArea': copMetrics['area'] ?? 0.0,
      'copPathLength': copMetrics['pathLength'] ?? 0.0,
      'copVelocity': copMetrics['velocity'] ?? 0.0,
      
      // Sway metrics
      'swayVelocityX': swayMetrics['velocityX'] ?? 0.0,
      'swayVelocityY': swayMetrics['velocityY'] ?? 0.0,
      'swayArea95': swayMetrics['area95'] ?? 0.0,
      'swayFrequency': swayMetrics['frequency'] ?? 0.0,
      
      // Stability indices
      'stabilityIndex': stabilityMetrics['overall'] ?? 0.0,
      'anteriorPosteriorIndex': stabilityMetrics['ap'] ?? 0.0,
      'medialLateralIndex': stabilityMetrics['ml'] ?? 0.0,
    };
  }

  /// Genel metrikler (diğer test türleri için)
  Future<Map<String, double>> _calculateGenericMetrics(MetricsCalculationParams params) async {
    final data = params.forceData;
    final bodyWeightN = params.bodyWeight * 9.81;
    
    // Basic statistical metrics
    final forceValues = data.data.map((d) => d.totalGRF).toList();
    final stats = _calculateStatistics(forceValues);
    
    return {
      'mean': stats['mean'] ?? 0.0,
      'median': stats['median'] ?? 0.0,
      'standardDeviation': stats['std'] ?? 0.0,
      'coefficientOfVariation': stats['cv'] ?? 0.0,
      'range': stats['range'] ?? 0.0,
      'skewness': stats['skewness'] ?? 0.0,
      'kurtosis': stats['kurtosis'] ?? 0.0,
    };
  }

  // Helper methods for calculations

  Map<String, PhaseInfo?> _detectJumpPhases(ForceDataCollection data, double bodyWeightN) {
    // Simplified phase detection algorithm
    final threshold = bodyWeightN * 0.05; // 5% of body weight
    final forces = data.data.map((d) => d.totalGRF).toList();
    
    // Find quiet standing (first stable period)
    int quietStart = 0;
    int quietEnd = 0;
    for (int i = 100; i < forces.length - 100; i++) {
      final window = forces.sublist(i - 50, i + 50);
      final variance = _calculateVariance(window);
      if (variance < threshold) {
        quietEnd = i;
        break;
      }
    }

    // Find unloading (force below body weight)
    int unloadingStart = quietEnd;
    int unloadingEnd = quietEnd;
    for (int i = quietEnd; i < forces.length; i++) {
      if (forces[i] < bodyWeightN * 0.9) {
        unloadingStart = i;
        break;
      }
    }
    for (int i = unloadingStart; i < forces.length; i++) {
      if (forces[i] > bodyWeightN * 0.9) {
        unloadingEnd = i;
        break;
      }
    }

    // Continue with braking and propulsion detection...
    // Simplified for brevity

    return {
      'quietStanding': PhaseInfo(quietStart, quietEnd, data.data),
      'unloading': PhaseInfo(unloadingStart, unloadingEnd, data.data),
      'braking': null, // Implement full detection
      'propulsion': null, // Implement full detection
    };
  }

  Map<String, PhaseInfo?> _detectSJPhases(ForceDataCollection data, double bodyWeightN) {
    // SJ phase detection (no eccentric phase)
    return <String, PhaseInfo?>{};
  }

  Map<String, PhaseInfo?> _detectDJPhases(ForceDataCollection data, double bodyWeightN) {
    // Drop jump phase detection
    return <String, PhaseInfo?>{};
  }

  double _calculateJumpHeightImpulse(ForceDataCollection data, double bodyWeightN, Map<String, PhaseInfo?> phases) {
    // Jump height calculation using impulse-momentum theorem
    // Simplified calculation
    final netImpulse = _calculateNetImpulse(data, bodyWeightN);
    final mass = bodyWeightN / 9.81;
    final velocity = netImpulse / mass;
    return (velocity * velocity) / (2 * 9.81) * 100; // Convert to cm
  }

  double _calculateNetImpulse(ForceDataCollection data, double bodyWeightN) {
    double impulse = 0.0;
    final dt = 1.0 / data.sampleRate; // Time step in seconds
    
    for (final point in data.data) {
      impulse += (point.totalGRF - bodyWeightN) * dt;
    }
    
    return impulse;
  }

  double _calculateFlightTime(ForceDataCollection data, double bodyWeightN) {
    // Flight time detection (force below threshold)
    final threshold = bodyWeightN * 0.1;
    int flightSamples = 0;
    
    for (final point in data.data) {
      if (point.totalGRF < threshold) {
        flightSamples++;
      }
    }
    
    return flightSamples / data.sampleRate * 1000; // Convert to ms
  }

  double _calculateContactTime(ForceDataCollection data, double bodyWeightN) {
    // Contact time (force above threshold)
    final threshold = bodyWeightN * 0.1;
    int contactSamples = 0;
    
    for (final point in data.data) {
      if (point.totalGRF > threshold) {
        contactSamples++;
      }
    }
    
    return contactSamples / data.sampleRate * 1000; // Convert to ms
  }

  double _calculateTakeoffVelocity(double jumpHeight) {
    // v = sqrt(2 * g * h)
    return math.sqrt(2 * 9.81 * jumpHeight / 100); // Convert cm to m
  }

  Map<String, double> _calculateRFD(ForceDataCollection data, Map<String, PhaseInfo?> phases) {
    // Rate of Force Development calculations
    final forces = data.data.map((d) => d.totalGRF).toList();
    final dt = 1.0 / data.sampleRate;
    
    // Calculate force derivative
    final rfdValues = <double>[];
    for (int i = 1; i < forces.length; i++) {
      rfdValues.add((forces[i] - forces[i - 1]) / dt);
    }
    
    return {
      'rfd': rfdValues.isEmpty ? 0.0 : rfdValues.reduce(math.max),
      'rfd50': 0.0, // Calculate RFD at 50ms
      'rfd100': 0.0, // Calculate RFD at 100ms
      'rfd200': 0.0, // Calculate RFD at 200ms
      'timeToTakeoff': 0.0,
    };
  }

  Map<String, double> _calculateImpulses(ForceDataCollection data, double bodyWeightN, Map<String, PhaseInfo?> phases) {
    // Impulse calculations for different phases
    return {
      'net': _calculateNetImpulse(data, bodyWeightN),
      'braking': 0.0, // Calculate braking impulse
      'propulsion': 0.0, // Calculate propulsion impulse
    };
  }

  Map<String, double> _calculatePowerMetrics(ForceDataCollection data, double bodyWeightN, Athlete athlete) {
    // Power calculations (P = F * v)
    // Simplified calculation
    final mass = bodyWeightN / 9.81;
    final peakForce = data.peakTotalGRF;
    final estimatedVelocity = 2.0; // Simplified
    
    return {
      'peak': peakForce * estimatedVelocity,
      'average': data.avgTotalGRF * estimatedVelocity * 0.7,
      'relativePeak': (peakForce * estimatedVelocity) / mass,
      'relativeAverage': (data.avgTotalGRF * estimatedVelocity * 0.7) / mass,
    };
  }

  double _getPhaseMaxForce(ForceDataCollection data, PhaseInfo? phase) {
    if (phase == null) return 0.0;
    
    final phaseForces = phase.getData().map((d) => d.totalGRF);
    return phaseForces.isEmpty ? 0.0 : phaseForces.reduce(math.max);
  }

  double _getPhaseForceRate(ForceDataCollection data, PhaseInfo? phase, double bodyWeightN) {
    if (phase == null) return 0.0;
    
    final phaseData = phase.getData();
    if (phaseData.length < 2) return 0.0;
    
    final startForce = phaseData.first.totalGRF;
    final endForce = phaseData.last.totalGRF;
    final duration = phase.duration.inMilliseconds / 1000.0; // Convert to seconds
    
    return duration > 0 ? (endForce - startForce) / duration : 0.0;
  }

  double _getPhaseImpulse(ForceDataCollection data, PhaseInfo? phase, double bodyWeightN) {
    if (phase == null) return 0.0;
    
    final phaseData = phase.getData();
    double impulse = 0.0;
    final dt = 1.0 / data.sampleRate;
    
    for (final point in phaseData) {
      impulse += (point.totalGRF - bodyWeightN) * dt;
    }
    
    return impulse;
  }

  double _calculateLeftLoadPercentage(ForceDataCollection data) {
    if (data.isEmpty) return 50.0;
    
    double totalLeft = 0.0;
    double totalBoth = 0.0;
    
    for (final point in data.data) {
      totalLeft += point.leftGRF;
      totalBoth += point.totalGRF;
    }
    
    return totalBoth > 0 ? (totalLeft / totalBoth) * 100 : 50.0;
  }

  double _calculateRightLoadPercentage(ForceDataCollection data) {
    return 100.0 - _calculateLeftLoadPercentage(data);
  }

  double _calculateGroundContactTime(ForceDataCollection data, Map<String, PhaseInfo?> phases) {
    // Ground contact time for drop jump
    return 200.0; // Simplified
  }

  double _calculateReactiveStrengthIndex(double jumpHeight, double contactTime) {
    // RSI = Jump Height / Ground Contact Time
    return contactTime > 0 ? jumpHeight / (contactTime / 1000) : 0.0;
  }

  int _detectForceOnset(ForceDataCollection data, double bodyWeightN) {
    // Detect when force starts to increase above baseline
    final threshold = bodyWeightN * 1.05; // 5% above body weight
    
    for (int i = 0; i < data.length; i++) {
      if (data.data[i].totalGRF > threshold) {
        return i;
      }
    }
    
    return 0;
  }

  double _calculateTimeToPeakForce(ForceDataCollection data, int onsetIndex) {
    final peakForce = data.peakTotalGRF;
    
    for (int i = onsetIndex; i < data.length; i++) {
      if (data.data[i].totalGRF >= peakForce * 0.95) { // Within 95% of peak
        return (i - onsetIndex) / data.sampleRate * 1000; // Convert to ms
      }
    }
    
    return 0.0;
  }

  Map<String, double> _calculateIMTPRFD(ForceDataCollection data, int onsetIndex) {
    // IMTP specific RFD calculations
    return {
      'rfd0_50': 0.0,
      'rfd0_100': 0.0,
      'rfd0_150': 0.0,
      'rfd0_200': 0.0,
      'rfd0_250': 0.0,
      'maxRFD': 0.0,
      'timeToMaxRFD': 0.0,
    };
  }

  Map<String, double> _calculateForceAtTimePoints(ForceDataCollection data, int onsetIndex) {
    // Force values at specific time points
    return {
      'f50': 0.0,
      'f100': 0.0,
      'f150': 0.0,
      'f200': 0.0,
      'f250': 0.0,
    };
  }

  Map<String, double> _calculateIMTPImpulse(ForceDataCollection data, double bodyWeightN, int onsetIndex) {
    // Impulse calculations for IMTP
    return {
      'i0_100': 0.0,
      'i0_200': 0.0,
      'i0_300': 0.0,
    };
  }

  Map<String, double> _calculateCOPMetrics(ForceDataCollection data) {
    // Center of Pressure calculations
    final copData = data.data
        .map((d) => d.combinedCOP)
        .where((cop) => cop != null)
        .map((cop) => cop!)
        .toList();
    
    if (copData.isEmpty) return <String, double>{};
    
    final xValues = copData.map((cop) => cop.x).toList();
    final yValues = copData.map((cop) => cop.y).toList();
    
    return {
      'rangeX': xValues.reduce(math.max) - xValues.reduce(math.min),
      'rangeY': yValues.reduce(math.max) - yValues.reduce(math.min),
      'range': 0.0, // Overall range
      'area': 0.0, // COP area
      'pathLength': 0.0, // Total path length
      'velocity': 0.0, // Average velocity
    };
  }

  Map<String, double> _calculateSwayMetrics(ForceDataCollection data) {
    // Sway analysis metrics
    final copData = data.data
        .map((d) => d.combinedCOP)
        .where((cop) => cop != null)
        .map((cop) => cop!)
        .toList();
    
    if (copData.isEmpty) return <String, double>{};
    
    // Calculate sway velocity
    double totalVelocityX = 0.0;
    double totalVelocityY = 0.0;
    final dt = 1.0 / data.sampleRate;
    
    for (int i = 1; i < copData.length; i++) {
      final dx = copData[i].x - copData[i - 1].x;
      final dy = copData[i].y - copData[i - 1].y;
      totalVelocityX += dx.abs() / dt;
      totalVelocityY += dy.abs() / dt;
    }
    
    return {
      'velocityX': copData.length > 1 ? totalVelocityX / (copData.length - 1) : 0.0,
      'velocityY': copData.length > 1 ? totalVelocityY / (copData.length - 1) : 0.0,
      'area95': 0.0, // 95% confidence ellipse area
      'frequency': 0.0, // Dominant frequency
    };
  }

  Map<String, double> _calculateStabilityMetrics(ForceDataCollection data) {
    // Stability index calculations
    final copData = data.data
        .map((d) => d.combinedCOP)
        .where((cop) => cop != null)
        .map((cop) => cop!)
        .toList();
    
    if (copData.isEmpty) return <String, double>{};
    
    // Calculate standard deviations
    final xValues = copData.map((cop) => cop.x).toList();
    final yValues = copData.map((cop) => cop.y).toList();
    
    final xStats = _calculateStatistics(xValues);
    final yStats = _calculateStatistics(yValues);
    
    return {
      'overall': math.sqrt((xStats['std'] ?? 0.0) * (xStats['std'] ?? 0.0) + 
                          (yStats['std'] ?? 0.0) * (yStats['std'] ?? 0.0)),
      'ap': yStats['std'] ?? 0.0, // Anterior-posterior
      'ml': xStats['std'] ?? 0.0, // Medial-lateral
    };
  }

  Map<String, double> _calculateStatistics(List<double> values) {
    if (values.isEmpty) return <String, double>{};
    
    // Basic statistics
    final mean = values.reduce((a, b) => a + b) / values.length;
    final sortedValues = List<double>.from(values)..sort();
    final median = sortedValues.length.isOdd 
        ? sortedValues[sortedValues.length ~/ 2]
        : (sortedValues[sortedValues.length ~/ 2 - 1] + sortedValues[sortedValues.length ~/ 2]) / 2;
    
    // Variance and standard deviation
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final std = math.sqrt(variance);
    
    // Coefficient of variation
    final cv = mean != 0 ? std / mean.abs() : 0.0;
    
    // Range
    final range = sortedValues.last - sortedValues.first;
    
    // Skewness and kurtosis (simplified)
    final skewness = _calculateSkewness(values, mean, std);
    final kurtosis = _calculateKurtosis(values, mean, std);
    
    return {
      'mean': mean,
      'median': median,
      'std': std,
      'variance': variance,
      'cv': cv,
      'range': range,
      'skewness': skewness,
      'kurtosis': kurtosis,
      'min': sortedValues.first,
      'max': sortedValues.last,
    };
  }

  double _calculateSkewness(List<double> values, double mean, double std) {
    if (std == 0 || values.length < 3) return 0.0;
    
    final n = values.length;
    final sum = values.map((v) => math.pow((v - mean) / std, 3)).reduce((a, b) => a + b);
    
    return (n / ((n - 1) * (n - 2))) * sum;
  }

  double _calculateKurtosis(List<double> values, double mean, double std) {
    if (std == 0 || values.length < 4) return 0.0;
    
    final n = values.length;
    final sum = values.map((v) => math.pow((v - mean) / std, 4)).reduce((a, b) => a + b);
    
    return ((n * (n + 1)) / ((n - 1) * (n - 2) * (n - 3))) * sum - 
           (3 * (n - 1) * (n - 1)) / ((n - 2) * (n - 3));
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    
    return variance;
  }
}

/// Metrik hesaplama parametreleri
class MetricsCalculationParams {
  final ForceDataCollection forceData;
  final TestType testType;
  final Athlete athlete;
  final double bodyWeight; // kg
  final int sampleRate; // Hz

  const MetricsCalculationParams({
    required this.forceData,
    required this.testType,
    required this.athlete,
    required this.bodyWeight,
    required this.sampleRate,
  });
}

/// Metrik hesaplama sonucu
class MetricsCalculationResult {
  final bool isSuccess;
  final Map<String, double>? metrics;
  final Duration? calculationTime;
  final String? errorMessage;

  const MetricsCalculationResult._({
    required this.isSuccess,
    this.metrics,
    this.calculationTime,
    this.errorMessage,
  });

  factory MetricsCalculationResult.success({
    required Map<String, double> metrics,
    required Duration calculationTime,
  }) {
    return MetricsCalculationResult._(
      isSuccess: true,
      metrics: metrics,
      calculationTime: calculationTime,
    );
  }

  factory MetricsCalculationResult.failure(String errorMessage) {
    return MetricsCalculationResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// Faz bilgisi
class PhaseInfo {
  final int startIndex;
  final int endIndex;
  final List<ForceData> _allData;

  const PhaseInfo(this.startIndex, this.endIndex, this._allData);

  Duration get duration {
    if (startIndex >= endIndex || endIndex >= _allData.length) {
      return Duration.zero;
    }
    
    final startTime = _allData[startIndex].timestamp;
    final endTime = _allData[endIndex].timestamp;
    
    return Duration(milliseconds: endTime - startTime);
  }

  List<ForceData> getData() {
    if (startIndex >= endIndex || endIndex >= _allData.length) {
      return [];
    }
    
    return _allData.sublist(startIndex, endIndex);
  }

  int get sampleCount => endIndex - startIndex;
}