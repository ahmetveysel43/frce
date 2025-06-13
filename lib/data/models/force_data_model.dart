import 'package:json_annotation/json_annotation.dart';
import 'dart:math' as math;
import '../../domain/entities/force_data.dart';

part 'force_data_model.g.dart';

/// Kuvvet verisi data model - Database ve API mapping için
@JsonSerializable()
class ForceDataModel {
  @JsonKey(name: 'id')
  final int? id; // Database auto-increment ID
  
  @JsonKey(name: 'session_id')
  final String sessionId;
  
  @JsonKey(name: 'timestamp')
  final int timestamp; // milliseconds since epoch
  
  @JsonKey(name: 'left_grf')
  final double leftGRF; // Ground Reaction Force - Sol (N)
  
  @JsonKey(name: 'right_grf')
  final double rightGRF; // Ground Reaction Force - Sağ (N)
  
  @JsonKey(name: 'total_grf')
  final double totalGRF; // Toplam kuvvet (N)
  
  @JsonKey(name: 'left_cop_x')
  final double? leftCopX; // Center of Pressure X - Sol (mm)
  
  @JsonKey(name: 'left_cop_y')
  final double? leftCopY; // Center of Pressure Y - Sol (mm)
  
  @JsonKey(name: 'right_cop_x')
  final double? rightCopX; // Center of Pressure X - Sağ (mm)
  
  @JsonKey(name: 'right_cop_y')
  final double? rightCopY; // Center of Pressure Y - Sağ (mm)
  
  // Raw load cell data (8 sensors - 4 per platform)
  @JsonKey(name: 'load_cell_1')
  final double? loadCell1; // Sol platform - ön sol
  
  @JsonKey(name: 'load_cell_2')
  final double? loadCell2; // Sol platform - ön sağ
  
  @JsonKey(name: 'load_cell_3')
  final double? loadCell3; // Sol platform - arka sol
  
  @JsonKey(name: 'load_cell_4')
  final double? loadCell4; // Sol platform - arka sağ
  
  @JsonKey(name: 'load_cell_5')
  final double? loadCell5; // Sağ platform - ön sol
  
  @JsonKey(name: 'load_cell_6')
  final double? loadCell6; // Sağ platform - ön sağ
  
  @JsonKey(name: 'load_cell_7')
  final double? loadCell7; // Sağ platform - arka sol
  
  @JsonKey(name: 'load_cell_8')
  final double? loadCell8; // Sağ platform - arka sağ
  
  // Calculated fields
  @JsonKey(name: 'asymmetry_index')
  final double? asymmetryIndex; // Precalculated for performance
  
  @JsonKey(name: 'combined_cop_x')
  final double? combinedCopX; // Combined COP X
  
  @JsonKey(name: 'combined_cop_y')
  final double? combinedCopY; // Combined COP Y
  
  // Quality flags
  @JsonKey(name: 'is_valid')
  final bool isValid; // Data quality flag
  
  @JsonKey(name: 'noise_level')
  final double? noiseLevel; // Signal noise level
  
  @JsonKey(name: 'calibration_applied')
  final bool calibrationApplied; // Kalibrasyon uygulandı mı
  
  // Metadata
  @JsonKey(name: 'sample_rate')
  final int? sampleRate; // Hz
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const ForceDataModel({
    this.id,
    required this.sessionId,
    required this.timestamp,
    required this.leftGRF,
    required this.rightGRF,
    required this.totalGRF,
    this.leftCopX,
    this.leftCopY,
    this.rightCopX,
    this.rightCopY,
    this.loadCell1,
    this.loadCell2,
    this.loadCell3,
    this.loadCell4,
    this.loadCell5,
    this.loadCell6,
    this.loadCell7,
    this.loadCell8,
    this.asymmetryIndex,
    this.combinedCopX,
    this.combinedCopY,
    this.isValid = true,
    this.noiseLevel,
    this.calibrationApplied = false,
    this.sampleRate,
    this.createdAt,
  });

  /// JSON'dan model oluştur
  factory ForceDataModel.fromJson(Map<String, dynamic> json) => _$ForceDataModelFromJson(json);

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() => _$ForceDataModelToJson(this);

  /// Database map'inden model oluştur
  factory ForceDataModel.fromMap(Map<String, dynamic> map) {
    return ForceDataModel(
      id: map['id'] as int?,
      sessionId: map['sessionId'] as String,
      timestamp: map['timestamp'] as int,
      leftGRF: map['leftGRF'] as double,
      rightGRF: map['rightGRF'] as double,
      totalGRF: map['totalGRF'] as double,
      leftCopX: map['leftCOP_x'] as double?,
      leftCopY: map['leftCOP_y'] as double?,
      rightCopX: map['rightCOP_x'] as double?,
      rightCopY: map['rightCOP_y'] as double?,
      loadCell1: map['loadCell1'] as double?,
      loadCell2: map['loadCell2'] as double?,
      loadCell3: map['loadCell3'] as double?,
      loadCell4: map['loadCell4'] as double?,
      loadCell5: map['loadCell5'] as double?,
      loadCell6: map['loadCell6'] as double?,
      loadCell7: map['loadCell7'] as double?,
      loadCell8: map['loadCell8'] as double?,
      asymmetryIndex: map['asymmetryIndex'] as double?,
      combinedCopX: map['combinedCOP_x'] as double?,
      combinedCopY: map['combinedCOP_y'] as double?,
      isValid: (map['isValid'] as int?) == 1,
      noiseLevel: map['noiseLevel'] as double?,
      calibrationApplied: (map['calibrationApplied'] as int?) == 1,
      sampleRate: map['sampleRate'] as int?,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  /// Model'i database map'ine çevir
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sessionId': sessionId,
      'timestamp': timestamp,
      'leftGRF': leftGRF,
      'rightGRF': rightGRF,
      'totalGRF': totalGRF,
      'leftCOP_x': leftCopX,
      'leftCOP_y': leftCopY,
      'rightCOP_x': rightCopX,
      'rightCOP_y': rightCopY,
      'loadCell1': loadCell1,
      'loadCell2': loadCell2,
      'loadCell3': loadCell3,
      'loadCell4': loadCell4,
      'loadCell5': loadCell5,
      'loadCell6': loadCell6,
      'loadCell7': loadCell7,
      'loadCell8': loadCell8,
      'asymmetryIndex': asymmetryIndex,
      'combinedCOP_x': combinedCopX,
      'combinedCOP_y': combinedCopY,
      'isValid': isValid ? 1 : 0,
      'noiseLevel': noiseLevel,
      'calibrationApplied': calibrationApplied ? 1 : 0,
      'sampleRate': sampleRate,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Domain entity'den model oluştur
  factory ForceDataModel.fromEntity(ForceData entity, String sessionId) {
    return ForceDataModel(
      sessionId: sessionId,
      timestamp: entity.timestamp,
      leftGRF: entity.leftGRF,
      rightGRF: entity.rightGRF,
      totalGRF: entity.totalGRF,
      leftCopX: entity.leftCopX,
      leftCopY: entity.leftCopY,
      rightCopX: entity.rightCopX,
      rightCopY: entity.rightCopY,
      asymmetryIndex: entity.asymmetryIndex,
      combinedCopX: entity.combinedCOP?.x,
      combinedCopY: entity.combinedCOP?.y,
      isValid: true,
      calibrationApplied: true,
      createdAt: DateTime.now(),
    );
  }

  /// Model'i domain entity'ye çevir
  ForceData toEntity() {
    return ForceData(
      timestamp: timestamp,
      leftGRF: leftGRF,
      rightGRF: rightGRF,
      totalGRF: totalGRF,
      leftCopX: leftCopX,
      leftCopY: leftCopY,
      rightCopX: rightCopX,
      rightCopY: rightCopY,
    );
  }

  /// Raw load cell verilerinden model oluştur
  factory ForceDataModel.fromLoadCells({
    required String sessionId,
    required int timestamp,
    required List<double> loadCellValues, // 8 değer
    double platformWidth = 400.0, // mm
    double platformLength = 600.0, // mm
    List<double>? zeroOffsets, // Kalibrasyon offset'leri
    int? sampleRate,
  }) {
    assert(loadCellValues.length == 8, 'Load cell değerleri 8 adet olmalı');

    // Kalibrasyon uygula
    final calibratedValues = zeroOffsets != null
        ? List.generate(8, (i) => loadCellValues[i] - (zeroOffsets.length > i ? zeroOffsets[i] : 0))
        : loadCellValues;

    // Sol platform (0-3) ve sağ platform (4-7)
    final leftValues = calibratedValues.sublist(0, 4);
    final rightValues = calibratedValues.sublist(4, 8);

    final leftGRF = leftValues.fold(0.0, (sum, val) => sum + math.max(0, val));
    final rightGRF = rightValues.fold(0.0, (sum, val) => sum + math.max(0, val));
    final totalGRF = leftGRF + rightGRF;

    // COP hesaplama
    final leftCOP = _calculateCOP(leftValues, platformWidth, platformLength);
    final rightCOP = _calculateCOP(rightValues, platformWidth, platformLength);

    // Combined COP hesaplama
    final combinedCOP = totalGRF > 0 
        ? _calculateCombinedCOP(leftGRF, rightGRF, leftCOP, rightCOP)
        : null;

    // Asimetri hesaplama
    final asymmetry = totalGRF > 0 
        ? ((leftGRF - rightGRF).abs() / totalGRF) * 100
        : 0.0;

    // Noise level hesaplama (basit varyans)
    final noiseLevel = _calculateNoiseLevel(calibratedValues);

    return ForceDataModel(
      sessionId: sessionId,
      timestamp: timestamp,
      leftGRF: leftGRF,
      rightGRF: rightGRF,
      totalGRF: totalGRF,
      leftCopX: leftCOP.x,
      leftCopY: leftCOP.y,
      rightCopX: rightCOP.x,
      rightCopY: rightCOP.y,
      loadCell1: calibratedValues[0],
      loadCell2: calibratedValues[1],
      loadCell3: calibratedValues[2],
      loadCell4: calibratedValues[3],
      loadCell5: calibratedValues[4],
      loadCell6: calibratedValues[5],
      loadCell7: calibratedValues[6],
      loadCell8: calibratedValues[7],
      asymmetryIndex: asymmetry,
      combinedCopX: combinedCOP?.x,
      combinedCopY: combinedCOP?.y,
      isValid: _validateData(calibratedValues, totalGRF),
      noiseLevel: noiseLevel,
      calibrationApplied: zeroOffsets != null,
      sampleRate: sampleRate,
      createdAt: DateTime.now(),
    );
  }

  /// COP hesaplama helper
  static ({double x, double y}) _calculateCOP(
    List<double> forces,
    double width,
    double length,
  ) {
    // Load cell pozisyonları (platform merkezine göre mm)
    final positions = [
      (-width/2, -length/2), // Sol ön
      (width/2, -length/2),  // Sağ ön
      (-width/2, length/2),  // Sol arka
      (width/2, length/2),   // Sağ arka
    ];

    final totalForce = forces.fold(0.0, (sum, f) => sum + math.max(0, f));
    if (totalForce <= 0) return (x: 0.0, y: 0.0);

    double copX = 0;
    double copY = 0;

    for (int i = 0; i < 4; i++) {
      final force = math.max(0, forces[i]);
      copX += force * positions[i].$1;
      copY += force * positions[i].$2;
    }

    return (x: copX / totalForce, y: copY / totalForce);
  }

  /// Combined COP hesaplama
  static ({double x, double y})? _calculateCombinedCOP(
    double leftGRF,
    double rightGRF,
    ({double x, double y}) leftCOP,
    ({double x, double y}) rightCOP,
  ) {
    final totalForce = leftGRF + rightGRF;
    if (totalForce <= 0) return null;

    // Platform arası mesafe (örnek: 100mm)
    const platformGap = 100.0;
    
    // Sol platform COP'u sol koordinat sisteminde
    final leftcopGlobalX = leftCOP.x - platformGap/2;
    final leftcopGlobalY = leftCOP.y;
    
    // Sağ platform COP'u global koordinat sisteminde
    final rightcopGlobalX = rightCOP.x + platformGap/2;
    final rightcopGlobalY = rightCOP.y;

    // Weighted average
    final combinedX = (leftcopGlobalX * leftGRF + rightcopGlobalX * rightGRF) / totalForce;
    final combinedY = (leftcopGlobalY * leftGRF + rightcopGlobalY * rightGRF) / totalForce;

    return (x: combinedX, y: combinedY);
  }

  /// Noise level hesaplama
  static double _calculateNoiseLevel(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.fold(0.0, (sum, val) => sum + val) / values.length;
    final variance = values
        .map((val) => (val - mean) * (val - mean))
        .fold(0.0, (sum, val) => sum + val) / values.length;
    
    return math.sqrt(variance);
  }

  /// Data validation
  static bool _validateData(List<double> loadCellValues, double totalForce) {
    // Negatif değer kontrolü
    if (loadCellValues.any((val) => val < -50)) return false; // -50N tolerance
    
    // Aşırı yüksek değer kontrolü
    if (loadCellValues.any((val) => val > 5000)) return false; // 5000N max
    
    // Total force makul aralıkta mı
    if (totalForce > 10000) return false; // 10kN max
    
    // Load cell'ler arası makul dağılım var mı
    final maxLoadCell = loadCellValues.fold(0.0, (max, val) => math.max(max, val));
    if (maxLoadCell > totalForce * 0.8) return false; // Tek load cell toplam kuvvetin %80'inden fazla olamaz
    
    return true;
  }

  /// Copy with
  ForceDataModel copyWith({
    int? id,
    String? sessionId,
    int? timestamp,
    double? leftGRF,
    double? rightGRF,
    double? totalGRF,
    double? leftCopX,
    double? leftCopY,
    double? rightCopX,
    double? rightCopY,
    double? loadCell1,
    double? loadCell2,
    double? loadCell3,
    double? loadCell4,
    double? loadCell5,
    double? loadCell6,
    double? loadCell7,
    double? loadCell8,
    double? asymmetryIndex,
    double? combinedCopX,
    double? combinedCopY,
    bool? isValid,
    double? noiseLevel,
    bool? calibrationApplied,
    int? sampleRate,
    DateTime? createdAt,
  }) {
    return ForceDataModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      leftGRF: leftGRF ?? this.leftGRF,
      rightGRF: rightGRF ?? this.rightGRF,
      totalGRF: totalGRF ?? this.totalGRF,
      leftCopX: leftCopX ?? this.leftCopX,
      leftCopY: leftCopY ?? this.leftCopY,
      rightCopX: rightCopX ?? this.rightCopX,
      rightCopY: rightCopY ?? this.rightCopY,
      loadCell1: loadCell1 ?? this.loadCell1,
      loadCell2: loadCell2 ?? this.loadCell2,
      loadCell3: loadCell3 ?? this.loadCell3,
      loadCell4: loadCell4 ?? this.loadCell4,
      loadCell5: loadCell5 ?? this.loadCell5,
      loadCell6: loadCell6 ?? this.loadCell6,
      loadCell7: loadCell7 ?? this.loadCell7,
      loadCell8: loadCell8 ?? this.loadCell8,
      asymmetryIndex: asymmetryIndex ?? this.asymmetryIndex,
      combinedCopX: combinedCopX ?? this.combinedCopX,
      combinedCopY: combinedCopY ?? this.combinedCopY,
      isValid: isValid ?? this.isValid,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      calibrationApplied: calibrationApplied ?? this.calibrationApplied,
      sampleRate: sampleRate ?? this.sampleRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Load cell array getter
  List<double> get loadCellValues => [
    loadCell1 ?? 0,
    loadCell2 ?? 0,
    loadCell3 ?? 0,
    loadCell4 ?? 0,
    loadCell5 ?? 0,
    loadCell6 ?? 0,
    loadCell7 ?? 0,
    loadCell8 ?? 0,
  ];

  /// Sol platform load cell'leri
  List<double> get leftLoadCells => loadCellValues.sublist(0, 4);

  /// Sağ platform load cell'leri
  List<double> get rightLoadCells => loadCellValues.sublist(4, 8);

  /// Data quality score (0-100)
  double get qualityScore {
    double score = 100.0;
    
    if (!isValid) score -= 50;
    if (noiseLevel != null && noiseLevel! > 10) score -= 20;
    if (!calibrationApplied) score -= 15;
    if (totalGRF <= 0) score -= 30;
    
    return math.max(0, score);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForceDataModel &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(sessionId, timestamp);

  @override
  String toString() {
    return 'ForceDataModel{session: $sessionId, t: ${timestamp}ms, L: ${leftGRF.toStringAsFixed(1)}N, R: ${rightGRF.toStringAsFixed(1)}N, Total: ${totalGRF.toStringAsFixed(1)}N}';
  }
}

/// Batch force data operations için helper class
class ForceDataBatch {
  final List<ForceDataModel> data;
  final String sessionId;
  final DateTime startTime;
  final DateTime endTime;
  final int sampleCount;
  final double avgSampleRate;

  const ForceDataBatch({
    required this.data,
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.sampleCount,
    required this.avgSampleRate,
  });

  factory ForceDataBatch.fromModels(List<ForceDataModel> models) {
    if (models.isEmpty) {
      throw ArgumentError('Force data list cannot be empty');
    }

    final sessionId = models.first.sessionId;
    final timestamps = models.map((m) => m.timestamp).toList()..sort();
    
    final startTime = DateTime.fromMillisecondsSinceEpoch(timestamps.first);
    final endTime = DateTime.fromMillisecondsSinceEpoch(timestamps.last);
    
    final duration = endTime.difference(startTime).inMilliseconds;
    final avgSampleRate = duration > 0 ? (models.length * 1000.0) / duration : 0.0;

    return ForceDataBatch(
      data: models,
      sessionId: sessionId,
      startTime: startTime,
      endTime: endTime,
      sampleCount: models.length,
      avgSampleRate: avgSampleRate,
    );
  }

  /// Batch'i database map'lerine çevir
  List<Map<String, dynamic>> toMapList() {
    return data.map((model) => model.toMap()).toList();
  }

  /// Geçerli data'ları filtrele
  ForceDataBatch get validDataOnly {
    final validData = data.where((model) => model.isValid).toList();
    return ForceDataBatch.fromModels(validData);
  }

  /// Downsample (performans için)
  ForceDataBatch downsample(int factor) {
    if (factor <= 1) return this;
    
    final downsampled = <ForceDataModel>[];
    for (int i = 0; i < data.length; i += factor) {
      downsampled.add(data[i]);
    }
    
    return ForceDataBatch.fromModels(downsampled);
  }

  /// Kalite istatistikleri
  Map<String, dynamic> get qualityStats {
    final validCount = data.where((m) => m.isValid).length;
    final calibratedCount = data.where((m) => m.calibrationApplied).length;
    final avgQuality = data.map((m) => m.qualityScore).fold(0.0, (sum, q) => sum + q) / data.length;
    
    return {
      'totalSamples': data.length,
      'validSamples': validCount,
      'validPercentage': (validCount / data.length) * 100,
      'calibratedSamples': calibratedCount,
      'avgQualityScore': avgQuality,
    };
  }
}