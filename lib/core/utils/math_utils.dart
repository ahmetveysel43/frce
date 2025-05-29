import 'dart:math' as math;

class MathUtils {
  /// Liste ortalaması hesapla
  static double calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Standart sapma hesapla
  static double calculateStandardDeviation(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = calculateMean(values);
    final variance = values
        .map((value) => math.pow(value - mean, 2))
        .reduce((a, b) => a + b) / (values.length - 1);
    
    return math.sqrt(variance);
  }

  /// RMS (Root Mean Square) hesapla
  static double calculateRMS(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final sumOfSquares = values
        .map((value) => value * value)
        .reduce((a, b) => a + b);
    
    return math.sqrt(sumOfSquares / values.length);
  }

  /// Maksimum değer ve indeksini bul
  static ({double value, int index}) findMax(List<double> values) {
    if (values.isEmpty) return (value: 0.0, index: -1);
    
    double maxValue = values.first;
    int maxIndex = 0;
    
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxValue) {
        maxValue = values[i];
        maxIndex = i;
      }
    }
    
    return (value: maxValue, index: maxIndex);
  }

  /// Minimum değer ve indeksini bul
  static ({double value, int index}) findMin(List<double> values) {
    if (values.isEmpty) return (value: 0.0, index: -1);
    
    double minValue = values.first;
    int minIndex = 0;
    
    for (int i = 1; i < values.length; i++) {
      if (values[i] < minValue) {
        minValue = values[i];
        minIndex = i;
      }
    }
    
    return (value: minValue, index: minIndex);
  }

  /// Rate of Force Development (RFD) hesapla
  static double calculateRFD(List<double> forces, double samplingRate) {
    if (forces.length < 2) return 0.0;
    
    final timeInterval = 1.0 / samplingRate; // saniye
    final forceChange = forces.last - forces.first;
    final totalTime = (forces.length - 1) * timeInterval;
    
    return forceChange / totalTime; // N/s
  }

  /// İmpuls hesapla (kuvvet-zaman eğrisi altındaki alan)
  static double calculateImpulse(List<double> forces, double samplingRate) {
    if (forces.isEmpty) return 0.0;
    
    final timeInterval = 1.0 / samplingRate;
    return forces.reduce((a, b) => a + b) * timeInterval;
  }

  /// Değerleri normalize et (0-1 arası)
  static List<double> normalizeValues(List<double> values) {
    if (values.isEmpty) return [];
    
    final minMax = (min: findMin(values).value, max: findMax(values).value);
    final range = minMax.max - minMax.min;
    
    if (range == 0) return values.map((e) => 0.5).toList();
    
    return values
        .map((value) => (value - minMax.min) / range)
        .toList();
  }

  /// Asimetri yüzdesi hesapla
  static double calculateAsymmetryPercentage(double leftValue, double rightValue) {
    final total = leftValue + rightValue;
    if (total == 0) return 0.0;
    
    final difference = (leftValue - rightValue).abs();
    return (difference / total) * 100;
  }

  // Private constructor
  MathUtils._();
}