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

class EditFoodEntryScreen extends StatefulWidget {
  final String itemType;
  final double quantity;
  final DateTime date;
  final File? image;
  final String? imageUrl;
  final String documentId; // Firestore document ID

  const EditFoodEntryScreen({
    Key? key,
    required this.itemType,
    required this.quantity,
    required this.date,
    this.image,
    this.imageUrl,
    required this.documentId,
  }) : super(key: key);

  @override
  State<EditFoodEntryScreen> createState() => _EditFoodEntryScreenState();
}

class _EditFoodEntryScreenState extends State<EditFoodEntryScreen> {
  // Services
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
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
  
  // Selected values
  String? _selectedItemType;
  bool _isItemTypeDropdownOpen = false;
  
  // Key and layer link for dropdown positioning
  final GlobalKey _itemTypeDropdownKey = GlobalKey();
  final LayerLink _itemTypeLayerLink = LayerLink();
  
  // Overlay entry for dropdown
  OverlayEntry? _overlayEntry;
  
  // Text controller for quantity input
  final TextEditingController _quantityController = TextEditingController();
  
  // Selected date
  late DateTime _selectedDate;
  
  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  
  // Loading state
  bool _isLoading = false;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with the entry's values
    _selectedItemType = widget.itemType;
    _quantityController.text = widget.quantity.toString();
    _selectedDate = widget.date;
    _selectedImage = widget.image;
  }
  
  @override
  void dispose() {
    _removeDropdownOverlay();
    _quantityController.dispose();
    super.dispose();
  }
  
  // Remove dropdown overlay
  void _removeDropdownOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  // Toggle item type dropdown
  void _toggleItemTypeDropdown(BuildContext context) {
    if (_isItemTypeDropdownOpen) {
      _removeDropdownOverlay();
      setState(() {
        _isItemTypeDropdownOpen = false;
      });
      return;
    }
    
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
                maxHeight: 200, // Limit height for scrolling
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _foodItemTypes.map((String value) {
                    bool isLast = _foodItemTypes.indexOf(value) == _foodItemTypes.length - 1;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedItemType = value;
                          _isItemTypeDropdownOpen = false;
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
      _isItemTypeDropdownOpen = true;
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
    if (_selectedItemType == null || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
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
      
      // Parse quantity
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      
      // Calculate emissions using the Climatiq API
      final emissions = await EmissionService.calculateFoodEmissions(
        _selectedItemType!,
        quantity
      );
      
      // Get current user
      User? currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Prepare data for Firestore
      final entryData = {
        'category': 'Food & Packaging Consumption',
        'itemType': _selectedItemType,
        'quantity': quantity,
        'date': Timestamp.fromDate(_selectedDate),
        'emissions': emissions,
      };
      
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
        title: const Text(
          'Edit Food & Packaging Entry',
          style: TextStyle(
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
                        // Item Type field
                        const Text(
                          'Item Type',
                          style: TextStyle(
                            color: Color(0xFFE4FFAC),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Item Type dropdown header
                        GestureDetector(
                          key: _itemTypeDropdownKey,
                          onTap: () => _toggleItemTypeDropdown(context),
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
                        
                        // Quantity input field
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