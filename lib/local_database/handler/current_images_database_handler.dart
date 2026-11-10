import 'package:document_companion/local_database/handler/local_database_handler.dart';

import '../document_file_store.dart';
import '../models/current_image.dart';

/// Pages captured in the current session, waiting to be saved to a folder.
class CurrentImageDatabaseHandler {
  static const _tableName = 'CurrentImages';

  Future<void> insertImage(CurrentImage currentImage) async {
    final database = await localDatabaseHandler.db;
    await database?.insert(_tableName, currentImage.toMap());
  }

  Future<List<CurrentImage>> getCurrentImage() async {
    final database = await localDatabaseHandler.db;
    final maps = await database?.query(_tableName, orderBy: 'timestamp ASC');
    return [for (final map in maps ?? const []) CurrentImage.fromMap(map)];
  }

  /// Removes a single pending page and its file.
  Future<void> deleteImage(CurrentImage image) async {
    final database = await localDatabaseHandler.db;
    await database?.delete(_tableName, where: 'id = ?', whereArgs: [image.id]);
    await documentFileStore.delete(image.filePath);
  }

  /// Clears the whole session, deleting any files still in the pending folder.
  Future<void> deleteCurrentImage() async {
    final images = await getCurrentImage();
    final database = await localDatabaseHandler.db;
    await database?.delete(_tableName);
    for (final image in images) {
      await documentFileStore.delete(image.filePath);
    }
  }
}
