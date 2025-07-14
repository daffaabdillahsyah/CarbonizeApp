import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomInputField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  
  const CustomInputField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    required this.controller,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.accentGreen,
        borderRadius: BorderRadius.circular(AppDimensions.inputCornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: Color(0xFF5D6C24),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.inputHint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
        ),
      ),
    );
  }
} 