import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/config/custom_theme.dart';
import 'package:document_companion/local_database/models/recent_document_model.dart';
import 'package:document_companion/local_database/models/tag_model.dart';
import 'package:document_companion/modules/home/bloc/current_image_bloc.dart';
import 'package:document_companion/modules/home/bloc/folder_bloc.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:document_companion/modules/home/bloc/recent_documents_bloc.dart';
import 'package:document_companion/modules/home/bloc/tag_bloc.dart';
import 'package:document_companion/modules/home/services/tag_service.dart';
import 'package:document_companion/modules/home/models/folder_view_model.dart';
import 'package:document_companion/modules/home/services/pdf_service.dart';
import 'package:document_companion/modules/home/view/create_bottom_modal_sheet.dart';
import 'package:document_companion/modules/home/view/document_viewer_page.dart';
import 'package:document_companion/modules/home/view/filter_dialog.dart';
import 'package:document_companion/modules/home/view/images_preview.dart';
import 'package:document_companion/modules/home/widgets/banner_ad_widget.dart';
import 'package:document_companion/modules/settings/view/settings_page.dart';
import 'package:document_companion/utils/constants/constants.dart';
import 'package:document_companion/utils/ux_helpers.dart';
import 'package:document_companion/local_database/handler/image_database_handler.dart';
import 'package:document_companion/modules/home/services/file_import_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'folder_page.dart';

class Homepage extends StatefulWidget {
  static const String route = '/homepage';

  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _hasActiveFilters = false;

  @override
  void initState() {
    folderBloc.fetchFolders();
    recentDocumentsBloc.fetchRecentDocuments(limit: 5);
    tagBloc.fetchTags();
    _hasActiveFilters = folderBloc.hasActiveFilters;
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        folderBloc.clearSearch();
      }
    });
  }

  void _onSearchChanged(String query) {
    folderBloc.searchFolders(query);
  }

  void _handleServiceTap(BuildContext context, int index) {
    UXHelpers.selectionFeedback();
    switch (index) {
      case 0: // PDF to Word
        pdfService.showPdfToWordDialog(context);
        break;
      case 1: // Merge PDF
        pdfService.showMergePdfDialog(context);
        break;
      case 2: // Split PDF
        pdfService.showSplitPdfDialog(context);
        break;
      case 3: // File Compress
        pdfService.showCompressPdfDialog(context);
        break;
      case 4: // Image to PDF
        _handleImageToPdf(context);
        break;
      case 5: // Import PDF
        pdfService.showImportPdfDialog(context);
        break;
    }
  }

  Future<void> _handleImageToPdf(BuildContext context) async {
    // Check if there are any images to convert
    final images = await currentImageBloc.getCurrentImagesList();
    if (!context.mounted) return;

    if (images.isEmpty) {
      // Nothing scanned yet: pick images, then offer PDF from the preview.
      final imported = await fileImportService.importMultipleImagesFromGallery(
        context,
      );
      if (imported == 0) return;
    }
    // Navigate to images preview where PDF conversion is available
    if (context.mounted) {
      Navigator.pushNamed(context, ImagesPreview.route);
    }
  }

  Future<void> _refreshFolders() async {
    UXHelpers.lightImpact();
    await folderBloc.fetchFolders();
    await recentDocumentsBloc.fetchRecentDocuments(limit: 5);
    tagBloc.fetchTags();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await UXHelpers.showExitConfirmationDialog(
            context,
          );
          if (shouldExit && context.mounted) {
            Navigator.of(context).pop();
            // Exit the app
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search folders...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        folderBloc.clearSearch();
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Document Companion',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Your complete document solution',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: CustomColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
          actions: [
            if (_isSearching)
              IconButton(
                onPressed: () {
                  UXHelpers.selectionFeedback();
                  _toggleSearch();
                },
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
                  UXHelpers.selectionFeedback();
                  switch (value) {
                    case 'search':
                      _toggleSearch();
                      break;
                    case 'sort':
                      // Sort menu will be handled by the sort popup in folders section
                      break;
                    case 'filter':
                      showDialog(
                        context: context,
                        builder: (context) => const FilterDialog(),
                      ).then((_) {
                        if (context.mounted) {
                          setState(() {
                            _hasActiveFilters = folderBloc.hasActiveFilters;
                          });
                        }
                      });
                      break;
                    case 'theme':
                      final theme = CustomTheme();
                      theme.toggleTheme();
                      UXHelpers.successFeedback();
                      break;
                    case 'tags':
                      tagService.showTagManagementDialog(context);
                      break;
                    case 'settings':
                      Navigator.pushNamed(context, SettingsPage.route);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  // Search
                  const PopupMenuItem(
                    value: 'search',
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Search Folders'),
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
                          color: _hasActiveFilters
                              ? CustomColors.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Filter',
                          style: TextStyle(
                            color: _hasActiveFilters
                                ? CustomColors.primary
                                : null,
                            fontWeight: _hasActiveFilters
                                ? FontWeight.w500
                                : null,
                          ),
                        ),
                        if (_hasActiveFilters) ...[
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
                  const PopupMenuDivider(),
                  // Theme
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(
                          CustomTheme().isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          CustomTheme().isDarkMode ? 'Light Mode' : 'Dark Mode',
                        ),
                      ],
                    ),
                  ),
                  // Tags
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
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            UXHelpers.mediumImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CreateBottomModalSheet(),
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Services Section
              SizedBox(
                height: 136,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: Constant.availableServices.length,
                  itemBuilder: (context, index) => _ServiceCard(
                    icon: Constant.availableServices[index].operationIcon,
                    title: Constant.availableServices[index].title,
                    onTap: () => _handleServiceTap(context, index),
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                ),
              ),
              // Coming Soon Features Preview
              _ComingSoonSection(),
              const SizedBox(height: 12),
              // Recent Documents Section
              StreamBuilder<List<RecentDocumentModel>>(
                stream: recentDocumentsBloc.recentDocumentsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return _RecentDocumentsSection(
                      recentDocuments: snapshot.data!,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Folders Section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Folders',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Row(
                              children: [
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.sort_rounded),
                                  tooltip: 'Sort',
                                  iconSize: 20,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (value) {
                                    UXHelpers.selectionFeedback();
                                    final parts = value.split('_');
                                    final sortBy = parts[0];
                                    final ascending = parts[1] == 'asc';
                                    folderBloc.sortFolders(
                                      sortBy,
                                      ascending: ascending,
                                    );
                                    UXHelpers.successFeedback();
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'name_asc',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.sort_by_alpha_rounded,
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Name (A-Z)'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'name_desc',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.sort_by_alpha_rounded,
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Name (Z-A)'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'created_desc',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Newest First'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'created_asc',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Oldest First'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'modified_desc',
                                      child: Row(
                                        children: [
                                          Icon(Icons.update_rounded, size: 20),
                                          SizedBox(width: 12),
                                          Text('Recently Modified'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Builder(
                                  builder: (context) {
                                    // Check filter status by listening to folder list changes
                                    return StreamBuilder<List<FolderViewModel>>(
                                      stream: folderBloc.folderList,
                                      builder: (context, _) {
                                        final hasFilters =
                                            folderBloc.hasActiveFilters;
                                        return Stack(
                                          children: [
                                            IconButton(
                                              onPressed: () async {
                                                UXHelpers.selectionFeedback();
                                                await showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      const FilterDialog(),
                                                );
                                                // Refresh the UI after dialog closes
                                                if (context.mounted) {
                                                  setState(() {
                                                    _hasActiveFilters =
                                                        folderBloc
                                                            .hasActiveFilters;
                                                  });
                                                }
                                              },
                                              icon: Icon(
                                                Icons.filter_list_rounded,
                                                color: hasFilters
                                                    ? CustomColors.primary
                                                    : null,
                                              ),
                                              tooltip: 'Filter',
                                              iconSize: 20,
                                            ),
                                            if (hasFilters)
                                              Positioned(
                                                right: 8,
                                                top: 8,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: CustomColors.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshFolders,
                          color: CustomColors.primary,
                          child: StreamBuilder<List<FolderViewModel>>(
                            stream: folderBloc.folderList,
                            builder:
                                (
                                  context,
                                  AsyncSnapshot<List<FolderViewModel>> snapshot,
                                ) {
                                  if (snapshot.hasData) {
                                    final folders = snapshot.data;
                                    if (folders?.isEmpty ?? true) {
                                      return Column(
                                        children: [
                                          Expanded(child: _EmptyState()),
                                          BannerAdWidget(),
                                        ],
                                      );
                                    }
                                    return Column(
                                      children: [
                                        Expanded(
                                          child: GridView.builder(
                                            padding: const EdgeInsets.fromLTRB(
                                              20,
                                              20,
                                              20,
                                              8,
                                            ),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 2,
                                                  childAspectRatio: 0.85,
                                                  crossAxisSpacing: 16,
                                                  mainAxisSpacing: 16,
                                                ),
                                            itemCount: folders?.length ?? 0,
                                            itemBuilder: (context, index) {
                                              return _FolderCard(
                                                folder: folders![index],
                                                onTap: () {
                                                  UXHelpers.selectionFeedback();
                                                  Navigator.pushNamed(
                                                    context,
                                                    FolderPage.route,
                                                    arguments: folders[index],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        BannerAdWidget(),
                                      ],
                                    );
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 88,
        height: 112,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CustomColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: CustomColors.primary, size: 22),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).textTheme.bodySmall?.color ??
                        CustomColors.textPrimary,
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final FolderViewModel folder;
  final VoidCallback onTap;

  const _FolderCard({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CustomColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: CustomColors.primary,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                folder.folderName,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              ValueListenableBuilder<int>(
                valueListenable: imageDatabaseHandler.changes,
                builder: (context, _, _) => FutureBuilder<int>(
                  future: imageBloc.getImageCount(folder.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      '$count ${count == 1 ? 'document' : 'documents'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
              FutureBuilder<List<TagModel>>(
                future: tagBloc.getTagsByFolderId(folder.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final tags = snapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 6,
                        children: tags.take(2).map((tag) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _parseColor(tag.color)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag.name,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _parseColor(tag.color),
                                  fontWeight: FontWeight.w500,
                                ),
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
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }
}

class _RecentDocumentsSection extends StatelessWidget {
  final List<RecentDocumentModel> recentDocuments;

  const _RecentDocumentsSection({required this.recentDocuments});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Documents',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  UXHelpers.selectionFeedback();
                  recentDocumentsBloc.clearRecentDocuments();
                  UXHelpers.successFeedback();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: recentDocuments.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final recentDoc = recentDocuments[index];
                return _RecentDocumentCard(recentDocument: recentDoc);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentDocumentCard extends StatelessWidget {
  final RecentDocumentModel recentDocument;

  const _RecentDocumentCard({required this.recentDocument});

  Future<void> _openDocument(BuildContext context) async {
    UXHelpers.selectionFeedback();
    // Fetch the image from database
    final image = await imageBloc.getImageById(recentDocument.documentId);
    if (image == null) {
      if (context.mounted) {
        UXHelpers.errorFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Fetch all images in the folder to show in viewer
    final images = await imageBloc.getImagesByFolderId(recentDocument.folderId);
    final imageIndex = images.indexWhere((img) => img.id == image.id);

    if (context.mounted) {
      Navigator.pushNamed(
        context,
        DocumentViewerPage.route,
        arguments: {
          'images': images,
          'initialIndex': imageIndex >= 0 ? imageIndex : 0,
          'folderId': recentDocument.folderId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openDocument(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (recentDocument.thumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  Uint8List.fromList(recentDocument.thumbnail!),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: CustomColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color: CustomColors.primary,
                        size: 24,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: CustomColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: CustomColors.primary,
                  size: 24,
                ),
              ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                recentDocument.documentName,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CustomColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: CustomColors.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Document Hub Awaits',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Create your first folder to start organizing all your documents',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonSection extends StatelessWidget {
  final List<Map<String, dynamic>> comingSoonFeatures = [
    {
      'icon': Icons.text_fields_rounded,
      'title': 'OCR',
      'description': 'Text recognition',
      'color': CustomColors.primary,
    },
    {
      'icon': Icons.edit_rounded,
      'title': 'Annotations',
      'description': 'Mark up docs',
      'color': CustomColors.accent,
    },
    {
      'icon': Icons.draw_rounded,
      'title': 'Signatures',
      'description': 'Digital signing',
      'color': CustomColors.warning,
    },
    {
      'icon': Icons.backup_rounded,
      'title': 'Local Backup',
      'description': 'Export & restore',
      'color': CustomColors.primary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: comingSoonFeatures.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final feature = comingSoonFeatures[index];
          return _ComingSoonCard(
            icon: feature['icon'] as IconData,
            title: feature['title'] as String,
            description: feature['description'] as String,
            color: feature['color'] as Color,
          );
        },
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: CustomColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: CustomColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 8,
                  color: CustomColors.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
