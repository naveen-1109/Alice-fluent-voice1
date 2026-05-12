import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/app_user_model.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  AppUser? _appUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => SupabaseService.currentUser;
  AppUser? get appUser => _appUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      try {
        final data = await SupabaseService.client
            .from('users')
            .select()
            .eq('id', user.id)
            .single();
        _appUser = AppUser.fromJson(data);
        notifyListeners();
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      await SupabaseService.signIn(email, password);
      await fetchUserProfile();
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String role, String fullName) async {
    _setLoading(true);
    _setError(null);
    try {
      debugPrint('Starting direct Supabase signup flow...');
      
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );
      
      // After successful signup, authenticate to establish a full session
      if (response.user != null) {
        debugPrint('Signup successful. Initiating password sign in to establish session.');
        await SupabaseService.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        await fetchUserProfile();
      }
      
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      debugPrint('AuthException during signup: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Unexpected exception during signup: $e');
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await SupabaseService.signOut();
      _appUser = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _setError(null);
    try {
      final email = currentUser?.email;
      if (email == null) throw Exception('Email not found for current user.');

      // Verify current password by signing in
      await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // If successful, update to new password
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Incorrect current password or update failed.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(
        email,
      );
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to send reset email.');
      _setLoading(false);
      return false;
    }
  }
}
