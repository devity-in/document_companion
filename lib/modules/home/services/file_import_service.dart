import 'dart:developer' as developer;
import 'dart:io';

import 'package:document_companion/local_database/document_repository.dart';
import 'package:document_companion/modules/home/bloc/current_image_bloc.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class FileImportService {
  final ImagePicker _picker = ImagePicker();

  void _showError(BuildContext context, Object error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error importing images: $error'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Picks one image and stages it for the preview screen.
  /// Returns the number of images staged (0 or 1).
  Future<int> importImageFromGallery(BuildContext context) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return 0;
      await currentImageBloc.saveCurrentImageFile(File(image.path));
      await currentImageBloc.getCurrentImage();
      return 1;
    } catch (e) {
      if (context.mounted) _showError(context, e);
      return 0;
    }
  }

  /// Picks several images and stages them for the preview screen.
  /// Returns the number of images staged.
  Future<int> importMultipleImagesFromGallery(BuildContext context) async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 90);
      for (final image in images) {
        await currentImageBloc.saveCurrentImageFile(File(image.path));
      }
      await currentImageBloc.getCurrentImage();
      return images.length;
    } catch (e) {
      if (context.mounted) _showError(context, e);
      return 0;
    }
  }

  /// Picks images and saves them straight into [folderId].
  /// Returns the number of images saved.
  Future<int> importImagesToFolder(
    BuildContext context,
    String folderId,
  ) async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 90);
      for (final image in images) {
        await documentRepository.addFromFile(
          folderId: folderId,
          name: p.basenameWithoutExtension(image.name),
          source: File(image.path),
        );
      }
      if (images.isNotEmpty) {
        await imageBloc.fetchImagesByFolderId(folderId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Imported ${images.length} image${images.length == 1 ? '' : 's'}',
              ),
            ),
          );
        }
      }
      return images.length;
    } catch (e) {
      developer.log('Error importing images to folder', error: e);
      if (context.mounted) _showError(context, e);
      return 0;
    }
  }

  /// Asks how many images to import, then imports them.
  /// Returns the number of images staged for the preview screen.
  Future<int> showImportOptions(BuildContext context) async {
    final multiple = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Import Single Image'),
                subtitle: const Text('Select one image from gallery'),
                onTap: () => Navigator.pop(context, false),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Import Multiple Images'),
                subtitle: const Text('Select multiple images from gallery'),
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (multiple == null || !context.mounted) return 0;
    return multiple
        ? importMultipleImagesFromGallery(context)
        : importImageFromGallery(context);
  }
}

final fileImportService = FileImportService();
