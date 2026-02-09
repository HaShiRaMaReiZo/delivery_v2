import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/package_model.dart';
import '../../models/package_status_history_model.dart';
import '../../bloc/location/location_bloc.dart';
import '../../bloc/location/location_event.dart';
import 'bloc/packages_bloc.dart';
import 'bloc/packages_event.dart';
import 'bloc/packages_state.dart';

class PackageDetailScreen extends StatefulWidget {
  final PackageModel package;

  const PackageDetailScreen({super.key, required this.package});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  final TextEditingController _codAmountController = TextEditingController();
  final TextEditingController _deliveryFeesController = TextEditingController();
  final TextEditingController _deliveredToNameController =
      TextEditingController();
  final TextEditingController _deliveredToPhoneController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  PackageModel? _currentPackage;
  bool _wasPackageInList =
      true; // Track if package was in list when screen opened

  @override
  void initState() {
    super.initState();
    _currentPackage = widget.package;
    _wasPackageInList = true; // Package is in list when screen opens
    // Pre-fill COD amount if package has amount
    if (_currentPackage!.paymentType == 'cod') {
      _codAmountController.text = _currentPackage!.amount.toStringAsFixed(0);
    }

    // If package is on_the_way, automatically update location tracking with package_id
    if (_currentPackage!.status == 'on_the_way') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint(
            'PackageDetailScreen: Package is on_the_way, auto-updating location tracking with package_id: ${_currentPackage!.id}',
          );
          context.read<LocationBloc>().add(
            LocationUpdatePackageIdEvent(_currentPackage!.id),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _codAmountController.dispose();
    _deliveryFeesController.dispose();
    _deliveredToNameController.dispose();
    _deliveredToPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PackagesBloc, PackagesState>(
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
          // Find updated package in the list (check both pickups and assignedDeliveries)
          final allPackages = [...state.pickups, ...state.assignedDeliveries];
          PackageModel? packageInList;
          try {
            packageInList = allPackages.firstWhere(
              (p) => p.id == widget.package.id,
            );
          } catch (e) {
            // Package not found in list
            packageInList = null;
          }

          // Update tracking: package is now in list or not
          final isPackageInCurrentList = packageInList != null;

          // If package was in list before but is not in list now, navigate back
          // This handles cases where contact_failed or return_to_office removes the package
          // Check this on every state update (not just when action completes)
          if (_wasPackageInList &&
              !isPackageInCurrentList &&
              !state.isActionLoading) {
            // Only show snackbar and navigate if we haven't already done so
            // This prevents multiple navigations
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Action completed successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              // Package was removed from rider's list (e.g., contact_failed clears assignment)
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && context.mounted) {
                  Navigator.pop(context);
                }
              });
              // Update flag to prevent multiple navigations
              _wasPackageInList = false;
              return; // Exit early to prevent further processing
            }
          }

          // Update tracking flag (only if package is still in list)
          if (isPackageInCurrentList) {
            _wasPackageInList = true;
          }

          // Check if action was just completed
          final previousState = context.read<PackagesBloc>().state;
          final wasActionLoading =
              previousState is PackagesLoaded && previousState.isActionLoading;
          final isActionCompleted = wasActionLoading && !state.isActionLoading;

          if (isActionCompleted && packageInList != null) {
            // Package is still in list, update local state
            final updatedPackage = packageInList;

            // Update local package state if it changed
            if (mounted) {
              if (_currentPackage == null ||
                  _currentPackage!.status != updatedPackage.status ||
                  _currentPackage!.statusHistory?.length !=
                      updatedPackage.statusHistory?.length) {
                setState(() {
                  _currentPackage = updatedPackage;
                });
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Action completed successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Navigate back after success (only for certain statuses)
            // These statuses mean package is no longer with the rider
            // or the rider assignment was cleared, so navigate back
            if (updatedPackage.status == 'delivered' ||
                updatedPackage.status == 'return_to_office' ||
                updatedPackage.status == 'arrived_at_office' ||
                updatedPackage.status == 'contact_failed') {
              // Clear package ID from location tracking
              context.read<LocationBloc>().add(
                const LocationUpdatePackageIdEvent(null),
              );
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && context.mounted) {
                  Navigator.pop(context);
                }
              });
            }
          } else if (packageInList != null) {
            // Update local package state if package is in list and state changed
            final updatedPackage = packageInList;
            if (mounted) {
              if (_currentPackage == null ||
                  _currentPackage!.status != updatedPackage.status ||
                  _currentPackage!.statusHistory?.length !=
                      updatedPackage.statusHistory?.length) {
                setState(() {
                  _currentPackage = updatedPackage;
                });
              }
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.neutral50,
        appBar: AppBar(
          backgroundColor: AppTheme.neutral50,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          toolbarHeight: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.arrow_back,
                color: AppTheme.neutral900,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          leadingWidth: 64,
          titleSpacing: 0,
          title: Builder(
            builder: (context) {
              final package = _currentPackage ?? widget.package;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Package Details',
                    style: TextStyle(
                      color: AppTheme.neutral900,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    package.trackingCode ?? 'Package #${package.id}',
                    style: const TextStyle(
                      color: AppTheme.neutral500,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        body: BlocBuilder<PackagesBloc, PackagesState>(
          builder: (context, state) {
            final isLoading = state is PackagesLoaded && state.isActionLoading;
            final package = _currentPackage ?? widget.package;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF020617), // dark hero background
                    AppTheme.neutral50,
                  ],
                  stops: [0.0, 0.4],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDetailHeroBanner(package),
                    const SizedBox(height: 20),

                    // Package Info Card
                    _buildPackageInfoCard(package),

                    const SizedBox(height: 20),

                    // Customer Info Card
                    _buildCustomerInfoCard(package),

                    const SizedBox(height: 20),

                    // Payment Info Card
                    _buildPaymentInfoCard(package),

                    const SizedBox(height: 20),

                    // Status History Card
                    if (package.statusHistory != null &&
                        package.statusHistory!.isNotEmpty) ...[
                      _buildStatusHistoryCard(package),
                      const SizedBox(height: 20),
                    ],

                    // Action Buttons
                    _buildActionButtons(context, package, isLoading),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailHeroBanner(PackageModel package) {
    final statusLabel = _getStatusLabel(package.status);
    final isOnTheWay = package.status == 'on_the_way';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOnTheWay
              ? const [
                  Color(0xFFFACC15), // yellow400
                  Color(0xFFEAB308), // yellow500
                ]
              : const [
                  Color(0xFF0F172A), // slate-900
                  Color(0xFF020617), // slate-950
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isOnTheWay
                ? const Color(0xFFEAB308).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOnTheWay
                  ? Icons.directions_bike_rounded
                  : Icons.inventory_2_outlined,
              color: Color(0xFFEAB308),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: isOnTheWay ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnTheWay
                      ? 'On the way to ${package.deliveryAddress}'
                      : 'Current status of this package.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isOnTheWay
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFE5E7EB),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageInfoCard(PackageModel package) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.yellow400.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
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
                    Text(
                      package.trackingCode ?? 'Package #${package.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(package.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            Icons.description_outlined,
            'Description',
            package.packageDescription ?? 'No description',
          ),
          if (package.packageImage != null &&
              package.packageImage!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                package.packageImage!.trim(), // Remove any whitespace/newlines
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                headers: const {'Accept': 'image/*'},
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    color: AppTheme.neutral100,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.yellow500,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  if (kDebugMode) {
                    debugPrint(
                      'PackageDetailScreen: Image load error for ${package.packageImage}: $error',
                    );
                    debugPrint('PackageDetailScreen: Stack trace: $stackTrace');
                    debugPrint(
                      'PackageDetailScreen: Image URL (trimmed): ${package.packageImage!.trim()}',
                    );
                  }
                  return GestureDetector(
                    onTap: () {
                      // Allow user to open URL in browser to verify
                      try {
                        launchUrl(
                          Uri.parse(package.packageImage!.trim()),
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        if (kDebugMode) {
                          debugPrint(
                            'PackageDetailScreen: Failed to launch URL: $e',
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppTheme.neutral100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.neutral300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: AppTheme.neutral400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: AppTheme.neutral500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to open in browser',
                            style: TextStyle(
                              color: AppTheme.neutral400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(height: 1, color: AppTheme.neutral200),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.access_time_outlined,
            'Created',
            MyanmarDateUtils.formatDateTime(package.createdAt),
          ),
          if (package.assignedAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.assignment_outlined,
              'Assigned',
              MyanmarDateUtils.formatDateTime(package.assignedAt!),
            ),
          ],
          if (package.pickedUpAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.check_circle_outline,
              'Picked Up',
              MyanmarDateUtils.formatDateTime(package.pickedUpAt!),
            ),
          ],
          if (package.deliveredAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.local_shipping_outlined,
              'Delivered',
              MyanmarDateUtils.formatDateTime(package.deliveredAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(PackageModel package) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.neutral900,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Customer Information',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.person_outline, 'Name', package.customerName),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.phone_outlined,
                  'Phone',
                  package.customerPhone,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.neutral900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.phone, color: AppTheme.yellow400),
                  onPressed: () => _callCustomer(package.customerPhone),
                  tooltip: 'Call Customer',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Address',
            package.deliveryAddress,
          ),
          if (package.deliveryLatitude != null &&
              package.deliveryLongitude != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openMaps(
                    package.deliveryLatitude!,
                    package.deliveryLongitude!,
                  );
                },
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Open in Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neutral900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard(PackageModel package) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: package.paymentType == 'cod'
                      ? AppTheme.yellow400.withValues(alpha: 0.1)
                      : AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  package.paymentType == 'cod'
                      ? Icons.money_outlined
                      : Icons.credit_card_outlined,
                  color: AppTheme.neutral900,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payment Information',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Type:',
                style: TextStyle(color: AppTheme.neutral600, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: package.paymentType == 'cod'
                      ? AppTheme.yellow400.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  package.paymentType.toUpperCase(),
                  style: TextStyle(
                    color: package.paymentType == 'cod'
                        ? AppTheme.yellow600
                        : Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppTheme.neutral200),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amount:',
                style: TextStyle(color: AppTheme.neutral600, fontSize: 14),
              ),
              Text(
                '${package.amount.toStringAsFixed(0)} MMK',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHistoryCard(PackageModel package) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history_outlined,
                  color: AppTheme.neutral900,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Status History',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (package.statusHistory == null ||
              package.statusHistory!.isEmpty) ...[
            const Text(
              'No status history yet.',
              style: TextStyle(color: AppTheme.neutral500, fontSize: 13),
            ),
          ] else ...[
            ..._buildKeyStatusHistory(package.statusHistory!),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildKeyStatusHistory(
    List<PackageStatusHistoryModel> historyList,
  ) {
    // Sort by time ascending so the timeline reads from first → latest
    final sorted = List<PackageStatusHistoryModel>.from(historyList)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return sorted.map((history) {
      final title = _buildStatusHistoryTitle(history);
      final subtitle = MyanmarDateUtils.formatDateTime(
        history.createdAt,
      ); // when

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _getStatusColor(history.status),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusHistoryTitleWidget(history, title),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.neutral500,
                      fontSize: 12,
                    ),
                  ),
                  if (history.notes != null && history.notes!.trim().isNotEmpty)
                    const SizedBox(height: 6),
                  if (history.notes != null && history.notes!.trim().isNotEmpty)
                    Text(
                      history.notes!.trim(),
                      style: const TextStyle(
                        color: AppTheme.neutral600,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatusHistoryTitleWidget(
    PackageStatusHistoryModel history,
    String fullTitle,
  ) {
    final name = history.changedByName?.trim();

    // If there's no real name, fall back to simple text
    if (name == null || name.isEmpty) {
      return const Text(''); // This will immediately be replaced below
    }

    final index = fullTitle.indexOf(name);

    // If the name is not found in the sentence, just show plain text
    if (index == -1) {
      return Text(
        fullTitle,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.neutral900,
        ),
      );
    }

    final before = fullTitle.substring(0, index);
    final after = fullTitle.substring(index + name.length);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.neutral900,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: name,
            style: const TextStyle(color: AppTheme.yellow600),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  String _buildStatusHistoryTitle(PackageStatusHistoryModel history) {
    // Prefer real user name from backend when available
    final actorName = history.changedByName?.trim();

    // Default role based on who changed the status
    final baseActorRole = switch (history.changedByType) {
      'rider' => 'Rider',
      'office' => 'Office staff',
      'merchant' => 'Merchant',
      _ => 'System',
    };

    // For some statuses, we want to force a specific actor role
    final effectiveActorRole = switch (history.status) {
      // Pick up is always done by the assigned rider (not merchant)
      'picked_up' => 'Rider',
      _ => baseActorRole,
    };

    // If we have a real name, show both role + name, e.g. "Rider Zwe Mhan"
    final who = actorName != null && actorName.isNotEmpty
        ? '$effectiveActorRole $actorName'
        : effectiveActorRole;

    return switch (history.status) {
      'picked_up' => '$who picked up the package from merchant',
      'arrived_at_office' => '$who confirmed package arrived at office',
      'assigned_to_rider' => '$who assigned the package to a rider',
      'ready_for_delivery' => '$who marked the package ready for delivery',
      'on_the_way' => '$who started delivery to customer',
      'delivered' => '$who confirmed delivery to customer',
      'return_to_office' => '$who marked the package to return to office',
      'cancelled' => '$who cancelled the package',
      'contact_failed' => '$who marked contact failed with customer',
      _ =>
        // Fallback to generic label if we add new statuses later
        '$who ${_getStatusLabel(history.status)}',
    };
  }

  Widget _buildActionButtons(
    BuildContext context,
    PackageModel package,
    bool isLoading,
  ) {
    final status = package.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Receive from Office (for assigned_to_rider delivery)
        if (status == 'assigned_to_rider' && package.isForDelivery)
          _buildSolidActionButton(
            context,
            icon: Icons.inventory_2_outlined,
            label: 'Receive from Office',
            color: AppTheme.neutral900,
            isLoading: isLoading,
            onPressed: () {
              // Update location tracking to include this package ID
              debugPrint(
                'PackageDetailScreen: Dispatching LocationUpdatePackageIdEvent(${package.id}) for Receive from Office',
              );
              context.read<LocationBloc>().add(
                LocationUpdatePackageIdEvent(package.id),
              );
              context.read<PackagesBloc>().add(
                PackageReceiveFromOfficeRequested(package.id),
              );
            },
          ),

        // Start Delivery (for ready_for_delivery)
        if (status == 'ready_for_delivery')
          _buildSolidActionButton(
            context,
            icon: Icons.directions_bike,
            label: 'Start Delivery',
            color: AppTheme.neutral900,
            isLoading: isLoading,
            onPressed: () {
              // Update location tracking to include this package ID
              debugPrint(
                'PackageDetailScreen: Dispatching LocationUpdatePackageIdEvent(${package.id}) for Start Delivery',
              );
              context.read<LocationBloc>().add(
                LocationUpdatePackageIdEvent(package.id),
              );
              // Start delivery
              context.read<PackagesBloc>().add(
                PackageStartDeliveryRequested(package.id),
              );
            },
          ),

        // Mark as Delivered (for on_the_way)
        if (status == 'on_the_way') ...[
          _buildGradientPrimaryButton(
            context,
            icon: Icons.check_circle,
            label: 'Mark as Delivered',
            isLoading: isLoading,
            onPressed: () => _showMarkDeliveredDialog(context, package),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryOutlineButton(
                  context,
                  icon: Icons.phone_outlined,
                  label: 'Contact Customer',
                  isLoading: isLoading,
                  onPressed: () => _showContactCustomerDialog(context, package),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryOutlineButton(
                  context,
                  icon: Icons.undo,
                  label: 'Return to Office',
                  isLoading: isLoading,
                  onPressed: () => _showReturnToOfficeDialog(context, package),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSolidActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }

  Widget _buildGradientPrimaryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return AnimatedScale(
      scale: isLoading ? 1.0 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF22C55E), // emerald-500
                Color(0xFF16A34A), // emerald-600
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryOutlineButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: Icon(icon, size: 18, color: AppTheme.neutral900),
      label: Text(
        label,
        style: const TextStyle(
          color: AppTheme.neutral900,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.neutral300),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.neutral500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.neutral500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.neutral700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'registered':
        return AppTheme.neutral500;
      case 'assigned_to_rider':
        return AppTheme.neutral600;
      case 'picked_up':
        return AppTheme.yellow500;
      case 'arrived_at_office':
        return AppTheme.yellow500;
      case 'ready_for_delivery':
        return AppTheme.yellow500;
      case 'on_the_way':
        return AppTheme.yellow600;
      case 'delivered':
        return Colors.green;
      case 'return_to_office':
        return Colors.red;
      default:
        return AppTheme.neutral500;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'registered':
        return 'Registered';
      case 'assigned_to_rider':
        return 'Assigned';
      case 'picked_up':
        return 'Picked Up';
      case 'arrived_at_office':
        return 'At Office';
      case 'ready_for_delivery':
        return 'Ready';
      case 'on_the_way':
        return 'On the Way';
      case 'delivered':
        return 'Delivered';
      case 'return_to_office':
        return 'Returned';
      default:
        return status ?? 'Unknown';
    }
  }

  Future<void> _openMaps(double latitude, double longitude) async {
    // Open maps app with coordinates
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMarkDeliveredDialog(BuildContext context, PackageModel package) {
    // Pre-fill amounts based on payment type
    if (package.paymentType == 'cod') {
      _codAmountController.text = package.amount.toStringAsFixed(0);
    }

    // Capture the BLoC from the parent context before showing dialog
    final packagesBloc = context.read<PackagesBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Package: ${package.trackingCode ?? 'Package #${package.id}'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // COD Amount field (if COD payment)
                if (package.paymentType == 'cod') ...[
                  Text(
                    'Expected COD Amount: ${package.amount.toStringAsFixed(0)} MMK',
                    style: const TextStyle(
                      color: AppTheme.neutral600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codAmountController,
                    decoration: const InputDecoration(
                      labelText: 'COD Amount Collected (MMK) *',
                      border: OutlineInputBorder(),
                      prefixText: 'MMK ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                ],
                // Delivery Fees field (if Prepaid payment)
                if (package.paymentType == 'prepaid') ...[
                  TextField(
                    controller: _deliveryFeesController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Fees Collected (MMK) *',
                      border: OutlineInputBorder(),
                      prefixText: 'MMK ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_selectedImage != null)
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.neutral200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      _pickImage();
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo Proof'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neutral900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _codAmountController.clear();
                  _deliveryFeesController.clear();
                });
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.neutral600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate required fields
                if (package.paymentType == 'cod') {
                  final codAmount = double.tryParse(_codAmountController.text);
                  if (codAmount == null || codAmount <= 0) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid COD amount'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                } else if (package.paymentType == 'prepaid') {
                  final deliveryFees = double.tryParse(
                    _deliveryFeesController.text,
                  );
                  if (deliveryFees == null || deliveryFees <= 0) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid delivery fees amount',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                Navigator.pop(dialogContext);

                // For COD: Collect COD (which also marks as delivered)
                if (package.paymentType == 'cod') {
                  final codAmount = double.parse(_codAmountController.text);
                  packagesBloc.add(
                    PackageCollectCodRequested(
                      package.id,
                      codAmount,
                      collectionProof: _selectedImage,
                    ),
                  );
                } else {
                  // For Prepaid: Mark as delivered with delivery fees in notes
                  final deliveryFees = double.parse(
                    _deliveryFeesController.text,
                  );
                  final notesWithFees =
                      'Delivery Fees: ${deliveryFees.toStringAsFixed(0)} MMK';

                  packagesBloc.add(
                    PackageMarkDeliveredRequested(
                      package.id,
                      photo: _selectedImage,
                      notes: notesWithFees,
                    ),
                  );
                }

                // Clear fields
                setState(() {
                  _selectedImage = null;
                  _codAmountController.clear();
                  _deliveryFeesController.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neutral900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Confirm Delivery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callCustomer(String phoneNumber) async {
    try {
      // Clean phone number - remove spaces, dashes, and other non-digit characters except +
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // If number doesn't start with +, ensure it's properly formatted
      if (!cleanedNumber.startsWith('+')) {
        // Remove leading zeros if present
        cleanedNumber = cleanedNumber.replaceFirst(RegExp(r'^0+'), '');
      }

      final url = Uri.parse('tel:$cleanedNumber');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not make phone call. Please check if a dialer app is available.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Customer: ${package.customerName}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone: ${package.customerPhone}',
              style: const TextStyle(color: AppTheme.neutral600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _callCustomer(package.customerPhone);
              },
              icon: const Icon(Icons.phone, size: 20),
              label: const Text('Call Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neutral900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'After calling, was the contact successful?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _notesController.clear();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.neutral600),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              packagesBloc.add(
                PackageContactCustomerRequested(
                  package.id,
                  'failed',
                  notes: _notesController.text.isNotEmpty
                      ? _notesController.text
                      : null,
                ),
              );
              _notesController.clear();
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
                PackageContactCustomerRequested(
                  package.id,
                  'success',
                  notes: _notesController.text.isNotEmpty
                      ? _notesController.text
                      : null,
                ),
              );
              _notesController.clear();
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
          children: [
            Text(
              'Return ${package.trackingCode ?? 'Package #${package.id}'} to office?',
              style: const TextStyle(color: AppTheme.neutral800, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _notesController.clear();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.neutral600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PackagesBloc>().add(
                PackageReturnToOfficeRequested(
                  package.id,
                  notes: _notesController.text.isNotEmpty
                      ? _notesController.text
                      : null,
                ),
              );
              _notesController.clear();
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
}
