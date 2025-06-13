import 'package:equatable/equatable.dart';
import 'dart:math' as math;

/// Force plate ham veri entity
class ForceData extends Equatable {
  final int timestamp; // milliseconds since epoch
  final double leftGRF; // Ground Reaction Force - Sol (N)
  final double rightGRF; // Ground Reaction Force - Sağ (N)
  final double totalGRF; // Toplam kuvvet (N)
  final double? leftCopX; // Center of Pressure X - Sol (mm)
  final double? leftCopY; // Center of Pressure Y - Sol (mm)
  final double? rightCopX; // Center of Pressure X - Sağ (mm)
  final double? rightCopY; // Center of Pressure Y - Sağ (mm)

  const ForceData({
    required this.timestamp,
    required this.leftGRF,
    required this.rightGRF,
    required this.totalGRF,
    this.leftCopX,
    this.leftCopY,
    this.rightCopX,
    this.rightCopY,
  });

  /// Relative timestamp (test başlangıcından itibaren ms)
  int relativeTimestamp(int testStartTime) => timestamp - testStartTime;

  /// Relative timestamp in seconds
  double relativeTimeInSeconds(int testStartTime) => 
      relativeTimestamp(testStartTime) / 1000.0;

  /// Asimetri indeksi (%) - Sol/Sağ platform kuvvet farkı
  double get asymmetryIndex {
    final total = leftGRF + rightGRF;
    if (total <= 0) return 0.0;
    
    final difference = (leftGRF - rightGRF).abs();
    return (difference / total) * 100;
  }

  /// Sol platform yük yüzdesi
  double get leftLoadPercentage {
    final total = leftGRF + rightGRF;
    if (total <= 0) return 50.0;
    return (leftGRF / total) * 100;
  }

  /// Sağ platform yük yüzdesi
  double get rightLoadPercentage {
    final total = leftGRF + rightGRF;
    if (total <= 0) return 50.0;
    return (rightGRF / total) * 100;
  }

  /// Center of Pressure - Combined (her iki platform)
  ({double x, double y})? get combinedCOP {
    if (leftCopX == null || leftCopY == null || 
        rightCopX == null || rightCopY == null) {
      return null;
    }

    final totalForce = leftGRF + rightGRF;
    if (totalForce <= 0) return null;

    // Weighted average based on force distribution
    final x = (leftCopX! * leftGRF + rightCopX! * rightGRF) / totalForce;
    final y = (leftCopY! * leftGRF + rightCopY! * rightGRF) / totalForce;

    return (x: x, y: y);
  }

  /// COP displacement from center (mm)
  double? get copDisplacement {
    final cop = combinedCOP;
    if (cop == null) return null;
    
    // Platform center assumed to be (0, 0)
    return math.sqrt(cop.x * cop.x + cop.y * cop.y);
  }

  /// Platform dengesi kontrolü (iyi denge = düşük asimetri)
  bool get isBalanced => asymmetryIndex < 10.0; // %10 threshold

  /// Kuvvet seviyesi kategorisi
  ForceLevel get forceLevel {
    if (totalGRF < 50) return ForceLevel.minimal;
    if (totalGRF < 200) return ForceLevel.low;
    if (totalGRF < 500) return ForceLevel.moderate;
    if (totalGRF < 1000) return ForceLevel.high;
    return ForceLevel.maximum;
  }

  /// Copy with
  ForceData copyWith({
    int? timestamp,
    double? leftGRF,
    double? rightGRF,
    double? totalGRF,
    double? leftCopX,
    double? leftCopY,
    double? rightCopX,
    double? rightCopY,
  }) {
    return ForceData(
      timestamp: timestamp ?? this.timestamp,
      leftGRF: leftGRF ?? this.leftGRF,
      rightGRF: rightGRF ?? this.rightGRF,
      totalGRF: totalGRF ?? this.totalGRF,
      leftCopX: leftCopX ?? this.leftCopX,
      leftCopY: leftCopY ?? this.leftCopY,
      rightCopX: rightCopX ?? this.rightCopX,
      rightCopY: rightCopY ?? this.rightCopY,
    );
  }

  /// Factory - create with auto total calculation
  factory ForceData.create({
    required int timestamp,
    required double leftGRF,
    required double rightGRF,
    double? leftCopX,
    double? leftCopY,
    double? rightCopX,
    double? rightCopY,
  }) {
    return ForceData(
      timestamp: timestamp,
      leftGRF: math.max(0, leftGRF), // Negatif değerleri engelle
      rightGRF: math.max(0, rightGRF),
      totalGRF: math.max(0, leftGRF) + math.max(0, rightGRF),
      leftCopX: leftCopX,
      leftCopY: leftCopY,
      rightCopX: rightCopX,
      rightCopY: rightCopY,
    );
  }

  /// Factory - from USB raw data (8 load cell)
  factory ForceData.fromRawLoadCells({
    required int timestamp,
    required List<double> loadCellValues, // 8 değer (her platform 4'er)
    double platformWidth = 400.0, // mm
    double platformLength = 600.0, // mm
  }) {
    assert(loadCellValues.length == 8, 'Load cell değerleri 8 adet olmalı');

    // Sol platform load cell'leri (0-3), Sağ platform (4-7)
    final leftValues = loadCellValues.sublist(0, 4);
    final rightValues = loadCellValues.sublist(4, 8);

    final leftGRF = leftValues.reduce((a, b) => a + b);
    final rightGRF = rightValues.reduce((a, b) => a + b);

    // COP hesaplama (load cell pozisyonlarına göre)
    final leftCOP = _calculateCOP(leftValues, platformWidth, platformLength);
    final rightCOP = _calculateCOP(rightValues, platformWidth, platformLength);

    return ForceData.create(
      timestamp: timestamp,
      leftGRF: leftGRF,
      rightGRF: rightGRF,
      leftCopX: leftCOP.x,
      leftCopY: leftCOP.y,
      rightCopX: rightCOP.x,
      rightCopY: rightCOP.y,
    );
  }

  /// COP hesaplama (4 load cell için)
  static ({double x, double y}) _calculateCOP(
    List<double> forces,
    double width,
    double length,
  ) {
    // Load cell pozisyonları (platform merkezine göre)
    final positions = [
      (-width/2, -length/2), // Sol ön
      (width/2, -length/2),  // Sağ ön
      (-width/2, length/2),  // Sol arka
      (width/2, length/2),   // Sağ arka
    ];

    final totalForce = forces.reduce((a, b) => a + b);
    if (totalForce <= 0) return (x: 0.0, y: 0.0);

    double copX = 0;
    double copY = 0;

    for (int i = 0; i < 4; i++) {
      copX += forces[i] * positions[i].$1;
      copY += forces[i] * positions[i].$2;
    }

    return (x: copX / totalForce, y: copY / totalForce);
  }

  /// To database map
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'leftGRF': leftGRF,
      'rightGRF': rightGRF,
      'totalGRF': totalGRF,
      'leftCOP_x': leftCopX,
      'leftCOP_y': leftCopY,
      'rightCOP_x': rightCopX,
      'rightCOP_y': rightCopY,
    };
  }

  /// From database map
  factory ForceData.fromMap(Map<String, dynamic> map) {
    return ForceData(
      timestamp: map['timestamp'] as int,
      leftGRF: map['leftGRF'] as double,
      rightGRF: map['rightGRF'] as double,
      totalGRF: map['totalGRF'] as double,
      leftCopX: map['leftCOP_x'] as double?,
      leftCopY: map['leftCOP_y'] as double?,
      rightCopX: map['rightCOP_x'] as double?,
      rightCopY: map['rightCOP_y'] as double?,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() => toMap();

  /// From JSON
  factory ForceData.fromJson(Map<String, dynamic> json) => ForceData.fromMap(json);

  @override
  List<Object?> get props => [
        timestamp,
        leftGRF,
        rightGRF,
        totalGRF,
        leftCopX,
        leftCopY,
        rightCopX,
        rightCopY,
      ];

  @override
  String toString() {
    return 'ForceData(t: ${timestamp}ms, L: ${leftGRF.toStringAsFixed(1)}N, '
           'R: ${rightGRF.toStringAsFixed(1)}N, Total: ${totalGRF.toStringAsFixed(1)}N)';
  }
}

/// Kuvvet seviyeleri
enum ForceLevel {
  minimal('Minimal', 'Minimal'),
  low('Low', 'Düşük'),
  moderate('Moderate', 'Orta'),
  high('High', 'Yüksek'),
  maximum('Maximum', 'Maksimum');

  const ForceLevel(this.englishName, this.turkishName);
  final String englishName;
  final String turkishName;
}

/// Force data collection helper
class ForceDataCollection {
  final List<ForceData> data;

  const ForceDataCollection(this.data);

  /// Boş koleksiyon
  factory ForceDataCollection.empty() => const ForceDataCollection([]);

  /// Collection statistics
  int get length => data.length;
  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;

  /// First/Last data points
  ForceData? get first => data.isNotEmpty ? data.first : null;
  ForceData? get last => data.isNotEmpty ? data.last : null;

  /// Duration calculation
  Duration get duration {
    if (data.length < 2) return Duration.zero;
    return Duration(milliseconds: data.last.timestamp - data.first.timestamp);
  }

  /// Sample rate (Hz)
  double get sampleRate {
    if (data.length < 2) return 0.0;
    final durationMs = data.last.timestamp - data.first.timestamp;
    return (data.length - 1) * 1000.0 / durationMs;
  }

  /// Peak values
  double get peakLeftGRF => data.isEmpty ? 0.0 : 
      data.map((d) => d.leftGRF).reduce(math.max);
  
  double get peakRightGRF => data.isEmpty ? 0.0 : 
      data.map((d) => d.rightGRF).reduce(math.max);
  
  double get peakTotalGRF => data.isEmpty ? 0.0 : 
      data.map((d) => d.totalGRF).reduce(math.max);

  /// Average values
  double get avgLeftGRF => data.isEmpty ? 0.0 : 
      data.map((d) => d.leftGRF).reduce((a, b) => a + b) / data.length;
  
  double get avgRightGRF => data.isEmpty ? 0.0 : 
      data.map((d) => d.rightGRF).reduce((a, b) => a + b) / data.length;
  
  double get avgTotalGRF => data.isEmpty ? 0.0 : 
      data.map((d) => d.totalGRF).reduce((a, b) => a + b) / data.length;

  /// Overall asymmetry
  double get overallAsymmetry => data.isEmpty ? 0.0 : 
      data.map((d) => d.asymmetryIndex).reduce((a, b) => a + b) / data.length;

  /// Time range filter
  ForceDataCollection timeRange(int startMs, int endMs) {
    final filtered = data.where((d) => 
        d.timestamp >= startMs && d.timestamp <= endMs).toList();
    return ForceDataCollection(filtered);
  }

  /// Force threshold filter
  ForceDataCollection forceThreshold(double minForce) {
    final filtered = data.where((d) => d.totalGRF >= minForce).toList();
    return ForceDataCollection(filtered);
  }

  /// Downsample data (performans için)
  ForceDataCollection downsample(int factor) {
    if (factor <= 1) return this;
    final downsampled = <ForceData>[];
    for (int i = 0; i < data.length; i += factor) {
      downsampled.add(data[i]);
    }
    return ForceDataCollection(downsampled);
  }

  /// Moving average (smoothing)
  ForceDataCollection smoothed(int windowSize) {
    if (windowSize <= 1 || data.length < windowSize) return this;
    
    final smoothed = <ForceData>[];
    final halfWindow = windowSize ~/ 2;
    
    for (int i = 0; i < data.length; i++) {
      final start = math.max(0, i - halfWindow);
      final end = math.min(data.length, i + halfWindow + 1);
      
      double sumLeft = 0, sumRight = 0, sumTotal = 0;
      for (int j = start; j < end; j++) {
        sumLeft += data[j].leftGRF;
        sumRight += data[j].rightGRF;
        sumTotal += data[j].totalGRF;
      }
      
      final count = end - start;
      smoothed.add(data[i].copyWith(
        leftGRF: sumLeft / count,
        rightGRF: sumRight / count,
        totalGRF: sumTotal / count,
      ));
    }
    
    return ForceDataCollection(smoothed);
  }

  /// Convert to list
  List<ForceData> toList() => List.from(data);

  /// Add data point
  ForceDataCollection add(ForceData point) {
    return ForceDataCollection([...data, point]);
  }

  /// Add multiple data points
  ForceDataCollection addAll(List<ForceData> points) {
    return ForceDataCollection([...data, ...points]);
  }
}

/// Mock force data generator (development için)
class MockForceDataGenerator {
  static ForceDataCollection generateCMJ({
    int duration = 5000, // ms
    int sampleRate = 1000, // Hz
    double bodyWeight = 700, // N
  }) {
    final data = <ForceData>[];
    final samples = (duration * sampleRate) ~/ 1000;
    final startTime = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate; // seconds
      final timestamp = startTime + (t * 1000).round();
      
      // CMJ pattern simulation
      double totalForce = bodyWeight;
      
      if (t < 1.0) {
        // Quiet standing
        totalForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 20;
      } else if (t < 1.5) {
        // Unloading phase
        final phase = (t - 1.0) / 0.5;
        totalForce = bodyWeight * (1.0 - 0.3 * phase) + 
                    (math.Random().nextDouble() - 0.5) * 30;
      } else if (t < 2.0) {
        // Braking phase
        final phase = (t - 1.5) / 0.5;
        totalForce = bodyWeight * (0.7 + 1.5 * phase) + 
                    (math.Random().nextDouble() - 0.5) * 50;
      } else if (t < 2.2) {
        // Propulsion phase
        final phase = (t - 2.0) / 0.2;
        totalForce = bodyWeight * (2.2 - 0.4 * phase) + 
                    (math.Random().nextDouble() - 0.5) * 40;
      } else if (t < 2.6) {
        // Flight phase
        totalForce = (math.Random().nextDouble() - 0.5) * 10;
      } else if (t < 3.0) {
        // Landing phase
        final phase = (t - 2.6) / 0.4;
        totalForce = bodyWeight * (0.5 + 1.5 * phase) + 
                    (math.Random().nextDouble() - 0.5) * 60;
      } else {
        // Recovery
        totalForce = bodyWeight + (math.Random().nextDouble() - 0.5) * 20;
      }

      // Asymmetry simulation (5-15%)
      final asymmetry = 0.05 + math.Random().nextDouble() * 0.10;
      final leftGRF = totalForce * (0.5 + asymmetry/2);
      final rightGRF = totalForce * (0.5 - asymmetry/2);

      data.add(ForceData.create(
        timestamp: timestamp,
        leftGRF: math.max(0, leftGRF),
        rightGRF: math.max(0, rightGRF),
        leftCopX: (math.Random().nextDouble() - 0.5) * 100,
        leftCopY: (math.Random().nextDouble() - 0.5) * 150,
        rightCopX: (math.Random().nextDouble() - 0.5) * 100,
        rightCopY: (math.Random().nextDouble() - 0.5) * 150,
      ));
    }

    return ForceDataCollection(data);
  }
}