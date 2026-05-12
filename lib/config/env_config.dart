class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isValid {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL is not defined. Please build with --dart-define=SUPABASE_URL=value');
    }
    if (supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is not defined. Please build with --dart-define=SUPABASE_ANON_KEY=value');
    }
    
    // Simple URL validation
    if (!supabaseUrl.startsWith('https://')) {
       throw Exception('SUPABASE_URL must start with https://');
    }
  }
}
