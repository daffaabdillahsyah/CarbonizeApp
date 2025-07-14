import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  String _username = '';
  bool _isLoading = true;
  
  // Page controller for swiping between monthly and yearly views
  final PageController _pageController = PageController();
  bool _isMonthlyView = true;
  
  // Selected month and year for viewing
  DateTime _selectedMonth = DateTime.now();
  
  // Current date for display (now a formatted string based on _selectedMonth)
  String get _currentMonth => DateFormat('MMMM, yyyy').format(_selectedMonth).toUpperCase();
  String get _currentYear => DateFormat('yyyy').format(_selectedMonth);
  
  // Monthly emissions data
  int _totalMonthlyEmissions = 0;
  final List<CarbonCategory> _categories = [
    CarbonCategory(
      name: 'Food & Packaging Consumption',
      percentage: 0,
      value: 0,
      color: const Color(0xFF7DA7C9),
    ),
    CarbonCategory(
      name: 'Fuel Consumption',
      percentage: 0,
      value: 0,
      color: const Color(0xFFE6BC62),
    ),
  ];
  
  // Sample data for yearly bar chart
  List<MonthlyEmission> _monthlyEmissions = [
    MonthlyEmission(month: 'January', value: 6000),
    MonthlyEmission(month: 'February', value: 4000),
    MonthlyEmission(month: 'March', value: 9000),
    MonthlyEmission(month: 'April', value: 5000),
    MonthlyEmission(month: 'May', value: 4500),
    MonthlyEmission(month: 'June', value: 3500),
  ];

  // Add _yearlyCategories declaration that was mentioned in the implementation
  final List<CarbonCategory> _yearlyCategories = [
    CarbonCategory(
      name: 'Food & Packaging Consumption',
      percentage: 0,
      value: 0,
      color: const Color(0xFF7DA7C9),
    ),
    CarbonCategory(
      name: 'Fuel Consumption',
      percentage: 0,
      value: 0,
      color: const Color(0xFFE6BC62),
    ),
  ];

  // Add a new method to load yearly emissions data
  Future<void> _loadYearlyEmissions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Get start and end of the selected year
        final DateTime startOfYear = DateTime(_selectedMonth.year, 1, 1);
        final DateTime endOfYear = DateTime(_selectedMonth.year, 12, 31, 23, 59, 59);
        
        // Get entries from Firestore for the selected year
        final entriesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('consumption_entries')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
            .get();
        
        // Calculate emissions for each month
        Map<int, Map<String, int>> monthlyData = {};
        for (int i = 1; i <= 12; i++) {
          monthlyData[i] = {'food': 0, 'fuel': 0};
        }
        
        for (var doc in entriesSnapshot.docs) {
          final data = doc.data();
          final category = data['category'] as String? ?? '';
          final emissions = (data['emissions'] as num?)?.toInt() ?? 0;
          
          // Get month from timestamp
          DateTime date = (data['date'] as Timestamp).toDate();
          int month = date.month;
          
          if (category == 'Food & Packaging Consumption') {
            monthlyData[month]?['food'] = (monthlyData[month]?['food'] ?? 0) + emissions;
          } else if (category == 'Fuel Consumption') {
            monthlyData[month]?['fuel'] = (monthlyData[month]?['fuel'] ?? 0) + emissions;
          }
        }
        
        // Update monthly emissions data for chart
        List<MonthlyEmission> updatedEmissions = [];
        int yearlyTotalFood = 0;
        int yearlyTotalFuel = 0;
        
        final List<String> monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        
        for (int i = 1; i <= 12; i++) {
          final food = monthlyData[i]?['food'] ?? 0;
          final fuel = monthlyData[i]?['fuel'] ?? 0;
          final total = food + fuel;
          
          updatedEmissions.add(MonthlyEmission(
            month: monthNames[i-1], 
            value: total,
            foodValue: food,
            fuelValue: fuel
          ));
          
          yearlyTotalFood += food;
          yearlyTotalFuel += fuel;
        }
        
        // Calculate yearly total and percentages
        final yearlyTotal = yearlyTotalFood + yearlyTotalFuel;
        final foodPercentage = yearlyTotal > 0 ? (yearlyTotalFood / yearlyTotal * 100).round() : 0;
        final fuelPercentage = yearlyTotal > 0 ? (yearlyTotalFuel / yearlyTotal * 100).round() : 0;
        
        if (mounted) {
          setState(() {
            _monthlyEmissions = updatedEmissions;
            
            // Update yearly details data
            _yearlyCategories[0] = CarbonCategory(
              name: 'Food & Packaging Consumption',
              percentage: foodPercentage,
              value: yearlyTotalFood,
              color: const Color(0xFF7DA7C9),
            );
            
            _yearlyCategories[1] = CarbonCategory(
              name: 'Fuel Consumption',
              percentage: fuelPercentage,
              value: yearlyTotalFuel, 
              color: const Color(0xFFE6BC62),
            );
            
            _isLoading = false;
          });
        }
        
        print('Loaded yearly emissions for ${_selectedMonth.year}');
      }
    } catch (e) {
      print('Error loading yearly emissions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMonthlyEmissions();
    _loadYearlyEmissions();
    
    // Add listener to page controller to update the view state
    _pageController.addListener(_onPageChanged);
  }
  
  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }
  
  void _onPageChanged() {
    if (_pageController.page == 0 && !_isMonthlyView) {
      setState(() {
        _isMonthlyView = true;
      });
    } else if (_pageController.page == 1 && _isMonthlyView) {
      setState(() {
        _isMonthlyView = false;
      });
      // Load yearly data when switching to yearly view
      _loadYearlyEmissions();
    }
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userData = await _userService.getUserData(currentUser.uid);
        if (userData.exists) {
          setState(() {
            _username = userData['username'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      // Loading state will be managed by _loadMonthlyEmissions
      if (mounted && _isLoading && _totalMonthlyEmissions > 0) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Load monthly emissions data for the selected month
  Future<void> _loadMonthlyEmissions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Get start and end of the selected month
        final DateTime startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        final DateTime endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
        
        // Get entries from Firestore for the selected month
        final entriesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('consumption_entries')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .get();
        
        // Calculate emissions for each category
        int totalFoodEmissions = 0;
        int totalFuelEmissions = 0;
        
        for (var doc in entriesSnapshot.docs) {
          final data = doc.data();
          final category = data['category'] as String? ?? '';
          final emissions = (data['emissions'] as num?)?.toDouble() ?? 0.0;
          
          if (category == 'Food & Packaging Consumption') {
            totalFoodEmissions += emissions.toInt();
          } else if (category == 'Fuel Consumption') {
            totalFuelEmissions += emissions.toInt();
          }
        }
        
        // Calculate total and percentages
        final totalEmissions = totalFoodEmissions + totalFuelEmissions;
        final foodPercentage = totalEmissions > 0 ? (totalFoodEmissions / totalEmissions * 100).round() : 0;
        final fuelPercentage = totalEmissions > 0 ? (totalFuelEmissions / totalEmissions * 100).round() : 0;
        
        // Update state with new values
        if (mounted) {
          setState(() {
            _totalMonthlyEmissions = totalEmissions;
            
            // Update category values
            _categories[0] = CarbonCategory(
              name: 'Food & Packaging Consumption',
              percentage: foodPercentage,
              value: totalFoodEmissions,
              color: const Color(0xFF7DA7C9),
            );
            
            _categories[1] = CarbonCategory(
              name: 'Fuel Consumption',
              percentage: fuelPercentage,
              value: totalFuelEmissions,
              color: const Color(0xFFE6BC62),
            );
            
            _isLoading = false;
          });
        }
        
        print('Loaded monthly emissions for ${DateFormat('MMMM yyyy').format(_selectedMonth)}');
        print('Food: $totalFoodEmissions, Fuel: $totalFuelEmissions, Total: $totalEmissions');
      }
    } catch (e) {
      print('Error loading monthly emissions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Method to show month picker
  Future<void> _selectMonth() async {
    // Current selection to be modified
    int selectedYear = _selectedMonth.year;
    int selectedMonth = _selectedMonth.month;
    
    // Prepare year options (current year and 5 years back)
    final List<int> yearOptions = [];
    final int currentYear = DateTime.now().year;
    for (int i = 0; i <= 5; i++) {
      yearOptions.add(currentYear - i);
    }
    
    // Month names for dropdown
    final List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    // Show dialog with dropdown selectors
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFFE4FFAC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select Month',
                      style: TextStyle(
                        color: Color(0xFF5D6C24),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Year Dropdown
                    Row(
                      children: [
                        const Text(
                          'Year:',
                          style: TextStyle(
                            color: Color(0xFF5D6C24),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA4B465),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<int>(
                              value: selectedYear,
                              isExpanded: true,
                              dropdownColor: const Color(0xFFA4B465),
                              underline: Container(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              items: yearOptions.map((int year) {
                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedYear = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Month Dropdown
                    Row(
                      children: [
                        const Text(
                          'Month:',
                          style: TextStyle(
                            color: Color(0xFF5D6C24),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA4B465),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<int>(
                              value: selectedMonth,
                              isExpanded: true,
                              dropdownColor: const Color(0xFFA4B465),
                              underline: Container(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              items: List.generate(12, (index) {
                                return DropdownMenuItem<int>(
                                  value: index + 1,
                                  child: Text(monthNames[index]),
                                );
                              }),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedMonth = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Preview selected date
                    Text(
                      '${monthNames[selectedMonth - 1]} $selectedYear',
                      style: const TextStyle(
                        color: Color(0xFF5D6C24),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF5D6C24),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            final selectedDate = DateTime(selectedYear, selectedMonth, 1);
                            Navigator.pop(context, selectedDate);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D6C24),
                          ),
                          child: const Text(
                            'Select',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _selectedMonth = selectedDate;
        });
        _loadMonthlyEmissions();
      }
    });
  }

  // Add a method to select year (like month selector but only for years)
  Future<void> _selectYear() async {
    // Prepare year options (current year and 5 years back)
    final List<int> yearOptions = [];
    final int currentYear = DateTime.now().year;
    for (int i = 0; i <= 5; i++) {
      yearOptions.add(currentYear - i);
    }
    
    // Show dialog with year selector
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFFE4FFAC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Year',
                  style: TextStyle(
                    color: Color(0xFF5D6C24),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Year options as a grid
                Container(
                  constraints: BoxConstraints(
                    maxHeight: 300,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: yearOptions.length,
                    itemBuilder: (context, index) {
                      final year = yearOptions[index];
                      final isSelected = year == _selectedMonth.year;
                      
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context, year);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF5D6C24) : const Color(0xFFA4B465),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              year.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Cancel button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF5D6C24),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((selectedYear) {
      if (selectedYear != null) {
        setState(() {
          // Keep the same month but change the year
          _selectedMonth = DateTime(selectedYear, _selectedMonth.month, 1);
        });
        
        // Load data for the new year
        if (_isMonthlyView) {
          _loadMonthlyEmissions();
        } else {
          _loadYearlyEmissions();
        }
      }
    });
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
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
            : _buildHomeContent(),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Stack(
      children: [
        // Background leaves image - positioned higher
        Positioned(
          top: -150, // Moved up from -10
          left: 0,
          child: Image.asset(
            'assets/images/leaf1.png',
            width: 410,
            height: 510,
            fit: BoxFit.contain,
          ),
        ),
        
        // Main content
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // Welcome message in a container
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Welcome Back,\n$_username',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Date selector - aligned to the left and now clickable to select month
                GestureDetector(
                  onTap: _isMonthlyView ? _selectMonth : _selectYear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isMonthlyView ? _currentMonth : _currentYear,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Image.asset(
                          'assets/icons/downarroworange_icon.png',
                          width: 24,
                          height: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Carbon emissions title - centered
                Center(
                  child: Text(
                    _isMonthlyView ? 'Your Monthly Carbon Emissions' : 'Your Yearly Carbon Emissions',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Swipeable chart area
                SizedBox(
                  height: 280,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _isMonthlyView = index == 0;
                      });
                    },
                    children: [
                      // Monthly view - Donut chart
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildDonutChart(),
                            // Center text
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Your CO₂e',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _totalMonthlyEmissions.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Percentage texts inside the chart segments
                            if (_categories[1].percentage > 0)
                              Positioned(
                                left: 50,
                                bottom: 200,
                                child: Text(
                                  '${_categories[1].percentage}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            if (_categories[0].percentage > 0)
                              Positioned(
                                right: 50,
                                top: 200,
                                child: Text(
                                  '${_categories[0].percentage}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Yearly view - Bar chart
                      _buildYearlyBarChart(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Details section
                const Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Details container
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4FFAC),
                    borderRadius: BorderRadius.circular(12),
                    // Add shadow to details table
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Food & Packaging
                      _buildDetailItem(_isMonthlyView ? _categories[0] : _yearlyCategories[0]),
                      
                      // Divider with 28% opacity black - not from edge to edge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          height: 1,
                          color: const Color(0x47000000), // 28% opacity black
                        ),
                      ),
                      
                      // Fuel Consumption
                      _buildDetailItem(_isMonthlyView ? _categories[1] : _yearlyCategories[1]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom navigation bar - keeping position unchanged
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
                  
                  // HOME BUTTON (BROWN CONTAINER)
                  Container(
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

  Widget _buildDonutChart() {
    return SizedBox(
      width: 260,
      height: 260,
      child: CustomPaint(
        painter: DonutChartPainter(
          categories: _categories,
        ),
      ),
    );
  }
  
  Widget _buildYearlyBarChart() {
    // Find the maximum value for scaling
    final double maxValue = _monthlyEmissions.isEmpty 
        ? 10000.0 
        : _monthlyEmissions.map((e) => e.value).reduce(math.max).toDouble();
    
    // Set a minimum max value to avoid empty chart
    final double chartMaxValue = maxValue > 0 ? maxValue : 10000.0;
    
    // Calculate y-axis labels (dividing into 5 equal parts)
    final List<int> yAxisLabels = [
      (chartMaxValue).round(),
      (chartMaxValue * 0.75).round(),
      (chartMaxValue * 0.5).round(),
      (chartMaxValue * 0.25).round(),
      0,
    ];
    
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 20, 5),
      child: Column(
        children: [
          // CO2e title aligned with y-axis labels
          Padding(
            padding: const EdgeInsets.only(left: 45, bottom: 5, right: 10),
            child: Row(
              children: [
                const Text(
                  'CO2e',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Horizontal line next to CO2e label
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 5),
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          
          // Graph content (with axes and bars)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis with labels
                SizedBox(
                  width: 45,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ...yAxisLabels.map((label) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '$label',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                
                // Chart area with bars and connecting line
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double totalWidth = constraints.maxWidth;
                      final barWidth = (totalWidth / 15); // Even narrower bars
                      final spacing = (totalWidth - (barWidth * 12)) / 13; // Distribute remaining space
                      
                      return Stack(
                        children: [
                          // Horizontal grid lines
                          ...yAxisLabels.map((label) {
                            final y = constraints.maxHeight * (1 - (label / chartMaxValue));
                            return Positioned(
                              top: y,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            );
                          }),
                          
                          // Bars for each month
                          ...List.generate(12, (index) {
                            final emission = index < _monthlyEmissions.length
                                ? _monthlyEmissions[index]
                                : MonthlyEmission(month: '', value: 0);
                            
                            final barHeight = emission.value > 0
                                ? (emission.value / chartMaxValue) * constraints.maxHeight
                                : 0.0;
                            
                            final x = (index * (barWidth + spacing)) + spacing;
                            
                            return Positioned(
                              left: x,
                              bottom: 30, // Increased space for month labels
                              width: barWidth,
                              height: barHeight,
                              child: Column(
                                children: [
                                  // Value on top of the bar
                                  if (emission.value > 0)
                                    Text(
                                      '${emission.value}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  
                                  const SizedBox(height: 2),
                                  
                                  // Bar with circle on top
                                  Expanded(
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.topCenter,
                                      children: [
                                        // Bar
                                        Container(
                                          width: barWidth,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0BB78),
                                            borderRadius: BorderRadius.circular(barWidth / 2),
                                          ),
                                        ),
                                        
                                        // Circle on top
                                        Positioned(
                                          top: -5,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFF0BB78),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                          // Connect dots with a curved line
                          CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: ConnectionLinePainter(
                              months: _monthlyEmissions,
                              maxValue: chartMaxValue,
                              barWidth: barWidth,
                              spacing: spacing,
                            ),
                          ),
                          
                          // Month labels at the bottom
                          Positioned(
                            left: spacing / 2,
                            right: spacing / 2,
                            bottom: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(12, (index) {
                                final emission = index < _monthlyEmissions.length
                                    ? _monthlyEmissions[index]
                                    : MonthlyEmission(month: '', value: 0);
                                
                                final monthAbbr = emission.month.isNotEmpty 
                                    ? emission.month.substring(0, 3) // First 3 letters of month
                                    : '';
                                
                                // Buat width konstan untuk menghindari overflow
                                return Container(
                                  width: (totalWidth - spacing) / 13, // Ensure fixed width that fits
                                  child: Text(
                                    monthAbbr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.visible,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // "Month" label at the bottom
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'Month',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(CarbonCategory category) {
    return GestureDetector(
      onTap: () {
        if (category.name.contains('Food')) {
          Navigator.pushNamed(context, '/food_packaging_details');
        } else if (category.name.contains('Fuel')) {
          Navigator.pushNamed(context, '/fuel_consumption_details');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Category icon
            Image.asset(
              category.name.contains('Food') 
                  ? 'assets/images/foodandpackaging.png' 
                  : 'assets/images/fuelconsumption.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            
            // Category name and percentage
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Color(0xFF5D6C24),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Percentage
            Text(
              '${category.percentage}%',
              style: TextStyle(
                color: category.color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Value
            Text(
              category.value.toString(),
              style: const TextStyle(
                color: Color(0xFF5D6C24),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            // Arrow icon
            Image.asset(
              'assets/icons/rightarrow_button.png',
              width: 20,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for donut chart
class DonutChartPainter extends CustomPainter {
  final List<CarbonCategory> categories;

  DonutChartPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.6; // 60% of outer radius for donut hole
    
    double startAngle = -math.pi / 2; // Start from top (12 o'clock position)
    
    for (var category in categories) {
      final sweepAngle = 2 * math.pi * category.percentage / 100;
      
      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CarbonCategory {
  final String name;
  final int percentage;
  final int value;
  final Color color;

  CarbonCategory({
    required this.name,
    required this.percentage,
    required this.value,
    required this.color,
  });
}

// Class for monthly emissions data
class MonthlyEmission {
  final String month;
  final int value;
  final int foodValue;
  final int fuelValue;
  
  MonthlyEmission({
    required this.month,
    required this.value,
    this.foodValue = 0,
    this.fuelValue = 0,
  });
}

// Custom painter for the connecting curved line
class ConnectionLinePainter extends CustomPainter {
  final List<MonthlyEmission> months;
  final double maxValue;
  final double barWidth;
  final double spacing;
  
  ConnectionLinePainter({
    required this.months,
    required this.maxValue,
    required this.barWidth,
    required this.spacing,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;
    
    final paint = Paint()
      ..color = const Color(0xFF7DA7C9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    
    // Create points for the curved line
    List<Offset> points = [];
    
    for (int i = 0; i < math.min(months.length, 12); i++) {
      if (months[i].value <= 0) continue;
      
      // Ensure x position is within bounds
      final x = math.min((i * (barWidth + spacing)) + spacing + (barWidth / 2), size.width - 5);
      final y = size.height - (size.height * (months[i].value / maxValue)) - 30;
      
      points.add(Offset(x, y));
    }
    
    if (points.isEmpty) return;
    
    // Move to first point
    path.moveTo(points[0].dx, points[0].dy);
    
    // Create a smooth curve through the points
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      
      // Calculate control points for cubic curve
      final controlPoint1 = Offset(
        current.dx + (next.dx - current.dx) / 2,
        current.dy,
      );
      
      final controlPoint2 = Offset(
        current.dx + (next.dx - current.dx) / 2,
        next.dy,
      );
      
      // Add cubic curve to path
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        next.dx, next.dy,
      );
    }
    
    // Draw the path
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 