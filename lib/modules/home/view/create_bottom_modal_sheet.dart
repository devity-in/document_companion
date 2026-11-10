import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/modules/home/services/file_import_service.dart';
import 'package:document_companion/modules/home/view/images_preview.dart';
import 'package:document_companion/modules/scan/scan_launcher.dart';
import 'package:flutter/material.dart';

import 'create_folder_bottom_modal_sheet.dart';

class CreateBottomModalSheet extends StatelessWidget {
  const CreateBottomModalSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CustomColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create new',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan, import, or organize your documents',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: CustomColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CreateOption(
                      icon: Icons.folder_rounded,
                      label: 'Folder',
                      color: CustomColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: CreateFolderBottomModalSheet(),
                          ),
                        );
                      },
                    ),
                    _CreateOption(
                      icon: Icons.file_upload_rounded,
                      label: 'Add file',
                      color: CustomColors.accent,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        final imported = await fileImportService
                            .showImportOptions(navigator.context);
                        if (imported > 0 && navigator.mounted) {
                          navigator.pushNamed(ImagesPreview.route);
                        }
                      },
                    ),
                    _CreateOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Scan',
                      color: CustomColors.warning,
                      onTap: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        ScanLauncher.start(navigator.context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CreateOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
