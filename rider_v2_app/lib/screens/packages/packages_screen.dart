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
import '../../bloc/location/location_bloc.dart';
import '../../bloc/location/location_event.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  PackagesBloc? _packagesBloc;
  bool _initialized = false;
  int?
  _lastPackageIdSet; // Track last package ID we set to avoid duplicate dispatches

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
        backgroundColor: AppTheme.neutral50,
        appBar: AppBar(
          backgroundColor: AppTheme.neutral50,
          elevation: 0,
          title: const Text(
            'Packages',
            style: TextStyle(
              color: AppTheme.neutral900,
              fontWeight: FontWeight.w600,
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: _packagesBloc!,
      child: Scaffold(
        backgroundColor: AppTheme.neutral50,
        appBar: AppBar(
          backgroundColor: AppTheme.neutral50,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Packages',
            style: TextStyle(
              color: AppTheme.neutral900,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
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
            } else if (state is PackagesLoaded) {
              // Auto-update location tracking if there's an on_the_way package
              final allPackages = [
                ...state.pickups,
                ...state.assignedDeliveries,
              ];
              try {
                final onTheWayPackage = allPackages.firstWhere(
                  (p) => p.status == 'on_the_way',
                );

                debugPrint(
                  'PackagesScreen: Found on_the_way package (id: ${onTheWayPackage.id}), auto-updating location tracking',
                );
                try {
                  context.read<LocationBloc>().add(
                    LocationUpdatePackageIdEvent(onTheWayPackage.id),
                  );
                  _lastPackageIdSet = onTheWayPackage.id; // Track what we set
                } catch (e) {
                  debugPrint(
                    'PackagesScreen: Error updating location tracking: $e',
                  );
                }
              } catch (e) {
                // No on_the_way package found - reset package ID
                if (_lastPackageIdSet != null) {
                  try {
                    context.read<LocationBloc>().add(
                      const LocationUpdatePackageIdEvent(null),
                    );
                    _lastPackageIdSet = null;
                  } catch (e) {
                    // LocationBloc not available
                  }
                }
                debugPrint('PackagesScreen: No on_the_way package found');
              }
            }
          },
          child: BlocBuilder<PackagesBloc, PackagesState>(
            builder: (context, state) {
              // Also check for on_the_way package in builder (in case listener didn't fire)
              if (state is PackagesLoaded) {
                final allPackages = [
                  ...state.pickups,
                  ...state.assignedDeliveries,
                ];
                try {
                  final onTheWayPackage = allPackages.firstWhere(
                    (p) => p.status == 'on_the_way',
                  );
                  // Only dispatch if we haven't already set this package ID
                  if (_lastPackageIdSet != onTheWayPackage.id) {
                    try {
                      final locationBloc = context.read<LocationBloc>();
                      locationBloc.add(
                        LocationUpdatePackageIdEvent(onTheWayPackage.id),
                      );
                      _lastPackageIdSet = onTheWayPackage.id;
                      debugPrint(
                        'PackagesScreen (builder): Updated location tracking with package_id: ${onTheWayPackage.id}',
                      );
                    } catch (e) {
                      // LocationBloc not available - this is OK, listener will handle it
                    }
                  }
                } catch (e) {
                  // No on_the_way package - reset tracking
                  if (_lastPackageIdSet != null) {
                    try {
                      final locationBloc = context.read<LocationBloc>();
                      locationBloc.add(
                        const LocationUpdatePackageIdEvent(null),
                      );
                      _lastPackageIdSet = null;
                    } catch (e) {
                      // LocationBloc not available
                    }
                  }
                }
              }
              // UI-First: Always render UI structure, show skeleton when loading
              final isLoading =
                  state is PackagesLoading || state is PackagesInitial;
              final isError = state is PackagesError;
              final loadedState = state is PackagesLoaded ? state : null;

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PackagesBloc>().add(
                    const PackagesFetchRequested(),
                  );
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: CustomScrollView(
                  slivers: [
                    // Assigned for Pickup Section
                    SliverToBoxAdapter(
                      child: _buildPickupSection(
                        context,
                        loadedState,
                        isLoading,
                      ),
                    ),

                    // Assigned to Delivery Section Header
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        context,
                        title: 'Assigned to Delivery',
                        count: loadedState?.assignedDeliveries.length ?? 0,
                        icon: Icons.local_shipping_outlined,
                        isLoading: isLoading,
                      ),
                    ),

                    // Assigned Deliveries List
                    if (isLoading)
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildPackageCardSkeleton(),
                            childCount: 3,
                          ),
                        ),
                      )
                    else if (isError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildErrorState(context, switch (state) {
                          PackagesError(:final message) => message,
                          _ => 'An error occurred',
                        }),
                      )
                    else if (loadedState != null)
                      loadedState.assignedDeliveries.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(
                                context,
                                message: 'No assigned deliveries',
                                icon: Icons.inbox_outlined,
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final deliveries =
                                        loadedState.assignedDeliveries;
                                    return _buildPackageCard(
                                      context,
                                      deliveries[index],
                                      isDelivery: true,
                                    );
                                  },
                                  childCount:
                                      loadedState.assignedDeliveries.length,
                                ),
                              ),
                            ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPickupSection(
    BuildContext context,
    PackagesLoaded? state,
    bool isLoading,
  ) {
    final merchants = state?.pickupsByMerchant.keys.toList() ?? [];
    final totalPickups = state?.pickups.length ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.yellow400.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.neutral900,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assigned for Pickup',
                      style: TextStyle(
                        color: AppTheme.neutral900,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoading
                          ? 'Loading...'
                          : '$totalPickups ${totalPickups == 1 ? 'package' : 'packages'}',
                      style: const TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    totalPickups.toString(),
                    style: const TextStyle(
                      color: AppTheme.yellow400,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Merchant Cards (Fixed height, scrollable horizontally)
          if (isLoading)
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 2,
                itemBuilder: (context, index) => _buildMerchantCardSkeleton(),
              ),
            )
          else if (merchants.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: AppTheme.neutral300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No pickups assigned',
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: merchants.length,
                itemBuilder: (context, index) {
                  final merchant = merchants[index];
                  final merchantPackages = state!.pickupsByMerchant[merchant]!;
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
          color: AppTheme.neutral100,
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.yellow400.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: AppTheme.neutral900,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
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
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  merchant.businessName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral900,
                    fontSize: 14,
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
                    style: TextStyle(color: AppTheme.neutral500, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tap to view',
                    style: TextStyle(
                      color: AppTheme.neutral600,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppTheme.neutral600,
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
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.neutral900.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.neutral900, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.neutral900,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neutral900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: AppTheme.yellow400,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.neutral300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppTheme.neutral500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<PackagesBloc>().add(const PackagesFetchRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neutral900,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 80,
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
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCardSkeleton() {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.neutral200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 120,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with tracking code and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (package.trackingCode != null)
                          Text(
                            package.trackingCode!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.neutral900,
                              fontSize: 16,
                            ),
                          )
                        else
                          Text(
                            'Package #${package.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.neutral900,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        package.status,
                      ).withValues(alpha: 0.15),
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

              const SizedBox(height: 12),
              // Customer info
              _buildInfoRow(Icons.person_outline, package.customerName),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone_outlined, package.customerPhone),
              const SizedBox(height: 8),

              // Delivery address or merchant info
              if (isDelivery)
                _buildInfoRow(
                  Icons.location_on_outlined,
                  package.deliveryAddress,
                )
              else if (package.merchant != null)
                _buildInfoRow(
                  Icons.store_outlined,
                  package.merchant!.businessName,
                ),

              if (isDelivery && package.merchant != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.store_outlined,
                  'From: ${package.merchant!.businessName}',
                ),
              ],

              const SizedBox(height: 12),
              // Divider
              Container(height: 1, color: AppTheme.neutral200),
              const SizedBox(height: 12),

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
                        color: AppTheme.neutral500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        package.paymentType.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.neutral600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${package.amount.toStringAsFixed(0)} MMK',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              // Timestamp
              if (package.assignedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Assigned: ${MyanmarDateUtils.formatDateTime(package.assignedAt!)}',
                  style: TextStyle(color: AppTheme.neutral500, fontSize: 11),
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
              backgroundColor: AppTheme.neutral900,
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
                    foregroundColor: AppTheme.neutral900,
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
    // Capture BLoC before showing dialog so we don't depend on dialog context
    final packagesBloc = context.read<PackagesBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppTheme.neutral900,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Mark as Delivered',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.neutral900,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark this package as delivered?',
              style: const TextStyle(color: AppTheme.neutral800, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Package: ${package.trackingCode ?? 'Package #${package.id}'}',
              style: const TextStyle(
                color: AppTheme.neutral600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.neutral600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              packagesBloc.add(PackageMarkDeliveredRequested(package.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neutral900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Mark as Delivered'),
          ),
        ],
      ),
    );
  }

  void _showContactCustomerDialog(BuildContext context, PackageModel package) {
    // Capture BLoC before showing dialog
    final packagesBloc = context.read<PackagesBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.phone_outlined,
                color: AppTheme.neutral900,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Contact Customer',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.neutral900,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.customerName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Phone: ${package.customerPhone}',
              style: const TextStyle(color: AppTheme.neutral600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Was the contact successful?',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.neutral800,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.neutral600),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              packagesBloc.add(
                PackageContactCustomerRequested(package.id, 'failed'),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Failed'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              packagesBloc.add(
                PackageContactCustomerRequested(package.id, 'success'),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neutral900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Success'),
          ),
        ],
      ),
    );
  }

  void _showReturnToOfficeDialog(BuildContext context, PackageModel package) {
    // Capture BLoC before showing dialog
    final packagesBloc = context.read<PackagesBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.undo_rounded,
                color: AppTheme.neutral900,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Return to Office',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.neutral900,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Return this package to office?',
              style: const TextStyle(color: AppTheme.neutral800, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Package: ${package.trackingCode ?? 'Package #${package.id}'}',
              style: const TextStyle(
                color: AppTheme.neutral600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.neutral600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              packagesBloc.add(PackageReturnToOfficeRequested(package.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neutral900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Return to Office'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.neutral500),
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ready_for_delivery':
        return AppTheme.yellow500;
      case 'on_the_way':
        return AppTheme.yellow600;
      case 'assigned_to_rider':
        return AppTheme.neutral600;
      case 'picked_up':
        return Colors.green;
      default:
        return AppTheme.neutral500;
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
