import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/package_model.dart';
import '../../repositories/package_repository.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/utils/date_utils.dart' as myanmar_date;
import '../../widgets/image_preview_screen.dart';
import 'edit_draft_screen.dart';

class DraftDateDetailScreen extends StatefulWidget {
  final DateTime date;
  final List<PackageModel> packages;

  const DraftDateDetailScreen({
    super.key,
    required this.date,
    required this.packages,
  });

  @override
  State<DraftDateDetailScreen> createState() => _DraftDateDetailScreenState();
}

class _DraftDateDetailScreenState extends State<DraftDateDetailScreen> {
  final _packageRepository = PackageRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );

  late List<PackageModel> _packages;
  bool _isDeleting = false;
  bool _isSubmitting = false;
  bool _packagesWereSubmitted = false;

  @override
  void initState() {
    super.initState();
    _packages = List.from(widget.packages);
  }

  Future<void> _loadDrafts() async {
    try {
      final drafts = await _packageRepository.getDrafts();
      final filteredDrafts = drafts.where((d) {
        // Use Myanmar timezone for comparison
        final draftDate = myanmar_date.MyanmarDateUtils.getDateKey(d.createdAt);
        final widgetDate = DateTime(
          widget.date.year,
          widget.date.month,
          widget.date.day,
        );
        return draftDate == widgetDate;
      }).toList();

      if (mounted) {
        setState(() {
          _packages = filteredDrafts;
        });

        // If no drafts found for this date and packages were submitted, navigate back
        // This means all packages were submitted successfully
        if (filteredDrafts.isEmpty && _packagesWereSubmitted) {
          // Navigate back to draft list
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        // Only show error if it's not an empty list scenario
        if (!e.toString().contains('No valid draft packages found')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading drafts: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // If no drafts found, navigate back to draft list
          Navigator.of(context).pop(true);
        }
      }
    }
  }

  Future<void> _deleteDraft(int packageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft'),
        content: const Text(
          'Are you sure you want to delete this draft package?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _packageRepository.deleteDraft(packageId);

      if (mounted) {
        setState(() {
          _packages.removeWhere((p) => p.id == packageId);
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // If no packages left, go back
        if (_packages.isEmpty) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registerAllPackages() async {
    if (_packages.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register All Packages'),
        content: Text(
          'Are you sure you want to register all ${_packages.length} package(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Register'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final packageIds = _packages.map((p) => p.id).toList();
      final response = await _packageRepository.submitDrafts(packageIds);

      if (mounted) {
        // Mark that packages were submitted before clearing
        _packagesWereSubmitted = true;

        setState(() {
          _isSubmitting = false;
          // Clear packages list immediately since they're no longer drafts
          _packages = [];
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registration Result'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response.submittedCount > 0
                      ? '${response.submittedCount} package(s) registered successfully'
                      : '${response.createdCount} package(s) registered successfully',
                ),
                if (response.failedCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${response.failedCount} package(s) failed',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (response.errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Errors:'),
                  ...response.errors.map(
                    (e) => Text(
                      '${e.customerName}: ${e.error}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Go back to draft list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    // date is already in Myanmar timezone from getDateKey
    final now = myanmar_date.MyanmarDateUtils.getMyanmarNow();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime utcDateTime) {
    return myanmar_date.MyanmarDateUtils.formatDateTime(utcDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.neutral900, AppTheme.neutral800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(widget.date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_packages.length} package${_packages.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppTheme.yellow400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body Content
            if (_isDeleting || _isSubmitting)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_packages.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No packages for this date',
                    style: TextStyle(fontSize: 18, color: AppTheme.neutral500),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _packages.length,
                  itemBuilder: (context, index) {
                    final package = _packages[index];
                    return _buildPackageCard(package);
                  },
                ),
              ),
            // Register All Button
            if (_packages.isNotEmpty && !_isDeleting && !_isSubmitting)
              Container(
                padding: const EdgeInsets.all(20),
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
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _registerAllPackages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.yellow400,
                        foregroundColor: AppTheme.neutral900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.neutral900,
                                ),
                              ),
                            )
                          : const Text(
                              'Register All Packages',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(PackageModel package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neutral100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package Image
          if (package.packageImage != null)
            GestureDetector(
              onTap: () {
                ImagePreviewScreen.show(
                  context,
                  package.packageImage!,
                  title: 'Package Image',
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.network(
                  package.packageImage!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: AppTheme.neutral100,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppTheme.neutral400,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.yellow50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.yellow200),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 16,
                        color: AppTheme.yellow600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        package.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.neutral900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Customer Phone
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppTheme.neutral500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      package.customerPhone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.neutral700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Delivery Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppTheme.neutral500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        package.deliveryAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),
                // Package Description (if exists)
                if (package.packageDescription != null &&
                    package.packageDescription!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: AppTheme.neutral500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          package.packageDescription!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.neutral700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Payment Type and Amount
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.neutral100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: package.paymentType.toLowerCase() == 'cod'
                                  ? AppTheme.yellow50
                                  : AppTheme.neutral100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    package.paymentType.toLowerCase() == 'cod'
                                    ? AppTheme.yellow200
                                    : AppTheme.neutral200,
                              ),
                            ),
                            child: Text(
                              package.paymentType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    package.paymentType.toLowerCase() == 'cod'
                                    ? AppTheme.yellow700
                                    : AppTheme.neutral600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${package.amount.toStringAsFixed(0)} MMK',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.neutral900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Created At and Action Buttons
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppTheme.neutral400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Created: ${_formatDateTime(package.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral500,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditDraftScreen(package: package),
                            ),
                          );

                          if (result == true) {
                            _loadDrafts();
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.yellow50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.yellow200),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: AppTheme.yellow600,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _deleteDraft(package.id),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
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
