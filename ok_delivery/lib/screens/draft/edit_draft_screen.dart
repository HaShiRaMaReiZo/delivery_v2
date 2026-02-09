import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../models/package_model.dart';
import '../../repositories/package_repository.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../widgets/image_preview_screen.dart';

class EditDraftScreen extends StatefulWidget {
  final PackageModel package;

  const EditDraftScreen({super.key, required this.package});

  @override
  State<EditDraftScreen> createState() => _EditDraftScreenState();
}

class _EditDraftScreenState extends State<EditDraftScreen> {
  final _formKey = GlobalKey<FormState>();
  final _packageRepository = PackageRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );

  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _amountController = TextEditingController();
  final _packageDescriptionController = TextEditingController();

  String _paymentType = 'prepaid';
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isSubmitting = false;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _loadPackageData();
  }

  void _loadPackageData() {
    _customerNameController.text = widget.package.customerName;
    _customerPhoneController.text = widget.package.customerPhone;
    _deliveryAddressController.text = widget.package.deliveryAddress;
    _amountController.text = widget.package.amount.toStringAsFixed(2);
    _packageDescriptionController.text =
        widget.package.packageDescription ?? '';
    _paymentType = widget.package.paymentType;
    _currentImageUrl = widget.package.packageImage;
  }

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
      final cameraStatus = await Permission.camera.status;

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
          _imageChanged = true;
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

  Future<String?> _encodeImageToBase64(File? imageFile) async {
    if (imageFile == null) return null;
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  Future<void> _updatePackage() async {
    if (_formKey.currentState!.validate()) {
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
        String? base64Image;

        // Handle image updates
        if (_imageChanged) {
          if (_selectedImage != null) {
            // New image selected - encode it
            base64Image = await _encodeImageToBase64(_selectedImage);
          } else {
            // Image was removed - send empty string to delete
            base64Image = '';
          }
        }
        // If image not changed, base64Image stays null and won't be sent

        final package = CreatePackageModel(
          customerName: _customerNameController.text.trim(),
          customerPhone: _customerPhoneController.text.trim(),
          deliveryAddress: _deliveryAddressController.text.trim(),
          paymentType: _paymentType,
          amount: amount,
          packageImage:
              base64Image, // Will be null if not changed, empty string if removed, base64 if new
          packageDescription: _packageDescriptionController.text.trim().isEmpty
              ? null
              : _packageDescriptionController.text.trim(),
        );

        await _packageRepository.updateDraft(widget.package.id, package);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate update
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBeige,
      appBar: AppBar(
        title: const Text('Edit Package'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 48,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Package Image
              if (_selectedImage != null)
                GestureDetector(
                  onTap: () {
                    // Show preview of selected image
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else if (_currentImageUrl != null && !_imageChanged)
                GestureDetector(
                  onTap: () {
                    ImagePreviewScreen.show(
                      context,
                      _currentImageUrl!,
                      title: 'Package Image',
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _currentImageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.error)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  _selectedImage != null || _currentImageUrl != null
                      ? 'Change Package Image'
                      : 'Add Package Image',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.darkBlue),
                ),
              ),
              if (_selectedImage != null || _currentImageUrl != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                      _currentImageUrl = null;
                      _imageChanged = true;
                    });
                  },
                  child: const Text(
                    'Remove Image',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Customer Name
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Customer Phone
              TextFormField(
                controller: _customerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Customer Phone *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter customer phone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Delivery Address
              TextFormField(
                controller: _deliveryAddressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address *',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter delivery address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Payment Type
              DropdownButtonFormField<String>(
                value: _paymentType,
                decoration: const InputDecoration(
                  labelText: 'Payment Type *',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: const [
                  DropdownMenuItem(value: 'prepaid', child: Text('Prepaid')),
                  DropdownMenuItem(
                    value: 'cod',
                    child: Text('Cash on Delivery (COD)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _paymentType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount < 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Package Description
              TextFormField(
                controller: _packageDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Package Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              // Update Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _updatePackage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Update Package',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
