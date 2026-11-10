import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import '../../../local_database/document_repository.dart';
import '../../../local_database/handler/current_images_database_handler.dart';
import '../../../local_database/models/current_image.dart';

class CurrentImageBloc {
  final StreamController<List<CurrentImage>> _currentImageController =
      StreamController<List<CurrentImage>>.broadcast();
  Stream<List<CurrentImage>> get currentImageStream =>
      _currentImageController.stream;

  final CurrentImageDatabaseHandler _databaseHandler =
      CurrentImageDatabaseHandler();

  /// Stages image bytes for the current session.
  Future<void> saveCurrentImage(Uint8List currentImage) async {
    try {
      await documentRepository.addPendingFromBytes(currentImage);
    } catch (e) {
      developer.log('Error saving current image', error: e);
    }
  }

  /// Stages an image file (e.g. a scanner result) for the current session.
  Future<void> saveCurrentImageFile(File file) async {
    try {
      await documentRepository.addPendingFromFile(file);
    } catch (e) {
      developer.log('Error saving current image', error: e);
    }
  }

  /// Removes one page from the current session.
  Future<void> deleteCurrentImageItem(CurrentImage image) async {
    try {
      await _databaseHandler.deleteImage(image);
      await getCurrentImage();
    } catch (e) {
      developer.log('Error deleting current image', error: e);
    }
  }

  Future<void> getCurrentImage() async {
    try {
      final currentImage = await _databaseHandler.getCurrentImage();
      _currentImageController.sink.add(currentImage);
    } catch (e) {
      developer.log('Error getting current image', error: e);
      return;
    }
  }

  Future<void> deleteCurrentImages() async {
    try {
      await _databaseHandler.deleteCurrentImage();
      await getCurrentImage(); // Refresh stream after deletion
    } catch (e) {
      developer.log('Error deleting current images', error: e);
    }
  }

  Future<List<CurrentImage>> getCurrentImagesList() async {
    try {
      return await _databaseHandler.getCurrentImage();
    } catch (e) {
      developer.log('Error getting current images list', error: e);
      return [];
    }
  }
}

final currentImageBloc = CurrentImageBloc();
