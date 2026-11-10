import 'package:document_companion/local_database/handler/local_database_handler.dart';

import '../models/folder_model.dart';

class FolderTableHandler {
  static const _tableName = 'Folders';
  /*
  Table Name - Folders
  Columns - id | folder_name | created_on | modified_on
   */

  Future<void> insertFolder(FolderModel tableData) async {
    final database = await localDatabaseHandler.db;
    await database?.insert(_tableName, tableData.toMap());
  }

  Future<List<FolderModel>> getFolders() async {
    final database = await localDatabaseHandler.db;
    final maps = await database?.query(_tableName);
    return List.generate(maps?.length ?? 0, (i) {
      final map = maps?.elementAt(i);
      final id = map!['id'].toString();
      final createdOn = map['created_on'].toString();
      final folderName = map['folder_name'].toString();
      final modifiedOn = map['modified_on'].toString();
      return FolderModel(
        id: id,
        createdOn: createdOn,
        folderName: folderName,
        modifiedOn: modifiedOn,
      );
    });
  }

  Future<void> updateFolder(FolderModel folder) async {
    final database = await localDatabaseHandler.db;
    await database?.update(
      _tableName,
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<void> deleteFolder(String folderId) async {
    final database = await localDatabaseHandler.db;
    await database?.delete(_tableName, where: 'id = ?', whereArgs: [folderId]);
  }
}

final folderTableHandler = FolderTableHandler();
