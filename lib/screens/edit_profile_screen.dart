import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  final String username;
  final String email;

  const EditProfileScreen({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _dailyCarbonLimitController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Focus nodes to track when fields are focused
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _dateOfBirthFocus = FocusNode();
  final FocusNode _dailyCarbonLimitFocus = FocusNode();
  
  // Store original values to restore if user cancels editing
  String _originalUsername = '';
  String _originalDateOfBirth = '';
  String _originalDailyCarbonLimit = '';

  @override
  void initState() {
    super.initState();
    _originalUsername = widget.username;
    _usernameController.text = _originalUsername;
    _emailController.text = widget.email;
    _passwordController.text = '******'; // Placeholder for password
    
    // Set up focus listeners
    _usernameFocus.addListener(_onUsernameFocusChange);
    _dateOfBirthFocus.addListener(_onDateOfBirthFocusChange);
    _dailyCarbonLimitFocus.addListener(_onDailyCarbonLimitFocusChange);
    
    _loadUserData();
  }

  @override
  void dispose() {
    // Clean up controllers
    _usernameController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    _dailyCarbonLimitController.dispose();
    _passwordController.dispose();
    
    // Clean up focus nodes
    _usernameFocus.removeListener(_onUsernameFocusChange);
    _usernameFocus.dispose();
    _dateOfBirthFocus.removeListener(_onDateOfBirthFocusChange);
    _dateOfBirthFocus.dispose();
    _dailyCarbonLimitFocus.removeListener(_onDailyCarbonLimitFocusChange);
    _dailyCarbonLimitFocus.dispose();
    
    super.dispose();
  }
  
  // Focus change listeners
  void _onUsernameFocusChange() {
    if (_usernameFocus.hasFocus) {
      _usernameController.clear();
    } else if (_usernameController.text.isEmpty) {
      _usernameController.text = _originalUsername;
    }
  }
  
  void _onDateOfBirthFocusChange() {
    if (_dateOfBirthFocus.hasFocus) {
      _dateOfBirthController.clear();
    } else if (_dateOfBirthController.text.isEmpty) {
      _dateOfBirthController.text = _originalDateOfBirth;
    }
  }
  
  void _onDailyCarbonLimitFocusChange() {
    if (_dailyCarbonLimitFocus.hasFocus) {
      _dailyCarbonLimitController.clear();
    } else if (_dailyCarbonLimitController.text.isEmpty) {
      _dailyCarbonLimitController.text = _originalDailyCarbonLimit;
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userData = await _userService.getUserData(currentUser.uid);
        if (userData.exists) {
          // Store original values
          _originalDateOfBirth = userData['dateOfBirth'] ?? 'DD/MM/YYYY';
          _originalDailyCarbonLimit = userData['dailyCarbonLimit']?.toString() ?? '6';
          
          setState(() {
            _dateOfBirthController.text = _originalDateOfBirth;
            _dailyCarbonLimitController.text = _originalDailyCarbonLimit;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Update user data in Firestore
        await _userService.updateUserData(currentUser.uid, {
          'username': _usernameController.text,
          'dateOfBirth': _dateOfBirthController.text,
          'dailyCarbonLimit': int.tryParse(_dailyCarbonLimitController.text) ?? 6,
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context); // Go back to profile screen
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: ${e.toString()}';
      });
      print('Error updating profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isLoading = false;
    String errorMessage = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFA4B465),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Change Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Password
                      const Text(
                        'Current Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF626F47).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: TextField(
                                  controller: currentPasswordController,
                                  obscureText: obscureCurrentPassword,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Enter current password',
                                    hintStyle: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureCurrentPassword = !obscureCurrentPassword;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // New Password
                      const Text(
                        'New Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF626F47).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: TextField(
                                  controller: newPasswordController,
                                  obscureText: obscureNewPassword,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Enter new password',
                                    hintStyle: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureNewPassword = !obscureNewPassword;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Confirm New Password
                      const Text(
                        'Confirm New Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF626F47).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: TextField(
                                  controller: confirmPasswordController,
                                  obscureText: obscureConfirmPassword,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Confirm new password',
                                    hintStyle: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureConfirmPassword = !obscureConfirmPassword;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF626F47),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          // Validate inputs
                          if (currentPasswordController.text.isEmpty ||
                              newPasswordController.text.isEmpty ||
                              confirmPasswordController.text.isEmpty) {
                            setState(() {
                              errorMessage = 'All fields are required';
                            });
                            return;
                          }
                          
                          // Check if passwords match
                          if (newPasswordController.text != confirmPasswordController.text) {
                            setState(() {
                              errorMessage = 'New passwords do not match';
                            });
                            return;
                          }
                          
                          // Check password strength
                          if (newPasswordController.text.length < 6) {
                            setState(() {
                              errorMessage = 'Password must be at least 6 characters';
                            });
                            return;
                          }
                          
                          // Attempt to change password
                          setState(() {
                            isLoading = true;
                            errorMessage = '';
                          });
                          
                          try {
                            await _authService.changePassword(
                              currentPasswordController.text,
                              newPasswordController.text,
                            );
                            
                            // Close dialog and show success message
                            Navigator.of(context).pop();
                            
                            if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password changed successfully'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              errorMessage = e.toString().replaceAll('Exception: ', '');
                              isLoading = false;
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
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
              AppColors.gradientTop,
              AppColors.gradientBottom,
            ],
            stops: [0.07, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
              : _buildEditProfileContent(),
        ),
      ),
    );
  }

  Widget _buildEditProfileContent() {
    return Stack(
      children: [
        // Main content
        Column(
          children: [
            // App bar with back button and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFFE4FFAC),
                      size: 24,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Color(0xFFE4FFAC),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24), // Balance for back button
                ],
              ),
            ),
            
            // Form content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Information Section
                      const Text(
                        'Profile Information',
                        style: TextStyle(
                          color: Color(0xFFF5ECD5),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Username Field
                      const Text(
                        'Username',
                        style: TextStyle(
                          color: Color(0xFFF5ECD5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA4B465),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _usernameController,
                            focusNode: _usernameFocus,
                            style: const TextStyle(
                              color: Color(0xFF5D6C24),
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Color(0xFF5D6C24),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Email Field
                      const Text(
                        'Email',
                        style: TextStyle(
                          color: Color(0xFFF5ECD5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA4B465),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _emailController,
                            enabled: false, // Email cannot be changed
                            style: const TextStyle(
                              color: Color(0xFF5D6C24),
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Color(0xFF5D6C24),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Date of Birth Field
                      const Text(
                        'Date of Birth',
                        style: TextStyle(
                          color: Color(0xFFF5ECD5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA4B465),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _dateOfBirthController,
                            focusNode: _dateOfBirthFocus,
                            style: const TextStyle(
                              color: Color(0xFF5D6C24),
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'DD/MM/YYYY',
                              hintStyle: TextStyle(
                                color: Color(0xFF5D6C24),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Daily Carbon Limit Field
                      const Text(
                        'Your Daily Carbon Limit',
                        style: TextStyle(
                          color: Color(0xFFF5ECD5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA4B465),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Number input
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: TextField(
                                  controller: _dailyCarbonLimitController,
                                  focusNode: _dailyCarbonLimitFocus,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: Color(0xFF5D6C24),
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '6',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF5D6C24),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Unit label (kg CO2e)
                            Container(
                              padding: const EdgeInsets.only(right: 12),
                              child: const Text(
                                'kg CO2e',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Field
                      const Text(
                        'Password',
                        style: TextStyle(
                          color: Color(0xFFF5ECD5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA4B465),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _passwordController,
                                  enabled: false,
                                  obscureText: true,
                                  style: const TextStyle(
                                    color: Color(0xFF5D6C24),
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _showChangePasswordDialog,
                                child: const Text(
                                  'Change password',
                                  style: TextStyle(
                                    color: Color(0xFFF0BB78),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Save Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 120,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF626F47),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _saveProfile,
                              borderRadius: BorderRadius.circular(8),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFF5ECD5),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Save',
                                        style: TextStyle(
                                          color: Color(0xFFF5ECD5),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Bottom navigation bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 20,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.70,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0BB78),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // PROFILE ICON (SELECTED)
                  Container(
                    width: 74,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF55481D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/icons/profileselect_icon.png',
                        width: 70,
                        height: 70,
                      ),
                    ),
                  ),
                  
                  // HOME ICON (UNSELECTED)
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: Image.asset(
                      'assets/icons/homeunselect_icon.png',
                      width: 70,
                      height: 70,
                    ),
                  ),
                  
                  // CALCULATOR ICON
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/calculator');
                    },
                    child: Image.asset(
                      'assets/icons/calculatorunselect_icon.png',
                      width: 70,
                      height: 70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
} 