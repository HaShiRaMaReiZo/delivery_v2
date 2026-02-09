import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/user_model.dart';
import '../../models/package_model.dart';
import 'bloc/home_bloc.dart';
import 'bloc/home_event.dart';
import 'bloc/home_state.dart';

class HomePage extends StatefulWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // HomeBloc is provided by MainNavigationScreen (persists across navigation)
    // Data is cached in memory - only fetch if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<HomeBloc>();
        final state = bloc.state;
        // Only fetch if we're in initial state (first load, not cached yet)
        if (state is HomeInitial) {
          bloc.add(HomeFetchRequested());
        }
        // If already loaded, UI will show cached data immediately (UI-First)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // UI-First: HomeBloc is provided by MainNavigationScreen (persists across navigation)
    // Just consume it from context - data is cached in memory
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            // UI-First: Always render UI structure, show skeleton when loading
            final isLoading = state is HomeLoading || state is HomeInitial;
            final isError = state is HomeError;
            final errorMessage = switch (state) {
              HomeError(:final message) => message,
              _ => '',
            };
            final loadedState = state is HomeLoaded ? state : null;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(HomeFetchRequested());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header - always visible, show skeleton values when loading
                    _buildHeader(context, loadedState),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Overview cards - show skeleton when loading
                          Row(
                            children: [
                              Expanded(
                                child: isLoading
                                    ? _buildOverviewCardSkeleton()
                                    : _buildOverviewCard(
                                        title: 'Active deliveries',
                                        value:
                                            loadedState?.assignedDeliveries ??
                                            0,
                                        icon: Icons.local_shipping_outlined,
                                        accentColor: AppTheme.yellow500,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: isLoading
                                    ? _buildOverviewCardSkeleton()
                                    : _buildOverviewCard(
                                        title: 'Pickups assigned',
                                        value:
                                            loadedState?.assignedPickups ?? 0,
                                        icon: Icons.inventory_2_outlined,
                                        accentColor: AppTheme.neutral100,
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Delivered card - show skeleton when loading
                          isLoading
                              ? _buildDeliveredCardSkeleton()
                              : _buildDeliveredCard(
                                  context,
                                  deliveredThisMonth:
                                      loadedState?.deliveredThisMonth ?? 0,
                                ),
                          const SizedBox(height: 24),
                          // Today's Tasks Section
                          _buildTodaysTasksSection(
                            context,
                            loadedState,
                            isLoading,
                          ),
                          // Error banner (non-blocking, shows at bottom)
                          if (isError) ...[
                            const SizedBox(height: 16),
                            _buildErrorBanner(context, errorMessage),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HomeLoaded? state) {
    final riderName = widget.user.name;
    final isLoading = state == null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF020617), // near black (slate-950-ish)
            Color(0xFF111827), // neutral900
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back,',
                    style: TextStyle(color: AppTheme.yellow400, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    riderName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: isLoading
                    ? _HeaderStatCardSkeleton()
                    : _HeaderStatCard(
                        title: 'Assigned deliveries',
                        subtitle: 'Current',
                        value: state.assignedDeliveries.toString(),
                        icon: Icons.local_shipping_outlined,
                        isFirst: true, // Yellow gradient card
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isLoading
                    ? _HeaderStatCardSkeleton()
                    : _HeaderStatCard(
                        title: 'Delivered',
                        subtitle: 'This month',
                        value: state.deliveredThisMonth.toString(),
                        icon: Icons.check_circle_outline,
                        isFirst: false, // Dark gradient card
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required int value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppTheme.neutral900),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppTheme.neutral500),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveredCard(
    BuildContext context, {
    required int deliveredThisMonth,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.yellow400, AppTheme.yellow500],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.yellow500.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.neutral900.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppTheme.neutral900,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This month\'s performance',
                  style: TextStyle(
                    color: AppTheme.neutral900,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$deliveredThisMonth deliveries completed',
                  style: const TextStyle(
                    color: AppTheme.neutral900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Skeleton widgets for loading states
  Widget _buildOverviewCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.neutral200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveredCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.neutral200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.neutral300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.neutral300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 140,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.neutral300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[900], fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<HomeBloc>().add(HomeFetchRequested());
            },
            child: Text(
              'Retry',
              style: TextStyle(color: Colors.red[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysTasksSection(
    BuildContext context,
    HomeLoaded? state,
    bool isLoading,
  ) {
    final packages = state?.upcomingPackages ?? [];
    final hasPackages = packages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.yellow400.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.task_alt,
                  color: AppTheme.neutral900,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Today's Tasks",
                style: TextStyle(
                  color: AppTheme.neutral900,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!isLoading && hasPackages)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${packages.length}',
                    style: const TextStyle(
                      color: AppTheme.yellow400,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Package List
        if (isLoading)
          Column(
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTaskCardSkeleton(),
              ),
            ),
          )
        else if (!hasPackages)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: AppTheme.neutral300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All caught up!',
                    style: TextStyle(color: AppTheme.neutral500, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No tasks for today',
                    style: TextStyle(color: AppTheme.neutral400, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: packages.map((package) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTaskCard(context, package),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, PackageModel package) {
    final isDelivery = package.isForDelivery;

    return GestureDetector(
      onTap: () {
        // Navigate to packages tab when tapped
        // You can enhance this later to navigate to specific package detail
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDelivery
                    ? AppTheme.yellow400.withValues(alpha: 0.15)
                    : AppTheme.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDelivery
                    ? Icons.local_shipping_outlined
                    : Icons.inventory_2_outlined,
                color: AppTheme.neutral900,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          package.trackingCode ?? 'Package #${package.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.neutral900,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTaskStatusColor(
                            package.status,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getTaskStatusLabel(package.status, isDelivery),
                          style: TextStyle(
                            color: _getTaskStatusColor(package.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isDelivery
                        ? package.customerName
                        : package.merchant?.businessName ?? 'Merchant',
                    style: const TextStyle(
                      color: AppTheme.neutral600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (package.assignedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Assigned: ${MyanmarDateUtils.formatDateTime(package.assignedAt!)}',
                      style: const TextStyle(
                        color: AppTheme.neutral400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Arrow
            Icon(Icons.chevron_right, color: AppTheme.neutral400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.neutral200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTaskStatusColor(String? status) {
    switch (status) {
      case 'ready_for_delivery':
        return AppTheme.yellow500;
      case 'on_the_way':
        return AppTheme.yellow600;
      case 'assigned_to_rider':
        return AppTheme.neutral600;
      default:
        return AppTheme.neutral500;
    }
  }

  String _getTaskStatusLabel(String? status, bool isDelivery) {
    if (isDelivery) {
      switch (status) {
        case 'ready_for_delivery':
          return 'Ready';
        case 'on_the_way':
          return 'In Transit';
        default:
          return 'Delivery';
      }
    } else {
      switch (status) {
        case 'assigned_to_rider':
          return 'Pickup';
        default:
          return 'Pickup';
      }
    }
  }
}

class _HeaderStatCard extends StatelessWidget {
  const _HeaderStatCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    this.isFirst = false,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final bool isFirst; // First card gets yellow gradient, second gets dark

  @override
  Widget build(BuildContext context) {
    final isYellowCard = isFirst;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: isYellowCard
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFACC15), // yellow400
                  Color(0xFFEAB308), // yellow500
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // slate-900
                  Color(0xFF020617), // slate-950
                ],
              ),
        boxShadow: isYellowCard
            ? [
                BoxShadow(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
        border: !isYellowCard
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: isYellowCard
                      ? Colors.black.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isYellowCard
                      ? Colors.black.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isYellowCard ? Colors.black : Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: isYellowCard ? Colors.black : Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: isYellowCard
                  ? const Color(0xFF1F2937) // neutral800-ish
                  : const Color(0xFF9CA3AF), // neutral400-ish
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatCardSkeleton extends StatelessWidget {
  const _HeaderStatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.neutral300.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.neutral300.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 30,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.neutral300.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
