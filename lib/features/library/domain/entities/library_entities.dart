/// A user-made folder in the photo library.
class PhotoFolder {
  final int id;
  final String name;

  /// ARGB color used for the folder's accent.
  final int color;
  final DateTime createdAt;

  const PhotoFolder({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  static const colorPresets = <int>[
    0xFFF3742D, // Locus orange
    0xFF1E88E5, // Blue
    0xFF43A047, // Green
    0xFF8E24AA, // Purple
    0xFFE53935, // Red
    0xFF00897B, // Teal
    0xFF6D4C41, // Brown
  ];
}

/// A photo stored in the app's own library (a copy, not the gallery file).
class LibraryPhoto {
  final int id;

  /// Null when the photo isn't in any folder.
  final int? folderId;

  /// Absolute path of the app's copy.
  final String path;
  final DateTime createdAt;

  const LibraryPhoto({
    required this.id,
    required this.folderId,
    required this.path,
    required this.createdAt,
  });

  LibraryPhoto copyWith({int? folderId, bool clearFolder = false}) =>
      LibraryPhoto(
        id: id,
        folderId: clearFolder ? null : (folderId ?? this.folderId),
        path: path,
        createdAt: createdAt,
      );
}
