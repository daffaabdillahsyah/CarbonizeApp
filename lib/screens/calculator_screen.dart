import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/emission_service.dart';
import '../widgets/tips_dialog.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:convert';
import '../screens/edit_food_entry_screen.dart';
import '../screens/edit_fuel_consumption_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // Services
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  // Sample data
  String _currentDate = ''; // Will be set in initState
  int _totalEmissions = 0; // Changed from final to allow updates
  int _foodPackagingEmissions = 0; // Total emissions from Food & Packaging
  int _fuelEmissions = 0; // Total emissions from Fuel Consumption
  int _dailyLimit = 6; // Default value, will be updated from user profile
  double _progressPercentage = 0.0; // For the circular progress chart, changed from final to allow updates
  double _currentEmissions = 0.0; // For the circular progress chart, changed from final to allow updates
  bool _isLoading = true;
  
  // Selected date for viewing entries
  DateTime _viewDate = DateTime.now();
  
  // Category options for the dropdown
  final List<String> _categories = ['Fuel Consumption', 'Food & Packaging Consumption'];
  String? _selectedCategory;
  bool _isDropdownOpen = false;
  
  // Item types for Food & Packaging Consumption, sorted alphabetically
  final List<String> _foodItemTypes = [
    'Apples',
    'Cardboard Boxes',
    'Cocoa Fruit',
    'Fresh Fish',
    'Plastic Bags/Films',
    'Plastic Bottles',
    'Rice',
    'Tissue Paper',
  ];
  String? _selectedItemType;
  bool _isItemTypeDropdownOpen = false;
  
  // Transportation modes for Fuel Consumption
  final List<String> _transportationModes = [
    'Private Vehicle',
    'Public Transport',
  ];
  String? _selectedTransportationMode;
  bool _isTransportationModeDropdownOpen = false;
  
  // Vehicle types for Private Vehicle
  final List<String> _vehicleTypes = [
    'City Car',
    'Motorcycle',
    'Sedan / Medium Car',
    'SUV / MPV',
    'Diesel Car',
    'Hybrid Car',
  ];
  String? _selectedVehicleType;
  bool _isVehicleTypeDropdownOpen = false;
  
  // Public transport types
  final List<String> _publicTransportTypes = [
    'City Bus',
    'Intercity Bus',
    'Minibus / Angkot',
    'Online Motorcycle (Ojek)',
    'Online Taxi (Car)',
    'MRT',
  ];
  
  // Custom efficiency options
  final List<String> _customEfficiencyOptions = [
    'Yes',
    'No',
  ];
  String? _selectedCustomEfficiency;
  bool _isCustomEfficiencyDropdownOpen = false;
  bool _useCustomEfficiency = false;
  
  // Fuel type options
  final List<String> _fuelTypes = [
    'Pertalite',
    'Pertamax',
    'Pertamax Turbo',
    'Shell Super',
    'Shell V-Power',
    'Shell V-Power Nitro+',
    'Solar / Bio Solar',
    'Dexlite',
    'Pertamina Dex',
    'Shell V-Power Diesel',
  ];
  String? _selectedFuelType;
  bool _isFuelTypeDropdownOpen = false;
  
  // Keys for dropdown positioning
  final GlobalKey _categoryDropdownKey = GlobalKey();
  final GlobalKey _itemTypeDropdownKey = GlobalKey();
  final GlobalKey _transportationModeDropdownKey = GlobalKey();
  final GlobalKey _vehicleTypeDropdownKey = GlobalKey();
  final GlobalKey _customEfficiencyDropdownKey = GlobalKey();
  final GlobalKey _fuelTypeDropdownKey = GlobalKey();
  
  // Layer links for fixed positioning
  final LayerLink _categoryLayerLink = LayerLink();
  final LayerLink _itemTypeLayerLink = LayerLink();
  final LayerLink _transportationModeLayerLink = LayerLink();
  final LayerLink _vehicleTypeLayerLink = LayerLink();
  final LayerLink _customEfficiencyLayerLink = LayerLink();
  final LayerLink _fuelTypeLayerLink = LayerLink();
  
  // Overlay entry for dropdowns
  OverlayEntry? _overlayEntry;
  
  // Text controller for quantity input
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _efficiencyController = TextEditingController();
  
  // Selected date
  DateTime _selectedDate = DateTime.now();
  
  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  
  // List to store consumption entries
  List<ConsumptionEntry> _consumptionEntries = [];
  
  // Page controller for swiping between monthly and yearly views
  final PageController _pageController = PageController();
  bool _isMonthlyView = true;
  
  // Current date for display
  final String _currentMonth = 'MAY, 2025';
  final String _currentYear = '2025';
  
  // Sample data for carbon emissions
  final int _totalCO2 = 80000;

  // Controller for the form scrolling
  final ScrollController _formScrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _viewDate = DateTime.now(); // Initialize with today's date
    _currentDate = _formatDate(_viewDate); // Format the date for display
    _loadUserData();
    _loadConsumptionEntries();
    
    // Add listener to page controller to update the view state
    _pageController.addListener(_onPageChanged);
  }
  
  @override
  void dispose() {
    _removeDropdownOverlay();
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _formScrollController.dispose();
    _quantityController.dispose();
    _distanceController.dispose();
    _efficiencyController.dispose();
    super.dispose();
  }
  
  void _removeDropdownOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
          setState(() {
            // Get the user's custom daily carbon limit or use default (6) if not set
            _dailyLimit = userData['dailyCarbonLimit'] ?? 6;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Load consumption entries for the selected date
  Future<void> _loadConsumptionEntries() async {
    try {
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        setState(() {
          _isLoading = true;
        });
        
        // Get start and end of the selected day
        final DateTime startOfDay = DateTime(_viewDate.year, _viewDate.month, _viewDate.day);
        final DateTime endOfDay = DateTime(_viewDate.year, _viewDate.month, _viewDate.day, 23, 59, 59);
        
        // Get entries from Firestore for the selected date
        final entriesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('consumption_entries')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .orderBy('date', descending: true)
            .get();
        
        // Convert to ConsumptionEntry objects
        final entries = entriesSnapshot.docs.map((doc) {
          final data = doc.data();
          
          // Convert Firestore Timestamp to DateTime
          DateTime date;
          if (data['date'] is Timestamp) {
            date = (data['date'] as Timestamp).toDate();
          } else {
            // Handle the case where date might be stored differently
            date = DateTime.now();
          }
          
          // Handle image - could be URL or Base64
          String? imageUrl = data['imageUrl'] as String?;
          File? imageFile;
          
          // If we have Base64 image data, convert it to a File
          if (data['imageBase64'] != null) {
            try {
              final String base64Image = data['imageBase64'] as String;
              final bytes = base64Decode(base64Image);
              
              // Create a temporary file
              final tempDir = Directory.systemTemp;
              final tempPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
              final tempFile = File(tempPath);
              
              // Write bytes to file
              tempFile.writeAsBytesSync(bytes);
              imageFile = tempFile;
              
              print('Created image file from Base64: $tempPath');
            } catch (e) {
              print('Error converting Base64 to File: $e');
            }
          }
          
          return ConsumptionEntry(
            category: data['category'] ?? '',
            itemType: data['itemType'] ?? '',
            quantity: (data['quantity'] ?? 0).toDouble(),
            date: date,
            emissions: (data['emissions'] ?? 0).toDouble(),
            imageUrl: imageUrl,
            image: imageFile,
            metadata: data['metadata'] as Map<String, dynamic>? ?? {},
          );
        }).toList();
        
        // Update state
        if (mounted) {
          setState(() {
            _consumptionEntries = entries;
            _isLoading = false;
          });
          
          // Calculate emissions after loading entries
          _calculateEmissions();
        }
        
        print('Loaded ${entries.length} consumption entries for ${_formatDate(_viewDate)}');
      }
    } catch (e) {
      print('Error loading consumption entries: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Show category dropdown overlay
  void _toggleCategoryDropdown(BuildContext context, StateSetter setDialogState) {
    if (_isDropdownOpen) {
      _removeDropdownOverlay();
      setDialogState(() {
        _isDropdownOpen = false;
      });
      return;
    }
    
    // Close all other dropdowns first
    _closeAllDropdowns(setDialogState);
    
    // Get the RenderBox after the widget is built
    final RenderBox renderBox = _categoryDropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    // Create overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _categoryLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFA4B465),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                maxHeight: 200, // Limit height to 4 items (50 height per item)
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _categories.map((String value) {
                    bool isLast = _categories.indexOf(value) == _categories.length - 1;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          _selectedCategory = value;
                          _selectedItemType = null;
                        });
                        _removeDropdownOverlay();
                        setDialogState(() {
                          _isDropdownOpen = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          border: !isLast ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ) : null,
                          borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(8)) : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    // Insert overlay
    Overlay.of(context).insert(_overlayEntry!);
    setDialogState(() {
      _isDropdownOpen = true;
    });
  }
  
  // Show item type dropdown overlay
  void _toggleItemTypeDropdown(BuildContext context, StateSetter setDialogState) {
    if (_isItemTypeDropdownOpen) {
      _removeDropdownOverlay();
      setDialogState(() {
        _isItemTypeDropdownOpen = false;
      });
      return;
    }
    
    // Close all other dropdowns first
    _closeAllDropdowns(setDialogState);
    
    // Get the RenderBox after the widget is built
    final RenderBox renderBox = _itemTypeDropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    // Create overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _itemTypeLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFA4B465),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                maxHeight: 200, // Limit height to 4 items (50 height per item)
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _foodItemTypes.map((String value) {
                    bool isLast = _foodItemTypes.indexOf(value) == _foodItemTypes.length - 1;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          _selectedItemType = value;
                        });
                        _removeDropdownOverlay();
                        setDialogState(() {
                          _isItemTypeDropdownOpen = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          border: !isLast ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ) : null,
                          borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(8)) : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    // Insert overlay
    Overlay.of(context).insert(_overlayEntry!);
    setDialogState(() {
      _isItemTypeDropdownOpen = true;
    });
  }
  
  // Show transportation mode dropdown overlay
  void _toggleTransportationModeDropdown(BuildContext context, StateSetter setDialogState) {
    if (_isTransportationModeDropdownOpen) {
      _removeDropdownOverlay();
      setDialogState(() {
        _isTransportationModeDropdownOpen = false;
      });
      return;
    }
    
    // Close all other dropdowns first
    _closeAllDropdowns(setDialogState);
    
    // Get the RenderBox after the widget is built
    final RenderBox renderBox = _transportationModeDropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    // Create overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _transportationModeLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFA4B465),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                maxHeight: 200, // Limit height to 4 items (50 height per item)
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _transportationModes.map((String value) {
                    bool isLast = _transportationModes.indexOf(value) == _transportationModes.length - 1;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          _selectedTransportationMode = value;
                        });
                        _removeDropdownOverlay();
                        setDialogState(() {
                          _isTransportationModeDropdownOpen = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          border: !isLast ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ) : null,
                          borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(8)) : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    // Insert overlay
    Overlay.of(context).insert(_overlayEntry!);
    setDialogState(() {
      _isTransportationModeDropdownOpen = true;
    });
  }
  
  // Show vehicle type dropdown overlay
  void _toggleVehicleTypeDropdown(BuildContext context, StateSetter setDialogState) {
    if (_isVehicleTypeDropdownOpen) {
      _removeDropdownOverlay();
      setDialogState(() {
        _isVehicleTypeDropdownOpen = false;
      });
      return;
    }
    
    // Close all other dropdowns first
    _closeAllDropdowns(setDialogState);
    
    // Get the RenderBox after the widget is built
    final RenderBox renderBox = _vehicleTypeDropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    // Create overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _vehicleTypeLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFA4B465),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                maxHeight: 200, // Limit height to 4 items (50 height per item)
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: (_selectedTransportationMode == 'Public Transport' 
                      ? _publicTransportTypes 
                      : _vehicleTypes).map((String value) {
                    bool isLast = (_selectedTransportationMode == 'Public Transport' 
                        ? _publicTransportTypes 
                        : _vehicleTypes).indexOf(value) == (_selectedTransportationMode == 'Public Transport' 
                            ? _publicTransportTypes 
                            : _vehicleTypes).length - 1;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          _selectedVehicleType = value;
                        });
                        _removeDropdownOverlay();
                        setDialogState(() {
                          _isVehicleTypeDropdownOpen = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          border: !isLast ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ) : null,
                          borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(8)) : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    // Insert overlay
    Overlay.of(context).insert(_overlayEntry!);
    setDialogState(() {
      _isVehicleTypeDropdownOpen = true;
    });
  }
  
  // Toggle custom efficiency dropdown
  void _toggleCustomEfficiencyDropdown(BuildContext context, StateSetter setDialogState) {
    if (_isCustomEfficiencyDropdownOpen) {
      _removeDropdownOverlay();
      setDialogState(() {
        _isCustomEfficiencyDropdownOpen = false;
      });
      return;
    }
    
    // Close all other dropdowns first
    _closeAllDropdowns(setDialogState);
    
    // Get the RenderBox after the widget is built
    final RenderBox renderBox = _customEfficiencyDropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    // Create overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _customEfficiencyLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFA4B465),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                maxHeight: 200, // Limit height to 4 items (50 height per item)
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _customEfficiencyOptions.map((String value) {
                    bool isLast = _customEfficiencyOptions.indexOf(value) == _customEfficiencyOptions.length - 1;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          _selectedCustomEfficiency = value;
                          _useCustomEfficiency = value == 'Yes';
                          _isCustomEfficiencyDropdownOpen = false;
                        });
                        _removeDropdownOverlay();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          border: !isLast ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ) : null,
                          borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(8)) : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    // Insert overlay
    Overlay.of(context).insert(_overlayEntry!);
    setDialogState(() {
      _isCustomEfficiencyDropdownOpen = true;
    });
  }
  
  // Show fuel type dropdown overlay
  void _toggleFuelTypeDropdown(BuildContext context, StateSetter setDialogState) {
    if (_isFuelTypeDropdownOpen) {
      _removeDropdownOverlay();
      setDialogState(() {
        _isFuelTypeDropdownOpen = false;
      });
      return;
    }
    
    // Close all other dropdowns first
    _closeAllDropdowns(setDialogState);
    
    // Get the RenderBox after the widget is built
    final RenderBox renderBox = _fuelTypeDropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    // Create overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _fuelTypeLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFA4B465),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                maxHeight: 200, // Limit height to 4 items (50 height per item)
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _fuelTypes.map((String value) {
                    bool isLast = _fuelTypes.indexOf(value) == _fuelTypes.length - 1;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          _selectedFuelType = value;
                        });
                        _removeDropdownOverlay();
                        setDialogState(() {
                          _isFuelTypeDropdownOpen = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          border: !isLast ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ) : null,
                          borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(8)) : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    // Insert overlay
    Overlay.of(context).insert(_overlayEntry!);
    setDialogState(() {
      _isFuelTypeDropdownOpen = true;
    });
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
              : _buildCalculatorContent(),
        ),
      ),
    );
  }

  // Show circular progress chart dialog
  void _showProgressChartDialog() {
    // Use a separate date for the dialog to avoid affecting the main screen's date
    DateTime _dialogDate = _viewDate;
    String _dialogDateStr = _formatDate(_dialogDate);
    double _dialogProgressPercentage = _progressPercentage;
    double _dialogCurrentEmissions = _currentEmissions;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Function to load data for the selected date in dialog
            Future<void> _loadDialogDateData() async {
              try {
                User? currentUser = _authService.currentUser;
                if (currentUser != null) {
                  // Get start and end of the selected day
                  final DateTime startOfDay = DateTime(_dialogDate.year, _dialogDate.month, _dialogDate.day);
                  final DateTime endOfDay = DateTime(_dialogDate.year, _dialogDate.month, _dialogDate.day, 23, 59, 59);
                  
                  // Get entries from Firestore for the selected date
                  final entriesSnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .collection('consumption_entries')
                      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                      .get();
                  
                  // Calculate emissions for the dialog date
                  double totalFoodEmissions = 0;
                  double totalFuelEmissions = 0;
                  
                  for (var doc in entriesSnapshot.docs) {
                    final data = doc.data();
                    final emissions = (data['emissions'] ?? 0).toDouble();
                    final category = data['category'] ?? '';
                    
                    if (category == 'Food & Packaging Consumption') {
                      totalFoodEmissions += emissions;
                    } else if (category == 'Fuel Consumption') {
                      totalFuelEmissions += emissions;
                    }
                  }
                  
                  double totalEmissions = totalFoodEmissions + totalFuelEmissions;
                  double progressPercentage = _dailyLimit > 0 
                      ? (totalEmissions / _dailyLimit * 100).clamp(0, 100) 
                      : 0;
                  
                  setState(() {
                    _dialogProgressPercentage = progressPercentage;
                    _dialogCurrentEmissions = totalEmissions;
                    _dialogDateStr = _formatDate(_dialogDate);
                  });
                }
              } catch (e) {
                print('Error loading dialog date data: $e');
              }
            }
            
            // Function to go to previous day
            void _goToPreviousDialogDay() {
              setState(() {
                _dialogDate = _dialogDate.subtract(const Duration(days: 1));
              });
              _loadDialogDateData();
            }
            
            // Function to go to next day
            void _goToNextDialogDay() {
              setState(() {
                _dialogDate = _dialogDate.add(const Duration(days: 1));
              });
              _loadDialogDateData();
            }
            
            // Function to select a specific date
            Future<void> _selectDialogDate() async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _dialogDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF5D6C24),
                        onPrimary: Colors.white,
                        surface: Color(0xFFE4FFAC),
                        onSurface: Color(0xFF5D6C24),
                      ),
                      dialogBackgroundColor: const Color(0xFFE4FFAC),
                    ),
                    child: child!,
                  );
                },
              );
              
              if (picked != null && picked != _dialogDate) {
                setState(() {
                  _dialogDate = picked;
                });
                _loadDialogDateData();
              }
            }
            
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFFE4FFAC),
                child: Column(
                  children: [
                    // Header section with title and date navigation with background color #EFEFEF
                    Container(
                      color: const Color(0xFFEFEFEF),
                      child: Column(
                        children: [
                          // Header with close button and title
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(
                                    Icons.close,
                                    color: Color(0xFF626F47),
                                    size: 24,
                                  ),
                                ),
                                const Expanded(
                                  child: Center(
                                    child: Text(
                                      'Daily Carbon Footprint',
                                      style: TextStyle(
                                        color: Color(0xFF626F47),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24), // Balance for close icon
                              ],
                            ),
                          ),
                          
                          // Date navigation
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _goToPreviousDialogDay,
                                  child: Image.asset(
                                    'assets/icons/previous1_button.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _selectDialogDate,
                                  child: Row(
                                    children: [
                                      Text(
                                        _dialogDateStr,
                                        style: const TextStyle(
                                          color: Color(0xFF626F47),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Image.asset(
                                        'assets/icons/dropdownbutton1_icon.png',
                                        width: 35,
                                        height: 35,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _goToNextDialogDay,
                                  child: Image.asset(
                                    'assets/icons/next1_button.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Circular progress chart
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Donut chart
                                  CustomPaint(
                                    size: const Size(200, 200),
                                    painter: DonutChartPainter(
                                      percentage: _dialogProgressPercentage,
                                      backgroundColor: const Color(0xFFB9C982),
                                      progressColor: const Color(0xFFDCE4C0),
                                    ),
                                  ),
                                  
                                  // Percentage text in center
                                  Text(
                                    '${_dialogProgressPercentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: Color(0xCCE259A4), // E259A4 with 80% opacity
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Emissions text
                            Text(
                              '$_dialogCurrentEmissions / $_dailyLimit kg CO2e',
                              style: const TextStyle(
                                color: Color(0xFF626F47),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
  
  // Show add calculation dialog
  void _showAddCalculationDialog() {
    // Reset selection
    _selectedCategory = null;
    _isDropdownOpen = false;
    _selectedItemType = null;
    _isItemTypeDropdownOpen = false;
    _selectedTransportationMode = null;
    _isTransportationModeDropdownOpen = false;
    _selectedVehicleType = null;
    _isVehicleTypeDropdownOpen = false;
    _selectedCustomEfficiency = null;
    _isCustomEfficiencyDropdownOpen = false;
    _selectedFuelType = null;
    _isFuelTypeDropdownOpen = false;
    _quantityController.text = '';
    _distanceController.text = '';
    _efficiencyController.text = '';
    _selectedDate = DateTime.now();
    _selectedImage = null;
    
    // Flag to prevent double submission
    bool isSubmitting = false;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Local loading state for the dialog
            bool isCalculating = false;
            
            // Local debounce function
            void debounceCalculateButton() {
              setDialogState(() {
                isSubmitting = true;
              });
              
              // Auto-reset after 2 seconds (safety mechanism)
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setDialogState(() {
                    isSubmitting = false;
                  });
                }
              });
            }
            
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFE4FFAC),
                child: Stack(
                  children: [
                    // Main content
                    Column(
              children: [
                // Header with close button and title with background color #EFEFEF
                Container(
                  color: const Color(0xFFEFEFEF),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                                onTap: () {
                                  _removeDropdownOverlay();
                                  Navigator.pop(context);
                                },
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF626F47),
                          size: 24,
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Daily Carbon Footprint',
                            style: TextStyle(
                              color: Color(0xFF626F47),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24), // Balance for close icon
                    ],
                  ),
                ),
                
                // Add calculation form
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (scrollNotification) {
                              if (scrollNotification is ScrollUpdateNotification) {
                                // Close any open dropdowns when scrolling
                                _closeAllDropdowns(setDialogState);
                              }
                              return true;
                            },
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                              child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category selection label
                          const Text(
                            'Select Category',
                            style: TextStyle(
                              color: Color(0xFF5D6C24),
                              fontSize: 16,
                              fontWeight: FontWeight.w600, // Semi-bold font
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                                  // Category dropdown header
                              GestureDetector(
                                    key: _categoryDropdownKey,
                                    onTap: () => _toggleCategoryDropdown(context, setDialogState),
                                child: CompositedTransformTarget(
                                  link: _categoryLayerLink,
                                  child: Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA4B465),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                            color: Colors.black.withOpacity(0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedCategory ?? 'Choose',
                                        style: TextStyle(
                                          color: _selectedCategory == null ? Colors.white70 : Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Image.asset(
                                        _isDropdownOpen 
                                            ? 'assets/icons/dropdownbutton2back_icon.png' 
                                            : 'assets/icons/dropdownbutton2_icon.png',
                                        width: 20,
                                        height: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                ),
                          ),
                          
                          // Additional form fields based on selected category
                          if (_selectedCategory == 'Food & Packaging Consumption') ...[
                            const SizedBox(height: 20),
                            
                            // Item Type field
                            const Text(
                              'Item Type',
                              style: TextStyle(
                                color: Color(0xFF5D6C24),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                                    // Item Type dropdown header
                                    GestureDetector(
                                      key: _itemTypeDropdownKey,
                                      onTap: () => _toggleItemTypeDropdown(context, setDialogState),
                                      child: CompositedTransformTarget(
                                        link: _itemTypeLayerLink,
                                        child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4B465),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                            Text(
                                              _selectedItemType ?? 'Choose',
                                    style: TextStyle(
                                                color: _selectedItemType == null ? Colors.white70 : Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Image.asset(
                                              _isItemTypeDropdownOpen 
                                                  ? 'assets/icons/dropdownbutton2back_icon.png' 
                                                  : 'assets/icons/dropdownbutton2_icon.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                ],
                              ),
                            ),
                                      ),
                                    ),
                            
                            const SizedBox(height: 20),
                            
                            // Quantity used field
                            Row(
                              children: [
                                const Text(
                                  'Quantity used',
                                  style: TextStyle(
                                    color: Color(0xFF5D6C24),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5D6C24),
                                    shape: BoxShape.circle,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: const Color(0xFFE4FFAC),
                                            title: const Text(
                                              'Quantity Information',
                                              style: TextStyle(
                                                color: Color(0xFF5D6C24),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: const Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Enter the quantity in kilograms (kg):',
                                                  style: TextStyle(
                                                    color: Color(0xFF5D6C24),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                Text(
                                                  '• For food items: weight in kg',
                                                  style: TextStyle(color: Color(0xFF5D6C24)),
                                                ),
                                                SizedBox(height: 5),
                                                Text(
                                                  '• For packaging: weight in kg',
                                                  style: TextStyle(color: Color(0xFF5D6C24)),
                                                ),
                                                SizedBox(height: 10),
                                                Text(
                                                  'Examples:',
                                                  style: TextStyle(
                                                    color: Color(0xFF5D6C24),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                                Text(
                                                  '• 1 apple ≈ 0.2 kg',
                                                  style: TextStyle(color: Color(0xFF5D6C24)),
                                                ),
                                                Text(
                                                  '• 1 plastic bottle ≈ 0.025 kg',
                                                  style: TextStyle(color: Color(0xFF5D6C24)),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text(
                                                  'Got it',
                                                  style: TextStyle(
                                                    color: Color(0xFF5D6C24),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                                    // Quantity input field - now a TextField for numeric input
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4B465),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: TextField(
                                        controller: _quantityController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Enter quantity',
                                          hintStyle: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Date of Activity field
                            const Text(
                              'Date of Activity',
                              style: TextStyle(
                                color: Color(0xFF5D6C24),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                                    // Date picker field - now shows selected date and can be tapped to change
                                    GestureDetector(
                                      onTap: () => _selectDate(context, setDialogState),
                                      child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4B465),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                            Text(
                                              _formatDate(_selectedDate),
                                              style: const TextStyle(
                                                color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Image.asset(
                                    'assets/icons/dropdownbutton2_icon.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                ],
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Documentation field
                                    const Text(
                                      'Documentation',
                                      style: TextStyle(
                                        color: Color(0xFF5D6C24),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Image upload area
                                    Center(
                                      child: GestureDetector(
                                        onTap: () => _pickImage(setDialogState),
                                        child: Container(
                                          width: 250,
                                          height: 250,
                                          decoration: BoxDecoration(
                                            color: const Color(0x66D9D9D9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: DottedBorder(
                                            color: Colors.black,
                                            strokeWidth: 2,
                                            dashPattern: const [6, 6],
                                            borderType: BorderType.RRect,
                                            radius: const Radius.circular(8),
                                            padding: const EdgeInsets.all(0),
                                            child: _selectedImage != null
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.file(
                                                      _selectedImage!,
                                                      width: 250,
                                                      height: 250,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Image.asset(
                                                          'assets/icons/image_icon.png',
                                                          width: 40,
                                                          height: 40,
                                                        ),
                                                        const SizedBox(height: 8),
                                                        const Text(
                                                          'Upload a file or take a photo',
                                                          style: TextStyle(
                                                            color: Color(0xFFA4B465),
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 30),
                                    
                                    // Calculate button
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: (isCalculating || isSubmitting) ? null : () async {
                                          // Activate debounce to prevent multiple clicks
                                          debounceCalculateButton();
                                          
                                          // Validate inputs
                                          if (_selectedItemType != null && _quantityController.text.isNotEmpty && _selectedImage != null) {
                                            try {
                                              // Show loading indicator and disable button
                                              setDialogState(() {
                                                isCalculating = true;
                                              });
                                              
                                              // Parse quantity
                                              final quantity = double.tryParse(_quantityController.text) ?? 0;
                                              
                                              // Calculate emissions using the Climatiq API
                                              final emissions = await EmissionService.calculateFoodEmissions(
                                                _selectedItemType!,
                                                quantity
                                              );
                                              
                                              // Create new entry with calculated emissions
                                              final entry = ConsumptionEntry(
                                                category: 'Food & Packaging Consumption',
                                                itemType: _selectedItemType!,
                                                quantity: quantity,
                                                date: _selectedDate,
                                                image: _selectedImage,
                                                emissions: emissions,
                                                imageUrl: null,
                                                metadata: {},
                                              );
                                              
                                              // Check if dialog is still mounted before proceeding
                                              if (!mounted) return;
                                              
                                              // Only add to local list if the entry date matches the current view date
                                              final bool isSameDay = 
                                                  _selectedDate.year == _viewDate.year && 
                                                  _selectedDate.month == _viewDate.month && 
                                                  _selectedDate.day == _viewDate.day;
                                              
                                              if (isSameDay) {
                                                setState(() {
                                                  _consumptionEntries.add(entry);
                                                });
                                                
                                                // Recalculate emissions after adding new entry
                                                _calculateEmissions();
                                              } else {
                                                // If entry is for a different date, notify user and offer to navigate
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text('Entry saved for ${_formatDate(_selectedDate)}'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(context); // Close dialog
                                                            _navigateToDate(_selectedDate); // Navigate to entry date
                                                          },
                                                          child: const Text(
                                                            'GO TO DATE',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor: Colors.green,
                                                    duration: const Duration(seconds: 5),
                                                  ),
                                                );
                                              }
                                              
                                              // Save to Firebase
                                              try {
                                                User? currentUser = _authService.currentUser;
                                                if (currentUser != null) {
                                                  // Print image info for debugging
                                                  if (_selectedImage != null) {
                                                    print('Image path: ${_selectedImage!.path}');
                                                    print('Image exists: ${_selectedImage!.existsSync()}');
                                                    print('Image size: ${await _selectedImage!.length()} bytes');
                                                  }
                                                  
                                                  // Prepare data for Firestore
                                                  final entryData = {
                                                    'category': entry.category,
                                                    'itemType': entry.itemType,
                                                    'quantity': entry.quantity,
                                                    'date': Timestamp.fromDate(entry.date),
                                                    'emissions': entry.emissions,
                                                    'metadata': entry.metadata,
                                                  };
                                                  
                                                  // Save to Firestore
                                                  await _userService.saveConsumptionEntry(
                                                    currentUser.uid, 
                                                    entryData, 
                                                    entry.image
                                                  );
                                                  
                                                  print('Entry saved to Firebase');
                                                }
                                              } catch (e) {
                                                print('Error saving to Firebase: $e');
                                                // Show error message but don't block the UI
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Entry saved locally but failed to sync: $e'),
                                                      backgroundColor: Colors.orange,
                                                    ),
                                                  );
                                                }
                                              }
                                              
                                              // Close dialog
                                              if (mounted) {
                                                Navigator.pop(context);
                                              }
                                            } catch (e) {
                                              // Hide loading indicator
                                              if (mounted) {
                                                setDialogState(() {
                                                  isCalculating = false;
                                                });
                                                
                                                // Show error message
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error calculating emissions: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          } else {
                                            // Show error message with specific validation failures
                                            String errorMessage = 'Please fill in all required fields';
                                            if (_selectedItemType == null) {
                                              errorMessage = 'Please select an item type';
                                            } else if (_quantityController.text.isEmpty) {
                                              errorMessage = 'Please enter a quantity';
                                            } else if (_selectedImage == null) {
                                              errorMessage = 'Documentation image is required';
                                            }
                                            
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(errorMessage),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF626F47),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          elevation: 4,
                                        ),
                                        child: isCalculating 
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Calculate',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                              ),
                            ),
                          ] else if (_selectedCategory == 'Fuel Consumption') ...[
                            const SizedBox(height: 20),
                            
                                    // Transportation Mode field
                            const Text(
                                      'Transportation Mode',
                              style: TextStyle(
                                color: Color(0xFF5D6C24),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                                    // Transportation Mode dropdown
                                    GestureDetector(
                                      key: _transportationModeDropdownKey,
                                      onTap: () => _toggleTransportationModeDropdown(context, setDialogState),
                                      child: CompositedTransformTarget(
                                        link: _transportationModeLayerLink,
                                        child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4B465),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                            Text(
                                              _selectedTransportationMode ?? 'Choose',
                                    style: TextStyle(
                                                color: _selectedTransportationMode == null ? Colors.white70 : Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Image.asset(
                                              _isTransportationModeDropdownOpen
                                                  ? 'assets/icons/dropdownbutton2back_icon.png'
                                                  : 'assets/icons/dropdownbutton2_icon.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                ],
                              ),
                            ),
                                      ),
                                    ),
                            
                                    // Only show additional fields if transportation mode is selected
                                    if (_selectedTransportationMode == 'Private Vehicle') ...[
                                      const SizedBox(height: 20),
                                      
                                      // Vehicle Type field
                                      const Text(
                                        'Select Vehicle Type',
                                        style: TextStyle(
                                          color: Color(0xFF5D6C24),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Vehicle Type dropdown
                                      GestureDetector(
                                        key: _vehicleTypeDropdownKey,
                                        onTap: () => _toggleVehicleTypeDropdown(context, setDialogState),
                                        child: CompositedTransformTarget(
                                          link: _vehicleTypeLayerLink,
                                          child: Container(
                                          width: double.infinity,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFA4B465),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.25),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _selectedVehicleType ?? 'Choose',
                                                style: TextStyle(
                                                  color: _selectedVehicleType == null ? Colors.white70 : Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Image.asset(
                                                _isVehicleTypeDropdownOpen
                                                    ? 'assets/icons/dropdownbutton2back_icon.png'
                                                    : 'assets/icons/dropdownbutton2_icon.png',
                                                width: 20,
                                                height: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                        ),
                                      ),
                                    ] else if (_selectedTransportationMode == 'Public Transport') ...[
                                      const SizedBox(height: 20),
                                      
                                      // Vehicle Type field for Public Transport
                                      const Text(
                                        'Select Vehicle Type',
                                        style: TextStyle(
                                          color: Color(0xFF5D6C24),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Vehicle Type dropdown for Public Transport
                                      GestureDetector(
                                        key: _vehicleTypeDropdownKey,
                                        onTap: () => _toggleVehicleTypeDropdown(context, setDialogState),
                                        child: CompositedTransformTarget(
                                          link: _vehicleTypeLayerLink,
                                          child: Container(
                                          width: double.infinity,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFA4B465),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.25),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _selectedVehicleType ?? 'Choose',
                                                style: TextStyle(
                                                  color: _selectedVehicleType == null ? Colors.white70 : Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Image.asset(
                                                _isVehicleTypeDropdownOpen
                                                    ? 'assets/icons/dropdownbutton2back_icon.png'
                                                    : 'assets/icons/dropdownbutton2_icon.png',
                                                width: 20,
                                                height: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                        ),
                                      ),
                                    ],
                            
                                    // Distance field - show for both Private Vehicle and Public Transport
                                    if (_selectedTransportationMode != null) ...[
                            const SizedBox(height: 20),
                            
                            // Distance field
                            const Text(
                              'Distance Traveled (km)',
                              style: TextStyle(
                                color: Color(0xFF5D6C24),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                                      // Distance input field - now a TextField for numeric input
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4B465),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        child: TextField(
                                          controller: _distanceController,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Enter distance',
                                            hintStyle: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                                ),
                              ),
                            ),
                            
                            // Only show Custom Efficiency and Fuel Type for Private Vehicle
                            if (_selectedTransportationMode == 'Private Vehicle') ...[
                              const SizedBox(height: 20),
                              
                              // Custom Efficiency field
                              Row(
                                children: [
                                  const Text(
                                    'Use Custom Efficiency?',
                                    style: TextStyle(
                                      color: Color(0xFF5D6C24),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF5D6C24),
                                      shape: BoxShape.circle,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              backgroundColor: const Color(0xFFE4FFAC),
                                              title: const Text(
                                                'Custom Efficiency',
                                                style: TextStyle(
                                                  color: Color(0xFF5D6C24),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: const [
                                                  Text(
                                                    'Custom Efficiency allows you to input your vehicle\'s specific fuel consumption rate instead of using default values.',
                                                    style: TextStyle(fontSize: 14, color: Color(0xFF5D6C24)),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text(
                                                    'How to use:',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF5D6C24)),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    '1. Select "Yes" to enable custom efficiency',
                                                    style: TextStyle(fontSize: 14, color: Color(0xFF5D6C24)),
                                                  ),
                                                  Text(
                                                    '2. Enter your vehicle\'s fuel efficiency in km/l',
                                                    style: TextStyle(fontSize: 14, color: Color(0xFF5D6C24)),
                                                  ),
                                                  Text(
                                                    '3. Select your fuel type',
                                                    style: TextStyle(fontSize: 14, color: Color(0xFF5D6C24)),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text(
                                                    'This will provide a more accurate carbon footprint calculation based on your specific vehicle.',
                                                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF5D6C24)),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text(
                                                    'Got it',
                                                    style: TextStyle(
                                                      color: Color(0xFF5D6C24),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: const Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Custom Efficiency dropdown
                              GestureDetector(
                                key: _customEfficiencyDropdownKey,
                                onTap: () => _toggleCustomEfficiencyDropdown(context, setDialogState),
                                child: CompositedTransformTarget(
                                  link: _customEfficiencyLayerLink,
                                  child: Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA4B465),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedCustomEfficiency ?? 'Choose',
                                        style: TextStyle(
                                          color: _selectedCustomEfficiency == null ? Colors.white70 : Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Image.asset(
                                        _isCustomEfficiencyDropdownOpen
                                            ? 'assets/icons/dropdownbutton2back_icon.png'
                                            : 'assets/icons/dropdownbutton2_icon.png',
                                        width: 20,
                                        height: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                ),
                              ),
                              
                              // Show Custom Fuel Efficiency field if Yes is selected
                              if (_selectedCustomEfficiency == 'Yes') ...[
                                const SizedBox(height: 20),
                                
                                // Custom Fuel Efficiency field
                                const Text(
                                  'Custom Fuel Efficiency (km/l)',
                                  style: TextStyle(
                                    color: Color(0xFF5D6C24),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Custom Fuel Efficiency input field
                                Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA4B465),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: TextField(
                                    controller: _efficiencyController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Type',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                                    ),
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 20),
                              
                              // Fuel Type field
                              const Text(
                                'Fuel Type',
                                style: TextStyle(
                                  color: Color(0xFF5D6C24),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Fuel Type dropdown
                              GestureDetector(
                                key: _fuelTypeDropdownKey,
                                onTap: () => _toggleFuelTypeDropdown(context, setDialogState),
                                child: CompositedTransformTarget(
                                  link: _fuelTypeLayerLink,
                                  child: Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA4B465),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedFuelType ?? 'Type',
                                        style: TextStyle(
                                          color: _selectedFuelType == null ? Colors.white70 : Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Image.asset(
                                        _isFuelTypeDropdownOpen
                                            ? 'assets/icons/dropdownbutton2back_icon.png'
                                            : 'assets/icons/dropdownbutton2_icon.png',
                                        width: 20,
                                        height: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 20),
                            
                            // Date of Activity field
                            const Text(
                              'Date of Activity',
                              style: TextStyle(
                                color: Color(0xFF5D6C24),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                                      // Date picker field - now shows selected date and can be tapped to change
                                      GestureDetector(
                                        onTap: () => _selectDate(context, setDialogState),
                                        child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4B465),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                            Text(
                                              _formatDate(_selectedDate),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Image.asset(
                                                'assets/icons/dropdownbutton2_icon.png',
                                                width: 20,
                                                height: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Documentation field
                                  const Text(
                                        'Documentation',
                                    style: TextStyle(
                                          color: Color(0xFF5D6C24),
                                      fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Image upload area
                                      Center(
                                        child: GestureDetector(
                                          onTap: () => _pickImage(setDialogState),
                                          child: Container(
                                            width: 250,
                                            height: 250,
                                            decoration: BoxDecoration(
                                              color: const Color(0x66D9D9D9),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: DottedBorder(
                                              color: Colors.black,
                                              strokeWidth: 2,
                                              dashPattern: const [6, 6],
                                              borderType: BorderType.RRect,
                                              radius: const Radius.circular(8),
                                              padding: const EdgeInsets.all(0),
                                              child: _selectedImage != null
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.file(
                                                        _selectedImage!,
                                                        width: 250,
                                                        height: 250,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                  Image.asset(
                                                            'assets/icons/image_icon.png',
                                                            width: 40,
                                                            height: 40,
                                                          ),
                                                          const SizedBox(height: 8),
                                                          const Text(
                                                            'Upload a file or take a photo',
                                                            style: TextStyle(
                                                              color: Color(0xFFA4B465),
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    
                                    const SizedBox(height: 30),
                                    
                                    // Calculate button
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: (isCalculating || isSubmitting) ? null : () async {
                                          // Activate debounce to prevent multiple clicks
                                          debounceCalculateButton();
                                          
                                          // Validate inputs
                                          if (_selectedTransportationMode != null && _distanceController.text.isNotEmpty && _selectedImage != null) {
                                            try {
                                              // Show loading indicator and disable button
                                              setDialogState(() {
                                                isCalculating = true;
                                              });
                                              
                                              // Parse distance
                                              final distance = double.tryParse(_distanceController.text) ?? 0;
                                              
                                              // Calculate emissions using EmissionService
                                              double emissions = 0;
                                              if (_selectedTransportationMode == 'Private Vehicle' && _selectedVehicleType != null && _selectedFuelType != null) {
                                                emissions = await EmissionService.calculateFuelEmissions(
                                                  distance: distance,
                                                  fuelType: _selectedFuelType!,
                                                  vehicleType: _selectedVehicleType!,
                                                  customEfficiency: _useCustomEfficiency && _efficiencyController.text.isNotEmpty
                                                      ? double.parse(_efficiencyController.text)
                                                      : null,
                                                );
                                              } else if (_selectedTransportationMode == 'Public Transport' && _selectedVehicleType != null) {
                                                // For public transport, use the new calculation method
                                                emissions = await EmissionService.calculatePublicTransportEmissions(
                                                  distance: distance,
                                                  vehicleType: _selectedVehicleType!,
                                                );
                                              }
                                              
                                              // Create new entry with calculated emissions
                                              final entry = ConsumptionEntry(
                                                category: 'Fuel Consumption',
                                                itemType: _selectedTransportationMode == 'Private Vehicle' 
                                                    ? _selectedVehicleType ?? 'Vehicle'
                                                    : _selectedVehicleType ?? 'Public Transport',
                                                quantity: distance,
                                                date: _selectedDate,
                                                image: _selectedImage,
                                                emissions: emissions,
                                                imageUrl: null,
                                                metadata: {
                                                  'useCustomEfficiency': _useCustomEfficiency,
                                                  'customEfficiency': _useCustomEfficiency && _efficiencyController.text.isNotEmpty 
                                                      ? double.parse(_efficiencyController.text) 
                                                      : null,
                                                  'fuelType': _selectedTransportationMode == 'Private Vehicle' ? _selectedFuelType ?? 'Petrol' : null,
                                                  'transportationMode': _selectedTransportationMode,
                                                },
                                              );
                                              
                                              // Check if dialog is still mounted before proceeding
                                              if (!mounted) return;
                                              
                                              // Only add to local list if the entry date matches the current view date
                                              final bool isSameDay = 
                                                  _selectedDate.year == _viewDate.year && 
                                                  _selectedDate.month == _viewDate.month && 
                                                  _selectedDate.day == _viewDate.day;
                                              
                                              if (isSameDay) {
                                                setState(() {
                                                  _consumptionEntries.add(entry);
                                                });
                                                
                                                // Recalculate emissions after adding new entry
                                                _calculateEmissions();
                                              } else {
                                                // If entry is for a different date, notify user and offer to navigate
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text('Entry saved for ${_formatDate(_selectedDate)}'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(context); // Close dialog
                                                            _navigateToDate(_selectedDate); // Navigate to entry date
                                                          },
                                                          child: const Text(
                                                            'GO TO DATE',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor: Colors.green,
                                                    duration: const Duration(seconds: 5),
                                                  ),
                                                );
                                              }
                                              
                                              // Save to Firebase
                                              try {
                                                User? currentUser = _authService.currentUser;
                                                if (currentUser != null) {
                                                  // Prepare data for Firestore
                                                  final entryData = {
                                                    'category': entry.category,
                                                    'itemType': entry.itemType,
                                                    'quantity': entry.quantity,
                                                    'date': Timestamp.fromDate(entry.date),
                                                    'emissions': entry.emissions,
                                                    'metadata': entry.metadata,
                                                  };
                                                  
                                                  // Save to Firestore
                                                  await _userService.saveConsumptionEntry(
                                                    currentUser.uid, 
                                                    entryData, 
                                                    entry.image
                                                  );
                                                  
                                                  print('Entry saved to Firebase');
                                                }
                                              } catch (e) {
                                                print('Error saving to Firebase: $e');
                                                // Show error message but don't block the UI
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Entry saved locally but failed to sync: $e'),
                                                      backgroundColor: Colors.orange,
                                                    ),
                                                  );
                                                }
                                              }
                                              
                                              // Close dialog
                                              if (mounted) {
                                                Navigator.pop(context);
                                              }
                                            } catch (e) {
                                              // Hide loading indicator
                                              if (mounted) {
                                                setDialogState(() {
                                                  isCalculating = false;
                                                });
                                                
                                                // Show error message
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error calculating emissions: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          } else {
                                            // Show error message with specific validation failures
                                            String errorMessage = 'Please fill in all required fields';
                                            if (_selectedTransportationMode == null) {
                                              errorMessage = 'Please select a transportation mode';
                                            } else if (_distanceController.text.isEmpty) {
                                              errorMessage = 'Please enter a distance';
                                            } else if (_selectedImage == null) {
                                              errorMessage = 'Documentation image is required';
                                            }
                                            
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(errorMessage),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF626F47),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          elevation: 4,
                                        ),
                                        child: isCalculating 
                                          ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Calculate',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ],],
                                ),
                              ),
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
    );
  }
  
  // Pick image from camera or gallery
  Future<void> _pickImage(StateSetter setDialogState) async {
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
                  final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    setDialogState(() {
                      _selectedImage = File(photo.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setDialogState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
                ),
              ],
            ),
        );
      },
    );
  }
  
  // Format date as DD/MM/YYYY
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  // Navigate to previous day
  void _goToPreviousDay() {
    setState(() {
      _viewDate = _viewDate.subtract(const Duration(days: 1));
      _currentDate = _formatDate(_viewDate);
    });
    _loadConsumptionEntries(); // Reload entries for the new date
  }
  
  // Navigate to next day
  void _goToNextDay() {
    setState(() {
      _viewDate = _viewDate.add(const Duration(days: 1));
      _currentDate = _formatDate(_viewDate);
    });
    _loadConsumptionEntries(); // Reload entries for the new date
  }
  
  // Show date picker to select a specific date
  Future<void> _selectViewDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _viewDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5D6C24),
              onPrimary: Colors.white,
              surface: Color(0xFFE4FFAC),
              onSurface: Color(0xFF5D6C24),
            ),
            dialogBackgroundColor: const Color(0xFFE4FFAC),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _viewDate) {
      setState(() {
        _viewDate = picked;
        _currentDate = _formatDate(_viewDate);
      });
      _loadConsumptionEntries(); // Reload entries for the new date
    }
  }
  
  // Add a method to navigate to a specific date after adding an entry
  void _navigateToDate(DateTime date) {
    setState(() {
      _viewDate = date;
      _currentDate = _formatDate(_viewDate);
    });
    _loadConsumptionEntries(); // Reload entries for the new date
  }
  
  // Modify the _selectDate method to update _selectedDate without affecting _viewDate
  Future<void> _selectDate(BuildContext context, StateSetter setDialogState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5D6C24),
              onPrimary: Colors.white,
              surface: Color(0xFFE4FFAC),
              onSurface: Color(0xFF5D6C24),
            ),
            dialogBackgroundColor: const Color(0xFFE4FFAC),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setDialogState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildCalculatorContent() {
    return Stack(
      children: [
        // Main content
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Daily Carbon Footprint',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Daily Carbon Footprint Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4FFAC), // Light green background
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
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        // Date navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous date button
                            GestureDetector(
                              onTap: _goToPreviousDay,
                              child: Image.asset(
                                'assets/icons/previous1_button.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                            
                            // Date with dropdown - aligned left
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectViewDate(context),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentDate,
                                      style: const TextStyle(
                                        color: Color(0xFF626F47),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Image.asset(
                                      'assets/icons/dropdownbutton1_icon.png',
                                      width: 35,
                                      height: 35,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Next date button
                            GestureDetector(
                              onTap: _goToNextDay,
                              child: Image.asset(
                                'assets/icons/next1_button.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Emissions summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_totalEmissions kg CO2e',
                                  style: const TextStyle(
                                    color: Color(0xFFE259A4),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Total Emissions Today',
                                  style: TextStyle(
                                    color: Color(0xFF626F47),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$_dailyLimit kg CO2e',
                                  style: const TextStyle(
                                    color: Color(0xFF409718),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Daily Limit',
                                  style: TextStyle(
                                    color: Color(0xFF626F47),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Divider line
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Container(
                            height: 2,
                            width: double.infinity,
                            color: Colors.black.withOpacity(0.2), // #000000 with 20% opacity
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Fuel Consumption row with progress bar
                        Row(
                          children: [
                            // Label
                            const SizedBox(width: 5),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'Fuel Consumption',
                                style: TextStyle(
                                  color: Color(0xFF626F47),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            
                            // Progress bar with embedded text
                            Expanded(
                              flex: 3,
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  // Progress bar background
                                  Container(
                                    width: double.infinity,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA4B465),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  // Progress overlay
                                  Container(
                                    width: (_totalEmissions >= _dailyLimit) 
                                        ? double.infinity // Full width jika total melebihi limit
                                        : (_fuelEmissions / _dailyLimit).clamp(0.0, 1.0) * MediaQuery.of(context).size.width * 0.45,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEFEFE).withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  // Text inside progress bar
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      '$_fuelEmissions kg CO2e',
                                      style: const TextStyle(
                                        color: Color(0xFFE259A4),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Food & Packaging Consumption row with progress bar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label
                            const SizedBox(width: 5),
                            const Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Food & Packaging',
                                    style: TextStyle(
                                      color: Color(0xFF626F47),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Consumption',
                                    style: TextStyle(
                                      color: Color(0xFF626F47),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Progress bar with embedded text
                            Expanded(
                              flex: 3,
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  // Progress bar background
                                  Container(
                                    width: double.infinity,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA4B465),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  // Progress overlay
                                  Container(
                                    width: (_totalEmissions >= _dailyLimit) 
                                        ? double.infinity // Full width jika total melebihi limit
                                        : (_foodPackagingEmissions / _dailyLimit).clamp(0.0, 1.0) * MediaQuery.of(context).size.width * 0.45,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEFEFE).withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  // Text inside progress bar
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      '$_foodPackagingEmissions kg CO2e',
                                      style: const TextStyle(
                                        color: Color(0xFFE259A4),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Bottom row with progress bar and label
                        Row(
                          children: [
                            // Progress bar - takes most of the width
                            Expanded(
                              flex: 5,
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA4B465),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Stack(
                                  children: [
                                    // Progress overlay
                                    Container(
                                      width: (_totalEmissions / _dailyLimit).clamp(0.0, 1.0) * MediaQuery.of(context).size.width * 0.65,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEFEFE).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    // Left label inside progress bar
                                    Positioned(
                                      left: 15,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Text(
                                          '$_totalEmissions kg CO2e',
                                          style: TextStyle(
                                            color: Color(0xFFE259A4),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Center percentage
                                    Center(
                                      child: Text(
                                        '${_progressPercentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: Color(0xFF626F47),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    
                                    // Right label inside progress bar
                                    Positioned(
                                      right: 15,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Text(
                                          '$_dailyLimit kg CO2e',
                                          style: TextStyle(
                                            color: Color(0xFFE259A4),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 10),
                            
                            // Right label outside progress bar - clickable to show chart
                            GestureDetector(
                              onTap: _showProgressChartDialog,
                              child: Row(
                                children: [
                                  Text(
                                    '$_dailyLimit kg CO2e',
                                    style: TextStyle(
                                      color: Color(0xFF626F47),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Image.asset(
                                    'assets/icons/morebutton1_icon.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Consumption entries list
                ..._consumptionEntries.map((entry) => _buildConsumptionEntryCard(entry)),
                
                const SizedBox(height: 20),
                
                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Show Tips button
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => TipsDialog(
                            fuelEmissions: _fuelEmissions,
                            foodPackagingEmissions: _foodPackagingEmissions,
                            viewDate: _viewDate, // Pass the current view date
                          ),
                        );
                      },
                      child: Tooltip(
                        message: 'Get personalized tips based on your ${_formatDate(_viewDate)} emissions',
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF626F47), // 626F47 as requested
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/icons/lighticon.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Show Tips',
                                  style: TextStyle(
                                    color: Color(0xFFF5ECD5), // F5ECD5 as requested
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Add button
                    GestureDetector(
                      onTap: _showAddCalculationDialog,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4FFAC), // E4FFAC as requested
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icons/add_button_icon.png',
                            width: 48,
                            height: 48,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Add padding at the bottom to ensure content is not hidden behind the navigation bar
                const SizedBox(height: 120),
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
                  // PROFILE ICON (UNSELECTED)
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
                  
                  // CALCULATOR ICON (SELECTED)
                  Container(
                    width: 74,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF55481D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/icons/calculatorselect_icon.png',
                        width: 70,
                        height: 70,
                      ),
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
  
  // Build consumption entry card
  Widget _buildConsumptionEntryCard(ConsumptionEntry entry) {
    // Format date as DD/MM
    final formattedDate = '${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')}';
    
    // Format emissions to 1 decimal place
    final formattedEmissions = entry.emissions.toStringAsFixed(1);
    
    return GestureDetector(
      onTap: () => _showEntryDetailDialog(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE4FFAC),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Left side - Category Icon (always show the category icon)
              Image.asset(
                entry.category.contains('Food') 
                  ? 'assets/images/foodandpackaging.png' 
                  : 'assets/images/fuelconsumption.png',
                width: 60,
                height: 60,
              ),
              const SizedBox(width: 12),
              
              // Middle - Category and Item
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category and Item Type
                    Text(
                      entry.category,
                      style: const TextStyle(
                        color: Color(0xFF5D6C24),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (entry.itemType.isNotEmpty)
                      Text(
                        entry.itemType,
                        style: const TextStyle(
                          color: Color(0xFF5D6C24),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Right side - Emissions and Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$formattedEmissions kg CO2e',
                    style: const TextStyle(
                      color: Colors.pink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Color(0xFF5D6C24),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show entry detail dialog
  void _showEntryDetailDialog(ConsumptionEntry entry) {
    final formattedDate = '${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')}/${entry.date.year}';
    final formattedEmissions = entry.emissions.toStringAsFixed(2);
    
    // Debug info
    print('Entry detail - imageUrl: ${entry.imageUrl}');
    print('Entry detail - has image file: ${entry.image != null}');
    if (entry.image != null) {
      print('Entry detail - image path: ${entry.image!.path}');
      print('Entry detail - image exists: ${entry.image!.existsSync()}');
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE4FFAC), // Color as specified
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button, delete button, and edit button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF626F47),
                          size: 24,
                        ),
                      ),
                      
                      // Delete and Edit buttons
                      Row(
                        children: [
                          // Delete button
                          GestureDetector(
                            onTap: () {
                              // Close the current dialog
                              Navigator.pop(context);
                              
                              // Show confirmation dialog
                              _showDeleteConfirmationDialog(entry);
                            },
                            child: Image.asset(
                              'assets/icons/trashbutton_icon.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Edit button
                          GestureDetector(
                            onTap: () {
                              // Close the current dialog
                              Navigator.pop(context);
                              
                              // Find document ID for this entry
                              _findDocumentIdAndEdit(entry);
                            },
                            child: Image.asset(
                              'assets/icons/editbutton_icon.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Category icon and title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Category icon
                      Image.asset(
                        entry.category.contains('Food') 
                            ? 'assets/images/foodandpackaging.png' 
                            : 'assets/images/fuelconsumption.png',
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(width: 12),
                      
                      // Category title
                      Text(
                        entry.category,
                        style: const TextStyle(
                          color: Color(0xFF626F47), // Color as specified
                          fontSize: 18,
                          fontWeight: FontWeight.bold, // Bold as specified
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Different content based on category type
                if (entry.category == 'Fuel Consumption') ...[
                  // Date
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text(
                          'Date: ',
                          style: TextStyle(
                            color: Color(0xFF626F47),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Color(0xFF626F47),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Transportation Mode
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text(
                          'Transportation Mode: ',
                          style: TextStyle(
                            color: Color(0xFF626F47),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        Text(
                          entry.itemType,
                          style: const TextStyle(
                            color: Color(0xFF626F47),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Distance Traveled
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text(
                          'Distance Traveled (km): ',
                          style: TextStyle(
                            color: Color(0xFF626F47),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        Text(
                          '${entry.quantity.toInt()}',
                          style: const TextStyle(
                            color: Color(0xFF626F47),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Use Custom Efficiency - only for Private Vehicle
                  if (entry.metadata?['transportationMode'] == 'Private Vehicle') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          const Text(
                            'Use Custom Efficiency: ',
                            style: TextStyle(
                              color: Color(0xFF626F47),
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Text(
                            entry.metadata?['useCustomEfficiency'] == true ? 'Yes' : 'No',
                            style: const TextStyle(
                              color: Color(0xFF626F47),
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Show Custom Fuel Efficiency if custom efficiency was used
                    if (entry.metadata?['useCustomEfficiency'] == true) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            const Text(
                              'Custom Fuel Efficiency (km/l): ',
                              style: TextStyle(
                                color: Color(0xFF626F47),
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${entry.metadata?['customEfficiency'] ?? ''}',
                              style: const TextStyle(
                                color: Color(0xFF626F47),
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Fuel Type - only for Private Vehicle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          const Text(
                            'Fuel Type: ',
                            style: TextStyle(
                              color: Color(0xFF626F47),
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Text(
                            entry.metadata?['fuelType'] ?? 'Petrol',
                            style: const TextStyle(
                              color: Color(0xFF626F47),
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // Date
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text(
                          'Date: ',
                          style: TextStyle(
                            color: Color(0xFF626F47), // Color as specified
                            fontSize: 16,
                            fontWeight: FontWeight.normal, // Regular as specified
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Color(0xFF626F47), // Color as specified
                            fontSize: 16,
                            fontWeight: FontWeight.normal, // Regular as specified
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Item Type
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text(
                          'Item Type: ',
                          style: TextStyle(
                            color: Color(0xFF626F47), // Color as specified
                            fontSize: 16,
                            fontWeight: FontWeight.normal, // Regular as specified
                          ),
                        ),
                        Text(
                          entry.itemType,
                          style: const TextStyle(
                            color: Color(0xFF626F47), // Color as specified
                            fontSize: 16,
                            fontWeight: FontWeight.normal, // Regular as specified
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Quantity
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text(
                          'Quantity used : ',
                          style: TextStyle(
                            color: Color(0xFF626F47), // Color as specified
                            fontSize: 16,
                            fontWeight: FontWeight.normal, // Regular as specified
                          ),
                        ),
                        Text(
                          '${entry.quantity.toInt()}',
                          style: const TextStyle(
                            color: Color(0xFF626F47), // Color as specified
                            fontSize: 16,
                            fontWeight: FontWeight.normal, // Regular as specified
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Image with dotted border - Always show the dotted border container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DottedBorder(
                    color: Colors.black,
                    strokeWidth: 3,
                    dashPattern: const [8, 6],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(8),
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 250,
                        height: 250,
                        color: const Color(0x66D9D9D9),
                        child: _buildImageContent(entry),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Total emissions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Total : ',
                        style: TextStyle(
                          color: Color(0xFFE259A4), // Pink color as specified
                          fontSize: 16,
                          fontWeight: FontWeight.w500, // Medium as specified
                        ),
                      ),
                      Text(
                        '$formattedEmissions kg CO2e',
                        style: const TextStyle(
                          color: Color(0xFFE259A4), // Pink color as specified
                          fontSize: 16,
                          fontWeight: FontWeight.w500, // Medium as specified
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper method to build the image content
  Widget _buildImageContent(ConsumptionEntry entry) {
    // First try to show the network image if available
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      return Image.network(
        entry.imageUrl!,
        width: 250,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          // If network image fails, try to show local file image
          if (entry.image != null && entry.image!.existsSync()) {
            return Image.file(
              entry.image!,
              width: 250,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading file image: $error');
                return _buildImagePlaceholder();
              },
            );
          } else {
            return _buildImagePlaceholder();
          }
        },
      );
    }
    // If no network image, try to show local file image
    else if (entry.image != null && entry.image!.existsSync()) {
      return Image.file(
        entry.image!,
        width: 250,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading file image: $error');
          return _buildImagePlaceholder();
        },
      );
    }
    // If no image available, show placeholder
    else {
      return _buildImagePlaceholder();
    }
  }
  
  // Helper method to build image placeholder
  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/image_icon.png',
            width: 40,
            height: 40,
          ),
          const SizedBox(height: 8),
          const Text(
            'No image available',
            style: TextStyle(
              color: Color(0xFFA4B465),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Delete consumption entry
  Future<void> _deleteConsumptionEntry(ConsumptionEntry entry) async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Find the entry in Firestore
        final entriesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('consumption_entries')
            .where('date', isEqualTo: Timestamp.fromDate(entry.date))
            .where('itemType', isEqualTo: entry.itemType)
            .where('quantity', isEqualTo: entry.quantity)
            .get();
        
        // Delete all matching entries (should be just one, but being safe)
        for (var doc in entriesSnapshot.docs) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('consumption_entries')
              .doc(doc.id)
              .delete();
          
          print('Deleted entry with ID: ${doc.id}');
        }
        
        // Remove from local list
        setState(() {
          _consumptionEntries.removeWhere((e) => 
            e.date == entry.date && 
            e.itemType == entry.itemType && 
            e.quantity == entry.quantity);
        });
        
        // Recalculate emissions after deletion
        _calculateEmissions();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting entry: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete entry: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Hide loading indicator
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Calculate emissions from all entries
  void _calculateEmissions() {
    // Reset all emission counters
    int totalFoodEmissions = 0;
    int totalFuelEmissions = 0;
    
    // Calculate emissions for each category
    for (var entry in _consumptionEntries) {
      if (entry.category == 'Food & Packaging Consumption') {
        totalFoodEmissions += entry.emissions.toInt();
      } else if (entry.category == 'Fuel Consumption') {
        totalFuelEmissions += entry.emissions.toInt();
      }
    }
    
    // Update state with new values
    setState(() {
      _foodPackagingEmissions = totalFoodEmissions;
      _fuelEmissions = totalFuelEmissions;
      _totalEmissions = totalFoodEmissions + totalFuelEmissions;
      
      // Calculate progress percentage (total emissions / daily limit * 100)
      _progressPercentage = _dailyLimit > 0 
          ? (_totalEmissions / _dailyLimit * 100).clamp(0, 100) 
          : 0;
          
      // Update current emissions for the chart
      _currentEmissions = _totalEmissions.toDouble();
    });
    
    print('Calculated emissions - Food: $_foodPackagingEmissions, Fuel: $_fuelEmissions, Total: $_totalEmissions');
    print('Progress percentage: $_progressPercentage%');
  }

  // Close dropdowns when form is scrolled
  void _closeAllDropdowns(StateSetter? setDialogState) {
    _removeDropdownOverlay();
    
    if (setDialogState != null) {
      setDialogState(() {
        _isDropdownOpen = false;
        _isItemTypeDropdownOpen = false;
        _isTransportationModeDropdownOpen = false;
        _isVehicleTypeDropdownOpen = false;
        _isCustomEfficiencyDropdownOpen = false;
        _isFuelTypeDropdownOpen = false;
      });
    } else {
      setState(() {
        _isDropdownOpen = false;
        _isItemTypeDropdownOpen = false;
        _isTransportationModeDropdownOpen = false;
        _isVehicleTypeDropdownOpen = false;
        _isCustomEfficiencyDropdownOpen = false;
        _isFuelTypeDropdownOpen = false;
      });
    }
  }

  // Add listener to page controller to update the view state
  void _onPageChanged() {
    setState(() {
      _isMonthlyView = _pageController.page == 0;
    });
  }

  // Find document ID and navigate to edit screen
  Future<void> _findDocumentIdAndEdit(ConsumptionEntry entry) async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Find the entry in Firestore
        final entriesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('consumption_entries')
            .where('date', isEqualTo: Timestamp.fromDate(entry.date))
            .where('itemType', isEqualTo: entry.itemType)
            .where('quantity', isEqualTo: entry.quantity)
            .get();
        
        if (entriesSnapshot.docs.isNotEmpty) {
          // Get the document ID of the first matching entry
          final String documentId = entriesSnapshot.docs.first.id;
          
          // Hide loading indicator
          setState(() {
            _isLoading = false;
          });
          
          // Check the category and navigate to the appropriate edit screen
          if (entry.category == 'Food & Packaging Consumption') {
            // Navigate to the food entry edit screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditFoodEntryScreen(
                itemType: entry.itemType,
                quantity: entry.quantity,
                date: entry.date,
                image: entry.image,
                imageUrl: entry.imageUrl,
                documentId: documentId,
              ),
            ),
          );
          
          // If edit was successful, reload entries
          if (result == true) {
            _loadConsumptionEntries();
            }
          } else if (entry.category == 'Fuel Consumption') {
            // Determine transportation mode
            String transportationMode = 'Public Transport';
            if (entry.metadata != null && entry.metadata!.containsKey('transportationMode')) {
              transportationMode = entry.metadata!['transportationMode'];
            }
            
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditFuelConsumptionScreen(
                  itemType: entry.itemType,
                  quantity: entry.quantity,
                  date: entry.date,
                  image: entry.image,
                  imageUrl: entry.imageUrl,
                  documentId: documentId,
                  transportationMode: transportationMode,
                ),
              ),
            );
            
            // If edit was successful, reload entries
            if (result == true) {
              _loadConsumptionEntries();
            }
          }
        } else {
          // Entry not found, show error
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry not found in database'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error finding document ID: $e');
      
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to edit entry: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show confirmation dialog before deleting an entry
  void _showDeleteConfirmationDialog(ConsumptionEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE4FFAC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Confirm Delete',
            style: TextStyle(
              color: Color(0xFF5D6C24),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this entry?',
            style: TextStyle(
              color: Color(0xFF5D6C24),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'No',
                style: TextStyle(
                  color: Color(0xFF5D6C24),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteConsumptionEntry(entry);
              },
              child: const Text(
                'Yes',
                style: TextStyle(
                  color: Color(0xFFE259A4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom painter for the donut chart
class DonutChartPainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final Color progressColor;
  
  DonutChartPainter({
    required this.percentage,
    required this.backgroundColor,
    required this.progressColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.3; // 30% of radius for donut thickness
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
      
    canvas.drawCircle(center, radius - (strokeWidth / 2), backgroundPaint);
    
    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final progressAngle = 2 * math.pi * (percentage / 100);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
      -math.pi / 2, // Start from top
      progressAngle,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    // Draw dashed border
    final dashWidth = 5.0;
    final dashSpace = gap;
    double distance = 0.0;
    final metrics = path.computeMetrics();
    
    for (final metric in metrics) {
      while (distance < metric.length) {
        if (distance + dashWidth > metric.length) {
          // Draw remaining dash
          canvas.drawPath(
            metric.extractPath(distance, metric.length),
            paint,
          );
          distance = metric.length;
        } else {
          // Draw dash
          canvas.drawPath(
            metric.extractPath(distance, distance + dashWidth),
            paint,
          );
          distance += dashWidth;
        }
        // Add gap
        distance += dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Class to represent a consumption entry
class ConsumptionEntry {
  final String category;
  final String itemType;
  final double quantity;
  final DateTime date;
  final File? image;
  final double emissions;
  final String? imageUrl;
  final Map<String, dynamic>? metadata; // Tambahkan metadata untuk menyimpan informasi tambahan
  
  ConsumptionEntry({
    required this.category,
    required this.itemType,
    required this.quantity,
    required this.date,
    this.image,
    required this.emissions,
    this.imageUrl,
    this.metadata,
  });
} 