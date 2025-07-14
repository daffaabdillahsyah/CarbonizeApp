import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'upload_emission_factors.dart';

/// This is a standalone script that can be run to upload emission factors to Firebase.
/// Run this once to populate the database, then use the main app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const UploadEmissionFactorsApp());
}

class UploadEmissionFactorsApp extends StatelessWidget {
  const UploadEmissionFactorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upload Emission Factors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D6C24)),
        useMaterial3: true,
      ),
      home: const UploadEmissionFactorsScreen(),
    );
  }
} 