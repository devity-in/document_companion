import 'dart:io';
import 'dart:typed_data';

import '../document_file_store.dart';

/// A page captured or imported in the current session that has not been
/// saved to a folder yet.
class CurrentImage {
  CurrentImage({
    required this.id,
    required this.filePath,
    required this.timestamp,
  });

  String id;

  /// Path relative to [DocumentFileStore.baseDirectory].
  String filePath;

  /// Milliseconds since epoch, as a string.
  String timestamp;

  File get file => documentFileStore.fileFor(filePath);

  Future<Uint8List> readBytes() => file.readAsBytes();

  Map<String, dynamic> toMap() {
    return {'id': id, 'file_path': filePath, 'timestamp': timestamp};
  }

  factory CurrentImage.fromMap(Map<String, dynamic> map) {
    return CurrentImage(
      id: map['id'] as String,
      filePath: map['file_path'] as String,
      timestamp: map['timestamp'] as String,
    );
  }
}
