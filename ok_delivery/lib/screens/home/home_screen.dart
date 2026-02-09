import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/package_model.dart';
import '../../repositories/package_repository.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/utils/date_utils.dart' as myanmar_date;
import 'home_widgets.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _packageRepository = PackageRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );

  int _registeredThisMonth = 0;
  int _pendingThisMonth = 0;
  int _inTransitThisMonth = 0;
  int _deliveredThisMonth = 0;
  double _revenueToday = 0.0;
  List<PackageModel> _recentPackages = [];
  int _draftCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load all packages (multiple pages if needed)
      final allPackages = <PackageModel>[];
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
          // If we got less than 20 packages, we've reached the end
          if (packages.length < 20) {
            hasMore = false;
          } else {
            currentPage++;
          }
        }
      }

      // Load drafts count
      try {
        final drafts = await _packageRepository.getDrafts();
        _draftCount = drafts.length;
      } catch (e) {
        // Ignore draft loading errors
        _draftCount = 0;
      }

      final now = myanmar_date.MyanmarDateUtils.getMyanmarNow();
      final today = DateTime(now.year, now.month, now.day);
      final currentMonth = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      int registeredThisMonth = 0;
      int pendingThisMonth = 0;
      int inTransitThisMonth = 0;
      int deliveredThisMonth = 0;
      double revenueToday = 0.0;

      // Get recent packages (sorted by updated_at, most recent first)
      final recentPackages = allPackages.where((p) => p.status != null).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      for (final package in allPackages) {
        // Count registered this month (using registered_at)
        if (package.registeredAt != null) {
          final registeredDate = myanmar_date.MyanmarDateUtils.toMyanmarTime(
            package.registeredAt!,
          );
          if (registeredDate.isAfter(
                currentMonth.subtract(const Duration(days: 1)),
              ) &&
              registeredDate.isBefore(nextMonth)) {
            registeredThisMonth++;
          }

          // Calculate revenue for today (sum of amounts registered today)
          final registeredDateOnly = DateTime(
            registeredDate.year,
            registeredDate.month,
            registeredDate.day,
          );
          if (registeredDateOnly.isAtSameMomentAs(today)) {
            revenueToday += package.amount;
          }
        }

        // Count statuses this month
        if (package.status != null) {
          final updatedDate = myanmar_date.MyanmarDateUtils.toMyanmarTime(
            package.updatedAt,
          );
          final isInCurrentMonth =
              updatedDate.isAfter(
                currentMonth.subtract(const Duration(days: 1)),
              ) &&
              updatedDate.isBefore(nextMonth);

          if (isInCurrentMonth) {
            switch (package.status) {
              case 'delivered':
                deliveredThisMonth++;
                break;
              case 'on_the_way':
              case 'ready_for_delivery':
                inTransitThisMonth++;
                break;
              case 'assigned_to_rider':
              case 'picked_up':
                // These are pending delivery
                pendingThisMonth++;
                break;
              default:
                if (package.status != 'cancelled' &&
                    package.status != 'returned_to_merchant') {
                  pendingThisMonth++;
                }
                break;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _registeredThisMonth = registeredThisMonth;
          _pendingThisMonth = pendingThisMonth;
          _inTransitThisMonth = inTransitThisMonth;
          _deliveredThisMonth = deliveredThisMonth;
          _revenueToday = revenueToday;
          _recentPackages = recentPackages.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchantName = widget.user.merchant?.businessName ?? widget.user.name;
    final merchantEmail =
        widget.user.merchant?.businessEmail ?? widget.user.email;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                HomeHeader(
                  merchantName: merchantName,
                  merchantEmail: merchantEmail,
                  isLoading: _isLoading,
                  registeredThisMonth: _registeredThisMonth,
                  revenueToday: _revenueToday,
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Quick action - Register package
                      const RegisterPackageCard(),
                      const SizedBox(height: 24),

                      // Status overview (3 cards)
                      StatusOverviewRow(
                        pendingCount: _pendingThisMonth,
                        deliveredCount: _deliveredThisMonth,
                        inTransitCount: _inTransitThisMonth,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Recent Activity
                      if (_recentPackages.isNotEmpty)
                        RecentActivitySection(recentPackages: _recentPackages),
                      if (_recentPackages.isNotEmpty)
                        const SizedBox(height: 24),

                      // Quick Actions
                      QuickActionsSection(draftCount: _draftCount),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
