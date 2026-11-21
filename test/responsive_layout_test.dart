// Renders the new screens at several screen sizes and text scales. Any
// RenderFlex overflow is reported as an exception and fails the test.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrscan_app/core/providers/settings_provider.dart';
import 'package:qrscan_app/core/providers/theme_provider.dart';
import 'package:qrscan_app/features/qrscan/domain/entities/scan.dart';
import 'package:qrscan_app/features/qrscan/domain/repositories/qrscan_repository.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/clear_all_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/get_all_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/save_scan.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/search_scans.dart';
import 'package:qrscan_app/features/qrscan/presentation/providers/qrscan_provider.dart';
import 'package:qrscan_app/core/theme/app_theme.dart';
import 'package:qrscan_app/features/qr_maker/domain/entities/created_code.dart';
import 'package:qrscan_app/features/qr_maker/domain/entities/qr_style.dart';
import 'package:qrscan_app/features/qr_maker/domain/entities/qr_type.dart';
import 'package:qrscan_app/features/qr_maker/domain/repositories/created_code_repository.dart';
import 'package:qrscan_app/features/qr_maker/presentation/pages/create_page.dart';
import 'package:qrscan_app/features/qr_maker/presentation/pages/qr_editor_page.dart';
import 'package:qrscan_app/features/qr_maker/presentation/providers/qr_maker_provider.dart';
import 'package:qrscan_app/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ScanRepo implements QrScanRepository {
  @override
  Future<void> saveScan(Scan scan) async {}
  @override
  Future<List<Scan>> getAllScans() async => [];
  @override
  Future<List<Scan>> searchScans(String q) async => [];
  @override
  Future<void> clearAllScans() async {}
  @override
  Future<void> deleteScan(Scan scan) async {}
  @override
  Future<List<Scan>> getRecentScans(int n) async => [];
}

class _Repo implements CreatedCodeRepository {
  final List<CreatedCode> codes;
  _Repo(this.codes);
  @override
  Future<List<CreatedCode>> getAll() async => codes;
  @override
  Future<CreatedCode> save(CreatedCode code) async => code;
  @override
  Future<void> delete(int id) async {}
}

final _sampleCodes = [
  for (var i = 0; i < 3; i++)
    CreatedCode(
      id: i,
      type: QrType.wifi,
      fields: {
        'ssid': 'A rather long network name $i',
        'password': 'password1',
      },
      style: const QrStyle(caption: 'Scan to join'),
      data: 'WIFI:T:WPA;S:net$i;P:password;;',
      createdAt: DateTime(2026, 11, 21),
      updatedAt: DateTime(2026, 11, 21),
    ),
];

const _sizes = {
  'small phone': Size(320, 568),
  'phone': Size(411, 891),
  'phone landscape': Size(891, 411),
  'tablet': Size(1280, 800),
};

Future<void> _pump(
  WidgetTester tester,
  Size size,
  double textScale,
  Widget home, {
  bool dark = false,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'isDarkMode': dark});

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => QrMakerProvider(_Repo(_sampleCodes)),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final repo = _ScanRepo();
            return QrScanProvider(
              SaveScan(repo),
              GetAllScans(repo),
              SearchScans(repo),
              ClearAllScans(repo),
            );
          },
        ),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
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
}

void main() {
  for (final entry in _sizes.entries) {
    for (final scale in [1.0, 1.5]) {
      final label = '${entry.key} @${scale}x text';

      testWidgets('editor with content fits: $label', (tester) async {
        await _pump(
          tester,
          entry.value,
          scale,
          QrEditorPage.edit(code: _sampleCodes.first),
        );
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('empty wifi editor fits: $label', (tester) async {
        await _pump(
          tester,
          entry.value,
          scale,
          const QrEditorPage(type: QrType.wifi),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('create page fits: $label', (tester) async {
        await _pump(
          tester,
          entry.value,
          scale,
          const Scaffold(body: CreatePage()),
        );
        expect(find.text('Website'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('settings page fits: $label', (tester) async {
        await _pump(
          tester,
          entry.value,
          scale,
          const Scaffold(body: SettingsPage()),
          dark: true,
        );
        expect(find.text('Save location'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Theme'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Theme'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('wide editor shows actions beside the form', (tester) async {
    await _pump(
      tester,
      const Size(1280, 800),
      1,
      QrEditorPage.edit(code: _sampleCodes.first),
    );
    // Actions live in the left pane, not a bottom bar.
    final share = tester.getRect(find.text('Share'));
    expect(share.left, lessThan(400));
    expect(share.bottom, lessThan(700));
  });

  testWidgets('create page: codes list and one row of types on tablets', (
    tester,
  ) async {
    await _pump(
      tester,
      const Size(1280, 800),
      1,
      const Scaffold(body: CreatePage()),
    );
    // My codes is one grouped list.
    final titles = find.textContaining('A rather long network name');
    expect(titles, findsNWidgets(3));
    expect(
      tester.getRect(titles.at(1)).top,
      greaterThan(tester.getRect(titles.at(0)).top),
    );
    // All seven types fit on one row.
    expect(
      tester.getRect(find.text('Website')).top,
      tester.getRect(find.text('Email')).top,
    );
  });
}
