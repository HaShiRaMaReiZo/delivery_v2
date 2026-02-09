import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/merchant_model.dart';
import '../../models/package_model.dart';
import 'bloc/packages_bloc.dart';
import 'bloc/packages_event.dart';
import 'bloc/packages_state.dart';

class MerchantPickupScreen extends StatefulWidget {
  final MerchantModel merchant;
  final List<PackageModel> packages;

  const MerchantPickupScreen({
    super.key,
    required this.merchant,
    required this.packages,
  });

  @override
  State<MerchantPickupScreen> createState() => _MerchantPickupScreenState();
}

class _MerchantPickupScreenState extends State<MerchantPickupScreen> {
  bool _wasLoading = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PackagesBloc, PackagesState>(
      listenWhen: (previous, current) {
        // Track loading state changes
        if (previous is PackagesLoaded && current is PackagesLoaded) {
          final wasLoading = previous.isActionLoading;
          final isLoading = current.isActionLoading;
          if (wasLoading && !isLoading) {
            _wasLoading = true;
            return true;
          }
        }
        return current is PackagesError;
      },
      listener: (context, state) {
        if (state is PackagesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is PackagesLoaded && _wasLoading) {
          // Action completed successfully
          _wasLoading = false; // Reset flag
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pickup confirmed successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate back after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.neutral50,
        appBar: AppBar(
          title: Text(
            widget.merchant.businessName,
            style: const TextStyle(
              color: AppTheme.neutral900,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          backgroundColor: AppTheme.neutral50,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: AppTheme.neutral900,
          iconTheme: const IconThemeData(color: AppTheme.neutral900),
        ),
        body: Column(
          children: [
            // Merchant Info Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.neutral200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.yellow400.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store,
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
                              widget.merchant.businessName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.neutral900,
                                fontSize: 18,
                              ),
                            ),
                            if (widget.merchant.businessAddress != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.merchant.businessAddress!,
                                style: const TextStyle(
                                  color: AppTheme.neutral600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.yellow500,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${widget.packages.length}',
                            style: const TextStyle(
                              color: AppTheme.neutral900,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.merchant.businessPhone != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: AppTheme.neutral600),
                        const SizedBox(width: 8),
                        Text(
                          widget.merchant.businessPhone!,
                          style: const TextStyle(
                            color: AppTheme.neutral700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Packages List
            Expanded(
              child: widget.packages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No packages to pick up',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: widget.packages.length,
                      itemBuilder: (context, index) {
                        return _buildPackageCard(
                          context,
                          widget.packages[index],
                        );
                      },
                    ),
            ),

            // Confirm Pickup Button (Fixed at bottom)
            if (widget.packages.isNotEmpty &&
                widget.packages.every(
                  (pkg) => pkg.status == 'assigned_to_rider',
                ))
              BlocBuilder<PackagesBloc, PackagesState>(
                builder: (context, state) {
                  final isLoading =
                      state is PackagesLoaded && state.isActionLoading;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: AppTheme.neutral200, width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.read<PackagesBloc>().add(
                                    PackageConfirmPickupRequested(
                                      widget.merchant.id,
                                    ),
                                  );
                                },
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.neutral900,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check_circle, size: 24),
                          label: Text(
                            isLoading
                                ? 'Confirming...'
                                : 'Confirm Pickup (${widget.packages.length} packages)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.yellow500,
                            foregroundColor: AppTheme.neutral900,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, PackageModel package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with tracking code and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  package.trackingCode ?? 'Package #${package.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral900,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.yellow500.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(package.status),
                  style: const TextStyle(
                    color: AppTheme.neutral900,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Customer info
          _buildInfoRow(Icons.person_outline, package.customerName),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.phone_outlined, package.customerPhone),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.location_on_outlined, package.deliveryAddress),

          const SizedBox(height: 16),

          // Payment info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    package.paymentType == 'cod'
                        ? Icons.money_outlined
                        : Icons.credit_card_outlined,
                    size: 16,
                    color: AppTheme.neutral600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    package.paymentType.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.neutral600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '${package.amount.toStringAsFixed(0)} MMK',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          // Timestamp
          if (package.assignedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Assigned: ${MyanmarDateUtils.formatDateTime(package.assignedAt!)}',
              style: const TextStyle(color: AppTheme.neutral500, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.neutral600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.neutral700, fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'ready_for_delivery':
        return 'Ready';
      case 'on_the_way':
        return 'On the way';
      case 'assigned_to_rider':
        return 'Assigned';
      case 'picked_up':
        return 'Picked up';
      default:
        return status ?? 'Unknown';
    }
  }
}
