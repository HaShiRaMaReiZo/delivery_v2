import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PackageDetails {
  final String trackingNumber;
  final String customer;
  final String phone;
  final String destination;
  final String driverName;
  final String driverPhone;
  final String estimatedTime;
  final String distance;
  final String currentLocation;

  const PackageDetails({
    required this.trackingNumber,
    required this.customer,
    required this.phone,
    required this.destination,
    required this.driverName,
    required this.driverPhone,
    required this.estimatedTime,
    required this.distance,
    required this.currentLocation,
  });
}

class PackageDetailsSheet extends StatelessWidget {
  final PackageDetails packageDetails;
  final VoidCallback? onContactCustomer;
  final VoidCallback? onCallDriver;

  const PackageDetailsSheet({
    super.key,
    required this.packageDetails,
    this.onContactCustomer,
    this.onCallDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: AppTheme.neutral100, width: 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.yellow50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.yellow200),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: AppTheme.yellow600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageDetails.customer,
                        style: const TextStyle(
                          color: AppTheme.neutral900,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        packageDetails.trackingNumber,
                        style: const TextStyle(
                          color: AppTheme.neutral500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.yellow50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.yellow200),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.local_shipping_outlined,
                      color: AppTheme.yellow700,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'In Transit',
                      style: TextStyle(
                        color: AppTheme.yellow700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Destination
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.neutral50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.neutral100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.yellow400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: AppTheme.neutral900,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destination Address',
                        style: TextStyle(
                          color: AppTheme.neutral500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        packageDetails.destination,
                        style: const TextStyle(
                          color: AppTheme.neutral900,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Driver info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.neutral900, AppTheme.neutral800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppTheme.yellow400,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _driverInitials(packageDetails.driverName),
                          style: const TextStyle(
                            color: AppTheme.neutral900,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          packageDetails.driverName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Delivery Driver',
                          style: TextStyle(
                            color: AppTheme.neutral400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Material(
                  color: AppTheme.yellow400,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onCallDriver,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.phone,
                        color: AppTheme.neutral900,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Contact customer
          ElevatedButton.icon(
            onPressed: onContactCustomer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.neutral900,
              elevation: 0,
              side: const BorderSide(color: AppTheme.neutral900, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.phone, size: 20),
            label: const Text(
              'Contact Customer',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    bool isSmall = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neutral100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.neutral500, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.neutral500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: isSmall ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.neutral900,
              fontWeight: FontWeight.w700,
              fontSize: isSmall ? 13 : 15,
            ),
          ),
        ],
      ),
    );
  }

  String _driverInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.isNotEmpty ? parts.first[0] : '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.last.isNotEmpty ? parts.last[0] : '';
    final initials = '$first$last';
    return initials.isEmpty ? '?' : initials;
  }
}
