import 'package:document_companion/local_database/handler/image_database_handler.dart';
import 'package:document_companion/local_database/models/image_model.dart';
import 'package:document_companion/modules/home/bloc/folder_bloc.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:document_companion/modules/home/bloc/recent_documents_bloc.dart';
import 'package:document_companion/modules/home/services/pdf_service.dart';
import 'package:flutter/material.dart';

class BatchOperationsService {
  /// Batch delete multiple documents
  Future<void> batchDelete(
    BuildContext context,
    List<ImageModel> images,
    String folderId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Documents'),
        content: Text(
          'Are you sure you want to delete ${images.length} document${images.length == 1 ? '' : 's'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Delete all selected images
      for (var image in images) {
        await imageDatabaseHandler.deleteImage(image.id);
        // Also remove from recent documents
        await recentDocumentsBloc.deleteRecentDocumentByDocumentId(image.id);
      }

      // Refresh folder images
      await imageBloc.fetchImagesByFolderId(folderId);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${images.length} document${images.length == 1 ? '' : 's'} deleted successfully',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting documents: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Batch move multiple documents to a different folder
  Future<void> batchMove(
    BuildContext context,
    List<ImageModel> images,
    String sourceFolderId,
  ) async {
    // Get available folders (excluding current folder)
    final folders = folderBloc.getAllFolders();
    final availableFolders = folders
        .where((folder) => folder.id != sourceFolderId)
        .toList();

    if (availableFolders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other folders available')),
      );
      return;
    }

    String? selectedFolderId;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Move Documents'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select destination folder for ${images.length} document${images.length == 1 ? '' : 's'}:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: RadioGroup<String>(
                  groupValue: selectedFolderId,
                  onChanged: (value) {
                    if (value == null) return;
                    selectedFolderId = value;
                    Navigator.pop(dialogContext);
                    _performBatchMove(context, images, sourceFolderId, value);
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableFolders.length,
                    itemBuilder: (context, index) {
                      final folder = availableFolders[index];
                      return RadioListTile<String>(
                        title: Text(folder.folderName),
                        value: folder.id,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBatchMove(
    BuildContext context,
    List<ImageModel> images,
    String sourceFolderId,
    String destinationFolderId,
  ) async {
    if (!context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Move all selected images
      for (var image in images) {
        await imageDatabaseHandler.updateImage(
          image.copyWith(folderId: destinationFolderId),
        );
      }

      // Refresh folder images
      await imageBloc.fetchImagesByFolderId(sourceFolderId);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${images.length} document${images.length == 1 ? '' : 's'} moved successfully',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error moving documents: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Batch convert multiple images to PDF
  Future<void> batchConvertToPdf(
    BuildContext context,
    List<ImageModel> images,
  ) async {
    if (!context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Convert images to Uint8List format
      final imageBytes = [for (final image in images) await image.readBytes()];

      // Create PDF from images
      final pdfBytes = await pdfService.createPdfFromImageBytes(imageBytes);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show PDF options (save/share/print)
      final fileName = 'batch_${DateTime.now().millisecondsSinceEpoch}';
      await pdfService.showPdfOptions(context, pdfBytes, fileName);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error converting to PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

final batchOperationsService = BatchOperationsService();
