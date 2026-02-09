import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/package_model.dart';
import '../register_package/register_package_screen.dart';
import '../draft/draft_screen.dart';
import '../track/track_screen.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.merchantName,
    required this.merchantEmail,
    required this.isLoading,
    required this.registeredThisMonth,
    required this.revenueToday,
  });

  final String merchantName;
  final String merchantEmail;
  final bool isLoading;
  final int registeredThisMonth;
  final double revenueToday;

  String _formatRevenue(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neutral900,
            AppTheme.neutral800,
            AppTheme.neutral900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                  Text(
                    'Welcome back,',
                    style: const TextStyle(
                      color: AppTheme.yellow400,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    merchantName,
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
                child: _HeaderStatCard(
                  title: 'Packages registered',
                  subtitle: "Today's Total",
                  value: isLoading ? '...' : registeredThisMonth.toString(),
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderStatCard(
                  title: 'MMK today',
                  subtitle: 'Revenue',
                  value: isLoading ? '...' : _formatRevenue(revenueToday),
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  const _HeaderStatCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.neutral300,
                  fontSize: 12,
                ),
              ),
              Icon(icon, color: AppTheme.yellow400, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppTheme.yellow400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class RegisterPackageCard extends StatelessWidget {
  const RegisterPackageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const RegisterPackageScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.yellow400, AppTheme.yellow500],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.yellow500.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.neutral900.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: AppTheme.neutral900,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Register New Package',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Quick registration',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.neutral700),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              color: AppTheme.neutral900,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class StatusOverviewRow extends StatelessWidget {
  const StatusOverviewRow({
    super.key,
    required this.pendingCount,
    required this.deliveredCount,
    required this.inTransitCount,
    required this.isLoading,
  });

  final int pendingCount;
  final int deliveredCount;
  final int inTransitCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: AppTheme.neutral900,
            ),
            const SizedBox(width: 8),
            Text(
              'Status Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.neutral900),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatusCard(
                label: 'Pending',
                count: isLoading ? '...' : pendingCount.toString(),
                icon: Icons.schedule,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatusCard(
                label: 'In Transit',
                count: isLoading ? '...' : inTransitCount.toString(),
                icon: Icons.local_shipping_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatusCard(
                label: 'Delivered',
                count: isLoading ? '...' : deliveredCount.toString(),
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final String count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.yellow600, size: 20),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.neutral500),
          ),
        ],
      ),
    );
  }
}

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key, required this.recentPackages});

  final List<PackageModel> recentPackages;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 20,
                  color: AppTheme.neutral900,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppTheme.neutral900),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TrackScreen()),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(color: AppTheme.yellow600, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentPackages
            .take(3)
            .map((pkg) => _RecentPackageCard(package: pkg)),
      ],
    );
  }
}

class _RecentPackageCard extends StatelessWidget {
  const _RecentPackageCard({required this.package});

  final PackageModel package;

  String _getStatusLabel(String? status) {
    if (status == null) return 'Pending';
    switch (status) {
      case 'delivered':
        return 'Delivered';
      case 'on_the_way':
      case 'ready_for_delivery':
        return 'In Transit';
      default:
        return 'Pending';
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return AppTheme.neutral600;
    switch (status) {
      case 'delivered':
        return AppTheme.neutral700;
      case 'on_the_way':
      case 'ready_for_delivery':
        return AppTheme.yellow700;
      default:
        return AppTheme.neutral600;
    }
  }

  Color _getStatusBgColor(String? status) {
    if (status == null) return AppTheme.neutral50;
    switch (status) {
      case 'delivered':
        return AppTheme.neutral100;
      case 'on_the_way':
      case 'ready_for_delivery':
        return AppTheme.yellow50;
      default:
        return AppTheme.neutral50;
    }
  }

  Color _getStatusBorderColor(String? status) {
    if (status == null) return AppTheme.neutral200;
    switch (status) {
      case 'on_the_way':
      case 'ready_for_delivery':
        return AppTheme.yellow200;
      default:
        return AppTheme.neutral200;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = _getStatusLabel(package.status);
    final statusColor = _getStatusColor(package.status);
    final statusBgColor = _getStatusBgColor(package.status);
    final statusBorderColor = _getStatusBorderColor(package.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      package.trackingCode ?? 'Draft',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusBorderColor),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTimeAgo(package.updatedAt),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral500,
                ),
              ),
              Text(
                '${package.amount.toStringAsFixed(0)} MMK',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.neutral900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key, required this.draftCount});

  final int draftCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppTheme.neutral900),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.drafts_outlined,
                title: 'Draft Packages',
                subtitle: '$draftCount drafts',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DraftScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.bar_chart_outlined,
                title: 'Analytics',
                subtitle: 'View reports',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TrackScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.yellow600, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}
