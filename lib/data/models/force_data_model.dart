// lib/data/models/force_data_model.dart - Yeni dosya oluştur
import '../../domain/entities/force_data.dart';

class ForceDataModel {
  final String timestamp; // ISO string format
  final double leftGRF;
  final double leftCoPX;
  final double leftCoPY;
  final double rightGRF;
  final double rightCoPX;
  final double rightCoPY;
  final double totalGRF;
  final double asymmetryIndex;
  final double stabilityIndex;
  final double loadRate;
  final List<double>? leftDeckForces;
  final List<double>? rightDeckForces;
  final double? samplingRate;
  final int? sampleIndex;

  const ForceDataModel({
    required this.timestamp,
    required this.leftGRF,
    required this.leftCoPX,
    required this.leftCoPY,
    required this.rightGRF,
    required this.rightCoPX,
    required this.rightCoPY,
    required this.totalGRF,
    required this.asymmetryIndex,
    required this.stabilityIndex,
    required this.loadRate,
    this.leftDeckForces,
    this.rightDeckForces,
    this.samplingRate,
    this.sampleIndex,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'leftGRF': leftGRF,
      'leftCoPX': leftCoPX,
      'leftCoPY': leftCoPY,
      'rightGRF': rightGRF,
      'rightCoPX': rightCoPX,
      'rightCoPY': rightCoPY,
      'totalGRF': totalGRF,
      'asymmetryIndex': asymmetryIndex,
      'stabilityIndex': stabilityIndex,
      'loadRate': loadRate,
      'leftDeckForces': leftDeckForces,
      'rightDeckForces': rightDeckForces,
      'samplingRate': samplingRate,
      'sampleIndex': sampleIndex,
    };
  }

  factory ForceDataModel.fromJson(Map<String, dynamic> json) {
    return ForceDataModel(
      timestamp: json['timestamp'] as String,
      leftGRF: (json['leftGRF'] as num).toDouble(),
      leftCoPX: (json['leftCoPX'] as num).toDouble(),
      leftCoPY: (json['leftCoPY'] as num).toDouble(),
      rightGRF: (json['rightGRF'] as num).toDouble(),
      rightCoPX: (json['rightCoPX'] as num).toDouble(),
      rightCoPY: (json['rightCoPY'] as num).toDouble(),
      totalGRF: (json['totalGRF'] as num).toDouble(),
      asymmetryIndex: (json['asymmetryIndex'] as num).toDouble(),
      stabilityIndex: (json['stabilityIndex'] as num).toDouble(),
      loadRate: (json['loadRate'] as num).toDouble(),
      leftDeckForces: (json['leftDeckForces'] as List?)?.cast<double>(),
      rightDeckForces: (json['rightDeckForces'] as List?)?.cast<double>(),
      samplingRate: (json['samplingRate'] as num?)?.toDouble(),
      sampleIndex: json['sampleIndex'] as int?,
    );
  }

  // Entity conversion
  ForceData toEntity() {
    return ForceData(
      timestamp: DateTime.parse(timestamp),
      leftGRF: leftGRF,
      leftCoPX: leftCoPX,
      leftCoPY: leftCoPY,
      rightGRF: rightGRF,
      rightCoPX: rightCoPX,
      rightCoPY: rightCoPY,
      totalGRF: totalGRF,
      asymmetryIndex: asymmetryIndex,
      stabilityIndex: stabilityIndex,
      loadRate: loadRate,
      leftDeckForces: leftDeckForces,
      rightDeckForces: rightDeckForces,
      samplingRate: samplingRate,
      sampleIndex: sampleIndex,
    );
  }

  factory ForceDataModel.fromEntity(ForceData entity) {
    return ForceDataModel(
      timestamp: entity.timestamp.toIso8601String(),
      leftGRF: entity.leftGRF,
      leftCoPX: entity.leftCoPX,
      leftCoPY: entity.leftCoPY,
      rightGRF: entity.rightGRF,
      rightCoPX: entity.rightCoPX,
      rightCoPY: entity.rightCoPY,
      totalGRF: entity.totalGRF,
      asymmetryIndex: entity.asymmetryIndex,
      stabilityIndex: entity.stabilityIndex,
      loadRate: entity.loadRate,
      leftDeckForces: entity.leftDeckForces,
      rightDeckForces: entity.rightDeckForces,
      samplingRate: entity.samplingRate,
      sampleIndex: entity.sampleIndex,
    );
  }

  // Mock data factory
  factory ForceDataModel.mock({
    DateTime? timestamp,
    double? totalForce,
    int? index,
  }) {
    final time = timestamp ?? DateTime.now();
    final force = totalForce ?? 800.0;
    final leftForce = force * 0.48;
    final rightForce = force * 0.52;
    
    return ForceDataModel(
      timestamp: time.toIso8601String(),
      leftGRF: leftForce,
      leftCoPX: 0.0,
      leftCoPY: 0.0,
      rightGRF: rightForce,
      rightCoPX: 0.0,
      rightCoPY: 0.0,
      totalGRF: force,
      asymmetryIndex: (leftForce - rightForce).abs() / force,
      stabilityIndex: 0.8,
      loadRate: 0.0,
      samplingRate: 1000.0,
      sampleIndex: index ?? 0,
    );
  }
}