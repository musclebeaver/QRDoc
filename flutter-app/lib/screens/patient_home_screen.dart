import 'package:flutter/material.dart';
import '../models/patient_profile.dart';
import '../models/medication_log.dart';
import 'qr_generator_screen.dart';
import 'ai_review_screen.dart';

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

  // Mock Patient Profile
  final PatientProfile _profile = PatientProfile(
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
  final List<MedicationLog> _medications = [
    MedicationLog(
      id: '1',
      medicineName: 'Amoxicillin',
      dosage: '500mg',
      frequencyPerDay: 3,
      totalDays: 7,
      prescriptionDate: '2023-10-24',
      inputMethod: 'GEMINI_AI_OCR',
      isActive: true,
    ),
    MedicationLog(
      id: '2',
      medicineName: 'Lisinopril',
      dosage: '10mg',
      frequencyPerDay: 1,
      totalDays: 30,
      prescriptionDate: '2023-10-15',
      inputMethod: 'GEMINI_AI_OCR',
      isActive: true,
    ),
  ];

  int _currentIndex = 0;

  // Navigates to AI Review Screen to add a new prescription (simulating OCR scan)
  void _scanNewPrescription() {
    // Generate a mock log matching Gemini OCR output format
    final mockOcrLog = MedicationLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      medicineName: 'Metformin',
      dosage: '500mg',
      frequencyPerDay: 2,
      totalDays: 14,
      prescriptionDate: '2026-07-18',
      inputMethod: 'GEMINI_AI_OCR',
      isActive: true,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiReviewScreen(
          initialLog: mockOcrLog,
          onSave: (newLog) {
            setState(() {
              _medications.insert(0, newLog);
            });
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
          initialLog: log,
          onSave: (updatedLog) {
            setState(() {
              final index = _medications.indexWhere((m) => m.id == updatedLog.id);
              if (index != -1) {
                _medications[index] = updatedLog;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('복약 정보가 성공적으로 수정되었습니다.')),
            );
          },
        ),
      ),
    );
  }

  // Opens the QR Generator Screen with a mock sharing URL
  void _showQrGenerator() {
    // Zero-Knowledge URL simulation: id is query parameter, secret key is in URL hash fragment
    const mockShareUrl = 'http://qrdoc.devbeaver.cloud/?id=share-592b1a8f#k9120ba98dce1e289f81';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QrGeneratorScreen(qrUrl: mockShareUrl),
      ),
    );
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
            // Revert back or show a toast
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

            // Main Scan Button
            ElevatedButton.icon(
              onPressed: _scanNewPrescription,
              icon: const Icon(Icons.photo_camera, size: 24, color: Colors.white),
              label: const Text(
                '새 처방전 스캔하기',
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
            '처방 및 복약 기록 전체',
            style: TextStyle(
              color: onSurfaceColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '클릭하여 처방 로그 세부사항을 확인하고 직접 수정할 수 있습니다.',
            style: TextStyle(color: onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _medications.isEmpty
                ? const Center(
                    child: Text('저장된 복약 기록이 없습니다.'),
                  )
                : ListView.separated(
                    itemCount: _medications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = _medications[index];
                      return GestureDetector(
                        onTap: () => _editMedication(log),
                        child: _buildRecordCard(log),
                      );
                    },
                  ),
          ),
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
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
