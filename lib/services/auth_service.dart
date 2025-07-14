import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Login with email and password
  Future<UserCredential> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during login: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during login: $e');
      throw Exception('Login failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    print('Handling auth exception with code: ${e.code}');
    
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password. Please try again.';
        break;
      case 'invalid-credential':
        message = 'Invalid email or password. Please try again.';
        break;
      case 'invalid-login-credentials':
        message = 'Invalid email or password. Please try again.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'email-already-in-use':
        message = 'Email is already in use.';
        break;
      case 'weak-password':
        message = 'Password is too weak.';
        break;
      case 'invalid-email':
        message = 'Email address is invalid.';
        break;
      case 'operation-not-allowed':
        message = 'Operation not allowed.';
        break;
      case 'too-many-requests':
        message = 'Too many requests. Try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Check your internet connection.';
        break;
      default:
        message = 'Authentication error: ${e.code}. Please try again.';
    }
    return Exception(message);
  }

  // Function to change user password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in');
      }
      
      // Create credential with current email and password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      // Re-authenticate user to verify current password
      await user.reauthenticateWithCredential(credential);
      
      // Change password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during password change: $e');
      throw Exception('Failed to change password: $e');
    }
  }
} 