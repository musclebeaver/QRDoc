import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/patient_profile.dart';
import '../models/medication_log.dart';

class LocalStorageService {
  static const String _dbKeyName = 'hive_encryption_key';
  static const String _profileBoxName = 'patient_profile_box';
  static const String _medicationBoxName = 'medication_log_box';
  
  final _secureStorage = const FlutterSecureStorage();
  late Box<String> _profileBox;
  late Box<String> _medicationBox;

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
    // Sort so newest items (with higher IDs or custom logic) show first if needed
    list.sort((a, b) => b.prescriptionDate.compareTo(a.prescriptionDate));
    return list;
  }

  Future<void> saveMedication(MedicationLog log) async {
    await _medicationBox.put(log.id, log.toJson());
  }

  Future<void> deleteMedication(String id) async {
    await _medicationBox.delete(id);
  }
}
