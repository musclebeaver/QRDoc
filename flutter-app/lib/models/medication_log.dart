import 'dart:convert';

class MedicationLog {
  final String id;
  final String medicineName;
  final String dosage;
  final int frequencyPerDay;
  final int totalDays;
  final String prescriptionDate; // YYYY-MM-DD
  final String inputMethod; // 'GEMINI_AI_OCR' or 'MANUAL'
  final bool isActive;

  MedicationLog({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.frequencyPerDay,
    required this.totalDays,
    required this.prescriptionDate,
    required this.inputMethod,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'frequencyPerDay': frequencyPerDay,
      'totalDays': totalDays,
      'prescriptionDate': prescriptionDate,
      'inputMethod': inputMethod,
      'isActive': isActive,
    };
  }

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'] ?? '',
      medicineName: map['medicineName'] ?? '',
      dosage: map['dosage'] ?? '',
      frequencyPerDay: map['frequencyPerDay'] ?? 0,
      totalDays: map['totalDays'] ?? 0,
      prescriptionDate: map['prescriptionDate'] ?? '',
      inputMethod: map['inputMethod'] ?? 'MANUAL',
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory MedicationLog.fromJson(String source) => MedicationLog.fromMap(json.decode(source));
}
