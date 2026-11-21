import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:qrscan_app/core/theme/app_theme.dart';
import 'package:qrscan_app/features/library/domain/entities/library_entities.dart';
import 'package:qrscan_app/features/library/domain/repositories/library_repository.dart';
import 'package:qrscan_app/features/library/presentation/pages/folder_page.dart';
import 'package:qrscan_app/features/library/presentation/pages/library_page.dart';
import 'package:qrscan_app/features/library/presentation/providers/library_provider.dart';
import 'package:qrscan_app/features/post_maker/domain/post_style.dart';
import 'package:qrscan_app/features/post_maker/domain/quotes.dart';
import 'package:qrscan_app/features/post_maker/presentation/pages/post_editor_page.dart';

/// In-memory library.
class _Repo implements LibraryRepository {
  final List<PhotoFolder> folders;
  final List<LibraryPhoto> photos;
  _Repo(this.folders, this.photos);

  @override
  Future<List<PhotoFolder>> getFolders() async => List.of(folders);
  @override
  Future<List<LibraryPhoto>> getPhotos() async => List.of(photos);
  @override
  Future<PhotoFolder> createFolder(String name, int color) async {
    final f = PhotoFolder(
      id: folders.length + 100,
      name: name,
      color: color,
      createdAt: DateTime(2026),
    );
    folders.add(f);
    return f;
  }

  @override
  Future<void> updateFolder(PhotoFolder folder) async {}
  @override
  Future<void> deleteFolder(int id) async {}
  @override
  Future<List<LibraryPhoto>> importFiles(List<String> p, int? f) async => [];
  @override
  Future<LibraryPhoto> addPng(Uint8List png, int? folderId) async =>
      LibraryPhoto(
        id: 999,
        folderId: folderId,
        path: imagePath,
        createdAt: DateTime(2026),
      );
  @override
  Future<void> movePhotos(List<int> ids, int? folderId) async {}
  @override
  Future<void> deletePhotos(List<int> ids) async {}
}

late String imagePath;

// A valid 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

LibraryProvider _provider() => LibraryProvider(
  _Repo(
    [
      PhotoFolder(
        id: 1,
        name: 'A folder with a long name',
        color: 0xFF1E88E5,
        createdAt: DateTime(2026),
      ),
      PhotoFolder(
        id: 2,
        name: 'Receipts',
        color: 0xFF43A047,
        createdAt: DateTime(2026),
      ),
    ],
    [
      for (var i = 0; i < 9; i++)
        LibraryPhoto(
          id: i,
          folderId: i.isEven ? 1 : null,
          path: imagePath,
          createdAt: DateTime(2026, 1, 9 - i),
        ),
    ],
  ),
);

Future<LibraryProvider> _pump(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(411, 891),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = _provider();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

const _sizes = {
  'small phone': Size(320, 568),
  'phone': Size(411, 891),
  'phone landscape': Size(891, 411),
  'tablet': Size(1280, 800),
};

void main() {
  setUpAll(() {
    final dir = Directory.systemTemp.createTempSync('locus_photo_test');
    imagePath = '${dir.path}/pixel.png';
    File(imagePath).writeAsBytesSync(_png);
  });

  group('PostStyle', () {
    test('moving text stays on the canvas', () {
      const s = PostStyle(dx: 0.9, dy: 0.1);
      final moved = s.moved(0.5, -0.5);
      expect(moved.dx, 1.0);
      expect(moved.dy, 0.0);
    });

    test('size is clamped and signature tracks changes', () {
      const s = PostStyle();
      expect(s.copyWith(scale: 1).scale, PostStyle.maxScale);
      expect(s.copyWith(scale: 0).scale, PostStyle.minScale);
      expect(s.signature, isNot(s.copyWith(text: 'x').signature));
      expect(s.signature, s.copyWith().signature);
    });

    test('quotes are attributed and every category has some', () {
      for (final q in Quote.all) {
        expect(q.text.trim(), isNotEmpty);
        expect(q.author.trim(), isNotEmpty);
        expect(Quote.categories, contains(q.category));
      }
      for (final c in Quote.categories) {
        expect(Quote.all.where((q) => q.category == c), isNotEmpty);
      }
    });
  });

  testWidgets('picking a quote fills text and author', (tester) async {
    await _pump(tester, PostEditorPage(imagePath: imagePath));
    await tester.tap(find.text('Pick a quote'));
    await tester.pumpAndSettle();
    final first = Quote.all.first;
    await tester.tap(find.text(first.text));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, first.text), findsOneWidget);
    expect(find.widgetWithText(TextField, first.author), findsOneWidget);
    // And it's drawn on the canvas.
    expect(find.text('— ${first.author}'), findsOneWidget);
  });

  testWidgets('dragging the text moves it', (tester) async {
    await _pump(tester, PostEditorPage(imagePath: imagePath));
    final placeholder = find.text('Your text here');
    final before = tester.getCenter(placeholder);
    await tester.drag(placeholder, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(tester.getCenter(placeholder).dy, lessThan(before.dy - 40));
  });

  testWidgets('folder page: long-press selects, app bar shows actions', (
    tester,
  ) async {
    await _pump(tester, const FolderPage(folderId: null));
    expect(find.text('All photos'), findsOneWidget);
    await tester.longPress(find.bySemanticsLabel('Photo 1 of 9'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byTooltip('Move to folder'), findsOneWidget);
    await tester.tap(find.byTooltip('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('9 selected'), findsOneWidget);
  });

  // Regression: creating a folder crashed the app ("TextEditingController
  // was used after being disposed") while the dialog animated closed.
  testWidgets('creating a folder from the Photos tab works', (tester) async {
    final provider = await _pump(tester, const Scaffold(body: LibraryPage()));
    await tester.tap(find.text('New folder'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Create'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Family');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    // Pump through the closing animation frame by frame.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(provider.folders.map((f) => f.name), contains('Family'));
    expect(find.text('Family'), findsOneWidget);
  });

  testWidgets('cancelling the folder dialog is safe', (tester) async {
    await _pump(tester, const Scaffold(body: LibraryPage()));
    await tester.tap(find.text('New folder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Temp');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Temp'), findsNothing);
  });

  testWidgets('new folder from the move sheet moves the photos into it', (
    tester,
  ) async {
    final provider = await _pump(tester, const FolderPage(folderId: null));
    await tester.longPress(find.bySemanticsLabel('Photo 2 of 9'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Move to folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New folder…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Trips');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(provider.folders.map((f) => f.name), contains('Trips'));
    expect(find.textContaining('Moved 1 photo to Trips'), findsOneWidget);
  });

  testWidgets('library page shows folders with counts', (tester) async {
    await _pump(tester, const Scaffold(body: LibraryPage()));
    expect(find.text('All photos'), findsOneWidget);
    expect(find.text('9 photos'), findsOneWidget);
    expect(find.text('5 photos'), findsOneWidget); // folder 1: even ids
    expect(find.text('0 photos'), findsOneWidget);
  });

  for (final entry in _sizes.entries) {
    for (final scale in [1.0, 1.5]) {
      final label = '${entry.key} @${scale}x text';

      testWidgets('post editor fits: $label', (tester) async {
        await _pump(
          tester,
          PostEditorPage(imagePath: imagePath),
          size: entry.value,
          textScale: scale,
        );
        expect(find.text('Share'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('photo source chooser fits: $label', (tester) async {
        await _pump(
          tester,
          const PostEditorPage(),
          size: entry.value,
          textScale: scale,
        );
        expect(
          find.text('Choose from gallery', skipOffstage: false),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('library + folder pages fit: $label', (tester) async {
        await _pump(
          tester,
          const Scaffold(body: LibraryPage()),
          size: entry.value,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        await _pump(
          tester,
          const FolderPage(folderId: 1),
          size: entry.value,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
