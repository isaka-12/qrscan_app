import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrscan_app/features/qr_maker/domain/entities/created_code.dart';
import 'package:qrscan_app/features/qr_maker/domain/entities/qr_type.dart';
import 'package:qrscan_app/features/qr_maker/domain/repositories/created_code_repository.dart';
import 'package:qrscan_app/features/qr_maker/presentation/pages/create_page.dart';
import 'package:qrscan_app/features/qr_maker/presentation/pages/qr_editor_page.dart';
import 'package:qrscan_app/features/qr_maker/presentation/providers/qr_maker_provider.dart';

class _FakeRepo implements CreatedCodeRepository {
  final List<CreatedCode> saved = [];
  int _nextId = 1;

  @override
  Future<List<CreatedCode>> getAll() async => List.of(saved);

  @override
  Future<CreatedCode> save(CreatedCode code) async {
    final withId = code.id == null ? code.copyWith(id: _nextId++) : code;
    saved
      ..removeWhere((c) => c.id == withId.id)
      ..add(withId);
    return withId;
  }

  @override
  Future<void> delete(int id) async => saved.removeWhere((c) => c.id == id);
}

/// [scaffold] wraps pages that live inside the app's main Scaffold (tabs);
/// the editor is a full route with its own Scaffold.
Widget _wrap(QrMakerProvider provider, Widget child, {bool scaffold = false}) =>
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(home: scaffold ? Scaffold(body: child) : child),
    );

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    // A tall phone screen so the whole form is built.
    binding.platformDispatcher.views.first
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 2.6;
  });
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  testWidgets('editor shows a live preview and saves to My codes', (
    tester,
  ) async {
    final repo = _FakeRepo();
    final provider = QrMakerProvider(repo);
    await tester.pumpWidget(
      _wrap(provider, const QrEditorPage(type: QrType.url)),
    );

    // Empty form: hint instead of a code, actions disabled.
    expect(
      find.text('Fill in the details below to see your QR code'),
      findsOneWidget,
    );
    expect(find.byType(QrImageView), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'bad');
    await tester.pump();
    expect(find.text('Enter a valid website address'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'example.com');
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.saved.single.data, 'https://example.com');
    expect(find.text('Saved'), findsOneWidget);

    // Editing again updates the same record instead of adding another.
    await tester.enterText(find.byType(TextField).first, 'example.org');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.saved.single.data, 'https://example.org');
  });

  testWidgets('wifi password field hides for open networks', (tester) async {
    final provider = QrMakerProvider(_FakeRepo());
    await tester.pumpWidget(
      _wrap(provider, const QrEditorPage(type: QrType.wifi)),
    );
    expect(find.text('Password *'), findsOneWidget);

    await tester.tap(find.text('WPA/WPA2/WPA3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None').last);
    await tester.pumpAndSettle();
    expect(find.text('Password *'), findsNothing);
  });

  testWidgets('create page lists types and saved codes', (tester) async {
    final repo = _FakeRepo();
    final provider = QrMakerProvider(repo);
    await tester.pumpWidget(
      _wrap(provider, const CreatePage(), scaffold: true),
    );
    await tester.pumpAndSettle();

    for (final t in QrType.values) {
      expect(find.text(t.label), findsOneWidget);
    }
    expect(find.textContaining('Codes you save appear here'), findsOneWidget);
  });
}
