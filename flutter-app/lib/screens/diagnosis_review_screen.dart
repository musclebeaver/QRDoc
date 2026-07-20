import 'package:flutter/material.dart';
import '../models/diagnosis_log.dart';

class DiagnosisReviewScreen extends StatefulWidget {
  final List<DiagnosisLog> initialLogs;
  final Function(List<DiagnosisLog>) onSave;

  const DiagnosisReviewScreen({
    Key? key,
    required this.initialLogs,
    required this.onSave,
  }) : super(key: key);

  @override
  State<DiagnosisReviewScreen> createState() => _DiagnosisReviewScreenState();
}

class _DiagnosisReviewScreenState extends State<DiagnosisReviewScreen> {
  // Theme Colors (VitalPass Design System)
  static const Color primaryColor = Color(0xFF003FB1);
  static const Color primaryContainer = Color(0xFF1A56DB);
  static const Color backgroundColor = Color(0xFFFAF8FF);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color outlineColor = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C5D7);
  static const Color onSurfaceColor = Color(0xFF191B23);
  static const Color onSurfaceVariant = Color(0xFF434654);
  static const Color errorColor = Color(0xFFBA1A1A);

  // States to manage controllers dynamically
  final List<Map<String, TextEditingController>> _controllersList = [];
  final List<String> _ids = [];
  final List<String> _methods = [];
  final List<bool> _actives = [];

  @override
  void initState() {
    super.initState();
    for (var log in widget.initialLogs) {
      _addLogToControllers(log);
    }
  }

  @override
  void dispose() {
    for (var controllers in _controllersList) {
      controllers['diseaseName']?.dispose();
      controllers['diseaseCode']?.dispose();
      controllers['diagnosisDate']?.dispose();
      controllers['hospitalName']?.dispose();
      controllers['doctorOpinion']?.dispose();
    }
    super.dispose();
  }

  void _addLogToControllers(DiagnosisLog log) {
    _ids.add(log.id);
    _methods.add(log.inputMethod);
    _actives.add(log.isActive);
    _controllersList.add({
      'diseaseName': TextEditingController(text: log.diseaseName),
      'diseaseCode': TextEditingController(text: log.diseaseCode),
      'diagnosisDate': TextEditingController(text: log.diagnosisDate),
      'hospitalName': TextEditingController(text: log.hospitalName),
      'doctorOpinion': TextEditingController(text: log.doctorOpinion),
    });
  }

  void _addNewBlankDiagnosis() {
    setState(() {
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
      _addLogToControllers(blankLog);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _controllersList[index]['diseaseName']?.dispose();
      _controllersList[index]['diseaseCode']?.dispose();
      _controllersList[index]['diagnosisDate']?.dispose();
      _controllersList[index]['hospitalName']?.dispose();
      _controllersList[index]['doctorOpinion']?.dispose();

      _controllersList.removeAt(index);
      _ids.removeAt(index);
      _methods.removeAt(index);
      _actives.removeAt(index);
    });
  }

  Future<void> _selectDiagnosisDate(int index) async {
    final controller = _controllersList[index]['diagnosisDate']!;
    DateTime initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: onSurfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  void _handleSave() {
    final List<DiagnosisLog> updatedLogs = [];

    for (int i = 0; i < _controllersList.length; i++) {
      final diseaseName = _controllersList[i]['diseaseName']!.text.trim();
      if (diseaseName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('진단 #${i + 1}의 병명을 입력해 주세요.')),
        );
        return;
      }

      final diseaseCode = _controllersList[i]['diseaseCode']!.text.trim().toUpperCase();
      final diagnosisDate = _controllersList[i]['diagnosisDate']!.text.trim();
      final hospitalName = _controllersList[i]['hospitalName']!.text.trim();
      final doctorOpinion = _controllersList[i]['doctorOpinion']!.text.trim();

      updatedLogs.add(
        DiagnosisLog(
          id: _ids[i],
          diseaseName: diseaseName,
          diseaseCode: diseaseCode.isEmpty ? '미분류' : diseaseCode,
          diagnosisDate: diagnosisDate,
          hospitalName: hospitalName.isEmpty ? '미지정 병원' : hospitalName,
          doctorOpinion: doctorOpinion,
          inputMethod: _methods[i],
          isActive: _actives[i],
        ),
      );
    }

    if (updatedLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 진단 내역이 없습니다.')),
      );
      return;
    }

    widget.onSave(updatedLogs);
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
          '진단서 확인 및 편집',
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
              // Info banner
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
                    const Icon(Icons.description, color: primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '진단서 정보 검토',
                            style: TextStyle(
                              color: onSurfaceColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '진단서 또는 소견서에서 추출된 확진 내역을 검토 및 추가 수정하여 지갑에 저장할 수 있습니다.',
                            style: TextStyle(
                              color: onSurfaceVariant,
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Form list
              Expanded(
                child: _controllersList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('편집할 진단 내역이 없습니다.', style: TextStyle(color: onSurfaceVariant)),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _addNewBlankDiagnosis,
                              icon: const Icon(Icons.add, color: primaryColor),
                              label: const Text('진단 내역 직접 추가', style: TextStyle(color: primaryColor)),
                            )
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _controllersList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          return _buildDiagnosisCard(index);
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // Bottom action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addNewBlankDiagnosis,
                      icon: const Icon(Icons.add, color: primaryColor),
                      label: const Text('진단 추가'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text('전체 확인 및 저장', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
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

  Widget _buildDiagnosisCard(int index) {
    final controllers = _controllersList[index];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x051A56DB),
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
              Text(
                '진단 내역 #${index + 1}',
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.delete_outline, color: errorColor),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            ],
          ),
          const SizedBox(height: 12),

          // 1. Disease Name
          _buildCardTextField(
            controller: controllers['diseaseName']!,
            label: '확진 병명',
            icon: Icons.healing,
            placeholder: '예: 2형 당뇨병, 위염 등',
          ),
          const SizedBox(height: 12),

          // 2. Disease Code & Diagnosis Date
          Row(
            children: [
              Expanded(
                child: _buildCardTextField(
                  controller: controllers['diseaseCode']!,
                  label: '질병 코드',
                  icon: Icons.qr_code,
                  placeholder: '예: E11',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '진단 일자',
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDiagnosisDate(index),
                      child: IgnorePointer(
                        child: TextField(
                          controller: controllers['diagnosisDate']!,
                          style: const TextStyle(color: onSurfaceColor, fontSize: 14),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.calendar_today, color: outlineColor, size: 18),
                            filled: true,
                            fillColor: backgroundColor,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(color: outlineVariant, width: 1.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Hospital Name
          _buildCardTextField(
            controller: controllers['hospitalName']!,
            label: '진단 의료기관',
            icon: Icons.local_hospital,
            placeholder: '예: 서울대학교병원',
          ),
          const SizedBox(height: 12),

          // 4. Doctor Opinion
          _buildCardTextField(
            controller: controllers['doctorOpinion']!,
            label: '소견 및 조치 사항',
            icon: Icons.rate_review,
            placeholder: '예: 운동 병행 요망, 주기적 당 수치 점검',
          ),
        ],
      ),
    );
  }

  Widget _buildCardTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: onSurfaceColor,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: outlineColor, fontSize: 13),
            prefixIcon: Icon(icon, color: outlineColor, size: 18),
            filled: true,
            fillColor: backgroundColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: outlineVariant, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
