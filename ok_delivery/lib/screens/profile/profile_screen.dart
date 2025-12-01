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

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final Future<void> Function(String)? onLanguageChanged;

  const ProfileScreen({super.key, required this.user, this.onLanguageChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepository = AuthRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );
  final _packageRepository = PackageRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );

  UserModel? _currentUser;
  int _totalPackages = 0;
  int _pendingPackages = 0;
  int _completedPackages = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
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

      for (final package in allPackages) {
        if (package.status != null &&
            package.status != 'delivered' &&
            package.status != 'cancelled' &&
            package.status != 'returned_to_merchant') {
          pending++;
        }
        if (package.status == 'delivered') {
          completed++;
        }
      }

      setState(() {
        _totalPackages = total;
        _pendingPackages = pending;
        _completedPackages = completed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBeige,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfileData,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.errorLoadingProfile,
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadProfileData,
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        AppLocalizations.of(context)!.manageYourAccount,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                    // User/Shop Owner Information Card
                    _buildUserInfoCard(context),

                    const SizedBox(height: 16),

                    // Shop Information Card
                    _buildShopInfoCard(context),

                    const SizedBox(height: 16),

                    // Settings and Notifications Card
                    _buildSettingsCard(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    final merchant = _currentUser?.merchant;
    final displayName = merchant?.businessName ?? _currentUser?.name ?? 'N/A';
    final role = AppLocalizations.of(context)!.shopOwner;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              // Name and Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Edit Button
              TextButton(
                onPressed: () {
                  // TODO: Navigate to edit profile screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!.editProfileFeatureComingSoon,
                      ),
                    ),
                  );
                },
                child: Text(
                  AppLocalizations.of(context)!.edit,
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Statistics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                value: _totalPackages.toString(),
                label: AppLocalizations.of(context)!.total,
                valueColor: AppTheme.black,
              ),
              _buildStatItem(
                context,
                value: _pendingPackages.toString(),
                label: AppLocalizations.of(context)!.pending,
                valueColor: AppTheme.primaryBlue,
              ),
              _buildStatItem(
                context,
                value: _completedPackages.toString(),
                label: AppLocalizations.of(context)!.completed,
                valueColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildShopInfoCard(BuildContext context) {
    final merchant = _currentUser?.merchant;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.shopInformation,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            icon: Icons.home,
            label: AppLocalizations.of(context)!.shopName,
            value: merchant?.businessName ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.phone,
            label: AppLocalizations.of(context)!.phoneNumber,
            value: merchant?.businessPhone ?? _currentUser?.phone ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.email,
            label: AppLocalizations.of(context)!.email,
            value: merchant?.businessEmail ?? _currentUser?.email ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.location_on,
            label: AppLocalizations.of(context)!.location,
            value: merchant?.businessAddress ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            context,
            icon: Icons.settings,
            title: AppLocalizations.of(context)!.settings,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onLanguageChanged: widget.onLanguageChanged,
                  ),
                ),
              );
              // Reload profile data after returning from settings
              if (mounted) {
                _loadProfileData();
              }
            },
          ),
          const Divider(height: 32),
          _buildSettingsItem(
            context,
            icon: Icons.notifications,
            title: AppLocalizations.of(context)!.notifications,
            onTap: () {
              // TODO: Navigate to notifications screen
              ScaffoldMessenger.of(context).showSnackBar(
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
          const Divider(height: 32),
          _buildSettingsItem(
            context,
            icon: Icons.logout,
            title: AppLocalizations.of(context)!.logout,
            onTap: () => _showLogoutDialog(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? Colors.red : AppTheme.primaryBlue;
    final textColor = isDestructive ? Colors.red : AppTheme.black;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
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
