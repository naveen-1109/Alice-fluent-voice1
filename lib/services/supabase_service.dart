import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Sign Up
  static Future<AuthResponse> signUp(String email, String password, String role) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role},
    );
  }

  // Sign In
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  // Sign Out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Get Current User
  static User? get currentUser => client.auth.currentUser;

  // Reset Password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }
}
