import 'package:equatable/equatable.dart';
import 'dart:math' as math;

class ForceData extends Equatable {
  final DateTime timestamp;
  final List<double> leftPlateForces; // 4 load cell values
  final List<double> rightPlateForces; // 4 load cell values
  final double samplingRate; // Hz
  final int sampleIndex;

  const ForceData({
    required this.timestamp,
    required this.leftPlateForces,
    required this.rightPlateForces,
    required this.samplingRate,
    required this.sampleIndex,
  });

  // Computed properties
  double get leftTotal => leftPlateForces.fold(0.0, (sum, force) => sum + force);
  
  double get rightTotal => rightPlateForces.fold(0.0, (sum, force) => sum + force);
  
  // DÜZELTİLDİ: leftForce ve rightForce yerine leftTotal ve rightTotal kullan
  double get totalForce => math.sqrt(leftTotal * leftTotal + rightTotal * rightTotal);
  
  double get asymmetryPercentage {
    final total = totalForce;
    if (total == 0) return 0.0;
    return ((leftTotal - rightTotal).abs() / total) * 100;
  }

  // Center of Pressure calculation (simplified)
  double get centerOfPressureX {
    final total = totalForce;
    if (total == 0) return 0.0;
    
    // Assuming symmetric plate layout: -1 to +1 range
    return (rightTotal - leftTotal) / total;
  }

  // Force per load cell averages
  double get leftAverageForce => leftTotal / 4;
  double get rightAverageForce => rightTotal / 4;

  // Quality indicators
  bool get isValidData {
    // Check if all forces are finite and within reasonable range
    final allForces = [...leftPlateForces, ...rightPlateForces];
    return allForces.every((force) => 
      force.isFinite && force >= -1000 && force <= 5000);
  }

  double get dataQuality {
    if (!isValidData) return 0.0;
    
    // Simple quality metric based on force consistency
    final leftStdDev = _calculateStdDev(leftPlateForces);
    final rightStdDev = _calculateStdDev(rightPlateForces);
    final avgStdDev = (leftStdDev + rightStdDev) / 2;
    
    // Lower standard deviation = higher quality (more consistent)
    return (100 / (1 + avgStdDev / 10)).clamp(0.0, 100.0);
  }

  double _calculateStdDev(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((v) => (v - mean) * (v - mean))
        .reduce((a, b) => a + b) / values.length;
    
    // DÜZELTİLDİ: sqrt kullanımı
    return variance.isFinite ? math.sqrt(variance) : 0.0;
  }

  // Copy with method
  ForceData copyWith({
    DateTime? timestamp,
    List<double>? leftPlateForces,
    List<double>? rightPlateForces,
    double? samplingRate,
    int? sampleIndex,
  }) {
    return ForceData(
      timestamp: timestamp ?? this.timestamp,
      leftPlateForces: leftPlateForces ?? this.leftPlateForces,
      rightPlateForces: rightPlateForces ?? this.rightPlateForces,
      samplingRate: samplingRate ?? this.samplingRate,
      sampleIndex: sampleIndex ?? this.sampleIndex,
    );
  }

  @override
  List<Object?> get props => [
        timestamp,
        leftPlateForces,
        rightPlateForces,
        samplingRate,
        sampleIndex,
      ];
}