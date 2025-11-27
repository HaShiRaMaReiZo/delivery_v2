import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api/api_client.dart';
import 'core/api/api_endpoints.dart';
import 'core/theme/app_theme.dart';
import 'repositories/auth_repository.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/location/location_bloc.dart';
import 'services/location_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences early
  await SharedPreferences.getInstance();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ApiClient? _apiClient;
  AuthRepository? _authRepository;
  AuthBloc? _authBloc;
  LocationBloc? _locationBloc;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Get saved token first
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');

    // Initialize API client with saved token
    _apiClient = ApiClient.create(
      baseUrl: ApiEndpoints.baseUrl,
      token: savedToken,
    );
    _authRepository = AuthRepository(_apiClient!);
    _authBloc = AuthBloc(_authRepository!)..add(AuthCheckStatus());

    // Initialize location service and bloc
    if (kDebugMode) {
      debugPrint('MyApp: Initializing LocationService and LocationBloc');
    }
    final locationService = LocationService(_apiClient!);
    _locationBloc = LocationBloc(service: locationService);
    if (kDebugMode) {
      debugPrint('MyApp: LocationBloc initialized');
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _authBloc?.close();
    _locationBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while initializing
    if (!_initialized || _authBloc == null) {
      return MaterialApp(
        title: 'OK Delivery - Rider',
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc!),
        BlocProvider.value(value: _locationBloc!),
      ],
      child: MaterialApp(
        title: 'OK Delivery - Rider',
        theme: AppTheme.lightTheme,
        home: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // Update API client token when authenticated
            if (state is AuthAuthenticated) {
              _authRepository!.getToken().then((token) {
                if (token != null) {
                  _apiClient!.updateToken(token);
                }
              });
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              // Show loading while checking authentication status
              if (state is AuthInitial || state is AuthLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (state is AuthAuthenticated) {
                return MainNavigationScreen(user: state.user);
              }

              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
