import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Result of [DocumentFileStore.describe]: the pixel size of an image and a
/// small JPEG preview of it.
class ImageDescription {
  const ImageDescription({this.width, this.height, this.thumbnail});

  final int? width;
  final int? height;
  final Uint8List? thumbnail;
}

/// Stores document images as files on disk.
///
/// Images used to live in SQLite as BLOBs, which Android cannot read back once
/// a row exceeds the ~2 MB cursor window. The database now only keeps a path
/// relative to [baseDirectory] (relative so that it survives the app container
/// moving between installs) plus a small thumbnail.
class DocumentFileStore {
  static const documentsFolder = 'documents';
  static const pendingFolder = 'pending';

  /// Longest side of generated thumbnails, in pixels.
  static const thumbnailSize = 400;

  Directory? _baseDirectory;

  /// Overrides the storage root. Used by tests.
  set baseDirectory(Directory directory) => _baseDirectory = directory;

  Directory get baseDirectory {
    final directory = _baseDirectory;
    if (directory == null) {
      throw StateError('DocumentFileStore.init() has not been called');
    }
    return directory;
  }

  /// Must complete before any other member is used.
  Future<void> init() async {
    _baseDirectory ??= await getApplicationDocumentsDirectory();
    await Directory(p.join(baseDirectory.path, documentsFolder))
        .create(recursive: true);
    await Directory(p.join(baseDirectory.path, pendingFolder))
        .create(recursive: true);
  }

  /// Resolves a path stored in the database to a file.
  File fileFor(String relativePath) =>
      File(p.join(baseDirectory.path, relativePath));

  /// Writes [bytes] into [folder] and returns the relative path to store.
  Future<String> write(String folder, String id, Uint8List bytes) async {
    final relativePath = p.join(folder, '$id.${extensionFor(bytes)}');
    final file = fileFor(relativePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return relativePath;
  }

  /// Copies an existing file (inside or outside the store) into [folder].
  Future<String> importFile(String folder, String id, File source) async {
    final extension = p.extension(source.path).replaceFirst('.', '');
    final relativePath = p.join(
      folder,
      '$id.${extension.isEmpty ? 'jpg' : extension.toLowerCase()}',
    );
    final target = fileFor(relativePath);
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    return relativePath;
  }

  Future<void> delete(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return;
    final file = fileFor(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Number and total size of saved documents.
  Future<({int files, int bytes})> usage() async {
    final directory = Directory(p.join(baseDirectory.path, documentsFolder));
    var files = 0, bytes = 0;
    if (await directory.exists()) {
      await for (final entry in directory.list()) {
        if (entry is File) {
          files++;
          bytes += await entry.length();
        }
      }
    }
    return (files: files, bytes: bytes);
  }

  /// Picks a file extension from the image's magic bytes.
  static String extensionFor(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    return 'jpg';
  }

  /// Reads the pixel size of [file] and builds a thumbnail for it.
  ///
  /// Decoding is done by the engine at thumbnail size, so this stays cheap
  /// even for full-resolution camera photos. Returns an empty description if
  /// the file is not a decodable image.
  Future<ImageDescription> describe(File file) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width;
      final height = descriptor.height;

      final landscape = width >= height;
      final scale = thumbnailSize / (landscape ? width : height);
      final codec = await descriptor.instantiateCodec(
        targetWidth: scale < 1 ? (width * scale).round().clamp(1, width) : null,
        targetHeight: scale < 1
            ? (height * scale).round().clamp(1, height)
            : null,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final thumbWidth = image.width;
      final thumbHeight = image.height;
      image.dispose();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();

      Uint8List? thumbnail;
      if (pixels != null) {
        final small = img.Image.fromBytes(
          width: thumbWidth,
          height: thumbHeight,
          bytes: pixels.buffer,
          numChannels: 4,
        );
        thumbnail = img.encodeJpg(small, quality: 75);
      }
      return ImageDescription(
        width: width,
        height: height,
        thumbnail: thumbnail,
      );
    } catch (_) {
      return const ImageDescription();
    }
  }
}

final documentFileStore = DocumentFileStore();
