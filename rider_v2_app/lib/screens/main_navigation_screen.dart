import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/user_model.dart';
import '../bloc/location/location_bloc.dart';
import '../bloc/location/location_event.dart';
import 'home/home_page.dart';
import 'home/bloc/home_bloc.dart';
import 'home/bloc/home_event.dart';
import 'home/repository/home_repository.dart';
import 'packages/packages_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final UserModel user;

  const MainNavigationScreen({super.key, required this.user});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _locationTrackingStarted = false;
  HomeBloc? _homeBloc;
  bool _homeBlocInitialized = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeHomeBloc();

    _screens = [
      HomePage(user: widget.user),
      const PackagesScreen(),
      HistoryScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];

    // Start location tracking automatically when rider logs in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_locationTrackingStarted) {
        if (kDebugMode) {
          debugPrint('========================================');
          debugPrint('MainNavigationScreen: initState postFrameCallback');
          debugPrint('MainNavigationScreen: Starting location tracking...');
          debugPrint('========================================');
        }
        try {
          final locationBloc = context.read<LocationBloc>();
          if (kDebugMode) {
            debugPrint(
              'MainNavigationScreen: LocationBloc found, adding start event',
            );
          }
          // Start location tracking without a package_id (general tracking)
          locationBloc.add(const LocationStartEvent(packageId: null));
          _locationTrackingStarted = true;
          if (kDebugMode) {
            debugPrint('MainNavigationScreen: LocationStartEvent dispatched');
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint(
              'MainNavigationScreen: ERROR starting location tracking: $e',
            );
            debugPrint('MainNavigationScreen: Stack trace: $stackTrace');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            'MainNavigationScreen: Location tracking already started, skipping',
          );
        }
      }
    });
  }

  Future<void> _initializeHomeBloc() async {
    // Create HomeBloc once at navigation level - persists across tab switches
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    final apiClient = ApiClient.create(
      baseUrl: ApiEndpoints.baseUrl,
      token: savedToken,
    );
    _homeBloc = HomeBloc(HomeRepository(apiClient));

    if (mounted) {
      setState(() {
        _homeBlocInitialized = true;
      });
      // Fetch data once after UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _homeBloc != null) {
          _homeBloc!.add(HomeFetchRequested());
        }
      });
    }
  }

  @override
  void dispose() {
    _homeBloc?.close();
    super.dispose();
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData filledIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : icon,
              size: 24,
              color: isSelected ? AppTheme.yellow500 : AppTheme.neutral400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.yellow500 : AppTheme.neutral400,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.yellow500,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provide HomeBloc at navigation level so it persists across tab switches
    if (!_homeBlocInitialized || _homeBloc == null) {
      return Scaffold(
        backgroundColor: AppTheme.neutral50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: _homeBloc!,
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.neutral200, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    filledIcon: Icons.home,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.inventory_2_outlined,
                    filledIcon: Icons.inventory_2,
                    label: 'Packages',
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.history_outlined,
                    filledIcon: Icons.history,
                    label: 'History',
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    filledIcon: Icons.person,
                    label: 'Profile',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
