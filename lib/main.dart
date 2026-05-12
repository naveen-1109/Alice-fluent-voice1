import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'theme/colors.dart';
import 'theme/typography.dart';
import 'screens/auth_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/therapist_provider.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => TherapistProvider()),
      ],
      child: const FluentVoiceApp(),
    ),
  );
}

class FluentVoiceApp extends StatelessWidget {
  const FluentVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FluentVoice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: TextTheme(
          displayLarge: AppTypography.displayLarge,
          headlineMedium: AppTypography.screenHeading,
          titleLarge: AppTypography.subheading,
          bodyLarge: AppTypography.bodyText,
          bodyMedium: AppTypography.smallText,
          bodySmall: AppTypography.caption,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          secondary: AppColors.secondaryBlue,
          surface: AppColors.backgroundLight,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
