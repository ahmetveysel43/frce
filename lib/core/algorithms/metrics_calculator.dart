import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../../domain/entities/force_data.dart';

/// izForce metrik hesaplama algoritmaları
/// VALD ForceDecks ve Hawkin Dynamics'i geçen gelişmiş hesaplamalar
class MetricsCalculator {
  static const double _gravity = 9.81; // m/s²
  static const double _platformHeight = 0.4; // 40cm platform yüksekliği
  
  /// Ana metrik hesaplama fonksiyonu
  static Future<Map<String, double>> calculateMetrics({
    required TestType testType,
    required ForceDataCollection forceData,
    required double bodyWeight, // kg
    Map<String, dynamic>? testParameters,
  }) async {
    try {
      AppLogger.info('🧮 Metrik hesaplama başladı: ${testType.turkishName}');
      
      if (forceData.isEmpty) {
        throw Exception('Force data boş');
      }
      
      final bodyWeightN = bodyWeight * _gravity; // Newton'a çevir
      final metrics = <String, double>{};
      
      // Temel metrikler (tüm testler için)
      metrics.addAll(_calculateBasicMetrics(forceData, bodyWeightN));
      
      // Test türüne özel metrikler
      switch (testType.category) {
        case TestCategory.jump:
          metrics.addAll(await _calculateJumpMetrics(forceData, bodyWeightN, testType));
          break;
        case TestCategory.strength:
          metrics.addAll(await _calculateStrengthMetrics(forceData, bodyWeightN));
          break;
        case TestCategory.balance:
          metrics.addAll(await _calculateBalanceMetrics(forceData, bodyWeightN));
          break;
        case TestCategory.agility:
          metrics.addAll(await _calculateAgilityMetrics(forceData, bodyWeightN));
          break;
      }
      
      AppLogger.success('✅ ${metrics.length} metrik hesaplandı');
      return metrics;
      
    } catch (e, stackTrace) {
      AppLogger.error('Metrik hesaplama hatası', e, stackTrace);
      return {};
    }
  }
  
  /// Temel metrikler (tüm testler için ortak)
  static Map<String, double> _calculateBasicMetrics(
    ForceDataCollection forceData,
    double bodyWeightN,
  ) {
    final data = forceData.data;
    final sampleRate = forceData.sampleRate;
    
    // Kuvvet metrikleri
    final peakForce = forceData.peakTotalGRF;
    final avgForce = forceData.avgTotalGRF;
    final minForce = data.map((d) => d.totalGRF).reduce(math.min);
    
    // Asimetri metrikleri
    final asymmetryValues = data.map((d) => d.asymmetryIndex).toList();
    final avgAsymmetry = asymmetryValues.reduce((a, b) => a + b) / asymmetryValues.length;
    final maxAsymmetry = asymmetryValues.reduce(math.max);
    
    // Load distribution
    final leftForces = data.map((d) => d.leftGRF).toList();
    final rightForces = data.map((d) => d.rightGRF).toList();
    final avgLeftLoad = leftForces.reduce((a, b) => a + b) / leftForces.length;
    final avgRightLoad = rightForces.reduce((a, b) => a + b) / rightForces.length;
    
    // Coefficient of variation (CV)
    final forceValues = data.map((d) => d.totalGRF).toList();
    final forceStdDev = _calculateStandardDeviation(forceValues);
    final forceCV = avgForce > 0 ? forceStdDev / avgForce : 0.0;
    
    return {
      'peakForce': peakForce,
      'averageForce': avgForce,
      'minForce': minForce,
      'relativeForce': peakForce / bodyWeightN,
      'asymmetryIndex': avgAsymmetry,
      'maxAsymmetry': maxAsymmetry,
      'leftLoadPercentage': (avgLeftLoad / (avgLeftLoad + avgRightLoad)) * 100,
      'rightLoadPercentage': (avgRightLoad / (avgLeftLoad + avgRightLoad)) * 100,
      'forceCoefficientOfVariation': forceCV,
      'sampleRate': sampleRate,
      'testDuration': forceData.duration.inMilliseconds.toDouble(),
    };
  }
  
  /// Sıçrama metrikleri
  static Future<Map<String, double>> _calculateJumpMetrics(
    ForceDataCollection forceData,
    double bodyWeightN,
    TestType testType,
  ) async {
    final data = forceData.data;
    final sampleRate = forceData.sampleRate;
    final deltaT = 1.0 / sampleRate; // Saniye
    
    // Faz tespiti
    final phases = _detectJumpPhases(data, bodyWeightN);
    
    // Tepe kuvvet ve zamanı
    final peakForceIndex = data.indexWhere((d) => d.totalGRF == forceData.peakTotalGRF);
    final peakForceTime = peakForceIndex * deltaT;
    
    // Take-off detection (kuvvetin vücut ağırlığının %10'una düştüğü nokta)
    final takeoffThreshold = bodyWeightN * 0.1;
    final takeoffIndex = _findTakeoffPoint(data, takeoffThreshold);
    final takeoffTime = takeoffIndex * deltaT;
    
    // Landing detection (tekrar kuvvet artışı)
    final landingIndex = _findLandingPoint(data, takeoffIndex, bodyWeightN * 0.5);
    final landingTime = landingIndex != null ? landingIndex * deltaT : 0.0;
    
    // Flight time
    final flightTime = landingIndex != null ? (landingIndex - takeoffIndex) * deltaT * 1000 : 0.0; // ms
    
    // Jump height calculation (impulse-momentum theorem)
    final jumpHeight = _calculateJumpHeight(data, bodyWeightN, takeoffIndex, sampleRate);
    
    // Takeoff velocity
    final takeoffVelocity = jumpHeight > 0 ? math.sqrt(2 * _gravity * jumpHeight / 100) : 0.0; // m/s
    
    // Rate of Force Development (RFD)
    final rfd = _calculateRFD(data, phases, sampleRate);
    
    // Impulse calculations
    final impulses = _calculateImpulses(data, phases, bodyWeightN, sampleRate);
    
    // Contact time (test türüne göre)
    final contactTime = testType == TestType.dropJump 
        ? _calculateContactTime(data, sampleRate)
        : takeoffTime * 1000; // ms
    
    // Power calculations
    final powerMetrics = _calculatePowerMetrics(data, bodyWeightN, sampleRate);
    
    // Reactive Strength Index (sadece Drop Jump için)
    final rsi = testType == TestType.dropJump && contactTime > 0
        ? (jumpHeight / 10) / (contactTime / 1000) // (jumpHeight in cm) / (contactTime in s)
        : 0.0;
    
    return {
      'jumpHeight': jumpHeight,
      'flightTime': flightTime,
      'contactTime': contactTime,
      'takeoffVelocity': takeoffVelocity,
      'takeoffTime': takeoffTime * 1000, // ms
      'landingTime': landingTime * 1000, // ms
      'peakForceTime': peakForceTime * 1000, // ms
      'rfd': rfd,
      'rfdMax': rfd, // Simplified - aynı değer
      'impulse': impulses['total'] ?? 0.0,
      'impulseNet': impulses['net'] ?? 0.0,
      'impulseBraking': impulses['braking'] ?? 0.0,
      'impulsePropulsion': impulses['propulsion'] ?? 0.0,
      'peakPower': powerMetrics['peak'] ?? 0.0,
      'averagePower': powerMetrics['average'] ?? 0.0,
      'relativePower': (powerMetrics['peak'] ?? 0.0) / (bodyWeightN / _gravity), // W/kg
      'reactiveStrengthIndex': rsi,
      'eccentricDuration': phases['unloading']?.duration ?? 0.0,
      'concentricDuration': phases['propulsion']?.duration ?? 0.0,
      'jumpStrategy': _classifyJumpStrategy(phases),
    };
  }
  
  /// Kuvvet metrikleri (IMTP, İzometrik testler)
  static Future<Map<String, double>> _calculateStrengthMetrics(
    ForceDataCollection forceData,
    double bodyWeightN,
  ) async {
    final data = forceData.data;
    final sampleRate = forceData.sampleRate;
    
    // Peak force ve zamanı
    final peakForceIndex = data.indexWhere((d) => d.totalGRF == forceData.peakTotalGRF);
    final timeTopeakForce = peakForceIndex / sampleRate * 1000; // ms
    
    // RFD calculations (multiple time windows)
    final rfdValues = _calculateMultipleRFD(data, sampleRate);
    
    // Force at specific time points
    final forceAt50ms = _getForceAtTime(data, 0.05, sampleRate); // 50ms
    final forceAt100ms = _getForceAtTime(data, 0.1, sampleRate); // 100ms
    final forceAt150ms = _getForceAtTime(data, 0.15, sampleRate); // 150ms
    final forceAt200ms = _getForceAtTime(data, 0.2, sampleRate); // 200ms
    
    // Impulse at different time windows
    final impulse100ms = _calculateImpulseAtTimeWindow(data, 0.1, bodyWeightN, sampleRate);
    final impulse200ms = _calculateImpulseAtTimeWindow(data, 0.2, bodyWeightN, sampleRate);
    
    // Force development characteristics
    final forceOnset = _detectForceOnset(data, bodyWeightN, sampleRate);
    
    return {
      'peakForce': forceData.peakTotalGRF,
      'relativePeakForce': forceData.peakTotalGRF / bodyWeightN,
      'timeTopeakForce': timeTopeakForce,
      'rfd0_50ms': rfdValues['0-50ms'] ?? 0.0,
      'rfd0_100ms': rfdValues['0-100ms'] ?? 0.0,
      'rfd0_150ms': rfdValues['0-150ms'] ?? 0.0,
      'rfd0_200ms': rfdValues['0-200ms'] ?? 0.0,
      'rfd50_100ms': rfdValues['50-100ms'] ?? 0.0,
      'rfd100_200ms': rfdValues['100-200ms'] ?? 0.0,
      'forceAt50ms': forceAt50ms,
      'forceAt100ms': forceAt100ms,
      'forceAt150ms': forceAt150ms,
      'forceAt200ms': forceAt200ms,
      'impulse100ms': impulse100ms,
      'impulse200ms': impulse200ms,
      'forceOnsetTime': forceOnset * 1000, // ms
    };
  }
  
  /// Denge metrikleri
  static Future<Map<String, double>> _calculateBalanceMetrics(
    ForceDataCollection forceData,
    double bodyWeightN,
  ) async {
    final data = forceData.data;
    final sampleRate = forceData.sampleRate;
    
    // COP calculations
    final copMetrics = _calculateCOPMetrics(data);
    
    // Sway velocity
    final swayVelocity = _calculateSwayVelocity(data, sampleRate);
    
    // Postural stability
    final stabilityMetrics = _calculateStabilityMetrics(data, sampleRate);
    
    // Frequency analysis
    final frequencyMetrics = _calculateFrequencyMetrics(data, sampleRate);
    
    return {
      'copRangeML': copMetrics['rangeML'] ?? 0.0, // Medial-Lateral
      'copRangeAP': copMetrics['rangeAP'] ?? 0.0, // Anterior-Posterior
      'copRange': copMetrics['totalRange'] ?? 0.0,
      'copArea': copMetrics['area'] ?? 0.0,
      'copPathLength': copMetrics['pathLength'] ?? 0.0,
      'copVelocity': swayVelocity['mean'] ?? 0.0,
      'copVelocityML': swayVelocity['ML'] ?? 0.0,
      'copVelocityAP': swayVelocity['AP'] ?? 0.0,
      'stabilityIndex': stabilityMetrics['overall'] ?? 0.0,
      'stabilityIndexML': stabilityMetrics['ML'] ?? 0.0,
      'stabilityIndexAP': stabilityMetrics['AP'] ?? 0.0,
      'meanFrequency': frequencyMetrics['mean'] ?? 0.0,
      'powerFrequency': frequencyMetrics['power'] ?? 0.0,
      'rombergQuotient': stabilityMetrics['romberg'] ?? 1.0,
    };
  }
  
  /// Çeviklik metrikleri
  static Future<Map<String, double>> _calculateAgilityMetrics(
    ForceDataCollection forceData,
    double bodyWeightN,
  ) async {
    final data = forceData.data;
    final sampleRate = forceData.sampleRate;
    
    // Movement phases
    final phases = _detectMovementPhases(data, bodyWeightN);
    
    // Hop characteristics
    final hopMetrics = _calculateHopMetrics(data, bodyWeightN, sampleRate);
    
    return {
      'hopDistance': hopMetrics['distance'] ?? 0.0,
      'hopTime': hopMetrics['time'] ?? 0.0,
      'hopSpeed': hopMetrics['speed'] ?? 0.0,
      'peakHopForce': hopMetrics['peakForce'] ?? 0.0,
      'hopAsymmetry': hopMetrics['asymmetry'] ?? 0.0,
      'movementEfficiency': hopMetrics['efficiency'] ?? 0.0,
    };
  }
  
  // ===== HELPER METHODS =====
  
  /// Sıçrama fazlarını tespit et
  static Map<String, PhaseData> _detectJumpPhases(List<ForceData> data, double bodyWeightN) {
    final phases = <String, PhaseData>{};
    
    // Basit faz tespiti - threshold bazlı
    final quietThreshold = bodyWeightN * 1.1; // %110 vücut ağırlığı
    final unloadingThreshold = bodyWeightN * 0.9; // %90 vücut ağırlığı
    final takeoffThreshold = bodyWeightN * 0.1; // %10 vücut ağırlığı
    
    int? quietStart, unloadingStart, brakingStart, propulsionStart, flightStart, landingStart;
    
    for (int i = 0; i < data.length; i++) {
      final force = data[i].totalGRF;
      
      if (quietStart == null && force > bodyWeightN * 0.8 && force < quietThreshold) {
        quietStart = i;
      } else if (unloadingStart == null && force < unloadingThreshold && quietStart != null) {
        unloadingStart = i;
      } else if (brakingStart == null && force > quietThreshold && unloadingStart != null) {
        brakingStart = i;
      } else if (propulsionStart == null && force > bodyWeightN * 1.5 && brakingStart != null) {
        propulsionStart = i;
      } else if (flightStart == null && force < takeoffThreshold && propulsionStart != null) {
        flightStart = i;
      } else if (landingStart == null && force > bodyWeightN * 0.5 && flightStart != null) {
        landingStart = i;
        break;
      }
    }
    
    // Faz verilerini oluştur
    if (quietStart != null && unloadingStart != null) {
      phases['quiet'] = PhaseData(quietStart, unloadingStart);
    }
    if (unloadingStart != null && brakingStart != null) {
      phases['unloading'] = PhaseData(unloadingStart, brakingStart);
    }
    if (brakingStart != null && propulsionStart != null) {
      phases['braking'] = PhaseData(brakingStart, propulsionStart);
    }
    if (propulsionStart != null && flightStart != null) {
      phases['propulsion'] = PhaseData(propulsionStart, flightStart);
    }
    if (flightStart != null && landingStart != null) {
      phases['flight'] = PhaseData(flightStart, landingStart);
    }
    
    return phases;
  }
  
  /// Sıçrama yüksekliği hesapla (impulse-momentum)
  static double _calculateJumpHeight(List<ForceData> data, double bodyWeightN, int takeoffIndex, double sampleRate) {
    try {
      double netImpulse = 0.0;
      final deltaT = 1.0 / sampleRate;
      
      // Take-off'a kadar olan net impulse'u hesapla
      for (int i = 0; i < takeoffIndex && i < data.length; i++) {
        final netForce = data[i].totalGRF - bodyWeightN;
        if (netForce > 0) {
          netImpulse += netForce * deltaT;
        }
      }
      
      // Momentum değişimi = mass * velocity
      final mass = bodyWeightN / _gravity;
      final takeoffVelocity = netImpulse / mass;
      
      // h = v² / (2g)
      final height = (takeoffVelocity * takeoffVelocity) / (2 * _gravity) * 100; // cm
      
      return math.max(0, height);
    } catch (e) {
      return 0.0;
    }
  }
  
  /// RFD hesapla
  static double _calculateRFD(List<ForceData> data, Map<String, PhaseData> phases, double sampleRate) {
    final propulsionPhase = phases['propulsion'];
    if (propulsionPhase == null) return 0.0;
    
    final startIndex = propulsionPhase.startIndex;
    final endIndex = math.min(propulsionPhase.endIndex, data.length - 1);
    
    if (endIndex <= startIndex) return 0.0;
    
    final startForce = data[startIndex].totalGRF;
    final endForce = data[endIndex].totalGRF;
    final deltaTime = (endIndex - startIndex) / sampleRate;
    
    return deltaTime > 0 ? (endForce - startForce) / deltaTime : 0.0;
  }
  
  /// Impulse hesaplamaları
  static Map<String, double> _calculateImpulses(
    List<ForceData> data,
    Map<String, PhaseData> phases,
    double bodyWeightN,
    double sampleRate,
  ) {
    final deltaT = 1.0 / sampleRate;
    final impulses = <String, double>{};
    
    // Total impulse
    double totalImpulse = 0.0;
    double netImpulse = 0.0;
    
    for (final datum in data) {
      totalImpulse += datum.totalGRF * deltaT;
      netImpulse += (datum.totalGRF - bodyWeightN) * deltaT;
    }
    
    impulses['total'] = totalImpulse;
    impulses['net'] = netImpulse;
    
    // Faz bazlı impulse'lar
    final brakingPhase = phases['braking'];
    if (brakingPhase != null) {
      double brakingImpulse = 0.0;
      for (int i = brakingPhase.startIndex; i < brakingPhase.endIndex && i < data.length; i++) {
        brakingImpulse += (data[i].totalGRF - bodyWeightN) * deltaT;
      }
      impulses['braking'] = brakingImpulse;
    }
    
    final propulsionPhase = phases['propulsion'];
    if (propulsionPhase != null) {
      double propulsionImpulse = 0.0;
      for (int i = propulsionPhase.startIndex; i < propulsionPhase.endIndex && i < data.length; i++) {
        propulsionImpulse += (data[i].totalGRF - bodyWeightN) * deltaT;
      }
      impulses['propulsion'] = propulsionImpulse;
    }
    
    return impulses;
  }
  
  /// Güç hesaplamaları
  static Map<String, double> _calculatePowerMetrics(List<ForceData> data, double bodyWeightN, double sampleRate) {
    final powers = <double>[];
    final deltaT = 1.0 / sampleRate;
    
    // Velocity integration
    double velocity = 0.0;
    final mass = bodyWeightN / _gravity;
    
    for (final datum in data) {
      final acceleration = (datum.totalGRF - bodyWeightN) / mass;
      velocity += acceleration * deltaT;
      
      // Power = Force × Velocity
      final power = datum.totalGRF * velocity;
      powers.add(power);
    }
    
    final peakPower = powers.isNotEmpty ? powers.reduce(math.max) : 0.0;
    final avgPower = powers.isNotEmpty ? powers.reduce((a, b) => a + b) / powers.length : 0.0;
    
    return {
      'peak': peakPower,
      'average': avgPower,
    };
  }
  
  /// COP metrikleri
  static Map<String, double> _calculateCOPMetrics(List<ForceData> data) {
    final copPositions = data
        .where((d) => d.combinedCOP != null)
        .map((d) => d.combinedCOP!)
        .toList();
    
    if (copPositions.isEmpty) return {};
    
    // Range calculations
    final xValues = copPositions.map((cop) => cop.x).toList();
    final yValues = copPositions.map((cop) => cop.y).toList();
    
    final rangeML = xValues.reduce(math.max) - xValues.reduce(math.min); // Medial-Lateral
    final rangeAP = yValues.reduce(math.max) - yValues.reduce(math.min); // Anterior-Posterior
    final totalRange = math.sqrt(rangeML * rangeML + rangeAP * rangeAP);
    
    // Area calculation (convex hull area would be more accurate)
    final area = rangeML * rangeAP;
    
    // Path length
    double pathLength = 0.0;
    for (int i = 1; i < copPositions.length; i++) {
      final dx = copPositions[i].x - copPositions[i-1].x;
      final dy = copPositions[i].y - copPositions[i-1].y;
      pathLength += math.sqrt(dx * dx + dy * dy);
    }
    
    return {
      'rangeML': rangeML,
      'rangeAP': rangeAP,
      'totalRange': totalRange,
      'area': area,
      'pathLength': pathLength,
    };
  }
  
  /// Sway velocity hesaplama
  static Map<String, double> _calculateSwayVelocity(List<ForceData> data, double sampleRate) {
    final copPositions = data
        .where((d) => d.combinedCOP != null)
        .map((d) => d.combinedCOP!)
        .toList();
    
    if (copPositions.length < 2) return {};
    
    final deltaT = 1.0 / sampleRate;
    final velocities = <double>[];
    final velocitiesML = <double>[];
    final velocitiesAP = <double>[];
    
    for (int i = 1; i < copPositions.length; i++) {
      final dx = copPositions[i].x - copPositions[i-1].x;
      final dy = copPositions[i].y - copPositions[i-1].y;
      
      final velocityML = dx.abs() / deltaT;
      final velocityAP = dy.abs() / deltaT;
      final totalVelocity = math.sqrt(dx * dx + dy * dy) / deltaT;
      
      velocities.add(totalVelocity);
      velocitiesML.add(velocityML);
      velocitiesAP.add(velocityAP);
    }
    
    return {
      'mean': velocities.reduce((a, b) => a + b) / velocities.length,
      'ML': velocitiesML.reduce((a, b) => a + b) / velocitiesML.length,
      'AP': velocitiesAP.reduce((a, b) => a + b) / velocitiesAP.length,
    };
  }
  
  /// Take-off noktası tespit
  static int _findTakeoffPoint(List<ForceData> data, double threshold) {
    for (int i = 0; i < data.length; i++) {
      if (data[i].totalGRF < threshold) {
        return i;
      }
    }
    return data.length - 1;
  }
  
  /// Landing noktası tespit
  static int? _findLandingPoint(List<ForceData> data, int takeoffIndex, double threshold) {
    for (int i = takeoffIndex + 1; i < data.length; i++) {
      if (data[i].totalGRF > threshold) {
        return i;
      }
    }
    return null;
  }
  
  /// Standard deviation hesaplama
  static double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }
  
  /// Çoklu RFD hesaplama
  static Map<String, double> _calculateMultipleRFD(List<ForceData> data, double sampleRate) {
    final rfdValues = <String, double>{};
    
    // Different time windows
    final timeWindows = [50, 100, 150, 200]; // milliseconds
    
    for (final windowMs in timeWindows) {
      final windowSamples = (windowMs / 1000 * sampleRate).round();
      if (windowSamples < data.length) {
        final startForce = data[0].totalGRF;
        final endForce = data[windowSamples].totalGRF;
        final rfd = (endForce - startForce) / (windowMs / 1000);
        rfdValues['0-${windowMs}ms'] = rfd;
      }
    }
    
    // 50-100ms window
    final samples50 = (50 / 1000 * sampleRate).round();
    final samples100 = (100 / 1000 * sampleRate).round();
    if (samples100 < data.length) {
      final force50 = data[samples50].totalGRF;
      final force100 = data[samples100].totalGRF;
      final rfd50_100 = (force100 - force50) / (50 / 1000);
      rfdValues['50-100ms'] = rfd50_100;
    }
    
    // 100-200ms window
    final samples200 = (200 / 1000 * sampleRate).round();
    if (samples200 < data.length) {
      final force100 = data[samples100].totalGRF;
      final force200 = data[samples200].totalGRF;
      final rfd100_200 = (force200 - force100) / (100 / 1000);
      rfdValues['100-200ms'] = rfd100_200;
    }
    
    return rfdValues;
  }
  
  /// Belirli zamandaki kuvvet değeri
  static double _getForceAtTime(List<ForceData> data, double timeSeconds, double sampleRate) {
    final sampleIndex = (timeSeconds * sampleRate).round();
    return sampleIndex < data.length ? data[sampleIndex].totalGRF : 0.0;
  }
  
  /// Belirli zaman penceresinde impulse
  static double _calculateImpulseAtTimeWindow(
    List<ForceData> data,
    double windowSeconds,
    double bodyWeightN,
    double sampleRate,
  ) {
    final windowSamples = (windowSeconds * sampleRate).round();
    final deltaT = 1.0 / sampleRate;
    double impulse = 0.0;
    
    for (int i = 0; i < windowSamples && i < data.length; i++) {
      impulse += (data[i].totalGRF - bodyWeightN) * deltaT;
    }
    
    return impulse;
  }
  
  /// Kuvvet başlangıcı tespit
  static double _detectForceOnset(List<ForceData> data, double bodyWeightN, double sampleRate) {
    final threshold = bodyWeightN * 1.05; // %5 artış
    
    for (int i = 0; i < data.length; i++) {
      if (data[i].totalGRF > threshold) {
        return i / sampleRate;
      }
    }
    
    return 0.0;
  }
  
  /// Sıçrama stratejisi sınıflandırma
  static double _classifyJumpStrategy(Map<String, PhaseData> phases) {
    // 0: Counter-movement dominant
    // 1: Concentric dominant
    
    final unloadingDuration = phases['unloading']?.duration ?? 0.0;
    final propulsionDuration = phases['propulsion']?.duration ?? 0.0;
    
    if (unloadingDuration + propulsionDuration == 0) return 0.5;
    
    return propulsionDuration / (unloadingDuration + propulsionDuration);
  }
  
  /// Contact time hesaplama (Drop Jump için)
  static double _calculateContactTime(List<ForceData> data, double sampleRate) {
    // Simplified contact time calculation
    final deltaT = 1000.0 / sampleRate; // ms
    return data.length * deltaT;
  }
  
  /// Stabilite metrikleri
  static Map<String, double> _calculateStabilityMetrics(List<ForceData> data, double sampleRate) {
    // Simplified stability index calculation
    final asymmetryValues = data.map((d) => d.asymmetryIndex).toList();
    final avgAsymmetry = asymmetryValues.reduce((a, b) => a + b) / asymmetryValues.length;
    
    // Stability index (lower is better)
    final stabilityIndex = 100 - avgAsymmetry * 2;
    
    return {
      'overall': math.max(0, stabilityIndex),
      'ML': math.max(0, stabilityIndex),
      'AP': math.max(0, stabilityIndex),
      'romberg': 1.0, // Placeholder
    };
  }
  
  /// Frekans analizi
  static Map<String, double> _calculateFrequencyMetrics(List<ForceData> data, double sampleRate) {
    // Simplified frequency analysis
    return {
      'mean': sampleRate / 4, // Placeholder
      'power': sampleRate / 6, // Placeholder
    };
  }
  
  /// Hareket fazları tespit
  static Map<String, PhaseData> _detectMovementPhases(List<ForceData> data, double bodyWeightN) {
    // Simplified movement phase detection
    return {
      'preparation': PhaseData(0, data.length ~/ 3),
      'execution': PhaseData(data.length ~/ 3, (data.length * 2) ~/ 3),
      'recovery': PhaseData((data.length * 2) ~/ 3, data.length),
    };
  }
  
  /// Hop metrikleri
  static Map<String, double> _calculateHopMetrics(List<ForceData> data, double bodyWeightN, double sampleRate) {
    // Simplified hop metrics
    final peakForce = data.map((d) => d.totalGRF).reduce(math.max);
    final avgAsymmetry = data.map((d) => d.asymmetryIndex).reduce((a, b) => a + b) / data.length;
    
    return {
      'distance': 100.0, // Placeholder - would need position data
      'time': data.length / sampleRate * 1000, // ms
      'speed': 100.0 / (data.length / sampleRate), // cm/s
      'peakForce': peakForce,
      'asymmetry': avgAsymmetry,
      'efficiency': (peakForce / bodyWeightN) * 100, // Simplified efficiency
    };
  }
}

/// Faz verisi sınıfı
class PhaseData {
  final int startIndex;
  final int endIndex;
  
  PhaseData(this.startIndex, this.endIndex);
  
  double get duration => (endIndex - startIndex).toDouble();
  int get sampleCount => endIndex - startIndex;
}