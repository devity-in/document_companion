import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'document_file_store.dart';
import 'handler/current_images_database_handler.dart';
import 'handler/image_database_handler.dart';
import 'models/current_image.dart';
import 'models/image_model.dart';

/// Creates documents: writes the image file, builds its thumbnail and inserts
/// the database row.
class DocumentRepository {
  final _uuid = const Uuid();
  final _pending = CurrentImageDatabaseHandler();

  static String timestampOf(DateTime time) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(time);

  /// Saves [bytes] as a new document in [folderId].
  Future<ImageModel> addFromBytes({
    required String folderId,
    required String name,
    required Uint8List bytes,
  }) async {
    final id = _uuid.v4();
    final filePath = await documentFileStore.write(
      DocumentFileStore.documentsFolder,
      id,
      bytes,
    );
    return _insert(id: id, folderId: folderId, name: name, filePath: filePath);
  }

  /// Copies [source] into the store as a new document in [folderId].
  Future<ImageModel> addFromFile({
    required String folderId,
    required String name,
    required File source,
  }) async {
    final id = _uuid.v4();
    final filePath = await documentFileStore.importFile(
      DocumentFileStore.documentsFolder,
      id,
      source,
    );
    return _insert(id: id, folderId: folderId, name: name, filePath: filePath);
  }

  /// Stages an image for the current session (shown in the preview screen
  /// until it is saved to a folder or discarded).
  Future<CurrentImage> addPendingFromBytes(Uint8List bytes) async {
    final id = _uuid.v4();
    final filePath = await documentFileStore.write(
      DocumentFileStore.pendingFolder,
      id,
      bytes,
    );
    return _insertPending(id, filePath);
  }

  Future<CurrentImage> addPendingFromFile(File source) async {
    final id = _uuid.v4();
    final filePath = await documentFileStore.importFile(
      DocumentFileStore.pendingFolder,
      id,
      source,
    );
    return _insertPending(id, filePath);
  }

  /// Saves every pending page into each of [folderIds] and clears the
  /// session. Returns the number of pages that were saved per folder.
  Future<int> savePendingToFolders(List<String> folderIds) async {
    final pending = await _pending.getCurrentImage();
    if (pending.isEmpty || folderIds.isEmpty) return 0;

    final baseName =
        'Scan ${DateFormat('yyyy-MM-dd HH.mm').format(DateTime.now())}';
    for (final folderId in folderIds) {
      for (var i = 0; i < pending.length; i++) {
        await addFromFile(
          folderId: folderId,
          name: pending.length == 1 ? baseName : '$baseName (${i + 1})',
          source: pending[i].file,
        );
      }
    }
    await _pending.deleteCurrentImage();
    return pending.length;
  }

  Future<CurrentImage> _insertPending(String id, String filePath) async {
    final image = CurrentImage(
      id: id,
      filePath: filePath,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString().padLeft(
        15,
        '0',
      ),
    );
    await _pending.insertImage(image);
    return image;
  }

  Future<ImageModel> _insert({
    required String id,
    required String folderId,
    required String name,
    required String filePath,
  }) async {
    final file = documentFileStore.fileFor(filePath);
    final description = await documentFileStore.describe(file);
    final timestamp = timestampOf(DateTime.now());
    final image = ImageModel(
      id: id,
      folderId: folderId,
      filePath: filePath,
      thumbnail: description.thumbnail,
      name: name,
      createdOn: timestamp,
      modifiedOn: timestamp,
      size: await file.length(),
      width: description.width,
      height: description.height,
    );
    await imageDatabaseHandler.insertImage(image);
    return image;
  }
}

final documentRepository = DocumentRepository();
