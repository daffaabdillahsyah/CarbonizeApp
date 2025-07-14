import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Starting login process');
      // Validate input fields
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw Exception('Please enter email and password');
      }

      print('Attempting to login with Firebase Auth');
      // Login with Firebase Auth
      final userCredential = await _authService.loginWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      print('Login successful for user: ${userCredential.user?.uid}');

      try {
        // Update last login timestamp
        print('Updating last login timestamp');
        await _userService.updateLastLogin(userCredential.user!.uid);
      } catch (firestoreError) {
        print('Firestore error: $firestoreError');
        // If user document doesn't exist in Firestore, create it
        if (userCredential.user != null) {
          print('Creating user document for: ${userCredential.user!.uid}');
          await _userService.createUserDocument(
            userCredential.user!,
            userCredential.user!.email?.split('@')[0] ?? 'user',
          );
        }
      }

      // Add explicit navigation to home screen
      if (mounted) {
        print('Navigation to home screen');
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('Login error: $e');
      if (mounted) {
        setState(() {
          // Clean up error message by removing Exception prefix and other noise
          String errorMsg = e.toString();
          errorMsg = errorMsg.replaceAll('Exception: ', '');
          errorMsg = errorMsg.replaceAll('firebase_auth/wrong-password', 'Wrong password');
          errorMsg = errorMsg.replaceAll('firebase_auth/', '');
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientTop,
              AppColors.gradientBottom,
            ],
            stops: [0.07, 1.0], // 7% from top for first color
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.08),
                const Text(
                  "Login",
                  style: AppTextStyles.loginTitle,
                ),
                SizedBox(height: screenHeight * 0.04),
                // Email Input Field
                Container(
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
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Image.asset(
                        'assets/icons/profileicon1.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            color: Color(0xFF5D6C24),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Email",
                            hintStyle: AppTextStyles.inputHint,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Password Input Field
                Container(
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
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Image.asset(
                        'assets/icons/lockicon.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            color: Color(0xFF5D6C24),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Password",
                            hintStyle: AppTextStyles.inputHint,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Image.asset(
                            _obscurePassword ? 'assets/icons/vieweyeicon.png' : 'assets/icons/vieweyeicon-open.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: "Register",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: _isLoading ? "Logging in..." : "Login",
                  onPressed: _isLoading ? (){} : () => _login(),
                ),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/Tree_home.png',
                      height: screenHeight * 0.55,
                      fit: BoxFit.contain,
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
} 