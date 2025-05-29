import 'package:equatable/equatable.dart';

class Athlete extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final int age;
  final String gender; // 'M' veya 'F'
  final double? height; // cm
  final double? weight; // kg
  final String? sport;
  final String? position;
  final String? phone;
  final String? email;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Athlete({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.gender,
    this.height,
    this.weight,
    this.sport,
    this.position,
    this.phone,
    this.email,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getter'lar
  String get fullName => '$firstName $lastName';
  
  String get displayInfo {
    final parts = <String>[];
    parts.add('$age yaş');
    if (sport != null) parts.add(sport!);
    if (position != null) parts.add(position!);
    return parts.join(' • ');
  }

  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      final heightInM = height! / 100;
      return weight! / (heightInM * heightInM);
    }
    return null;
  }

  // JSON dönüşümleri
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'sport': sport,
      'position': position,
      'phone': phone,
      'email': email,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      height: json['height'] as double?,
      weight: json['weight'] as double?,
      sport: json['sport'] as String?,
      position: json['position'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // copyWith method
  Athlete copyWith({
    String? id,
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? sport,
    String? position,
    String? phone,
    String? email,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Athlete(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      sport: sport ?? this.sport,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        age,
        gender,
        height,
        weight,
        sport,
        position,
        phone,
        email,
        notes,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Athlete(id: $id, name: $fullName, age: $age, sport: $sport)';
  }
}