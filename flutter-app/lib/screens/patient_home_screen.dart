import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../main.dart'; // To access the global localStorage singleton
import 'edit_profile_screen.dart';
import '../models/patient_profile.dart';
import '../models/medication_log.dart';
import '../models/diagnosis_log.dart';
import 'diagnosis_review_screen.dart';
import 'qr_generator_screen.dart';
import 'ai_review_screen.dart';
import 'emergency_pass_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({Key? key}) : super(key: key);

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  // Theme Color Constants (VitalPass Design System)
  static const Color primaryColor = Color(0xFF003FB1);
  static const Color primaryContainer = Color(0xFF1A56DB);
  static const Color secondaryColor = Color(0xFF006A61);
  static const Color secondaryContainer = Color(0xFF86F2E4);
  static const Color onSecondaryContainer = Color(0xFF006F66);
  static const Color backgroundColor = Color(0xFFFAF8FF);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color outlineColor = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C5D7);
  static const Color onSurfaceColor = Color(0xFF191B23);
  static const Color onSurfaceVariant = Color(0xFF434654);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color errorColor = Color(0xFFBA1A1A);

  // Default patient profile used as initial state before loading from Hive DB
  PatientProfile _profile = PatientProfile(
    uuid: 'patient-123',
    name: 'John Doe',
    birthDate: '1975-05-12',
    bloodType: 'A+',
    chronicDiseases: ['Hypertension', 'Diabetes'],
    allergies: ['Penicillin', 'Sulfa Drugs'],
    emergencyContact: '010-1234-5678',
    updatedAt: '2026-07-18T10:00:00Z',
  );

  // Dynamic Medication Logs list in State
  List<MedicationLog> _medications = [];
  List<DiagnosisLog> _diagnoses = [];
  int _recordsSubTabIndex = 0; // 0: medications, 1: diagnoses
  int _currentIndex = 0;
  bool _isEmergencyPassEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  // Load profile, medication logs, and diagnoses from encrypted Hive storage
  void _loadLocalData() {
    final savedProfile = localStorage.getProfile();
    final savedMedications = localStorage.getMedications();
    final savedDiagnoses = localStorage.getDiagnoses();
    setState(() {
      if (savedProfile != null) {
        _profile = savedProfile;
      }
      _medications = savedMedications;
      _diagnoses = savedDiagnoses;
    });
  }

  // Opens the camera to take a prescription photo, uploads it to backend OCR, and opens the review screen
  Future<void> _scanNewPrescription() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // 1. Capture prescription photo from native camera
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress image to ~1-2MB to save bandwidth and fit API size constraints
      );

      if (image == null) {
        // User cancelled camera capture
        return;
      }

      // 2. Show loading dialog with AdMob Test Banner
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AdmobLoadingDialog();
        },
      );

      // 3. Upload photo to backend /api/ocr endpoint
      final File imageFile = File(image.path);
      final result = await apiService.processPrescriptionOCR(imageFile);

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
      }

      // 4. Map OCR JSON result to lists of MedicationLogs & DiagnosisLogs
      final String documentType = result['documentType'] ?? 'UNKNOWN';
      final List<dynamic> medicationsJson = result['medications'] ?? [];
      final List<dynamic> diagnosesJson = result['diagnoses'] ?? [];

      final List<MedicationLog> parsedLogs = medicationsJson.map((m) {
        return MedicationLog(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + (m['medicineName'] ?? 'med'),
          medicineName: m['medicineName'] ?? '알 수 없는 약물',
          dosage: m['dosage'] ?? '미지정',
          frequencyPerDay: m['frequencyPerDay'] ?? 0,
          totalDays: m['totalDays'] ?? 0,
          prescriptionDate: result['prescriptionDate'] ?? DateTime.now().toIso8601String().split('T')[0],
          inputMethod: 'GEMINI_AI_OCR',
          isActive: true,
        );
      }).toList();

      final List<DiagnosisLog> parsedDiagnoses = diagnosesJson.map((d) {
        return DiagnosisLog(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + (d['diseaseName'] ?? 'diag'),
          diseaseName: d['diseaseName'] ?? '알 수 없는 진단',
          diseaseCode: d['diseaseCode'] ?? 'UNKNOWN',
          diagnosisDate: d['diagnosisDate'] ?? result['prescriptionDate'] ?? DateTime.now().toIso8601String().split('T')[0],
          hospitalName: d['hospitalName'] ?? '미지정 병원',
          doctorOpinion: d['doctorOpinion'] ?? '',
          inputMethod: 'GEMINI_AI_OCR',
          isActive: true,
        );
      }).toList();

      if (parsedLogs.isEmpty && parsedDiagnoses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인식된 복약 기록 또는 진단 정보가 없습니다. 직접 입력해서 추가해 주세요.')),
          );
        }
        return;
      }

      // 5. Route to appropriate screen based on OCR findings
      if (!mounted) return;
      if (parsedDiagnoses.isNotEmpty && (parsedLogs.isEmpty || documentType == 'MEDICAL_CERTIFICATE')) {
        // Route to Diagnosis Review Screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DiagnosisReviewScreen(
              initialLogs: parsedDiagnoses,
              onSave: (newDiags) async {
                for (var diag in newDiags) {
                  await localStorage.saveDiagnosis(diag);
                }
                _loadLocalData(); // Refresh UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('새로운 진단 정보가 추가되었습니다!')),
                );
              },
            ),
          ),
        );
      } else {
        // Route to Medications Review Screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AiReviewScreen(
              initialLogs: parsedLogs,
              onSave: (newLogs) async {
                for (var log in newLogs) {
                  await localStorage.saveMedication(log);
                }
                _loadLocalData(); // Refresh UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('새로운 복약 정보가 추가되었습니다!')),
                );
              },
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog if open
        
        // Show fallback alert for emulator testing
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('카메라 실행 실패'),
              content: Text('카메라를 열 수 없습니다 ($e). 에뮬레이터 테스트를 위해 샘플 데이터를 사용할까요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _useMockScannerFallback();
                  },
                  child: const Text('샘플 데이터 사용'),
                ),
              ],
            );
          }
        );
      }
    }
  }

  // Fallback for emulator testing when camera is unavailable
  void _useMockScannerFallback() {
    final mockOcrLogs = [
      MedicationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_1',
        medicineName: 'Metformin',
        dosage: '500mg',
        frequencyPerDay: 2,
        totalDays: 14,
        prescriptionDate: '2026-07-20',
        inputMethod: 'GEMINI_AI_OCR',
        isActive: true,
      ),
      MedicationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_2',
        medicineName: 'Glimepiride',
        dosage: '2mg',
        frequencyPerDay: 1,
        totalDays: 14,
        prescriptionDate: '2026-07-20',
        inputMethod: 'GEMINI_AI_OCR',
        isActive: true,
      ),
    ];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiReviewScreen(
          initialLogs: mockOcrLogs,
          onSave: (newLogs) async {
            for (var log in newLogs) {
              await localStorage.saveMedication(log);
            }
            _loadLocalData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('새로운 복약 정보가 추가되었습니다!')),
            );
          },
        ),
      ),
    );
  }

  // Opens AI Review Screen to edit an existing medication log
  void _editMedication(MedicationLog log) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiReviewScreen(
          initialLogs: [log],
          onSave: (updatedLogs) async {
            // Update payload inside secure local database
            if (updatedLogs.isNotEmpty) {
              await localStorage.saveMedication(updatedLogs.first);
              _loadLocalData(); // Refresh UI State
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('복약 정보가 성공적으로 수정되었습니다.')),
              );
            } else {
              // Deleted in the review screen
              await localStorage.deleteMedication(log.id);
              _loadLocalData(); // Refresh UI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('복약 정보가 성공적으로 삭제되었습니다.')),
              );
            }
          },
        ),
      ),
    );
  }

  // Shows a bottom sheet option to scan via camera, pick from gallery, or input manually
  void _showAddMedicationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '건강 기록 추가 방식 선택',
                  style: TextStyle(
                    color: onSurfaceColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Option 1: Camera Scan
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _scanNewPrescription();
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: outlineVariant),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_camera, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '📷 카메라로 문서 스캔',
                                style: TextStyle(
                                  color: onSurfaceColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '처방전 또는 진단서 사진을 촬영하여 자동 인식합니다.',
                                style: TextStyle(
                                  color: onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Option 2: Gallery Picker
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _scanPrescriptionFromGallery();
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: outlineVariant),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '🖼️ 앨범에서 사진 불러오기',
                                style: TextStyle(
                                  color: onSurfaceColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '저장해둔 처방전 또는 진단서 이미지에서 정보를 분석합니다.',
                                style: TextStyle(
                                  color: onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Option 3: Manual Medication Input
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _addMedicationManually();
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: outlineVariant),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note, color: secondaryColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '💊 복약 기록 직접 추가',
                                style: TextStyle(
                                  color: onSurfaceColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '약물명과 복용 방법 등을 수동으로 직접 기입합니다.',
                                style: TextStyle(
                                  color: onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Option 4: Manual Diagnosis Input
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _addDiagnosisManually();
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: outlineVariant),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '🩺 진단서 직접 추가',
                                style: TextStyle(
                                  color: onSurfaceColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '확진 병명, 질병 코드, 진단 병원 등을 수동으로 직접 기입합니다.',
                                style: TextStyle(
                                  color: onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Opens the photo library to pick an existing prescription photo, uploads it to backend OCR, and opens the review screen
  Future<void> _scanPrescriptionFromGallery() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // 1. Pick prescription photo from device gallery
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress to save bandwidth
      );

      if (image == null) {
        // User cancelled image selection
        return;
      }

      // 2. Show loading dialog with AdMob Test Banner
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AdmobLoadingDialog();
        },
      );

      // 3. Upload photo to backend /api/ocr endpoint
      final File imageFile = File(image.path);
      final result = await apiService.processPrescriptionOCR(imageFile);

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
      }

      // 4. Map OCR JSON result to lists of MedicationLogs & DiagnosisLogs
      final String documentType = result['documentType'] ?? 'UNKNOWN';
      final List<dynamic> medicationsJson = result['medications'] ?? [];
      final List<dynamic> diagnosesJson = result['diagnoses'] ?? [];

      final List<MedicationLog> parsedLogs = medicationsJson.map((m) {
        return MedicationLog(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + (m['medicineName'] ?? 'med'),
          medicineName: m['medicineName'] ?? '알 수 없는 약물',
          dosage: m['dosage'] ?? '미지정',
          frequencyPerDay: m['frequencyPerDay'] ?? 0,
          totalDays: m['totalDays'] ?? 0,
          prescriptionDate: result['prescriptionDate'] ?? DateTime.now().toIso8601String().split('T')[0],
          inputMethod: 'GEMINI_AI_OCR',
          isActive: true,
        );
      }).toList();

      final List<DiagnosisLog> parsedDiagnoses = diagnosesJson.map((d) {
        return DiagnosisLog(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + (d['diseaseName'] ?? 'diag'),
          diseaseName: d['diseaseName'] ?? '알 수 없는 진단',
          diseaseCode: d['diseaseCode'] ?? 'UNKNOWN',
          diagnosisDate: d['diagnosisDate'] ?? result['prescriptionDate'] ?? DateTime.now().toIso8601String().split('T')[0],
          hospitalName: d['hospitalName'] ?? '미지정 병원',
          doctorOpinion: d['doctorOpinion'] ?? '',
          inputMethod: 'GEMINI_AI_OCR',
          isActive: true,
        );
      }).toList();

      if (parsedLogs.isEmpty && parsedDiagnoses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인식된 복약 기록 또는 진단 정보가 없습니다. 직접 입력해서 추가해 주세요.')),
          );
        }
        return;
      }

      // 5. Route to appropriate screen based on OCR findings
      if (!mounted) return;
      if (parsedDiagnoses.isNotEmpty && (parsedLogs.isEmpty || documentType == 'MEDICAL_CERTIFICATE')) {
        // Route to Diagnosis Review Screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DiagnosisReviewScreen(
              initialLogs: parsedDiagnoses,
              onSave: (newDiags) async {
                for (var diag in newDiags) {
                  await localStorage.saveDiagnosis(diag);
                }
                _loadLocalData(); // Refresh UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('새로운 진단 정보가 추가되었습니다!')),
                );
              },
            ),
          ),
        );
      } else {
        // Route to Medications Review Screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AiReviewScreen(
              initialLogs: parsedLogs,
              onSave: (newLogs) async {
                for (var log in newLogs) {
                  await localStorage.saveMedication(log);
                }
                _loadLocalData(); // Refresh UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('새로운 복약 정보가 추가되었습니다!')),
                );
              },
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 분석 실패: $e')),
        );
      }
    }
  }

  // Opens a blank MedicationLog form for manual entry
  void _addMedicationManually() {
    final blankLog = MedicationLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      medicineName: '',
      dosage: '',
      frequencyPerDay: 1,
      totalDays: 3,
      prescriptionDate: DateTime.now().toIso8601String().split('T')[0],
      inputMethod: 'MANUAL',
      isActive: true,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiReviewScreen(
          initialLogs: [blankLog],
          onSave: (newLogs) async {
            for (var log in newLogs) {
              await localStorage.saveMedication(log);
            }
            _loadLocalData(); // Refresh UI state
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('새로운 복약 정보가 추가되었습니다!')),
            );
          },
        ),
      ),
    );
  }

  // Opens a blank DiagnosisLog form for manual entry
  void _addDiagnosisManually() {
    final blankLog = DiagnosisLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      diseaseName: '',
      diseaseCode: '',
      diagnosisDate: DateTime.now().toIso8601String().split('T')[0],
      hospitalName: '',
      doctorOpinion: '',
      inputMethod: 'MANUAL',
      isActive: true,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiagnosisReviewScreen(
          initialLogs: [blankLog],
          onSave: (newDiags) async {
            for (var diag in newDiags) {
              await localStorage.saveDiagnosis(diag);
            }
            _loadLocalData(); // Refresh UI state
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('새로운 진단 정보가 추가되었습니다!')),
            );
          },
        ),
      ),
    );
  }

  // Opens DiagnosisReviewScreen for editing a saved diagnosis log
  void _editDiagnosis(DiagnosisLog log) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiagnosisReviewScreen(
          initialLogs: [log],
          onSave: (updatedLogs) async {
            if (updatedLogs.isNotEmpty) {
              await localStorage.saveDiagnosis(updatedLogs.first);
              _loadLocalData(); // Refresh UI State
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('진단 정보가 성공적으로 수정되었습니다.')),
              );
            } else {
              // Deleted in the review screen
              await localStorage.deleteDiagnosis(log.id);
              _loadLocalData(); // Refresh UI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('진단 정보가 성공적으로 삭제되었습니다.')),
              );
            }
          },
        ),
      ),
    );
  }

  // Opens the QR Generator Screen with custom sharing expiration & content selection
  void _showQrGenerator() {
    int selectedSeconds = 180; // default 3 minutes
    bool shareProfile = true;
    bool shareMedicalInfo = true;
    // Set containing selected medication IDs (initially all medications are selected)
    Set<String> selectedMedicationIds = _medications.map((m) => m.id).toSet();
    // Set containing selected diagnosis IDs (initially all diagnoses are selected)
    Set<String> selectedDiagnosisIds = _diagnoses.map((d) => d.id).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow custom height and scrolling inside bottom sheet
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 20.0,
                  bottom: 20.0 + MediaQuery.of(context).padding.bottom,
                ),
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '바이탈패스 QR 생성 설정',
                      style: TextStyle(
                        color: onSurfaceColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Expiry selection header
                    const Text(
                      '1. QR 코드 유효기간 설정',
                      style: TextStyle(
                        color: onSurfaceColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Duration Option List
                    _buildDurationOption(
                      title: '1분 (보안 공유 권장)',
                      seconds: 60,
                      current: selectedSeconds,
                      onTap: () => setModalState(() => selectedSeconds = 60),
                    ),
                    const SizedBox(height: 10),
                    _buildDurationOption(
                      title: '3분 (기본값)',
                      seconds: 180,
                      current: selectedSeconds,
                      onTap: () => setModalState(() => selectedSeconds = 180),
                    ),
                    const SizedBox(height: 10),
                    _buildDurationOption(
                      title: '5분 (여유로운 열람)',
                      seconds: 300,
                      current: selectedSeconds,
                      onTap: () => setModalState(() => selectedSeconds = 300),
                    ),
                    const SizedBox(height: 10),
                    _buildDurationOption(
                      title: '10분 (대기 시간이 길 때)',
                      seconds: 600,
                      current: selectedSeconds,
                      onTap: () => setModalState(() => selectedSeconds = 600),
                    ),
                    
                    const Divider(height: 32),
                    
                    // Expiry selection header
                    const Text(
                      '2. 공유할 건강 정보 선택',
                      style: TextStyle(
                        color: onSurfaceColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Profile Checkbox
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: primaryColor,
                      title: const Text('기본 인적 사항 포함', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurfaceColor)),
                      subtitle: const Text('이름, 생년월일, 혈액형', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                      value: shareProfile,
                      onChanged: (val) {
                        setModalState(() {
                          shareProfile = val ?? true;
                        });
                      },
                    ),
                    
                    // Medical Info Checkbox
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: primaryColor,
                      title: const Text('민감 의료 요약 정보 포함', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurfaceColor)),
                      subtitle: const Text('만성 지병, 알레르기 내역, 비상 연락처', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                      value: shareMedicalInfo,
                      onChanged: (val) {
                        setModalState(() {
                          shareMedicalInfo = val ?? true;
                        });
                      },
                    ),
                    
                    if (_medications.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '복약 기록 개별 선택',
                        style: TextStyle(
                          color: onSurfaceColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._medications.map((med) {
                        final isChecked = selectedMedicationIds.contains(med.id);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: primaryColor,
                          title: Text(med.medicineName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurfaceColor)),
                          subtitle: Text('${med.dosage} • 하루 ${med.frequencyPerDay}회', style: const TextStyle(fontSize: 12, color: onSurfaceVariant)),
                          value: isChecked,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedMedicationIds.add(med.id);
                              } else {
                                selectedMedicationIds.remove(med.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],

                    if (_diagnoses.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '확진/진단서 기록 개별 선택',
                        style: TextStyle(
                          color: onSurfaceColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._diagnoses.map((diag) {
                        final isChecked = selectedDiagnosisIds.contains(diag.id);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: primaryColor,
                          title: Text(diag.diseaseName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurfaceColor)),
                          subtitle: Text('${diag.diseaseCode} • ${diag.hospitalName}', style: const TextStyle(fontSize: 12, color: onSurfaceVariant)),
                          value: isChecked,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedDiagnosisIds.add(diag.id);
                              } else {
                                selectedDiagnosisIds.remove(diag.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: (shareProfile || shareMedicalInfo || selectedMedicationIds.isNotEmpty || selectedDiagnosisIds.isNotEmpty)
                          ? () async {
                              Navigator.of(context).pop(); // Close BottomSheet
                              await _generateAndShowQr(
                                expireSeconds: selectedSeconds,
                                shareProfile: shareProfile,
                                shareMedicalInfo: shareMedicalInfo,
                                selectedMedicationIds: selectedMedicationIds,
                                selectedDiagnosisIds: selectedDiagnosisIds,
                              );
                            }
                          : null, // Disable button if nothing is checked
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        disabledBackgroundColor: outlineVariant,
                      ),
                      child: const Text(
                        'QR 코드 생성하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        );
      },
    );
  }

  Widget _buildDurationOption({
    required String title,
    required int seconds,
    required int current,
    required VoidCallback onTap,
  }) {
    final isSelected = seconds == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? primaryColor : outlineVariant,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? primaryColor : onSurfaceColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: primaryColor)
            else
              const Icon(Icons.radio_button_off, color: outlineColor),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndShowQr({
    required int expireSeconds,
    required bool shareProfile,
    required bool shareMedicalInfo,
    required Set<String> selectedMedicationIds,
    required Set<String> selectedDiagnosisIds,
  }) async {
    // Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: primaryColor),
        );
      },
    );

    try {
      // 1. Package actual local data with user's custom filtering selections
      final Map<String, dynamic> filteredProfile = {};
      if (shareProfile) {
        filteredProfile['uuid'] = _profile.uuid;
        filteredProfile['name'] = _profile.name;
        filteredProfile['birthDate'] = _profile.birthDate;
        filteredProfile['bloodType'] = _profile.bloodType;
        filteredProfile['updatedAt'] = _profile.updatedAt;
      }
      if (shareMedicalInfo) {
        filteredProfile['chronicDiseases'] = _profile.chronicDiseases;
        filteredProfile['allergies'] = _profile.allergies;
        filteredProfile['emergencyContact'] = _profile.emergencyContact;
      }

      final filteredMedications = _medications
          .where((m) => selectedMedicationIds.contains(m.id))
          .map((m) => m.toMap())
          .toList();

      final filteredDiagnoses = _diagnoses
          .where((d) => selectedDiagnosisIds.contains(d.id))
          .map((d) => d.toMap())
          .toList();

      final data = {
        'profile': filteredProfile,
        'medications': filteredMedications,
        'diagnoses': filteredDiagnoses,
      };
      
      final plaintext = json.encode(data);

      // 2. Encrypt using client-side service
      final encryptionResult = await encryptionService.encryptData(plaintext);

      // 3. Upload to backend server
      final qrUrl = await apiService.generateShareQrUrl(
        encryptionResult,
        expireSeconds: expireSeconds,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss Loading Dialog

        // 4. Push QrGeneratorScreen with real generated url
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QrGeneratorScreen(qrUrl: qrUrl),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss Loading Dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR 생성 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('메인 화면입니다.')),
            );
          },
        ),
        title: const Text(
          'QRDoc',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 2; // Jump to Profile tab
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: outlineVariant.withOpacity(0.5),
                child: const Icon(Icons.person, color: primaryColor),
              ),
            ),
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildRecordsTab(),
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQrGenerator,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.qr_code, color: Colors.white),
        label: const Text(
          '바이탈패스 QR',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: onSurfaceVariant,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_shared),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '프로필',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: HOME PAGE TAB
  // ==========================================
  Widget _buildHomeTab() {
    final activeLogs = _medications.where((m) => m.isActive).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: outlineVariant),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lock,
                    size: 40,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '안전한 건강 정보 지갑',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurfaceColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '암호화된 의료 기록과 처방전을 안전하게 보관하고 필요할 때 바로 확인하세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurfaceVariant,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main Add Record Button (supporting camera ocr & manual entry choice)
            ElevatedButton.icon(
              onPressed: _showAddMedicationOptions,
              icon: const Icon(Icons.add_circle_outline, size: 24, color: Colors.white),
              label: const Text(
                '새 건강 기록 추가',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Records Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 기록',
                  style: TextStyle(
                    color: onSurfaceColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 1; // Swap to Records tab
                    });
                  },
                  child: const Text('전체 보기', style: TextStyle(color: primaryColor)),
                )
              ],
            ),
            const SizedBox(height: 8),

            // Medications list
            activeLogs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30.0),
                    child: Text(
                      '최근 스캔한 처방 기록이 없습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeLogs.length > 2 ? 2 : activeLogs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = activeLogs[index];
                      return GestureDetector(
                        onTap: () => _editMedication(log),
                        onLongPress: () => _showDeleteConfirmDialog(
                          context: context,
                          title: '복약 기록 삭제',
                          content: '\'${log.medicineName}\' 복약 기록을 영구히 삭제하시겠습니까?',
                          onConfirm: () async {
                            await localStorage.deleteMedication(log.id);
                            _loadLocalData();
                          },
                        ),
                        child: _buildRecordCard(log),
                      );
                    },
                  ),
            const SizedBox(height: 80), // Prevent floating action button overlapping last card
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: RECORDS LIST TAB
  // ==========================================
  Widget _buildRecordsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '건강 및 의료 기록 전체',
            style: TextStyle(
              color: onSurfaceColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '스캔하거나 직접 기입한 약물 정보 및 진단 내역을 관리합니다. 길게 눌러 바로 삭제할 수 있습니다.',
            style: TextStyle(color: onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Custom Segmented Switcher Control
          Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: outlineVariant.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _recordsSubTabIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      decoration: BoxDecoration(
                        color: _recordsSubTabIndex == 0 ? surfaceColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: _recordsSubTabIndex == 0
                            ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '💊 복약 기록 (${_medications.length})',
                          style: TextStyle(
                            color: _recordsSubTabIndex == 0 ? primaryColor : onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _recordsSubTabIndex = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      decoration: BoxDecoration(
                        color: _recordsSubTabIndex == 1 ? surfaceColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: _recordsSubTabIndex == 1
                            ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '🩺 확진/진단서 (${_diagnoses.length})',
                          style: TextStyle(
                            color: _recordsSubTabIndex == 1 ? primaryColor : onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lists display
          Expanded(
            child: _recordsSubTabIndex == 0
                ? (_medications.isEmpty
                    ? const Center(
                        child: Text('저장된 복약 기록이 없습니다.', style: TextStyle(color: onSurfaceVariant)),
                      )
                    : ListView.separated(
                        itemCount: _medications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final log = _medications[index];
                          return GestureDetector(
                            onTap: () => _editMedication(log),
                            onLongPress: () => _showDeleteConfirmDialog(
                              context: context,
                              title: '복약 기록 삭제',
                              content: '\'${log.medicineName}\' 복약 기록을 영구히 삭제하시겠습니까?',
                              onConfirm: () async {
                                await localStorage.deleteMedication(log.id);
                                _loadLocalData();
                              },
                            ),
                            child: _buildRecordCard(log),
                          );
                        },
                      ))
                : (_diagnoses.isEmpty
                    ? const Center(
                        child: Text('저장된 진단 내역이 없습니다.', style: TextStyle(color: onSurfaceVariant)),
                      )
                    : ListView.separated(
                        itemCount: _diagnoses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final log = _diagnoses[index];
                          return GestureDetector(
                            onTap: () => _editDiagnosis(log),
                            onLongPress: () => _showDeleteConfirmDialog(
                              context: context,
                              title: '진단 기록 삭제',
                              content: '\'${log.diseaseName}\' 진단 기록을 영구히 삭제하시겠습니까?',
                              onConfirm: () async {
                                await localStorage.deleteDiagnosis(log.id);
                                _loadLocalData();
                              },
                            ),
                            child: _buildDiagnosisCard(log),
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }

  // Shows a premium alert dialog to confirm item deletion on long press
  void _showDeleteConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: onSurfaceColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            content,
            style: const TextStyle(
              color: onSurfaceVariant,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(color: onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                await onConfirm();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('기록이 성공적으로 삭제되었습니다.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Renders a high-contrast elegant diagnosis certificate item card
  Widget _buildDiagnosisCard(DiagnosisLog log) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: log.isActive ? outlineVariant : outlineVariant.withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  log.diseaseName,
                  style: const TextStyle(
                    color: onSurfaceColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: primaryContainer.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  log.diseaseCode,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: outlineVariant),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: outlineColor, size: 14),
              const SizedBox(width: 6),
              Text(
                '진단일: ${log.diagnosisDate}',
                style: const TextStyle(color: onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.local_hospital, color: outlineColor, size: 14),
              const SizedBox(width: 6),
              Text(
                '기관: ${log.hospitalName}',
                style: const TextStyle(color: onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
          if (log.doctorOpinion.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                log.doctorOpinion,
                style: const TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: PATIENT PROFILE TAB
  // ==========================================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Profile Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: outlineVariant),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A1A56DB),
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Stack(
                children: [
                  // Positioned Edit Button on the top right
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.edit_note, color: primaryColor, size: 28),
                      tooltip: '프로필 수정',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              profile: _profile,
                              onSave: (updatedProfile) async {
                                await localStorage.saveProfile(updatedProfile);
                                _loadLocalData(); // Refresh UI State
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('프로필 정보가 수정되었습니다.')),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.person, size: 40, color: primaryColor),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _profile.name,
                          style: const TextStyle(
                            color: onSurfaceColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '생년월일: ${_profile.birthDate}',
                          style: const TextStyle(color: onSurfaceVariant, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '혈액형: ${_profile.bloodType}',
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Health Details
            const Text(
              '민감 의료 정보 요약',
              style: TextStyle(
                color: onSurfaceColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Chronic Diseases Card
            _buildProfileDetailCard(
              title: '보유 만성 질환',
              icon: Icons.healing,
              iconColor: primaryColor,
              items: _profile.chronicDiseases,
              itemBgColor: Color(0xFFDBE1FF),
              itemTextColor: primaryColor,
            ),
            const SizedBox(height: 12),

            // Allergies Card
            _buildProfileDetailCard(
              title: '알레르기 내역',
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.red,
              items: _profile.allergies,
              itemBgColor: errorContainer,
              itemTextColor: onErrorContainer,
            ),
            const SizedBox(height: 20),

            // Emergency Contact Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: secondaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '비상 연락처',
                          style: TextStyle(
                            color: onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _profile.emergencyContact,
                          style: const TextStyle(
                            color: onSurfaceColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Emergency Lockscreen Widget Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: _isEmergencyPassEnabled ? errorColor : outlineVariant,
                  width: _isEmergencyPassEnabled ? 2.0 : 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05BA1A1A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency_share, color: errorColor),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '비상 의료 패스 (잠금화면 위젯)',
                          style: TextStyle(
                            color: onSurfaceColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Switch(
                        activeColor: errorColor,
                        value: _isEmergencyPassEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isEmergencyPassEnabled = value;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value 
                                  ? '비상 의료 패스 알림창 위젯이 활성화되었습니다. 잠금화면에서 비상 정보가 표시됩니다.' 
                                  : '비상 의료 패스 알림창 위젯이 비활성화되었습니다.'
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '사고 등 응급 상황 시, 구조대원이 기기를 잠금 해제하지 않고 알림바나 잠금화면에서 즉시 비상 의료 카드를 조회할 수 있게 상시 연동합니다.',
                    style: TextStyle(
                      color: onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (_isEmergencyPassEnabled) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EmergencyPassScreen(profile: _profile),
                          ),
                        );
                      },
                      icon: const Icon(Icons.preview, color: Colors.white, size: 18),
                      label: const Text('비상 의료 패스 미리보기', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Font Size Settings Card (어르신 배려 글자 크기 조절)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.text_fields, color: primaryColor),
                      SizedBox(width: 8),
                      Text(
                        '화면 글자 크기 조절 (어르신 배려)',
                        style: TextStyle(
                          color: onSurfaceColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Font Size Slider
                  Row(
                    children: [
                      const Text('가장 작게', style: TextStyle(fontSize: 11, color: onSurfaceVariant)),
                      Expanded(
                        child: Slider(
                          value: MyApp.fontSizeNotifier.value,
                          min: 0.85,
                          max: 1.45,
                          divisions: 4, // 0.85, 1.0, 1.15, 1.3, 1.45
                          activeColor: primaryColor,
                          inactiveColor: outlineVariant.withOpacity(0.3),
                          onChanged: (double value) async {
                            setState(() {
                              MyApp.fontSizeNotifier.value = value;
                            });
                            await localStorage.saveFontSizeFactor(value);
                          },
                        ),
                      ),
                      const Text('가장 크게', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Current level text indicator
                  Center(
                    child: Text(
                      _getFontSizeLabel(MyApp.fontSizeNotifier.value),
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _getFontSizeLabel(double value) {
    if (value < 0.9) return '작은 글씨 (0.85배)';
    if (value < 1.1) return '보통 글씨 (1.0배 - 기본값)';
    if (value < 1.2) return '조금 큰 글씨 (1.15배)';
    if (value < 1.4) return '큰 글씨 (1.30배 어르신 추천)';
    return '가장 큰 글씨 (1.45배)';
  }

  Widget _buildProfileDetailCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
    required Color itemBgColor,
    required Color itemTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: onSurfaceColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          items.isEmpty
              ? const Text('등록된 정보가 없습니다.', style: TextStyle(color: onSurfaceVariant, fontSize: 13))
              : Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: items.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: itemBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: itemTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // ==========================================
  // COMMON HELPER WIDGETS
  // ==========================================
  Widget _buildRecordCard(MedicationLog log) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A56DB),
            blurRadius: 15,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBE1FF), // primary-fixed
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.medicineName,
                      style: const TextStyle(
                        color: onSurfaceColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${log.dosage} • 하루 ${log.frequencyPerDay}회 • ${log.totalDays}일 복용',
                      style: const TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '처방일: ${log.prescriptionDate}',
                      style: const TextStyle(
                        color: outlineColor,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (log.inputMethod == 'GEMINI_AI_OCR')
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: secondaryContainer,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: secondaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: onSecondaryContainer,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AI 인증됨',
                      style: TextStyle(
                        color: onSecondaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Atkinson Hyperlegible Next',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom AdMob loading dialog shown during Gemini OCR processing
class AdmobLoadingDialog extends StatefulWidget {
  const AdmobLoadingDialog({Key? key}) : super(key: key);

  @override
  State<AdmobLoadingDialog> createState() => _AdmobLoadingDialogState();
}

class _AdmobLoadingDialogState extends State<AdmobLoadingDialog> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      // Official Google AdMob Test Banner Ad Unit ID
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.mediumRectangle, // Premium 300x250 medium rectangle banner
      request: const AdRequest(
        nonPersonalizedAds: true, // STRICT PRIVACY: Serve Non-Personalized Ads only
      ),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // Fail gracefully without crashing the user flow
          debugPrint('AdMob failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(color: Color(0xFF003FB1), strokeWidth: 3.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gemini AI 문서 분석 중...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191B23),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '약물 성분 및 소견 내용을 추출하고 있습니다. 잠시만 대기해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF434654),
              ),
            ),
            const SizedBox(height: 20),
            // AdMob Banner Container (300x250 Medium Rectangle)
            Container(
              height: 250,
              width: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8FF),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFC3C5D7)),
              ),
              alignment: Alignment.center,
              child: _isAdLoaded && _bannerAd != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11.0),
                      child: AdWidget(ad: _bannerAd!),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.ads_click, color: Color(0xFFC3C5D7), size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Sponsor Ad',
                          style: TextStyle(fontSize: 12, color: Color(0xFFC3C5D7), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
