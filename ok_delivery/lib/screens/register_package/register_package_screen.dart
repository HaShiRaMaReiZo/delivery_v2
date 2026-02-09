import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../models/package_model.dart';
import '../../repositories/package_repository.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../widgets/image_preview_screen.dart';
import 'register_package_widgets.dart';

// Helper class to store package with its image and draft ID
class PackageWithImage {
  final CreatePackageModel package;
  final File? imageFile;
  int? draftId; // Store draft ID after saving to API

  PackageWithImage({required this.package, this.imageFile, this.draftId});
}

class RegisterPackageScreen extends StatefulWidget {
  const RegisterPackageScreen({super.key});

  @override
  State<RegisterPackageScreen> createState() => _RegisterPackageScreenState();
}

class _RegisterPackageScreenState extends State<RegisterPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _packageRepository = PackageRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );

  // Current package form fields
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _amountController = TextEditingController();
  final _packageDescriptionController = TextEditingController();

  String _paymentType = 'cod';
  File? _selectedImage;
  final List<PackageWithImage> _packageList = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _deliveryAddressController.dispose();
    _amountController.dispose();
    _packageDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Check camera permission status first (this doesn't show a dialog)
      final cameraStatus = await Permission.camera.status;

      // Only request permission if not already granted
      // This will show the system permission dialog when user clicks the button
      if (!cameraStatus.isGranted) {
        final result = await Permission.camera.request();

        if (!result.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Camera permission is required to take photos. Please grant permission in settings.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // Open camera to take photo
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _clearForm() {
    _customerNameController.clear();
    _customerPhoneController.clear();
    _deliveryAddressController.clear();
    _amountController.clear();
    _packageDescriptionController.clear();
    _paymentType = 'cod';
    setState(() {
      _selectedImage = null;
    });
  }

  Future<String?> _encodeImageToBase64(File? imageFile) async {
    if (imageFile == null) return null;
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  Future<void> _addToPackageList() async {
    if (_formKey.currentState!.validate()) {
      // Validate image is required
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add a package photo (required)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final base64Image = await _encodeImageToBase64(_selectedImage);

        final package = CreatePackageModel(
          customerName: _customerNameController.text.trim(),
          customerPhone: _customerPhoneController.text.trim(),
          deliveryAddress: _deliveryAddressController.text.trim(),
          paymentType: _paymentType,
          amount: amount,
          packageImage: base64Image,
          packageDescription: _packageDescriptionController.text.trim().isEmpty
              ? null
              : _packageDescriptionController.text.trim(),
        );

        // Save to draft API
        final response = await _packageRepository.saveDraft([package]);

        // Debug: Log response details
        debugPrint('SaveDraft Response:');
        debugPrint('  - createdCount: ${response.createdCount}');
        debugPrint('  - failedCount: ${response.failedCount}');
        debugPrint('  - packages.length: ${response.packages.length}');
        debugPrint('  - errors.length: ${response.errors.length}');
        if (response.imageUploadErrors != null) {
          debugPrint(
            '  - imageUploadErrors.length: ${response.imageUploadErrors!.length}',
          );
        }

        // Check if package was created successfully (even if image upload failed)
        // The package is saved even if image upload fails, so check createdCount too
        if (response.packages.isNotEmpty || response.createdCount > 0) {
          // If packages list is empty but createdCount > 0, the package was saved but parsing failed
          // In this case, we should still add it to the queue using the original package data
          if (response.packages.isNotEmpty) {
            final savedPackage = response.packages.first;
            setState(() {
              _packageList.add(
                PackageWithImage(
                  package: package,
                  imageFile: _selectedImage,
                  draftId: savedPackage.id,
                ),
              );
            });
          } else {
            // Package was saved but parsing failed - we can't get the ID
            // This shouldn't happen, but handle it gracefully
            debugPrint(
              'WARNING: Package created but parsing failed. createdCount: ${response.createdCount}',
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Package saved but could not be added to queue. Please refresh.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return; // Exit early since we can't add to queue without ID
          }

          _clearForm();

          if (mounted) {
            // Show success message, but warn about image upload errors
            String message =
                'Package saved to draft (${_packageList.length} total)';
            if (response.imageUploadErrors != null &&
                response.imageUploadErrors!.isNotEmpty) {
              message += '\n⚠️ Image upload failed, but package was saved';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor:
                    response.imageUploadErrors != null &&
                        response.imageUploadErrors!.isNotEmpty
                    ? Colors.orange
                    : Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Package creation failed
          String errorMsg = 'Failed to save package to draft';
          if (response.errors.isNotEmpty) {
            errorMsg = response.errors.first.error;
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  Future<void> _submitPackages() async {
    if (_packageList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one package')),
      );
      return;
    }

    // Get all draft IDs
    final draftIds = _packageList
        .where((item) => item.draftId != null)
        .map((item) => item.draftId!)
        .toList();

    if (draftIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid draft packages to submit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Submit drafts to system
      final response = await _packageRepository.submitDrafts(draftIds);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submission Result'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${response.submittedCount > 0 ? response.submittedCount : response.createdCount} package(s) submitted successfully',
                ),
                if (response.failedCount > 0)
                  Text(
                    '${response.failedCount} package(s) failed',
                    style: const TextStyle(color: Colors.red),
                  ),
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
                  Navigator.of(context).pop();
                  setState(() {
                    _packageList.clear();
                    _clearForm();
                  });
                  Navigator.of(context).pop(); // Go back to home
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _removeFromPackageList(int index) {
    setState(() {
      _packageList.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Package removed from list')));
  }

  double _getTotalAmount() {
    return _packageList.fold(0.0, (sum, item) => sum + item.package.amount);
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _getTotalAmount();

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: Column(
        children: [
          // Custom Header
          RegisterPackageHeader(
            packageCount: _packageList.length,
            onBack: () => Navigator.of(context).pop(),
            onSubmit: _submitPackages,
            isSubmitting: _isSubmitting,
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Package Queue Summary
                  if (_packageList.isNotEmpty) ...[
                    PackageQueueSummary(
                      packageCount: _packageList.length,
                      totalAmount: totalAmount,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Package List
                  if (_packageList.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.list,
                          size: 16,
                          color: AppTheme.neutral500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Queued Packages',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.neutral600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_packageList.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QueuedPackageCard(
                          package: _packageList[index],
                          index: index,
                          onRemove: () => _removeFromPackageList(index),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Registration Form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.neutral200),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Package Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.neutral900,
                                ),
                              ),
                              Text(
                                '* Required',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.yellow600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Customer Name
                          _buildFormField(
                            label: 'Customer Name',
                            icon: Icons.person,
                            controller: _customerNameController,
                            hint: 'Enter customer name',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter customer name';
                              }
                              return null;
                            },
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),

                          // Customer Phone
                          _buildFormField(
                            label: 'Customer Phone',
                            icon: Icons.phone,
                            controller: _customerPhoneController,
                            hint: '09-XXX-XXX-XXX',
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter phone number';
                              }
                              return null;
                            },
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),

                          // Delivery Address
                          _buildFormField(
                            label: 'Delivery Address',
                            icon: Icons.home,
                            controller: _deliveryAddressController,
                            hint: 'House No, Street, etc.',
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter delivery address';
                              }
                              return null;
                            },
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),

                          // Payment Type & Amount Grid
                          Row(
                            children: [
                              Expanded(child: _buildPaymentTypeSelector()),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFormField(
                                  label: 'Amount',
                                  icon: Icons.currency_exchange,
                                  controller: _amountController,
                                  hint: 'MMK',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount < 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                  isRequired: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Package Description
                          _buildFormField(
                            label: 'Description',
                            icon: Icons.description,
                            controller: _packageDescriptionController,
                            hint: 'Package contents, special instructions...',
                            maxLines: 3,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),

                          // Photo Button
                          _buildPhotoButton(),
                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _addToPackageList,
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text('Add to Queue'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.neutral100,
                                    foregroundColor: AppTheme.neutral900,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () async {
                                          await _addToPackageList();
                                        },
                                  icon: const Icon(Icons.save, size: 20),
                                  label: const Text('Save Draft'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.yellow400,
                                    foregroundColor: AppTheme.neutral900,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Help Tip Box
                  const HelpTipBox(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.yellow600),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.neutral700),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(fontSize: 13, color: AppTheme.yellow600),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.neutral50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.neutral300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.neutral300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.yellow400, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.credit_card, size: 16, color: AppTheme.yellow600),
            const SizedBox(width: 6),
            const Text(
              'Payment',
              style: TextStyle(fontSize: 13, color: AppTheme.neutral700),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(fontSize: 13, color: AppTheme.yellow600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _paymentType,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.neutral50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.neutral300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.neutral300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.yellow400, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.neutral600,
            size: 20,
          ),
          iconSize: 20,
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.neutral900,
            fontWeight: FontWeight.w500,
          ),
          borderRadius: BorderRadius.circular(16),
          items: [
            DropdownMenuItem<String>(
              value: 'cod',
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.yellow50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.yellow200),
                      ),
                      child: const Icon(
                        Icons.money,
                        size: 16,
                        color: AppTheme.yellow600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'COD',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.neutral900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.yellow50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Cash on Delivery',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.yellow700,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'prepaid',
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.neutral100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.neutral200),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 16,
                        color: AppTheme.neutral600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'Prepaid',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.neutral900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.neutral100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Prepaid',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.neutral600,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          selectedItemBuilder: (BuildContext context) {
            return [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.yellow50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.yellow200),
                    ),
                    child: const Icon(
                      Icons.money,
                      size: 14,
                      color: AppTheme.yellow600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'COD',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.neutral900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.neutral100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.neutral200),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 14,
                      color: AppTheme.neutral600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Prepaid',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.neutral900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ];
          },
          onChanged: (value) {
            setState(() {
              _paymentType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPhotoButton() {
    if (_selectedImage != null) {
      return GestureDetector(
        onTap: () {
          ImagePreviewScreen.showFile(
            context,
            _selectedImage!,
            title: 'Package Image Preview',
          );
        },
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.yellow400, width: 2),
            color: AppTheme.yellow50,
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.neutral300,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, color: AppTheme.neutral600, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Add Package Photo',
              style: TextStyle(color: AppTheme.neutral600),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(color: AppTheme.yellow600, fontSize: 16),
            ),
            const SizedBox(width: 2),
            Text(
              'Required',
              style: TextStyle(color: AppTheme.yellow600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
