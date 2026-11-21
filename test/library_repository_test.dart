// Runs the real SQLite queries (via sqflite_common_ffi) and file handling of
// the photo library against a temporary directory.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qrscan_app/core/database/database_helper.dart';
import 'package:qrscan_app/features/library/data/library_repository_impl.dart';
import 'package:qrscan_app/features/library/presentation/providers/library_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tmp;
  late LibraryRepositoryImpl repo;
  final db = DatabaseHelper();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('locus_lib_test');
    await db.deleteDatabase();
    repo = LibraryRepositoryImpl(db, baseDir: () async => tmp);
  });

  tearDown(() async {
    await db.close();
    await db.deleteDatabase();
    await tmp.delete(recursive: true);
  });

  Future<String> sourceFile(String name) async {
    final f = File('${tmp.path}/$name');
    await f.writeAsBytes([1, 2, 3]);
    return f.path;
  }

  test('import copies files and keeps folder; newest first', () async {
    final trips = await repo.createFolder('Trips', 0xFF1E88E5);
    final a = await sourceFile('a.JPG');
    final b = await sourceFile('b.png');

    final added = await repo.importFiles([a, b], trips.id);
    expect(added, hasLength(2));
    for (final p in added) {
      expect(File(p.path).existsSync(), isTrue);
      expect(p.path, startsWith('${tmp.path}/photos/'));
      expect(p.folderId, trips.id);
    }
    expect(added.first.path, endsWith('.jpg')); // extension normalized

    final all = await repo.getPhotos();
    expect(all.first.id, added.last.id); // newest first
  });

  test(
    'move, delete folder keeps photos, delete photos removes files',
    () async {
      final family = await repo.createFolder('Family', 0xFFF3742D);
      final work = await repo.createFolder('Work', 0xFF43A047);
      final added = await repo.importFiles([
        await sourceFile('1.jpg'),
        await sourceFile('2.jpg'),
      ], family.id);

      await repo.movePhotos([added.first.id], work.id);
      var photos = await repo.getPhotos();
      expect(photos.where((p) => p.folderId == work.id), hasLength(1));

      await repo.deleteFolder(family.id);
      photos = await repo.getPhotos();
      expect(photos, hasLength(2)); // photos survive
      expect(photos.where((p) => p.folderId == null), hasLength(1));
      expect((await repo.getFolders()).map((f) => f.name), ['Work']);

      final path = photos.first.path;
      await repo.deletePhotos([photos.first.id]);
      expect(await repo.getPhotos(), hasLength(1));
      expect(File(path).existsSync(), isFalse);
    },
  );

  test('addPng stores rendered posts; folders sort by name', () async {
    await repo.createFolder('zeta', 1);
    await repo.createFolder('Alpha', 2);
    expect((await repo.getFolders()).map((f) => f.name), ['Alpha', 'zeta']);

    final post = await repo.addPng(Uint8List.fromList([9, 9]), null);
    expect(File(post.path).readAsBytesSync(), [9, 9]);
    expect(post.path, endsWith('.png'));
  });

  test('upgrading a v2 database keeps scans and codes, adds library', () async {
    await db.close();
    await db.deleteDatabase();
    final path = '${await getDatabasesPath()}/qr_scans.db';
    final v2 = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (d, _) async {
          await d.execute(
            'CREATE TABLE scans(id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'qr_data TEXT NOT NULL, timestamp TEXT NOT NULL, '
            'latitude REAL NOT NULL, longitude REAL NOT NULL, '
            'address TEXT NOT NULL, created_at TEXT NOT NULL, '
            'updated_at TEXT NOT NULL)',
          );
          await d.execute(
            'CREATE TABLE created_codes(id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'type TEXT NOT NULL, fields TEXT NOT NULL, style TEXT NOT NULL, '
            'data TEXT NOT NULL, created_at TEXT NOT NULL, '
            'updated_at TEXT NOT NULL)',
          );
          await d.insert('scans', {
            'qr_data': 'hello',
            'timestamp': 't',
            'latitude': 0.0,
            'longitude': 0.0,
            'address': 'a',
            'created_at': 't',
            'updated_at': 't',
          });
        },
      ),
    );
    await v2.close();

    final upgraded = await db.database;
    expect(await upgraded.getVersion(), 3);
    expect(await upgraded.query('scans'), hasLength(1));
    expect(await repo.getFolders(), isEmpty);
    await repo.createFolder('After upgrade', 1);
    expect(await repo.getFolders(), hasLength(1));
  });

  test('provider derives counts and covers', () async {
    final f = await repo.createFolder('Pets', 3);
    await repo.importFiles([await sourceFile('x.jpg')], null);
    final inFolder = await repo.importFiles([await sourceFile('y.jpg')], f.id);

    final provider = LibraryProvider(repo);
    await provider.load();
    expect(provider.countIn(null), 2);
    expect(provider.countIn(f.id), 1);
    expect(provider.coverOf(f.id)?.id, inFolder.single.id);

    await provider.deleteFolder(f.id);
    expect(provider.countIn(null), 2);
    expect(provider.photos.every((p) => p.folderId == null), isTrue);
  });
}
