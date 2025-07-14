import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FoodPackagingDetailsScreen extends StatefulWidget {
  const FoodPackagingDetailsScreen({super.key});

  @override
  State<FoodPackagingDetailsScreen> createState() => _FoodPackagingDetailsScreenState();
}

class _FoodPackagingDetailsScreenState extends State<FoodPackagingDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Food & Packaging Consumption',
          style: TextStyle(
            color: Color(0xFFE4FFAC),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF5D6C24),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFE4FFAC)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE4FFAC)),
      ),
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
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 18.0),
                child: _buildDetailsContent(context),
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
                        // PROFILE ICON
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/profile');
                          },
                          child: Image.asset(
                            'assets/icons/profileunselect_icon.png',
                            width: 70,
                            height: 70,
                          ),
                        ),
                        
                        // HOME ICON (SELECTED)
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/home');
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
                                'assets/icons/homeselect_icon.png',
                                width: 70,
                                height: 70,
                              ),
                            ),
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

  Widget _buildDetailsContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Card with image and all content
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with padding
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/fooddetails.png',
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                // Title and content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title for information page
                      const Text(
                        'Food & Packaging – Information Page',
                        style: TextStyle(
                          color: Color(0xFF626F47),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildContentSection(
                        '🔍 What is Food & Packaging Emission?',
                        'Every food item you consume and every packaging product you throw away has an environmental cost. The production, transportation, and disposal of food and plastic generate carbon emissions.\n• Fast food meals produce high emissions due to meat, frying oils, and packaging waste.\n• Plastic items like bottles and bags take hundreds of years to break down and emit CO₂ during their lifecycle.',
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildContentSection(
                        '⚙️ How is Food & Packaging Emission Calculated?',
                        'The formula is simple:\n\nEmissions (kg CO₂e) = Quantity × Emission Factor (kg CO₂e per item)\n\n❤️ Example:\nIf you use 3 plastic bottles in a day:\nEmissions = 3 × 0.18 = 0.54 kg CO₂e\n\nOr if you eat 1 fast food meal:\nEmissions = 1 × 2.5 = 2.5 kg CO₂e',
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildContentSection(
                        '💕 Why It Matters',
                        '• Small changes like using reusable containers or reducing fast food intake can make a huge difference.\n• Being aware of your daily impact helps you form eco-friendly habits.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 120), // Space for bottom navigation bar
        ],
      ),
    );
  }

  Widget _buildContentSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF626F47),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Color(0xFF626F47),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
} 