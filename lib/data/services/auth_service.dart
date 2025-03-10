import 'package:hive/hive.dart';
import '../models/user.dart';

class AuthService {
  final Box _authBox = Hive.box('authBox');

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      // Simulate network request
      await Future.delayed(const Duration(seconds: 1));

      // In a real app, you would verify credentials against a backend
      // For this example, we'll just create a mock user if credentials match
      if (email.isNotEmpty && password.isNotEmpty) {
        final user = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
        );

        // Save user to local storage
        await _saveUserToLocal(user);
        return user;
      }
      return null;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // In a real app, you would implement Google Sign-In
      // For this example, we'll create a mock user
      await Future.delayed(const Duration(seconds: 1));

      final user = User(
        id: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'google_user@example.com',
      );

      // Save user to local storage
      await _saveUserToLocal(user);
      return user;
    } catch (e) {
      print('Google sign in error: $e');
      return null;
    }
  }

  // Register a new user
  Future<User?> register(String email, String password) async {
    try {
      // Simulate network request
      await Future.delayed(const Duration(seconds: 1));

      // In a real app, you would register the user with a backend
      // For this example, we'll just create a mock user
      if (email.isNotEmpty && password.isNotEmpty) {
        final user = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
        );

        // Save user to local storage
        await _saveUserToLocal(user);
        return user;
      }
      return null;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authBox.delete('currentUser');
  }

  // Get current user
  User? getCurrentUser() {
    final userData = _authBox.get('currentUser');
    if (userData != null) {
      return User.fromJson(Map<String, dynamic>.from(userData));
    }
    return null;
  }

  // Update user's buddy prefix
  Future<void> updateBuddyPrefix(String prefix) async {
    final userData = _authBox.get('currentUser');
    if (userData != null) {
      final user = User.fromJson(Map<String, dynamic>.from(userData));
      final updatedUser = User(
        id: user.id,
        email: user.email,
        buddyPrefix: prefix,
      );

      await _saveUserToLocal(updatedUser);
    }
  }

  // Save user to local storage
  Future<void> _saveUserToLocal(User user) async {
    await _authBox.put('currentUser', user.toJson());
  }
}