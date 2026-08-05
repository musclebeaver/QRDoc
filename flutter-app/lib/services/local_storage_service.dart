import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/patient_profile.dart';
import '../models/medication_log.dart';
import '../models/diagnosis_log.dart';
import '../models/medication_intake.dart';
import 'local_notification_service.dart';

class LocalStorageService {
  static const String _dbKeyName = 'hive_encryption_key';
  static const String _profileBoxName = 'patient_profile_box';
  static const String _medicationBoxName = 'medication_log_box';
  static const String _diagnosisBoxName = 'diagnosis_log_box';
  static const String _intakeBoxName = 'medication_intake_box';
  
  final _secureStorage = const FlutterSecureStorage();
  late Box<String> _profileBox;
  late Box<String> _medicationBox;
  late Box<String> _diagnosisBox;
  late Box<String> _intakeBox;

  Future<void> initDatabase() async {
    await Hive.initFlutter();

    // 1. Retrieve or generate 256-bit AES key in OS Secure Storage
    String? keyExists = await _secureStorage.read(key: _dbKeyName);
    List<int> encryptionKey;

    if (keyExists == null) {
      final newKey = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _dbKeyName, 
        value: base64Url.encode(newKey)
      );
      encryptionKey = newKey;
    } else {
      encryptionKey = base64Url.decode(keyExists);
    }

    // 2. Open secure encrypted Hive boxes
    final cipher = HiveAesCipher(encryptionKey);
    _profileBox = await Hive.openBox<String>(_profileBoxName, encryptionCipher: cipher);
    _medicationBox = await Hive.openBox<String>(_medicationBoxName, encryptionCipher: cipher);
    _diagnosisBox = await Hive.openBox<String>(_diagnosisBoxName, encryptionCipher: cipher);
    _intakeBox = await Hive.openBox<String>(_intakeBoxName, encryptionCipher: cipher);
    
    // Seed default mock data if boxes are completely empty
    if (_profileBox.isEmpty) {
      final defaultProfile = PatientProfile(
        uuid: 'patient-123',
        name: 'John Doe',
        birthDate: '1975-05-12',
        bloodType: 'A+',
        chronicDiseases: ['Hypertension', 'Diabetes'],
        allergies: ['Penicillin', 'Sulfa Drugs'],
        emergencyContact: '010-1234-5678',
        updatedAt: DateTime.now().toIso8601String(),
      );
      await saveProfile(defaultProfile);
    }
    
    if (_medicationBox.isEmpty) {
      final defaultLog1 = MedicationLog(
        id: '1',
        medicineName: 'Amoxicillin',
        dosage: '500mg',
        frequencyPerDay: 3,
        totalDays: 7,
        prescriptionDate: '2023-10-24',
        inputMethod: 'GEMINI_AI_OCR',
        isActive: true,
      );
      final defaultLog2 = MedicationLog(
        id: '2',
        medicineName: 'Lisinopril',
        dosage: '10mg',
        frequencyPerDay: 1,
        totalDays: 30,
        prescriptionDate: '2023-10-15',
        inputMethod: 'GEMINI_AI_OCR',
        isActive: true,
      );
      await saveMedication(defaultLog1);
      await saveMedication(defaultLog2);
    }

    if (_diagnosisBox.isEmpty) {
      final defaultDiag = DiagnosisLog(
        id: 'diag-1',
        diseaseName: '본태성 고혈압 (Essential Hypertension)',
        diseaseCode: 'I10',
        diagnosisDate: '2025-05-20',
        hospitalName: '서울대학교병원',
        doctorOpinion: '저염식 관리 및 매일 아침 Lisinopril 10mg 정기 복용 지도.',
        inputMethod: 'MANUAL',
        isActive: true,
      );
      await saveDiagnosis(defaultDiag);
    }
  }

  // Profile CRUD
  PatientProfile? getProfile() {
    final raw = _profileBox.get('profile');
    if (raw == null) return null;
    return PatientProfile.fromJson(raw);
  }

  Future<void> saveProfile(PatientProfile profile) async {
    await _profileBox.put('profile', profile.toJson());
  }

  // Medications CRUD
  List<MedicationLog> getMedications() {
    final List<MedicationLog> list = [];
    for (var key in _medicationBox.keys) {
      final raw = _medicationBox.get(key);
      if (raw != null) {
        list.add(MedicationLog.fromJson(raw));
      }
    }
    // Sort so newest items show first
    list.sort((a, b) => b.prescriptionDate.compareTo(a.prescriptionDate));
    return list;
  }

  Future<void> saveMedication(MedicationLog log) async {
    await _medicationBox.put(log.id, log.toJson());

    // Generate daily intakes for the duration of the prescription
    final List<MedicationIntake> newIntakes = [];
    final startDate = DateTime.tryParse(log.prescriptionDate) ?? DateTime.now();

    final reminderTimes = getReminderTimes();
    final String morningStr = reminderTimes['morning'] ?? "08:00";
    final String lunchStr = reminderTimes['lunch'] ?? "13:00";
    final String eveningStr = reminderTimes['evening'] ?? "19:00";

    for (int d = 0; d < log.totalDays; d++) {
      final targetDate = startDate.add(Duration(days: d));
      final dateStr = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      final List<String> times;
      if (log.frequencyPerDay >= 3) {
        times = [morningStr, lunchStr, eveningStr];
      } else if (log.frequencyPerDay == 2) {
        times = [morningStr, eveningStr];
      } else {
        times = [morningStr];
      }

      for (int i = 0; i < log.frequencyPerDay; i++) {
        final timeStr = i < times.length ? times[i] : "13:00";
        newIntakes.add(MedicationIntake(
          id: "${log.id}_${dateStr}_$i",
          medicationLogId: log.id,
          medicineName: log.medicineName,
          date: dateStr,
          intakeIndex: i,
          scheduledTime: timeStr,
          isTaken: false,
        ));
      }
    }
    
    if (newIntakes.isNotEmpty) {
      await saveIntakes(newIntakes);
    }

    // Schedule native alarm reminders
    await LocalNotificationService.scheduleAlarmsForMedication(log);
  }

  Future<void> deleteMedication(String id) async {
    final raw = _medicationBox.get(id);
    if (raw != null) {
      try {
        final log = MedicationLog.fromJson(raw);
        await LocalNotificationService.cancelAlarmsForMedication(log);
      } catch (e) {
        debugPrint("Error cancelling alarms: $e");
      }
    }
    await _medicationBox.delete(id);
    await deleteIntakesForLog(id);
  }

  // Diagnoses CRUD
  List<DiagnosisLog> getDiagnoses() {
    final List<DiagnosisLog> list = [];
    for (var key in _diagnosisBox.keys) {
      final raw = _diagnosisBox.get(key);
      if (raw != null) {
        list.add(DiagnosisLog.fromJson(raw));
      }
    }
    list.sort((a, b) => b.diagnosisDate.compareTo(a.diagnosisDate));
    return list;
  }

  Future<void> saveDiagnosis(DiagnosisLog log) async {
    await _diagnosisBox.put(log.id, log.toJson());
  }

  Future<void> deleteDiagnosis(String id) async {
    await _diagnosisBox.delete(id);
  }

  // Font Size Settings (Accessibility)
  double getFontSizeFactor() {
    final raw = _profileBox.get('fontSizeFactor');
    if (raw == null) return 1.0;
    return double.tryParse(raw) ?? 1.0;
  }

  Future<void> saveFontSizeFactor(double factor) async {
    await _profileBox.put('fontSizeFactor', factor.toString());
  }

  // Emergency Pass settings persistence
  bool getEmergencyPassEnabled() {
    final raw = _profileBox.get('emergencyPassEnabled');
    return raw == 'true';
  }

  Future<void> saveEmergencyPassEnabled(bool enabled) async {
    await _profileBox.put('emergencyPassEnabled', enabled.toString());
  }

  // Medication Intakes Tracking
  List<MedicationIntake> getIntakes() {
    return _intakeBox.values
        .map((raw) => MedicationIntake.fromJson(raw))
        .toList();
  }

  Future<void> saveIntake(MedicationIntake intake) async {
    await _intakeBox.put(intake.id, intake.toJson());
  }

  Future<void> saveIntakes(List<MedicationIntake> intakes) async {
    final Map<String, String> data = {};
    for (var val in intakes) {
      data[val.id] = val.toJson();
    }
    await _intakeBox.putAll(data);
  }

  List<MedicationIntake> getIntakesForDate(String date) {
    return _intakeBox.values
        .map((raw) => MedicationIntake.fromJson(raw))
        .where((element) => element.date == date)
        .toList();
  }

  Future<void> deleteIntakesForLog(String medicationLogId) async {
    final keysToDelete = _intakeBox.keys.where((key) {
      final raw = _intakeBox.get(key);
      if (raw == null) return false;
      final item = MedicationIntake.fromJson(raw);
      return item.medicationLogId == medicationLogId;
    }).toList();
    
    if (keysToDelete.isNotEmpty) {
      await _intakeBox.deleteAll(keysToDelete);
    }
  }

  // Custom Reminder Times Persistence
  Map<String, String> getReminderTimes() {
    final morning = _profileBox.get('reminder_morning') ?? '08:00';
    final lunch = _profileBox.get('reminder_lunch') ?? '13:00';
    final evening = _profileBox.get('reminder_evening') ?? '19:00';
    return {
      'morning': morning,
      'lunch': lunch,
      'evening': evening,
    };
  }

  Future<void> saveReminderTimes(String morning, String lunch, String evening) async {
    await _profileBox.put('reminder_morning', morning);
    await _profileBox.put('reminder_lunch', lunch);
    await _profileBox.put('reminder_evening', evening);
  }
}
