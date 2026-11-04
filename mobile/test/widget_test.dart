import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_play/main.dart';

void configurePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> openGame(
  WidgetTester tester,
  String gameTitle,
) async {
  final game = find.text(gameTitle);
  await tester.ensureVisible(game);
  await tester.tap(game);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen renders the NOVA PLAY arcade', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();

    expect(find.text('NOVA PLAY'), findsOneWidget);
    expect(find.text('تحدي إكس أو'), findsOneWidget);
    expect(find.text('اختبار الذاكرة'), findsOneWidget);
    expect(find.text('سرعة الاستجابة'), findsOneWidget);
    expect(find.text('اختبر معلوماتك'), findsOneWidget);
  });

  testWidgets('memory game opens and displays twelve cards', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();
    await openGame(tester, 'اختبار الذاكرة');

    expect(find.text('الأزواج: 0 / 6'), findsOneWidget);
    expect(find.text('?'), findsNWidgets(12));
  });

  testWidgets('tic-tac-toe game opens with an empty board', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();
    await openGame(tester, 'تحدي إكس أو');

    expect(find.text('X     O'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('quick tap game starts and counts the first tap', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();
    await openGame(tester, 'سرعة الاستجابة');

    await tester.tap(find.text('ابدأ'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('10 s'), findsOneWidget);

    // Let the countdown finish so its asynchronous timer is not left pending
    // when the widget test disposes the page.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('انتهى التحدي'), findsOneWidget);
  });

  testWidgets('quiz game displays its first question and answers', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();
    await openGame(tester, 'اختبر معلوماتك');

    expect(find.text('ما أكبر كوكب؟'), findsOneWidget);
    expect(find.text('المشتري'), findsOneWidget);
    expect(find.text('السؤال 1 / 5'), findsOneWidget);
  });

  testWidgets('language menu switches the home screen to French', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();

    expect(find.text('Choisissez un jeu'), findsOneWidget);
    expect(find.text('Morpion'), findsOneWidget);
  });
}
