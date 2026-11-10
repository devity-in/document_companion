import 'dart:developer' as developer;
import 'dart:io';

import 'package:document_companion/config/custom_key.dart';
import 'package:document_companion/local_database/document_repository.dart';
import 'package:document_companion/local_database/handler/settings_database_handler.dart';
import 'package:document_companion/modules/home/bloc/current_image_bloc.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:document_companion/modules/home/view/images_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:intl/intl.dart';

import 'view/scan.dart';

/// Starts a scan with the best scanner available on the device.
///
/// On Android this is Google's ML Kit document scanner (live edge detection,
/// auto-capture, perspective correction, multi-page). Where that is not
/// available — iOS, or Android devices without Google Play services — the
/// built-in camera, crop and filter screens are used instead.
class ScanLauncher {
  static const _maxPages = 30;
  static const _mlKitWorkedKey = 'mlkit_scanner_worked';

  /// Scans pages. With [folderId] they are saved straight into that folder;
  /// otherwise they are staged and the preview screen is opened.
  static Future<void> start(BuildContext context, {String? folderId}) async {
    if (!kIsWeb && Platform.isAndroid) {
      final handled = await _scanWithMlKit(context, folderId);
      if (handled) return;
    }
    if (context.mounted) {
      Navigator.pushNamed(context, Scan.route);
    }
  }

  /// Returns `false` when the ML Kit scanner could not be started, so the
  /// caller can fall back to the built-in scanner.
  static Future<bool> _scanWithMlKit(
    BuildContext context,
    String? folderId,
  ) async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: _maxPages,
        isGalleryImport: true,
      ),
    );
    final List<String> pages;
    try {
      final result = await scanner.scanDocument();
      pages = result.images ?? const [];
    } on PlatformException catch (e) {
      if (e.message == 'Operation cancelled') {
        // Google's scanner also reports "cancelled" when it fails to load
        // (no Play services module, unsupported device). Until it has worked
        // once on this device, point the user to the built-in scanner.
        final worked =
            await settingsDatabaseHandler.getValue(_mlKitWorkedKey) == 'true';
        if (!worked && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Scan cancelled'),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Use built-in scanner',
                onPressed: () =>
                    CustomKey.navigatorKey.currentState?.pushNamed(Scan.route),
              ),
            ),
          );
        }
        return true;
      }
      developer.log('ML Kit scanner unavailable', error: e);
      return false;
    } on MissingPluginException {
      return false;
    } finally {
      scanner.close().ignore();
    }
    if (pages.isEmpty) return true;
    await settingsDatabaseHandler.setValue(_mlKitWorkedKey, 'true');

    if (folderId == null) {
      for (final path in pages) {
        await currentImageBloc.saveCurrentImageFile(File(path));
      }
      await currentImageBloc.getCurrentImage();
      if (context.mounted) {
        Navigator.pushNamed(context, ImagesPreview.route);
      }
      return true;
    }

    final baseName =
        'Scan ${DateFormat('yyyy-MM-dd HH.mm').format(DateTime.now())}';
    for (var i = 0; i < pages.length; i++) {
      await documentRepository.addFromFile(
        folderId: folderId,
        name: pages.length == 1 ? baseName : '$baseName (${i + 1})',
        source: File(pages[i]),
      );
    }
    await imageBloc.fetchImagesByFolderId(folderId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${pages.length} page${pages.length == 1 ? '' : 's'}',
          ),
        ),
      );
    }
    return true;
  }
}
