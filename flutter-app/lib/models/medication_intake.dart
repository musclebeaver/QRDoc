import 'dart:convert';

class MedicationIntake {
  final String id; // UUID
  final String medicationLogId; // Link to MedicationLog
  final String medicineName;
  final String date; // YYYY-MM-DD
  final int intakeIndex; // 0: 아침, 1: 점심, 2: 저녁
  final String scheduledTime; // "08:00", "13:00", "19:00"
  final bool isTaken;
  final String? takenTime; // YYYY-MM-DD HH:mm:ss or null

  MedicationIntake({
    required this.id,
    required this.medicationLogId,
    required this.medicineName,
    required this.date,
    required this.intakeIndex,
    required this.scheduledTime,
    required this.isTaken,
    this.takenTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationLogId': medicationLogId,
      'medicineName': medicineName,
      'date': date,
      'intakeIndex': intakeIndex,
      'scheduledTime': scheduledTime,
      'isTaken': isTaken,
      'takenTime': takenTime,
    };
  }

  factory MedicationIntake.fromMap(Map<String, dynamic> map) {
    return MedicationIntake(
      id: map['id'] ?? '',
      medicationLogId: map['medicationLogId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      date: map['date'] ?? '',
      intakeIndex: map['intakeIndex'] ?? 0,
      scheduledTime: map['scheduledTime'] ?? '',
      isTaken: map['isTaken'] ?? false,
      takenTime: map['takenTime'],
    );
  }

  String toJson() => json.encode(toMap());

  factory MedicationIntake.fromJson(String source) => MedicationIntake.fromMap(json.decode(source));
}
