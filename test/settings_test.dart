import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:qrscan_app/core/providers/settings_provider.dart';
import 'package:qrscan_app/core/providers/theme_provider.dart';
import 'package:qrscan_app/core/theme/app_theme.dart';
import 'package:qrscan_app/features/qr_maker/domain/entities/created_code.dart';
import 'package:qrscan_app/features/qr_maker/domain/entities/qr_style.dart';
import 'package:qrscan_app/features/qr_maker/domain/entities/qr_type.dart';
import 'package:qrscan_app/features/qr_maker/domain/repositories/created_code_repository.dart';
import 'package:qrscan_app/features/qr_maker/presentation/pages/create_page.dart';
import 'package:qrscan_app/features/qr_maker/presentation/providers/qr_maker_provider.dart';
import 'package:qrscan_app/features/qrscan/domain/entities/scan.dart';
import 'package:qrscan_app/features/qrscan/domain/repositories/qrscan_repository.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/clear_all_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/get_all_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/save_scan.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/search_scans.dart';
import 'package:qrscan_app/features/qrscan/presentation/providers/qrscan_provider.dart';
import 'package:qrscan_app/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ScanRepo implements QrScanRepository {
  final scans = <Scan>[
    Scan(
      qrData: 'a',
      timestamp: DateTime(2026),
      latitude: 0,
      longitude: 0,
      address: 'x',
    ),
  ];
  @override
  Future<void> saveScan(Scan s) async => scans.add(s);
  @override
  Future<List<Scan>> getAllScans() async => List.of(scans);
  @override
  Future<List<Scan>> searchScans(String q) async => [];
  @override
  Future<void> clearAllScans() async => scans.clear();
  @override
  Future<void> deleteScan(Scan s) async => scans.remove(s);
  @override
  Future<List<Scan>> getRecentScans(int n) async => [];
}

class _CodeRepo implements CreatedCodeRepository {
  final codes = <CreatedCode>[];
  int _id = 1;
  @override
  Future<List<CreatedCode>> getAll() async => List.of(codes);
  @override
  Future<CreatedCode> save(CreatedCode c) async {
    final saved = c.id == null ? c.copyWith(id: _id++) : c;
    codes.add(saved);
    return saved;
  }

  @override
  Future<void> delete(int id) async => codes.removeWhere((c) => c.id == id);
}

void main() {
  group('SettingsProvider', () {
    test('defaults on, persists changes', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsProvider();
      await Future<void>.delayed(Duration.zero);
      expect([s.saveScans, s.saveLocation, s.vibrate], [true, true, true]);

      s.saveLocation = false;
      s.vibrate = false;
      await Future<void>.delayed(Duration.zero);
      final again = SettingsProvider();
      await Future<void>.delayed(Duration.zero);
      expect(again.saveLocation, isFalse);
      expect(again.vibrate, isFalse);
      expect(again.saveScans, isTrue);
    });
  });

  group('ThemeProvider', () {
    test('carries over the old dark-mode switch', () async {
      SharedPreferences.setMockInitialValues({'isDarkMode': true});
      final t = ThemeProvider();
      await Future<void>.delayed(Duration.zero);
      expect(t.themeMode, ThemeMode.dark);
    });

    test('remembers System', () async {
      SharedPreferences.setMockInitialValues({});
      final t = ThemeProvider();
      await Future<void>.delayed(Duration.zero);
      await t.setThemeMode(ThemeMode.system);
      final again = ThemeProvider();
      await Future<void>.delayed(Duration.zero);
      expect(again.themeMode, ThemeMode.system);
    });
  });

  Future<(SettingsProvider, ThemeProvider, QrScanProvider)> pumpSettings(
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..physicalSize = const Size(411, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = SettingsProvider();
    final theme = ThemeProvider();
    final repo = _ScanRepo();
    final scans = QrScanProvider(
      SaveScan(repo),
      GetAllScans(repo),
      SearchScans(repo),
      ClearAllScans(repo),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: scans),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: SettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (settings, theme, scans);
  }

  testWidgets('turning off Save scans disables Save location', (tester) async {
    final (settings, _, _) = await pumpSettings(tester);
    SwitchListTile tile(String title) => tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, title),
    );
    expect(tile('Save location').onChanged, isNotNull);

    await tester.tap(find.text('Save scans'));
    await tester.pumpAndSettle();
    expect(settings.saveScans, isFalse);
    expect(tile('Save location').onChanged, isNull);
    expect(tile('Save location').value, isFalse);
    expect(find.text('Turn on "Save scans" first'), findsOneWidget);

    await tester.tap(find.text('Vibrate on scan'));
    await tester.pumpAndSettle();
    expect(settings.vibrate, isFalse);
  });

  testWidgets('theme choice and clearing scans', (tester) async {
    final (_, theme, scans) = await pumpSettings(tester);
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(theme.themeMode, ThemeMode.system);

    expect(find.text('1 scan saved'), findsOneWidget);
    await tester.tap(find.text('Clear all scans'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(scans.scans, isEmpty);
    expect(find.text('No scans saved'), findsOneWidget);
  });

  testWidgets('My codes: swipe deletes, Undo restores', (tester) async {
    tester.view
      ..physicalSize = const Size(411, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _CodeRepo();
    await repo.save(
      CreatedCode(
        type: QrType.url,
        fields: const {'url': 'example.com'},
        style: const QrStyle(),
        data: 'https://example.com',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    final provider = QrMakerProvider(repo);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: CreatePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('QR code'), findsOneWidget);
    expect(find.text('Photo post'), findsOneWidget);

    await tester.drag(find.text('example.com'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(provider.codes, isEmpty);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(provider.codes, hasLength(1));
    expect(find.text('example.com'), findsOneWidget);
  });
}
