import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FuelConsumptionDetailsScreen extends StatefulWidget {
  const FuelConsumptionDetailsScreen({super.key});

  @override
  State<FuelConsumptionDetailsScreen> createState() => _FuelConsumptionDetailsScreenState();
}

class _FuelConsumptionDetailsScreenState extends State<FuelConsumptionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fuel Consumption',
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
                      'assets/images/fueldetails.png',
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
                        'Fuel Consumption – Information Page',
                        style: TextStyle(
                          color: Color(0xFF626F47),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildContentSection(
                        'What is Fuel Consumption Emission?',
                        'Fuel consumption refers to the amount of fuel you use when driving a motorbike or a car. When fuel is burned, it releases carbon dioxide (CO₂) into the atmosphere — one of the major contributors to climate change.\n\nDifferent fuel types release different amounts of CO₂. For example, diesel emits more CO₂ per liter than petrol, while LPG emits the least.',
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildContentSection(
                        'How is Fuel Emission Calculated?',
                        'The emission is calculated using this formula:\n\nEmissions (kg CO₂e) = Distance Traveled (km) / Fuel Efficiency (km/l) × Emission Factor (kg CO₂e/l)\n\nExample:\nIf you travel 60 km using a city car with an efficiency of 12 km/l (Petrol):\nFuel used = 60 ÷ 12 = 5 liters\nEmissions = 5 × 2.31 = 11.55 kg CO₂e',
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildContentSection(
                        'Why It Matters',
                        '• Driving shorter distances or using more efficient vehicles can significantly reduce emissions.\n• Switching to public transport or carpooling is even better for the planet.',
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