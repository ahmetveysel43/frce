// lib/domain/usecases/calculate_metrics_usecase.dart - Tamamen Düzeltilmiş
import 'dart:math' as math;
import 'package:dartz/dartz.dart';
import '../entities/force_data.dart';
import '../value_objects/asymmetry_data.dart';
import '../../core/constants/test_constants.dart';
import '../../core/constants/physics_constants.dart';
import '../../core/utils/math_utils.dart';
import '../../core/utils/signal_processing.dart';
import '../../core/errors/failures.dart';

class CalculateMetricsUseCase {
  const CalculateMetricsUseCase();

  /// Test tipine göre metrikleri hesapla
  Future<Either<Failure, Map<String, double>>> calculateMetrics(
    List<ForceData> rawData,
    TestType testType,
  ) async {
    if (rawData.isEmpty) {
      return const Left(DataProcessingFailure('Ham veri bulunamadı'));
    }

    try {
      switch (testType) {
        case TestType.counterMovementJump:
          return Right(await _calculateCMJMetrics(rawData));
        case TestType.squatJump:
          return Right(await _calculateSJMetrics(rawData));
        case TestType.dropJump:
          return Right(await _calculateDJMetrics(rawData));
        case TestType.balance:
          return Right(await _calculateBalanceMetrics(rawData));
        case TestType.isometric:
          return Right(await _calculateIsometricMetrics(rawData));
        case TestType.landing:
          return Right(await _calculateLandingMetrics(rawData));
      }
    } catch (e) {
      return Left(DataProcessingFailure('Metrik hesaplama hatası: $e'));
    }
  }

  /// Counter Movement Jump metriklerini hesapla
  Future<Map<String, double>> _calculateCMJMetrics(List<ForceData> data) async {
    final forces = data.map((d) => d.totalGRF).toList();
    final samplingRate = data.first.samplingRate ?? 1000.0; // ✅ Null safety
    
    // Baseline düzeltmesi
    final correctedForces = SignalProcessor.baselineCorrection(forces);
    
    // Faz geçişlerini tespit et
    final phases = _detectJumpPhases(correctedForces, samplingRate);
    
    // Temel metrikler
    final peakForce = _getMaxValue(correctedForces);
    final averageForce = _getMeanValue(correctedForces);
    final rfd = _calculateRFD(correctedForces, phases, samplingRate);
    final impulse = MathUtils.calculateImpulse(correctedForces, samplingRate);
    
    // Jump height hesaplama (kuvvet-zaman eğrisinden)
    final jumpHeight = _calculateJumpHeight(correctedForces, phases, samplingRate);
    
    // Asimetri hesaplama
    final asymmetryData = _calculateAsymmetry(data);
    
    // Contact ve flight time
    final contactTime = phases['contactTime'] ?? 0.0;
    final flightTime = _calculateFlightTime(jumpHeight);
    
    // Güç hesaplama
    final peakPower = _calculatePeakPower(correctedForces, samplingRate);
    
    return {
      'jumpHeight': jumpHeight,
      'peakForce': peakForce,
      'averageForce': averageForce,
      'peakPower': peakPower,
      'rfd': rfd,
      'impulse': impulse,
      'contactTime': contactTime,
      'flightTime': flightTime,
      'asymmetryIndex': asymmetryData.percentage,
      'forceAsymmetry': asymmetryData.asymmetryIndex,
    };
  }

  /// Squat Jump metriklerini hesapla
  Future<Map<String, double>> _calculateSJMetrics(List<ForceData> data) async {
    // SJ için CMJ'den farklı olarak countermovement fazı yok
    final forces = data.map((d) => d.totalGRF).toList();
    final samplingRate = data.first.samplingRate ?? 1000.0; // ✅ Null safety
    
    final correctedForces = SignalProcessor.baselineCorrection(forces);
    final phases = _detectSquatJumpPhases(correctedForces, samplingRate);
    
    final peakForce = _getMaxValue(correctedForces);
    final averageForce = _getMeanValue(correctedForces);
    final rfd = _calculateRFD(correctedForces, phases, samplingRate);
    final impulse = MathUtils.calculateImpulse(correctedForces, samplingRate);
    final jumpHeight = _calculateJumpHeight(correctedForces, phases, samplingRate);
    final asymmetryData = _calculateAsymmetry(data);
    
    return {
      'jumpHeight': jumpHeight,
      'peakForce': peakForce,
      'averageForce': averageForce,
      'rfd': rfd,
      'impulse': impulse,
      'asymmetryIndex': asymmetryData.percentage,
      'forceAsymmetry': asymmetryData.asymmetryIndex,
    };
  }

  /// Drop Jump metriklerini hesapla
  Future<Map<String, double>> _calculateDJMetrics(List<ForceData> data) async {
    final forces = data.map((d) => d.totalGRF).toList();
    final samplingRate = data.first.samplingRate ?? 1000.0; // ✅ Null safety
    
    final correctedForces = SignalProcessor.baselineCorrection(forces);
    final phases = _detectDropJumpPhases(correctedForces, samplingRate);
    
    final peakLandingForce = phases['peakLandingForce'] ?? 0.0;
    final peakJumpForce = phases['peakJumpForce'] ?? 0.0;
    final groundContactTime = phases['groundContactTime'] ?? 0.0;
    
    final jumpHeight = _calculateJumpHeight(correctedForces, phases, samplingRate);
    final reactiveStrengthIndex = groundContactTime > 0 ? jumpHeight / groundContactTime : 0.0;
    
    return {
      'jumpHeight': jumpHeight,
      'peakLandingForce': peakLandingForce,
      'peakJumpForce': peakJumpForce,
      'groundContactTime': groundContactTime,
      'reactiveStrengthIndex': reactiveStrengthIndex,
    };
  }

  /// Balance metriklerini hesapla
  Future<Map<String, double>> _calculateBalanceMetrics(List<ForceData> data) async {
    // ✅ Combined CoP calculation from left and right CoP
    final copX = data.map((d) => _calculateCombinedCoPX(d)).toList();
    
    // Postural sway hesaplamaları
    final copRange = _getMaxValue(copX) - _getMinValue(copX);
    final copStdDev = _calculateStandardDeviation(copX);
    final copVelocity = _calculateCoPVelocity(copX, data.first.samplingRate ?? 1000.0);
    
    return {
      'copRange': copRange,
      'copStdDev': copStdDev,
      'copVelocity': copVelocity,
      'sway': copStdDev * 100, // Sway index
    };
  }

  /// Isometric metriklerini hesapla
  Future<Map<String, double>> _calculateIsometricMetrics(List<ForceData> data) async {
    final forces = data.map((d) => d.totalGRF).toList();
    
    final peakForce = _getMaxValue(forces);
    final averageForce = _getMeanValue(forces);
    final forceStability = _calculateStandardDeviation(forces);
    final samplingRate = data.first.samplingRate ?? 1000.0; // ✅ Null safety
    final rfd = forces.isNotEmpty ? (forces.last - forces.first) / (forces.length / samplingRate) : 0.0;
    
    return {
      'peakForce': peakForce,
      'averageForce': averageForce,
      'forceStability': forceStability,
      'rfd': rfd,
    };
  }

  /// Landing metriklerini hesapla
  Future<Map<String, double>> _calculateLandingMetrics(List<ForceData> data) async {
    final forces = data.map((d) => d.totalGRF).toList();
    final samplingRate = data.first.samplingRate ?? 1000.0; // ✅ Null safety
    
    final peakLandingForce = _getMaxValue(forces);
    final timeToStabilization = _calculateTimeToStabilization(forces, samplingRate);
    final loadingRate = _calculateLoadingRate(forces, samplingRate);
    
    return {
      'peakLandingForce': peakLandingForce,
      'timeToStabilization': timeToStabilization,
      'loadingRate': loadingRate,
    };
  }

  // ✅ Helper methods - Null safety ile
  double _getMaxValue(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce(math.max);
  }

  double _getMinValue(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce(math.min);
  }

  double _getMeanValue(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = _getMeanValue(values);
    final variance = values.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  // ✅ Combined CoP calculation
  double _calculateCombinedCoPX(ForceData data) {
    final leftForce = data.leftGRF;
    final rightForce = data.rightGRF;
    final totalForce = leftForce + rightForce;
    
    if (totalForce == 0) return 0.0;
    
    // Weight-averaged CoP
    return (leftForce * data.leftCoPX + rightForce * data.rightCoPX) / totalForce;
  }

  Map<String, double> _detectJumpPhases(List<double> forces, double samplingRate) {
    // Basitleştirilmiş faz tespiti
    const threshold = 50.0; // Newton
    int takeoffIndex = -1;
    
    for (int i = 0; i < forces.length; i++) {
      if (forces[i] > threshold) {
        takeoffIndex = i;
        break;
      }
    }
    
    final contactTime = takeoffIndex >= 0 ? takeoffIndex / samplingRate : 0.0;
    
    return {
      'takeoffIndex': takeoffIndex.toDouble(),
      'contactTime': contactTime,
    };
  }

  Map<String, double> _detectSquatJumpPhases(List<double> forces, double samplingRate) {
    return _detectJumpPhases(forces, samplingRate);
  }

  Map<String, double> _detectDropJumpPhases(List<double> forces, double samplingRate) {
    return _detectJumpPhases(forces, samplingRate);
  }

  double _calculateRFD(List<double> forces, Map<String, double> phases, double samplingRate) {
    if (forces.length < 2) return 0.0;
    return MathUtils.calculateRFD(forces, samplingRate);
  }

  double _calculateJumpHeight(List<double> forces, Map<String, double> phases, double samplingRate) {
    // Basitleştirilmiş jump height hesaplama
    final impulse = MathUtils.calculateImpulse(forces, samplingRate);
    const bodyWeight = 700.0; // Varsayılan vücut ağırlığı (N)
    
    if (bodyWeight == 0) return 0.0;
    
    final velocity = impulse / bodyWeight;
    final height = (velocity * velocity) / (2 * PhysicsConstants.gravity);
    
    return height * 100; // cm'ye çevir
  }

  double _calculateFlightTime(double jumpHeight) {
    if (jumpHeight <= 0) return 0.0;
    return 2 * math.sqrt(2 * (jumpHeight / 100) / PhysicsConstants.gravity);
  }

  double _calculatePeakPower(List<double> forces, double samplingRate) {
    if (forces.length < 2) return 0.0;
    
    // P = F * v, velocity'yi force'tan türetiyoruz
    final maxForce = _getMaxValue(forces);
    final estimatedVelocity = maxForce / 1000; // Basitleştirilmiş
    
    return maxForce * estimatedVelocity;
  }

  AsymmetryData _calculateAsymmetry(List<ForceData> data) {
    if (data.isEmpty) {
      return AsymmetryData.fromValues(
        type: AsymmetryType.force,
        leftValue: 0,
        rightValue: 0,
      );
    }
    
    // ✅ Use actual ForceData properties
    final leftTotal = data.map((d) => d.leftGRF).reduce((a, b) => a + b);
    final rightTotal = data.map((d) => d.rightGRF).reduce((a, b) => a + b);
    
    return AsymmetryData.fromValues(
      type: AsymmetryType.force,
      leftValue: leftTotal,
      rightValue: rightTotal,
    );
  }

  double _calculateCoPVelocity(List<double> copX, double samplingRate) {
    if (copX.length < 2) return 0.0;
    
    double totalDistance = 0;
    for (int i = 1; i < copX.length; i++) {
      totalDistance += (copX[i] - copX[i-1]).abs();
    }
    
    final totalTime = copX.length / samplingRate;
    return totalDistance / totalTime;
  }

  double _calculateTimeToStabilization(List<double> forces, double samplingRate) {
    // Basitleştirilmiş stabilizasyon zamanı
    final threshold = _getMeanValue(forces) + _calculateStandardDeviation(forces);
    
    for (int i = forces.length - 1; i >= 0; i--) {
      if (forces[i] > threshold) {
        return (forces.length - i) / samplingRate;
      }
    }
    
    return 0.0;
  }

  double _calculateLoadingRate(List<double> forces, double samplingRate) {
    if (forces.length < 2) return 0.0;
    
    final peakForce = _getMaxValue(forces);
    final peakIndex = forces.indexOf(peakForce);
    
    if (peakIndex == 0) return 0.0;
    
    final timeToPeak = peakIndex / samplingRate;
    return peakForce / timeToPeak;
  }
}