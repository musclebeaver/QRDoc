import 'package:flutter/material.dart';
import '../models/patient_profile.dart';

class EmergencyPassScreen extends StatefulWidget {
  final PatientProfile profile;

  const EmergencyPassScreen({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  State<EmergencyPassScreen> createState() => _EmergencyPassScreenState();
}

class _EmergencyPassScreenState extends State<EmergencyPassScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Set up emergency pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBA1A1A), // Emergency Red
      appBar: AppBar(
        backgroundColor: const Color(0xFFBA1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '🚨 EMERGENCY MEDICAL ID',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.2,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Red Flashing Pulse Heart Icon
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 2. Alert Subtitle
              const Text(
                '이 카드는 응급상황 발생 시 구조대원 및 의료진이 잠금화면 상태에서 즉각 확인할 수 있는 비상 의료 패스입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 32),

              // 3. Name & Birth
              _buildInfoSection(
                title: '환자 성명 (Full Name)',
                value: widget.profile.name,
                valueSize: 24.0,
                valueWeight: FontWeight.bold,
              ),
              const Divider(color: Colors.white30, height: 28),

              // 4. Blood Type & Birth Date Row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoSection(
                      title: '혈액형 (Blood Type)',
                      value: widget.profile.bloodType,
                      valueColor: const Color(0xFFFFDAD6),
                      valueSize: 28.0,
                      valueWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoSection(
                      title: '생년월일 (Birth Date)',
                      value: widget.profile.birthDate,
                      valueSize: 20.0,
                      valueWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white30, height: 28),

              // 5. Chronic Diseases Card
              _buildEmergencyListCard(
                title: '만성 질환 및 지병 (Chronic Conditions)',
                icon: Icons.healing,
                items: widget.profile.chronicDiseases,
              ),
              const SizedBox(height: 16),

              // 6. Allergies Card
              _buildEmergencyListCard(
                title: '알레르기 내역 (Allergies)',
                icon: Icons.warning_amber_rounded,
                items: widget.profile.allergies,
              ),
              const Divider(color: Colors.white30, height: 28),

              // 7. Emergency Contact
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.contact_phone, color: Colors.white, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '비상 보호자 연락처 (Emergency Contact)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.profile.emergencyContact,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Mock phone call action
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${widget.profile.emergencyContact} 번호로 전화를 연결합니다.')),
                        );
                      },
                      icon: const Icon(Icons.call, color: Colors.greenAccent, size: 28),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String value,
    Color valueColor = Colors.white,
    double valueSize = 18.0,
    FontWeight valueWeight = FontWeight.normal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '없음' : value,
          style: TextStyle(
            color: valueColor,
            fontSize: valueSize,
            fontWeight: valueWeight,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyListCard({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          items.isEmpty
              ? const Text(
                  '등록된 내역 없음',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                )
              : Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: items.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
