import 'package:document_companion/local_database/models/current_image.dart';
import 'package:document_companion/modules/home/bloc/current_image_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/custom_colors.dart';
import '../../../home/view/images_preview.dart';
import '../../document_scanner_controller.dart';

class ButtonTakePhoto extends StatelessWidget {
  final bool hide;

  const ButtonTakePhoto({super.key, this.hide = false});

  @override
  Widget build(BuildContext context) {
    if (hide) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: CustomColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail and done button row
            StreamBuilder<List<CurrentImage>>(
              stream: currentImageBloc.currentImageStream,
              builder: (context, AsyncSnapshot<List<CurrentImage>> snapshot) {
                final hasImages = snapshot.hasData && snapshot.data!.isNotEmpty;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Thumbnail
                    if (hasImages)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, ImagesPreview.route);
                        },
                        child: Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CustomColors.border,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                Image.file(
                                  snapshot.data!.last.file,
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                  cacheWidth: 168,
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CustomColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      snapshot.data!.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 56),

                    // Capture button
                    GestureDetector(
                      onTap: () =>
                          context.read<DocumentScannerController>().takePhoto(),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CustomColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: CustomColors.primary.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),

                    // Done/Preview button
                    if (hasImages)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, ImagesPreview.route);
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Done'),
                        style: TextButton.styleFrom(
                          foregroundColor: CustomColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
