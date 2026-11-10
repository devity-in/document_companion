import 'dart:async';

import 'package:document_companion/local_database/handler/folder_table_handler.dart';
import 'package:document_companion/local_database/handler/tag_database_handler.dart';
import 'package:document_companion/local_database/models/folder_model.dart';
import 'package:uuid/uuid.dart';

import '../models/folder_view_model.dart';

class FolderBloc {
  final uuid = Uuid();
  StreamController<List<FolderViewModel>> folderListController =
      StreamController<List<FolderViewModel>>.broadcast();
  Stream<List<FolderViewModel>> get folderList => folderListController.stream;

  List<FolderViewModel> _allFolders = [];
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'created', 'modified'
  bool _sortAscending = true;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterDateType; // 'created' or 'modified'
  Set<String> _selectedTagIds = {}; // Tag filtering

  Future<void> createFolder(String folderName) async {
    final tableData = FolderModel(
      id: uuid.v4(),
      folderName: folderName,
      createdOn: DateTime.now().millisecondsSinceEpoch.toString(),
      modifiedOn: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    await folderTableHandler.insertFolder(tableData);
    await fetchFolders();
  }

  Future<void> fetchFolders() async {
    List<FolderModel> foldersData = await folderTableHandler.getFolders();
    _allFolders = [];
    for (var folder in foldersData) {
      _allFolders.add(
        FolderViewModel(
          id: folder.id,
          createdOn: folder.createdOn,
          folderName: folder.folderName,
          modifiedOn: folder.modifiedOn,
        ),
      );
    }
    _applyFilters();
  }

  void searchFolders(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters(); // Fire and forget for sync operations
  }

  void sortFolders(String sortBy, {bool ascending = true}) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFilters(); // Fire and forget for sync operations
  }

  Future<void> _applyFilters() async {
    List<FolderViewModel> filtered = List.from(_allFolders);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((folder) {
        return folder.folderName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply date range filter
    if (_filterStartDate != null || _filterEndDate != null) {
      filtered = filtered.where((folder) {
        final dateString = _filterDateType == 'modified'
            ? folder.modifiedOn
            : folder.createdOn;
        final folderDate = DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(dateString) ?? 0,
        );

        bool matchesStart =
            _filterStartDate == null ||
            folderDate.isAfter(
              _filterStartDate!.subtract(const Duration(days: 1)),
            ) ||
            folderDate.isAtSameMomentAs(_filterStartDate!);
        bool matchesEnd =
            _filterEndDate == null ||
            folderDate.isBefore(_filterEndDate!.add(const Duration(days: 1))) ||
            folderDate.isAtSameMomentAs(_filterEndDate!);

        return matchesStart && matchesEnd;
      }).toList();
    }

    // Apply tag filter (async operation)
    if (_selectedTagIds.isNotEmpty) {
      final tagHandler = TagDatabaseHandler();
      final folderIdsWithTags = <String>{};

      // Get all folder IDs that have at least one of the selected tags
      for (var tagId in _selectedTagIds) {
        final folderIds = await tagHandler.getFolderIdsByTagId(tagId);
        folderIdsWithTags.addAll(folderIds);
      }

      // Filter folders to only those that have the selected tags
      filtered = filtered.where((folder) {
        return folderIdsWithTags.contains(folder.id);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.folderName.compareTo(b.folderName);
          break;
        case 'created':
          comparison = a.createdOn.compareTo(b.createdOn);
          break;
        case 'modified':
          comparison = a.modifiedOn.compareTo(b.modifiedOn);
          break;
        default:
          comparison = a.folderName.compareTo(b.folderName);
      }
      return _sortAscending ? comparison : -comparison;
    });

    folderListController.add(filtered);
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters(); // Fire and forget for sync operations
  }

  void applyDateFilter({
    DateTime? startDate,
    DateTime? endDate,
    String? dateType,
  }) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    _filterDateType = dateType;
    _applyFilters(); // Fire and forget for sync operations
  }

  void clearDateFilter() {
    _filterStartDate = null;
    _filterEndDate = null;
    _filterDateType = null;
    _applyFilters(); // Fire and forget for sync operations
  }

  Future<void> applyTagFilter(Set<String> tagIds) async {
    _selectedTagIds = Set.from(tagIds);
    await _applyFilters();
  }

  Future<void> clearTagFilter() async {
    _selectedTagIds.clear();
    await _applyFilters();
  }

  bool get hasActiveFilters =>
      _filterStartDate != null ||
      _filterEndDate != null ||
      _selectedTagIds.isNotEmpty;

  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String? get filterDateType => _filterDateType;
  Set<String> get selectedTagIds => Set.from(_selectedTagIds);

  Future<void> updateFolder(String folderId, String newName) async {
    final index = _allFolders.indexWhere((f) => f.id == folderId);
    if (index < 0) return;
    final folder = _allFolders[index];
    final updatedFolder = FolderModel(
      id: folder.id,
      folderName: newName,
      createdOn: folder.createdOn,
      modifiedOn: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    await folderTableHandler.updateFolder(updatedFolder);
    await fetchFolders();
  }

  Future<void> deleteFolder(String folderId) async {
    await folderTableHandler.deleteFolder(folderId);
    await fetchFolders();
  }

  List<FolderViewModel> getAllFolders() {
    return List.from(_allFolders);
  }
}

final folderBloc = FolderBloc();
