import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/package_model.dart';
import '../../repositories/package_repository.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/utils/date_utils.dart' as myanmar_date;
import 'draft_date_detail_screen.dart';
import 'draft_widgets.dart';

class DraftScreen extends StatefulWidget {
  const DraftScreen({super.key});

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  final _packageRepository = PackageRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );

  List<PackageModel> _drafts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when coming back from detail screen
    final result = ModalRoute.of(context)?.settings.arguments;
    if (result == true) {
      _loadDrafts();
    }
  }

  Future<void> _loadDrafts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final drafts = await _packageRepository.getDrafts();
      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<DateTime, List<PackageModel>> _groupDraftsByDate() {
    final Map<DateTime, List<PackageModel>> grouped = {};

    for (final draft in _drafts) {
      // Use Myanmar timezone for grouping
      final date = myanmar_date.MyanmarDateUtils.getDateKey(draft.createdAt);

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(draft);
    }

    return grouped;
  }

  String _formatDate(DateTime date) {
    // date is already in Myanmar timezone from getDateKey
    final now = myanmar_date.MyanmarDateUtils.getMyanmarNow();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return AppLocalizations.of(context)!.today;
    } else if (dateOnly == yesterday) {
      return AppLocalizations.of(context)!.yesterday;
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    }
  }

  String _formatLastModified(DateTime lastUpdated) {
    final now = myanmar_date.MyanmarDateUtils.getMyanmarNow();
    final updatedLocal = myanmar_date.MyanmarDateUtils.toMyanmarTime(
      lastUpdated,
    );
    final diff = now.difference(updatedLocal);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else {
      final days = diff.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                l10n.errorLoadingDrafts,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadDrafts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.yellow400,
                  foregroundColor: AppTheme.neutral900,
                ),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_drafts.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.neutral50,
        body: Center(
          child: Text(
            l10n.noDraftPackages,
            style: const TextStyle(fontSize: 18, color: AppTheme.neutral500),
          ),
        ),
      );
    }

    final grouped = _groupDraftsByDate();
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: SafeArea(
        child: Column(
          children: [
            DraftHeader(totalDraftGroups: sortedDates.length),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDrafts,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: sortedDates.length + 1,
                  itemBuilder: (context, index) {
                    if (index == sortedDates.length) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: DraftInfoBox(),
                      );
                    }

                    final date = sortedDates[index];
                    final packages = grouped[date]!;
                    final totalAmount = packages.fold<double>(
                      0,
                      (sum, p) => sum + p.amount,
                    );
                    final latestUpdated = packages
                        .map((p) => p.updatedAt)
                        .reduce((a, b) => a.isAfter(b) ? a : b);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DraftDateCard(
                        title: _formatDate(date),
                        lastModifiedText: _formatLastModified(latestUpdated),
                        packageCount: packages.length,
                        totalAmount: totalAmount,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DraftDateDetailScreen(
                                date: date,
                                packages: packages,
                              ),
                            ),
                          );

                          if (result == true) {
                            _loadDrafts();
                          }
                        },
                      ),
                    );
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
