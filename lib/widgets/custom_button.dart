import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppColors.buttonBrown,
    this.textColor = AppColors.accentGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.inputCornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.inputCornerRadius),
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: SizedBox(
          height: 50,
          child: Center(
            child: Text(
              text,
              style: AppTextStyles.buttonText,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
} 