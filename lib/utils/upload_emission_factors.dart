import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// This utility class is designed to be run once to upload all emission factors to Firebase.
/// After running, the app will use the data from Firebase instead of hardcoded values.
class UploadEmissionFactors {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Map food item types to Climatiq emission factors with correct activity IDs
  static final Map<String, String> foodEmissionFactors = {
    'Apples': 'arable_farming-type_apples-origin_region_global',
    'Rice': 'arable_farming-type_apples-origin_region_global',
    'Fresh Fish': 'agriculture_fishing_forestry-type_fish_all_species-origin_region_multi_region',
    'Cocoa Fruit': 'agriculture_fishing_forestry-type_fish_all_species-origin_region_multi_region',
    'Plastic Bottles': 'chemicals-type_polyethylene_terephthalate_granulate_bottle_grade_market_for_polyethylene_terephthalate_granulate_bottle_grade',
    'Plastic Bags/Films': 'chemicals-type_polyethylene_linear_low_density_granulate_market_for_polyethylene_linear_low_density_granulate',
    'Cardboard Boxes': 'paper_and_cardboard-type_carton_board_box_production_with_offset_printing_market_for_carton_board_box_production_with_offset_printing',
    'Tissue Paper': 'paper_and_cardboard-type_tissue_paper_market_for_tissue_paper',
  };
  
  // Fixed emission values for packaging items (kg CO2e per kg)
  static final Map<String, double> fixedEmissionValues = {
    'Cardboard Boxes': 0.85,
    'Plastic Bags/Films': 2.63,
    'Plastic Bottles': 2.3,
    'Tissue Paper': 1.1,
  };

  // Fuel emission factors (kg CO2e/l)
  static final Map<String, double> fuelEmissionFactors = {
    'Pertalite': 2.31,
    'Pertamax': 2.31,
    'Pertamax Turbo': 2.31,
    'Shell Super': 2.31,
    'Shell V-Power': 2.346,
    'Shell V-Power Nitro+': 2.346,
    'Solar / Bio Solar': 2.58,
    'Dexlite': 2.65,
    'Pertamina Dex': 2.68,
    'Shell V-Power Diesel': 2.68,
  };

  // Vehicle efficiency values (km/l)
  static final Map<String, double> vehicleEfficiencyValues = {
    'City Car': 45.0,
    'Motorcycle': 19.3,
    'Sedan / Medium Car': 18.4,
    'SUV / MPV': 14.8,
    'Diesel Car': 21.8,
    'Hybrid Car': 27.0,
  };
  
  // Public transport emission factors (kg CO2e/km)
  static final Map<String, double> publicTransportEmissionFactors = {
    'City Bus': 1.06,
    'Intercity Bus': 1.15,
    'Minibus / Angkot': 2.40,
    'Online Motorcycle (Ojek)': 0.058,
    'Online Taxi (Car)': 1.37,
    'MRT': 0.08,
  };
  
  // Average passengers per public transport mode
  static final Map<String, int> publicTransportAveragePassengers = {
    'City Bus': 20,
    'Intercity Bus': 25,
    'Minibus / Angkot': 8,
    'Online Motorcycle (Ojek)': 1,
    'Online Taxi (Car)': 4,
    'MRT': 300,
  };

  /// Upload all emission factors to Firebase
  static Future<void> uploadAllFactors() async {
    try {
      // Upload food emission factors
      await _uploadMapToFirebase('foodEmissionFactors', foodEmissionFactors);
      
      // Upload fixed emission values
      await _uploadMapToFirebase('fixedEmissionValues', fixedEmissionValues);
      
      // Upload fuel emission factors
      await _uploadMapToFirebase('fuelEmissionFactors', fuelEmissionFactors);
      
      // Upload vehicle efficiency values
      await _uploadMapToFirebase('vehicleEfficiencyValues', vehicleEfficiencyValues);
      
      // Upload public transport emission factors
      await _uploadMapToFirebase('publicTransportEmissionFactors', publicTransportEmissionFactors);
      
      // Upload public transport average passengers
      await _uploadMapToFirebase('publicTransportAveragePassengers', publicTransportAveragePassengers);
      
      print('All emission factors uploaded successfully!');
    } catch (e) {
      print('Error uploading emission factors: $e');
      rethrow;
    }
  }
  
  /// Helper method to upload a map to Firebase
  static Future<void> _uploadMapToFirebase(String collectionName, Map<dynamic, dynamic> data) async {
    try {
      // Reference to the collection
      final CollectionReference collection = _firestore.collection('emission_factors').doc('factors').collection(collectionName);
      
      // Create a batch to upload all items at once
      final WriteBatch batch = _firestore.batch();
      
      // Add each item to the batch
      data.forEach((key, value) {
        final docRef = collection.doc(key.toString().replaceAll('/', '_'));
        batch.set(docRef, {
          'name': key,
          'value': value,
        });
      });
      
      // Commit the batch
      await batch.commit();
      print('Uploaded $collectionName to Firebase');
    } catch (e) {
      print('Error uploading $collectionName: $e');
      rethrow;
    }
  }
}

/// Widget to run the upload process
class UploadEmissionFactorsScreen extends StatefulWidget {
  const UploadEmissionFactorsScreen({super.key});

  @override
  State<UploadEmissionFactorsScreen> createState() => _UploadEmissionFactorsScreenState();
}

class _UploadEmissionFactorsScreenState extends State<UploadEmissionFactorsScreen> {
  bool _isLoading = false;
  String _status = 'Ready to upload emission factors to Firebase';

  Future<void> _uploadFactors() async {
    setState(() {
      _isLoading = true;
      _status = 'Uploading emission factors...';
    });

    try {
      await UploadEmissionFactors.uploadAllFactors();
      setState(() {
        _status = 'Upload successful! You can now use the app with Firebase data.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error uploading factors: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Emission Factors'),
        backgroundColor: const Color(0xFF5D6C24),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator(color: Color(0xFF5D6C24))
              else
                ElevatedButton(
                  onPressed: _uploadFactors,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D6C24),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    'Upload Factors to Firebase',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Note: This should only be run once to populate the database.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 