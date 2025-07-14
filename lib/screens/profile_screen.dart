import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_button.dart';
import 'edit_profile_screen.dart';
import 'terms_policies_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  String _username = '';
  String _email = '';
  bool _isLoading = true;
  String? _profileImageUrl;
  String? _profileImageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userData = await _userService.getUserData(currentUser.uid);
        if (userData.exists) {
          // Convert to Map untuk penanganan data yang lebih aman
          Map<String, dynamic>? data = userData.data() as Map<String, dynamic>?;
          
          if (data != null) {
            setState(() {
              _username = data['username'] ?? 'User';
              _email = currentUser.email ?? '';
              
              // Akses data dengan pengecekan yang aman
              _profileImageUrl = data.containsKey('profileImageUrl') ? data['profileImageUrl'] : null;
              _profileImageBase64 = data.containsKey('profileImageBase64') ? data['profileImageBase64'] : null;
              
              print('Loaded profile data - Username: $_username, Email: $_email');
              print('Loaded profile image - URL: ${_profileImageUrl != null ? 'exists' : 'null'}, Base64: ${_profileImageBase64 != null ? 'exists' : 'null'}');
              
              _isLoading = false;
            });
          } else {
            print('User data exists but is null');
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          print('User document does not exist');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print('Current user is null');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error during logout: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getAndUploadImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getAndUploadImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Tampilkan progress dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecting image...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Compress image quality to 85% for smaller file size
        maxWidth: 800,    // Limit maximum width for smaller file size
      );
      
      if (pickedFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading image...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        
        final File imageFile = File(pickedFile.path);
        
        // Get current user
        User? currentUser = _authService.currentUser;
        if (currentUser != null) {
          // Upload image using UserService
          final imageData = await _userService.uploadProfileImage(currentUser.uid, imageFile);
          
          // Update state with new image data
          setState(() {
            // Safety check to ensure we're only setting values that exist
            if (imageData.containsKey('profileImageUrl')) {
              _profileImageUrl = imageData['profileImageUrl'];
            }
            if (imageData.containsKey('profileImageBase64')) {
              _profileImageBase64 = imageData['profileImageBase64'];
            }
            
            print('Updated profile image - Base64: ${_profileImageBase64 != null ? 'exists' : 'null'}, URL: ${_profileImageUrl != null ? 'exists' : 'null'}');
          });
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image updated successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('User not logged in');
        }
      } else {
        print('No image selected');
        // User cancelled image selection, no need to show error
      }
    } catch (e) {
      print('Error picking or uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile image: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
            : _buildProfileContent(),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Stack(
      children: [
        // Background leaf image - top left
        Positioned(
          top: -50,
          left: -30,
          child: Image.asset(
            'assets/images/leaf_left.png',
            width: 250,
            height: 250,
            fit: BoxFit.contain,
          ),
        ),
        
        // Background leaf image - bottom right
        Positioned(
          bottom: 120,
          right: -20,
          child: Image.asset(
            'assets/images/leaf_right.png',
            width: 250,
            height: 250,
            fit: BoxFit.contain,
          ),
        ),
        
        // Main content
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60), // Increased from 30 to move profile picture lower
                
                // Profile Picture - made larger with shadow and color A4B465
                GestureDetector(
                  onTap: _pickAndUploadProfileImage,
                  child: Container(
                    width: 134,
                    height: 134,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA4B465),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildProfileImage(),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickAndUploadProfileImage,
                  child: const Text(
                    'Edit Picture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Profile Options Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA4B465),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      children: [
                        // Edit Profile Option
                        _buildProfileOption(
                          icon: 'assets/icons/editprofile_icon.png',
                          title: 'Edit Profile',
                          onTap: () {
                            // Navigate to edit profile
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                  username: _username,
                                  email: _email,
                                ),
                              ),
                            ).then((_) {
                              // Reload user data when returning from edit profile screen
                              _loadUserData();
                            });
                          },
                        ),
                        
                        // No divider after Edit Profile
                        
                        // Report a Problem Option
                        _buildProfileOption(
                          icon: 'assets/icons/reportaproblem_icon.png',
                          title: 'Report a problem',
                          onTap: () {
                            Navigator.pushNamed(context, '/report');
                          },
                        ),
                        
                        // No divider between Report a problem and Terms and Policies
                        
                        // Terms and Policies Option
                        _buildProfileOption(
                          icon: 'assets/icons/termsandpolicies_icon.png',
                          title: 'Terms and Policies',
                          onTap: () {
                            // Navigate to terms and policies
                            Navigator.pushNamed(context, '/terms');
                          },
                        ),
                        
                        // No divider before Log out
                        
                        // Log Out Option
                        _buildProfileOption(
                          icon: 'assets/icons/logout_icon.png',
                          title: 'Log out',
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildProfileOption({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Image.asset(
              icon,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        color: Colors.white24,
        height: 1,
      ),
    );
  }

  Widget _buildProfileImage() {
    print('Building profile image: URL=${_profileImageUrl}, Base64=${_profileImageBase64 != null ? 'exists' : 'null'}');
    
    // If there's Base64 data, use it as primary source
    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(_profileImageBase64!);
        return ClipOval(
          child: Image.memory(
            imageBytes,
            width: 134,
            height: 134,
            fit: BoxFit.cover,
            // Use cacheWidth and cacheHeight for better performance
            cacheWidth: 268, // 2x for high DPI
            cacheHeight: 268, // 2x for high DPI
            errorBuilder: (context, error, stackTrace) {
              print('Error loading profile image from Base64: $error');
              return _buildDefaultProfileImage();
            },
          ),
        );
      } catch (e) {
        print('Error decoding Base64 image: $e');
        // If Base64 fails, try URL as fallback
        if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
          return _buildNetworkImage();
        }
        return _buildDefaultProfileImage();
      }
    } 
    // If no Base64 but URL exists, try network image
    else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return _buildNetworkImage();
    } 
    // Default image if nothing else works
    else {
      return _buildDefaultProfileImage();
    }
  }
  
  Widget _buildNetworkImage() {
    return ClipOval(
      child: Image.network(
        _profileImageUrl!,
        width: 134,
        height: 134,
        fit: BoxFit.cover,
        // Use cacheWidth and cacheHeight for better performance
        cacheWidth: 268, // 2x for high DPI
        cacheHeight: 268, // 2x for high DPI
        errorBuilder: (context, error, stackTrace) {
          print('Error loading profile image from URL: $error');
          return _buildDefaultProfileImage();
        },
      ),
    );
  }
  
  Widget _buildDefaultProfileImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: -24,
          child: Image.asset(
            'assets/icons/profileicon3.png',
            width: 125,
            height: 125,
          ),
        ),
      ],
    );
  }
} 