import '../../domain/entities/test_result.dart';
import '../../core/constants/test_constants.dart';
import 'force_data_model.dart';

class TestResultModel {
  final String id;
  final String athleteId;
  final String testType; // TestType enum string
  final String startTime; // ISO string format
  final String? endTime; // ISO string format
  final String status; // TestStatus enum string
  final List<ForceDataModel> rawData;
  final Map<String, double> metrics;
  final double? qualityScore;
  final String? notes;
  final String createdAt; // ISO string format

  const TestResultModel({
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

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'athleteId': athleteId,
      'testType': testType,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'rawData': rawData.map((data) => data.toJson()).toList(),
      'metrics': metrics,
      'qualityScore': qualityScore,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  factory TestResultModel.fromJson(Map<String, dynamic> json) {
    return TestResultModel(
      id: json['id'] as String,
      athleteId: json['athleteId'] as String,
      testType: json['testType'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String?,
      status: json['status'] as String,
      rawData: (json['rawData'] as List)
          .map((data) => ForceDataModel.fromJson(data as Map<String, dynamic>))
          .toList(),
      metrics: Map<String, double>.from(json['metrics'] as Map),
      qualityScore: json['qualityScore'] as double?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  // Entity conversion
  TestResult toEntity() {
    return TestResult(
      id: id,
      athleteId: athleteId,
      testType: _parseTestType(testType),
      startTime: DateTime.parse(startTime),
      endTime: endTime != null ? DateTime.parse(endTime!) : null,
      status: _parseTestStatus(status),
      rawData: rawData.map((model) => model.toEntity()).toList(),
      metrics: metrics,
      qualityScore: qualityScore,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
    );
  }

  factory TestResultModel.fromEntity(TestResult testResult) {
    return TestResultModel(
      id: testResult.id,
      athleteId: testResult.athleteId,
      testType: _testTypeToString(testResult.testType),
      startTime: testResult.startTime.toIso8601String(),
      endTime: testResult.endTime?.toIso8601String(),
      status: _testStatusToString(testResult.status),
      rawData: testResult.rawData.map((entity) => ForceDataModel.fromEntity(entity)).toList(),
      metrics: testResult.metrics,
      qualityScore: testResult.qualityScore,
      notes: testResult.notes,
      createdAt: testResult.createdAt.toIso8601String(),
    );
  }

  // Mock data oluşturma için factory
  factory TestResultModel.mock({
    String? athleteId,
    TestType? testType,
    int? dataPoints,
  }) {
    final now = DateTime.now();
    final type = testType ?? TestType.counterMovementJump;
    final points = dataPoints ?? 100;
    
    // Mock force data oluştur
    final mockRawData = List.generate(points, (index) {
      return ForceDataModel.mock(
        timestamp: now.add(Duration(milliseconds: index)),
        totalForce: 800 + (index * 2), // Artan kuvvet
        index: index,
      );
    });

    // Mock metrikler
    final mockMetrics = <String, double>{
      'jumpHeight': 35.5,
      'peakForce': 1200.0,
      'averageForce': 850.0,
      'peakPower': 3500.0,
      'rfd': 2500.0,
      'impulse': 85.0,
      'contactTime': 0.8,
      'flightTime': 0.6,
      'asymmetryIndex': 8.5,
      'forceAsymmetry': -3.2,
    };

    return TestResultModel(
      id: 'test_${now.millisecondsSinceEpoch}',
      athleteId: athleteId ?? 'athlete_1',
      testType: _testTypeToString(type),
      startTime: now.subtract(const Duration(seconds: 10)).toIso8601String(),
      endTime: now.toIso8601String(),
      status: _testStatusToString(TestStatus.completed),
      rawData: mockRawData,
      metrics: mockMetrics,
      qualityScore: 85.5,
      notes: 'Mock test data',
      createdAt: now.toIso8601String(),
    );
  }

  // Helper methods
  static TestType _parseTestType(String testType) {
    switch (testType) {
      case 'counterMovementJump':
        return TestType.counterMovementJump;
      case 'squatJump':
        return TestType.squatJump;
      case 'dropJump':
        return TestType.dropJump;
      case 'balance':
        return TestType.balance;
      case 'isometric':
        return TestType.isometric;
      case 'landing':
        return TestType.landing;
      default:
        return TestType.counterMovementJump;
    }
  }

  static String _testTypeToString(TestType testType) {
    switch (testType) {
      case TestType.counterMovementJump:
        return 'counterMovementJump';
      case TestType.squatJump:
        return 'squatJump';
      case TestType.dropJump:
        return 'dropJump';
      case TestType.balance:
        return 'balance';
      case TestType.isometric:
        return 'isometric';
      case TestType.landing:
        return 'landing';
    }
  }

  static TestStatus _parseTestStatus(String status) {
    switch (status) {
      case 'completed':
        return TestStatus.completed;
      case 'failed':
        return TestStatus.failed;
      case 'cancelled':
        return TestStatus.cancelled;
      case 'inProgress':
        return TestStatus.inProgress;
      default:
        return TestStatus.failed;
    }
  }

  static String _testStatusToString(TestStatus status) {
    switch (status) {
      case TestStatus.completed:
        return 'completed';
      case TestStatus.failed:
        return 'failed';
      case TestStatus.cancelled:
        return 'cancelled';
      case TestStatus.inProgress:
        return 'inProgress';
    }
  }
}