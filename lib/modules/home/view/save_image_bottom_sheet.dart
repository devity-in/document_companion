import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/local_database/document_repository.dart';
import 'package:document_companion/modules/home/bloc/current_image_bloc.dart';
import 'package:document_companion/modules/home/bloc/folder_bloc.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/folder_selection_model.dart';

class SaveImageBottomSheet extends StatefulWidget {
  const SaveImageBottomSheet({super.key});

  @override
  State<SaveImageBottomSheet> createState() => _SaveImageBottomSheetState();
}

class _SaveImageBottomSheetState extends State<SaveImageBottomSheet> {
  final List<FolderSelectionModel> folderList = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    folderBloc.fetchFolders();
    folderBloc.folderList.listen((event) {
      folderList.clear();
      for (var element in event) {
        folderList.add(FolderSelectionModel(element, false));
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _saveImages() async {
    final selectedFolders = folderList
        .where((folder) => folder.isSelected)
        .map((folder) => folder.folder)
        .toList();

    if (selectedFolders.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one folder')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final savedCount = await documentRepository.savePendingToFolders([
        for (final folder in selectedFolders) folder.id,
      ]);
      if (savedCount == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No images to save')));
        }
        return;
      }
      await currentImageBloc.getCurrentImage();

      // Refresh image count for selected folders
      for (var folder in selectedFolders) {
        imageBloc.fetchImagesByFolderId(folder.id);
      }

      if (mounted) {
        Navigator.pop(context); // Close save sheet
        Navigator.pop(context); // Close images preview if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved $savedCount page${savedCount == 1 ? '' : 's'} to ${selectedFolders.length} folder${selectedFolders.length == 1 ? '' : 's'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving images: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Save images to folder',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                if (folderList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 64,
                          color: CustomColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No folders available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a folder first to save images',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: folderList.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final folderModel = folderList[index];
                        final folder = folderModel.folder;
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: folderModel.isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  folderModel.isSelected = value ?? false;
                                });
                              },
                            ),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: CustomColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.folder_rounded,
                                    color: CustomColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        folder.folderName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        'Created ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(int.tryParse(folder.createdOn) ?? 0))}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                folderModel.isSelected =
                                    !folderModel.isSelected;
                              });
                            },
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveImages,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
