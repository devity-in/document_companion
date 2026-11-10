import 'dart:io' as io;
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../document_file_store.dart';

class LocalDatabaseHandler {
  static const databaseName = 'document_companion.db';
  static const _legacyDatabaseName = 'test.db';
  static const databaseVersion = 6;

  static Database? _db;

  /// Overrides where the database is opened. Used by tests.
  static String? pathOverride;

  Future<Database?> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  /// Closes the database so the next access reopens it. Used by tests.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<Database?> initDb() async {
    await documentFileStore.init();
    var path = pathOverride;
    if (path == null) {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, databaseName);
      // Early builds shipped the database as "test.db".
      final legacy = io.File(
        join(documentsDirectory.path, _legacyDatabaseName),
      );
      if (await legacy.exists() && !await io.File(path).exists()) {
        await legacy.rename(path);
      }
    }
    return openDatabase(
      path,
      version: databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static const _createCurrentImages =
      "CREATE TABLE CurrentImages(id TEXT PRIMARY KEY, file_path TEXT, timestamp TEXT)";
  static const _createSettings =
      "CREATE TABLE IF NOT EXISTS Settings(key TEXT PRIMARY KEY, value TEXT)";

  Future<void> _onCreate(Database db, int version) async {
    // When creating the db, create the table
    // Create [CurrentImage] table
    await db.execute(_createCurrentImages);
    await db.execute(_createSettings);
    // Create [Folders] table
    await db.execute(
      "CREATE TABLE Folders(id TEXT PRIMARY KEY, folder_name TEXT, created_on TEXT, modified_on TEXT )",
    );
    // Create [Images] table for folder-linked images
    await db.execute(
      "CREATE TABLE Images(id TEXT PRIMARY KEY, folder_id TEXT, file_path TEXT, thumbnail BLOB, name TEXT, created_on TEXT, modified_on TEXT, size INTEGER, width INTEGER, height INTEGER, FOREIGN KEY (folder_id) REFERENCES Folders(id) ON DELETE CASCADE)",
    );
    // Create [RecentDocuments] table for tracking recently accessed documents
    await db.execute(
      "CREATE TABLE RecentDocuments(id TEXT PRIMARY KEY, document_id TEXT, document_type TEXT, folder_id TEXT, document_name TEXT, accessed_on TEXT, thumbnail BLOB)",
    );
    // Create [Tags] table
    await db.execute(
      "CREATE TABLE Tags(id TEXT PRIMARY KEY, name TEXT UNIQUE, color TEXT, created_on TEXT)",
    );
    // Create [Folder_Tags] junction table
    await db.execute(
      "CREATE TABLE Folder_Tags(folder_id TEXT, tag_id TEXT, PRIMARY KEY (folder_id, tag_id), FOREIGN KEY (folder_id) REFERENCES Folders(id) ON DELETE CASCADE, FOREIGN KEY (tag_id) REFERENCES Tags(id) ON DELETE CASCADE)",
    );
    // Create [Document_Tags] junction table
    await db.execute(
      "CREATE TABLE Document_Tags(document_id TEXT, tag_id TEXT, PRIMARY KEY (document_id, tag_id), FOREIGN KEY (document_id) REFERENCES Images(id) ON DELETE CASCADE, FOREIGN KEY (tag_id) REFERENCES Tags(id) ON DELETE CASCADE)",
    );

    // Create indexes for better query performance
    await db.execute("CREATE INDEX idx_images_folder_id ON Images(folder_id)");
    await db.execute(
      "CREATE INDEX idx_images_created_on ON Images(created_on)",
    );
    await db.execute(
      "CREATE INDEX idx_images_modified_on ON Images(modified_on)",
    );
    await db.execute(
      "CREATE INDEX idx_folders_created_on ON Folders(created_on)",
    );
    await db.execute(
      "CREATE INDEX idx_folders_modified_on ON Folders(modified_on)",
    );
    await db.execute(
      "CREATE INDEX idx_recent_documents_accessed_on ON RecentDocuments(accessed_on)",
    );
    await db.execute(
      "CREATE INDEX idx_recent_documents_document_id ON RecentDocuments(document_id)",
    );
    await db.execute(
      "CREATE INDEX idx_folder_tags_folder_id ON Folder_Tags(folder_id)",
    );
    await db.execute(
      "CREATE INDEX idx_folder_tags_tag_id ON Folder_Tags(tag_id)",
    );
    await db.execute(
      "CREATE INDEX idx_document_tags_document_id ON Document_Tags(document_id)",
    );
    await db.execute(
      "CREATE INDEX idx_document_tags_tag_id ON Document_Tags(tag_id)",
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add Images table for existing databases
      await db.execute(
        "CREATE TABLE IF NOT EXISTS Images(id TEXT PRIMARY KEY, folder_id TEXT, image BLOB, name TEXT, created_on TEXT, modified_on TEXT, size INTEGER, width INTEGER, height INTEGER, FOREIGN KEY (folder_id) REFERENCES Folders(id) ON DELETE CASCADE)",
      );
    }
    if (oldVersion < 3) {
      // Add RecentDocuments table for tracking recently accessed documents
      await db.execute(
        "CREATE TABLE IF NOT EXISTS RecentDocuments(id TEXT PRIMARY KEY, document_id TEXT, document_type TEXT, folder_id TEXT, document_name TEXT, accessed_on TEXT, thumbnail BLOB)",
      );
    }
    if (oldVersion < 4) {
      // Add Tags table
      await db.execute(
        "CREATE TABLE IF NOT EXISTS Tags(id TEXT PRIMARY KEY, name TEXT UNIQUE, color TEXT, created_on TEXT)",
      );
      // Add Folder_Tags junction table
      await db.execute(
        "CREATE TABLE IF NOT EXISTS Folder_Tags(folder_id TEXT, tag_id TEXT, PRIMARY KEY (folder_id, tag_id), FOREIGN KEY (folder_id) REFERENCES Folders(id) ON DELETE CASCADE, FOREIGN KEY (tag_id) REFERENCES Tags(id) ON DELETE CASCADE)",
      );
      // Add Document_Tags junction table
      await db.execute(
        "CREATE TABLE IF NOT EXISTS Document_Tags(document_id TEXT, tag_id TEXT, PRIMARY KEY (document_id, tag_id), FOREIGN KEY (document_id) REFERENCES Images(id) ON DELETE CASCADE, FOREIGN KEY (tag_id) REFERENCES Tags(id) ON DELETE CASCADE)",
      );

      // Create indexes for better query performance
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_images_folder_id ON Images(folder_id)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_images_created_on ON Images(created_on)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_images_modified_on ON Images(modified_on)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_folders_created_on ON Folders(created_on)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_folders_modified_on ON Folders(modified_on)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_recent_documents_accessed_on ON RecentDocuments(accessed_on)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_recent_documents_document_id ON RecentDocuments(document_id)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_folder_tags_folder_id ON Folder_Tags(folder_id)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_folder_tags_tag_id ON Folder_Tags(tag_id)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_document_tags_document_id ON Document_Tags(document_id)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_document_tags_tag_id ON Document_Tags(tag_id)",
      );
    }
    if (oldVersion < 6) {
      await _moveImagesToFiles(db);
      // Session images are temporary, so the table is simply recreated.
      await db.execute("DROP TABLE IF EXISTS CurrentImages");
      await db.execute(_createCurrentImages);
      await db.execute(_createSettings);
      // Old "thumbnails" were truncated JPEG data; they are rebuilt on access.
      await db.execute("DELETE FROM RecentDocuments");
    }
  }

  /// Version 6 stores images as files instead of BLOBs.
  ///
  /// The BLOBs are read in slices because Android cannot return a row larger
  /// than its ~2 MB cursor window. Thumbnails are left empty here and the UI
  /// falls back to the file until the document is next saved.
  Future<void> _moveImagesToFiles(Database db) async {
    const chunkSize = 512 * 1024;
    await db.execute("ALTER TABLE Images ADD COLUMN file_path TEXT");
    await db.execute("ALTER TABLE Images ADD COLUMN thumbnail BLOB");

    final rows = await db.rawQuery(
      "SELECT id, length(image) AS bytes FROM Images WHERE image IS NOT NULL",
    );
    for (final row in rows) {
      final id = row['id'] as String;
      final total = row['bytes'] as int? ?? 0;
      final builder = BytesBuilder(copy: false);
      for (var offset = 0; offset < total; offset += chunkSize) {
        // substr() is 1-based.
        final chunk = await db.rawQuery(
          "SELECT substr(image, ?, ?) AS chunk FROM Images WHERE id = ?",
          [offset + 1, chunkSize, id],
        );
        builder.add(chunk.first['chunk'] as Uint8List);
      }
      final filePath = await documentFileStore.write(
        DocumentFileStore.documentsFolder,
        id,
        builder.takeBytes(),
      );
      await db.update(
        'Images',
        {'file_path': filePath, 'image': null},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}

final localDatabaseHandler = LocalDatabaseHandler();
