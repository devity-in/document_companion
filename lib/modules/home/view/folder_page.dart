import 'dart:async';

import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/local_database/models/image_model.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:document_companion/local_database/models/tag_model.dart';
import 'package:document_companion/modules/home/bloc/tag_bloc.dart';
import 'package:document_companion/modules/home/models/date_filter_model.dart';
import 'package:document_companion/modules/home/services/batch_operations_service.dart';
import 'package:document_companion/modules/home/services/document_service.dart';
import 'package:document_companion/modules/home/services/folder_service.dart';
import 'package:document_companion/modules/home/services/tag_service.dart';
import 'package:document_companion/modules/home/view/document_viewer_page.dart';
import 'package:document_companion/modules/home/view/filter_bottom_sheet.dart';
import 'package:document_companion/modules/home/widgets/cached_image_widget.dart';
import 'package:document_companion/modules/home/services/file_import_service.dart';
import 'package:document_companion/modules/scan/scan_launcher.dart';
import 'package:document_companion/utils/ux_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../models/folder_view_model.dart';

class FolderPage extends StatefulWidget {
  static const route = '/folder/folder_page';
  const FolderPage({super.key, required this.folder});

  final FolderViewModel folder;
  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  bool _isGridView = true;
  bool _isSearching = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedImageIds = {};
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<ImageModel>>? _imageSubscription;
  int _imageCount = 0;
  bool _hasActiveFilter = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _updateImageCount();
    tagBloc.fetchTags();
    _hasActiveFilter = imageBloc.currentDateFilter.isActive;
  }

  @override
  void dispose() {
    _imageSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    UXHelpers.selectionFeedback();
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        imageBloc.clearSearch();
      }
    });
  }

  void _onSearchChanged(String query) {
    imageBloc.searchImages(query);
  }

  void _toggleSelectionMode() {
    UXHelpers.mediumImpact();
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedImageIds.clear();
      }
    });
  }

  void _toggleImageSelection(String imageId) {
    UXHelpers.selectionFeedback();
    setState(() {
      if (_selectedImageIds.contains(imageId)) {
        _selectedImageIds.remove(imageId);
      } else {
        _selectedImageIds.add(imageId);
      }
      if (_selectedImageIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAllImages(List<ImageModel> images) {
    UXHelpers.mediumImpact();
    setState(() {
      _selectedImageIds.clear();
      _selectedImageIds.addAll(images.map((img) => img.id));
    });
  }

  void _deselectAll() {
    UXHelpers.selectionFeedback();
    setState(() {
      _selectedImageIds.clear();
      _isSelectionMode = false;
    });
  }

  List<ImageModel> _getSelectedImages(List<ImageModel> allImages) {
    return allImages
        .where((img) => _selectedImageIds.contains(img.id))
        .toList();
  }

  Future<void> _loadImages() async {
    imageBloc.fetchImagesByFolderId(widget.folder.id);
    _imageSubscription = imageBloc.imageStream.listen((images) {
      if (mounted) {
        setState(() {
          _imageCount = images.length;
        });
      }
    });
  }

  Future<void> _updateImageCount() async {
    final count = await imageBloc.getImageCount(widget.folder.id);
    if (mounted) {
      setState(() {
        _imageCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      imageBloc.clearSearch();
                      _toggleSearch();
                    },
                  ),
                ),
                onChanged: _onSearchChanged,
              )
            : Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CustomColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.folder.folderName,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$_imageCount ${_imageCount == 1 ? 'document' : 'documents'}',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StreamBuilder<DateFilter>(
                              stream: Stream.value(imageBloc.currentDateFilter),
                              builder: (context, snapshot) {
                                final filter = snapshot.data;
                                if (filter?.isActive == true) {
                                  String filterText = '';
                                  switch (filter!.type) {
                                    case DateFilterType.today:
                                      filterText = ' • Today';
                                      break;
                                    case DateFilterType.thisWeek:
                                      filterText = ' • This Week';
                                      break;
                                    case DateFilterType.thisMonth:
                                      filterText = ' • This Month';
                                      break;
                                    case DateFilterType.customRange:
                                      filterText = ' • Custom Range';
                                      break;
                                    default:
                                      break;
                                  }
                                  return Flexible(
                                    child: Text(
                                      filterText,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          if (_isSelectionMode) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${_selectedImageIds.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            IconButton(
              onPressed: _deselectAll,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancel',
            ),
          ] else ...[
            if (_isSearching)
              IconButton(
                onPressed: _toggleSearch,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close search',
              )
            else
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'More options',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'grid_view':
                      setState(() {
                        _isGridView = true;
                      });
                      break;
                    case 'list_view':
                      setState(() {
                        _isGridView = false;
                      });
                      break;
                    case 'search':
                      _toggleSearch();
                      break;
                    case 'filter':
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const FilterBottomSheet(),
                      ).then((_) {
                        // Update filter state after bottom sheet closes
                        setState(() {
                          _hasActiveFilter =
                              imageBloc.currentDateFilter.isActive;
                        });
                      });
                      break;
                    case 'select':
                      _toggleSelectionMode();
                      break;
                    case 'rename':
                      folderService.showRenameDialog(context, widget.folder);
                      break;
                    case 'tags':
                      tagService.showAddTagToFolderDialog(
                        context,
                        widget.folder.id,
                      );
                      break;
                    case 'delete':
                      folderService.showDeleteConfirmation(
                        context,
                        widget.folder,
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  // View Options
                  PopupMenuItem(
                    value: _isGridView ? 'list_view' : 'grid_view',
                    child: Row(
                      children: [
                        Icon(
                          _isGridView
                              ? Icons.view_list_rounded
                              : Icons.grid_view_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(_isGridView ? 'List View' : 'Grid View'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  // Search
                  const PopupMenuItem(
                    value: 'search',
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Search'),
                      ],
                    ),
                  ),
                  // Filter
                  PopupMenuItem(
                    value: 'filter',
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 20,
                          color: _hasActiveFilter ? CustomColors.primary : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Filter',
                          style: TextStyle(
                            color: _hasActiveFilter
                                ? CustomColors.primary
                                : null,
                            fontWeight: _hasActiveFilter
                                ? FontWeight.w500
                                : null,
                          ),
                        ),
                        if (_hasActiveFilter) ...[
                          const Spacer(),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: CustomColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Select Mode
                  const PopupMenuItem(
                    value: 'select',
                    child: Row(
                      children: [
                        Icon(Icons.checklist_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Select Documents'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  // Folder Actions
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Rename Folder'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'tags',
                    child: Row(
                      children: [
                        Icon(Icons.label_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Manage Tags'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  // Delete
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Delete Folder',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
      body: StreamBuilder<List<ImageModel>>(
        stream: imageBloc.imageStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final images = snapshot.data ?? [];
            if (images.isEmpty) {
              return _EmptyFolderState(
                folderName: widget.folder.folderName,
                folderId: widget.folder.id,
              );
            }
            return Stack(
              children: [
                _ImageGridView(
                  images: images,
                  isGridView: _isGridView,
                  folderId: widget.folder.id,
                  isSelectionMode: _isSelectionMode,
                  selectedImageIds: _selectedImageIds,
                  onImageTap: _isSelectionMode
                      ? (imageId) => _toggleImageSelection(imageId)
                      : null,
                ),
                if (_isSelectionMode && _selectedImageIds.isNotEmpty)
                  _BatchActionBar(
                    selectedCount: _selectedImageIds.length,
                    totalCount: images.length,
                    onSelectAll: () => _selectAllImages(images),
                    onDeselectAll: _deselectAll,
                    onDelete: () {
                      final selectedImages = _getSelectedImages(images);
                      batchOperationsService.batchDelete(
                        context,
                        selectedImages,
                        widget.folder.id,
                      );
                      _deselectAll();
                    },
                    onMove: () {
                      final selectedImages = _getSelectedImages(images);
                      batchOperationsService.batchMove(
                        context,
                        selectedImages,
                        widget.folder.id,
                      );
                      _deselectAll();
                    },
                    onConvertToPdf: () {
                      final selectedImages = _getSelectedImages(images);
                      batchOperationsService.batchConvertToPdf(
                        context,
                        selectedImages,
                      );
                      _deselectAll();
                    },
                  ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                ScanLauncher.start(context, folderId: widget.folder.id);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Document'),
            ),
    );
  }
}

class _ImageGridView extends StatelessWidget {
  final List<ImageModel> images;
  final bool isGridView;
  final String folderId;
  final bool isSelectionMode;
  final Set<String> selectedImageIds;
  final void Function(String)? onImageTap;

  const _ImageGridView({
    required this.images,
    required this.isGridView,
    required this.folderId,
    this.isSelectionMode = false,
    this.selectedImageIds = const {},
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return GridView.builder(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: isSelectionMode ? 80 : 16,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: images.length,
        // Lazy loading optimization
        scrollCacheExtent: const ScrollCacheExtent.pixels(
          500,
        ), // Cache 500 pixels worth of items
        addAutomaticKeepAlives:
            false, // Don't keep widgets alive when scrolled away
        addRepaintBoundaries:
            true, // Add repaint boundaries for better performance
        itemBuilder: (context, index) {
          return _ImageCard(
            image: images[index],
            folderId: folderId,
            images: images,
            index: index,
            isSelectionMode: isSelectionMode,
            isSelected: selectedImageIds.contains(images[index].id),
            onTap: onImageTap != null
                ? () => onImageTap!(images[index].id)
                : null,
          );
        },
      );
    } else {
      return ListView.builder(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: isSelectionMode ? 80 : 16,
        ),
        itemCount: images.length,
        // Lazy loading optimization
        scrollCacheExtent: const ScrollCacheExtent.pixels(
          500,
        ), // Cache 500 pixels worth of items
        addAutomaticKeepAlives:
            false, // Don't keep widgets alive when scrolled away
        addRepaintBoundaries:
            true, // Add repaint boundaries for better performance
        itemBuilder: (context, index) {
          return _ImageListTile(
            image: images[index],
            folderId: folderId,
            images: images,
            index: index,
            isSelectionMode: isSelectionMode,
            isSelected: selectedImageIds.contains(images[index].id),
            onTap: onImageTap != null
                ? () => onImageTap!(images[index].id)
                : null,
          );
        },
      );
    }
  }
}

class _ImageCard extends StatelessWidget {
  final ImageModel image;
  final String folderId;
  final List<ImageModel> images;
  final int index;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ImageCard({
    required this.image,
    required this.folderId,
    required this.images,
    required this.index,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Stack(
        children: [
          InkWell(
            onTap: isSelectionMode
                ? onTap
                : () {
                    Navigator.pushNamed(
                      context,
                      DocumentViewerPage.route,
                      arguments: {
                        'images': images,
                        'initialIndex': index,
                        'folderId': folderId,
                      },
                    );
                  },
            onLongPress: isSelectionMode
                ? null
                : () {
                    documentService.showDeleteConfirmation(
                      context,
                      image,
                      folderId,
                    );
                  },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: CachedImageWidget(
                          image: image,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      if (isSelectionMode)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? CustomColors.primary.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      if (isSelectionMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? CustomColors.primary
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: isSelected ? Colors.white : Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        image.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        image.createdOn,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      FutureBuilder<List<TagModel>>(
                        future: tagBloc.getTagsByDocumentId(image.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            final tags = snapshot.data!;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: tags.take(2).map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _parseColor(tag.color)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tag.name,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _parseColor(tag.color),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }
}

class _ImageListTile extends StatelessWidget {
  final ImageModel image;
  final String folderId;
  final List<ImageModel> images;
  final int index;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ImageListTile({
    required this.image,
    required this.folderId,
    required this.images,
    required this.index,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? CustomColors.primary.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedImageWidget(
                image: image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
              ),
            ),
            if (isSelectionMode)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CustomColors.primary.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        title: Text(image.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(image.createdOn, style: Theme.of(context).textTheme.bodySmall),
            FutureBuilder<List<TagModel>>(
              future: tagBloc.getTagsByDocumentId(image.id),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final tags = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _parseColor(tag.color)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: _parseColor(tag.color),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        trailing: isSelectionMode
            ? Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? CustomColors.primary : Colors.grey,
              )
            : IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        _DocumentOptionsSheet(image: image, folderId: folderId),
                  );
                },
              ),
        onTap: isSelectionMode
            ? onTap
            : () {
                Navigator.pushNamed(
                  context,
                  DocumentViewerPage.route,
                  arguments: {
                    'images': images,
                    'initialIndex': index,
                    'folderId': folderId,
                  },
                );
              },
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }
}

class _EmptyFolderState extends StatelessWidget {
  final String folderName;
  final String folderId;

  const _EmptyFolderState({required this.folderName, required this.folderId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: CustomColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: CustomColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No documents yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start by scanning a document or importing files',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScanLauncher.start(context, folderId: folderId);
                  },
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Scan'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    fileImportService.importImagesToFolder(context, folderId);
                  },
                  icon: const Icon(Icons.file_upload_rounded),
                  label: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentOptionsSheet extends StatelessWidget {
  final ImageModel image;
  final String folderId;

  const _DocumentOptionsSheet({required this.image, required this.folderId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                documentService.showRenameDialog(context, image, folderId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label_rounded),
              title: const Text('Manage Tags'),
              onTap: () {
                Navigator.pop(context);
                tagService.showAddTagToDocumentDialog(context, image.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_rounded),
              title: const Text('Move'),
              onTap: () {
                Navigator.pop(context);
                documentService.showMoveDialog(context, image, folderId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                documentService.shareDocument(context, image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                documentService.showDeleteConfirmation(
                  context,
                  image,
                  folderId,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _BatchActionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onDelete;
  final VoidCallback onMove;
  final VoidCallback onConvertToPdf;

  const _BatchActionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onDelete,
    required this.onMove,
    required this.onConvertToPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          child: Row(
            children: [
              TextButton.icon(
                onPressed: selectedCount == totalCount
                    ? onDeselectAll
                    : onSelectAll,
                icon: Icon(
                  selectedCount == totalCount
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                ),
                label: Text(
                  selectedCount == totalCount ? 'Deselect All' : 'Select All',
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onConvertToPdf,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                tooltip: 'Convert to PDF',
              ),
              IconButton(
                onPressed: onMove,
                icon: const Icon(Icons.drive_file_move_rounded),
                tooltip: 'Move',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded),
                color: Colors.red,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
