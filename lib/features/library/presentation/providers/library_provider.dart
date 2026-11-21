import 'package:flutter/foundation.dart';

import '../../domain/entities/library_entities.dart';
import '../../domain/repositories/library_repository.dart';

/// Holds the photo library in memory (paths only, not image data) and
/// derives per-folder counts and covers from it.
class LibraryProvider extends ChangeNotifier {
  final LibraryRepository _repository;

  LibraryProvider(this._repository) {
    load();
  }

  List<PhotoFolder> _folders = [];
  List<LibraryPhoto> _photos = [];
  bool _isLoading = false;
  String? _error;

  List<PhotoFolder> get folders => List.unmodifiable(_folders);
  List<LibraryPhoto> get photos => List.unmodifiable(_photos);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Photos in a folder, or all photos when [folderId] is null.
  List<LibraryPhoto> photosIn(int? folderId) => folderId == null
      ? photos
      : _photos.where((p) => p.folderId == folderId).toList();

  int countIn(int? folderId) => photosIn(folderId).length;

  /// Newest photo in the folder, used as its cover.
  LibraryPhoto? coverOf(int? folderId) {
    final list = folderId == null
        ? _photos
        : _photos.where((p) => p.folderId == folderId);
    return list.isEmpty ? null : list.first;
  }

  PhotoFolder? folderById(int? id) {
    if (id == null) return null;
    for (final f in _folders) {
      if (f.id == id) return f;
    }
    return null;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _folders = await _repository.getFolders();
      _photos = await _repository.getPhotos();
      _error = null;
    } catch (e) {
      _error = 'Could not load your photos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PhotoFolder> createFolder(String name, int color) async {
    final folder = await _repository.createFolder(name.trim(), color);
    _folders = [..._folders, folder]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    return folder;
  }

  Future<void> updateFolder(PhotoFolder folder) async {
    await _repository.updateFolder(folder);
    _folders = [for (final f in _folders) f.id == folder.id ? folder : f]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
  }

  Future<void> deleteFolder(int id) async {
    await _repository.deleteFolder(id);
    _folders = _folders.where((f) => f.id != id).toList();
    _photos = [
      for (final p in _photos)
        p.folderId == id ? p.copyWith(clearFolder: true) : p,
    ];
    notifyListeners();
  }

  Future<int> importFiles(List<String> paths, int? folderId) async {
    if (paths.isEmpty) return 0;
    final added = await _repository.importFiles(paths, folderId);
    _photos = [...added.reversed, ..._photos];
    notifyListeners();
    return added.length;
  }

  Future<LibraryPhoto> addPng(Uint8List png, int? folderId) async {
    final photo = await _repository.addPng(png, folderId);
    _photos = [photo, ..._photos];
    notifyListeners();
    return photo;
  }

  Future<void> movePhotos(List<int> ids, int? folderId) async {
    await _repository.movePhotos(ids, folderId);
    final set = ids.toSet();
    _photos = [
      for (final p in _photos)
        set.contains(p.id)
            ? p.copyWith(folderId: folderId, clearFolder: folderId == null)
            : p,
    ];
    notifyListeners();
  }

  Future<void> deletePhotos(List<int> ids) async {
    await _repository.deletePhotos(ids);
    final set = ids.toSet();
    _photos = _photos.where((p) => !set.contains(p.id)).toList();
    notifyListeners();
  }
}
