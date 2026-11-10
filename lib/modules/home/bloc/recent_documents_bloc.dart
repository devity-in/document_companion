import 'dart:async';
import 'dart:developer' as developer;

import 'package:document_companion/local_database/handler/recent_documents_database_handler.dart';
import 'package:document_companion/local_database/models/recent_document_model.dart';
import 'package:document_companion/local_database/models/image_model.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class RecentDocumentsBloc {
  final StreamController<List<RecentDocumentModel>> _recentDocumentsController =
      StreamController<List<RecentDocumentModel>>.broadcast();
  Stream<List<RecentDocumentModel>> get recentDocumentsStream =>
      _recentDocumentsController.stream;

  final RecentDocumentsDatabaseHandler _databaseHandler =
      recentDocumentsDatabaseHandler;
  final Uuid _uuid = Uuid();

  /// Track document access when viewing a document
  Future<void> trackDocumentAccess(ImageModel image, String folderId) async {
    try {
      final now = DateTime.now();
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      // Check if a recent document entry already exists for this document
      final existingDocument = await _databaseHandler
          .getRecentDocumentByDocumentId(image.id);

      final thumbnail = image.thumbnail;

      final recentDocument = RecentDocumentModel(
        // Reuse existing ID if document already exists, otherwise create new UUID
        id: existingDocument?.id ?? _uuid.v4(),
        documentId: image.id,
        documentType: 'image',
        folderId: folderId,
        documentName: image.name,
        accessedOn: timestamp,
        thumbnail: thumbnail,
      );

      await _databaseHandler.insertOrUpdateRecentDocument(recentDocument);
      await fetchRecentDocuments();
    } catch (e) {
      developer.log('Error tracking document access', error: e);
    }
  }

  /// Fetch recent documents
  Future<void> fetchRecentDocuments({int limit = 10}) async {
    try {
      final recentDocuments = await _databaseHandler.getRecentDocuments(
        limit: limit,
      );
      _recentDocumentsController.sink.add(recentDocuments);
    } catch (e) {
      developer.log('Error fetching recent documents', error: e);
      _recentDocumentsController.sink.add([]);
    }
  }

  /// Delete a recent document
  Future<void> deleteRecentDocument(String id) async {
    try {
      await _databaseHandler.deleteRecentDocument(id);
      await fetchRecentDocuments();
    } catch (e) {
      developer.log('Error deleting recent document', error: e);
    }
  }

  /// Clear all recent documents
  Future<void> clearRecentDocuments() async {
    try {
      await _databaseHandler.clearRecentDocuments();
      await fetchRecentDocuments();
    } catch (e) {
      developer.log('Error clearing recent documents', error: e);
    }
  }

  /// Delete recent document when the actual document is deleted
  Future<void> deleteRecentDocumentByDocumentId(String documentId) async {
    try {
      await _databaseHandler.deleteRecentDocumentByDocumentId(documentId);
      await fetchRecentDocuments();
    } catch (e) {
      developer.log('Error deleting recent document by document id', error: e);
    }
  }

  void dispose() {
    _recentDocumentsController.close();
  }
}

final recentDocumentsBloc = RecentDocumentsBloc();
