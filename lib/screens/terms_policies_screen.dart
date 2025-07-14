import 'package:flutter/material.dart';
import '../utils/constants.dart';

class TermsPoliciesScreen extends StatefulWidget {
  const TermsPoliciesScreen({super.key});

  @override
  State<TermsPoliciesScreen> createState() => _TermsPoliciesScreenState();
}

class _TermsPoliciesScreenState extends State<TermsPoliciesScreen> {
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
              Column(
                children: [
                  // Custom app bar with back button and title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            color: Color(0xFFE4FFAC),
                            size: 24,
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Terms and Policies',
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
                  
                  // Main content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 18.0),
                      child: _buildTermsContent(context),
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
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/profile');
                          },
                          child: Container(
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

  Widget _buildTermsContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/termsandpoliciescontent_icon.png',
                  width: 28,
                  height: 28,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Terms and Policies',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Terms Content Card
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Introduction
                _buildTermsSection(
                  '1. Introduction',
                  'This application is developed as part of an academic research project titled "Design of a Mobile Application for Calculating Carbon Footprint Reduction". The purpose of this application is to help individual users estimate and reduce their daily carbon emissions based on fuel consumption and the use of single-use products.\nBy using this application, you agree to the following terms and conditions.',
                ),
                
                const SizedBox(height: 20),
                
                // 2. User Responsibility
                _buildTermsSection(
                  '2. User Responsibility',
                  'Users are responsible for the accuracy of the data they input into the application, including travel distance, fuel type, and consumption of packaged food or plastic items.\nThe carbon footprint calculations are estimates based on widely accepted emission factors (e.g., DEFRA, IPCC) and may not reflect precise environmental impact.',
                ),
                
                const SizedBox(height: 20),
                
                // 3. Data Privacy
                _buildTermsSection(
                  '3. Data Privacy',
                  'This application does not store personal data or user accounts. All data input is processed locally on the device and is not transmitted to any server.\nNo login or registration is required.\nThe application operates offline and does not collect identifiable information from users.',
                ),
                
                const SizedBox(height: 20),
                
                // 4. Use of Emission Factors
                _buildTermsSection(
                  '4. Use of Emission Factors',
                  'Emission calculations are based on open-source environmental datasets from trusted sources such as the UK DEFRA, IPCC, and Our World in Data.\nThese factors are subject to change based on updated research. Users are advised that results are for educational and awareness purposes.',
                ),
                
                const SizedBox(height: 20),
                
                // 5. Limitation of Liability
                _buildTermsSection(
                  '5. Limitation of Liability',
                  'This application is provided "as is" without any warranties, guarantees, or claims of precision.\nThe developer is not liable for any decisions, actions, or consequences arising from the use of this app\'s results.\nThis app is intended as an environmental awareness tool and not for regulatory or commercial use.',
                ),
                
                const SizedBox(height: 20),
                
                // 6. Contact Information
                _buildTermsSection(
                  '6. Contact Information',
                  'For suggestions, feedback, or concerns regarding this application, you may contact the research developer through the academic institution Telkom University.',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 120), // Space for bottom navigation bar
        ],
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
} 