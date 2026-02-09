import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/package_model.dart';
import '../../models/user_model.dart';
import 'bloc/history_bloc.dart';
import 'bloc/history_event.dart';
import 'bloc/history_state.dart';
import 'repository/history_repository.dart';
import '../packages/package_detail_screen.dart';
import '../packages/bloc/packages_bloc.dart';
import '../packages/repository/packages_repository.dart';

class HistoryScreen extends StatefulWidget {
  final UserModel user;

  const HistoryScreen({super.key, required this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryBloc? _historyBloc;
  PackagesBloc? _packagesBloc; // For navigation to package detail
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
    _historyBloc = HistoryBloc(HistoryRepository(apiClient));

    // Get rider_id from user (prefer rider_id field, fallback to rider?.id)
    final riderId = widget.user.riderId ?? widget.user.rider?.id;
    if (riderId != null) {
      _historyBloc!.add(HistoryFetchRequested(riderId));
    }

    // Also create PackagesBloc for navigation to package detail
    _packagesBloc = PackagesBloc(PackagesRepository(apiClient));

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _historyBloc?.close();
    _packagesBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _historyBloc == null) {
      return Scaffold(
        backgroundColor: AppTheme.neutral50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: _historyBloc!,
      child: Scaffold(
        backgroundColor: AppTheme.neutral50,
        body: SafeArea(
          child: BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              final isLoading =
                  state is HistoryLoading || state is HistoryInitial;
              final isError = state is HistoryError;
              final errorMessage = switch (state) {
                HistoryError(:final message) => message,
                _ => '',
              };
              final loadedState = state is HistoryLoaded ? state : null;

              return RefreshIndicator(
                onRefresh: () async {
                  final riderId = widget.user.riderId ?? widget.user.rider?.id;
                  if (riderId != null) {
                    context.read<HistoryBloc>().add(
                      HistoryFetchRequested(riderId),
                    );
                  }
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: CustomScrollView(
                  slivers: [
                    // Header with current month info
                    SliverToBoxAdapter(
                      child: _buildHeader(context, loadedState, isLoading),
                    ),

                    // Packages grouped by day
                    if (isLoading)
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildHistoryCardSkeleton(),
                            childCount: 3,
                          ),
                        ),
                      )
                    else if (isError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildErrorState(context, errorMessage),
                      )
                    else if (loadedState != null)
                      loadedState.packagesByDate.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(context),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final dates = loadedState
                                        .packagesByDate
                                        .keys
                                        .toList();
                                    final date = dates[index];
                                    final packages =
                                        loadedState.packagesByDate[date]!;
                                    return _buildDaySection(
                                      context,
                                      date,
                                      packages,
                                    );
                                  },
                                  childCount: loadedState.packagesByDate.length,
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

  Widget _buildHeader(
    BuildContext context,
    HistoryLoaded? state,
    bool isLoading,
  ) {
    final now = DateTime.now();
    final monthName = _getMonthName(now.month);
    final totalDelivered =
        state?.packagesByDate.values.fold<int>(
          0,
          (sum, packages) => sum + packages.length,
        ) ??
        0;

    return Container(
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLoading
                  ? 'Loading...'
                  : '$monthName ${now.year} - $totalDelivered ${totalDelivered == 1 ? 'delivery' : 'deliveries'}',
              style: const TextStyle(
                color: Color(0xFFE5E7EB), // neutral200-ish
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    String dateKey,
    List<PackageModel> packages,
  ) {
    final date = DateTime.parse(dateKey);
    final formattedDate = _formatDateHeader(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    color: AppTheme.neutral900,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Packages for this day
        ...packages.map(
          (package) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHistoryCard(context, package),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, PackageModel package) {
    return GestureDetector(
      onTap: () {
        // Navigate to package detail - use PackagesBloc from state
        if (_packagesBloc != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: _packagesBloc!,
                child: PackageDetailScreen(package: package),
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.yellow400.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_outline,
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
                  Text(
                    package.trackingCode ?? 'Package #${package.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral900,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.customerName,
                    style: const TextStyle(
                      color: AppTheme.neutral600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (package.deliveredAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Delivered: ${MyanmarDateUtils.formatDateTime(package.deliveredAt!)}',
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
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${package.amount.toStringAsFixed(0)} MMK',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Delivered',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: AppTheme.neutral400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
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
              final riderId = widget.user.riderId ?? widget.user.rider?.id;
              if (riderId != null) {
                context.read<HistoryBloc>().add(HistoryFetchRequested(riderId));
              }
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

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppTheme.neutral300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No deliveries this month',
            style: TextStyle(color: AppTheme.neutral500, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Delivered packages will appear here',
            style: TextStyle(color: AppTheme.neutral400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return MyanmarDateUtils.formatDateOnly(date);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
