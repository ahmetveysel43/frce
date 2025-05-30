import 'dart:math' as math;

/// List<T> için utility extension'lar
extension ListExtensions<T> on List<T> {
  
  // ===== SAFETY =====
  
  /// Güvenli index erişimi
  T? safeGet(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }
  
  /// Güvenli first
  T? get safeFirst => isEmpty ? null : first;
  
  /// Güvenli last
  T? get safeLast => isEmpty ? null : last;
  
  /// Güvenli elementAt
  T? safeElementAt(int index) => safeGet(index);
  
  // ===== CHUNKING =====
  
  /// Listeyi belirtilen boyutlarda parçalara ayır
  List<List<T>> chunk(int size) {
    if (size <= 0) return [this];
    
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      final end = math.min(i + size, length);
      chunks.add(sublist(i, end));
    }
    return chunks;
  }
  
  /// Sliding window oluştur
  List<List<T>> slidingWindow(int windowSize) {
    if (windowSize <= 0 || windowSize > length) return [];
    
    final windows = <List<T>>[];
    for (int i = 0; i <= length - windowSize; i++) {
      windows.add(sublist(i, i + windowSize));
    }
    return windows;
  }
  
  // ===== SAMPLING =====
  
  /// Random sampling
  List<T> sample(int count, {int? seed}) {
    if (count >= length) return List.from(this);
    
    final random = seed != null ? math.Random(seed) : math.Random();
    final shuffled = List<T>.from(this)..shuffle(random);
    return shuffled.take(count).toList();
  }
  
  /// Downsample (her n'inci elemanı al)
  List<T> downsample(int factor) {
    if (factor <= 1) return List.from(this);
    
    final result = <T>[];
    for (int i = 0; i < length; i += factor) {
      result.add(this[i]);
    }
    return result;
  }
  
  /// Uniform sampling (eşit aralıklarla)
  List<T> uniformSample(int count) {
    if (count >= length) return List.from(this);
    if (count <= 0) return [];
    
    final result = <T>[];
    final step = (length - 1) / (count - 1);
    
    for (int i = 0; i < count; i++) {
      final index = (i * step).round().clamp(0, length - 1);
      result.add(this[index]);
    }
    return result;
  }
  
  // ===== FILTERING =====
  
  /// Null olmayan elemanları filtrele
  List<T> whereNotNull() => where((item) => item != null).toList();
  
  /// Unique elemanlar (Set kullanarak)
  List<T> unique() => toSet().toList();
  
  /// Belirli bir property'ye göre unique
  List<T> uniqueBy<K>(K Function(T) keySelector) {
    final seen = <K>{};
    return where((item) => seen.add(keySelector(item))).toList();
  }
  
  /// İki liste arasındaki fark
  List<T> difference(List<T> other) {
    final otherSet = other.toSet();
    return where((item) => !otherSet.contains(item)).toList();
  }
  
  /// İki liste arasındaki kesişim
  List<T> intersection(List<T> other) {
    final otherSet = other.toSet();
    return where((item) => otherSet.contains(item)).toList();
  }
  
  // ===== GROUPING =====
  
  /// Belirli bir key'e göre grupla
  Map<K, List<T>> groupBy<K>(K Function(T) keySelector) {
    final groups = <K, List<T>>{};
    for (final item in this) {
      final key = keySelector(item);
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }
  
  /// Partition (condition'a göre ikiye ayır)
  ({List<T> truthy, List<T> falsy}) partition(bool Function(T) predicate) {
    final truthy = <T>[];
    final falsy = <T>[];
    
    for (final item in this) {
      if (predicate(item)) {
        truthy.add(item);
      } else {
        falsy.add(item);
      }
    }
    
    return (truthy: truthy, falsy: falsy);
  }
  
  // ===== TRANSFORMATION =====
  
  /// Flatten (nested list'leri düzleştir)
  List<U> flatMap<U>(Iterable<U> Function(T) mapper) {
    return expand(mapper).toList();
  }
  
  /// Interleave (iki listeyi sırayla birleştir)
  List<T> interleave(List<T> other) {
    final result = <T>[];
    final maxLength = math.max(length, other.length);
    
    for (int i = 0; i < maxLength; i++) {
      if (i < length) result.add(this[i]);
      if (i < other.length) result.add(other[i]);
    }
    
    return result;
  }
  
  /// Zip (iki listeyi tuple'lara birleştir)
  List<(T, U)> zip<U>(List<U> other) {
    final minLength = math.min(length, other.length);
    return List.generate(minLength, (i) => (this[i], other[i]));
  }
  
  /// Rotate (listeyi n pozisyon kaydır)
  List<T> rotate(int positions) {
    if (isEmpty) return [];
    
    final normalizedPositions = positions % length;
    if (normalizedPositions == 0) return List.from(this);
    
    return [...skip(normalizedPositions), ...take(normalizedPositions)];
  }
  
  // ===== SEARCH =====
  
  /// Binary search (sorted list için)
  int binarySearch<K extends Comparable<K>>(K key, K Function(T) keySelector) {
    int low = 0;
    int high = length - 1;
    
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final midKey = keySelector(this[mid]);
      final comparison = midKey.compareTo(key);
      
      if (comparison == 0) {
        return mid;
      } else if (comparison < 0) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    
    return -1; // Not found
  }
  
  /// Find index with condition
  int findIndex(bool Function(T) predicate) {
    for (int i = 0; i < length; i++) {
      if (predicate(this[i])) return i;
    }
    return -1;
  }
  
  /// Find last index with condition
  int findLastIndex(bool Function(T) predicate) {
    for (int i = length - 1; i >= 0; i--) {
      if (predicate(this[i])) return i;
    }
    return -1;
  }
  
  // ===== AGGREGATION =====
  
  /// Count with condition
  int count(bool Function(T) predicate) {
    return where(predicate).length;
  }
  
  /// All elements satisfy condition
  bool all(bool Function(T) predicate) {
    return every(predicate);
  }
  
  /// Any element satisfies condition
  bool any(bool Function(T) predicate) {
    return where(predicate).isNotEmpty;
  }
  
  /// None of the elements satisfy condition
  bool none(bool Function(T) predicate) {
    return !any(predicate);
  }
}

/// List<num> için özel mathematical extension'lar
extension NumericListExtensions<T extends num> on List<T> {
  
  // ===== BASIC STATISTICS =====
  
  /// Toplam
  T get sum => isEmpty ? (0 as T) : reduce((a, b) => (a + b) as T);
  
  /// Ortalama
  double get mean => isEmpty ? 0.0 : sum / length;
  
  /// Medyan
  double get median {
    if (isEmpty) return 0.0;
    
    final sorted = List<T>.from(this)..sort();
    final middle = sorted.length ~/ 2;
    
    if (sorted.length.isOdd) {
      return sorted[middle].toDouble();
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    }
  }
  
  /// Minimum değer
  T get min => isEmpty ? (0 as T) : reduce(math.min);
  
  /// Maximum değer
  T get max => isEmpty ? (0 as T) : reduce(math.max);
  
  /// Range (max - min)
  T get range => max - min;
  
  /// Varyans
  double get variance {
    if (length < 2) return 0.0;
    
    final meanValue = mean;
    final sumSquaredDiffs = fold<double>(0.0, (sum, value) {
      final diff = value - meanValue;
      return sum + (diff * diff);
    });
    
    return sumSquaredDiffs / (length - 1);
  }
  
  /// Standart sapma
  double get standardDeviation => math.sqrt(variance);
  
  /// Coefficient of variation (CV)
  double get coefficientOfVariation {
    final meanValue = mean;
    return meanValue != 0 ? (standardDeviation / meanValue) * 100 : 0.0;
  }
  
  // ===== PERCENTILES =====
  
  /// Percentile hesapla
  double percentile(double p) {
    if (isEmpty) return 0.0;
    if (p < 0 || p > 100) throw ArgumentError('Percentile must be between 0 and 100');
    
    final sorted = List<T>.from(this)..sort();
    final index = (p / 100) * (sorted.length - 1);
    
    if (index == index.floor()) {
      return sorted[index.floor()].toDouble();
    } else {
      final lower = sorted[index.floor()];
      final upper = sorted[index.ceil()];
      final fraction = index - index.floor();
      return lower + (upper - lower) * fraction;
    }
  }
  
  /// Q1 (25th percentile)
  double get q1 => percentile(25);
  
  /// Q3 (75th percentile)
  double get q3 => percentile(75);
  
  /// IQR (Interquartile Range)
  double get iqr => q3 - q1;
  
  // ===== NORMALIZATION =====
  
  /// Min-Max normalization (0-1 aralığına)
  List<double> normalize() {
    if (isEmpty) return [];
    
    final minVal = min;
    final maxVal = max;
    final range = maxVal - minVal;
    
    if (range == 0) return List.filled(length, 0.5);
    
    return map((value) => (value - minVal) / range).toList();
  }
  
  /// Z-score normalization
  List<double> standardize() {
    if (length < 2) return List.filled(length, 0.0);
    
    final meanValue = mean;
    final stdDev = standardDeviation;
    
    if (stdDev == 0) return List.filled(length, 0.0);
    
    return map((value) => (value - meanValue) / stdDev).toList();
  }
  
  // ===== SMOOTHING =====
  
  /// Moving average
  List<double> movingAverage(int windowSize) {
    if (windowSize <= 0 || windowSize > length) return map((e) => e.toDouble()).toList();
    
    final result = <double>[];
    
    for (int i = 0; i <= length - windowSize; i++) {
      final window = sublist(i, i + windowSize);
      result.add(window.sum / windowSize);
    }
    
    return result;
  }
  
  /// Exponential moving average
  List<double> exponentialMovingAverage(double alpha) {
    if (isEmpty) return [];
    if (alpha < 0 || alpha > 1) throw ArgumentError('Alpha must be between 0 and 1');
    
    final result = <double>[];
    double ema = this[0].toDouble();
    result.add(ema);
    
    for (int i = 1; i < length; i++) {
      ema = alpha * this[i] + (1 - alpha) * ema;
      result.add(ema);
    }
    
    return result;
  }
  
  // ===== OUTLIER DETECTION =====
  
  /// IQR method ile outlier'ları tespit et
  List<bool> detectOutliersIQR({double factor = 1.5}) {
    if (length < 4) return List.filled(length, false);
    
    final q1Value = q1;
    final q3Value = q3;
    final iqrValue = iqr;
    
    final lowerBound = q1Value - factor * iqrValue;
    final upperBound = q3Value + factor * iqrValue;
    
    return map((value) => value < lowerBound || value > upperBound).toList();
  }
  
  /// Z-score method ile outlier'ları tespit et
  List<bool> detectOutliersZScore({double threshold = 3.0}) {
    final zScores = standardize();
    return zScores.map((z) => z.abs() > threshold).toList();
  }
  
  /// Outlier'ları kaldır
  List<T> removeOutliers({OutlierMethod method = OutlierMethod.iqr}) {
    List<bool> outliers;
    
    switch (method) {
      case OutlierMethod.iqr:
        outliers = detectOutliersIQR();
        break;
      case OutlierMethod.zScore:
        outliers = detectOutliersZScore();
        break;
    }
    
    final result = <T>[];
    for (int i = 0; i < length; i++) {
      if (!outliers[i]) result.add(this[i]);
    }
    
    return result;
  }
  
  // ===== SIGNAL PROCESSING =====
  
  /// Simple derivative (first difference)
  List<double> derivative() {
    if (length < 2) return [];
    
    final result = <double>[];
    for (int i = 1; i < length; i++) {
      result.add((this[i] - this[i-1]).toDouble());
    }
    
    return result;
  }
  
  /// Cumulative sum
  List<double> cumSum() {
    if (isEmpty) return [];
    
    final result = <double>[];
    double cumulative = 0.0;
    
    for (final value in this) {
      cumulative += value;
      result.add(cumulative);
    }
    
    return result;
  }
  
  /// Peak detection (simple)
  List<int> findPeaks({double? minHeight, double? minDistance}) {
    if (length < 3) return [];
    
    final peaks = <int>[];
    
    for (int i = 1; i < length - 1; i++) {
      final current = this[i];
      final prev = this[i-1];
      final next = this[i+1];
      
      if (current > prev && current > next) {
        if (minHeight == null || current >= minHeight) {
          if (minDistance == null || peaks.isEmpty || (i - peaks.last) >= minDistance) {
            peaks.add(i);
          }
        }
      }
    }
    
    return peaks;
  }
  
  // ===== CORRELATION =====
  
  /// Pearson correlation coefficient
  double correlationWith(List<num> other) {
    if (length != other.length || length < 2) return 0.0;
    
    final meanX = mean;
    final meanY = other.mean;
    
    double numerator = 0.0;
    double denomX = 0.0;
    double denomY = 0.0;
    
    for (int i = 0; i < length; i++) {
      final diffX = this[i] - meanX;
      final diffY = other[i] - meanY;
      
      numerator += diffX * diffY;
      denomX += diffX * diffX;
      denomY += diffY * diffY;
    }
    
    final denominator = math.sqrt(denomX * denomY);
    return denominator != 0 ? numerator / denominator : 0.0;
  }
}

/// Force data için özel extension'lar
extension ForceDataListExtensions on List<double> {
  
  /// RFD (Rate of Force Development) hesapla
  List<double> calculateRFD({int windowSize = 10}) {
    if (length < windowSize + 1) return [];
    
    final rfd = <double>[];
    
    for (int i = windowSize; i < length; i++) {
      final startIndex = i - windowSize;
      final forceChange = this[i] - this[startIndex];
      final timeChange = windowSize.toDouble(); // Assuming 1ms intervals
      
      rfd.add(forceChange / timeChange * 1000); // Convert to N/s
    }
    
    return rfd;
  }
  
  /// Impulse hesapla (area under curve)
  double calculateImpulse({double sampleRate = 1000}) {
    if (isEmpty) return 0.0;
    
    final timeInterval = 1.0 / sampleRate;
    return sum * timeInterval;
  }
  
  /// Phase detection (basit threshold tabanlı)
  List<ForcePhase> detectPhases({
    required double bodyWeight,
    double takeoffThreshold = 0.1,
    double landingThreshold = 0.5,
  }) {
    if (isEmpty) return [];
    
    final phases = <ForcePhase>[];
    bool inAir = false;
    
    for (int i = 0; i < length; i++) {
      final forceRatio = this[i] / bodyWeight;
      
      if (!inAir && forceRatio < takeoffThreshold) {
        phases.add(ForcePhase.takeoff);
        inAir = true;
      } else if (inAir && forceRatio > landingThreshold) {
        phases.add(ForcePhase.landing);
        inAir = false;
      } else if (!inAir) {
        if (forceRatio < 0.8) {
          phases.add(ForcePhase.unloading);
        } else if (forceRatio > 1.2) {
          phases.add(ForcePhase.propulsion);
        } else {
          phases.add(ForcePhase.standing);
        }
      } else {
        phases.add(ForcePhase.flight);
      }
    }
    
    return phases;
  }
}

/// Outlier detection methods
enum OutlierMethod { iqr, zScore }

/// Force phases
enum ForcePhase { standing, unloading, propulsion, takeoff, flight, landing }