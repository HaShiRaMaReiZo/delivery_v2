import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'core/api/api_client.dart';
import 'core/api/api_endpoints.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/language_preference.dart';
import 'repositories/auth_repository.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences early to ensure token can be loaded
  await SharedPreferences.getInstance();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final languageCode = await LanguagePreference.getLanguage();
    if (languageCode != null) {
      setState(() {
        _selectedLocale = Locale(languageCode);
      });
    }
  }

  // This method will be called from SettingsScreen via a callback
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == 'system') {
      await LanguagePreference.clearLanguage();
      setState(() {
        _selectedLocale = null; // Use device default
      });
    } else {
      await LanguagePreference.setLanguage(languageCode);
      setState(() {
        _selectedLocale = Locale(languageCode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize API client (token will be loaded dynamically via interceptor)
    final apiClient = ApiClient.create(baseUrl: ApiEndpoints.baseUrl);
    final authRepository = AuthRepository(apiClient);

    return MaterialApp(
      title: 'OK Delivery - Merchant',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false, // Remove debug banner
      locale: _selectedLocale, // Use saved language or device default
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('my', ''), // Myanmar
      ],
      home: BlocProvider(
        create: (context) => AuthBloc(authRepository)..add(AuthCheckStatus()),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // Show loading while checking authentication status
            if (state is AuthInitial || state is AuthLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is AuthAuthenticated) {
              return MainNavigationScreen(
                user: state.user,
                onLanguageChanged: changeLanguage,
              );
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
