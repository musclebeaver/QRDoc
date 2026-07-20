import 'package:flutter/material.dart';
import '../models/medication_log.dart';

class AiReviewScreen extends StatefulWidget {
  final List<MedicationLog> initialLogs;
  final Function(List<MedicationLog>) onSave;

  const AiReviewScreen({
    Key? key,
    required this.initialLogs,
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
  static const Color errorColor = Color(0xFFBA1A1A);

  // Lists to manage batch controllers dynamically
  final List<Map<String, TextEditingController>> _controllersList = [];
  final List<String> _ids = [];
  final List<String> _dates = [];
  final List<String> _methods = [];
  final List<bool> _actives = [];

  @override
  void initState() {
    super.initState();
    // Load initial logs into batch controller state
    for (var log in widget.initialLogs) {
      _addLogToControllers(log);
    }
  }

  @override
  void dispose() {
    for (var controllers in _controllersList) {
      controllers['name']?.dispose();
      controllers['dosage']?.dispose();
      controllers['frequency']?.dispose();
      controllers['duration']?.dispose();
    }
    super.dispose();
  }

  // Appends a new medication card representation to the controllers state
  void _addLogToControllers(MedicationLog log) {
    _ids.add(log.id);
    _dates.add(log.prescriptionDate);
    _methods.add(log.inputMethod);
    _actives.add(log.isActive);
    _controllersList.add({
      'name': TextEditingController(text: log.medicineName),
      'dosage': TextEditingController(text: log.dosage),
      'frequency': TextEditingController(text: '${log.frequencyPerDay}'),
      'duration': TextEditingController(text: '${log.totalDays}'),
    });
  }

  // Adds a blank medication item to the batch editor
  void _addNewBlankMedication() {
    setState(() {
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
      _addLogToControllers(blankLog);
    });
  }

  // Deletes an item from the batch controllers list
  void _removeItem(int index) {
    setState(() {
      _controllersList[index]['name']?.dispose();
      _controllersList[index]['dosage']?.dispose();
      _controllersList[index]['frequency']?.dispose();
      _controllersList[index]['duration']?.dispose();

      _controllersList.removeAt(index);
      _ids.removeAt(index);
      _dates.removeAt(index);
      _methods.removeAt(index);
      _actives.removeAt(index);
    });
  }

  // Validates input fields and saves the batch list to local storage
  void _handleSave() {
    final List<MedicationLog> updatedLogs = [];
    
    for (int i = 0; i < _controllersList.length; i++) {
      final name = _controllersList[i]['name']!.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('약물 #${i + 1}의 약품명을 입력해 주세요.')),
        );
        return;
      }

      final dosage = _controllersList[i]['dosage']!.text.trim();
      final freqStr = _controllersList[i]['frequency']!.text;
      final durStr = _controllersList[i]['duration']!.text;
      
      int freq = int.tryParse(freqStr.replaceAll(RegExp(r'\D'), '')) ?? 1;
      int days = int.tryParse(durStr.replaceAll(RegExp(r'\D'), '')) ?? 3;

      updatedLogs.add(
        MedicationLog(
          id: _ids[i],
          medicineName: name,
          dosage: dosage.isEmpty ? '미지정' : dosage,
          frequencyPerDay: freq,
          totalDays: days,
          prescriptionDate: _dates[i],
          inputMethod: _methods[i],
          isActive: _actives[i],
        ),
      );
    }

    if (updatedLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 복약 기록이 없습니다.')),
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
          '일괄 처방 확인 및 편집',
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
                            'AI 다중 추출 결과 검토',
                            style: TextStyle(
                              color: onSurfaceColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '처방전에서 스캔된 모든 약물 리스트를 일괄 수정하거나 약물을 추가/삭제할 수 있습니다.',
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

              // 2. Batch Form List
              Expanded(
                child: _controllersList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('편집할 약물이 없습니다.', style: TextStyle(color: onSurfaceVariant)),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _addNewBlankMedication,
                              icon: const Icon(Icons.add, color: primaryColor),
                              label: const Text('약물 직접 추가', style: TextStyle(color: primaryColor)),
                            )
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _controllersList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          return _buildMedicationCard(index);
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // 3. Action Buttons at the Bottom
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addNewBlankMedication,
                          icon: const Icon(Icons.add, color: primaryColor),
                          label: const Text('약물 추가'),
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
            ],
          ),
        ),
      ),
    );
  }

  // Renders a card for an individual medication in the batch
  Widget _buildMedicationCard(int index) {
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
          // Card Header: Drug Number and Delete Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '약물 #${index + 1}',
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

          // 1. Drug Name Text Field
          _buildCardTextField(
            controller: controllers['name']!,
            label: '약품명',
            icon: Icons.medication,
            placeholder: '약품명을 입력하세요',
          ),
          const SizedBox(height: 12),

          // 2. Dosage & Frequency Row
          Row(
            children: [
              Expanded(
                child: _buildCardTextField(
                  controller: controllers['dosage']!,
                  label: '용량',
                  icon: Icons.scale,
                  placeholder: '예: 500mg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCardTextField(
                  controller: controllers['frequency']!,
                  label: '1일 복용 횟수',
                  icon: Icons.schedule,
                  placeholder: '예: 3',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Duration Field
          _buildCardTextField(
            controller: controllers['duration']!,
            label: '총 복용 일수',
            icon: Icons.calendar_today,
            placeholder: '예: 7',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // Custom text field tailored for layout cards
  Widget _buildCardTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
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
          keyboardType: keyboardType,
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
