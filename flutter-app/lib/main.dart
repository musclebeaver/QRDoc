import 'package:flutter/material.dart';
import 'screens/patient_home_screen.dart';
import 'services/local_storage_service.dart';

// Singleton instance of the secure storage database service
final LocalStorageService localStorage = LocalStorageService();

void main() async {
  // Ensure Flutter engine bindings are initialized for native channels
  WidgetsFlutterBinding.ensureInitialized();
  
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
