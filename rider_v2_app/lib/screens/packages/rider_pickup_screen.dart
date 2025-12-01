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
        backgroundColor: AppTheme.lightBeige,
        appBar: AppBar(
          title: Text(widget.merchant.businessName),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // Merchant Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: AppTheme.darkBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.merchant.businessName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkBlue,
                                  ),
                            ),
                            if (widget.merchant.businessAddress != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.merchant.businessAddress!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.packages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.merchant.businessPhone != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          widget.merchant.businessPhone!,
                          style: TextStyle(
                            color: Colors.grey[800],
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
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
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check_circle, size: 24),
                          label: Text(
                            isLoading
                                ? 'Confirming...'
                                : 'Confirm Pickup (${widget.packages.length} packages)',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with tracking code and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (package.trackingCode != null)
                  Text(
                    package.trackingCode!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                    ),
                  )
                else
                  Text(
                    'Package #${package.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(package.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusLabel(package.status),
                    style: TextStyle(
                      color: _getStatusColor(package.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer info
            _buildInfoRow(Icons.person, package.customerName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, package.customerPhone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, package.deliveryAddress),

            const SizedBox(height: 12),

            // Payment info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      package.paymentType == 'cod'
                          ? Icons.money
                          : Icons.credit_card,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      package.paymentType.toUpperCase(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '${package.amount.toStringAsFixed(0)} MMK',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),

            // Timestamp
            if (package.assignedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Assigned: ${MyanmarDateUtils.formatDateTime(package.assignedAt!)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[800], fontSize: 14),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ready_for_delivery':
        return Colors.blue;
      case 'on_the_way':
        return Colors.orange;
      case 'assigned_to_rider':
        return Colors.purple;
      case 'picked_up':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
