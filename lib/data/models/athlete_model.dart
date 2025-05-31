import 'package:json_annotation/json_annotation.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/athlete.dart';

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
          ? Gender.values.firstWhere((e) => e.name == gender)
          : null,
      height: height,
      weight: weight,
      sport: sport,
      position: position,
      level: level != null 
          ? AthleteLevel.values.firstWhere((e) => e.name == level)
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
      final athleteLevel = AthleteLevel.values.firstWhere((e) => e.name == level);
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
}

/// Database için genişletilmiş sporcu model
class ExtendedAthleteModel extends AthleteModel {
  final List<String> injuries;
  final List<String> achievements;
  final Map<String, dynamic> customFields;
  final List<String> tags;
  final String? nationality;
  final String? dominantLeg;
  final double? bodyFatPercentage;
  final double? muscleMass;

  const ExtendedAthleteModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.email,
    super.dateOfBirth,
    super.gender,
    super.height,
    super.weight,
    super.sport,
    super.position,
    super.level,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    super.isActive,
    super.profileImageUrl,
    super.phoneNumber,
    super.emergencyContact,
    super.medicalNotes,
    super.coachName,
    super.teamName,
    super.licenseNumber,
    super.totalTests,
    super.lastTestDate,
    this.injuries = const [],
    this.achievements = const [],
    this.customFields = const {},
    this.tags = const [],
    this.nationality,
    this.dominantLeg,
    this.bodyFatPercentage,
    this.muscleMass,
  });

  factory ExtendedAthleteModel.fromAthleteModel(
    AthleteModel model, {
    List<String> injuries = const [],
    List<String> achievements = const [],
    Map<String, dynamic> customFields = const {},
    List<String> tags = const [],
    String? nationality,
    String? dominantLeg,
    double? bodyFatPercentage,
    double? muscleMass,
  }) {
    return ExtendedAthleteModel(
      id: model.id,
      firstName: model.firstName,
      lastName: model.lastName,
      email: model.email,
      dateOfBirth: model.dateOfBirth,
      gender: model.gender,
      height: model.height,
      weight: model.weight,
      sport: model.sport,
      position: model.position,
      level: model.level,
      notes: model.notes,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isActive: model.isActive,
      profileImageUrl: model.profileImageUrl,
      phoneNumber: model.phoneNumber,
      emergencyContact: model.emergencyContact,
      medicalNotes: model.medicalNotes,
      coachName: model.coachName,
      teamName: model.teamName,
      licenseNumber: model.licenseNumber,
      totalTests: model.totalTests,
      lastTestDate: model.lastTestDate,
      injuries: injuries,
      achievements: achievements,
      customFields: customFields,
      tags: tags,
      nationality: nationality,
      dominantLeg: dominantLeg,
      bodyFatPercentage: bodyFatPercentage,
      muscleMass: muscleMass,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'injuries': injuries.join(','),
      'achievements': achievements.join(','),
      'customFields': customFields,
      'tags': tags.join(','),
      'nationality': nationality,
      'dominantLeg': dominantLeg,
      'bodyFatPercentage': bodyFatPercentage,
      'muscleMass': muscleMass,
    });
    return map;
  }

  factory ExtendedAthleteModel.fromMap(Map<String, dynamic> map) {
    final baseModel = AthleteModel.fromMap(map);
    
    return ExtendedAthleteModel(
      id: baseModel.id,
      firstName: baseModel.firstName,
      lastName: baseModel.lastName,
      email: baseModel.email,
      dateOfBirth: baseModel.dateOfBirth,
      gender: baseModel.gender,
      height: baseModel.height,
      weight: baseModel.weight,
      sport: baseModel.sport,
      position: baseModel.position,
      level: baseModel.level,
      notes: baseModel.notes,
      createdAt: baseModel.createdAt,
      updatedAt: baseModel.updatedAt,
      isActive: baseModel.isActive,
      profileImageUrl: baseModel.profileImageUrl,
      phoneNumber: baseModel.phoneNumber,
      emergencyContact: baseModel.emergencyContact,
      medicalNotes: baseModel.medicalNotes,
      coachName: baseModel.coachName,
      teamName: baseModel.teamName,
      licenseNumber: baseModel.licenseNumber,
      totalTests: baseModel.totalTests,
      lastTestDate: baseModel.lastTestDate,
      injuries: (map['injuries'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      achievements: (map['achievements'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      customFields: map['customFields'] as Map<String, dynamic>? ?? {},
      tags: (map['tags'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      nationality: map['nationality'] as String?,
      dominantLeg: map['dominantLeg'] as String?,
      bodyFatPercentage: map['bodyFatPercentage'] as double?,
      muscleMass: map['muscleMass'] as double?,
    );
  }
}