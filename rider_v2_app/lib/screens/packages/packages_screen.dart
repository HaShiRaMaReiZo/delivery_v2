import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/package_model.dart';
import 'bloc/packages_bloc.dart';
import 'bloc/packages_event.dart';
import 'bloc/packages_state.dart';
import 'repository/packages_repository.dart';

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
        body: BlocBuilder<PackagesBloc, PackagesState>(
          builder: (context, state) {
            if (state is PackagesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PackagesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Assigned Deliveries Section
                      _buildSectionHeader(
                        context,
                        title: 'Assigned Deliveries',
                        count: state.assignedDeliveries.length,
                        icon: Icons.local_shipping,
                      ),
                      if (state.assignedDeliveries.isEmpty)
                        _buildEmptyState(
                          context,
                          message: 'No assigned deliveries',
                          icon: Icons.inbox_outlined,
                        )
                      else
                        ...state.assignedDeliveries.map(
                          (pkg) =>
                              _buildPackageCard(context, pkg, isDelivery: true),
                        ),

                      const SizedBox(height: 16),

                      // Pickups Section
                      _buildSectionHeader(
                        context,
                        title: 'Pickup',
                        count: state.pickups.length,
                        icon: Icons.inventory,
                      ),
                      if (state.pickups.isEmpty)
                        _buildEmptyState(
                          context,
                          message: 'No pickups assigned',
                          icon: Icons.inbox_outlined,
                        )
                      else
                        ...state.pickups.map(
                          (pkg) => _buildPackageCard(
                            context,
                            pkg,
                            isDelivery: false,
                          ),
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
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
