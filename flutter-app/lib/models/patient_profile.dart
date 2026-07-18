import 'dart:convert';

class PatientProfile {
  final String uuid;
  final String name;
  final String birthDate; // YYYY-MM-DD
  final String bloodType;
  final List<String> chronicDiseases;
  final List<String> allergies;
  final String emergencyContact;
  final String updatedAt; // ISO 8601 string

  PatientProfile({
    required this.uuid,
    required this.name,
    required this.birthDate,
    required this.bloodType,
    required this.chronicDiseases,
    required this.allergies,
    required this.emergencyContact,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'birthDate': birthDate,
      'bloodType': bloodType,
      'chronicDiseases': chronicDiseases,
      'allergies': allergies,
      'emergencyContact': emergencyContact,
      'updatedAt': updatedAt,
    };
  }

  factory PatientProfile.fromMap(Map<String, dynamic> map) {
    return PatientProfile(
      uuid: map['uuid'] ?? '',
      name: map['name'] ?? '',
      birthDate: map['birthDate'] ?? '',
      bloodType: map['bloodType'] ?? '',
      chronicDiseases: List<String>.from(map['chronicDiseases'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      emergencyContact: map['emergencyContact'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PatientProfile.fromJson(String source) => PatientProfile.fromMap(json.decode(source));
}
