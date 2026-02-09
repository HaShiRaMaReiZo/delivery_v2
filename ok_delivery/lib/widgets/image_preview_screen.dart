import 'dart:io';
import 'package:flutter/material.dart';

/// Reusable image preview screen that can be used throughout the project
/// Supports both network URLs and local File objects
class ImagePreviewScreen extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final String? title;

  const ImagePreviewScreen({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.title,
  }) : assert(
         imageUrl != null || imageFile != null,
         'Either imageUrl or imageFile must be provided',
       );

  /// Static method to easily navigate to image preview with network URL
  static void show(BuildContext context, String imageUrl, {String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ImagePreviewScreen(imageUrl: imageUrl, title: title),
      ),
    );
  }

  /// Static method to easily navigate to image preview with local File
  static void showFile(BuildContext context, File imageFile, {String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ImagePreviewScreen(imageFile: imageFile, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 48,
        title: title != null
            ? Text(title!, style: const TextStyle(color: Colors.white))
            : null,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: imageFile != null
              ? Image.file(
                  imageFile!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
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
}
