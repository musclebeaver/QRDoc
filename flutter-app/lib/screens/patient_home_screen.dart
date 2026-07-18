import 'package:flutter/material.dart';
import '../models/medication_log.dart';

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

  // Mock list of recent medication logs matching the Stitch design state
  final List<MedicationLog> _recentMedications = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {},
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: outlineVariant.withOpacity(0.5),
              child: const Icon(Icons.person, color: primaryColor),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Banner
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: outlineVariant),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 48,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '안전한 건강 정보 지갑',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: onSurfaceColor,
                        fontSize: 24,
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
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Main Scan Button
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.photo_camera, size: 28, color: Colors.white),
                label: const Text(
                  '새 처방전 스캔하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 32),

              // 3. Recent Records Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '최근 기록',
                    style: TextStyle(
                      color: onSurfaceColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('전체 보기', style: TextStyle(color: primaryColor)),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Records Grid/List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentMedications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final log = _recentMedications[index];
                  return _buildRecordCard(log);
                },
              ),
            ],
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
          // Content
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
                      '${log.dosage} • ${log.frequencyPerDay}회 • ${log.totalDays}일 복용',
                      style: const TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '추가됨: ${log.prescriptionDate}',
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
          // AI Chip on Top Right
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
