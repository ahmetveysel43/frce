import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Sporcu domain entity
class Athlete extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final double? height; // cm
  final double? weight; // kg
  final String? sport;
  final String? position;
  final AthleteLevel? level;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const Athlete({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.sport,
    this.position,
    this.level,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Tam ad
  String get fullName => '$firstName $lastName';

  /// Yaş hesapla
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// BMI hesapla
  double? get bmi {
    if (height == null || weight == null) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  /// BMI kategorisi
  String? get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return null;
    
    if (bmiValue < 18.5) return 'Zayıf';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Kilolu';
    return 'Obez';
  }

  /// Profil tamamlanma yüzdesi
  double get profileCompletion {
    int completed = 0;
    int total = 10; // Toplam alan sayısı

    if (firstName.isNotEmpty) completed++;
    if (lastName.isNotEmpty) completed++;
    if (email?.isNotEmpty == true) completed++;
    if (dateOfBirth != null) completed++;
    if (gender != null) completed++;
    if (height != null) completed++;
    if (weight != null) completed++;
    if (sport?.isNotEmpty == true) completed++;
    if (position?.isNotEmpty == true) completed++;
    if (level != null) completed++;

    return completed / total;
  }

  /// Profil tamamlanma durumu
  bool get isProfileComplete => profileCompletion >= 0.7; // %70 tamamlanma

  /// Sporcu seviye rengi
  String get levelColor {
    switch (level) {
      case AthleteLevel.recreational:
        return '#4CAF50'; // Green
      case AthleteLevel.amateur:
        return '#2196F3'; // Blue
      case AthleteLevel.semipro:
        return '#FF9800'; // Orange
      case AthleteLevel.professional:
        return '#9C27B0'; // Purple
      case AthleteLevel.elite:
        return '#F44336'; // Red
      default:
        return '#757575'; // Grey
    }
  }

  /// Yaş grubu
  String get ageGroup {
    final currentAge = age;
    if (currentAge == null) return 'Bilinmiyor';
    
    if (currentAge < 13) return 'Çocuk';
    if (currentAge < 18) return 'Genç';
    if (currentAge < 30) return 'Genç Yetişkin';
    if (currentAge < 40) return 'Yetişkin';
    if (currentAge < 50) return 'Orta Yaş';
    return 'Master';
  }

  /// Önerilen test türleri
  List<TestType> get recommendedTests {
    final tests = <TestType>[];

    // Yaş grubu bazlı öneriler
    if (age != null) {
      if (age! < 18) {
        tests.addAll([TestType.counterMovementJump, TestType.staticBalance]);
      } else if (age! < 40) {
        tests.addAll([
          TestType.counterMovementJump,
          TestType.squatJump,
          TestType.dropJump,
          TestType.isometricMidThighPull
        ]);
      } else {
        tests.addAll([
          TestType.counterMovementJump,
          TestType.staticBalance,
          TestType.singleLegBalance
        ]);
      }
    }

    // Spor dalı bazlı öneriler
    if (sport != null) {
      final sportLower = sport!.toLowerCase();
      
      if (sportLower.contains('basketbol') || sportLower.contains('voleybol')) {
        tests.addAll([TestType.counterMovementJump, TestType.dropJump]);
      } else if (sportLower.contains('futbol') || sportLower.contains('tenis')) {
        tests.addAll([TestType.counterMovementJump, TestType.lateralHop]);
      } else if (sportLower.contains('halter') || sportLower.contains('güreş')) {
        tests.addAll([TestType.isometricMidThighPull, TestType.isometricSquat]);
      } else if (sportLower.contains('jimnastik')) {
        tests.addAll([TestType.staticBalance, TestType.dynamicBalance]);
      }
    }

    // Seviye bazlı öneriler
    if (level != null) {
      switch (level!) {
        case AthleteLevel.recreational:
          tests.addAll([TestType.counterMovementJump, TestType.staticBalance]);
          break;
        case AthleteLevel.amateur:
        case AthleteLevel.semipro:
          tests.addAll([
            TestType.counterMovementJump,
            TestType.squatJump,
            TestType.staticBalance
          ]);
          break;
        case AthleteLevel.professional:
        case AthleteLevel.elite:
          tests.addAll([
            TestType.counterMovementJump,
            TestType.squatJump,
            TestType.dropJump,
            TestType.isometricMidThighPull,
            TestType.lateralHop
          ]);
          break;
      }
    }

    // Duplicate'leri kaldır
    return tests.toSet().toList();
  }

  /// Copy with
  Athlete copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    DateTime? dateOfBirth,
    Gender? gender,
    double? height,
    double? weight,
    String? sport,
    String? position,
    AthleteLevel? level,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Athlete(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      sport: sport ?? this.sport,
      position: position ?? this.position,
      level: level ?? this.level,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Factory constructor - new athlete
  factory Athlete.create({
    required String firstName,
    required String lastName,
    String? email,
    DateTime? dateOfBirth,
    Gender? gender,
    double? height,
    double? weight,
    String? sport,
    String? position,
    AthleteLevel? level,
    String? notes,
  }) {
    final now = DateTime.now();
    return Athlete(
      id: _generateId(),
      firstName: firstName,
      lastName: lastName,
      email: email,
      dateOfBirth: dateOfBirth,
      gender: gender,
      height: height,
      weight: weight,
      sport: sport,
      position: position,
      level: level,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );
  }

  /// ID generator
  static String _generateId() {
    return 'athlete_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Validation
  bool get isValid {
    return firstName.isNotEmpty && lastName.isNotEmpty;
  }

  /// Validation errors
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (firstName.isEmpty) errors.add('Ad boş olamaz');
    if (lastName.isEmpty) errors.add('Soyad boş olamaz');
    if (email != null && email!.isNotEmpty && !_isValidEmail(email!)) {
      errors.add('Geçersiz email adresi');
    }
    if (height != null && (height! < 50 || height! > 250)) {
      errors.add('Boy 50-250 cm arasında olmalı');
    }
    if (weight != null && (weight! < 20 || weight! > 300)) {
      errors.add('Kilo 20-300 kg arasında olmalı');
    }
    if (dateOfBirth != null && dateOfBirth!.isAfter(DateTime.now())) {
      errors.add('Doğum tarihi gelecekte olamaz');
    }
    
    return errors;
  }

  /// Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// To map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender?.name,
      'height': height,
      'weight': weight,
      'sport': sport,
      'position': position,
      'level': level?.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  /// From map
  factory Athlete.fromMap(Map<String, dynamic> map) {
    return Athlete(
      id: map['id'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      email: map['email'] as String?,
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      gender: map['gender'] != null 
          ? Gender.values.firstWhere((e) => e.name == map['gender'])
          : null,
      height: map['height'] as double?,
      weight: map['weight'] as double?,
      sport: map['sport'] as String?,
      position: map['position'] as String?,
      level: map['level'] != null 
          ? AthleteLevel.values.firstWhere((e) => e.name == map['level'])
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isActive: (map['isActive'] as int) == 1,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() => toMap();

  /// From JSON
  factory Athlete.fromJson(Map<String, dynamic> json) => Athlete.fromMap(json);

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        dateOfBirth,
        gender,
        height,
        weight,
        sport,
        position,
        level,
        notes,
        createdAt,
        updatedAt,
        isActive,
      ];

  @override
  String toString() {
    return 'Athlete(id: $id, name: $fullName, sport: $sport, level: ${level?.turkishName})';
  }
}

/// Mock athletes for development
class MockAthletes {
  static List<Athlete> get sampleAthletes => [
    Athlete.create(
      firstName: 'Ahmet',
      lastName: 'Yılmaz',
      email: 'ahmet.yilmaz@email.com',
      dateOfBirth: DateTime(1995, 5, 15),
      gender: Gender.male,
      height: 180,
      weight: 75,
      sport: 'Basketbol',
      position: 'Oyun Kurucu',
      level: AthleteLevel.professional,
    ),
    
    Athlete.create(
      firstName: 'Fatma',
      lastName: 'Kaya',
      email: 'fatma.kaya@email.com',
      dateOfBirth: DateTime(1998, 8, 22),
      gender: Gender.female,
      height: 165,
      weight: 58,
      sport: 'Voleybol',
      position: 'Pasör',
      level: AthleteLevel.semipro,
    ),
    
    Athlete.create(
      firstName: 'Mehmet',
      lastName: 'Demir',
      email: 'mehmet.demir@email.com',
      dateOfBirth: DateTime(1992, 12, 3),
      gender: Gender.male,
      height: 175,
      weight: 80,
      sport: 'Futbol',
      position: 'Merkez Orta Saha',
      level: AthleteLevel.amateur,
    ),
    
    Athlete.create(
      firstName: 'Ayşe',
      lastName: 'Özkan',
      email: 'ayse.ozkan@email.com',
      dateOfBirth: DateTime(2000, 3, 18),
      gender: Gender.female,
      height: 170,
      weight: 62,
      sport: 'Atletizm',
      position: 'Sprinter',
      level: AthleteLevel.elite,
    ),
    
    Athlete.create(
      firstName: 'Can',
      lastName: 'Arslan',
      dateOfBirth: DateTime(1996, 7, 9),
      gender: Gender.male,
      height: 185,
      weight: 85,
      sport: 'Halter',
      level: AthleteLevel.professional,
    ),
  ];
}