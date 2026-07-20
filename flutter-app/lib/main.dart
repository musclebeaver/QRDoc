import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/patient_home_screen.dart';
import 'services/local_storage_service.dart';
import 'services/api_service.dart';
import 'services/encryption_service.dart';

// Singletons for database, networking, and cryptography
final LocalStorageService localStorage = LocalStorageService();
final EncryptionService encryptionService = EncryptionService();
final ApiService apiService = ApiService(
  baseUrl: const String.fromEnvironment('BASE_URL', defaultValue: 'https://qrdoc.devbeaver.cloud/api'),
  webViewerUrl: const String.fromEnvironment('WEB_VIEWER_URL', defaultValue: 'https://qrdoc.devbeaver.cloud/'),
);

void main() async {
  // Ensure Flutter engine bindings are initialized for native channels
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();
  
  // Initialize Hive encrypted database using secure OS credentials
  await localStorage.initDatabase();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalPass QRDoc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003FB1),
          primary: const Color(0xFF003FB1),
          surface: const Color(0xFFFAF8FF),
          background: const Color(0xFFFAF8FF),
        ),
        fontFamily: 'Inter',
      ),
      home: const PatientHomeScreen(),
    );
  }
}
