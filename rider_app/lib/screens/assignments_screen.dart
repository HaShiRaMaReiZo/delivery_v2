import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../bloc/assignments/assignments_bloc.dart';
import '../bloc/delivery/delivery_bloc.dart';
import '../bloc/location/location_bloc.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/full_image_viewer.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final _searchController = TextEditingController();

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'on_the_way':
        return Colors.blue;
      case 'picked_up':
        return Colors.purple;
      case 'assigned_to_rider':
        return Colors.orange;
      case 'contact_failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'delivered':
        return Icons.check_circle;
      case 'on_the_way':
        return Icons.local_shipping;
      case 'picked_up':
        return Icons.inventory;
      case 'assigned_to_rider':
        return Icons.assignment;
      case 'contact_failed':
        return Icons.phone_disabled;
      default:
        return Icons.pending;
    }
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((s) {
          return s[0].toUpperCase() + s.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assignments'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AssignmentsBloc>().add(
                const AssignmentsEvent.fetchRequested(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by package ID or status...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Status Messages
          Column(
            children: [
              BlocBuilder<DeliveryBloc, DeliveryState>(
                builder: (context, state) {
                  return state.maybeWhen(
                    loading: () => const LinearProgressIndicator(),
                    success: (m) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m,
                              style: TextStyle(color: Colors.green[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    failure: (m) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m,
                              style: TextStyle(color: Colors.red[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
              // Location Tracking Status
              BlocBuilder<LocationBloc, LocationState>(
                builder: (context, state) {
                  return state.when(
                    idle: () => const SizedBox.shrink(),
                    active: () => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.my_location, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location tracking active',
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    error: (message) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_off, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message,
                              style: TextStyle(color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          // Assignments List
          Expanded(
            child: BlocBuilder<AssignmentsBloc, AssignmentsState>(
              builder: (context, state) {
                return state.when(
                  loading: () =>
                      const AppLoadingWidget(message: 'Loading assignments...'),
                  failure: (m) => AppErrorWidget(
                    message: m,
                    title: 'Error loading assignments',
                    onRetry: () {
                      context.read<AssignmentsBloc>().add(
                        const AssignmentsEvent.fetchRequested(),
                      );
                    },
                  ),
                  loaded: (assignments) {
                    // Filter assignments based on search
                    final searchQuery = _searchController.text.toLowerCase();
                    final filteredAssignments = searchQuery.isEmpty
                        ? assignments
                        : assignments.where((a) {
                            final id =
                                (a['id'] as int? ??
                                        a['package_id'] as int? ??
                                        0)
                                    .toString();
                            final status = (a['status']?.toString() ?? '')
                                .toLowerCase();
                            return id.contains(searchQuery) ||
                                status.contains(searchQuery);
                          }).toList();

                    if (filteredAssignments.isEmpty) {
                      return EmptyStateWidget(
                        icon: searchQuery.isEmpty
                            ? Icons.assignment_outlined
                            : Icons.search_off,
                        title: searchQuery.isEmpty
                            ? 'No assignments yet'
                            : 'No assignments found',
                        message: searchQuery.isEmpty
                            ? 'You will see your assigned packages here'
                            : 'Try a different search term',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<AssignmentsBloc>().add(
                          const AssignmentsEvent.fetchRequested(),
                        );
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredAssignments.length,
                        itemBuilder: (context, i) {
                          final a = filteredAssignments[i];
                          final id =
                              a['id'] as int? ?? a['package_id'] as int? ?? 0;
                          final status = a['status']?.toString() ?? 'unknown';
                          final trackingCode =
                              a['tracking_code']?.toString() ?? 'N/A';
                          final customerName =
                              a['customer_name']?.toString() ?? 'N/A';
                          final customerPhone =
                              a['customer_phone']?.toString() ?? 'N/A';
                          final address =
                              a['delivery_address']?.toString() ?? 'N/A';
                          final packageImage = a['package_image']?.toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getStatusIcon(status),
                                  color: _getStatusColor(status),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                trackingCode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    customerName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        status,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _formatStatus(status),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow(
                                        'Phone',
                                        customerPhone,
                                        isPhone: true,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInfoRow('Address', address),
                                      if (packageImage != null &&
                                          packageImage.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Package Image',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () {
                                            final imageUrl =
                                                packageImage.startsWith('http')
                                                ? packageImage
                                                : 'https://ok-delivery-service.onrender.com/storage/$packageImage';
                                            FullImageViewer.show(
                                              context,
                                              imageUrl,
                                              title: 'Package Image',
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Stack(
                                              children: [
                                                Image.network(
                                                  packageImage.startsWith(
                                                        'http',
                                                      )
                                                      ? packageImage
                                                      : 'https://ok-delivery-service.onrender.com/storage/$packageImage',
                                                  height: 200,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          height: 200,
                                                          width:
                                                              double.infinity,
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .broken_image,
                                                              color:
                                                                  Colors.grey,
                                                              size: 48,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Container(
                                                      height: 200,
                                                      width: double.infinity,
                                                      color: Colors.grey[200],
                                                      child: Center(
                                                        child: CircularProgressIndicator(
                                                          value:
                                                              loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black54,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.fullscreen,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _buildActionButtons(
                                          context,
                                          id,
                                          status,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<AssignmentsBloc>().add(
            const AssignmentsEvent.fetchRequested(),
          );
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    int packageId,
    String status,
  ) {
    final dBloc = context.read<DeliveryBloc>();
    final locationBloc = context.read<LocationBloc>();
    final buttons = <Widget>[];

    if (status == 'assigned_to_rider') {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () {
            dBloc.add(DeliveryEvent.startDelivery(packageId: packageId));
            // Start location tracking when delivery starts
            locationBloc.add(LocationEvent.start(packageId: packageId));
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Delivery'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (status == 'assigned_to_rider' || status == 'picked_up') {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () {
            dBloc.add(
              DeliveryEvent.updateStatus(
                packageId: packageId,
                status: 'picked_up',
              ),
            );
          },
          icon: const Icon(Icons.inventory),
          label: const Text('Picked Up'),
        ),
      );
    }

    if (status == 'picked_up') {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () {
            dBloc.add(
              DeliveryEvent.updateStatus(
                packageId: packageId,
                status: 'on_the_way',
              ),
            );
            // Start location tracking when status becomes "on_the_way"
            locationBloc.add(LocationEvent.start(packageId: packageId));
          },
          icon: const Icon(Icons.local_shipping),
          label: const Text('On The Way'),
        ),
      );
    }

    if (status == 'on_the_way') {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () {
            dBloc.add(
              DeliveryEvent.updateStatus(
                packageId: packageId,
                status: 'delivered',
              ),
            );
            // Stop location tracking when delivered
            locationBloc.add(const LocationEvent.stop());
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('Delivered'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
      buttons.add(
        OutlinedButton.icon(
          onPressed: () {
            dBloc.add(
              DeliveryEvent.contactCustomer(
                packageId: packageId,
                success: false,
              ),
            );
          },
          icon: const Icon(Icons.phone_disabled),
          label: const Text('Contact Failed'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        ),
      );
    }

    if (status == 'on_the_way' || status == 'picked_up') {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () {
            _showCodDialog(context, packageId, dBloc);
          },
          icon: const Icon(Icons.money),
          label: const Text('Collect COD'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
        ),
      );
    }

    return buttons.isEmpty
        ? [
            Text(
              'No actions available',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ]
        : buttons;
  }

  Widget _buildInfoRow(String label, String value, {bool isPhone = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: isPhone && value != 'N/A'
              ? InkWell(
                  onTap: () async {
                    final uri = Uri.parse('tel:$value');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch phone dialer'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Icon(Icons.phone, size: 18, color: Colors.blue),
                    ],
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ],
    );
  }

  void _showCodDialog(BuildContext context, int packageId, DeliveryBloc bloc) {
    final amountController = TextEditingController();
    File? proofImage;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Collect COD'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                if (proofImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      proofImage!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() => proofImage = File(image.path));
                    }
                  },
                  icon: Icon(
                    proofImage == null
                        ? Icons.add_photo_alternate
                        : Icons.change_circle,
                  ),
                  label: Text(
                    proofImage == null ? 'Add Proof Image' : 'Change Image',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount != null && amount > 0) {
                  bloc.add(
                    DeliveryEvent.collectCod(
                      packageId: packageId,
                      amount: amount,
                      imagePath: proofImage?.path,
                    ),
                  );
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Collect'),
            ),
          ],
        ),
      ),
    );
  }
}
