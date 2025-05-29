// lib/domain/entities/test_result.dart - Düzeltilmiş
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import '../../core/constants/test_constants.dart';
import 'force_data.dart';

enum TestStatus { completed, failed, cancelled, inProgress }

class TestResult extends Equatable {
  final String id;
  final String athleteId;
  final TestType testType;
  final DateTime startTime;
  final DateTime? endTime;
  final TestStatus status;
  final List<ForceData> rawData;
  final Map<String, double> metrics;
  final double? qualityScore;
  final String? notes;
  final DateTime createdAt;

  const TestResult({
    required this.id,
    required this.athleteId,
    required this.testType,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.rawData,
    required this.metrics,
    this.qualityScore,
    this.notes,
    required this.createdAt,
  });

  // Computed properties
  Duration get testDuration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  String get testName => TestConstants.testNames[testType] ?? 'Unknown Test';

  bool get isCompleted => status == TestStatus.completed;
  bool get hasFailed => status == TestStatus.failed;
  bool get isInProgress => status == TestStatus.inProgress;

  // Key metrics accessors (safe getters)
  double? get jumpHeight => metrics['jumpHeight'];
  double? get peakForce => metrics['peakForce'];
  double? get peakPower => metrics['peakPower'];
  double? get averageForce => metrics['averageForce'];
  double? get asymmetryIndex => metrics['asymmetryIndex'];
  double? get rfd => metrics['rfd']; // Rate of Force Development
  double? get impulse => metrics['impulse'];
  double? get contactTime => metrics['contactTime'];
  double? get flightTime => metrics['flightTime'];

  // Data quality indicators
  int get sampleCount => rawData.length;
  
  // ✅ FIXED: Calculate data quality from ForceData properties
  double get averageDataQuality {
    if (rawData.isEmpty) return 0.0;
    
    // Calculate quality based on available ForceData properties
    double totalQuality = 0.0;
    
    for (final data in rawData) {
      double quality = _calculateDataQuality(data);
      totalQuality += quality;
    }
    
    return totalQuality / rawData.length;
  }

  // ✅ Helper method to calculate data quality
  double _calculateDataQuality(ForceData data) {
    double quality = 100.0; // Start with perfect quality
    
    // Check for reasonable force values
    if (data.totalGRF < 0 || data.totalGRF > 5000) quality -= 20;
    if (data.leftGRF < 0 || data.rightGRF < 0) quality -= 15;
    
    // Check for reasonable CoP values (should be within platform bounds)
    if (data.leftCoPX.abs() > 200 || data.leftCoPY.abs() > 300) quality -= 10;
    if (data.rightCoPX.abs() > 200 || data.rightCoPY.abs() > 300) quality -= 10;
    
    // Check asymmetry (should be reasonable)
    if (data.asymmetryIndex > 0.5) quality -= 15; // More than 50% asymmetry is suspicious
    
    // Check stability (should be reasonable)
    if (data.stabilityIndex < 0.3) quality -= 10; // Very low stability is suspicious
    
    // Check sampling rate consistency
    if (data.samplingRate != null && (data.samplingRate! < 500 || data.samplingRate! > 2000)) {
      quality -= 10;
    }
    
    return math.max(0.0, quality); // Ensure quality is not negative
  }

  bool get hasGoodQuality => (qualityScore ?? 0) >= 70.0;

  // Copy with method
  TestResult copyWith({
    String? id,
    String? athleteId,
    TestType? testType,
    DateTime? startTime,
    DateTime? endTime,
    TestStatus? status,
    List<ForceData>? rawData,
    Map<String, double>? metrics,
    double? qualityScore,
    String? notes,
    DateTime? createdAt,
  }) {
    return TestResult(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      testType: testType ?? this.testType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      rawData: rawData ?? this.rawData,
      metrics: metrics ?? this.metrics,
      qualityScore: qualityScore ?? this.qualityScore,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        athleteId,
        testType,
        startTime,
        endTime,
        status,
        rawData,
        metrics,
        qualityScore,
        notes,
        createdAt,
      ];
}