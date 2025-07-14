import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TipsDialog extends StatelessWidget {
  final int fuelEmissions;
  final int foodPackagingEmissions;
  final DateTime viewDate;
  
  const TipsDialog({
    Key? key, 
    required this.fuelEmissions, 
    required this.foodPackagingEmissions,
    required this.viewDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format the date as DD/MM/YYYY
    final String formattedDate = DateFormat('dd/MM/yyyy').format(viewDate);
    
    // Determine which category has higher emissions or if they're equal
    final bool fuelIsHigher = fuelEmissions > foodPackagingEmissions;
    final bool foodIsHigher = foodPackagingEmissions > fuelEmissions;
    final bool emissionsEqual = fuelEmissions == foodPackagingEmissions;
    
    // Select tips based on usage pattern
    final List<Map<String, String>> tipsToShow = _selectTips(fuelIsHigher, foodIsHigher, emissionsEqual);
    
    // Get screen size to make dialog responsive
    final Size screenSize = MediaQuery.of(context).size;
    final double dialogHeight = screenSize.height * 0.6; // 60% of screen height
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        width: double.infinity,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF4D5639), // Dark green background as requested
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title with light bulb icon
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFF4D5639),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tips and Recommendation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'For $formattedDate',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Display selected tips in a scrollable container
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display the 6 selected tips
                      for (int i = 0; i < tipsToShow.length; i++) ...[
                        if (i > 0) ...[
                          const SizedBox(height: 8),
                          const Divider(color: Colors.white30, height: 1),
                          const SizedBox(height: 8),
                        ],
                        _buildTipItem(
                          icon: tipsToShow[i]['icon']!,
                          title: tipsToShow[i]['title']!,
                          description: tipsToShow[i]['description']!,
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Select 6 tips based on emissions pattern
  List<Map<String, String>> _selectTips(bool fuelIsHigher, bool foodIsHigher, bool emissionsEqual) {
    // All tips
    final List<Map<String, String>> fuelTips = [
      {
        'icon': '🛣️',
        'title': 'Drive Smart',
        'description': 'Avoid sudden braking and acceleration. Smooth driving improves fuel efficiency and reduces CO₂ emissions.',
      },
      {
        'icon': '🚗💨',
        'title': 'Carpool When Possible',
        'description': 'Share rides with friends, coworkers, or neighbors to reduce the number of vehicles on the road.',
      },
      {
        'icon': '🧼',
        'title': 'Maintain Your Vehicle',
        'description': 'Regular servicing, clean air filters, and properly inflated tires can significantly improve mileage and reduce emissions.',
      },
      {
        'icon': '⛽',
        'title': 'Choose Fuel Efficient Vehicles',
        'description': 'If buying or renting, opt for vehicles with better fuel economy ratings (e.g., LCGC or hybrid).',
      },
      {
        'icon': '⛽',
        'title': 'Don\'t Idle Unnecessarily',
        'description': 'Turn off your engine if you\'re waiting for more than 60 seconds. Idling burns fuel and emits CO₂ for no reason.',
      },
      {
        'icon': '🧭',
        'title': 'Plan Efficient Routes',
        'description': 'Use apps to avoid traffic and plan routes that combine errands to reduce distance traveled.',
      },
      {
        'icon': '🌬️',
        'title': 'Lighten the Load',
        'description': 'Remove unnecessary weight from your vehicle. Extra weight means higher fuel consumption.',
      },
      {
        'icon': '🅿️',
        'title': 'Park Smart',
        'description': 'Avoid circling endlessly to find the closest spot. Park further and walk a bit — you save fuel and stay active!',
      },
      {
        'icon': '🚶',
        'title': 'Walk or Bike for Short Trips',
        'description': 'For trips under 2–3 km, walking or biking emits zero CO₂ and improves your health.',
      },
      {
        'icon': '🕐',
        'title': 'Travel During Off-Peak Hours',
        'description': 'Avoiding traffic jams reduces idling and improves fuel efficiency.',
      },
      {
        'icon': '🏍️',
        'title': 'Use Motorcycles Wisely',
        'description': 'Motorcycles consume less fuel than cars. If traveling alone, consider riding instead of driving.',
      },
      {
        'icon': '🔌',
        'title': 'Switch to Hybrid or Biofuel Options',
        'description': 'If EVs are not accessible, consider hybrid or biofuel-compatible vehicles to cut fuel emissions.',
      },
      {
        'icon': '🅿️',
        'title': 'Avoid Aggressive Driving',
        'description': 'Harsh turns and racing not only waste fuel but also wear out your engine and brakes faster.',
      },
      {
        'icon': '🔧',
        'title': 'Use the Right Engine Oil',
        'description': 'Using the manufacturer-recommended oil can improve efficiency and reduce engine stress.',
      },
      {
        'icon': '📉',
        'title': 'Monitor Fuel Usage',
        'description': 'Track your fuel use weekly. It raises awareness and helps detect wasteful habits or car issues early.',
      },
    ];
    
    final List<Map<String, String>> foodPackagingTips = [
      {
        'icon': '🛍️',
        'title': 'Choose Minimal Packaging',
        'description': 'Buy products with little to no plastic or excessive wrapping. Less packaging means less manufacturing and waste emissions.',
      },
      {
        'icon': '🥡',
        'title': 'Bring Your Own Containers',
        'description': 'Use your own bags, jars, or containers when shopping or ordering takeout to cut down on single-use plastics.',
      },
      {
        'icon': '🍎',
        'title': 'Buy Local & Seasonal',
        'description': 'Local foods require less transportation and refrigeration. Seasonal items are often fresher and lower in carbon impact.',
      },
      {
        'icon': '♻️',
        'title': 'Reuse and Repurpose Packaging',
        'description': 'Glass jars, paper bags, and plastic containers can be reused at home instead of discarded.',
      },
      {
        'icon': '🚫',
        'title': 'Say No to Single-Use',
        'description': 'Avoid disposable cutlery, straws, and food wrappers. Reusables last longer and reduce landfill waste.',
      },
      {
        'icon': '📦',
        'title': 'Buy in Bulk',
        'description': 'Bulk products typically use less packaging per unit and reduce repeat transport emissions.',
      },
      {
        'icon': '🍽️',
        'title': 'Avoid Food Waste',
        'description': 'Only buy what you\'ll use. Store food properly and get creative with leftovers to reduce methane emissions from food waste.',
      },
      {
        'icon': '🍃',
        'title': 'Support Eco-Friendly Brands',
        'description': 'Choose brands with sustainable packaging and ethical sourcing. Look for certifications or eco-labels.',
      },
      {
        'icon': '📆',
        'title': 'Plan Meals Ahead',
        'description': 'Pre-planning weekly meals helps you avoid impulse buying and excess packaging.',
      },
      {
        'icon': '🛒',
        'title': 'Bring a Reusable Shopping Bag',
        'description': 'Plastic bags take centuries to degrade. Keep a cloth bag in your backpack or motorbike compartment.',
      },
      {
        'icon': '🍫',
        'title': 'Choose Low-Carbon Treats',
        'description': 'Chocolate, cheese, and red meat have high carbon footprints. Enjoy them occasionally or choose plant-based alternatives.',
      },
      {
        'icon': '🍵',
        'title': 'Choose Compostable Packaging',
        'description': 'Opt for brands using compostable or biodegradable packaging where possible.',
      },
      {
        'icon': '🍍',
        'title': 'Support Bulk Markets & Warungs',
        'description': 'Traditional markets often sell without excessive packaging, unlike many supermarkets.',
      },
      {
        'icon': '🧊',
        'title': 'Reduce Refrigerated Storage',
        'description': 'Frozen foods and prolonged refrigeration consume energy. Eat fresh, store right.',
      },
      {
        'icon': '🧃',
        'title': 'Avoid Plastic Bottled Drinks',
        'description': 'Choose refill stations, tumbler-friendly cafes, or local drinks in returnable glass bottles.',
      },
      {
        'icon': '🧯',
        'title': 'Freeze Leftovers',
        'description': 'If you can\'t finish a meal, freeze it! It prevents waste and gives you an easy meal for later.',
      },
    ];
    
    // Decide how many tips to show from each category based on emissions
    int fuelTipsCount;
    int foodTipsCount;
    
    if (emissionsEqual) {
      // If emissions are equal, show equal number of tips
      fuelTipsCount = 3;
      foodTipsCount = 3;
    } else if (fuelIsHigher) {
      // If fuel emissions are higher, show more fuel tips
      fuelTipsCount = 4;
      foodTipsCount = 2;
    } else { // foodIsHigher
      // If food & packaging emissions are higher, show more food tips
      fuelTipsCount = 2;
      foodTipsCount = 4;
    }
    
    // Select tips randomly from each category
    fuelTips.shuffle();
    foodPackagingTips.shuffle();
    
    // Get the specified number of tips from each category
    List<Map<String, String>> selectedTips = [];
    selectedTips.addAll(fuelTips.take(fuelTipsCount));
    selectedTips.addAll(foodPackagingTips.take(foodTipsCount));
    
    // Shuffle the combined list to mix the categories
    selectedTips.shuffle();
    
    return selectedTips;
  }
  
  Widget _buildTipItem({required String icon, required String title, required String description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with emoji icon
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              icon,
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Description
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
} 