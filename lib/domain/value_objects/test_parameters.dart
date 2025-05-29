import 'package:equatable/equatable.dart';
import '../../core/constants/test_constants.dart';

class TestParameters extends Equatable {
  final TestType testType;
  final Duration duration;
  final double samplingRate;
  final double forceThreshold; // Hareket başlangıcı için
  final double noiseThreshold; // Gürültü filtreleme için
  final bool autoDetectPhases; // Otomatik faz tespiti
  final Map<String, dynamic> customSettings;

  const TestParameters({
    required this.testType,
    required this.duration,
    required this.samplingRate,
    required this.forceThreshold,
    required this.noiseThreshold,
    this.autoDetectPhases = true,
    this.customSettings = const {},
  });

  // Default parameters for different test types
  static TestParameters defaultForTest(TestType testType) {
    switch (testType) {
      case TestType.counterMovementJump:
        return const TestParameters(
          testType: TestType.counterMovementJump,
          duration: Duration(seconds: 10),
          samplingRate: 1000,
          forceThreshold: 10.0,
          noiseThreshold: 5.0,
          customSettings: {
            'minCounterMovementDepth': 50.0, // Newton
            'maxPreparationTime': 3.0, // seconds
          },
        );
      
      case TestType.squatJump:
        return const TestParameters(
          testType: TestType.squatJump,
          duration: Duration(seconds: 8),
          samplingRate: 1000,
          forceThreshold: 15.0,
          noiseThreshold: 5.0,
          customSettings: {
            'holdingTime': 2.0, // seconds
            'maxHoldingVariation': 5.0, // Newton
          },
        );
      
      case TestType.dropJump:
        return const TestParameters(
          testType: TestType.dropJump,
          duration: Duration(seconds: 12),
          samplingRate: 1000,
          forceThreshold: 20.0,
          noiseThreshold: 8.0,
          customSettings: {
            'dropHeight': 30.0, // cm
            'maxGroundContactTime': 0.3, // seconds
          },
        );
      
      case TestType.balance:
        return const TestParameters(
          testType: TestType.balance,
          duration: Duration(seconds: 60),
          samplingRate: 100, // Lower for balance tests
          forceThreshold: 2.0,
          noiseThreshold: 1.0,
          customSettings: {
            'eyesOpen': true,
            'singleLeg': false,
          },
        );
      
      case TestType.isometric:
        return const TestParameters(
          testType: TestType.isometric,
          duration: Duration(seconds: 5),
          samplingRate: 1000,
          forceThreshold: 50.0,
          noiseThreshold: 10.0,
          customSettings: {
            'targetForce': 1000.0, // Newton
            'holdTime': 3.0, // seconds
          },
        );
      
      case TestType.landing:
        return const TestParameters(
          testType: TestType.landing,
          duration: Duration(seconds: 8),
          samplingRate: 1000,
          forceThreshold: 50.0,
          noiseThreshold: 10.0,
          customSettings: {
            'landingHeight': 20.0, // cm
          },
        );
    }
  }

  // Computed properties
  String get testName => TestConstants.testNames[testType] ?? 'Unknown';
  
  int get totalSamples => (duration.inMilliseconds * samplingRate / 1000).round();
  
  double get timePerSample => 1.0 / samplingRate;

  // Custom setting accessors
  T? getCustomSetting<T>(String key) {
    return customSettings[key] as T?;
  }

  bool hasCustomSetting(String key) {
    return customSettings.containsKey(key);
  }

  // Copy with method
  TestParameters copyWith({
    TestType? testType,
    Duration? duration,
    double? samplingRate,
    double? forceThreshold,
    double? noiseThreshold,
    bool? autoDetectPhases,
    Map<String, dynamic>? customSettings,
  }) {
    return TestParameters(
      testType: testType ?? this.testType,
      duration: duration ?? this.duration,
      samplingRate: samplingRate ?? this.samplingRate,
      forceThreshold: forceThreshold ?? this.forceThreshold,
      noiseThreshold: noiseThreshold ?? this.noiseThreshold,
      autoDetectPhases: autoDetectPhases ?? this.autoDetectPhases,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  List<Object> get props => [
        testType,
        duration,
        samplingRate,
        forceThreshold,
        noiseThreshold,
        autoDetectPhases,
        customSettings,
      ];
}