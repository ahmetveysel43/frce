extension DoubleExtensions on double {
  /// Newton'u kilogram'a çevir
  double get toKg => this / 9.81;
  
  /// Kilogram'ı Newton'a çevir
  double get toNewton => this * 9.81;
  
  /// Metre'yi santimetre'ye çevir
  double get toCm => this * 100;
  
  /// Santimetre'yi metre'ye çevir
  double get toM => this / 100;
  
  /// Saniye'yi milisaniye'ye çevir
  double get toMs => this * 1000;
  
  /// Milisaniye'yi saniye'ye çevir
  double get toS => this / 1000;
  
  /// Değerin belirli bir aralıkta olup olmadığını kontrol et
  bool isBetween(double min, double max) {
    return this >= min && this <= max;
  }
  
  /// Değeri belirli ondalık basamakta yuvarla
  double roundTo(int decimalPlaces) {
    final factor = 10.0 * decimalPlaces;
    return (this * factor).round() / factor;
  }
  
  /// Değerin sıfıra yakın olup olmadığını kontrol et
  bool get isNearZero => (this).abs() < 0.001;
  
  /// Değerin pozitif olup olmadığını kontrol et
  bool get isPositive => this > 0;
  
  /// Değerin negatif olup olmadığını kontrol et
  bool get isNegative => this < 0;
  
  /// Değeri yüzde olarak formatla
  String toPercentage([int decimalPlaces = 1]) {
    return '${(this * 100).toStringAsFixed(decimalPlaces)}%';
  }
  
  /// Değeri kuvvet birimi ile formatla
  String toForceString([int decimalPlaces = 1]) {
    return '${toStringAsFixed(decimalPlaces)} N';
  }
  
  /// Değeri güç birimi ile formatla
  String toPowerString([int decimalPlaces = 1]) {
    return '${toStringAsFixed(decimalPlaces)} W';
  }
  
  /// Değeri zaman birimi ile formatla
  String toTimeString([int decimalPlaces = 3]) {
    return '${toStringAsFixed(decimalPlaces)} s';
  }
  
  /// Değeri mesafe birimi ile formatla
  String toDistanceString([int decimalPlaces = 2]) {
    return '${toStringAsFixed(decimalPlaces)} cm';
  }
}