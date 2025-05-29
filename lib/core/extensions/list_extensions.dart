import '../utils/math_utils.dart';

extension ListExtensions<T> on List<T> {
  /// Liste boş mu kontrolü
  bool get isNotEmpty => !isEmpty;
  
  /// Güvenli eleman erişimi
  T? safeGet(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }
  
  /// Listenin son N elemanını al
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
  
  /// Listenin ilk N elemanını al (güvenli)
  List<T> safeSublist(int start, [int? end]) {
    final safeStart = start.clamp(0, length);
    final safeEnd = (end ?? length).clamp(safeStart, length);
    return sublist(safeStart, safeEnd);
  }
}

extension DoubleListExtensions on List<double> {
  /// Toplam değer
  double get sum => isEmpty ? 0.0 : reduce((a, b) => a + b);
  
  /// Ortalama değer
  double get mean => MathUtils.calculateMean(this);
  
  /// Standart sapma
  double get standardDeviation => MathUtils.calculateStandardDeviation(this);
  
  /// RMS değer
  double get rms => MathUtils.calculateRMS(this);
  
  /// Maksimum değer
  double get max => isEmpty ? 0.0 : reduce((a, b) => a > b ? a : b);
  
  /// Minimum değer
  double get min => isEmpty ? 0.0 : reduce((a, b) => a < b ? a : b);
  
  /// Değer aralığı (max - min)
  double get range => max - min;
  
  /// Maksimum değerin indeksi
  int get maxIndex => MathUtils.findMax(this).index;
  
  /// Minimum değerin indeksi
  int get minIndex => MathUtils.findMin(this).index;
  
  /// Belirli bir değerin üstündeki elemanları filtrele
  List<double> filterAbove(double threshold) {
    return where((value) => value > threshold).toList();
  }
  
  /// Belirli bir değerin altındaki elemanları filtrele
  List<double> filterBelow(double threshold) {
    return where((value) => value < threshold).toList();
  }
  
  /// Belirli bir aralıktaki elemanları filtrele
  List<double> filterBetween(double min, double max) {
    return where((value) => value >= min && value <= max).toList();
  }
  
  /// Hareketli ortalama hesapla
  List<double> movingAverage(int windowSize) {
    if (length < windowSize) return this;
    
    final result = <double>[];
    for (int i = 0; i <= length - windowSize; i++) {
      final window = sublist(i, i + windowSize);
      result.add(window.mean);
    }
    return result;
  }
  
  /// Baseline (ilk N değerin ortalaması) çıkar
  List<double> removeBaseline([int baselineSize = 100]) {
    if (isEmpty) return this;
    
    final actualBaselineSize = baselineSize.clamp(1, length);
    final baseline = take(actualBaselineSize).toList().mean;
    
    return map((value) => value - baseline).toList();
  }
  
  /// Normalize et (0-1 arası)
  List<double> normalize() {
    if (isEmpty) return this;
    
    final minVal = min;
    final maxVal = max;
    final range = maxVal - minVal;
    
    if (range == 0) return map((e) => 0.5).toList();
    
    return map((value) => (value - minVal) / range).toList();
  }
  
  /// Geçerli değerleri filtrele (NaN, Infinity vb. çıkar)
  List<double> filterValid() {
    return where((value) => value.isFinite).toList();
  }
}