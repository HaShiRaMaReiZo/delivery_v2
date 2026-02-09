import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/package_repository.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import 'settings_screen.dart';
import 'profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final Future<void> Function(String)? onLanguageChanged;

  const ProfileScreen({super.key, required this.user, this.onLanguageChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  // Simple in-memory cache for the session to avoid re-calling APIs on tab switch
  static UserModel? _cachedUser;
  static int _cachedTotalPackages = 0;
  static int _cachedPendingPackages = 0;
  static int _cachedCompletedPackages = 0;
  static double _cachedMonthlyRevenue = 0.0;
  static int _cachedMonthlyDeliveries = 0;
  static int _cachedSuccessPercent = 0;
  static bool _cacheLoaded = false;

  final _authRepository = AuthRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );
  final _packageRepository = PackageRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );

  // _hasLoaded is informational; actual guard is _cacheLoaded
  bool _hasLoaded = false;
  UserModel? _currentUser;
  int _totalPackages = 0;
  // Stats kept for potential future UI (currently unused)
  int _pendingPackages = 0;
  int _completedPackages = 0;
  double _rating = 4.8; // Default rating, can be calculated from reviews later
  int _successPercent = 92; // Default, can be calculated from delivered/total
  double _monthlyRevenue = 0.0;
  int _monthlyDeliveries = 0;
  bool _isLoading = false;
  bool _isFetching = false;
  String? _error;
  bool _isPullToRefresh = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadProfileData();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadProfileData({bool forceRefresh = false}) async {
    // Use cached data if available and not forcing refresh
    if (_cacheLoaded && !forceRefresh) {
      setState(() {
        _currentUser = _cachedUser ?? _currentUser;
        _totalPackages = _cachedTotalPackages;
        _pendingPackages = _cachedPendingPackages;
        _completedPackages = _cachedCompletedPackages;
        _monthlyRevenue = _cachedMonthlyRevenue;
        _monthlyDeliveries = _cachedMonthlyDeliveries;
        _successPercent = _cachedSuccessPercent;
        _isLoading = false;
        _hasLoaded = true;
      });
      return;
    }

    // If already loading, skip duplicate calls
    if (_isFetching) return;

    _isFetching = true;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load fresh user data
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
      }

      // Load all packages to calculate statistics
      final allPackages = <dynamic>[];
      int currentPage = 1;
      bool hasMore = true;

      while (hasMore) {
        final packages = await _packageRepository.getPackages(
          page: currentPage,
        );
        if (packages.isEmpty) {
          hasMore = false;
        } else {
          allPackages.addAll(packages);
          if (packages.length < 20) {
            hasMore = false;
          } else {
            currentPage++;
          }
        }
      }

      // Calculate statistics
      int total = allPackages.length;
      int pending = 0;
      int completed = 0;
      double monthlyRevenue = 0.0;
      int monthlyDeliveries = 0;
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);

      for (final package in allPackages) {
        if (package.status != null &&
            package.status != 'delivered' &&
            package.status != 'cancelled' &&
            package.status != 'returned_to_merchant') {
          pending++;
        }
        if (package.status == 'delivered') {
          completed++;
          // Calculate monthly stats
          if (package.deliveredAt != null) {
            if (package.deliveredAt!.isAfter(thisMonthStart) ||
                package.deliveredAt!.isAtSameMomentAs(thisMonthStart)) {
              monthlyDeliveries++;
              monthlyRevenue += package.amount;
            }
          }
        }
      }

      // Calculate success percent
      int successPercent = total > 0 ? ((completed / total) * 100).round() : 0;

      setState(() {
        _totalPackages = total;
        _pendingPackages = pending;
        _completedPackages = completed;
        _monthlyRevenue = monthlyRevenue;
        _monthlyDeliveries = monthlyDeliveries;
        _successPercent = successPercent;
        _isLoading = false;
        _hasLoaded = true;
        // save cache
        _cachedUser = _currentUser;
        _cachedTotalPackages = total;
        _cachedPendingPackages = pending;
        _cachedCompletedPackages = completed;
        _cachedMonthlyRevenue = monthlyRevenue;
        _cachedMonthlyDeliveries = monthlyDeliveries;
        _cachedSuccessPercent = successPercent;
        _cacheLoaded = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    } finally {
      _isFetching = false;
    }
  }

  String _formatRevenue(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _getTrendText() {
    // This is a placeholder - in real app, compare with previous month
    return '23% increase from last month';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final merchant = _currentUser?.merchant ?? widget.user.merchant;
    final displayName =
        merchant?.businessName ?? _currentUser?.name ?? widget.user.name;
    // Always show user's email first, then merchant business email as fallback
    final email = _currentUser?.email ?? widget.user.email;

    // When profile is loading for the very first time, show full-screen loader.
    final bool _showFullScreenLoader = _isLoading && !_hasLoaded;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: _showFullScreenLoader
          ? const Center(child: CircularProgressIndicator())
          : _error != null && !_hasLoaded
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.errorLoadingProfile,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _loadProfileData(forceRefresh: true),
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    // Custom Header
                    Stack(
                      children: [
                        ProfileHeader(
                          displayName: displayName,
                          email: email,
                          totalPackages: _totalPackages,
                          rating: _rating,
                          successPercent: _successPercent,
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 24,
                          right: 24,
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => SettingsScreen(
                                    onLanguageChanged: widget.onLanguageChanged,
                                  ),
                                ),
                              );
                              if (mounted) {
                                _loadProfileData(forceRefresh: true);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    // Content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          if (mounted) {
                            setState(() {
                              _isPullToRefresh = true;
                            });
                          }
                          try {
                            await _loadProfileData(forceRefresh: true);
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isPullToRefresh = false;
                              });
                            }
                          }
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              // Performance Card
                              PerformanceCard(
                                totalDeliveries: _monthlyDeliveries,
                                revenue:
                                    '${_formatRevenue(_monthlyRevenue)} MMK',
                                trendText: _getTrendText(),
                              ),
                              const SizedBox(height: 24),
                              // Account Section
                              ProfileSection(
                                title: 'ACCOUNT',
                                items: [
                                  ProfileMenuItem(
                                    icon: Icons.person,
                                    title: 'Edit Profile',
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.editProfileFeatureComingSoon,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  ProfileMenuItem(
                                    icon: Icons.shield,
                                    title: 'Privacy & Security',
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Privacy & Security feature coming soon',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  ProfileMenuItem(
                                    icon: Icons.notifications,
                                    title: 'Notifications',
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.notificationsFeatureComingSoon,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Support Section
                              ProfileSection(
                                title: 'SUPPORT',
                                items: [
                                  ProfileMenuItem(
                                    icon: Icons.help_outline,
                                    title: 'Help & Support',
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Help & Support coming soon',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  ProfileMenuItem(
                                    icon: Icons.info_outline,
                                    title: 'About',
                                    subtitle: 'v1.0.0',
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('About'),
                                          content: const Text(
                                            'OK Delivery v1.0.0',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Logout Button
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.neutral200,
                                    width: 2,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showLogoutDialog(context),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.logout,
                                            color: AppTheme.neutral900,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.logout,
                                            style: const TextStyle(
                                              color: AppTheme.neutral900,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLoading && _hasLoaded && !_isPullToRefresh)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.03),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.logout),
          content: Text(AppLocalizations.of(context)!.logoutConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Access AuthBloc from the root context
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        );
      },
    );
  }
}
