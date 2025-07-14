import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class UserService {
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new user document in Firestore
  Future<void> createUserDocument(User user, String username) async {
    await _usersCollection.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // Get user data
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _usersCollection.doc(uid).get();
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).update(data);
  }

  // Update last login timestamp
  Future<void> updateLastLogin(String uid) async {
    try {
      print('Attempting to update last login for user: $uid');
      // Check if document exists first
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        print('User document exists, updating last login timestamp');
        await _usersCollection.doc(uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('Last login timestamp updated successfully');
      } else {
        // Document doesn't exist, throw an exception to be caught by the caller
        print('User document not found in Firestore for uid: $uid');
        throw Exception('User document not found');
      }
    } catch (e) {
      print('Error updating last login: $e');
      // Only rethrow if it's not a "document not found" error
      if (e.toString().contains('User document not found')) {
        // This is an expected error that will be handled by the caller
        rethrow;
      } else {
        // For other errors, we'll just log them but not block the login process
        print('Non-critical error in updateLastLogin: $e');
      }
    }
  }
  
  // Save consumption entry to Firestore
  Future<void> saveConsumptionEntry(String uid, Map<String, dynamic> entryData, File? imageFile) async {
    try {
      print('Saving consumption entry for user: $uid');
      
      // If there's an image, upload it to Firebase Storage
      if (imageFile != null) {
        try {
          print('Starting image upload process');
          
          // Method 1: Direct Upload to Firebase Storage
          try {
            // Create a reference with a simpler path
            final storageRef = _storage
                .ref()
                .child('user_images')
                .child('$uid-${DateTime.now().millisecondsSinceEpoch}.jpg');
            
            // Create metadata
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'userId': uid,
                'timestamp': DateTime.now().toString(),
              },
            );
            
            // Upload the file as bytes
            final bytes = await imageFile.readAsBytes();
            print('Image size: ${bytes.length} bytes');
            
            // Create upload task
            final uploadTask = storageRef.putData(bytes, metadata);
            
            // Wait for upload to complete
            final snapshot = await uploadTask;
            print('Upload complete: ${snapshot.bytesTransferred} bytes');
            
            // Get download URL
            final downloadUrl = await snapshot.ref.getDownloadURL();
            print('Download URL: $downloadUrl');
            
            // Add URL to entry data
            entryData['imageUrl'] = downloadUrl;
          } catch (e) {
            print('Direct upload failed: $e');
            
            // Method 2: Base64 encoding as fallback
            print('Trying Base64 encoding as fallback');
            final bytes = await imageFile.readAsBytes();
            final base64Image = base64Encode(bytes);
            
            // Store a small portion in Firestore directly if it's under 1MB
            if (base64Image.length < 900000) {
              print('Storing image directly in Firestore (Base64)');
              entryData['imageBase64'] = base64Image;
            } else {
              print('Image too large for Firestore storage: ${base64Image.length} chars');
              // For larger images, we could split them or use other methods
            }
          }
        } catch (storageError) {
          print('Error handling image: $storageError');
          // Continue without the image
        }
      }
      
      // Add timestamp
      entryData['createdAt'] = FieldValue.serverTimestamp();
      
      // Save to Firestore in a subcollection of the user
      DocumentReference docRef = await _usersCollection
          .doc(uid)
          .collection('consumption_entries')
          .add(entryData);
          
      print('Consumption entry saved successfully with ID: ${docRef.id}');
      print('Entry data: $entryData');
    } catch (e) {
      print('Error saving consumption entry: $e');
      throw Exception('Failed to save entry: $e');
    }
  }

  // Add a new method for uploading profile image
  Future<Map<String, dynamic>> uploadProfileImage(String uid, File imageFile) async {
    try {
      print('Uploading profile image for user: $uid');
      Map<String, dynamic> imageData = {};
      
      // Langsung gunakan Base64 encoding sebagai metode utama karena lebih reliable
      try {
        print('Encoding profile image with Base64');
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        // Store in Firestore directly if it's under 900KB (Firestore has 1MB limit)
        if (base64Image.length < 900000) {
          print('Storing profile image directly in Firestore (Base64)');
          imageData['profileImageBase64'] = base64Image;
          
          // Hapus URL lama jika ada - dengan cara yang lebih aman
          DocumentSnapshot userData = await getUserData(uid);
          if (userData.exists) {
            Map<String, dynamic>? data = userData.data() as Map<String, dynamic>?;
            if (data != null && data.containsKey('profileImageUrl')) {
              imageData['profileImageUrl'] = FieldValue.delete();
              print('Deleting old profile image URL');
            }
          }
        } else {
          print('Profile image too large for Firestore: ${base64Image.length} chars');
          throw Exception('Profile image too large, please use a smaller image');
        }
      } catch (e) {
        print('Base64 encoding failed: $e');
        throw Exception('Failed to process image: $e');
      }
      
      // Update user document with the profile image data
      await updateUserData(uid, imageData);
      
      return imageData;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }
  
  // Method to update an image for an existing entry
  Future<Map<String, dynamic>> updateEntryImage(String uid, String documentId, File? imageFile) async {
    try {
      print('Updating image for entry $documentId for user: $uid');
      Map<String, dynamic> imageData = {};
      
      // If there's an image, upload it to Firebase Storage
      if (imageFile == null) {
        throw Exception('No image file provided for update');
      }
      
      try {
        print('Starting image upload process');
        
        // Method 1: Direct Upload to Firebase Storage
        try {
          // Create a reference with a simpler path
          final storageRef = _storage
              .ref()
              .child('user_images')
              .child('$uid-${DateTime.now().millisecondsSinceEpoch}.jpg');
          
          // Create metadata
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': uid,
              'timestamp': DateTime.now().toString(),
            },
          );
          
          // Upload the file as bytes
          final bytes = await imageFile.readAsBytes();
          print('Image size: ${bytes.length} bytes');
          
          // Create upload task
          final uploadTask = storageRef.putData(bytes, metadata);
          
          // Wait for upload to complete
          final snapshot = await uploadTask;
          print('Upload complete: ${snapshot.bytesTransferred} bytes');
          
          // Get download URL
          final downloadUrl = await snapshot.ref.getDownloadURL();
          print('Download URL: $downloadUrl');
          
          // Add URL to image data
          imageData['imageUrl'] = downloadUrl;
        } catch (e) {
          print('Direct upload failed: $e');
          
          // Method 2: Base64 encoding as fallback
          print('Trying Base64 encoding as fallback');
          final bytes = await imageFile.readAsBytes();
          final base64Image = base64Encode(bytes);
          
          // Store a small portion in Firestore directly if it's under 1MB
          if (base64Image.length < 900000) {
            print('Storing image directly in Firestore (Base64)');
            imageData['imageBase64'] = base64Image;
          } else {
            print('Image too large for Firestore storage: ${base64Image.length} chars');
            throw Exception('Image too large for storage');
          }
        }
      } catch (storageError) {
        print('Error handling image: $storageError');
        throw Exception('Failed to upload image: $storageError');
      }
      
      // Update the existing document with the new image data
      await _usersCollection
          .doc(uid)
          .collection('consumption_entries')
          .doc(documentId)
          .update(imageData);
          
      print('Entry image updated successfully for document ID: $documentId');
      
      return imageData;
    } catch (e) {
      print('Error updating entry image: $e');
      throw Exception('Failed to update entry image: $e');
    }
  }
} 