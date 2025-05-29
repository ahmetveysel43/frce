import '../../domain/entities/force_data.dart';

class ForceDataModel {
  final String timestamp; // ISO string format
  final List<double> leftPlateForces;
  final List<double> rightPlateForces;
  final double samplingRate;
  final int sampleIndex;

  const ForceDataModel({
    required this.timestamp,
    required this.leftPlateForces,
    required this.rightPlateForces,
    required this.samplingRate,
    required this.sampleIndex,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'leftPlateForces': leftPlateForces,
      'rightPlateForces': rightPlateForces,
      'samplingRate': samplingRate,
      'sampleIndex': sampleIndex,
    };
  }

  factory ForceDataModel.fromJson(Map<String, dynamic> json) {
    return ForceDataModel(
      timestamp: json['timestamp'] as String,
      leftPlateForces: List<double>.from(json['leftPlateForces'] as List),
      rightPlateForces: List<double>.from(json['rightPlateForces'] as List),
      samplingRate: (json['samplingRate'] as num).toDouble(),
      sampleIndex: json['sampleIndex'] as int,
    );
  }

  // Entity conversion
  ForceData toEntity() {
    return ForceData(
      timestamp: DateTime.parse(timestamp),
      leftPlateForces: leftPlateForces,
      rightPlateForces: rightPlateForces,
      samplingRate: samplingRate,
      sampleIndex: sampleIndex,
    );
  }

  factory ForceDataModel.fromEntity(ForceData forceData) {
    return ForceDataModel(
      timestamp: forceData.timestamp.toIso8601String(),
      leftPlateForces: forceData.leftPlateForces,
      rightPlateForces: forceData.rightPlateForces,
      samplingRate: forceData.samplingRate,
      sampleIndex: forceData.sampleIndex,
    );
  }

  // CSV format için
  String toCsvRow() {
    final leftStr = leftPlateForces.join(',');
    final rightStr = rightPlateForces.join(',');
    return '$timestamp,$leftStr,$rightStr,$samplingRate,$sampleIndex';
  }

  static String getCsvHeader() {
    return 'timestamp,left1,left2,left3,left4,right1,right2,right3,right4,samplingRate,sampleIndex';
  }

  // Mock data oluşturma için factory
  factory ForceDataModel.mock({
    DateTime? timestamp,
    double? totalForce,
    int? index,
  }) {
    final now = timestamp ?? DateTime.now();
    final baseForce = totalForce ?? 800.0; // Varsayılan vücut ağırlığı
    
    // Her load cell için rastgele ama gerçekçi değerler
    final leftForces = List.generate(4, (i) => 
      baseForce / 8 + (i * 5) + (DateTime.now().millisecond % 20) - 10);
    final rightForces = List.generate(4, (i) => 
      baseForce / 8 + (i * 5) + (DateTime.now().millisecond % 20) - 10);

    return ForceDataModel(
      timestamp: now.toIso8601String(),
      leftPlateForces: leftForces,
      rightPlateForces: rightForces,
      samplingRate: 1000.0,
      sampleIndex: index ?? 0,
    );
  }
}