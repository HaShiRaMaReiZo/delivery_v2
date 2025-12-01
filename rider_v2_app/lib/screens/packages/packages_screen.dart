import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/package_model.dart';
import '../../models/merchant_model.dart';
import 'bloc/packages_bloc.dart';
import 'bloc/packages_event.dart';
import 'bloc/packages_state.dart';
import 'repository/packages_repository.dart';
import 'rider_pickup_screen.dart';
import 'package_detail_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  PackagesBloc? _packagesBloc;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeBloc();
  }

  Future<void> _initializeBloc() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    final apiClient = ApiClient.create(
      baseUrl: ApiEndpoints.baseUrl,
      token: savedToken,
    );
    _packagesBloc = PackagesBloc(PackagesRepository(apiClient))
      ..add(const PackagesFetchRequested());

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _packagesBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _packagesBloc == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightBeige,
        appBar: AppBar(
          title: const Text('Packages'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: _packagesBloc!,
      child: Scaffold(
        backgroundColor: AppTheme.lightBeige,
        appBar: AppBar(
          title: const Text('Packages'),
          automaticallyImplyLeading: false,
        ),
        body: BlocListener<PackagesBloc, PackagesState>(
          listener: (context, state) {
            if (state is PackagesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: BlocBuilder<PackagesBloc, PackagesState>(
            builder: (context, state) {
              if (state is PackagesLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is PackagesError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<PackagesBloc>().add(
                            const PackagesFetchRequested(),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is PackagesLoaded) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<PackagesBloc>().add(
                      const PackagesFetchRequested(),
                    );
                    // Wait a bit for the state to update
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: CustomScrollView(
                    slivers: [
                      // Pickup Section (Fixed at top)
                      SliverToBoxAdapter(
                        child: _buildPickupSection(context, state),
                      ),

                      // Assigned Deliveries Section Header
                      SliverToBoxAdapter(
                        child: _buildSectionHeader(
                          context,
                          title: 'Assigned Deliveries',
                          count: state.assignedDeliveries.length,
                          icon: Icons.local_shipping,
                        ),
                      ),

                      // Assigned Deliveries List
                      if (state.assignedDeliveries.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(
                            context,
                            message: 'No assigned deliveries',
                            icon: Icons.inbox_outlined,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return _buildPackageCard(
                                context,
                                state.assignedDeliveries[index],
                                isDelivery: true,
                              );
                            }, childCount: state.assignedDeliveries.length),
                          ),
                        ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPickupSection(BuildContext context, PackagesLoaded state) {
    final merchants = state.pickupsByMerchant.keys.toList();
    final totalPickups = state.pickups.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.inventory, color: AppTheme.darkBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                'Pickup',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  totalPickups.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Merchant Cards (Fixed height, scrollable horizontally)
          merchants.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No pickups assigned',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: merchants.length,
                    itemBuilder: (context, index) {
                      final merchant = merchants[index];
                      final merchantPackages =
                          state.pickupsByMerchant[merchant]!;
                      return _buildMerchantCard(
                        context,
                        merchant,
                        merchantPackages,
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(
    BuildContext context,
    MerchantModel merchant,
    List<PackageModel> packages,
  ) {
    return GestureDetector(
      onTap: () {
        // Read the BLoC from the current context before navigation
        final packagesBloc = context.read<PackagesBloc>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: packagesBloc,
              child: MerchantPickupScreen(
                merchant: merchant,
                packages: packages,
              ),
            ),
          ),
        ).then((_) {
          // Refresh packages when returning from pickup screen
          if (context.mounted) {
            context.read<PackagesBloc>().add(const PackagesFetchRequested());
          }
        });
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: AppTheme.darkBlue,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${packages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  merchant.businessName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (merchant.businessAddress != null) ...[
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    merchant.businessAddress!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tap to view',
                    style: TextStyle(
                      color: AppTheme.darkBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppTheme.darkBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.primaryBlue.withOpacity(0.1),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.darkBlue, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.darkBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String message,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    PackageModel package, {
    required bool isDelivery,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to package detail screen
          final packagesBloc = context.read<PackagesBloc>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: packagesBloc,
                child: PackageDetailScreen(package: package),
              ),
            ),
          ).then((_) {
            // Refresh packages when returning
            if (context.mounted) {
              context.read<PackagesBloc>().add(const PackagesFetchRequested());
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
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

              // Delivery address or merchant info
              if (isDelivery)
                _buildInfoRow(Icons.location_on, package.deliveryAddress)
              else if (package.merchant != null)
                _buildInfoRow(Icons.store, package.merchant!.businessName),

              if (isDelivery && package.merchant != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.store,
                  'From: ${package.merchant!.businessName}',
                ),
              ],

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

              // Action Buttons (only for delivery packages)
              if (isDelivery) ...[
                const SizedBox(height: 16),
                _buildActionButtons(context, package),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, PackageModel package) {
    final bloc = context.read<PackagesBloc>();
    final state = bloc.state;
    final isLoading =
        state is PackagesLoaded &&
        state.isActionLoading &&
        state.actionPackageId == package.id;

    // Determine which buttons to show based on status
    if (package.status == 'assigned_to_rider') {
      // Check if this is a delivery assignment (not pickup)
      if (package.isForDelivery) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading
                ? null
                : () {
                    bloc.add(PackageReceiveFromOfficeRequested(package.id));
                  },
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.inventory_2, size: 18),
            label: Text(isLoading ? 'Receiving...' : 'Receive from Office'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      }
    } else if (package.status == 'ready_for_delivery') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () {
                  bloc.add(PackageStartDeliveryRequested(package.id));
                },
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.directions_bike, size: 18),
          label: Text(isLoading ? 'Starting...' : 'Start Delivery'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    } else if (package.status == 'on_the_way') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () {
                      _showMarkDeliveredDialog(context, package);
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle, size: 18),
              label: const Text('Mark as Delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          _showContactCustomerDialog(context, package);
                        },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Contact'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.darkBlue,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          _showReturnToOfficeDialog(context, package);
                        },
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Return'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showMarkDeliveredDialog(BuildContext context, PackageModel package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Delivered'),
        content: Text(
          'Confirm delivery of ${package.trackingCode ?? 'Package #${package.id}'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PackagesBloc>().add(
                PackageMarkDeliveredRequested(package.id),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showContactCustomerDialog(BuildContext context, PackageModel package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Customer: ${package.customerName}'),
            Text('Phone: ${package.customerPhone}'),
            const SizedBox(height: 16),
            const Text('Was the contact successful?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PackagesBloc>().add(
                PackageContactCustomerRequested(package.id, 'failed'),
              );
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Failed'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PackagesBloc>().add(
                PackageContactCustomerRequested(package.id, 'success'),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Success'),
          ),
        ],
      ),
    );
  }

  void _showReturnToOfficeDialog(BuildContext context, PackageModel package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return to Office'),
        content: Text(
          'Return ${package.trackingCode ?? 'Package #${package.id}'} to office?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PackagesBloc>().add(
                PackageReturnToOfficeRequested(package.id),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Return'),
          ),
        ],
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
