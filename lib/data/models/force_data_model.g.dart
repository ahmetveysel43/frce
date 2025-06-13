// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'force_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForceDataModel _$ForceDataModelFromJson(Map<String, dynamic> json) =>
    ForceDataModel(
      id: (json['id'] as num?)?.toInt(),
      sessionId: json['session_id'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      leftGRF: (json['left_grf'] as num).toDouble(),
      rightGRF: (json['right_grf'] as num).toDouble(),
      totalGRF: (json['total_grf'] as num).toDouble(),
      leftCopX: (json['left_cop_x'] as num?)?.toDouble(),
      leftCopY: (json['left_cop_y'] as num?)?.toDouble(),
      rightCopX: (json['right_cop_x'] as num?)?.toDouble(),
      rightCopY: (json['right_cop_y'] as num?)?.toDouble(),
      loadCell1: (json['load_cell_1'] as num?)?.toDouble(),
      loadCell2: (json['load_cell_2'] as num?)?.toDouble(),
      loadCell3: (json['load_cell_3'] as num?)?.toDouble(),
      loadCell4: (json['load_cell_4'] as num?)?.toDouble(),
      loadCell5: (json['load_cell_5'] as num?)?.toDouble(),
      loadCell6: (json['load_cell_6'] as num?)?.toDouble(),
      loadCell7: (json['load_cell_7'] as num?)?.toDouble(),
      loadCell8: (json['load_cell_8'] as num?)?.toDouble(),
      asymmetryIndex: (json['asymmetry_index'] as num?)?.toDouble(),
      combinedCopX: (json['combined_cop_x'] as num?)?.toDouble(),
      combinedCopY: (json['combined_cop_y'] as num?)?.toDouble(),
      isValid: json['is_valid'] as bool? ?? true,
      noiseLevel: (json['noise_level'] as num?)?.toDouble(),
      calibrationApplied: json['calibration_applied'] as bool? ?? false,
      sampleRate: (json['sample_rate'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ForceDataModelToJson(ForceDataModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'timestamp': instance.timestamp,
      'left_grf': instance.leftGRF,
      'right_grf': instance.rightGRF,
      'total_grf': instance.totalGRF,
      'left_cop_x': instance.leftCopX,
      'left_cop_y': instance.leftCopY,
      'right_cop_x': instance.rightCopX,
      'right_cop_y': instance.rightCopY,
      'load_cell_1': instance.loadCell1,
      'load_cell_2': instance.loadCell2,
      'load_cell_3': instance.loadCell3,
      'load_cell_4': instance.loadCell4,
      'load_cell_5': instance.loadCell5,
      'load_cell_6': instance.loadCell6,
      'load_cell_7': instance.loadCell7,
      'load_cell_8': instance.loadCell8,
      'asymmetry_index': instance.asymmetryIndex,
      'combined_cop_x': instance.combinedCopX,
      'combined_cop_y': instance.combinedCopY,
      'is_valid': instance.isValid,
      'noise_level': instance.noiseLevel,
      'calibration_applied': instance.calibrationApplied,
      'sample_rate': instance.sampleRate,
      'created_at': instance.createdAt?.toIso8601String(),
    };
