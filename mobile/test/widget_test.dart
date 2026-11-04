import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_play/main.dart';
import 'package:nova_play/snake_game.dart';
import 'package:nova_play/chess_game.dart';

void configurePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(393, 873);
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

  testWidgets('home screen remains usable on a compact Android phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();

    expect(find.text('NOVA PLAY'), findsOneWidget);
    expect(find.text('تحدي إكس أو'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('memory game opens and displays twelve cards', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();
    await openGame(tester, 'اختبار الذاكرة');

    expect(find.text('الأزواج: 0 / 6'), findsOneWidget);
    expect(find.text('✦'), findsNWidgets(12));
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
    expect(find.text('مرحلة مكتملة!'), findsOneWidget);
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    expect(find.text('العب مجدداً'), findsOneWidget);
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

  testWidgets('completing the quiz saves its score for that game', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();
    await openGame(tester, 'اختبر معلوماتك');

    for (final answer in ['المشتري', '7', 'الرباط', 'الجمل', '56']) {
      await tester.tap(find.text(answer).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }

    await tester.pump(const Duration(milliseconds: 100));
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('best_quiz'), 50);
    expect(preferences.getInt('best'), 50);
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

  testWidgets('memory reset cancels a pending mismatch hide callback', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();
    await openGame(tester, 'اختبار الذاكرة');

    final cards = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(GestureDetector),
    );
    expect(cards, findsNWidgets(12));

    await tester.tap(cards.at(0));
    await tester.pump();
    await tester.tap(cards.at(1));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('✦'), findsNWidgets(12));
    expect(find.text('الأزواج: 0 / 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quiz gives correction after a wrong answer and allows continuing', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();
    await openGame(tester, 'اختبر معلوماتك');

    await tester.tap(find.text('الأرض'));
    await tester.pumpAndSettle();

    expect(find.text('الإجابة الصحيحة: المشتري'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('السؤال 2 / 5'), findsOneWidget);
    expect(find.text('كم لوناً في قوس قزح؟'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tic-tac-toe accepts a move and reset clears the board', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();
    await openGame(tester, 'تحدي إكس أو');

    final cells = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(cells.at(0));
    await tester.pumpAndSettle();

    expect(find.text('X'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(find.text('X     O'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });


  testWidgets('memory game can complete all six pairs and persist its score', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();
    await openGame(tester, 'اختبار الذاكرة');

    final cards = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(GestureDetector),
    );
    final positions = <String, List<int>>{};

    // Reveal each card individually to discover the randomized board layout.
    for (var i = 0; i < 12; i++) {
      await tester.tap(cards.at(i));
      await tester.pumpAndSettle();
      final labels = tester.widgetList<Text>(
        find.descendant(of: cards.at(i), matching: find.byType(Text)),
      );
      final emoji = labels.first.data!;
      expect(emoji, isNot('✦'));
      positions.putIfAbsent(emoji, () => <int>[]).add(i);
      await tester.pump(const Duration(milliseconds: 800));
    }

    expect(positions.length, 6);
    for (final pair in positions.values) {
      expect(pair.length, 2);
      await tester.tap(cards.at(pair[0]));
      await tester.pump();
      await tester.tap(cards.at(pair[1]));
      await tester.pumpAndSettle();
    }

    expect(find.text('الأزواج: 6 / 6'), findsOneWidget);
    expect(find.text('مرحلة مكتملة!'), findsOneWidget);
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    expect(find.text('العب مجدداً'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('best_memory'), greaterThan(0));
    expect(preferences.getInt('stage_memory'), 2);
    expect(preferences.getInt('nova_coins'), greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Snake game opens with classic board, controls and rules', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SnakeGamePage(lang: 'ar')));
    await tester.pumpAndSettle();

    expect(find.text('لعبة الأفعى'), findsOneWidget);
    expect(find.text('ابدأ اللعب'), findsOneWidget);
    expect(find.textContaining('كُل الطعام'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });


  testWidgets('chess opens with a complete board and AI difficulty selector', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: ChessGamePage(lang: 'ar')));
    await tester.pumpAndSettle();
    expect(find.text('الشطرنج'), findsOneWidget);
    expect(find.text('دورك — الأبيض'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('متوسط'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
