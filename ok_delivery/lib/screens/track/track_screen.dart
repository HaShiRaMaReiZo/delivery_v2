import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/package_model.dart';
import '../../repositories/package_repository.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'track_widgets.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final _packageRepository = PackageRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );

  List<PackageModel> _packages = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  String _activeFilter = 'all'; // all, pending, pickup, transit, delivered

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when coming back from detail screen
    final result = ModalRoute.of(context)?.settings.arguments;
    if (result == true) {
      _loadPackages(refresh: true);
    }
  }

  Future<void> _loadPackages({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _packages = [];
      });
    }

    if (_isLoadingMore || (!_hasMore && !refresh)) return;

    setState(() {
      if (!refresh) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _error = null;
      }
    });

    try {
      final packages = await _packageRepository.getPackages(page: _currentPage);

      setState(() {
        if (refresh) {
          _packages = packages;
        } else {
          _packages.addAll(packages);
        }
        _hasMore = packages.length >= 20; // Assuming 20 per page
        _currentPage++;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  List<PackageModel> _filteredPackages() {
    List<PackageModel> list = List.from(_packages);

    // Filter by status category
    if (_activeFilter != 'all') {
      list = list.where((p) {
        final status = p.status;
        switch (_activeFilter) {
          case 'pending':
            return status == 'registered' || status == 'assigned_to_rider';
          case 'pickup':
            return status == 'picked_up';
          case 'transit':
            return status == 'ready_for_delivery' || status == 'on_the_way';
          case 'delivered':
            return status == 'delivered';
          default:
            return true;
        }
      }).toList();
    }

    // Search by tracking code or customer name
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        final tracking = p.trackingCode?.toLowerCase() ?? '';
        final name = p.customerName.toLowerCase();
        return tracking.contains(q) || name.contains(q);
      }).toList();
    }

    // Sort by updated date (newest first)
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Map<String, int> _statusCounts() {
    int all = _packages.length;
    int pending = 0;
    int pickup = 0;
    int transit = 0;
    int delivered = 0;

    for (final p in _packages) {
      switch (p.status) {
        case 'registered':
        case 'assigned_to_rider':
          pending++;
          break;
        case 'picked_up':
          pickup++;
          break;
        case 'ready_for_delivery':
        case 'on_the_way':
          transit++;
          break;
        case 'delivered':
          delivered++;
          break;
        default:
          break;
      }
    }

    return {
      'all': all,
      'pending': pending,
      'pickup': pickup,
      'transit': transit,
      'delivered': delivered,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool showBackButton = Navigator.of(context).canPop();

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.neutral50,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.neutral50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.errorLoadingPackages,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _loadPackages(refresh: true),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_packages.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.neutral50,
        body: Center(
          child: Text(
            l10n.noPackagesFound,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    final filtered = _filteredPackages();
    final counts = _statusCounts();

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: SafeArea(
        child: Column(
          children: [
            TrackHeader(
              totalCount: _packages.length,
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onRefreshPressed: () => _loadPackages(refresh: true),
              showBackButton: showBackButton,
            ),
            SizedBox(height: 20),
            TrackFilterChips(
              activeFilter: _activeFilter,
              countAll: counts['all'] ?? 0,
              countPending: counts['pending'] ?? 0,
              countPickup: counts['pickup'] ?? 0,
              countTransit: counts['transit'] ?? 0,
              countDelivered: counts['delivered'] ?? 0,
              onFilterChanged: (value) {
                setState(() {
                  _activeFilter = value;
                });
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadPackages(refresh: true),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  itemCount: filtered.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      if (!_isLoadingMore) {
                        _loadPackages();
                      }
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final package = filtered[index];
                    return TrackPackageCard(package: package);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
