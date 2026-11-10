import 'package:document_companion/local_database/models/image_model.dart';
import 'package:document_companion/modules/home/bloc/recent_documents_bloc.dart';
import 'package:document_companion/modules/home/services/document_service.dart';
import 'package:flutter/material.dart';

class DocumentViewerPage extends StatefulWidget {
  static const route = '/document_viewer';

  final List<ImageModel> images;
  final int initialIndex;
  final String folderId;

  const DocumentViewerPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.folderId,
  });

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Track document access
    _trackDocumentAccess();
  }

  void _trackDocumentAccess() {
    if (widget.images.isNotEmpty) {
      recentDocumentsBloc.trackDocumentAccess(
        widget.images[widget.initialIndex],
        widget.folderId,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _showDocumentOptions(ImageModel image) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _DocumentOptionsSheet(image: image, folderId: widget.folderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showDocumentOptions(widget.images[_currentIndex]),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _transformationController.value = Matrix4.identity();
          });
        },
        itemBuilder: (context, index) {
          final image = widget.images[index];
          return InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(child: Image.file(image.file, fit: BoxFit.contain)),
          );
        },
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
