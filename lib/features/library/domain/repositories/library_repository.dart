import 'dart:typed_data';

import '../entities/library_entities.dart';

abstract class LibraryRepository {
  Future<List<PhotoFolder>> getFolders();

  /// All photos, newest first.
  Future<List<LibraryPhoto>> getPhotos();

  Future<PhotoFolder> createFolder(String name, int color);
  Future<void> updateFolder(PhotoFolder folder);

  /// Deletes the folder; its photos stay in the library without a folder.
  Future<void> deleteFolder(int id);

  /// Copies image files (e.g. from the camera or gallery) into the library.
  Future<List<LibraryPhoto>> importFiles(List<String> paths, int? folderId);

  /// Stores rendered image bytes (e.g. a photo post) in the library.
  Future<LibraryPhoto> addPng(Uint8List png, int? folderId);

  Future<void> movePhotos(List<int> ids, int? folderId);

  /// Removes the photos and their files from the library.
  Future<void> deletePhotos(List<int> ids);
}
