import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_play/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen renders the NOVA PLAY arcade', (tester) async {
    await tester.view.setPhysicalSize(const Size(800, 1000));
    await tester.view.setDevicePixelRatio(1);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();

    expect(find.text('NOVA PLAY'), findsOneWidget);
    expect(find.text('تحدي إكس أو'), findsOneWidget);
    expect(find.text('اختبار الذاكرة'), findsOneWidget);
  });

  testWidgets('memory game opens and displays all twelve cards', (tester) async {
    await tester.view.setPhysicalSize(const Size(800, 1000));
    await tester.view.setDevicePixelRatio(1);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();

    final memoryTile = find.text('اختبار الذاكرة');
    await tester.ensureVisible(memoryTile);
    await tester.pumpAndSettle();
    await tester.tap(memoryTile);
    await tester.pumpAndSettle();

    expect(find.text('الأزواج: 0 / 6'), findsOneWidget);
    expect(find.text('?'), findsNWidgets(12));
  });
}
