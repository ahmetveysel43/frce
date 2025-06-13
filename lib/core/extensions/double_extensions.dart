import 'dart:math' as math;

/// Double değerler için utility extension'lar
extension DoubleExtensions on double {
  
  // ===== FORMATTING =====
  
  /// Değeri belirtilen ondalık basamakla formatla
  String toStringAsFixedSmart(int fractionDigits) {
    if (this == roundToDouble()) {
      return round().toString();
    }
    return toStringAsFixed(fractionDigits);
  }
  
  /// Akıllı formatla (büyük sayılar için k, M notasyonu)
  String toStringSmartFormat() {
    if (this.abs() >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this.abs() >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}k';
    } else if (this.abs() >= 100) {
      return toStringAsFixed(0);
    } else if (this.abs() >= 10) {
      return toStringAsFixed(1);
    } else {
      return toStringAsFixed(2);
    }
  }
  
  /// Force değeri formatla (Newton)
  String toForceString({bool showUnit = true}) {
    final formatted = toStringSmartFormat();
    return showUnit ? '$formatted N' : formatted;
  }
  
  /// Yüzde formatla
  String toPercentageString({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }
  
  /// Zaman formatla (milisaniye)
  String toTimeString({bool showUnit = true}) {
    final formatted = toStringAsFixed(0);
    return showUnit ? '$formatted ms' : formatted;
  }
  
  /// Mesafe formatla (cm/mm)
  String toDistanceString({String unit = 'cm', int decimals = 1}) {
    return '${toStringAsFixed(decimals)} $unit';
  }
  
  // ===== VALIDATION =====
  
  /// Değerin geçerli bir sayı olup olmadığını kontrol et
  bool get isValidNumber => !isNaN && isFinite;
  
  /// Pozitif değer mi?
  bool get isPositive => this > 0;
  
  /// Negatif değer mi?
  bool get isNegative => this < 0;
  
  /// Sıfır veya pozitif mi?
  bool get isNonNegative => this >= 0;
  
  /// Belirtilen aralıkta mı?
  bool isInRange(double min, double max) => this >= min && this <= max;
  
  /// Yaklaşık olarak eşit mi? (epsilon toleransı ile)
  bool isApproximatelyEqual(double other, {double epsilon = 0.001}) {
    return (this - other).abs() < epsilon;
  }
  
  // ===== MATHEMATICAL OPERATIONS =====
  
  /// Değeri belirtilen aralığa sınırla
  double clampToRange(double min, double max) => clamp(min, max).toDouble();
  
  /// Değeri yüzdeye çevir (0.75 -> 75.0)
  double get asPercentage => this * 100;
  
  /// Yüzdeden değere çevir (75.0 -> 0.75)
  double get fromPercentage => this / 100;
  
  /// Radyandan dereceye çevir
  double get toDegrees => this * 180 / math.pi;
  
  /// Dereceden radyana çevir
  double get toRadians => this * math.pi / 180;
  
  /// Karekök
  double get sqrt => math.sqrt(this);
  
  /// Karesi
  double get squared => this * this;
  
  /// Küpü
  double get cubed => this * this * this;
  
  /// Mutlak değer
  double get abs => this.abs();
  
  /// İşaret fonksiyonu (-1, 0, 1)
  int get sign {
    if (this > 0) return 1;
    if (this < 0) return -1;
    return 0;
  }
  
  // ===== FORCE PLATE SPECIFIC =====
  
  /// Newton'dan kilogram'a çevir (9.81 ile böl)
  double get toKilograms => this / 9.81;
  
  /// Kilogram'dan Newton'a çevir (9.81 ile çarp)
  double get toNewtons => this * 9.81;
  
  /// BMI hesapla (kg/m²)
  double calculateBMI(double heightInMeters) {
    if (heightInMeters <= 0) return 0;
    return this / (heightInMeters * heightInMeters);
  }
  
  /// Jump height hesapla (flight time'dan)
  double calculateJumpHeightFromFlightTime() {
    // h = (g * t²) / 8
    return (9.81 * squared) / 8;
  }
  
  /// Flight time hesapla (jump height'tan)
  double calculateFlightTimeFromJumpHeight() {
    // t = sqrt(8 * h / g)
    return math.sqrt(8 * this / 9.81);
  }
  
  /// Power hesapla (Force * Velocity)
  double calculatePower(double velocity) => this * velocity;
  
  /// Asimetri indeksini hesapla
  double calculateAsymmetryWith(double other) {
    final total = this + other;
    if (total == 0) return 0;
    return ((this - other).abs() / total) * 100;
  }
  
  // ===== STATISTICAL =====
  
  /// Normalize et (0-1 aralığına)
  double normalize(double min, double max) {
    if (max == min) return 0;
    return (this - min) / (max - min);
  }
  
  /// Z-score hesapla
  double zScore(double mean, double standardDeviation) {
    if (standardDeviation == 0) return 0;
    return (this - mean) / standardDeviation;
  }
  
  /// Linear interpolation
  double lerp(double other, double t) => this + (other - this) * t;
  
  /// Smoothstep (smooth interpolation)
  double smoothstep(double edge0, double edge1) {
    final t = ((this - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }
  
  // ===== ROUNDING =====
  
  /// Belirtilen sayıya yuvarla
  double roundToNearest(double nearest) {
    return (this / nearest).round() * nearest;
  }
  
  /// Ondalık basamakları yuvarla
  double roundToDecimals(int decimals) {
    final factor = math.pow(10, decimals);
    return (this * factor).round() / factor;
  }
  
  /// Yukarı yuvarla (ceil)
  double get ceiling => ceilToDouble();
  
  /// Aşağı yuvarla (floor)
  double get floor => floorToDouble();
  
  // ===== QUALITY ASSESSMENT =====
  
  /// Force değeri için kalite değerlendirmesi
  ForceQuality get forceQuality {
    if (this < 100) return ForceQuality.veryLow;
    if (this < 500) return ForceQuality.low;
    if (this < 1000) return ForceQuality.moderate;
    if (this < 2000) return ForceQuality.high;
    return ForceQuality.veryHigh;
  }
  
  /// Asimetri için kalite değerlendirmesi
  AsymmetryQuality get asymmetryQuality {
    if (this < 5) return AsymmetryQuality.excellent;
    if (this < 10) return AsymmetryQuality.good;
    if (this < 15) return AsymmetryQuality.fair;
    if (this < 25) return AsymmetryQuality.poor;
    return AsymmetryQuality.veryPoor;
  }
  
  /// Jump height için kalite değerlendirmesi
  JumpQuality get jumpQuality {
    if (this < 15) return JumpQuality.poor;
    if (this < 25) return JumpQuality.fair;
    if (this < 35) return JumpQuality.good;
    if (this < 45) return JumpQuality.excellent;
    return JumpQuality.elite;
  }
  
  // ===== UNIT CONVERSIONS =====
  
  /// Celsius'dan Fahrenheit'a
  double get celsiusToFahrenheit => (this * 9/5) + 32;
  
  /// Fahrenheit'tan Celsius'a
  double get fahrenheitToCelsius => (this - 32) * 5/9;
  
  /// Metre'den feet'e
  double get metersToFeet => this * 3.28084;
  
  /// Feet'ten metre'ye
  double get feetToMeters => this / 3.28084;
  
  /// Kilogram'dan pound'a
  double get kilogramsToPounds => this * 2.20462;
  
  /// Pound'dan kilogram'a
  double get poundsToKilograms => this / 2.20462;
  
  // ===== ANIMATION HELPERS =====
  
  /// Ease-in easing function
  double get easeIn => this * this;
  
  /// Ease-out easing function
  double get easeOut => 1 - (1 - this).squared;
  
  /// Ease-in-out easing function
  double get easeInOut {
    if (this < 0.5) {
      return 2 * this * this;
    } else {
      return 1 - 2 * (1 - this).squared;
    }
  }
  
  /// Bounce easing function
  double get bounce {
    if (this < 1/2.75) {
      return 7.5625 * this * this;
    } else if (this < 2/2.75) {
      final t = this - 1.5/2.75;
      return 7.5625 * t * t + 0.75;
    } else if (this < 2.5/2.75) {
      final t = this - 2.25/2.75;
      return 7.5625 * t * t + 0.9375;
    } else {
      final t = this - 2.625/2.75;
      return 7.5625 * t * t + 0.984375;
    }
  }
}

/// Force kalite enum'u
enum ForceQuality {
  veryLow('Çok Düşük'),
  low('Düşük'),
  moderate('Orta'),
  high('Yüksek'),
  veryHigh('Çok Yüksek');
  
  const ForceQuality(this.turkishName);
  final String turkishName;
}

/// Asimetri kalite enum'u
enum AsymmetryQuality {
  excellent('Mükemmel'),
  good('İyi'),
  fair('Orta'),
  poor('Zayıf'),
  veryPoor('Çok Zayıf');
  
  const AsymmetryQuality(this.turkishName);
  final String turkishName;
}

/// Jump kalite enum'u
enum JumpQuality {
  poor('Zayıf'),
  fair('Orta'),
  good('İyi'),
  excellent('Mükemmel'),
  elite('Elite');
  
  const JumpQuality(this.turkishName);
  final String turkishName;
}

/// Nullable double extension'ı
extension NullableDoubleExtensions on double? {
  /// Null ise varsayılan değer döndür
  double orDefault([double defaultValue = 0.0]) => this ?? defaultValue;
  
  /// Null değilse ve geçerliyse true
  bool get isValidAndNotNull => this != null && this!.isValidNumber;
  
  /// Güvenli formatla
  String toStringSafe({int decimals = 2, String nullText = 'N/A'}) {
    return this?.toStringAsFixed(decimals) ?? nullText;
  }
  
  /// Güvenli smart format
  String toStringSmartSafe({String nullText = 'N/A'}) {
    return this?.toStringSmartFormat() ?? nullText;
  }
}