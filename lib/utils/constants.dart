import 'package:flutter/material.dart';

class AppColors {
  // Background gradient colors
  static const Color gradientTop = Color(0xFF5D6C24);
  static const Color gradientBottom = Color(0xFFA4B465);
  
  // Text and UI element colors
  static const Color accentGreen = Color(0xFFE4FFAC);
  static const Color textLight = Color(0xFFF3CFA2);
  static const Color white = Colors.white;
  static const Color buttonBrown = Color(0xFF55481D);
  static const Color inputTextColor = Color(0xFF5D6C24);
  static const Color inputHintColor = Color(0x4D5D6C24); // 30% opacity of dark green
}

class AppTextStyles {
  static const TextStyle loginTitle = TextStyle(
    color: AppColors.accentGreen,
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle inputHint = TextStyle(
    color: AppColors.inputHintColor,
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
  );
  
  static const TextStyle forgotPassword = TextStyle(
    color: AppColors.white,
    fontSize: 12,
    fontWeight: FontWeight.w600, // SemiBold
  );
  
  static const TextStyle registerText = TextStyle(
    color: AppColors.textLight,
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle registerLink = TextStyle(
    color: AppColors.white,
    fontSize: 12,
    fontWeight: FontWeight.w600, // SemiBold
  );

  static const TextStyle buttonText = TextStyle(
    color: AppColors.accentGreen,
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
}

class AppDimensions {
  static const double inputCornerRadius = 8.0;
} 