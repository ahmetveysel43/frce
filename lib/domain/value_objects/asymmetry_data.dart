import 'package:equatable/equatable.dart';

enum AsymmetryType {
  force,      // Kuvvet asimetrisi
  impulse,    // İmpuls asimetrisi
  temporal,   // Zaman asimetrisi
  spatial,    // Mekansal asimetri
}

class AsymmetryData extends Equatable {
  final AsymmetryType type;
  final double leftValue;
  final double rightValue;
  final double percentage; // Asimetri yüzdesi
  final double asymmetryIndex; // -100 to +100 (negatif: sol baskın, pozitif: sağ baskın)
  final DateTime calculatedAt;

  const AsymmetryData({
    required this.type,
    required this.leftValue,
    required this.rightValue,
    required this.percentage,
    required this.asymmetryIndex,
    required this.calculatedAt,
  });

  // Factory constructors
  factory AsymmetryData.fromValues({
    required AsymmetryType type,
    required double leftValue,
    required double rightValue,
  }) {
    final total = leftValue + rightValue;
    final percentage = total == 0 ? 0.0 : ((leftValue - rightValue).abs() / total) * 100;
    final asymmetryIndex = total == 0 ? 0.0 : ((rightValue - leftValue) / total) * 100;

    return AsymmetryData(
      type: type,
      leftValue: leftValue,
      rightValue: rightValue,
      percentage: percentage,
      asymmetryIndex: asymmetryIndex,
      calculatedAt: DateTime.now(),
    );
  }

  // Computed properties
  double get totalValue => leftValue + rightValue;
  
  bool get isLeftDominant => asymmetryIndex < 0;
  bool get isRightDominant => asymmetryIndex > 0;
  bool get isSymmetric => percentage < 10.0; // %10'dan az asimetri
  
  String get dominantSide {
    if (isSymmetric) return 'Simetrik';
    return isLeftDominant ? 'Sol' : 'Sağ';
  }

  String get asymmetryLevel {
    if (percentage < 5.0) return 'Minimal';
    if (percentage < 10.0) return 'Hafif';
    if (percentage < 15.0) return 'Orta';
    if (percentage < 25.0) return 'Yüksek';
    return 'Çok Yüksek';
  }

  String get typeDescription {
    switch (type) {
      case AsymmetryType.force:
        return 'Kuvvet Asimetrisi';
      case AsymmetryType.impulse:
        return 'İmpuls Asimetrisi';
      case AsymmetryType.temporal:
        return 'Zaman Asimetrisi';
      case AsymmetryType.spatial:
        return 'Mekansal Asimetri';
    }
  }

  // Clinical interpretation
  String get clinicalInterpretation {
    if (isSymmetric) {
      return 'Normal simetrik performans';
    }
    
    final side = dominantSide.toLowerCase();
    final level = asymmetryLevel.toLowerCase();
    
    return '$side taraf $level asimetri (${percentage.toStringAsFixed(1)}%)';
  }

  bool get needsAttention => percentage > 15.0;
  
  String get recommendation {
    if (!needsAttention) return 'Asimetri normal sınırlarda';
    
    return 'Yüksek asimetri tespit edildi. '
           '${dominantSide == 'Sol' ? 'Sağ' : 'Sol'} taraf güçlendirme egzersizleri önerilir.';
  }

  @override
  List<Object> get props => [
        type,
        leftValue,
        rightValue,
        percentage,
        asymmetryIndex,
        calculatedAt,
      ];

  @override
  String toString() {
    return 'AsymmetryData(type: $type, percentage: ${percentage.toStringAsFixed(1)}%, '
           'dominant: $dominantSide)';
  }
}