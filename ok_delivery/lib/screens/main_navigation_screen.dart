import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../models/user_model.dart';
import 'home/home_screen.dart';
import 'draft/draft_screen.dart';
import 'track/track_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final UserModel user;
  final Future<void> Function(String)? onLanguageChanged;

  const MainNavigationScreen({
    super.key,
    required this.user,
    this.onLanguageChanged,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(user: widget.user),
      const DraftScreen(),
      const TrackScreen(),
      ProfileScreen(
        user: widget.user,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.neutral200, width: 1)),
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
                  label: AppLocalizations.of(context)!.home,
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.drafts_outlined,
                  filledIcon: Icons.drafts,
                  label: AppLocalizations.of(context)!.draft,
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.location_on_outlined,
                  filledIcon: Icons.location_on,
                  label: AppLocalizations.of(context)!.track,
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  filledIcon: Icons.person,
                  label: AppLocalizations.of(context)!.profile,
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              color: isSelected ? const Color(0xFFEAB308) : AppTheme.neutral400,
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
}
