import 'package:flutter/material.dart';
import '../models/patient_profile.dart';

class EditProfileScreen extends StatefulWidget {
  final PatientProfile profile;
  final Function(PatientProfile) onSave;

  const EditProfileScreen({
    Key? key,
    required this.profile,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Color Constants matching VitalPass Design System
  static const Color primaryColor = Color(0xFF003FB1);
  static const Color primaryContainer = Color(0xFF1A56DB);
  static const Color backgroundColor = Color(0xFFFAF8FF);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color outlineColor = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C5D7);
  static const Color onSurfaceColor = Color(0xFF191B23);
  static const Color onSurfaceVariant = Color(0xFF434654);

  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _birthDateController;
  late TextEditingController _contactController;
  
  String _selectedBloodType = 'A+';
  List<String> _chronicDiseases = [];
  List<String> _allergies = [];

  final TextEditingController _diseaseInputController = TextEditingController();
  final TextEditingController _allergyInputController = TextEditingController();

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _birthDateController = TextEditingController(text: widget.profile.birthDate);
    _contactController = TextEditingController(text: widget.profile.emergencyContact);
    
    _selectedBloodType = _bloodTypes.contains(widget.profile.bloodType) 
        ? widget.profile.bloodType 
        : 'A+';
        
    _chronicDiseases = List.from(widget.profile.chronicDiseases);
    _allergies = List.from(widget.profile.allergies);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _contactController.dispose();
    _diseaseInputController.dispose();
    _allergyInputController.dispose();
    super.dispose();
  }

  // Opens the native date picker and formats the result as YYYY-MM-DD
  Future<void> _selectBirthDate() async {
    DateTime initial = DateTime.tryParse(_birthDateController.text) ?? DateTime(1980, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
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
        _birthDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  // Appends a tag to chronic diseases
  void _addDisease() {
    final text = _diseaseInputController.text.trim();
    if (text.isNotEmpty && !_chronicDiseases.contains(text)) {
      setState(() {
        _chronicDiseases.add(text);
        _diseaseInputController.clear();
      });
    }
  }

  // Appends a tag to allergies
  void _addAllergy() {
    final text = _allergyInputController.text.trim();
    if (text.isNotEmpty && !_allergies.contains(text)) {
      setState(() {
        _allergies.add(text);
        _allergyInputController.clear();
      });
    }
  }

  // Triggers form validation and saves profile state
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = PatientProfile(
        uuid: widget.profile.uuid.isEmpty 
            ? DateTime.now().millisecondsSinceEpoch.toString() 
            : widget.profile.uuid,
        name: _nameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        bloodType: _selectedBloodType,
        chronicDiseases: _chronicDiseases,
        allergies: _allergies,
        emergencyContact: _contactController.text.trim(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      widget.onSave(updatedProfile);
      Navigator.of(context).pop();
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '내 프로필 수정',
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profile Avatar Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: const Icon(Icons.person_outline, size: 48, color: primaryColor),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '환자 본인의 정확한 건강 요약 정보를 작성해주세요.',
                        style: TextStyle(color: onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Name field
                _buildSectionHeader('기본 정보 입력'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _nameController,
                  label: '성명',
                  icon: Icons.person,
                  placeholder: '이름을 입력하세요',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이름은 필수 항목입니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. Birth date and Blood type Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDatePickerField(
                        controller: _birthDateController,
                        label: '생년월일',
                        icon: Icons.calendar_today,
                        onTap: _selectBirthDate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildDropdownField(),
                    ),
                  ],
                ),
                const Divider(height: 40, color: outlineVariant),

                // 4. Dynamic tags list: Chronic Diseases
                _buildSectionHeader('만성 지병 및 만성 질환'),
                const SizedBox(height: 8),
                _buildTagInputField(
                  controller: _diseaseInputController,
                  placeholder: '질환명을 입력하고 추가를 누르세요',
                  onAdd: _addDisease,
                ),
                const SizedBox(height: 10),
                _buildTagsWrap(
                  items: _chronicDiseases,
                  onRemove: (item) {
                    setState(() {
                      _chronicDiseases.remove(item);
                    });
                  },
                  activeColor: primaryColor,
                ),
                const Divider(height: 40, color: outlineVariant),

                // 5. Dynamic tags list: Allergies
                _buildSectionHeader('알레르기 및 부작용 내역'),
                const SizedBox(height: 8),
                _buildTagInputField(
                  controller: _allergyInputController,
                  placeholder: '알레르기 유발 물질을 입력하세요',
                  onAdd: _addAllergy,
                ),
                const SizedBox(height: 10),
                _buildTagsWrap(
                  items: _allergies,
                  onRemove: (item) {
                    setState(() {
                      _allergies.remove(item);
                    });
                  },
                  activeColor: Colors.red[700]!,
                ),
                const Divider(height: 40, color: outlineVariant),

                // 6. Emergency Contact Field
                _buildSectionHeader('응급 상황 연락처'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _contactController,
                  label: '비상 연락처',
                  icon: Icons.phone,
                  placeholder: '예: 010-1234-5678',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '비상 연락처는 필수 항목입니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // 7. Save Button
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    '저장하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 15,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: onSurfaceColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: outlineColor, fontSize: 14),
            prefixIcon: Icon(icon, color: outlineColor, size: 20),
            filled: true,
            fillColor: surfaceColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: outlineVariant, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: IgnorePointer(
            child: TextFormField(
              controller: controller,
              style: const TextStyle(color: onSurfaceColor, fontSize: 15),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: outlineColor, size: 20),
                filled: true,
                fillColor: surfaceColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: outlineVariant, width: 1.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '혈액형',
          style: TextStyle(color: onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: outlineVariant, width: 1.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBloodType,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: outlineColor),
              items: _bloodTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type, style: const TextStyle(color: onSurfaceColor, fontSize: 15)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedBloodType = val;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagInputField({
    required TextEditingController controller,
    required String placeholder,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: onSurfaceColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: outlineColor, fontSize: 13),
              filled: true,
              fillColor: surfaceColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: outlineVariant, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: const Text('추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTagsWrap({
    required List<String> items,
    required Function(String) onRemove,
    required Color activeColor,
  }) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: Text('등록된 항목이 없습니다. (예시 데이터를 입력하여 추가해 주세요)', style: TextStyle(color: outlineColor, fontSize: 12)),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: activeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activeColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => onRemove(item),
                icon: Icon(Icons.close, size: 16, color: activeColor),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
