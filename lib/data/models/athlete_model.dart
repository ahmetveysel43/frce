import 'package:json_annotation/json_annotation.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/athlete.dart';
// ✅ JSON encode/decode için
part 'athlete_model.g.dart';

/// Sporcu data model - Database ve API mapping için
@JsonSerializable()
class AthleteModel {
  @JsonKey(name: 'id')
  final String id;
  
  @JsonKey(name: 'first_name')
  final String firstName;
  
  @JsonKey(name: 'last_name')
  final String lastName;
  
  @JsonKey(name: 'email')
  final String? email;
  
  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;
  
  @JsonKey(name: 'gender')
  final String? gender; // enum string representation
  
  @JsonKey(name: 'height')
  final double? height;
  
  @JsonKey(name: 'weight')
  final double? weight;
  
  @JsonKey(name: 'sport')
  final String? sport;
  
  @JsonKey(name: 'team')
  final String? team;
  
  @JsonKey(name: 'position')
  final String? position;
  
  @JsonKey(name: 'level')
  final String? level; // enum string representation
  
  @JsonKey(name: 'notes')
  final String? notes;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // Ek database alanları
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
  
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  
  @JsonKey(name: 'emergency_contact')
  final String? emergencyContact;
  
  @JsonKey(name: 'medical_notes')
  final String? medicalNotes;
  
  @JsonKey(name: 'coach_name')
  final String? coachName;
  
  @JsonKey(name: 'team_name')
  final String? teamName;
  
  @JsonKey(name: 'license_number')
  final String? licenseNumber;
  
  @JsonKey(name: 'total_tests')
  final int totalTests;
  
  @JsonKey(name: 'last_test_date')
  final DateTime? lastTestDate;

  const AthleteModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.sport,
    this.team,
    this.position,
    this.level,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.profileImageUrl,
    this.phoneNumber,
    this.emergencyContact,
    this.medicalNotes,
    this.coachName,
    this.teamName,
    this.licenseNumber,
    this.totalTests = 0,
    this.lastTestDate,
  });

  /// JSON'dan model oluştur
  factory AthleteModel.fromJson(Map<String, dynamic> json) => _$AthleteModelFromJson(json);

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() => _$AthleteModelToJson(this);

  /// Database map'inden model oluştur
  factory AthleteModel.fromMap(Map<String, dynamic> map) {
    return AthleteModel(
      id: map['id'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      email: map['email'] as String?,
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      gender: map['gender'] as String?,
      height: map['height'] as double?,
      weight: map['weight'] as double?,
      sport: map['sport'] as String?,
      position: map['position'] as String?,
      level: map['level'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isActive: (map['isActive'] as int) == 1,
      profileImageUrl: map['profileImageUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
      medicalNotes: map['medicalNotes'] as String?,
      coachName: map['coachName'] as String?,
      teamName: map['teamName'] as String?,
      licenseNumber: map['licenseNumber'] as String?,
      totalTests: map['totalTests'] as int? ?? 0,
      lastTestDate: map['lastTestDate'] != null 
          ? DateTime.parse(map['lastTestDate'] as String)
          : null,
    );
  }

  /// Model'i database map'ine çevir
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'sport': sport,
      'position': position,
      'level': level,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'emergencyContact': emergencyContact,
      'medicalNotes': medicalNotes,
      'coachName': coachName,
      'teamName': teamName,
      'licenseNumber': licenseNumber,
      'totalTests': totalTests,
      'lastTestDate': lastTestDate?.toIso8601String(),
    };
  }

  /// Domain entity'den model oluştur
  factory AthleteModel.fromEntity(Athlete entity) {
    return AthleteModel(
      id: entity.id,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender?.name,
      height: entity.height,
      weight: entity.weight,
      sport: entity.sport,
      position: entity.position,
      level: entity.level?.name,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
      totalTests: 0, // Will be updated from database
    );
  }

  /// Model'i domain entity'ye çevir
  Athlete toEntity() {
    return Athlete(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      dateOfBirth: dateOfBirth,
      gender: gender != null 
          ? _getGenderEnum(gender!)
          : null,
      height: height,
      weight: weight,
      sport: sport,
      position: position,
      level: level != null 
          ? _getAthleteLevelEnum(level!)
          : null,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  /// Copy with (immutable update)
  AthleteModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? sport,
    String? position,
    String? level,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? profileImageUrl,
    String? phoneNumber,
    String? emergencyContact,
    String? medicalNotes,
    String? coachName,
    String? teamName,
    String? licenseNumber,
    int? totalTests,
    DateTime? lastTestDate,
  }) {
    return AthleteModel(
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
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      coachName: coachName ?? this.coachName,
      teamName: teamName ?? this.teamName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      totalTests: totalTests ?? this.totalTests,
      lastTestDate: lastTestDate ?? this.lastTestDate,
    );
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
    if (phoneNumber != null && phoneNumber!.isNotEmpty && !_isValidPhone(phoneNumber!)) {
      errors.add('Geçersiz telefon numarası');
    }
    
    return errors;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone.replaceAll(RegExp(r'[\s-()]'), ''));
  }

  /// Full name helper
  String get fullName => '$firstName $lastName';

  /// Display info helper
  String get displayInfo {
    final parts = <String>[];
    
    if (sport?.isNotEmpty == true) parts.add(sport!);
    if (position?.isNotEmpty == true) parts.add(position!);
    if (level != null) {
      final athleteLevel = _getAthleteLevelEnum(level!);
      parts.add(athleteLevel.turkishName);
    }
    
    return parts.join(' • ');
  }

  /// Age calculation
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

  /// Age group calculation for normative data
  String? get ageGroup {
    final currentAge = age;
    if (currentAge == null) return null;
    
    if (currentAge < 12) return 'child';
    if (currentAge < 16) return 'youth';
    if (currentAge < 18) return 'junior';
    if (currentAge < 23) return 'u23';
    if (currentAge < 35) return 'senior';
    if (currentAge < 50) return 'masters1';
    if (currentAge < 60) return 'masters2';
    return 'masters3';
  }

  /// BMI calculation
  double? get bmi {
    if (height == null || weight == null) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AthleteModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AthleteModel{id: $id, name: $fullName, sport: $sport, level: $level}';
  }

  /// Safe gender enum getter
  static Gender _getGenderEnum(String genderStr) {
    try {
      return Gender.values.firstWhere((e) => e.name == genderStr);
    } catch (e) {
      // Try case-insensitive matching
      try {
        return Gender.values.firstWhere((e) => 
          e.name.toLowerCase() == genderStr.toLowerCase() ||
          e.englishName.toLowerCase() == genderStr.toLowerCase() ||
          e.turkishName.toLowerCase() == genderStr.toLowerCase()
        );
      } catch (e) {
        // Default to unknown if no match found
        return Gender.unknown;
      }
    }
  }

  /// Safe athlete level enum getter
  static AthleteLevel _getAthleteLevelEnum(String levelStr) {
    try {
      return AthleteLevel.values.firstWhere((e) => e.name == levelStr);
    } catch (e) {
      // Try case-insensitive matching
      try {
        return AthleteLevel.values.firstWhere((e) => 
          e.name.toLowerCase() == levelStr.toLowerCase() ||
          e.englishName.toLowerCase() == levelStr.toLowerCase() ||
          e.turkishName.toLowerCase() == levelStr.toLowerCase()
        );
      } catch (e) {
        // Default to recreational if no match found
        return AthleteLevel.recreational;
      }
    }
  }
}

