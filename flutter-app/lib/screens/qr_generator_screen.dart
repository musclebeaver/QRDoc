import 'dart:async';
import 'package:flutter/material.dart';

class QrGeneratorScreen extends StatefulWidget {
  final String qrUrl; // The encrypted payload sharing URL containing the hash key

  const QrGeneratorScreen({
    Key? key,
    required this.qrUrl,
  }) : super(key: key);

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  // Theme Color Constants (VitalPass Design System)
  static const Color primaryColor = Color(0xFF003FB1);
  static const Color backgroundColor = Color(0xFFFAF8FF);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color outlineVariant = Color(0xFFC3C5D7);
  static const Color onSurfaceColor = Color(0xFF191B23);
  static const Color onSurfaceVariant = Color(0xFF434654);
  static const Color amberColor = Color(0xFFFBBF24); // For countdown warning

  Timer? _timer;
  int _secondsRemaining = 165; // 2 minutes 45 seconds (165 seconds)
  bool _isQrRevealed = false; // Mock tap-to-reveal or hover-to-reveal trigger

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Circumference math for progress indicator
    final double progress = _secondsRemaining / 165;

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
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Header
                const Text(
                  '바이탈패스',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '의료진에게 이 QR 코드를 보여주어 안전하게 정보를 전달하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurfaceVariant,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 32),

                // 2. QR Vault Card
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: outlineVariant),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 15,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Security Badge
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.lock, size: 14, color: primaryColor),
                              SizedBox(width: 4),
                              Text(
                                '암호화됨',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // QR Code Container (with Tap to Reveal overlay)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isQrRevealed = !_isQrRevealed;
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: outlineVariant),
                              ),
                              child: ClipRect(
                                child: Image.network(
                                  'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(widget.qrUrl)}',
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback QR Mockup if offline
                                    return const Icon(Icons.qr_code, size: 150, color: onSurfaceVariant);
                                  },
                                ),
                              ),
                            ),
                            // Blur Filter & Reveal Action Overlay
                            if (!_isQrRevealed)
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      size: 48,
                                      color: outlineVariant,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '터치하여 QR 보기',
                                      style: TextStyle(
                                        color: onSurfaceVariant,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
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

                      // Circular Countdown Timer
                      Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 4,
                                  backgroundColor: outlineVariant.withOpacity(0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(amberColor),
                                ),
                              ),
                              Text(
                                _formatTime(),
                                style: const TextStyle(
                                  color: amberColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '남은 시간',
                            style: TextStyle(
                              color: onSurfaceVariant,
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Security Badges
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildSecurityBadge(Icons.security, '종단간 암호화'),
                          _buildSecurityBadge(Icons.timer_10, '일회용'),
                          _buildSecurityBadge(Icons.local_fire_department, '조회 후 파기'),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: onSurfaceVariant,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
