import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class EmissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _apiKey = 'YOUR_API_KEY';
  static const String _baseUrl = 'https://api.climatiq.io/data/v1/estimate';
  
  // Cache maps to avoid repeated Firestore calls
  static Map<String, String>? _cachedFoodEmissionFactors;
  static Map<String, double>? _cachedFixedEmissionValues;
  static Map<String, double>? _cachedFuelEmissionFactors;
  static Map<String, double>? _cachedVehicleEfficiencyValues;
  static Map<String, double>? _cachedPublicTransportEmissionFactors;
  static Map<String, int>? _cachedPublicTransportAveragePassengers;

  // Get food emission factors from Firebase
  static Future<Map<String, String>> getFoodEmissionFactors() async {
    if (_cachedFoodEmissionFactors != null) {
      return _cachedFoodEmissionFactors!;
    }
    
    try {
      final snapshot = await _firestore
          .collection('emission_factors')
          .doc('factors')
          .collection('foodEmissionFactors')
          .get();
      
      final Map<String, String> factors = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        factors[data['name'] as String] = data['value'] as String;
      }
      
      _cachedFoodEmissionFactors = factors;
      return factors;
    } catch (e) {
      print('Error fetching food emission factors: $e');
      // Return empty map on error
      return {};
    }
  }
  
  // Get fixed emission values from Firebase
  static Future<Map<String, double>> getFixedEmissionValues() async {
    if (_cachedFixedEmissionValues != null) {
      return _cachedFixedEmissionValues!;
    }
    
    try {
      final snapshot = await _firestore
          .collection('emission_factors')
          .doc('factors')
          .collection('fixedEmissionValues')
          .get();
      
      final Map<String, double> values = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        values[data['name'] as String] = (data['value'] as num).toDouble();
      }
      
      _cachedFixedEmissionValues = values;
      return values;
    } catch (e) {
      print('Error fetching fixed emission values: $e');
      // Return empty map on error
      return {};
    }
  }
  
  // Get fuel emission factors from Firebase
  static Future<Map<String, double>> getFuelEmissionFactors() async {
    if (_cachedFuelEmissionFactors != null) {
      return _cachedFuelEmissionFactors!;
    }
    
    try {
      final snapshot = await _firestore
          .collection('emission_factors')
          .doc('factors')
          .collection('fuelEmissionFactors')
          .get();
      
      final Map<String, double> factors = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        factors[data['name'] as String] = (data['value'] as num).toDouble();
      }
      
      _cachedFuelEmissionFactors = factors;
      return factors;
    } catch (e) {
      print('Error fetching fuel emission factors: $e');
      // Return empty map on error
      return {};
    }
  }
  
  // Get vehicle efficiency values from Firebase
  static Future<Map<String, double>> getVehicleEfficiencyValues() async {
    if (_cachedVehicleEfficiencyValues != null) {
      return _cachedVehicleEfficiencyValues!;
    }
    
    try {
      final snapshot = await _firestore
          .collection('emission_factors')
          .doc('factors')
          .collection('vehicleEfficiencyValues')
          .get();
      
      final Map<String, double> values = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        values[data['name'] as String] = (data['value'] as num).toDouble();
      }
      
      _cachedVehicleEfficiencyValues = values;
      return values;
    } catch (e) {
      print('Error fetching vehicle efficiency values: $e');
      // Return empty map on error
      return {};
    }
  }
  
  // Get public transport emission factors from Firebase
  static Future<Map<String, double>> getPublicTransportEmissionFactors() async {
    if (_cachedPublicTransportEmissionFactors != null) {
      return _cachedPublicTransportEmissionFactors!;
    }
    
    try {
      final snapshot = await _firestore
          .collection('emission_factors')
          .doc('factors')
          .collection('publicTransportEmissionFactors')
          .get();
      
      final Map<String, double> factors = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        factors[data['name'] as String] = (data['value'] as num).toDouble();
      }
      
      _cachedPublicTransportEmissionFactors = factors;
      return factors;
    } catch (e) {
      print('Error fetching public transport emission factors: $e');
      // Return empty map on error
      return {};
    }
  }
  
  // Get public transport average passengers from Firebase
  static Future<Map<String, int>> getPublicTransportAveragePassengers() async {
    if (_cachedPublicTransportAveragePassengers != null) {
      return _cachedPublicTransportAveragePassengers!;
    }
    
    try {
      final snapshot = await _firestore
          .collection('emission_factors')
          .doc('factors')
          .collection('publicTransportAveragePassengers')
          .get();
      
      final Map<String, int> passengers = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        passengers[data['name'] as String] = (data['value'] as num).toInt();
      }
      
      _cachedPublicTransportAveragePassengers = passengers;
      return passengers;
    } catch (e) {
      print('Error fetching public transport average passengers: $e');
      // Return empty map on error
      return {};
    }
  }

  // Calculate emissions for food and packaging
  static Future<double> calculateFoodEmissions(String itemType, double quantity) async {
    try {
      print('Calculating emissions for $itemType, quantity: $quantity kg');
      
      // Get fixed emission values from Firebase
      final fixedEmissionValues = await getFixedEmissionValues();
      
      // Check if the item has a fixed emission value
      if (fixedEmissionValues.containsKey(itemType)) {
        final emissionFactor = fixedEmissionValues[itemType]!;
        final emissions = emissionFactor * quantity;
        print('Using fixed emission value: $emissionFactor kg CO2e/kg');
        print('Emissions calculated: $emissions kg CO2e');
        return emissions;
      }
      
      // Get food emission factors from Firebase
      final foodEmissionFactors = await getFoodEmissionFactors();
      
      // For other items, use the Climatiq API
      // Get emission factor ID for the item type
      final emissionFactorId = foodEmissionFactors[itemType];
      if (emissionFactorId == null) {
        print('Unknown item type: $itemType');
        throw Exception('Unknown item type: $itemType');
      }

      // Prepare request body
      final requestBody = {
        'emission_factor': {
          'activity_id': emissionFactorId,
          'data_version': '^22', // Updated to latest dynamic data version
        },
        'parameters': {
          'weight': quantity,
          'weight_unit': 'kg'
        }
      };

      print('Sending request to Climatiq API: ${jsonEncode(requestBody)}');

      // Make API request
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final emissions = data['co2e'] ?? 0.0;
        print('Emissions calculated: $emissions kg CO2e');
        
        // Return emissions in kg CO2e
        return emissions;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        
        // Try to parse error message from API
        String errorMessage = 'API Error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (_) {}
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error calculating emissions: $e');
      
      // Rethrow with more user-friendly message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to calculate emissions. Please try again.');
    }
  }

  // Calculate emissions for fuel consumption
  // Emisi (kg CO2e) = Jarak Tempuh (km) / Efisiensi (km/l) × Faktor Emisi Bahan Bakar (kg CO2e/l)
  static Future<double> calculateFuelEmissions({
    required double distance,
    required String fuelType,
    required String vehicleType,
    double? customEfficiency,
  }) async {
    try {
      print('Calculating fuel emissions - Distance: $distance km, Fuel: $fuelType, Vehicle: $vehicleType, Custom Efficiency: $customEfficiency');
      
      // Get fuel emission factors from Firebase
      final fuelEmissionFactors = await getFuelEmissionFactors();
      
      // Get emission factor for the fuel type
      final emissionFactor = fuelEmissionFactors[fuelType];
      if (emissionFactor == null) {
        print('Unknown fuel type: $fuelType');
        throw Exception('Unknown fuel type: $fuelType');
      }
      
      // Get efficiency based on vehicle type or custom value
      double efficiency;
      if (customEfficiency != null && customEfficiency > 0) {
        // Use custom efficiency if provided
        efficiency = customEfficiency;
        print('Using custom efficiency: $efficiency km/l');
      } else {
        // Get vehicle efficiency values from Firebase
        final vehicleEfficiencyValues = await getVehicleEfficiencyValues();
        
        // Use default efficiency for the vehicle type
        efficiency = vehicleEfficiencyValues[vehicleType] ?? 20.0; // Default to 20 km/l if not found
        print('Using default efficiency for $vehicleType: $efficiency km/l');
      }
      
      // Calculate emissions: distance / efficiency * emission factor
      final emissions = (distance / efficiency) * emissionFactor;
      print('Fuel emissions calculated: $emissions kg CO2e');
      
      return emissions;
    } catch (e) {
      print('Error calculating fuel emissions: $e');
      
      // Rethrow with more user-friendly message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to calculate fuel emissions. Please try again.');
    }
  }
  
  // Calculate emissions for public transport
  // Emisi (kg CO2e) = Emisi Moda per km × Jarak Tempuh (km) / Rata-rata Penumpang per Moda
  static Future<double> calculatePublicTransportEmissions({
    required double distance,
    required String vehicleType,
  }) async {
    try {
      print('Calculating public transport emissions - Distance: $distance km, Vehicle Type: $vehicleType');
      
      // Get public transport emission factors from Firebase
      final publicTransportEmissionFactors = await getPublicTransportEmissionFactors();
      
      // Get emission factor for the vehicle type
      final emissionFactor = publicTransportEmissionFactors[vehicleType];
      if (emissionFactor == null) {
        print('Unknown public transport type: $vehicleType');
        throw Exception('Unknown public transport type: $vehicleType');
      }
      
      // Get public transport average passengers from Firebase
      final publicTransportAveragePassengers = await getPublicTransportAveragePassengers();
      
      // Get average passengers for the vehicle type
      final averagePassengers = publicTransportAveragePassengers[vehicleType];
      if (averagePassengers == null) {
        print('Unknown average passengers for: $vehicleType');
        throw Exception('Unknown average passengers for: $vehicleType');
      }
      
      // Calculate emissions: emission factor * distance / average passengers
      final emissions = (emissionFactor * distance) / averagePassengers;
      print('Public transport emissions calculated: $emissions kg CO2e');
      print('Formula: ($emissionFactor kg CO2e/km * $distance km) / $averagePassengers passengers');
      
      return emissions;
    } catch (e) {
      print('Error calculating public transport emissions: $e');
      
      // Rethrow with more user-friendly message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to calculate public transport emissions. Please try again.');
    }
  }
  
  // Clear cache to force reload from Firebase
  static void clearCache() {
    _cachedFoodEmissionFactors = null;
    _cachedFixedEmissionValues = null;
    _cachedFuelEmissionFactors = null;
    _cachedVehicleEfficiencyValues = null;
    _cachedPublicTransportEmissionFactors = null;
    _cachedPublicTransportAveragePassengers = null;
    print('Emission service cache cleared');
  }
} 