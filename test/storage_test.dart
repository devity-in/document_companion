import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:document_companion/local_database/document_file_store.dart';
import 'package:document_companion/local_database/document_repository.dart';
import 'package:document_companion/local_database/handler/current_images_database_handler.dart';
import 'package:document_companion/local_database/handler/folder_table_handler.dart';
import 'package:document_companion/local_database/handler/image_database_handler.dart';
import 'package:document_companion/local_database/handler/local_database_handler.dart';
import 'package:document_companion/local_database/handler/settings_database_handler.dart';
import 'package:document_companion/local_database/models/folder_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Uint8List _photo({int width = 1600, int height = 1200, int seed = 1}) {
  final random = Random(seed);
  final image = img.Image(width: width, height: height);
  for (final pixel in image) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
  }
  return img.encodeJpg(image, quality: 95);
}

Future<void> _addFolder(String id) => folderTableHandler.insertFolder(
  FolderModel(id: id, folderName: id, createdOn: '1', modifiedOn: '1'),
);

void main() {
  late Directory root;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    root = await Directory.systemTemp.createTemp('dc_test');
    documentFileStore.baseDirectory = root;
    LocalDatabaseHandler.pathOverride = p.join(root.path, 'db.sqlite');
  });

  tearDown(() async {
    await localDatabaseHandler.close();
    await root.delete(recursive: true);
  });

  List<String> filesIn(String folder) =>
      Directory(p.join(root.path, folder))
          .listSync()
          .map((entry) => p.basename(entry.path))
          .toList();

  test(
    'a saved document lives in a file, with only a thumbnail in the row',
    () async {
      await _addFolder('f1');
      final bytes = _photo();
      expect(bytes.length, greaterThan(1024 * 1024), reason: 'test photo size');

      final saved = await documentRepository.addFromBytes(
        folderId: 'f1',
        name: 'Receipt',
        bytes: bytes,
      );

      final listed = await imageDatabaseHandler.getImagesByFolderId('f1');
      expect(listed, hasLength(1));
      final image = listed.single;
      expect(image.name, 'Receipt');
      expect(image.width, 1600);
      expect(image.height, 1200);
      expect(image.size, bytes.length);
      expect(await image.readBytes(), bytes);
      expect(image.filePath, saved.filePath);
      expect(p.isRelative(image.filePath), isTrue);

      final thumbnail = img.decodeJpg(image.thumbnail!)!;
      expect(max(thumbnail.width, thumbnail.height), 400);
      expect(image.thumbnail!.length, lessThan(200 * 1024));

      // Nothing but the thumbnail is stored as a BLOB.
      final db = await localDatabaseHandler.db;
      final columns = await db!.rawQuery('PRAGMA table_info(Images)');
      expect(columns.map((c) => c['name']), isNot(contains('image')));
    },
  );

  test(
    'deleting a document or a folder\'s documents removes the files',
    () async {
      await _addFolder('f1');
      final a = await documentRepository.addFromBytes(
        folderId: 'f1',
        name: 'a',
        bytes: _photo(width: 200, height: 100),
      );
      await documentRepository.addFromBytes(
        folderId: 'f1',
        name: 'b',
        bytes: _photo(width: 200, height: 100, seed: 2),
      );
      expect(filesIn('documents'), hasLength(2));

      await imageDatabaseHandler.deleteImage(a.id);
      expect(filesIn('documents'), hasLength(1));
      expect(await imageDatabaseHandler.getImageCountByFolderId('f1'), 1);

      await imageDatabaseHandler.deleteImagesByFolderId('f1');
      expect(filesIn('documents'), isEmpty);
      expect(await imageDatabaseHandler.getImageCountByFolderId('f1'), 0);
    },
  );

  test(
    'pending pages are saved to every chosen folder, in capture order',
    () async {
      await _addFolder('f1');
      await _addFolder('f2');
      final first = _photo(width: 300, height: 200, seed: 1);
      final second = _photo(width: 300, height: 200, seed: 2);
      await documentRepository.addPendingFromBytes(first);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await documentRepository.addPendingFromBytes(second);
      expect(filesIn('pending'), hasLength(2));

      final saved = await documentRepository.savePendingToFolders(['f1', 'f2']);

      expect(saved, 2);
      expect(filesIn('pending'), isEmpty);
      expect(await CurrentImageDatabaseHandler().getCurrentImage(), isEmpty);
      for (final folder in ['f1', 'f2']) {
        final images = await imageDatabaseHandler.getImagesByFolderId(folder);
        expect(images, hasLength(2));
        expect(images.map((i) => i.name).toSet(), hasLength(2));
        final byName = {for (final i in images) i.name: i};
        final names = byName.keys.toList()..sort();
        expect(await byName[names[0]]!.readBytes(), first);
        expect(await byName[names[1]]!.readBytes(), second);
      }
      // Each folder owns its own copy.
      expect(filesIn('documents'), hasLength(4));
    },
  );

  test('removing one pending page leaves the others', () async {
    await documentRepository.addPendingFromBytes(_photo(width: 50, height: 50));
    final keep = await documentRepository.addPendingFromBytes(
      _photo(width: 50, height: 50, seed: 2),
    );
    final handler = CurrentImageDatabaseHandler();
    final pending = await handler.getCurrentImage();
    await handler.deleteImage(pending.firstWhere((i) => i.id != keep.id));

    expect((await handler.getCurrentImage()).single.id, keep.id);
    expect(filesIn('pending'), hasLength(1));
  });

  test('settings round-trip and overwrite', () async {
    expect(await settingsDatabaseHandler.getValue('theme'), isNull);
    await settingsDatabaseHandler.setValue('theme', 'dark');
    await settingsDatabaseHandler.setValue('theme', 'light');
    expect(await settingsDatabaseHandler.getValue('theme'), 'light');
  });

  test('upgrading from version 5 moves image BLOBs into files', () async {
    // A blob larger than Android's 2 MB cursor window and not a multiple of
    // the chunk size used by the migration.
    final big = Uint8List.fromList(
      List.generate(3 * 1024 * 1024 + 12345, (i) => (i * 31 + i ~/ 7) & 0xFF),
    );
    final small = _photo(width: 120, height: 80);

    final old = await databaseFactory.openDatabase(
      LocalDatabaseHandler.pathOverride!,
      options: OpenDatabaseOptions(
        version: 5,
        onCreate: (db, _) async {
          await db.execute(
            "CREATE TABLE CurrentImages(id TEXT PRIMARY KEY, image BLOB, timestamp TEXT, is_shoot_through_fast_camera TEXT, low_res_image BLOB )",
          );
          await db.execute(
            "CREATE TABLE Folders(id TEXT PRIMARY KEY, folder_name TEXT, created_on TEXT, modified_on TEXT )",
          );
          await db.execute(
            "CREATE TABLE Images(id TEXT PRIMARY KEY, folder_id TEXT, image BLOB, name TEXT, created_on TEXT, modified_on TEXT, size INTEGER, width INTEGER, height INTEGER, FOREIGN KEY (folder_id) REFERENCES Folders(id) ON DELETE CASCADE)",
          );
          await db.execute(
            "CREATE TABLE RecentDocuments(id TEXT PRIMARY KEY, document_id TEXT, document_type TEXT, folder_id TEXT, document_name TEXT, accessed_on TEXT, thumbnail BLOB)",
          );
          await db.execute(
            "CREATE TABLE Tags(id TEXT PRIMARY KEY, name TEXT UNIQUE, color TEXT, created_on TEXT)",
          );
          await db.execute(
            "CREATE TABLE Folder_Tags(folder_id TEXT, tag_id TEXT, PRIMARY KEY (folder_id, tag_id))",
          );
          await db.execute(
            "CREATE TABLE Document_Tags(document_id TEXT, tag_id TEXT, PRIMARY KEY (document_id, tag_id))",
          );
        },
      ),
    );
    await old.insert('Folders', {
      'id': 'f1',
      'folder_name': 'Bills',
      'created_on': '1',
      'modified_on': '1',
    });
    for (final (id, bytes) in [('big', big), ('small', small)]) {
      await old.insert('Images', {
        'id': id,
        'folder_id': 'f1',
        'image': bytes,
        'name': id,
        'created_on': '2026-01-01 10:00:00',
        'modified_on': '2026-01-01 10:00:00',
        'size': bytes.length,
      });
    }
    await old.insert('CurrentImages', {'id': 'c', 'image': small});
    await old.insert('RecentDocuments', {
      'id': 'r',
      'document_id': 'big',
      'thumbnail': Uint8List(10),
    });
    await old.close();

    final images = await imageDatabaseHandler.getImagesByFolderId('f1');

    expect(images, hasLength(2));
    final byId = {for (final i in images) i.id: i};
    expect(await byId['big']!.readBytes(), big);
    expect(await byId['small']!.readBytes(), small);
    expect(byId['small']!.filePath, endsWith('.jpg'));
    expect(byId['big']!.name, 'big');

    final db = (await localDatabaseHandler.db)!;
    final leftover = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM Images WHERE image IS NOT NULL',
    );
    expect(leftover.single['n'], 0);
    expect(await db.query('RecentDocuments'), isEmpty);
    expect(await CurrentImageDatabaseHandler().getCurrentImage(), isEmpty);
    expect(await folderTableHandler.getFolders(), hasLength(1));

    // New documents can be added next to migrated ones.
    await documentRepository.addFromBytes(
      folderId: 'f1',
      name: 'new',
      bytes: small,
    );
    expect(await imageDatabaseHandler.getImageCountByFolderId('f1'), 3);
  });
}
