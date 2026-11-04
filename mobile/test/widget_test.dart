import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_play/main.dart';
import 'package:nova_play/snake_game.dart';
import 'package:nova_play/chess_game.dart';
import 'package:nova_play/pacman_game.dart';
import 'package:nova_play/sonic_runner_game.dart';

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
  testWidgets('Velocity Runner advances through its high-speed course without exceptions', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SonicRunnerPage(lang: 'en')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ready to run?'));
    await tester.pump();

    final rightControl = find.byIcon(Icons.arrow_forward);
    final gesture = await tester.startGesture(tester.getCenter(rightControl));
    await tester.pump(const Duration(seconds: 7));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });

  testWidgets('every home game card uses its own custom vector emblem', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();

    final glyphs = find.byWidgetPredicate((widget) =>
        widget is CustomPaint && widget.painter is ArcadeGameGlyph);
    expect(glyphs, findsNWidgets(8));
    expect(tester.takeException(), isNull);
  });

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
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('باك مان'), findsOneWidget);
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
  testWidgets('chess rejects an illegal move and completes a legal player/computer turn', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: ChessGamePage(lang: 'ar')));
    await tester.pumpAndSettle();

    final squares = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(GestureDetector),
    );
    // Board indices: e2 = 52, e5 = 28. A pawn cannot move three squares.
    await tester.tap(squares.at(52));
    await tester.pump();
    await tester.tap(squares.at(28));
    await tester.pumpAndSettle();
    expect(find.text('النقلات: 0'), findsOneWidget);
    expect(find.text('دورك — الأبيض'), findsOneWidget);

    // e2-e4 is legal. The computer must answer, returning the turn to White.
    await tester.tap(squares.at(52));
    await tester.pump();
    await tester.tap(squares.at(36));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('النقلات: 2'), findsOneWidget);
    expect(find.text('دورك — الأبيض'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snake starts, pauses, resumes and resets without exceptions', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SnakeGamePage(lang: 'ar')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ابدأ اللعب'));
    await tester.pump();
    expect(find.text('إيقاف مؤقت'), findsOneWidget);

    await tester.tap(find.text('إيقاف مؤقت'));
    await tester.pump();
    expect(find.text('اللعبة متوقفة مؤقتاً'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(find.text('ابدأ اللعب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tic-tac-toe computer blocks an immediate winning line', (tester) async {
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
    await tester.tap(cells.at(2));
    await tester.pumpAndSettle();

    expect(find.descendant(of: cells.at(1), matching: find.text('O')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snake ends on a wall collision and records the best score', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SnakeGamePage(lang: 'ar')));
    await tester.pumpAndSettle();

    // The snake starts at row 9; repeated upward turns must eventually hit row 0.
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();

    expect(find.text('انتهت اللعبة!'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('best_snake'), isNotNull);
    expect(tester.takeException(), isNull);
  });


  testWidgets('Pac-Man opens with maze, lives, score, rules and controls', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const NovaPlay());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await openGame(tester, 'باك مان');

    expect(find.text('PAC-MAN'), findsOneWidget);
    expect(find.text('الأرواح'), findsOneWidget);
    expect(find.text('ابدأ اللعب'), findsOneWidget);
    expect(find.textContaining('اجمع النقاط'), findsNWidgets(2));
    expect(find.byType(GridView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pac-Man starts, pauses and resets cleanly', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: PacManGamePage(lang: 'ar')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ابدأ اللعب'));
    await tester.pump();
    expect(find.text('إيقاف مؤقت'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('إيقاف مؤقت'));
    await tester.pump();
    expect(find.text('ابدأ اللعب'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(find.text('ابدأ اللعب'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pac-Man moves through the maze and awards pellet points', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: PacManGamePage(lang: 'ar')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_downward));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('10'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('إيقاف مؤقت'));
    await tester.pump();
  });

  testWidgets('Pac-Man supports French and English labels', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: PacManGamePage(lang: 'fr')));
    await tester.pumpAndSettle();
    expect(find.text('Démarrer'), findsOneWidget);
    expect(find.text('Vies'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: PacManGamePage(lang: 'en')));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Lives'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Velocity Runner opens with HUD and touch controls', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SonicRunnerPage(lang: 'ar')));
    await tester.pumpAndSettle();
    expect(find.text('VELOCITY RUNNER'), findsOneWidget);
    expect(find.text('الحلقات'), findsOneWidget);
    expect(find.text('الأرواح'), findsOneWidget);
    expect(find.text('ابدأ اللعب'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Velocity Runner starts, pauses and resets without exceptions', (tester) async {
    configurePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SonicRunnerPage(lang: 'ar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ابدأ اللعب'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.pause), findsOneWidget);
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    expect(find.text('مستعد للانطلاق؟'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(find.text('مستعد للانطلاق؟'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}