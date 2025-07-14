import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserEmail() async {
    try {
      User? currentUser = _authService.currentUser;
      if (currentUser != null && currentUser.email != null) {
        setState(() {
          _emailController.text = currentUser.email!;
        });
      }
    } catch (e) {
      print('Error loading user email: $e');
    }
  }
  
  Future<void> _submitReport() async {
    if (_emailController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create a map of data to store
      final reportData = {
        'email': _emailController.text,
        'description': _descriptionController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _authService.currentUser?.uid ?? 'anonymous',
      };
      
      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('problem_reports')
          .add(reportData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      print('Error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
          child: Stack(
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
                              'Report a Problem',
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
                            // Email Field with integrated label
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
                                    const Text(
                                      'Email: ',
                                      style: TextStyle(
                                        color: Color(0xFF5D6C24),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _emailController,
                                        style: const TextStyle(
                                          color: Color(0xFF5D6C24),
                                          fontSize: 16,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Enter your email',
                                          hintStyle: TextStyle(
                                            color: const Color(0xFFEEEEEE).withOpacity(0.6),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Description Field without separate label
                            Container(
                              height: 150,
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
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: TextField(
                                      controller: _descriptionController,
                                      maxLines: 7,
                                      style: const TextStyle(
                                        color: Color(0xFF5D6C24),
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'How can we improve your experience using this app?',
                                        hintStyle: TextStyle(
                                          color: const Color(0xFFEEEEEE).withOpacity(0.6),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: _submitReport,
                                      child: Icon(
                                        Icons.send,
                                        color: const Color(0xFF5D6C24),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Loading indicator
                            if (_isLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 24.0),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFE4FFAC),
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
          ),
        ),
      ),
    );
  }
} 