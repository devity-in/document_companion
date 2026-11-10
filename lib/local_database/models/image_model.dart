import 'dart:io';
import 'dart:typed_data';

import '../document_file_store.dart';

/// A document page saved in a folder.
///
/// The image itself lives on disk at [filePath]; only a small [thumbnail] is
/// kept in the database row.
class ImageModel {
  ImageModel({
    required this.id,
    required this.folderId,
    required this.filePath,
    required this.name,
    required this.createdOn,
    required this.modifiedOn,
    this.thumbnail,
    this.size,
    this.width,
    this.height,
  });

  /// Columns to select when reading rows. Deliberately leaves out the legacy
  /// `image` BLOB column that older database versions used.
  static const columns = [
    'id',
    'folder_id',
    'file_path',
    'thumbnail',
    'name',
    'created_on',
    'modified_on',
    'size',
    'width',
    'height',
  ];

  String id;
  String folderId;

  /// Path relative to [DocumentFileStore.baseDirectory].
  String filePath;
  Uint8List? thumbnail;
  String name;
  String createdOn;
  String modifiedOn;
  int? size;
  int? width;
  int? height;

  File get file => documentFileStore.fileFor(filePath);

  Future<Uint8List> readBytes() => file.readAsBytes();

  ImageModel copyWith({String? folderId, String? name, String? modifiedOn}) {
    return ImageModel(
      id: id,
      folderId: folderId ?? this.folderId,
      filePath: filePath,
      thumbnail: thumbnail,
      name: name ?? this.name,
      createdOn: createdOn,
      modifiedOn: modifiedOn ?? this.modifiedOn,
      size: size,
      width: width,
      height: height,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folder_id': folderId,
      'file_path': filePath,
      'thumbnail': thumbnail,
      'name': name,
      'created_on': createdOn,
      'modified_on': modifiedOn,
      'size': size,
      'width': width,
      'height': height,
    };
  }

  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
      id: map['id'] as String,
      folderId: map['folder_id'] as String,
      filePath: map['file_path'] as String? ?? '',
      thumbnail: map['thumbnail'] as Uint8List?,
      name: map['name'] as String,
      createdOn: map['created_on'] as String,
      modifiedOn: map['modified_on'] as String,
      size: map['size'] as int?,
      width: map['width'] as int?,
      height: map['height'] as int?,
    );
  }
}
