import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_artwork.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SnakeGamePage extends StatefulWidget {
  final String lang;
  const SnakeGamePage({super.key, required this.lang});
  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> with WidgetsBindingObserver {
  static const n = 18;
  final rng = Random();
  final snake = <Point<int>>[const Point(8, 9), const Point(7, 9), const Point(6, 9)];
  Point<int> food = const Point(12, 9), dir = const Point(1, 0), nextDir = const Point(1, 0);
  Timer? timer;
  int score = 0, best = 0, stage = 1, coins = 0;
  bool started = false, paused = false, over = false, ending = false;
  int roundId = 0;
  String tr(String a, String f, String e) => widget.lang == 'ar' ? a : widget.lang == 'fr' ? f : e;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _load(); _food(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed || !started || paused || over) return;
    timer?.cancel();
    if (mounted) setState(() { started = false; paused = true; });
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { best = p.getInt('best_snake') ?? 0; stage = p.getInt('stage_snake') ?? 1; coins = p.getInt('nova_coins') ?? 0; });
  }
  bool _food() {
    final empty = <Point<int>>[];
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final cell = Point(x, y);
        if (!snake.contains(cell)) empty.add(cell);
      }
    }
    if (empty.isEmpty) return false;
    food = empty[rng.nextInt(empty.length)];
    return true;
  }
  int get speed => max(85, 190 - (score ~/ 3) * 8);
  void _start() {
    if (over) _reset();
    if (started && !paused) return;
    setState(() { started = true; paused = false; });
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: speed), (_) => _tick());
  }
  void _tick() {
    if (!mounted || paused || over || ending) return;
    final candidateDirection = nextDir;
    final head = snake.first + candidateDirection;
    final eating = head == food;
    final collisionBody = eating ? snake : snake.take(snake.length - 1);
    if (head.x < 0 || head.x >= n || head.y < 0 || head.y >= n || collisionBody.contains(head)) {
      _end();
      return;
    }
    var boardFilled = false;
    setState(() {
      dir = candidateDirection;
      snake.insert(0, head);
      if (eating) {
        score++;
        boardFilled = !_food();
      } else {
        snake.removeLast();
      }
    });
    if (boardFilled) {
      _end();
      return;
    }
    if (eating) {
      timer?.cancel();
      timer = Timer.periodic(Duration(milliseconds: speed), (_) => _tick());
    }
  }
  void _turn(Point<int> d) {
    if (d.x == -dir.x && d.y == -dir.y) return;
    HapticFeedback.selectionClick();
    nextDir = d;
    if (!started) _start();
  }
  Future<void> _end() async {
    if (ending || over) return;
    ending = true;
    final completedRound = roundId;
    timer?.cancel();
    if (mounted) setState(() { over = true; started = false; paused = false; });
    final p = await SharedPreferences.getInstance();
    best = max(best, score);
    await p.setInt('best_snake', best);
    if (score > (p.getInt('best') ?? 0)) await p.setInt('best', score);
    final passed = score >= max(3, stage * 2);
    final reward = passed ? 25 + stage * 5 : 0;
    if (passed) {
      stage = min(10, stage + 1);
      coins = (p.getInt('nova_coins') ?? 0) + reward;
      await p.setInt('stage_snake', stage);
      await p.setInt('nova_coins', coins);
    }
    if (!mounted || completedRound != roundId) return;
    showDialog<void>(context: context, barrierDismissible: false, builder: (d) => AlertDialog(
      backgroundColor: const Color(0xFF151C31),
      title: Text(tr('انتهت اللعبة!', 'Partie terminée !', 'Game over!')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC857), size: 58),
        Text(tr('النقاط: ', 'Score : ', 'Score: ') + score.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Text(tr('أفضل نتيجة: ', 'Record : ', 'Best: ') + best.toString()),
        if (passed) Text('+' + reward.toString() + ' 🪙', style: const TextStyle(color: Color(0xFFFFC857))),
      ]),
      actions: [TextButton(onPressed: () { Navigator.pop(d); _reset(); }, child: Text(tr('العب مجدداً', 'Rejouer', 'Play again')))],
    ));
  }
  void _reset() {
    roundId++;
    timer?.cancel();
    setState(() {
      snake..clear()..addAll([const Point(8, 9), const Point(7, 9), const Point(6, 9)]);
      dir = const Point(1, 0); nextDir = dir; score = 0; started = false; paused = false; over = false; ending = false; _food();
    });
  }
  void _pause() {
    if ((!started && !paused) || over) return;
    setState(() { paused = !paused; started = !paused; });
    if (paused) {
      timer?.cancel();
    } else {
      timer = Timer.periodic(Duration(milliseconds: speed), (_) => _tick());
    }
  }
  Widget _stat(String label, String value, IconData icon) => Expanded(child: Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF30245F), Color(0xFF151C31)]), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFF8B6CFF).withOpacity(.4)), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))]),
    child: Column(children: [Icon(icon, color: const Color(0xFFFFC857), size: 17), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60))]),
  ));
  Widget _arrow(IconData icon, Point<int> d) => SizedBox(width: 58, height: 46, child: FilledButton(
    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF30245F), elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    onPressed: () => _turn(d), child: Icon(icon),
  ));
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: widget.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      backgroundColor: const Color(0xFF090D1B),
      appBar: AppBar(title: Row(mainAxisSize: MainAxisSize.max, children: [Hero(tag: 'nova-art-snake', child: GameArtwork(gameId: 'snake', width: 42)), const SizedBox(width: 9), Expanded(child: Text(tr('لعبة الأفعى', 'Jeu du serpent', 'Snake'), maxLines: 1, overflow: TextOverflow.ellipsis))]), actions: [
        IconButton(onPressed: _pause, icon: Icon(paused ? Icons.play_arrow : Icons.pause)),
        IconButton(onPressed: _reset, icon: const Icon(Icons.refresh)),
      ]),
      body: SafeArea(child: LayoutBuilder(builder: (context, c) {
        final side = min(c.maxWidth - 32, c.maxHeight * .56);
        return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
          Row(children: [
            _stat(tr('النقاط', 'Score', 'Score'), score.toString(), Icons.stars_rounded),
            const SizedBox(width: 7),
            _stat(tr('الأفضل', 'Record', 'Best'), best.toString(), Icons.emoji_events_rounded),
            const SizedBox(width: 7),
            _stat(tr('المرحلة', 'Niveau', 'Stage'), stage.toString() + '/10', Icons.military_tech_rounded),
          ]),
          const SizedBox(height: 14),
          GestureDetector(
            onHorizontalDragUpdate: (d) { if (d.delta.dx.abs() > d.delta.dy.abs()) _turn(d.delta.dx < 0 ? const Point(-1, 0) : const Point(1, 0)); },
            onVerticalDragUpdate: (d) { if (d.delta.dy.abs() > d.delta.dx.abs()) _turn(d.delta.dy < 0 ? const Point(0, -1) : const Point(0, 1)); },
            child: Container(width: side, height: side, padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF29385A), Color(0xFF10182B), Color(0xFF070B16)]), borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFF36D8E8).withOpacity(.6), width: 1.5), boxShadow: const [BoxShadow(color: Color(0x4436D8E8), blurRadius: 22, offset: Offset(0, 10)), BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 8))]),
              child: GridView.builder(physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero, itemCount: n*n, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: n), itemBuilder: (_, i) {
                final p = Point(i % n, i ~/ n);
                final head = p == snake.first, body = snake.contains(p), isFood = p == food;
                final color = isFood ? const Color(0xFFFF648D) : const Color(0xFF36D8E8);
                return AnimatedContainer(duration: const Duration(milliseconds: 75), margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    gradient: body || isFood ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [head ? color : color.withOpacity(.9), color.withOpacity(.35)]) : null,
                    color: body || isFood ? null : const Color(0xFF10182B),
                    borderRadius: BorderRadius.circular(head ? 5 : 3),
                    border: Border.all(color: body || isFood ? color : Colors.white.withOpacity(.035)),
                    boxShadow: body || isFood ? [BoxShadow(color: color.withOpacity(.28), blurRadius: head ? 7 : 3, offset: const Offset(0, 2))] : null,
                  ),
                  child: isFood ? const Icon(Icons.circle, size: 8, color: Colors.white) : head ? const Icon(Icons.circle, size: 5, color: Colors.white) : null,
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Text(paused ? tr('اللعبة متوقفة مؤقتاً', 'En pause', 'Paused') : tr('اسحب على اللوحة أو استعمل الأزرار', 'Glissez ou utilisez les flèches', 'Swipe or use the arrows'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _arrow(Icons.arrow_back, const Point(-1, 0)),
            const SizedBox(width: 7),
            Column(children: [_arrow(Icons.arrow_upward, const Point(0, -1)), const SizedBox(height: 5), _arrow(Icons.arrow_downward, const Point(0, 1))]),
            const SizedBox(width: 7),
            _arrow(Icons.arrow_forward, const Point(1, 0)),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilledButton.icon(onPressed: started ? _pause : _start, icon: Icon(started ? Icons.pause : Icons.play_arrow), label: Text(started ? tr('إيقاف مؤقت', 'Pause', 'Pause') : tr('ابدأ اللعب', 'Démarrer', 'Start'))),
            const SizedBox(width: 9),
            OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.replay), label: Text(tr('إعادة', 'Réinitialiser', 'Reset'))),
          ]),
          const SizedBox(height: 8),
          Text(tr('القواعد: كُل الطعام لزيادة طول الأفعى والنقاط. الاصطدام بالجدار أو بجسمك ينهي الجولة.', 'Règles : mangez pour grandir et gagner des points. Toucher un mur ou votre corps termine la partie.', 'Rules: eat food to grow and score. Hitting a wall or your own body ends the round.'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]));
      })),
    ),
  );
}