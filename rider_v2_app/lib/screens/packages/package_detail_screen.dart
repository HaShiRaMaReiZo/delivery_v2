import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/package_model.dart';
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
                if (mounted) {
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
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
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
        backgroundColor: AppTheme.lightBeige,
        appBar: AppBar(
          title: Builder(
            builder: (context) {
              final package = _currentPackage ?? widget.package;
              return Text(package.trackingCode ?? 'Package #${package.id}');
            },
          ),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<PackagesBloc, PackagesState>(
          builder: (context, state) {
            final isLoading = state is PackagesLoaded && state.isActionLoading;
            final package = _currentPackage ?? widget.package;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Package Info Card
                  _buildPackageInfoCard(package),

                  const SizedBox(height: 16),

                  // Customer Info Card
                  _buildCustomerInfoCard(package),

                  const SizedBox(height: 16),

                  // Payment Info Card
                  _buildPaymentInfoCard(package),

                  const SizedBox(height: 16),

                  // Status History Card
                  if (package.statusHistory != null &&
                      package.statusHistory!.isNotEmpty)
                    _buildStatusHistoryCard(package),

                  const SizedBox(height: 16),

                  // Action Buttons
                  _buildActionButtons(context, package, isLoading),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPackageInfoCard(PackageModel package) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    package.trackingCode ?? 'Package #${package.id}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
                _buildStatusBadge(package.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.description,
              'Description',
              package.packageDescription ?? 'No description',
            ),
            if (package.packageImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  package.packageImage!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 48),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              'Created',
              MyanmarDateUtils.formatDateTime(package.createdAt),
            ),
            if (package.assignedAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.assignment,
                'Assigned',
                MyanmarDateUtils.formatDateTime(package.assignedAt!),
              ),
            ],
            if (package.pickedUpAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.check_circle,
                'Picked Up',
                MyanmarDateUtils.formatDateTime(package.pickedUpAt!),
              ),
            ],
            if (package.deliveredAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.local_shipping,
                'Delivered',
                MyanmarDateUtils.formatDateTime(package.deliveredAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard(PackageModel package) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Customer Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person_outline, 'Name', package.customerName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'Phone', package.customerPhone),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on,
              'Address',
              package.deliveryAddress,
            ),
            if (package.deliveryLatitude != null &&
                package.deliveryLongitude != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Open maps with delivery location
                  _openMaps(
                    package.deliveryLatitude!,
                    package.deliveryLongitude!,
                  );
                },
                icon: const Icon(Icons.map, size: 18),
                label: const Text('Open in Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard(PackageModel package) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  package.paymentType == 'cod'
                      ? Icons.money
                      : Icons.credit_card,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Type:',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: package.paymentType == 'cod'
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    package.paymentType.toUpperCase(),
                    style: TextStyle(
                      color: package.paymentType == 'cod'
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount:',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Text(
                  '${package.amount.toStringAsFixed(0)} MMK',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistoryCard(PackageModel package) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Status History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...package.statusHistory!.map((history) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(history.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusLabel(history.status),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (history.notes != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              history.notes!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            MyanmarDateUtils.formatDateTime(history.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
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
          _buildActionButton(
            context,
            icon: Icons.inventory_2,
            label: 'Receive from Office',
            color: AppTheme.darkBlue,
            isLoading: isLoading,
            onPressed: () {
              context.read<PackagesBloc>().add(
                PackageReceiveFromOfficeRequested(package.id),
              );
            },
          ),

        // Start Delivery (for ready_for_delivery)
        if (status == 'ready_for_delivery')
          _buildActionButton(
            context,
            icon: Icons.directions_bike,
            label: 'Start Delivery',
            color: Colors.blue,
            isLoading: isLoading,
            onPressed: () {
              context.read<PackagesBloc>().add(
                PackageStartDeliveryRequested(package.id),
              );
            },
          ),

        // Mark as Delivered (for on_the_way)
        if (status == 'on_the_way') ...[
          _buildActionButton(
            context,
            icon: Icons.check_circle,
            label: 'Mark as Delivered',
            color: Colors.green,
            isLoading: isLoading,
            onPressed: () => _showMarkDeliveredDialog(context, package),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.phone,
                  label: 'Contact Customer',
                  color: AppTheme.primaryBlue,
                  isLoading: isLoading,
                  onPressed: () => _showContactCustomerDialog(context, package),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.undo,
                  label: 'Return to Office',
                  color: Colors.orange,
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

  Widget _buildActionButton(
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
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
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
        return Colors.grey;
      case 'assigned_to_rider':
        return Colors.purple;
      case 'picked_up':
        return Colors.blue;
      case 'arrived_at_office':
        return Colors.cyan;
      case 'ready_for_delivery':
        return Colors.blue;
      case 'on_the_way':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'return_to_office':
        return Colors.red;
      default:
        return Colors.grey;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          title: const Text('Mark as Delivered'),
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                      border: Border.all(color: Colors.grey),
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
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
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
              child: const Text('Cancel'),
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
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
        title: const Text('Contact Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Customer: ${package.customerName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Phone: ${package.customerPhone}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _callCustomer(package.customerPhone);
              },
              icon: const Icon(Icons.phone, size: 20),
              label: const Text('Call Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
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
            child: const Text('Cancel'),
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
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Return to Office'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Return ${package.trackingCode ?? 'Package #${package.id}'} to office?',
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
            child: const Text('Cancel'),
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
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Return'),
          ),
        ],
      ),
    );
  }
}
