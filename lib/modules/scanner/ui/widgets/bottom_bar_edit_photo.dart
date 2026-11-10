import 'package:document_companion/config/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../document_scanner_controller.dart';
import '../../models/filter_type.dart';
import '../../utils/edit_photo_document_style.dart';

class BottomBarEditPhoto extends StatelessWidget {
  final EditPhotoDocumentStyle editPhotoDocumentStyle;

  const BottomBarEditPhoto({super.key, required this.editPhotoDocumentStyle});

  @override
  Widget build(BuildContext context) {
    if (editPhotoDocumentStyle.hideBottomBarDefault) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
          child: StreamBuilder<FilterType>(
            stream: context.read<DocumentScannerController>().currentFilterType,
            builder: (context, AsyncSnapshot<FilterType> snapshot) {
              final currentFilter = snapshot.data ?? FilterType.natural;

              const filters = [
                (FilterType.natural, 'Original', Icons.image_outlined),
                (FilterType.enhance, 'Enhance', Icons.auto_awesome_rounded),
                (FilterType.gray, 'Gray', Icons.filter_b_and_w_rounded),
                (FilterType.blackWhite, 'B&W', Icons.contrast_rounded),
              ];

              return Row(
                children: [
                  for (final (type, label, icon) in filters)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _FilterButton(
                          label: label,
                          icon: icon,
                          isSelected: currentFilter == type,
                          onTap: () => context
                              .read<DocumentScannerController>()
                              .applyFilter(type),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? CustomColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? CustomColors.primary : CustomColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? CustomColors.primary
                  : CustomColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? CustomColors.primary
                    : CustomColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
