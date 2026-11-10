import 'package:document_companion/local_database/handler/local_database_handler.dart';
import 'package:sqflite/sqflite.dart';

/// Small key/value store for app preferences.
class SettingsDatabaseHandler {
  static const _tableName = 'Settings';

  Future<String?> getValue(String key) async {
    final database = await localDatabaseHandler.db;
    final rows = await database?.query(
      _tableName,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows == null || rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setValue(String key, String value) async {
    final database = await localDatabaseHandler.db;
    await database?.insert(_tableName, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

final settingsDatabaseHandler = SettingsDatabaseHandler();
