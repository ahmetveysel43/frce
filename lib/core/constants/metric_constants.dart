/// Unified metric constants for consistent metric handling across all screens
class MetricConstants {
  
  /// Available metrics by test type
  static const Map<String, List<MetricInfo>> metricsByTestType = {
    // ===== JUMP TESTS =====
    'CMJ': [
      // Basic metrics
      MetricInfo('jumpHeight', 'Jump Height', 'cm', true),
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('peakPower', 'Peak Power', 'W', true),
      MetricInfo('averagePower', 'Average Power', 'W', true),
      MetricInfo('rfd', 'RFD', 'N/s', true),
      MetricInfo('flightTime', 'Flight Time', 'ms', true),
      MetricInfo('contactTime', 'Contact Time', 'ms', false),
      MetricInfo('takeoffVelocity', 'Takeoff Velocity', 'm/s', true),
      MetricInfo('impulse', 'Impulse', 'N·s', true),
      
      // Phase-specific metrics
      MetricInfo('eccentricRfd', 'Eccentric RFD', 'N/s', true),
      MetricInfo('concentricRfd', 'Concentric RFD', 'N/s', true),
      MetricInfo('brakingRfd', 'Braking RFD', 'N/s', true),
      MetricInfo('propulsiveRfd', 'Propulsive RFD', 'N/s', true),
      MetricInfo('brakingImpulse', 'Braking Impulse', 'N·s', true),
      MetricInfo('propulsiveImpulse', 'Propulsive Impulse', 'N·s', true),
      MetricInfo('eccentricDuration', 'Eccentric Duration', 'ms', false),
      MetricInfo('concentricDuration', 'Concentric Duration', 'ms', false),
      MetricInfo('brakingPhaseDuration', 'Braking Phase Duration', 'ms', false),
      MetricInfo('propulsivePhaseDuration', 'Propulsive Phase Duration', 'ms', false),
      
      // Asymmetry metrics
      MetricInfo('asymmetryIndex', 'Asymmetry Index', '%', false),
      MetricInfo('takeoffAsymmetry', 'Takeoff Asymmetry', '%', false),
      MetricInfo('forceAsymmetry', 'Force Asymmetry', '%', false),
      MetricInfo('impulseAsymmetry', 'Impulse Asymmetry', '%', false),
      
      // Reactive strength
      MetricInfo('rsiMod', 'RSI Modified', 'ratio', true),
    ],
    
    'CMJ_LOADED': [
      MetricInfo('jumpHeight', 'Jump Height', 'cm', true),
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('peakPower', 'Peak Power', 'W', true),
      MetricInfo('rfd', 'RFD', 'N/s', true),
      MetricInfo('dsi', 'Dynamic Strength Index', 'ratio', true),
      MetricInfo('loadCapacity', 'Load Capacity', '%', true),
      MetricInfo('asymmetryIndex', 'Asymmetry Index', '%', false),
    ],
    
    'ABALAKOV': [
      MetricInfo('jumpHeight', 'Jump Height', 'cm', true),
      MetricInfo('armSwingContribution', 'Arm Swing Contribution', 'cm', true),
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('peakPower', 'Peak Power', 'W', true),
      MetricInfo('rfd', 'RFD', 'N/s', true),
      MetricInfo('coordinationIndex', 'Coordination Index', 'ratio', true),
    ],
    
    'SJ': [
      MetricInfo('jumpHeight', 'Jump Height', 'cm', true),
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('peakPower', 'Peak Power', 'W', true),
      MetricInfo('rfd', 'RFD', 'N/s', true),
      MetricInfo('startingStrength', 'Starting Strength', 'N/s', true),
      MetricInfo('timeToTakeoff', 'Time to Takeoff', 'ms', false),
      MetricInfo('asymmetryIndex', 'Asymmetry Index', '%', false),
    ],
    
    'SJ_LOADED': [
      MetricInfo('jumpHeight', 'Jump Height', 'cm', true),
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('dsi', 'Dynamic Strength Index', 'ratio', true),
      MetricInfo('forceProfile', 'Force Profile', 'ratio', true),
    ],
    
    'SINGLE_LEG_CMJ': [
      MetricInfo('jumpHeight', 'Jump Height', 'cm', true),
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('singleLegAsymmetry', 'Single Leg Asymmetry', '%', false),
      MetricInfo('phaseBasedAsymmetry', 'Phase-based Asymmetry', '%', false),
      MetricInfo('stabilityIndex', 'Stability Index', 'score', true),
      MetricInfo('landingStability', 'Landing Stability', 'score', true),
    ],
    
    'DJ': [
      MetricInfo('jumpHeight', 'Jump Height', 'cm', true),
      MetricInfo('contactTime', 'Contact Time', 'ms', false),
      MetricInfo('rsi', 'RSI', 'm/s', true),
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('landingHeight', 'Landing Height', 'cm', true),
      MetricInfo('landingPhaseDuration', 'Landing Phase Duration', 'ms', false),
      MetricInfo('landingPerformanceIndex', 'Landing Performance Index', 'ratio', true),
      MetricInfo('peakLandingForce', 'Peak Landing Force', 'N', false),
      MetricInfo('brakingForce', 'Braking Force', 'N', true),
      MetricInfo('landingAsymmetry', 'Landing Asymmetry', '%', false),
      MetricInfo('asymmetryIndex', 'Asymmetry Index', '%', false),
    ],
    
    'SINGLE_LEG_DJ': [
      MetricInfo('jumpHeight', 'Jump Height', 'cm', true),
      MetricInfo('rsi', 'RSI', 'm/s', true),
      MetricInfo('singleLegLandingPerformance', 'Single Leg Landing Performance', 'score', true),
      MetricInfo('phaseBasedAsymmetry', 'Phase-based Asymmetry', '%', false),
      MetricInfo('stabilizationIndex', 'Stabilization Index', 'score', true),
    ],
    
    'CMJ_REBOUND': [
      MetricInfo('averageJumpHeight', 'Average Jump Height', 'cm', true),
      MetricInfo('rsi', 'RSI', 'm/s', true),
      MetricInfo('fatigueIndex', 'Fatigue Index', '%', false),
      MetricInfo('consistencyScore', 'Consistency Score', '%', true),
      MetricInfo('rsiTrend', 'RSI Trend', '%', true),
      MetricInfo('heightTrend', 'Height Trend', '%', true),
    ],
    
    'SINGLE_LEG_CMJ_REBOUND': [
      MetricInfo('averageJumpHeight', 'Average Jump Height', 'cm', true),
      MetricInfo('asymmetryChange', 'Asymmetry Change', '%', false),
      MetricInfo('fatigueIndex', 'Fatigue Index', '%', false),
      MetricInfo('singleLegFatigueProfile', 'Single Leg Fatigue Profile', 'score', false),
    ],
    
    'LAND_AND_HOLD': [
      MetricInfo('peakLandingForce', 'Peak Landing Force', 'N', false),
      MetricInfo('timeToStabilization', 'Time to Stabilization', 'ms', false),
      MetricInfo('landingPerformanceIndex', 'Landing Performance Index', 'ratio', true),
      MetricInfo('stabilizationAsymmetry', 'Stabilization Asymmetry', '%', false),
      MetricInfo('forceBalance', 'Force Balance', 'score', true),
    ],
    
    'SINGLE_LEG_LAND_AND_HOLD': [
      MetricInfo('peakLandingForce', 'Peak Landing Force', 'N', false),
      MetricInfo('timeToStabilization', 'Time to Stabilization', 'ms', false),
      MetricInfo('singleLegStabilizationIndex', 'Single Leg Stabilization Index', 'score', true),
      MetricInfo('asymmetry', 'Asymmetry', '%', false),
    ],
    
    'HOP_TEST': [
      MetricInfo('hopDistance', 'Hop Distance', 'cm', true),
      MetricInfo('contactTime', 'Contact Time', 'ms', false),
      MetricInfo('hopAsymmetry', 'Hop Asymmetry', '%', false),
      MetricInfo('fatigueResistance', 'Fatigue Resistance', '%', true),
      MetricInfo('lateralForceProfile', 'Lateral Force Profile', 'N', true),
    ],
    
    'SINGLE_LEG_HOP': [
      MetricInfo('hopDistance', 'Hop Distance', 'cm', true),
      MetricInfo('singleLegAsymmetry', 'Single Leg Asymmetry', '%', false),
      MetricInfo('returnCapability', 'Return Capability', 'score', true),
    ],
    
    'HOP_AND_RETURN': [
      MetricInfo('contactTime', 'Contact Time', 'ms', false),
      MetricInfo('stabilizationTime', 'Stabilization Time', 'ms', false),
      MetricInfo('forceBalance', 'Force Balance', 'score', true),
      MetricInfo('landingAsymmetry', 'Landing Asymmetry', '%', false),
    ],
    
    // ===== FUNCTIONAL TESTS =====
    'SQUAT_ASSESSMENT': [
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('powerOutput', 'Power Output', 'W', true),
      MetricInfo('phaseBasedAsymmetry', 'Phase-based Asymmetry', '%', false),
      MetricInfo('kineticsControlPoint', 'Kinetic Control Point', 'score', true),
      MetricInfo('movementQuality', 'Movement Quality', 'score', true),
    ],
    
    'SINGLE_LEG_SQUAT': [
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('weightDistribution', 'Weight Distribution', '%', true),
      MetricInfo('singleLegPhaseAnalysis', 'Single Leg Phase Analysis', 'score', true),
      MetricInfo('stabilityAsymmetry', 'Stability Asymmetry', '%', false),
    ],
    
    'PUSH_UP': [
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('rfd', 'RFD', 'N/s', true),
      MetricInfo('pushUpAsymmetry', 'Push-up Asymmetry', '%', false),
      MetricInfo('workPerRepetition', 'Work per Repetition', 'J', true),
    ],
    
    'SIT_TO_STAND': [
      MetricInfo('time', 'Time', 's', false),
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('phaseTiming', 'Phase Timing', 'ms', false),
      MetricInfo('leftRightAsymmetry', 'L-R Asymmetry', '%', false),
      MetricInfo('repetitionFatigueIndex', 'Repetition Fatigue Index', '%', false),
    ],
    
    // ===== ISOMETRIC TESTS =====
    'IMTP': [
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('rfd0_100ms', 'RFD (0-100ms)', 'N/s', true),
      MetricInfo('rfd0_200ms', 'RFD (0-200ms)', 'N/s', true),
      MetricInfo('forceAt50ms', 'Force at 50ms', 'N', true),
      MetricInfo('forceAt100ms', 'Force at 100ms', 'N', true),
      MetricInfo('forceAt200ms', 'Force at 200ms', 'N', true),
      MetricInfo('impulse200ms', 'Impulse 200ms', 'N·s', true),
      MetricInfo('dsi', 'DSI', 'ratio', true),
      MetricInfo('forceTimeCurve', 'Force-Time Curve', 'profile', true),
      MetricInfo('singleLegAsymmetry', 'Single Leg Asymmetry', '%', false),
      MetricInfo('asymmetryIndex', 'Asymmetry Index', '%', false),
    ],
    
    'ISOMETRIC_SQUAT': [
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('forcePlateau', 'Force Plateau', 'N', true),
      MetricInfo('plateauDuration', 'Plateau Duration', 's', true),
      MetricInfo('timeToMaximum', 'Time to Maximum', 'ms', false),
      MetricInfo('phaseBasedAnalysis', 'Phase-based Analysis', 'score', true),
    ],
    
    'ISOMETRIC_SHOULDER': [
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('rfd', 'RFD', 'N/s', true),
      MetricInfo('segmentalForceDifferences', 'Segmental Force Differences', '%', false),
      MetricInfo('mvicAsymmetry', 'MVIC Asymmetry', '%', false),
    ],
    
    'SINGLE_LEG_ISOMETRIC': [
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('rfd', 'RFD', 'N/s', true),
      MetricInfo('singleLegAsymmetry', 'Single Leg Asymmetry', '%', false),
      MetricInfo('rfdDifference', 'RFD Difference', 'N/s', false),
      MetricInfo('timeBasedAnalysis', 'Time-based Analysis', 'profile', true),
    ],
    
    'CUSTOM_ISOMETRIC': [
      MetricInfo('peakForce', 'Peak Force', 'N', true),
      MetricInfo('customMetrics', 'Custom Protocol Metrics', 'various', true),
    ],
    
    // ===== BALANCE TESTS =====
    'QUIET_STAND': [
      MetricInfo('copPathLength', 'COP Path Length', 'mm', false),
      MetricInfo('copArea', 'COP Area', 'mm²', false),
      MetricInfo('copVelocityChange', 'COP Velocity Change', 'mm/s', false),
      MetricInfo('eyesOpenClosedDifference', 'Eyes Open/Closed Difference', '%', false),
      MetricInfo('weightDistributionAsymmetry', 'Weight Distribution Asymmetry', '%', false),
      MetricInfo('normativeComparison', 'Normative Comparison', 'percentile', true),
      MetricInfo('stabilityIndex', 'Stability Index', 'score', true),
      MetricInfo('copRange', 'COP Range', 'mm', false),
      MetricInfo('copVelocity', 'COP Velocity', 'mm/s', false),
    ],
    
    'SINGLE_LEG_STAND': [
      MetricInfo('copMetrics', 'COP Metrics', 'mm', false),
      MetricInfo('timeToFailure', 'Time to Failure', 's', true),
      MetricInfo('stabilizationDuration', 'Stabilization Duration', 's', true),
      MetricInfo('asymmetryTrend', 'Asymmetry Trend', '%', false),
    ],
    
    'SINGLE_LEG_RANGE_OF_STABILITY': [
      MetricInfo('maximumReachArea', 'Maximum Reach Area', 'mm²', true),
      MetricInfo('copEnvelope', 'COP Envelope', 'mm²', true),
      MetricInfo('multiDirectionalCopAnalysis', 'Multi-directional COP Analysis', 'profile', true),
      MetricInfo('stabilityLimitAssessment', 'Stability Limit Assessment', 'score', true),
    ],
    
    // ===== LEGACY COMPATIBILITY =====
    'Balance': [
      MetricInfo('stabilityIndex', 'Stability Index', 'index', false),
      MetricInfo('copRange', 'COP Range', 'mm', false),
      MetricInfo('copVelocity', 'COP Velocity', 'mm/s', false),
      MetricInfo('copArea', 'COP Area', 'mm²', false),
    ],
    'Speed Test': [
      MetricInfo('time', 'Time', 's', false),
      MetricInfo('speed', 'Speed', 'm/s', true),
      MetricInfo('acceleration', 'Acceleration', 'm/s²', true),
    ],
    'Agility Test': [
      MetricInfo('time', 'Time', 's', false),
      MetricInfo('hopDistance', 'Hop Distance', 'cm', true),
      MetricInfo('movementEfficiency', 'Movement Efficiency', '%', true),
    ],
  };

  /// Get metrics for a specific test type
  static List<MetricInfo> getMetricsForTestType(String testType) {
    return metricsByTestType[testType.toUpperCase()] ?? [];
  }

  /// Get all available test types
  static List<String> getAllTestTypes() {
    return metricsByTestType.keys.toList();
  }

  /// Check if a metric is improvement when increased
  static bool isImprovementWhenIncreased(String metricKey) {
    // Find the metric in all test types
    for (final metrics in metricsByTestType.values) {
      for (final metric in metrics) {
        if (metric.key == metricKey) {
          return metric.higherIsBetter;
        }
      }
    }
    return true; // Default assumption
  }

  /// Get unit for a metric
  static String getMetricUnit(String metricKey) {
    for (final metrics in metricsByTestType.values) {
      for (final metric in metrics) {
        if (metric.key == metricKey) {
          return metric.unit;
        }
      }
    }
    return '';
  }

  /// Get display name for a metric
  static String getMetricDisplayName(String metricKey) {
    for (final metrics in metricsByTestType.values) {
      for (final metric in metrics) {
        if (metric.key == metricKey) {
          return metric.displayName;
        }
      }
    }
    return metricKey;
  }

  /// Primary metrics for each test type (used for quick comparisons)
  static const Map<String, String> primaryMetrics = {
    // Jump tests
    'CMJ': 'jumpHeight',
    'CMJ_LOADED': 'dsi',
    'ABALAKOV': 'jumpHeight',
    'SJ': 'jumpHeight',
    'SJ_LOADED': 'dsi',
    'SINGLE_LEG_CMJ': 'singleLegAsymmetry',
    'DJ': 'rsi',
    'SINGLE_LEG_DJ': 'singleLegLandingPerformance',
    'CMJ_REBOUND': 'fatigueIndex',
    'SINGLE_LEG_CMJ_REBOUND': 'asymmetryChange',
    'LAND_AND_HOLD': 'landingPerformanceIndex',
    'SINGLE_LEG_LAND_AND_HOLD': 'singleLegStabilizationIndex',
    'HOP_TEST': 'hopAsymmetry',
    'SINGLE_LEG_HOP': 'singleLegAsymmetry',
    'HOP_AND_RETURN': 'forceBalance',
    
    // Functional tests
    'SQUAT_ASSESSMENT': 'movementQuality',
    'SINGLE_LEG_SQUAT': 'stabilityAsymmetry',
    'PUSH_UP': 'pushUpAsymmetry',
    'SIT_TO_STAND': 'leftRightAsymmetry',
    
    // Isometric tests
    'IMTP': 'peakForce',
    'ISOMETRIC_SQUAT': 'forcePlateau',
    'ISOMETRIC_SHOULDER': 'mvicAsymmetry',
    'SINGLE_LEG_ISOMETRIC': 'singleLegAsymmetry',
    'CUSTOM_ISOMETRIC': 'peakForce',
    
    // Balance tests
    'QUIET_STAND': 'stabilityIndex',
    'SINGLE_LEG_STAND': 'asymmetryTrend',
    'SINGLE_LEG_RANGE_OF_STABILITY': 'stabilityLimitAssessment',
    
    // Legacy compatibility
    'Balance': 'stabilityIndex',
    'Speed Test': 'speed',
    'Agility Test': 'movementEfficiency',
  };

  /// Get primary metric for test type
  static String getPrimaryMetric(String testType) {
    return primaryMetrics[testType.toUpperCase()] ?? 'peakForce';
  }

  /// Get metric info by key
  static MetricInfo? getMetricInfo(String metricKey) {
    for (final metrics in metricsByTestType.values) {
      for (final metric in metrics) {
        if (metric.key == metricKey) {
          return metric;
        }
      }
    }
    return null;
  }
}

/// Metric information class
class MetricInfo {
  final String key;
  final String displayName;
  final String unit;
  final bool higherIsBetter;

  const MetricInfo(this.key, this.displayName, this.unit, this.higherIsBetter);
}

/// Extension for List<MetricInfo>
extension MetricInfoListExtension on List<MetricInfo> {
  MetricInfo? firstWhereOrNull(bool Function(MetricInfo) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}