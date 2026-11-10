import 'package:flutter/material.dart';

import '../models/ui_models.dart';

class Constant {
  static List<ServiceOperation> availableServices = [
    ServiceOperation(
      Icons.document_scanner_rounded,
      'PDF to Word',
      "/",
    ),
    ServiceOperation(
      Icons.merge_outlined,
      'Merge PDF',
      "/",
    ),
    ServiceOperation(
      Icons.call_split_rounded,
      'Split PDF',
      "/",
    ),
    ServiceOperation(
      Icons.compress_outlined,
      'Compress PDF',
      "/",
    ),
    ServiceOperation(
      Icons.image,
      'Image to PDF',
      "/",
    ),
    ServiceOperation(
      Icons.file_present,
      'Import PDF',
      "/",
    ),
  ];
}
