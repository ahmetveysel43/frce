// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestResultModel _$TestResultModelFromJson(Map<String, dynamic> json) =>
    TestResultModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      athleteId: json['athlete_id'] as String,
      testType: json['test_type'] as String,
      testDate: DateTime.parse(json['test_date'] as String),
      durationMs: (json['duration_ms'] as num).toInt(),
      status: json['status'] as String,
      metrics: (json['metrics'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      qualityScore: (json['quality_score'] as num?)?.toDouble(),
      isArchived: json['is_archived'] as bool? ?? false,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      phaseData: json['phase_data'] as Map<String, dynamic>?,
      comparisonData: json['comparison_data'] as Map<String, dynamic>?,
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      rawDataFile: json['raw_data_file'] as String?,
      reportFile: json['report_file'] as String?,
      videoFile: json['video_file'] as String?,
      externalId: json['external_id'] as String?,
      syncStatus: json['sync_status'] as String?,
      lastSyncedAt: json['last_synced_at'] == null
          ? null
          : DateTime.parse(json['last_synced_at'] as String),
    );

Map<String, dynamic> _$TestResultModelToJson(TestResultModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'athlete_id': instance.athleteId,
      'test_type': instance.testType,
      'test_date': instance.testDate.toIso8601String(),
      'duration_ms': instance.durationMs,
      'status': instance.status,
      'metrics': instance.metrics,
      'metadata': instance.metadata,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'quality_score': instance.qualityScore,
      'is_archived': instance.isArchived,
      'tags': instance.tags,
      'phase_data': instance.phaseData,
      'comparison_data': instance.comparisonData,
      'recommendations': instance.recommendations,
      'raw_data_file': instance.rawDataFile,
      'report_file': instance.reportFile,
      'video_file': instance.videoFile,
      'external_id': instance.externalId,
      'sync_status': instance.syncStatus,
      'last_synced_at': instance.lastSyncedAt?.toIso8601String(),
    };

TestComparisonModel _$TestComparisonModelFromJson(Map<String, dynamic> json) =>
    TestComparisonModel(
      id: json['id'] as String,
      currentTestId: json['current_test_id'] as String,
      previousTestId: json['previous_test_id'] as String,
      comparisonType: json['comparison_type'] as String,
      improvements: (json['improvements'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TestComparisonModelToJson(
        TestComparisonModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'current_test_id': instance.currentTestId,
      'previous_test_id': instance.previousTestId,
      'comparison_type': instance.comparisonType,
      'improvements': instance.improvements,
      'summary': instance.summary,
      'created_at': instance.createdAt.toIso8601String(),
    };
