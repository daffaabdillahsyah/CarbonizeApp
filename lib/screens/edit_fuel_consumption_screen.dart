import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/emission_service.dart';

class EditFuelConsumptionScreen extends StatefulWidget {
  final String itemType; // Vehicle type for public transport
  final double quantity; // Distance traveled
  final DateTime date;
  final File? image;
  final String? imageUrl;
  final String documentId; // Firestore document ID
  final String transportationMode; // Public Transport or Private Vehicle

  const EditFuelConsumptionScreen({
    Key? key,
    required this.itemType,
    required this.quantity,
    required this.date,
    this.image,
    this.imageUrl,
    required this.documentId,
    required this.transportationMode,
  }) : super(key: key);

  @override
  State<EditFuelConsumptionScreen> createState() => _EditFuelConsumptionScreenState();
}

class _EditFuelConsumptionScreenState extends State<EditFuelConsumptionScreen> {
  // Services
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  // Public transport types
  final List<String> _publicTransportTypes = [
    'City Bus',
    'Intercity Bus',
    'Minibus / Angkot',
    'Online Motorcycle (Ojek)',
    'Online Taxi (Car)',
    'MRT',
  ];
  
  // Vehicle types for Private Vehicle
  final List<String> _vehicleTypes = [
    'City Car',
    'Motorcycle',
    'Sedan / Medium Car',
    'SUV / MPV',
    'Diesel Car',
    'Hybrid Car',
  ];
  
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
  
  // Selected values
  String? _selectedVehicleType;
  bool _isVehicleTypeDropdownOpen = false;
  
  // Key and layer link for dropdown positioning
  final GlobalKey _vehicleTypeDropdownKey = GlobalKey();
  final LayerLink _vehicleTypeLayerLink = LayerLink();
  
  // Overlay entry for dropdown
  OverlayEntry? _overlayEntry;
  
  // Text controller for distance input
  final TextEditingController _distanceController = TextEditingController();
  
  // Selected date
  late DateTime _selectedDate;
  
  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  
  // Loading state
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Additional fields for private vehicle
  String? _selectedFuelType;
  bool _isFuelTypeDropdownOpen = false;
  final GlobalKey _fuelTypeDropdownKey = GlobalKey();
  final LayerLink _fuelTypeLayerLink = LayerLink();
  bool _useCustomEfficiency = false;
  final TextEditingController _efficiencyController = TextEditingController();
  
  // For metadata storage
  Map<String, dynamic>? _metadata;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with the entry's values
    _selectedVehicleType = widget.itemType;
    _distanceController.text = widget.quantity.toString();
    _selectedDate = widget.date;
    _selectedImage = widget.image;
    
    // Load metadata for private vehicle entries
    _loadEntryMetadata();
  }
  
  // Load entry metadata from Firestore
  Future<void> _loadEntryMetadata() async {
    if (widget.transportationMode == 'Private Vehicle') {
      try {
        setState(() {
          _isLoading = true;
        });
        
        User? currentUser = _authService.currentUser;
        if (currentUser != null) {
          final docSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('consumption_entries')
              .doc(widget.documentId)
              .get();
              
          if (docSnapshot.exists) {
            final data = docSnapshot.data();
            if (data != null && data['metadata'] != null) {
              _metadata = data['metadata'];
              
              // Set fuel type from metadata
              if (_metadata!.containsKey('fuelType')) {
                setState(() {
                  _selectedFuelType = _metadata!['fuelType'];
                });
              }
              
              // Set custom efficiency from metadata
              if (_metadata!.containsKey('useCustomEfficiency') && 
                  _metadata!['useCustomEfficiency'] == true &&
                  _metadata!.containsKey('customEfficiency')) {
                setState(() {
                  _useCustomEfficiency = true;
                  _efficiencyController.text = _metadata!['customEfficiency'].toString();
                });
              }
            }
          }
        }
      } catch (e) {
        print('Error loading entry metadata: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  @override
  void dispose() {
    _removeDropdownOverlay();
    _distanceController.dispose();
    _efficiencyController.dispose();
    super.dispose();
  }
  
  // Remove dropdown overlay
  void _removeDropdownOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  // Toggle vehicle type dropdown
  void _toggleVehicleTypeDropdown(BuildContext context) {
    if (_isVehicleTypeDropdownOpen) {
      _removeDropdownOverlay();
      setState(() {
        _isVehicleTypeDropdownOpen = false;
      });
      return;
    }
    
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
                maxHeight: 200, // Limit height for scrolling
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: (widget.transportationMode == 'Public Transport' ? _publicTransportTypes : _vehicleTypes).map((String value) {
                    bool isLast = widget.transportationMode == 'Public Transport'
                        ? _publicTransportTypes.indexOf(value) == _publicTransportTypes.length - 1
                        : _vehicleTypes.indexOf(value) == _vehicleTypes.length - 1;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedVehicleType = value;
                          _isVehicleTypeDropdownOpen = false;
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
    setState(() {
      _isVehicleTypeDropdownOpen = true;
    });
  }
  
  // Toggle fuel type dropdown
  void _toggleFuelTypeDropdown(BuildContext context) {
    if (_isFuelTypeDropdownOpen) {
      _removeDropdownOverlay();
      setState(() {
        _isFuelTypeDropdownOpen = false;
      });
      return;
    }
    
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
                maxHeight: 200, // Limit height for scrolling
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _fuelTypes.map((String value) {
                    bool isLast = _fuelTypes.indexOf(value) == _fuelTypes.length - 1;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFuelType = value;
                          _isFuelTypeDropdownOpen = false;
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
    setState(() {
      _isFuelTypeDropdownOpen = true;
    });
  }
  
  // Toggle custom efficiency
  void _toggleCustomEfficiency(bool value) {
    setState(() {
      _useCustomEfficiency = value;
      if (!_useCustomEfficiency) {
        _efficiencyController.clear();
      }
    });
  }
  
  // Pick image from gallery or camera
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress image quality to 85% for smaller file size
        maxWidth: 800,    // Limit maximum width for smaller file size
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Select date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
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
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }
  
  // Format date as DD/MM/YYYY
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  // Update entry
  Future<void> _updateEntry() async {
    // Validate inputs
    if (_selectedVehicleType == null || _distanceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Additional validation for private vehicle
    if (widget.transportationMode == 'Private Vehicle' && _selectedFuelType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a fuel type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
        _isSaving = true;
      });
      
      // Parse distance
      final distance = double.tryParse(_distanceController.text) ?? 0;
      
      // Calculate emissions using the EmissionService
      double emissions;
      if (widget.transportationMode == 'Public Transport') {
        emissions = await EmissionService.calculatePublicTransportEmissions(
          distance: distance,
          vehicleType: _selectedVehicleType!
        );
      } else {
        // For private vehicle
        emissions = await EmissionService.calculateFuelEmissions(
          distance: distance,
          fuelType: _selectedFuelType!,
          vehicleType: _selectedVehicleType!,
          customEfficiency: _useCustomEfficiency && _efficiencyController.text.isNotEmpty
              ? double.tryParse(_efficiencyController.text)
              : null,
        );
      }
      
      // Get current user
      User? currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Prepare data for Firestore
      final entryData = {
        'category': 'Fuel Consumption',
        'itemType': _selectedVehicleType,
        'quantity': distance,
        'date': Timestamp.fromDate(_selectedDate),
        'emissions': emissions,
        'metadata': {
          'transportationMode': widget.transportationMode,
        },
      };
      
      // Add additional metadata for private vehicle
      if (widget.transportationMode == 'Private Vehicle') {
        entryData['metadata'] = {
          ...entryData['metadata'] as Map<String, dynamic>,
          'fuelType': _selectedFuelType,
          'useCustomEfficiency': _useCustomEfficiency,
          if (_useCustomEfficiency && _efficiencyController.text.isNotEmpty)
            'customEfficiency': double.tryParse(_efficiencyController.text),
        };
      }
      
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('consumption_entries')
          .doc(widget.documentId)
          .update(entryData);
          
      // If there's a new image, upload it
      if (_selectedImage != null && _selectedImage != widget.image) {
        print('Updating image: $_selectedImage');
        await _userService.updateEntryImage(
          currentUser.uid, 
          widget.documentId, 
          _selectedImage!
        );
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Return to previous screen
      if (mounted) {
        Navigator.pop(context, true); // Pass true to indicate successful update
      }
    } catch (e) {
      print('Error updating entry: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Hide loading indicator
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transportationMode == 'Public Transport' ? 'Edit Public Transport Entry' : 'Edit Private Vehicle Entry',
          style: const TextStyle(
            color: Color(0xFFE4FFAC),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF5D6C24),
        elevation: 0,
        centerTitle: true,
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle Type field
                        const Text(
                          'Vehicle Type',
                          style: TextStyle(
                            color: Color(0xFFE4FFAC),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Vehicle Type dropdown header
                        GestureDetector(
                          key: _vehicleTypeDropdownKey,
                          onTap: () => _toggleVehicleTypeDropdown(context),
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
                        
                        // Only show Fuel Type for Private Vehicle
                        if (widget.transportationMode == 'Private Vehicle') ...[
                          const SizedBox(height: 20),
                          
                          // Fuel Type field
                          const Text(
                            'Fuel Type',
                            style: TextStyle(
                              color: Color(0xFFE4FFAC),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Fuel Type dropdown
                          GestureDetector(
                            key: _fuelTypeDropdownKey,
                            onTap: () => _toggleFuelTypeDropdown(context),
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
                                      _selectedFuelType ?? 'Choose',
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
                        
                        // Distance traveled field
                        Row(
                          children: [
                            const Text(
                              'Distance Traveled (km)',
                              style: TextStyle(
                                color: Color(0xFFE4FFAC),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE4FFAC),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'i',
                                  style: TextStyle(
                                    color: Color(0xFF5D6C24),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Distance input field
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
                        
                        // Custom Efficiency field for Private Vehicle
                        if (widget.transportationMode == 'Private Vehicle') ...[
                          const SizedBox(height: 20),
                          
                          // Custom Efficiency field
                          Row(
                            children: [
                              const Text(
                                'Use Custom Efficiency?',
                                style: TextStyle(
                                  color: Color(0xFFE4FFAC),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Switch(
                                value: _useCustomEfficiency,
                                onChanged: _toggleCustomEfficiency,
                                activeColor: const Color(0xFFE4FFAC),
                                activeTrackColor: const Color(0xFF5D6C24),
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.white30,
                              ),
                            ],
                          ),
                          
                          // Custom Efficiency input field - only visible when custom efficiency is enabled
                          if (_useCustomEfficiency) ...[
                            const SizedBox(height: 8),
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
                                  hintText: 'Enter fuel efficiency (km/l)',
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
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Date of Activity field
                        const Text(
                          'Date of Activity',
                          style: TextStyle(
                            color: Color(0xFFE4FFAC),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Date picker field
                        GestureDetector(
                          onTap: () => _selectDate(context),
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
                            color: Color(0xFFE4FFAC),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Image upload area
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
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
                                  : widget.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          widget.imageUrl!,
                                          width: 250,
                                          height: 250,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
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
                                                    'Error loading image',
                                                    style: TextStyle(
                                                      color: Color(0xFFA4B465),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
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
                        
                        // Update button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE4FFAC),
                              foregroundColor: const Color(0xFF5D6C24),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 4,
                            ),
                            child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF5D6C24),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Update',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
} 