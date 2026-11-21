import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:qrscan_app/core/providers/theme_provider.dart';
import 'package:qrscan_app/core/theme/app_theme.dart';
import 'package:qrscan_app/features/library/domain/entities/library_entities.dart';
import 'package:qrscan_app/features/library/domain/repositories/library_repository.dart';
import 'package:qrscan_app/features/library/presentation/providers/library_provider.dart';
import 'package:qrscan_app/features/qr_maker/domain/entities/created_code.dart';
import 'package:qrscan_app/features/qr_maker/domain/repositories/created_code_repository.dart';
import 'package:qrscan_app/features/qr_maker/presentation/providers/qr_maker_provider.dart';
import 'package:qrscan_app/features/qrscan/domain/entities/scan.dart';
import 'package:qrscan_app/features/qrscan/domain/repositories/qrscan_repository.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/clear_all_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/get_all_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/save_scan.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/search_scans.dart';
import 'package:qrscan_app/features/qrscan/presentation/pages/main_navigation_page.dart';
import 'package:qrscan_app/features/qrscan/presentation/pages/scan_page.dart';
import 'package:qrscan_app/features/qrscan/presentation/providers/qrscan_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ScanRepo implements QrScanRepository {
  final scans = <Scan>[];
  @override
  Future<void> saveScan(Scan scan) async => scans.insert(0, scan);
  @override
  Future<List<Scan>> getAllScans() async => List.of(scans);
  @override
  Future<List<Scan>> searchScans(String q) async => [];
  @override
  Future<void> clearAllScans() async => scans.clear();
  @override
  Future<void> deleteScan(Scan scan) async => scans.remove(scan);
  @override
  Future<List<Scan>> getRecentScans(int limit) async =>
      scans.take(limit).toList();
}

class _CodeRepo implements CreatedCodeRepository {
  @override
  Future<List<CreatedCode>> getAll() async => [];
  @override
  Future<CreatedCode> save(CreatedCode c) async => c;
  @override
  Future<void> delete(int id) async {}
}

class _LibRepo implements LibraryRepository {
  @override
  Future<List<PhotoFolder>> getFolders() async => [];
  @override
  Future<List<LibraryPhoto>> getPhotos() async => [];
  @override
  Future<PhotoFolder> createFolder(String n, int c) async =>
      PhotoFolder(id: 1, name: n, color: c, createdAt: DateTime(2026));
  @override
  Future<void> updateFolder(PhotoFolder f) async {}
  @override
  Future<void> deleteFolder(int id) async {}
  @override
  Future<List<LibraryPhoto>> importFiles(List<String> p, int? f) async => [];
  @override
  Future<LibraryPhoto> addPng(Uint8List b, int? f) async =>
      throw UnimplementedError();
  @override
  Future<void> movePhotos(List<int> i, int? f) async {}
  @override
  Future<void> deletePhotos(List<int> i) async {}
}

final _scan = Scan(
  qrData: 'https://example.com',
  timestamp: DateTime(2026, 11, 21, 10),
  latitude: -6.8,
  longitude: 39.2,
  address: 'Dar es Salaam, Tanzania',
);

Future<void> _pumpSheet(
  WidgetTester tester,
  Future<Scan?> saving, {
  Size size = const Size(411, 891),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: ScanResultSheet(data: 'https://example.com', saving: saving),
      ),
    ),
  );
}

void main() {
  group('ScanResultSheet', () {
    testWidgets('shows saving, then saved with address', (tester) async {
      final done = Completer<Scan>();
      await _pumpSheet(tester, done.future);
      expect(find.text('Saving…'), findsOneWidget);
      done.complete(_scan);
      await tester.pumpAndSettle();
      expect(
        find.text('Saved to Scans · Dar es Salaam, Tanzania'),
        findsOneWidget,
      );
      expect(find.text('Scan again'), findsOneWidget);
    });

    testWidgets('says so when saving is turned off', (tester) async {
      await _pumpSheet(tester, Future<Scan?>.value(null));
      await tester.pumpAndSettle();
      expect(
        find.text('Not saved — saving scans is off in Settings'),
        findsOneWidget,
      );
    });

    testWidgets('notes when a scan was saved without location', (tester) async {
      await _pumpSheet(
        tester,
        Future.value(
          Scan(
            qrData: 'x',
            timestamp: DateTime(2026),
            latitude: 0,
            longitude: 0,
            address: Scan.noLocation,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saved to Scans (without location)'), findsOneWidget);
    });

    testWidgets('explains when saving fails', (tester) async {
      final done = Completer<Scan>();
      await _pumpSheet(tester, done.future);
      done.completeError(Exception('Location service disabled'));
      await tester.pumpAndSettle();
      expect(find.text('Not saved: Location service disabled'), findsOneWidget);
    });

    testWidgets('copy puts the code on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      await _pumpSheet(tester, Future.value(_scan));
      await tester.tap(find.byTooltip('Copy'));
      await tester.pump();
      expect(copied, 'https://example.com');
    });

    for (final size in const [
      Size(320, 568),
      Size(891, 411),
      Size(1280, 800),
    ]) {
      testWidgets('fits $size at 1.5x text', (tester) async {
        await _pumpSheet(
          tester,
          Future.value(_scan),
          size: size,
          textScale: 1.5,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('home is the Scans list; Scan button opens the camera', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..physicalSize = const Size(411, 891)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _ScanRepo()..scans.add(_scan);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => QrScanProvider(
              SaveScan(repo),
              GetAllScans(repo),
              SearchScans(repo),
              ClearAllScans(repo),
            ),
          ),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => QrMakerProvider(_CodeRepo())),
          ChangeNotifierProvider(create: (_) => LibraryProvider(_LibRepo())),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bar = find.byType(NavigationBar);
    for (final label in ['Scans', 'Photos', 'Create']) {
      expect(
        find.descendant(of: bar, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: bar, matching: find.text('History')),
      findsNothing,
    );
    expect(find.descendant(of: bar, matching: find.text('Home')), findsNothing);

    // The home tab lists scans, and has the Scan button.
    expect(find.text('example.com'), findsOneWidget);
    final fab = find.widgetWithText(FloatingActionButton, 'Scan');
    expect(fab, findsOneWidget);
    expect(find.byType(ScannerPage), findsNothing); // camera not running

    // Other tabs don't show it.
    await tester.tap(find.descendant(of: bar, matching: find.text('Create')));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.descendant(of: bar, matching: find.text('Scans')));
    await tester.pumpAndSettle();

    // Scan opens the full-screen scanner (the camera plugin isn't available
    // in tests, so its errors are ignored).
    await tester.tap(fab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tester.takeException();
    expect(find.byType(ScannerPage), findsOneWidget);
    expect(find.text('Scan a code'), findsOneWidget);

    // Back returns to the list.
    await tester.pageBack();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();
    }
    expect(find.byType(ScannerPage), findsNothing);
    expect(find.text('example.com'), findsOneWidget);
  });

  testWidgets('Scan button shrinks while scrolling down', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..physicalSize = const Size(411, 891)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _ScanRepo();
    for (var i = 0; i < 30; i++) {
      repo.scans.add(
        Scan(
          qrData: 'code $i',
          timestamp: DateTime.now().subtract(Duration(minutes: i)),
          latitude: 0,
          longitude: 0,
          address: 'Somewhere',
        ),
      );
    }
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => QrScanProvider(
              SaveScan(repo),
              GetAllScans(repo),
              SearchScans(repo),
              ClearAllScans(repo),
            ),
          ),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => QrMakerProvider(_CodeRepo())),
          ChangeNotifierProvider(create: (_) => LibraryProvider(_LibRepo())),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Scan'), findsWidgets); // label visible

    await tester.drag(find.text('code 5'), const Offset(0, -300));
    await tester.pumpAndSettle();
    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.isExtended, isFalse);

    await tester.drag(find.text('code 10'), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .isExtended,
      isTrue,
    );
  });

  testWidgets('empty Scans list points to the Scan button', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _ScanRepo();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => QrScanProvider(
              SaveScan(repo),
              GetAllScans(repo),
              SearchScans(repo),
              ClearAllScans(repo),
            ),
          ),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => QrMakerProvider(_CodeRepo())),
          ChangeNotifierProvider(create: (_) => LibraryProvider(_LibRepo())),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No scans yet'), findsOneWidget);
    expect(find.textContaining('Tap Scan to read'), findsOneWidget);
    expect(find.byTooltip('Clear all scans'), findsNothing);
  });
}
