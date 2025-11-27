import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../bloc/location/location_bloc.dart';
import '../bloc/location/location_event.dart';
import 'home/home_page.dart';
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomePage(user: widget.user),
      const PackagesScreen(),
      const HistoryScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.darkBlue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Packages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
