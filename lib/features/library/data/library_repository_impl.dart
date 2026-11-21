import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/database_helper.dart';
import '../domain/entities/library_entities.dart';
import '../domain/repositories/library_repository.dart';

/// SQLite rows + image files in `<app documents>/photos/`.
class LibraryRepositoryImpl implements LibraryRepository {
  final DatabaseHelper _db;

  /// Overridable for tests.
  final Future<Directory> Function() _baseDir;

  LibraryRepositoryImpl(this._db, {Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationDocumentsDirectory;

  Directory? _photoDir;
  final _random = Random();

  Future<Directory> _dir() async {
    if (_photoDir != null) return _photoDir!;
    final dir = Directory(p.join((await _baseDir()).path, 'photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return _photoDir = dir;
  }

  String _newName(String ext) =>
      '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}$ext';

  LibraryPhoto _photoFromRow(Map<String, Object?> row, Directory dir) =>
      LibraryPhoto(
        id: row['id'] as int,
        folderId: row['folder_id'] as int?,
        path: p.join(dir.path, row['file_name'] as String),
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  @override
  Future<List<PhotoFolder>> getFolders() async {
    final db = await _db.database;
    final rows = await db.query('folders', orderBy: 'name COLLATE NOCASE');
    return [
      for (final r in rows)
        PhotoFolder(
          id: r['id'] as int,
          name: r['name'] as String,
          color: r['color'] as int,
          createdAt: DateTime.parse(r['created_at'] as String),
        ),
    ];
  }

  @override
  Future<List<LibraryPhoto>> getPhotos() async {
    final db = await _db.database;
    final dir = await _dir();
    final rows = await db.query('photos', orderBy: 'created_at DESC, id DESC');
    return [for (final r in rows) _photoFromRow(r, dir)];
  }

  @override
  Future<PhotoFolder> createFolder(String name, int color) async {
    final db = await _db.database;
    final now = DateTime.now();
    final id = await db.insert('folders', {
      'name': name,
      'color': color,
      'created_at': now.toIso8601String(),
    });
    return PhotoFolder(id: id, name: name, color: color, createdAt: now);
  }

  @override
  Future<void> updateFolder(PhotoFolder folder) async {
    final db = await _db.database;
    await db.update(
      'folders',
      {'name': folder.name, 'color': folder.color},
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  @override
  Future<void> deleteFolder(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(
        'photos',
        {'folder_id': null},
        where: 'folder_id = ?',
        whereArgs: [id],
      );
      await txn.delete('folders', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<LibraryPhoto> _insert(String fileName, int? folderId) async {
    final db = await _db.database;
    final now = DateTime.now();
    final id = await db.insert('photos', {
      'folder_id': folderId,
      'file_name': fileName,
      'created_at': now.toIso8601String(),
    });
    return LibraryPhoto(
      id: id,
      folderId: folderId,
      path: p.join((await _dir()).path, fileName),
      createdAt: now,
    );
  }

  @override
  Future<List<LibraryPhoto>> importFiles(
    List<String> paths,
    int? folderId,
  ) async {
    final dir = await _dir();
    final added = <LibraryPhoto>[];
    for (final src in paths) {
      final ext = p.extension(src).isEmpty ? '.jpg' : p.extension(src);
      final name = _newName(ext.toLowerCase());
      await File(src).copy(p.join(dir.path, name));
      added.add(await _insert(name, folderId));
    }
    return added;
  }

  @override
  Future<LibraryPhoto> addPng(Uint8List png, int? folderId) async {
    final dir = await _dir();
    final name = _newName('.png');
    await File(p.join(dir.path, name)).writeAsBytes(png, flush: true);
    return _insert(name, folderId);
  }

  @override
  Future<void> movePhotos(List<int> ids, int? folderId) async {
    if (ids.isEmpty) return;
    final db = await _db.database;
    await db.update(
      'photos',
      {'folder_id': folderId},
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }

  @override
  Future<void> deletePhotos(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _db.database;
    final dir = await _dir();
    final where = 'id IN (${List.filled(ids.length, '?').join(',')})';
    final rows = await db.query(
      'photos',
      columns: ['file_name'],
      where: where,
      whereArgs: ids,
    );
    await db.delete('photos', where: where, whereArgs: ids);
    for (final r in rows) {
      final f = File(p.join(dir.path, r['file_name'] as String));
      if (await f.exists()) await f.delete();
    }
  }
}
