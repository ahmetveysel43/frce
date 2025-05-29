import 'package:equatable/equatable.dart';
import 'dart:math' as math;

class ForceVector extends Equatable {
  final double x; // Medial-Lateral (sağ-sol)
  final double y; // Anterior-Posterior (ön-arka)
  final double z; // Vertical (dikey)

  const ForceVector({
    required this.x,
    required this.y,
    required this.z,
  });

  // Static constructors
  static const ForceVector zero = ForceVector(x: 0, y: 0, z: 0);
  
  factory ForceVector.vertical(double force) {
    return ForceVector(x: 0, y: 0, z: force);
  }

  factory ForceVector.horizontal(double x, double y) {
    return ForceVector(x: x, y: y, z: 0);
  }

  // Computed properties
  double get magnitude => math.sqrt(x * x + y * y + z * z);
  
  double get horizontalMagnitude => math.sqrt(x * x + y * y);
  
  double get verticalComponent => z;
  
  /// Açı hesaplama (radyan)
  double get angleInRadians => math.atan2(y, x);
  
  /// Açı hesaplama (derece)
  double get angleInDegrees => angleInRadians * (180 / math.pi);

  // Vector operations
  ForceVector operator +(ForceVector other) {
    return ForceVector(
      x: x + other.x,
      y: y + other.y,
      z: z + other.z,
    );
  }

  ForceVector operator -(ForceVector other) {
    return ForceVector(
      x: x - other.x,
      y: y - other.y,
      z: z - other.z,
    );
  }

  ForceVector operator *(double scalar) {
    return ForceVector(
      x: x * scalar,
      y: y * scalar,
      z: z * scalar,
    );
  }

  ForceVector operator /(double scalar) {
    if (scalar == 0) throw ArgumentError('Cannot divide by zero');
    return ForceVector(
      x: x / scalar,
      y: y / scalar,
      z: z / scalar,
    );
  }

  /// Normalize vector (birim vektör)
  ForceVector normalize() {
    final mag = magnitude;
    if (mag == 0) return ForceVector.zero;
    return this / mag;
  }

  /// Dot product
  double dot(ForceVector other) {
    return x * other.x + y * other.y + z * other.z;
  }

  /// Cross product
  ForceVector cross(ForceVector other) {
    return ForceVector(
      x: y * other.z - z * other.y,
      y: z * other.x - x * other.z,
      z: x * other.y - y * other.x,
    );
  }

  @override
  List<Object> get props => [x, y, z];

  @override
  String toString() => 'ForceVector(x: $x, y: $y, z: $z)';
}