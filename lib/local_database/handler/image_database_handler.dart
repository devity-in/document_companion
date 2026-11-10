import 'package:document_companion/local_database/handler/local_database_handler.dart';
import 'package:document_companion/local_database/models/image_model.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../document_file_store.dart';

class ImageDatabaseHandler {
  static const _tableName = 'Images';

  /// Incremented whenever documents are added, moved or removed, so that
  /// widgets showing counts can refresh.
  final ValueNotifier<int> changes = ValueNotifier(0);

  Future<void> insertImage(ImageModel image) async {
    final database = await localDatabaseHandler.db;
    await database?.insert(
      _tableName,
      image.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    changes.value++;
  }

  Future<List<ImageModel>> getImagesByFolderId(String folderId) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _tableName,
      columns: ImageModel.columns,
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'created_on DESC',
    );
    return List.generate(maps?.length ?? 0, (i) {
      return ImageModel.fromMap(maps![i]);
    });
  }

  Future<List<ImageModel>> getAllImages() async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _tableName,
      columns: ImageModel.columns,
      orderBy: 'created_on DESC',
    );
    return List.generate(maps?.length ?? 0, (i) {
      return ImageModel.fromMap(maps![i]);
    });
  }

  Future<ImageModel?> getImageById(String id) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _tableName,
      columns: ImageModel.columns,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps != null && maps.isNotEmpty) {
      return ImageModel.fromMap(maps.first);
    }
    return null;
  }

  /// Deletes the row and the image file behind it.
  Future<void> deleteImage(String id) async {
    final database = await localDatabaseHandler.db;
    final image = await getImageById(id);
    await database?.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    await documentFileStore.delete(image?.filePath);
    changes.value++;
  }

  Future<void> deleteImagesByFolderId(String folderId) async {
    final database = await localDatabaseHandler.db;
    final paths = await database?.query(
      _tableName,
      columns: ['file_path'],
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
    await database?.delete(
      _tableName,
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
    for (final row in paths ?? const <Map<String, Object?>>[]) {
      await documentFileStore.delete(row['file_path'] as String?);
    }
    changes.value++;
  }

  Future<int> getImageCountByFolderId(String folderId) async {
    final database = await localDatabaseHandler.db;
    final result = await database?.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE folder_id = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result ?? []) ?? 0;
  }

  Future<void> updateImage(ImageModel image) async {
    final database = await localDatabaseHandler.db;
    await database?.update(
      _tableName,
      image.toMap(),
      where: 'id = ?',
      whereArgs: [image.id],
    );
    changes.value++;
  }
}

final imageDatabaseHandler = ImageDatabaseHandler();
