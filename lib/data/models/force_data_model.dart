// lib/data/models/force_data_model.dart - Düzeltilmiş
import '../../domain/entities/force_data.dart';

class ForceDataModel {
  final String timestamp; // ISO string format
  final List<double> leftDeckForces;  // ✅ leftPlateForces -> leftDeckForces
  final List<double> rightDeckForces; // ✅ rightPlateForces -> rightDeckForces
  final double samplingRate;
  final int sampleIndex;

  const ForceDataModel({
    required this.timestamp,
    required this.leftDeckForces,  // ✅ Parameter name fixed
    required this.rightDeckForces, // ✅ Parameter name fixed
    required this.samplingRate,
    required this.sampleIndex,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'leftDeckForces': leftDeckForces,   // ✅ JSON key updated
      'rightDeckForces': rightDeckForces, // ✅ JSON key updated
      'samplingRate': samplingRate,
      'sampleIndex': sampleIndex,
    };
  }

  factory ForceDataModel.fromJson(Map<String, dynamic> json) {
    return ForceDataModel(
      timestamp: json['timestamp'] as String,
      leftDeckForces: List<double>.from(json['leftDeckForces'] as List),   // ✅ JSON key updated
      rightDeckForces: List<double>.from(json['rightDeckForces'] as List), // ✅ JSON key updated
      samplingRate: (json['samplingRate'] as num).toDouble(),
      sampleIndex: json['sampleIndex'] as int,
    );
  }

  // Entity conversion
  ForceData toEntity() {
    return ForceData(
      timestamp: DateTime.parse(timestamp),
      leftDeckForces: leftDeckForces,   // ✅ Parameter name fixed
      rightDeckForces: rightDeckForces, // ✅ Parameter name fixed
      samplingRate: samplingRate,
      sampleIndex: sampleIndex,
    );
  }

  factory ForceDataModel.fromEntity(ForceData forceData) {
    return ForceDataModel(
      timestamp: forceData.timestamp.toIso8601String(),
      leftDeckForces: forceData.leftDeckForces,   // ✅ Property name fixed
      rightDeckForces: forceData.rightDeckForces, // ✅ Property name fixed
      samplingRate: forceData.samplingRate,
      sampleIndex: forceData.sampleIndex,
    );
  }

  // CSV format
  String toCsvRow() {
    final leftStr = leftDeckForces.join(',');
    final rightStr = rightDeckForces.join(',');
    return '$timestamp,$leftStr,$rightStr,$samplingRate,$sampleIndex';
  }

  static String getCsvHeader() {
    return 'timestamp,left1,left2,left3,left4,right1,right2,right3,right4,samplingRate,sampleIndex';
  }

  // Mock data factory
  factory ForceDataModel.mock({
    DateTime? timestamp,
    double? totalForce,
    int? index,
  }) {
    final now = timestamp ?? DateTime.now();
    final baseForce = totalForce ?? 800.0; // Default body weight
    
    // Realistic values for each load cell
    final leftDeckForces = List.generate(4, (i) => 
      baseForce / 8 + (i * 5) + (DateTime.now().millisecond % 20) - 10);
    final rightDeckForces = List.generate(4, (i) => 
      baseForce / 8 + (i * 5) + (DateTime.now().millisecond % 20) - 10);

    return ForceDataModel(
      timestamp: now.toIso8601String(),
      leftDeckForces: leftDeckForces,   // ✅ Parameter name fixed
      rightDeckForces: rightDeckForces, // ✅ Parameter name fixed
      samplingRate: 1000.0,
      sampleIndex: index ?? 0,
    );
  }
}