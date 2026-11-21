import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:qrscan_app/core/theme/app_theme.dart';
import 'package:qrscan_app/features/qrscan/domain/entities/scan.dart';
import 'package:qrscan_app/features/qrscan/domain/repositories/qrscan_repository.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/clear_all_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/delete_scan.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/get_all_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/save_scan.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/search_scans.dart';
import 'package:qrscan_app/features/qrscan/presentation/pages/qrscan_history_page.dart';
import 'package:qrscan_app/features/qrscan/presentation/providers/qrscan_provider.dart';
import 'package:qrscan_app/features/qrscan/presentation/widgets/scan_kind.dart';

class _Repo implements QrScanRepository {
  final List<Scan> scans;
  _Repo(this.scans);
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
  Future<List<Scan>> getRecentScans(int n) async => scans.take(n).toList();
}

Scan _s(String data, DateTime when, [String place = 'Arusha, Tanzania']) =>
    Scan(
      qrData: data,
      timestamp: when,
      latitude: 0,
      longitude: 0,
      address: place,
    );

Future<(QrScanProvider, _Repo)> _pump(
  WidgetTester tester,
  List<Scan> scans, {
  Size size = const Size(411, 891),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = _Repo(List.of(scans));
  final provider = QrScanProvider(
    SaveScan(repo),
    GetAllScans(repo),
    SearchScans(repo),
    ClearAllScans(repo),
    deleteScanUseCase: DeleteScan(repo),
  );
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
        home: const Scaffold(body: QrScanHistoryPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (provider, repo);
}

void main() {
  group('ScanKind', () {
    test('recognizes common QR payloads', () {
      expect(
        ScanKind.of('https://www.github.com/flutter').title,
        'github.com/flutter',
      );
      expect(ScanKind.of('https://example.com/').title, 'example.com');
      expect(ScanKind.of(r'WIFI:T:WPA;S:Cafe\;1;P:x;;').title, 'Cafe;1');
      expect(ScanKind.of('WIFI:T:WPA;S:Home;P:x;;').label, 'Wi-Fi');
      expect(
        ScanKind.of('BEGIN:VCARD\nVERSION:3.0\nFN:Asha Juma\nEND:VCARD').title,
        'Asha Juma',
      );
      expect(ScanKind.of('tel:+255712000111').title, '+255712000111');
      expect(ScanKind.of('SMSTO:0712345678:hi').title, '0712345678');
      expect(ScanKind.of('mailto:a@b.co?subject=x').title, 'a@b.co');
      expect(ScanKind.of('a@b.co').label, 'Email');
      expect(ScanKind.of('+255 712 345 678').label, 'Phone');
      expect(ScanKind.of('hello\nworld').title, 'hello');
      expect(ScanKind.of('hello').label, 'Text');
    });

    test('day labels', () {
      final now = DateTime(2026, 11, 21, 12); // a Saturday
      expect(dayLabel(DateTime(2026, 11, 21, 1), now: now), 'Today');
      expect(dayLabel(DateTime(2026, 11, 20, 23), now: now), 'Yesterday');
      expect(dayLabel(DateTime(2026, 11, 17), now: now), 'Tuesday');
      expect(dayLabel(DateTime(2026, 10, 2), now: now), '2 Oct 2026');
      expect(timeLabel(DateTime(2026, 1, 1, 9, 5)), '09:05');
    });
  });

  final now = DateTime.now();
  final scans = [
    _s('https://github.com/', now),
    _s(
      'WIFI:T:WPA;S:HomeNet;P:secret12;;',
      now.subtract(const Duration(minutes: 5)),
    ),
    _s(
      'hello there',
      now.subtract(const Duration(days: 1)),
      'Dodoma, Tanzania',
    ),
  ];

  testWidgets('groups by day with readable titles', (tester) async {
    await _pump(tester, scans);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('github.com'), findsOneWidget);
    expect(find.text('HomeNet'), findsOneWidget);
    expect(find.textContaining('Wi-Fi ·'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe deletes, Undo brings it back', (tester) async {
    final (provider, repo) = await _pump(tester, scans);
    await tester.drag(find.text('github.com'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('github.com'), findsNothing);
    expect(provider.scans, hasLength(2));
    expect(repo.scans, hasLength(2));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('github.com'), findsOneWidget);
    expect(provider.scans.first.qrData, 'https://github.com/');
    expect(repo.scans, hasLength(3));
  });

  testWidgets('long-press offers actions', (tester) async {
    await _pump(tester, scans);
    await tester.longPress(find.text('HomeNet'));
    await tester.pumpAndSettle();
    for (final a in ['Details', 'Copy', 'Share', 'Delete']) {
      expect(find.text(a), findsOneWidget);
    }
  });

  testWidgets('search filters by content, title and place', (tester) async {
    await _pump(tester, scans);
    await tester.enterText(find.byType(TextField), 'dodoma');
    await tester.pumpAndSettle();
    expect(find.text('1 result'), findsOneWidget);
    expect(find.text('hello there'), findsOneWidget);
    expect(find.text('github.com'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nothing-like-this');
    await tester.pumpAndSettle();
    expect(find.textContaining('No scans match'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('github.com'), findsOneWidget);
  });

  for (final size in const [Size(320, 568), Size(891, 411), Size(1280, 800)]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('fits $size @${scale}x', (tester) async {
        await _pump(tester, scans, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
