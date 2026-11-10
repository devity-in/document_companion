import 'package:document_companion/local_database/models/image_model.dart';
import 'package:flutter/material.dart';

/// Shows a document preview: the stored thumbnail when there is one,
/// otherwise the image file decoded at a reduced size.
class CachedImageWidget extends StatelessWidget {
  final ImageModel image;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImageWidget({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  Widget _error(BuildContext context, Object error, StackTrace? stackTrace) {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error_outline, color: Colors.grey),
        );
  }

  Widget _frame(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (frame != null || wasSynchronouslyLoaded) return child;
    return placeholder ?? child;
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = image.thumbnail;
    final Widget imageWidget = thumbnail != null
        ? Image.memory(
            thumbnail,
            fit: fit,
            width: width,
            height: height,
            gaplessPlayback: true,
            errorBuilder: _error,
          )
        : Image.file(
            image.file,
            fit: fit,
            width: width,
            height: height,
            cacheWidth: 400,
            frameBuilder: _frame,
            errorBuilder: _error,
          );

    // If width/height are not specified, expand to fill available space
    if (width == null && height == null) {
      return SizedBox.expand(child: imageWidget);
    }
    return imageWidget;
  }
}
