import 'package:flutter/material.dart';
import '../models/medication_log.dart';

class AiReviewScreen extends StatefulWidget {
  final MedicationLog initialLog;
  final Function(MedicationLog) onSave;

  const AiReviewScreen({
    Key? key,
    required this.initialLog,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends State<AiReviewScreen> {
  // Theme Color Constants (VitalPass Design System)
  static const Color primaryColor = Color(0xFF003FB1);
  static const Color primaryContainer = Color(0xFF1A56DB);
  static const Color backgroundColor = Color(0xFFFAF8FF);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color outlineColor = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C5D7);
  static const Color onSurfaceColor = Color(0xFF191B23);
  static const Color onSurfaceVariant = Color(0xFF434654);

  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _frequencyController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialLog.medicineName);
    _dosageController = TextEditingController(text: widget.initialLog.dosage);
    _frequencyController = TextEditingController(text: '하루 ${widget.initialLog.frequencyPerDay}회');
    _durationController = TextEditingController(text: '${widget.initialLog.totalDays}일');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // Parse controllers back to numeric values where applicable
    int freq = widget.initialLog.frequencyPerDay;
    final matchFreq = RegExp(r'\d+').firstMatch(_frequencyController.text);
    if (matchFreq != null) {
      freq = int.tryParse(matchFreq.group(0) ?? '') ?? freq;
    }

    int days = widget.initialLog.totalDays;
    final matchDays = RegExp(r'\d+').firstMatch(_durationController.text);
    if (matchDays != null) {
      days = int.tryParse(matchDays.group(0) ?? '') ?? days;
    }

    final updatedLog = MedicationLog(
      id: widget.initialLog.id,
      medicineName: _nameController.text,
      dosage: _dosageController.text,
      frequencyPerDay: freq,
      totalDays: days,
      prescriptionDate: widget.initialLog.prescriptionDate,
      inputMethod: 'GEMINI_AI_OCR',
      isActive: widget.initialLog.isActive,
    );

    widget.onSave(updatedLog);
    Navigator.of(context).pop();
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '처방전 확인',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Info Banner
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: primaryContainer.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: primaryContainer.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'AI 추출 정보',
                            style: TextStyle(
                              color: onSurfaceColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gemini AI가 스캔된 문서에서 다음 정보를 추출했습니다. 저장하기 전에 내용을 확인해주세요.',
                            style: TextStyle(
                              color: onSurfaceVariant,
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Form Fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drug Name
                      _buildTextField(
                        controller: _nameController,
                        label: '약물명',
                        icon: Icons.medication,
                        placeholder: '약물명을 입력하세요',
                      ),
                      const SizedBox(height: 20),

                      // Bento grid: Dosage & Frequency
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _dosageController,
                              label: '용량',
                              icon: Icons.scale,
                              placeholder: '예: 500mg',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _frequencyController,
                              label: '복용 횟수',
                              icon: Icons.schedule,
                              placeholder: '예: 하루 3회',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Duration
                      _buildTextField(
                        controller: _durationController,
                        label: '복용 기간',
                        icon: Icons.calendar_today,
                        placeholder: '예: 7일',
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Actions at bottom
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text(
                        '확인 및 저장',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        '직접 수정하기',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            label,
            style: const TextStyle(
              color: onSurfaceColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Atkinson Hyperlegible Next',
            ),
          ),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: onSurfaceColor,
            fontSize: 16,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: outlineColor),
            prefixIcon: Icon(icon, color: outlineColor),
            filled: true,
            fillColor: surfaceColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: outlineVariant, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: primaryColor, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}
