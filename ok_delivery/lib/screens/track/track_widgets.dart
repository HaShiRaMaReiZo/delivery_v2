import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/package_model.dart';
import 'live_tracking_map_screen.dart';

class TrackHeader extends StatelessWidget {
  const TrackHeader({
    super.key,
    required this.totalCount,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefreshPressed,
    this.showBackButton = false,
  });

  final int totalCount;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefreshPressed;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.neutral900, AppTheme.neutral800],
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
              Row(
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Back',
                    ),
                  if (showBackButton) const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Track Packages',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalCount total packages',
                        style: const TextStyle(
                          color: AppTheme.yellow400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: onRefreshPressed,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    Icons.search,
                    color: AppTheme.neutral500,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    style: const TextStyle(
                      color: AppTheme.neutral900,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search by tracking number or name',
                      hintStyle: TextStyle(
                        color: AppTheme.neutral400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: onSearchChanged,
                    controller: TextEditingController(text: searchQuery)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: searchQuery.length),
                      ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrackFilterChips extends StatelessWidget {
  const TrackFilterChips({
    super.key,
    required this.activeFilter,
    required this.countAll,
    required this.countPending,
    required this.countPickup,
    required this.countTransit,
    required this.countDelivered,
    required this.onFilterChanged,
  });

  final String
  activeFilter; // 'all', 'pending', 'pickup', 'transit', 'delivered'
  final int countAll;
  final int countPending;
  final int countPickup;
  final int countTransit;
  final int countDelivered;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 20),
          _buildChip('all', 'All ($countAll)'),
          _buildChip('pending', 'Pending ($countPending)'),
          _buildChip('pickup', 'Pickup ($countPickup)'),
          _buildChip('transit', 'In Transit ($countTransit)'),
          _buildChip('delivered', 'Delivered ($countDelivered)'),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildChip(String value, String label) {
    final bool isActive = activeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onFilterChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.yellow400 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppTheme.yellow400 : AppTheme.neutral200,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.yellow400.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isActive ? AppTheme.neutral900 : AppTheme.neutral700,
            ),
          ),
        ),
      ),
    );
  }
}

class TrackPackageCard extends StatelessWidget {
  const TrackPackageCard({super.key, required this.package});

  final PackageModel package;

  String _mapStatusLabel(String? status) {
    if (status == null) return 'Pending Pickup';
    switch (status) {
      case 'registered':
      case 'assigned_to_rider':
        return 'Pending Pickup';
      case 'picked_up':
        return 'Ready for Pickup';
      case 'ready_for_delivery':
      case 'on_the_way':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'contact_failed':
      case 'return_to_office':
      case 'returned_to_merchant':
      case 'cancelled':
        return 'Delivery Failed';
      default:
        return status;
    }
  }

  Color _statusBgColor(String? status) {
    if (status == null) return AppTheme.neutral100;
    switch (status) {
      case 'registered':
      case 'assigned_to_rider':
        return AppTheme.neutral100;
      case 'picked_up':
      case 'ready_for_delivery':
      case 'on_the_way':
        return AppTheme.yellow50;
      case 'delivered':
        return AppTheme.neutral100;
      case 'contact_failed':
      case 'return_to_office':
      case 'returned_to_merchant':
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return AppTheme.neutral100;
    }
  }

  Color _statusBorderColor(String? status) {
    if (status == null) return AppTheme.neutral200;
    switch (status) {
      case 'picked_up':
      case 'ready_for_delivery':
      case 'on_the_way':
        return AppTheme.yellow200;
      case 'contact_failed':
      case 'return_to_office':
      case 'returned_to_merchant':
      case 'cancelled':
        return const Color(0xFFFECDD3);
      default:
        return AppTheme.neutral200;
    }
  }

  Color _statusTextColor(String? status) {
    if (status == null) return AppTheme.neutral700;
    switch (status) {
      case 'registered':
      case 'assigned_to_rider':
      case 'delivered':
        return AppTheme.neutral700;
      case 'picked_up':
      case 'ready_for_delivery':
      case 'on_the_way':
        return AppTheme.yellow700;
      case 'contact_failed':
      case 'return_to_office':
      case 'returned_to_merchant':
      case 'cancelled':
        return const Color(0xFFB91C1C);
      default:
        return AppTheme.neutral700;
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

  bool _isInTransit(String? status) {
    // Only show live tracking for on_the_way status
    // ready_for_delivery means package is at office, not yet picked up by rider
    return status == 'on_the_way';
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = _mapStatusLabel(package.status);
    final statusBg = _statusBgColor(package.status);
    final statusBorder = _statusBorderColor(package.status);
    final statusText = _statusTextColor(package.status);
    final paymentType = package.paymentType.toLowerCase() == 'cod'
        ? 'COD'
        : 'Prepaid';
    final isInTransit = _isInTransit(package.status);

    return GestureDetector(
      onTap: isInTransit
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LiveTrackingMapScreen(package: package),
                ),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutral900,
                        ),
                      ),
                      if (package.trackingCode != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          package.trackingCode!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: statusText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppTheme.neutral500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    package.deliveryAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.neutral600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Phone
            Row(
              children: [
                const Icon(
                  Icons.phone_in_talk_outlined,
                  size: 16,
                  color: AppTheme.neutral500,
                ),
                const SizedBox(width: 6),
                Text(
                  package.customerPhone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${package.amount.toStringAsFixed(0)} MMK',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: paymentType == 'COD'
                            ? AppTheme.yellow50
                            : AppTheme.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        paymentType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: paymentType == 'COD'
                              ? AppTheme.yellow700
                              : AppTheme.neutral600,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isInTransit) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.yellow50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.yellow200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: AppTheme.yellow700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Live',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.yellow700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _formatTimeAgo(package.updatedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
