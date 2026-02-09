import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'register_package_screen.dart';

class RegisterPackageHeader extends StatelessWidget {
  final int packageCount;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  const RegisterPackageHeader({
    super.key,
    required this.packageCount,
    required this.onBack,
    required this.onSubmit,
    required this.isSubmitting,
  });

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
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Register Package',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$packageCount in queue',
                    style: const TextStyle(
                      color: AppTheme.yellow400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(isSubmitting ? 'Submitting...' : 'Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.yellow400,
                foregroundColor: AppTheme.neutral900,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PackageQueueSummary extends StatelessWidget {
  final int packageCount;
  final double totalAmount;

  const PackageQueueSummary({
    super.key,
    required this.packageCount,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.yellow400, AppTheme.yellow500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.yellow400.withValues(alpha: 0.3),
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
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2,
                    color: AppTheme.neutral900,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Package Queue',
                    style: TextStyle(
                      color: AppTheme.neutral900,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutral900,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$packageCount packages',
                  style: const TextStyle(
                    color: AppTheme.yellow400,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                totalAmount.toStringAsFixed(0),
                style: const TextStyle(
                  color: AppTheme.neutral900,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'MMK Total',
                style: TextStyle(color: AppTheme.neutral700, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QueuedPackageCard extends StatelessWidget {
  final PackageWithImage package;
  final int index;
  final VoidCallback onRemove;

  const QueuedPackageCard({
    super.key,
    required this.package,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.yellow50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppTheme.yellow700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
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
                            package.package.customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.neutral900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            package.package.customerPhone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: AppTheme.neutral400,
                      onPressed: onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.neutral400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        package.package.deliveryAddress,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.neutral600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            package.package.paymentType.toLowerCase() == 'cod'
                            ? AppTheme.yellow50
                            : AppTheme.neutral100,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              package.package.paymentType.toLowerCase() == 'cod'
                              ? AppTheme.yellow200
                              : AppTheme.neutral200,
                        ),
                      ),
                      child: Text(
                        package.package.paymentType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color:
                              package.package.paymentType.toLowerCase() == 'cod'
                              ? AppTheme.yellow700
                              : AppTheme.neutral700,
                        ),
                      ),
                    ),
                    Text(
                      '${package.package.amount.toStringAsFixed(0)} MMK',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HelpTipBox extends StatelessWidget {
  const HelpTipBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.yellow50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.yellow200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.yellow600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Tip',
                  style: TextStyle(
                    color: AppTheme.neutral900,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add multiple packages to queue and submit them all at once to save time.',
                  style: TextStyle(color: AppTheme.neutral600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
