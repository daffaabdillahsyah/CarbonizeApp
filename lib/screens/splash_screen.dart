import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the main app after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/auth_wrapper');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7C8C40), // 0% stop - top
              Color(0xFF5D6C24), // 47% stop - middle
              Color(0xFFA4B465), // 100% stop - bottom
            ],
            stops: [0.0, 0.47, 1.0],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/carbonize_logo.png',
            width: 280,
            height: 280,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
} 