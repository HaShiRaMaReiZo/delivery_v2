import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/package_model.dart';
import '../../core/utils/date_utils.dart' as myanmar_date;
import 'live_tracking_map_screen.dart';

class TrackDateDetailScreen extends StatefulWidget {
  final DateTime date;
  final List<PackageModel> packages;

  const TrackDateDetailScreen({
    super.key,
    required this.date,
    required this.packages,
  });

  @override
  State<TrackDateDetailScreen> createState() => _TrackDateDetailScreenState();
}

class _TrackDateDetailScreenState extends State<TrackDateDetailScreen> {
  late List<PackageModel> _packages;

  @override
  void initState() {
    super.initState();
    _packages = List.from(widget.packages);
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'registered':
        return Colors.blue;
      case 'assigned_to_rider':
        return Colors.orange;
      case 'picked_up':
        return Colors.purple;
      case 'on_the_way':
        return Colors.green;
      case 'delivered':
        return Colors.teal;
      case 'contact_failed':
        return Colors.red;
      case 'return_to_office':
        return Colors.amber;
      case 'returned_to_merchant':
        return Colors.brown;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    if (status == null) return 'Draft';
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final now = myanmar_date.MyanmarDateUtils.getMyanmarNow();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return myanmar_date.MyanmarDateUtils.formatDate(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBeige,
      appBar: AppBar(
        title: Text('Packages - ${_formatDate(widget.date)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 48,
      ),
      body: _packages.isEmpty
          ? const Center(
              child: Text(
                'No packages found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                final package = _packages[index];
                final canTrack = package.status == 'on_the_way';
                final statusColor = _getStatusColor(package.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Customer Name and Status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                package.customerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                _getStatusLabel(package.status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Tracking Code
                        if (package.trackingCode != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.qr_code,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tracking: ${package.trackingCode}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        if (package.trackingCode != null)
                          const SizedBox(height: 8),
                        // Delivery Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppTheme.darkBlue,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                package.deliveryAddress,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Registered Date
                        if (package.registeredAt != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Registered: ${myanmar_date.MyanmarDateUtils.formatDateTime(package.registeredAt!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        if (package.registeredAt != null)
                          const SizedBox(height: 8),
                        // Last Update Time
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Updated: ${myanmar_date.MyanmarDateUtils.formatDateTime(package.updatedAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Track Live Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: canTrack
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LiveTrackingMapScreen(
                                              package: package,
                                            ),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.location_on),
                            label: Text(
                              canTrack
                                  ? 'Track Live'
                                  : 'Tracking available when package is on the way',
                              style: const TextStyle(fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canTrack
                                  ? AppTheme.darkBlue
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
