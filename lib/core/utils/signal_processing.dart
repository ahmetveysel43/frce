import 'dart:math' as math;
import 'math_utils.dart';

class SignalProcessor {
  /// Basit hareketli ortalama filtresi
  static List<double> movingAverageFilter(List<double> data, int windowSize) {
    if (data.length < windowSize) return data;
    
    final filtered = <double>[];
    
    for (int i = 0; i < data.length; i++) {
      final start = math.max(0, i - windowSize ~/ 2);
      final end = math.min(data.length, i + windowSize ~/ 2 + 1);
      
      final window = data.sublist(start, end);
      filtered.add(MathUtils.calculateMean(window));
    }
    
    return filtered;
  }

  /// Basit alçak geçiren filtre (Low-pass filter)
  static List<double> lowPassFilter(List<double> data, double alpha) {
    if (data.isEmpty) return data;
    
    final filtered = <double>[data.first];
    
    for (int i = 1; i < data.length; i++) {
      final filteredValue = alpha * data[i] + (1 - alpha) * filtered.last;
      filtered.add(filteredValue);
    }
    
    return filtered;
  }

  /// Türev hesapla (force değişim hızı)
  static List<double> calculateDerivative(List<double> data, double samplingRate) {
    if (data.length < 2) return [];
    
    final derivative = <double>[];
    final timeInterval = 1.0 / samplingRate;
    
    for (int i = 1; i < data.length; i++) {
      final change = data[i] - data[i - 1];
      derivative.add(change / timeInterval);
    }
    
    return derivative;
  }

  /// Gürültü tespit et
  static List<bool> detectNoise(List<double> data, double threshold) {
    final noiseFlags = <bool>[];
    
    if (data.length < 3) {
      return List.filled(data.length, false);
    }
    
    for (int i = 1; i < data.length - 1; i++) {
      final prev = data[i - 1];
      final current = data[i];
      final next = data[i + 1];
      
      // Ani değişimler gürültü olabilir
      final change1 = (current - prev).abs();
      final change2 = (next - current).abs();
      
      final isNoise = change1 > threshold || change2 > threshold;
      noiseFlags.add(isNoise);
    }
    
    // İlk ve son değer için
    noiseFlags.insert(0, false);
    noiseFlags.add(false);
    
    return noiseFlags;
  }

  /// Baseline (sıfır seviyesi) düzeltmesi
  static List<double> baselineCorrection(List<double> data) {
    if (data.isEmpty) return data;
    
    // İlk 100 örnekten baseline hesapla
    final baselineSize = math.min(100, data.length ~/ 4);
    final baselineData = data.take(baselineSize).toList();
    final baseline = MathUtils.calculateMean(baselineData);
    
    return data.map((value) => value - baseline).toList();
  }

  /// Faz geçişlerini tespit et (hareket başlangıcı, tepe noktası vs.)
  static List<int> detectPhaseTransitions(
    List<double> data, 
    double threshold,
  ) {
    final transitions = <int>[];
    
    if (data.length < 3) return transitions;
    
    bool isIncreasing = false;
    bool wasIncreasing = false;
    
    for (int i = 1; i < data.length - 1; i++) {
      final slope = data[i + 1] - data[i];
      isIncreasing = slope > threshold;
      
      // Faz değişimi tespit et
      if (isIncreasing != wasIncreasing) {
        transitions.add(i);
      }
      
      wasIncreasing = isIncreasing;
    }
    
    return transitions;
  }

  // Private constructor
  SignalProcessor._();
}