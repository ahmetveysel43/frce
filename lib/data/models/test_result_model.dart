import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/test_result.dart';
import 'package:flutter/material.dart'; // ✅ DateTimeRange için

part 'test_result_model.g.dart';

/// Test sonucu data model - Database ve API mapping için
@JsonSerializable()
class TestResultModel {
  @JsonKey(name: 'id')
  final String id;
  
  @JsonKey(name: 'session_id')
  final String sessionId;
  
  @JsonKey(name: 'athlete_id')
  final String athleteId;
  
  @JsonKey(name: 'test_type')
  final String testType; // enum string representation
  
  @JsonKey(name: 'test_date')
  final DateTime testDate;
  
  @JsonKey(name: 'duration_ms')
  final int durationMs; // milliseconds
  
  @JsonKey(name: 'status')
  final String status; // enum string representation
  
  @JsonKey(name: 'metrics')
  final Map<String, double> metrics;
  
  @JsonKey(name: 'metadata')
  final Map<String, dynamic>? metadata;
  
  @JsonKey(name: 'notes')
  final String? notes;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  // Database specific fields
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  
  @JsonKey(name: 'quality_score')
  final double? qualityScore; // Precalculated quality (0-100)
  
  @JsonKey(name: 'is_archived')
  final bool isArchived;
  
  @JsonKey(name: 'tags')
  final List<String> tags; // Etiketler (baseline, post-injury, etc.)
  
  // Analysis results
  @JsonKey(name: 'phase_data')
  final Map<String, dynamic>? phaseData; // Jump phases, balance periods
  
  @JsonKey(name: 'comparison_data')
  final Map<String, dynamic>? comparisonData; // Previous test comparisons
  
  @JsonKey(name: 'recommendations')
  final List<String>? recommendations; // AI/Algorithm recommendations
  
  // File references
  @JsonKey(name: 'raw_data_file')
  final String? rawDataFile; // Force data file path
  
  @JsonKey(name: 'report_file')
  final String? reportFile; // PDF report file path
  
  @JsonKey(name: 'video_file')
  final String? videoFile; // Video analysis file path
  
  // External sync
  @JsonKey(name: 'external_id')
  final String? externalId; // Cloud/external system ID
  
  @JsonKey(name: 'sync_status')
  final String? syncStatus; // pending, synced, failed
  
  @JsonKey(name: 'last_synced_at')
  final DateTime? lastSyncedAt;

  const TestResultModel({
    required this.id,
    required this.sessionId,
    required this.athleteId,
    required this.testType,
    required this.testDate,
    required this.durationMs,
    required this.status,
    required this.metrics,
    this.metadata,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.qualityScore,
    this.isArchived = false,
    this.tags = const [],
    this.phaseData,
    this.comparisonData,
    this.recommendations,
    this.rawDataFile,
    this.reportFile,
    this.videoFile,
    this.externalId,
    this.syncStatus,
    this.lastSyncedAt,
  });

  /// JSON'dan model oluştur
  factory TestResultModel.fromJson(Map<String, dynamic> json) => _$TestResultModelFromJson(json);

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() => _$TestResultModelToJson(this);

  /// Database map'inden model oluştur
  factory TestResultModel.fromMap(Map<String, dynamic> map) {
    return TestResultModel(
      id: map['id'] as String,
      sessionId: map['sessionId'] as String,
      athleteId: map['athleteId'] as String,
      testType: map['testType'] as String,
      testDate: DateTime.parse(map['testDate'] as String),
      durationMs: map['durationMs'] as int,
      status: map['status'] as String,
      metrics: Map<String, double>.from(
        map['metrics'] is String 
            ? jsonDecode(map['metrics'] as String)
            : map['metrics'] as Map<String, dynamic>
      ),
      metadata: map['metadata'] != null
          ? (map['metadata'] is String
              ? jsonDecode(map['metadata'] as String)
              : map['metadata'] as Map<String, dynamic>)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      qualityScore: map['qualityScore'] as double?,
      isArchived: (map['isArchived'] as int?) == 1,
      tags: map['tags'] != null
          ? (map['tags'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      phaseData: map['phaseData'] != null
          ? (map['phaseData'] is String
              ? jsonDecode(map['phaseData'] as String)
              : map['phaseData'] as Map<String, dynamic>)
          : null,
      comparisonData: map['comparisonData'] != null
          ? (map['comparisonData'] is String
              ? jsonDecode(map['comparisonData'] as String)
              : map['comparisonData'] as Map<String, dynamic>)
          : null,
      recommendations: map['recommendations'] != null
          ? (map['recommendations'] as String).split('|').where((s) => s.isNotEmpty).toList()
          : null,
      rawDataFile: map['rawDataFile'] as String?,
      reportFile: map['reportFile'] as String?,
      videoFile: map['videoFile'] as String?,
      externalId: map['externalId'] as String?,
      syncStatus: map['syncStatus'] as String?,
      lastSyncedAt: map['lastSyncedAt'] != null 
          ? DateTime.parse(map['lastSyncedAt'] as String)
          : null,
    );
  }

  /// Model'i database map'ine çevir
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'athleteId': athleteId,
      'testType': testType,
      'testDate': testDate.toIso8601String(),
      'durationMs': durationMs,
      'status': status,
      'metrics': jsonEncode(metrics),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'qualityScore': qualityScore,
      'isArchived': isArchived ? 1 : 0,
      'tags': tags.join(','),
      'phaseData': phaseData != null ? jsonEncode(phaseData) : null,
      'comparisonData': comparisonData != null ? jsonEncode(comparisonData) : null,
      'recommendations': recommendations?.join('|'),
      'rawDataFile': rawDataFile,
      'reportFile': reportFile,
      'videoFile': videoFile,
      'externalId': externalId,
      'syncStatus': syncStatus,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  /// Domain entity'den model oluştur
  factory TestResultModel.fromEntity(TestResult entity) {
    return TestResultModel(
      id: entity.id,
      sessionId: entity.sessionId,
      athleteId: entity.athleteId,
      testType: entity.testType.name,
      testDate: entity.testDate,
      durationMs: entity.duration.inMilliseconds,
      status: entity.status.name,
      metrics: Map.from(entity.metrics),
      metadata: entity.metadata != null ? Map.from(entity.metadata!) : null,
      notes: entity.notes,
      createdAt: entity.createdAt,
      qualityScore: entity.qualityScore,
    );
  }

  /// Model'i domain entity'ye çevir
  TestResult toEntity() {
    return TestResult(
      id: id,
      sessionId: sessionId,
      athleteId: athleteId,
      testType: TestType.values.firstWhere((e) => e.name == testType),
      testDate: testDate,
      duration: Duration(milliseconds: durationMs),
      status: TestStatus.values.firstWhere((e) => e.name == status),
      metrics: Map.from(metrics),
      metadata: metadata != null ? Map.from(metadata!) : null,
      notes: notes,
      createdAt: createdAt,
    );
  }

  /// Enhanced model with additional data
  factory TestResultModel.enhanced({
    required TestResult entity,
    double? qualityScore,
    List<String> tags = const [],
    Map<String, dynamic>? phaseData,
    Map<String, dynamic>? comparisonData,
    List<String>? recommendations,
    String? rawDataFile,
    String? reportFile,
  }) {
    return TestResultModel(
      id: entity.id,
      sessionId: entity.sessionId,
      athleteId: entity.athleteId,
      testType: entity.testType.name,
      testDate: entity.testDate,
      durationMs: entity.duration.inMilliseconds,
      status: entity.status.name,
      metrics: Map.from(entity.metrics),
      metadata: entity.metadata != null ? Map.from(entity.metadata!) : null,
      notes: entity.notes,
      createdAt: entity.createdAt,
      qualityScore: qualityScore ?? entity.qualityScore,
      tags: tags,
      phaseData: phaseData,
      comparisonData: comparisonData,
      recommendations: recommendations,
      rawDataFile: rawDataFile,
      reportFile: reportFile,
    );
  }

  /// Copy with
  TestResultModel copyWith({
    String? id,
    String? sessionId,
    String? athleteId,
    String? testType,
    DateTime? testDate,
    int? durationMs,
    String? status,
    Map<String, double>? metrics,
    Map<String, dynamic>? metadata,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? qualityScore,
    bool? isArchived,
    List<String>? tags,
    Map<String, dynamic>? phaseData,
    Map<String, dynamic>? comparisonData,
    List<String>? recommendations,
    String? rawDataFile,
    String? reportFile,
    String? videoFile,
    String? externalId,
    String? syncStatus,
    DateTime? lastSyncedAt,
  }) {
    return TestResultModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      athleteId: athleteId ?? this.athleteId,
      testType: testType ?? this.testType,
      testDate: testDate ?? this.testDate,
      durationMs: durationMs ?? this.durationMs,
      status: status ?? this.status,
      metrics: metrics ?? Map.from(this.metrics),
      metadata: metadata ?? (this.metadata != null ? Map.from(this.metadata!) : null),
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      qualityScore: qualityScore ?? this.qualityScore,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? List.from(this.tags),
      phaseData: phaseData ?? (this.phaseData != null ? Map.from(this.phaseData!) : null),
      comparisonData: comparisonData ?? (this.comparisonData != null ? Map.from(this.comparisonData!) : null),
      recommendations: recommendations ?? (this.recommendations != null ? List.from(this.recommendations!) : null),
      rawDataFile: rawDataFile ?? this.rawDataFile,
      reportFile: reportFile ?? this.reportFile,
      videoFile: videoFile ?? this.videoFile,
      externalId: externalId ?? this.externalId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  /// Duration helper
  Duration get duration => Duration(milliseconds: durationMs);

  /// Test type enum
  TestType get testTypeEnum => TestType.values.firstWhere((e) => e.name == testType);

  /// Status enum
  TestStatus get statusEnum => TestStatus.values.firstWhere((e) => e.name == status);

  /// Primary metric helper
  double? getPrimaryMetric() {
    switch (testTypeEnum) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        return metrics['jumpHeight'];
      case TestType.isometricMidThighPull:
      case TestType.isometricSquat:
        return metrics['peakForce'];
      case TestType.staticBalance:
      case TestType.singleLegBalance:
        return metrics['stabilityIndex'];
      default:
        return metrics.values.isNotEmpty ? metrics.values.first : null;
    }
  }

  /// Quality assessment
  TestQuality get quality {
    final score = qualityScore ?? 0;
    if (score >= 90) return TestQuality.excellent;
    if (score >= 75) return TestQuality.good;
    if (score >= 60) return TestQuality.fair;
    if (score >= 40) return TestQuality.poor;
    return TestQuality.invalid;
  }

  /// File attachments count
  int get attachmentCount {
    int count = 0;
    if (rawDataFile != null) count++;
    if (reportFile != null) count++;
    if (videoFile != null) count++;
    return count;
  }

  /// Sync status check
  bool get needsSync => syncStatus == null || syncStatus == 'pending' || syncStatus == 'failed';
  bool get isSynced => syncStatus == 'synced';

  /// Has analysis data
  bool get hasPhaseData => phaseData != null && phaseData!.isNotEmpty;
  bool get hasComparisonData => comparisonData != null && comparisonData!.isNotEmpty;
  bool get hasRecommendations => recommendations != null && recommendations!.isNotEmpty;

  /// Tag management helpers
  bool hasTag(String tag) => tags.contains(tag);
  
  TestResultModel addTag(String tag) {
    if (hasTag(tag)) return this;
    return copyWith(tags: [...tags, tag]);
  }
  
  TestResultModel removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toList());
  }

  /// Archive/unarchive
  TestResultModel archive() => copyWith(isArchived: true, updatedAt: DateTime.now());
  TestResultModel unarchive() => copyWith(isArchived: false, updatedAt: DateTime.now());

  /// Update sync status
  TestResultModel markSynced(String externalId) => copyWith(
    syncStatus: 'synced',
    externalId: externalId,
    lastSyncedAt: DateTime.now(),
  );

  TestResultModel markSyncFailed() => copyWith(
    syncStatus: 'failed',
    lastSyncedAt: DateTime.now(),
  );

  /// Validation
  bool get isValid {
    return id.isNotEmpty &&
           sessionId.isNotEmpty &&
           athleteId.isNotEmpty &&
           testType.isNotEmpty &&
           durationMs > 0 &&
           metrics.isNotEmpty;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('ID boş olamaz');
    if (sessionId.isEmpty) errors.add('Session ID boş olamaz');
    if (athleteId.isEmpty) errors.add('Athlete ID boş olamaz');
    if (testType.isEmpty) errors.add('Test türü boş olamaz');
    if (durationMs <= 0) errors.add('Test süresi pozitif olmalı');
    if (metrics.isEmpty) errors.add('Metrikler boş olamaz');
    
    // Test type specific validation
    switch (testTypeEnum) {
      case TestType.counterMovementJump:
        if (!metrics.containsKey('jumpHeight')) {
          errors.add('CMJ için sıçrama yüksekliği gerekli');
        }
        break;
      case TestType.isometricMidThighPull:
        if (!metrics.containsKey('peakForce')) {
          errors.add('IMTP için tepe kuvvet gerekli');
        }
        break;
      default:
        break;
    }
    
    return errors;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestResultModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TestResultModel{id: $id, type: $testType, athlete: $athleteId, '
           'quality: ${quality.turkishName}, metrics: ${metrics.length}}';
  }
}

/// Test comparison model
@JsonSerializable()
class TestComparisonModel {
  @JsonKey(name: 'id')
  final String id;
  
  @JsonKey(name: 'current_test_id')
  final String currentTestId;
  
  @JsonKey(name: 'previous_test_id')
  final String previousTestId;
  
  @JsonKey(name: 'comparison_type')
  final String comparisonType; // baseline, previous, best, target
  
  @JsonKey(name: 'improvements')
  final Map<String, double> improvements; // percentage changes
  
  @JsonKey(name: 'summary')
  final String summary; // overall improvement summary
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const TestComparisonModel({
    required this.id,
    required this.currentTestId,
    required this.previousTestId,
    required this.comparisonType,
    required this.improvements,
    required this.summary,
    required this.createdAt,
  });

  factory TestComparisonModel.fromJson(Map<String, dynamic> json) => _$TestComparisonModelFromJson(json);
  Map<String, dynamic> toJson() => _$TestComparisonModelToJson(this);

  factory TestComparisonModel.fromTestResults(
    TestResultModel current,
    TestResultModel previous,
    String comparisonType,
  ) {
    final improvements = <String, double>{};
    
    for (final entry in current.metrics.entries) {
      final currentValue = entry.value;
      final previousValue = previous.metrics[entry.key];
      
      if (previousValue != null && previousValue != 0) {
        final improvement = ((currentValue - previousValue) / previousValue) * 100;
        improvements[entry.key] = improvement;
      }
    }
    
    final overallImprovement = improvements.values.isNotEmpty
        ? improvements.values.reduce((a, b) => a + b) / improvements.length
        : 0.0;
    
    String summary;
    if (overallImprovement > 5) {
      summary = 'Önemli gelişim gösterildi';
    } else if (overallImprovement > 0) {
      summary = 'Hafif gelişim görüldü';
    } else if (overallImprovement > -5) {
      summary = 'Performans stabil';
    } else {
      summary = 'Performansta gerileme';
    }
    
    return TestComparisonModel(
      id: 'comp_${current.id}_${previous.id}',
      currentTestId: current.id,
      previousTestId: previous.id,
      comparisonType: comparisonType,
      improvements: improvements,
      summary: summary,
      createdAt: DateTime.now(),
    );
  }

  /// Overall improvement percentage
  double get overallImprovement {
    if (improvements.isEmpty) return 0.0;
    return improvements.values.reduce((a, b) => a + b) / improvements.length;
  }

  /// Most improved metric
  String? get mostImprovedMetric {
    if (improvements.isEmpty) return null;
    return improvements.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Most declined metric
  String? get mostDeclinedMetric {
    if (improvements.isEmpty) return null;
    return improvements.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }
}

/// Batch test result operations
class TestResultBatch {
  final List<TestResultModel> results;
  final String athleteId;
  final TestType? testType;
  final DateTimeRange? dateRange;

  const TestResultBatch({
    required this.results,
    required this.athleteId,
    this.testType,
    this.dateRange,
  });

  factory TestResultBatch.forAthlete(
    List<TestResultModel> allResults,
    String athleteId, {
    TestType? testType,
    DateTimeRange? dateRange,
  }) {
    var filtered = allResults.where((r) => r.athleteId == athleteId);
    
    if (testType != null) {
      filtered = filtered.where((r) => r.testTypeEnum == testType);
    }
    
    if (dateRange != null) {
      filtered = filtered.where((r) => 
          r.testDate.isAfter(dateRange.start) && 
          r.testDate.isBefore(dateRange.end));
    }
    
    final sortedResults = filtered.toList()
      ..sort((a, b) => a.testDate.compareTo(b.testDate));
    
    return TestResultBatch(
      results: sortedResults,
      athleteId: athleteId,
      testType: testType,
      dateRange: dateRange,
    );
  }

  /// Statistics
  int get totalTests => results.length;
  int get completedTests => results.where((r) => r.statusEnum == TestStatus.completed).length;
  double get avgQualityScore => results.isEmpty ? 0 : 
      results.map((r) => r.qualityScore ?? 0).reduce((a, b) => a + b) / results.length;

  /// Latest test
  TestResultModel? get latest => results.isNotEmpty ? results.last : null;

  /// Best performance (highest primary metric)
  TestResultModel? get bestPerformance {
    if (results.isEmpty) return null;
    
    return results.reduce((a, b) {
      final aMetric = a.getPrimaryMetric() ?? 0;
      final bMetric = b.getPrimaryMetric() ?? 0;
      return aMetric > bMetric ? a : b;
    });
  }

  /// Progress trend
  List<TestComparisonModel> get progressTrend {
    if (results.length < 2) return [];
    
    final comparisons = <TestComparisonModel>[];
    for (int i = 1; i < results.length; i++) {
      comparisons.add(TestComparisonModel.fromTestResults(
        results[i],
        results[i - 1],
        'sequential',
      ));
    }
    
    return comparisons;
  }
}