import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../models/area.dart';
import '../models/contour.dart';
import '../models/filter_type.dart';
import 'document_image_processing.dart';

/// Image operations used by the scanner. The heavy lifting happens in
/// background isolates (see `document_image_processing.dart`).
class ImageUtils {
  /// Calculates the rect of the image
  Rect imageRect(Size screenSize) {
    return Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
  }

  /// Looks for a document in the photo and returns its corners, in pixel
  /// coordinates of the photo, or `null` if none was found.
  Future<Area?> findContourPhoto(
    Uint8List byteData, {
    double? minContourArea,
  }) async {
    try {
      final corners = await compute(detectCornersInIsolate, byteData);
      if (corners == null) return null;
      return Area(
        topLeft: Point(corners[0], corners[1]),
        topRight: Point(corners[2], corners[3]),
        bottomRight: Point(corners[4], corners[5]),
        bottomLeft: Point(corners[6], corners[7]),
      );
    } catch (e) {
      developer.log('Error in findContourPhoto: $e');
      return null;
    }
  }

  /// Crops the photo to [contour] (top-left, top-right, bottom-right,
  /// bottom-left) and straightens it into a rectangle.
  Future<Uint8List?> adjustingPerspective(
    Uint8List byteData,
    Contour contour,
  ) async {
    try {
      if (contour.points.length != 4) return null;
      return await compute(warpInIsolate, (
        byteData,
        [
          for (final point in contour.points) ...[point.x, point.y],
        ],
      ));
    } catch (e) {
      developer.log('Error in adjustingPerspective', error: e);
      return null;
    }
  }

  /// Applies the selected [filter].
  Future<Uint8List> applyFilter(Uint8List byteData, FilterType filter) async {
    try {
      return await compute(filterInIsolate, (byteData, filter.name));
    } catch (e) {
      developer.log('Error in applyFilter', error: e);
      return byteData;
    }
  }
}
