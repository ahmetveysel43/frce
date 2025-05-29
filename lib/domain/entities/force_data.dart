// lib/domain/entities/force_data.dart
class ForceData {
  final DateTime timestamp;
  
  // Sol platform verileri
  final double leftGRF;      // Ground Reaction Force (Newton)
  final double leftCoPX;     // Center of Pressure X (mm)
  final double leftCoPY;     // Center of Pressure Y (mm)
  
  // Sağ platform verileri
  final double rightGRF;     // Ground Reaction Force (Newton)
  final double rightCoPX;    // Center of Pressure X (mm)
  final double rightCoPY;    // Center of Pressure Y (mm)
  
  // Toplam ve hesaplanan metrikler
  final double totalGRF;           // Toplam kuvvet
  final double asymmetryIndex;     // Asimetri indeksi (0-1)
  final double stabilityIndex;     // Stabilite indeksi (0-1)
  final double loadRate;           // Yüklenme hızı (N/s)
  
  // Opsiyonel: Ham yük hücresi verileri (8 sensör)
  final List<double>? leftDeckForces;   // Sol platform 4 sensör
  final List<double>? rightDeckForces;  // Sağ platform 4 sensör
  final double? samplingRate;           // Örnekleme hızı (Hz)
  final int? sampleIndex;               // Örnek numarası

  const ForceData({
    required this.timestamp,
    required this.leftGRF,
    required this.leftCoPX,
    required this.leftCoPY,
    required this.rightGRF,
    required this.rightCoPX,
    required this.rightCoPY,
    required this.totalGRF,
    required this.asymmetryIndex,
    required this.stabilityIndex,
    required this.loadRate,
    this.leftDeckForces,
    this.rightDeckForces,
    this.samplingRate,
    this.sampleIndex,
  });

  // Kolay kopyalama için copyWith metodu
  ForceData copyWith({
    DateTime? timestamp,
    double? leftGRF,
    double? leftCoPX,
    double? leftCoPY,
    double? rightGRF,
    double? rightCoPX,
    double? rightCoPY,
    double? totalGRF,
    double? asymmetryIndex,
    double? stabilityIndex,
    double? loadRate,
    List<double>? leftDeckForces,
    List<double>? rightDeckForces,
    double? samplingRate,
    int? sampleIndex,
  }) {
    return ForceData(
      timestamp: timestamp ?? this.timestamp,
      leftGRF: leftGRF ?? this.leftGRF,
      leftCoPX: leftCoPX ?? this.leftCoPX,
      leftCoPY: leftCoPY ?? this.leftCoPY,
      rightGRF: rightGRF ?? this.rightGRF,
      rightCoPX: rightCoPX ?? this.rightCoPX,
      rightCoPY: rightCoPY ?? this.rightCoPY,
      totalGRF: totalGRF ?? this.totalGRF,
      asymmetryIndex: asymmetryIndex ?? this.asymmetryIndex,
      stabilityIndex: stabilityIndex ?? this.stabilityIndex,
      loadRate: loadRate ?? this.loadRate,
      leftDeckForces: leftDeckForces ?? this.leftDeckForces,
      rightDeckForces: rightDeckForces ?? this.rightDeckForces,
      samplingRate: samplingRate ?? this.samplingRate,
      sampleIndex: sampleIndex ?? this.sampleIndex,
    );
  }

  // Debug için toString
  @override
  String toString() {
    return 'ForceData(timestamp: $timestamp, totalGRF: ${totalGRF.toStringAsFixed(1)}N, asymmetry: ${(asymmetryIndex * 100).toStringAsFixed(1)}%)';
  }

  // Eşitlik kontrolü
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForceData &&
      other.timestamp == timestamp &&
      other.leftGRF == leftGRF &&
      other.rightGRF == rightGRF &&
      other.totalGRF == totalGRF;
  }

  @override
  int get hashCode {
    return timestamp.hashCode ^
      leftGRF.hashCode ^
      rightGRF.hashCode ^
      totalGRF.hashCode;
  }

  // Yardımcı metodlar
  bool get isBalanced => asymmetryIndex < 0.1; // %10'dan az asimetri
  bool get isStable => stabilityIndex > 0.7;   // %70'den fazla stabilite
  String get balanceStatus => isBalanced ? 'Dengeli' : 'Asimetrik';
  String get stabilityStatus => isStable ? 'Stabil' : 'Kararsız';
}