// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'athlete_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AthleteModel _$AthleteModelFromJson(Map<String, dynamic> json) => AthleteModel(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      sport: json['sport'] as String?,
      position: json['position'] as String?,
      level: json['level'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      profileImageUrl: json['profile_image_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      medicalNotes: json['medical_notes'] as String?,
      coachName: json['coach_name'] as String?,
      teamName: json['team_name'] as String?,
      licenseNumber: json['license_number'] as String?,
      totalTests: (json['total_tests'] as num?)?.toInt() ?? 0,
      lastTestDate: json['last_test_date'] == null
          ? null
          : DateTime.parse(json['last_test_date'] as String),
    );

Map<String, dynamic> _$AthleteModelToJson(AthleteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'gender': instance.gender,
      'height': instance.height,
      'weight': instance.weight,
      'sport': instance.sport,
      'position': instance.position,
      'level': instance.level,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'is_active': instance.isActive,
      'profile_image_url': instance.profileImageUrl,
      'phone_number': instance.phoneNumber,
      'emergency_contact': instance.emergencyContact,
      'medical_notes': instance.medicalNotes,
      'coach_name': instance.coachName,
      'team_name': instance.teamName,
      'license_number': instance.licenseNumber,
      'total_tests': instance.totalTests,
      'last_test_date': instance.lastTestDate?.toIso8601String(),
    };
