// lib/domain/entities/force_data.dart - VALD ForceDecks Optimized
import 'package:equatable/equatable.dart';
import 'dart:math' as math;

/// VALD ForceDecks benzeri dual force plate system için optimize edilmiş ForceData
/// 
/// Sistem Özellikleri:
/// - 2 ayrı force platform (Left Deck + Right Deck)
/// - Her platform 4 load cell (toplam 8 load cell)
/// - 1000Hz+ sampling rate
/// - Bilateral analiz kapasitesi
/// - Center of Pressure (CoP) hesaplama
/// - Ground Reaction Force (GRF) ölçümü
class ForceData extends Equatable {
  final DateTime timestamp;
  
  // ✅ VALD ForceDecks benzeri dual platform yapısı
  final List<double> leftDeckForces;  // Sol platform 4 load cell [N]
  final List<double> rightDeckForces; // Sağ platform 4 load cell [N]
  
  final double samplingRate; // Hz
  final int sampleIndex;
  
  // ✅ Platform geometrisi (VALD ForceDecks standardı)
  static const double platformWidth = 0.4;   // 40cm
  static const double platformLength = 0.6;  // 60cm
  static const double platformSeparation = 0.1; // 10cm ara

  const ForceData({
    required this.timestamp,
    required this.leftDeckForces,
    required this.rightDeckForces,
    required this.samplingRate,
    required this.sampleIndex,
  });

  // ✅ Temel Force Metrics
  
  /// Sol platform toplam kuvveti
  double get leftDeckTotal => leftDeckForces.fold(0.0, (sum, force) => sum + force);
  
  /// Sağ platform toplam kuvveti  
  double get rightDeckTotal => rightDeckForces.fold(0.0, (sum, force) => sum + force);
  
  /// Toplam Ground Reaction Force (GRF)
  double get totalGRF => leftDeckTotal + rightDeckTotal;
  
  /// Bilateral Force Symmetry Index (FSI)
  /// VALD standardı: %15'ten az asimetri normal kabul edilir
  double get forceSymmetryIndex {
    if (totalGRF == 0) return 0.0;
    return ((leftDeckTotal - rightDeckTotal).abs() / totalGRF) * 100;
  }
  
  /// Limb Symmetry Index (LSI) - VALD terminolojisi
  double get limbSymmetryIndex {
    if (rightDeckTotal == 0) return 0.0;
    return (leftDeckTotal / rightDeckTotal) * 100;
  }

  // ✅ Center of Pressure (CoP) Calculations
  
  /// Sol platform Center of Pressure (X ekseni)
  double get leftDeckCoPX {
    if (leftDeckTotal == 0) return 0.0;
    
    // Load cell pozisyonları (platform merkezinden)
    const positions = [-0.15, -0.05, 0.05, 0.15]; // -15cm, -5cm, +5cm, +15cm
    
    double weightedSum = 0.0;
    for (int i = 0; i < leftDeckForces.length && i < positions.length; i++) {
      weightedSum += leftDeckForces[i] * positions[i];
    }
    
    return weightedSum / leftDeckTotal;
  }
  
  /// Sağ platform Center of Pressure (X ekseni)
  double get rightDeckCoPX {
    if (rightDeckTotal == 0) return 0.0;
    
    const positions = [-0.15, -0.05, 0.05, 0.15];
    
    double weightedSum = 0.0;
    for (int i = 0; i < rightDeckForces.length && i < positions.length; i++) {
      weightedSum += rightDeckForces[i] * positions[i];
    }
    
    return weightedSum / rightDeckTotal;
  }
  
  /// Combined Center of Pressure (X ekseni)
  double get combinedCoPX {
    if (totalGRF == 0) return 0.0;
    
    // Sol platform CoP'u negatif tarafta, sağ platform pozitif tarafta
    final leftContribution = leftDeckTotal * (leftDeckCoPX - platformSeparation/2);
    final rightContribution = rightDeckTotal * (rightDeckCoPX + platformSeparation/2);
    
    return (leftContribution + rightContribution) / totalGRF;
  }
  
  /// Medial-Lateral (ML) CoP sway - denge analizi için
  double get medialLateralSway => combinedCoPX.abs();

  // ✅ VALD ForceDecks benzeri Performance Metrics
  
  /// Peak Force (maksimum kuvvet)
  double get peakForce => totalGRF;
  
  /// Force Rate of Development (RFD) - yaklaşık hesaplama
  double get forceRFD {
    // Bu tek bir sample için tam RFD hesaplanamaz
    // Gerçek implementasyonda zaman serisi gerekir
    return totalGRF / (1.0 / samplingRate);
  }
  
  /// Load Rate (N/s) - VALD terminolojisi
  double get loadRate => forceRFD;
  
  /// Power estimate (W) - basitleştirilmiş
  double get estimatedPower {
    // P = F * v, velocity'yi kuvvetten türetiyoruz
    final velocity = totalGRF / 1000.0; // Basitleştirilmiş velocity
    return totalGRF * velocity;
  }

  // ✅ Quality Indicators
  
  /// Veri kalitesi kontrolü
  bool get isValidData {
    // Tüm kuvvetlerin makul aralıkta olması
    final allForces = [...leftDeckForces, ...rightDeckForces];
    return allForces.every((force) => 
      force.isFinite && force >= -100 && force <= 5000);
  }
  
  /// Platform yükleme dengesi
  bool get isBalancedLoading {
    return forceSymmetryIndex <= 50.0; // %50'den fazla asimetri anormal
  }
  
  /// VALD standardı: %15 asimetri eşiği
  bool get isWithinVALDNormalRange {
    return forceSymmetryIndex <= 15.0;
  }
  
  /// Veri kalitesi puanı (0-100)
  double get dataQuality {
    if (!isValidData) return 0.0;
    
    double score = 100.0;
    
    // Asimetri cezası
    if (forceSymmetryIndex > 15.0) {
      score -= (forceSymmetryIndex - 15.0) * 2;
    }
    
    // Load cell tutarlılık kontrolü
    final leftStdDev = _calculateStdDev(leftDeckForces);
    final rightStdDev = _calculateStdDev(rightDeckForces);
    final avgStdDev = (leftStdDev + rightStdDev) / 2;
    
    // Yüksek standart sapma = düşük kalite
    score -= avgStdDev / 10;
    
    return score.clamp(0.0, 100.0);
  }

  // ✅ VALD ForceDecks Test Scenarios
  
  /// Countermovement Jump için uygun mu?
  bool get isSuitableForCMJ {
    return isValidData && totalGRF > 200.0 && forceSymmetryIndex < 30.0;
  }
  
  /// Balance test için uygun mu?
  bool get isSuitableForBalance {
    return isValidData && totalGRF > 100.0 && totalGRF < 1500.0;
  }
  
  /// Isometric test için uygun mu?
  bool get isSuitableForIsometric {
    return isValidData && totalGRF > 300.0;
  }

  // ✅ Helper Methods
  
  double _calculateStdDev(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((v) => (v - mean) * (v - mean))
        .reduce((a, b) => a + b) / values.length;
    
    return variance.isFinite ? math.sqrt(variance) : 0.0;
  }

  // ✅ Factory Constructors
  
  /// VALD ForceDecks benzeri mock data oluştur
  factory ForceData.mockVALDForceDecks({
    DateTime? timestamp,
    double? bodyWeight,
    double? asymmetryPercent,
    int? sampleIndex,
  }) {
    final now = timestamp ?? DateTime.now();
    final weight = bodyWeight ?? 70.0; // kg
    final weightInNewtons = weight * 9.81; // N
    final asymmetry = asymmetryPercent ?? 5.0; // %5 default asymmetry
    final index = sampleIndex ?? 0;
    
    // Asimetri ile left/right dağılımı
    final asymmetryRatio = asymmetry / 100.0;
    final leftWeight = weightInNewtons * (0.5 + asymmetryRatio / 2);
    final rightWeight = weightInNewtons * (0.5 - asymmetryRatio / 2);
    
    // Her platform için 4 load cell değeri (slight variation)
    final leftForces = List.generate(4, (i) {
      final baseForce = leftWeight / 4;
      final variation = (math.Random().nextDouble() - 0.5) * 10; // ±5N variation
      return baseForce + variation + (i * 2); // Slight position difference
    });
    
    final rightForces = List.generate(4, (i) {
      final baseForce = rightWeight / 4;
      final variation = (math.Random().nextDouble() - 0.5) * 10;
      return baseForce + variation + (i * 2);
    });
    
    return ForceData(
      timestamp: now,
      leftDeckForces: leftForces,
      rightDeckForces: rightForces,
      samplingRate: 1000.0,
      sampleIndex: index,
    );
  }
  
  /// Quiet Standing için mock data
  factory ForceData.mockQuietStanding({
    DateTime? timestamp,
    double? bodyWeight,
    int? sampleIndex,
  }) {
    return ForceData.mockVALDForceDecks(
      timestamp: timestamp,
      bodyWeight: bodyWeight,
      asymmetryPercent: 2.0, // Minimal asymmetry for quiet standing
      sampleIndex: sampleIndex,
    );
  }
  
  /// Jump için mock data
  factory ForceData.mockJump({
    DateTime? timestamp,
    double? bodyWeight,
    double? jumpForceMultiplier,
    int? sampleIndex,
  }) {
    final multiplier = jumpForceMultiplier ?? 2.5; // 2.5x body weight
    return ForceData.mockVALDForceDecks(
      timestamp: timestamp,
      bodyWeight: (bodyWeight ?? 70.0) * multiplier,
      asymmetryPercent: 8.0, // Slightly higher asymmetry during jump
      sampleIndex: sampleIndex,
    );
  }

  // ✅ Copy with method
  ForceData copyWith({
    DateTime? timestamp,
    List<double>? leftDeckForces,
    List<double>? rightDeckForces,
    double? samplingRate,
    int? sampleIndex,
  }) {
    return ForceData(
      timestamp: timestamp ?? this.timestamp,
      leftDeckForces: leftDeckForces ?? this.leftDeckForces,
      rightDeckForces: rightDeckForces ?? this.rightDeckForces,
      samplingRate: samplingRate ?? this.samplingRate,
      sampleIndex: sampleIndex ?? this.sampleIndex,
    );
  }

  @override
  List<Object?> get props => [
        timestamp,
        leftDeckForces,
        rightDeckForces,
        samplingRate,
        sampleIndex,
      ];
  
  @override
  String toString() {
    return 'ForceData(total: ${totalGRF.toStringAsFixed(1)}N, '
           'symmetry: ${forceSymmetryIndex.toStringAsFixed(1)}%, '
           'left: ${leftDeckTotal.toStringAsFixed(1)}N, '
           'right: ${rightDeckTotal.toStringAsFixed(1)}N)';
  }
}