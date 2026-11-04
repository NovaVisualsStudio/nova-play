import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _maze = <String>[
  '###############',
  '#.............#',
  '#.###.###.###.#',
  '#o#...#.#...#o#',
  '#.#.#.#.#.#.#.#',
  '#...#...#...#.#',
  '###.###.###.#.#',
  '#...#...#...#.#',
  '#.###.#.###.#.#',
  '#.....#.....#.#',
  '#.###.###.###.#',
  '#...#...#...#.#',
  '#.#.#.#.#.#.#.#',
  '#o#...#.#...#o#',
  '#.###.###.###.#',
  '#.............#',
  '###############',
];

enum _Move { up, down, left, right }

class _Ghost {
  int cell;
  final Color color;
  int release;
  _Move direction = _Move.left;
  _Ghost(this.cell, this.color, this.release);
}

class PacManGamePage extends StatefulWidget {
  final String lang;
  const PacManGamePage({super.key, required this.lang});

  @override
  State<PacManGamePage> createState() => _PacManGamePageState();
}

class _PacManGamePageState extends State<PacManGamePage> {
  static const int _w = 15;
  static const int _h = 17;
  static const int _playerHomeCell = _w + 1;
  static const int _ghostStart = 7 * _w + 7;
  final List<int> _pellets = <int>[];
  final List<int> _power = <int>[];
  final List<_Ghost> _ghosts = <_Ghost>[];
  Timer? _timer;
  int _player = _playerHomeCell;
  _Move _direction = _Move.left;
  _Move? _queued;
  int _score = 0;
  int _best = 0;
  int _lives = 3;
  int _level = 1;
  int _tick = 0;
  int _frightened = 0;
  int _ghostChain = 0;
  bool _started = false;
  bool _paused = false;
  bool _over = false;
  bool _won = false;

  String _t(String ar, String fr, String en) =>
      widget.lang == 'ar' ? ar : widget.lang == 'fr' ? fr : en;

  @override
  void initState() {
    super.initState();
    _loadBest();
    _resetBoard();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _best = prefs.getInt('best_pacman') ?? 0);
  }

  int _index(int x, int y) => y * _w + x;
  int _x(int cell) => cell % _w;
  int _y(int cell) => cell ~/ _w;

  bool _wall(int cell) {
    if (cell < 0 || cell >= _w * _h) return true;
    return _maze[_y(cell)][_x(cell)] == '#';
  }

  int? _step(int cell, _Move move) {
    final x = _x(cell), y = _y(cell);
    final nx = x + (move == _Move.left ? -1 : move == _Move.right ? 1 : 0);
    final ny = y + (move == _Move.up ? -1 : move == _Move.down ? 1 : 0);
    if (nx < 0 || nx >= _w || ny < 0 || ny >= _h) return null;
    final next = _index(nx, ny);
    return _wall(next) ? null : next;
  }

  List<_Move> get _moves => _Move.values;

  void _resetBoard({bool full = false}) {
    _timer?.cancel();
    _pellets.clear();
    _power.clear();
    for (var y = 0; y < _h; y++) {
      for (var x = 0; x < _w; x++) {
        final cell = _index(x, y);
        if (_maze[y][x] == '.') _pellets.add(cell);
        if (_maze[y][x] == 'o') _power.add(cell);
      }
    }
    _player = _playerHomeCell;
    _direction = _Move.left;
    _queued = null;
    _ghosts
      ..clear()
      ..addAll([
        _Ghost(_ghostStart, const Color(0xFFFF526B), 0),
        _Ghost(_ghostStart - 1, const Color(0xFFFF9BE7), 3),
        _Ghost(_ghostStart + 1, const Color(0xFF36D8E8), 6),
        _Ghost(_ghostStart + _w, const Color(0xFFFFA43A), 9),
      ]);
    _tick = 0;
    _frightened = 0;
    _ghostChain = 0;
    if (full) {
      _score = 0;
      _lives = 3;
      _level = 1;
      _started = false;
      _paused = false;
      _over = false;
      _won = false;
    }
  }

  void _start() {
    if (_over) {
      _resetBoard(full: true);
    }
    setState(() {
      _started = true;
      _paused = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: max(95, 175 - (_level - 1) * 10)), (_) => _tickGame());
  }

  void _pause() {
    if (!_started || _over) return;
    _timer?.cancel();
    setState(() {
      _paused = true;
      _started = false;
    });
  }

  void _reset() {
    setState(() => _resetBoard(full: true));
  }

  void _queue(_Move move) {
    if (_over) return;
    setState(() => _queued = move);
    if (!_started && !_paused) _start();
  }

  void _tickGame() {
    if (!mounted || !_started || _paused || _over) return;
    setState(() {
      _tick++;
      if (_queued != null && _step(_player, _queued!) != null) {
        _direction = _queued!;
        _queued = null;
      }
      final next = _step(_player, _direction);
      if (next != null) _player = next;
      if (_pellets.remove(_player)) _score += 10;
      if (_power.remove(_player)) {
        _score += 50;
        _frightened = 40;
        _ghostChain = 0;
      }
      if (_frightened > 0) _frightened--;
      if (_tick.isEven) {
        for (final ghost in _ghosts) {
          if (ghost.release > 0) {
            ghost.release--;
            continue;
          }
          _moveGhost(ghost);
        }
      }
      _checkCollision();
      if (!_over && _pellets.isEmpty && _power.isEmpty) {
        _level++;
        _resetBoard();
        _started = true;
        _timer?.cancel();
        _timer = Timer.periodic(Duration(milliseconds: max(95, 175 - (_level - 1) * 10)), (_) => _tickGame());
      }
    });
  }

  int _pathDistance(int start, int target) {
    if (start == target) return 0;
    final distances = List<int>.filled(_w * _h, -1);
    final queue = <int>[start];
    distances[start] = 0;
    var cursor = 0;
    while (cursor < queue.length) {
      final cell = queue[cursor++];
      for (final move in _moves) {
        final next = _step(cell, move);
        if (next == null || distances[next] != -1) continue;
        distances[next] = distances[cell] + 1;
        if (next == target) return distances[next];
        queue.add(next);
      }
    }
    return _w * _h;
  }

  void _moveGhost(_Ghost ghost) {
    final options = _moves
        .map((move) => (move: move, cell: _step(ghost.cell, move)))
        .where((option) => option.cell != null)
        .toList();
    if (options.isEmpty) return;
    final ranked = options.map((option) => (
      move: option.move,
      cell: option.cell!,
      distance: _pathDistance(option.cell!, _player),
    )).toList();
    ranked.sort((a, b) => _frightened > 0
        ? b.distance.compareTo(a.distance)
        : a.distance.compareTo(b.distance));
    final bestDistance = ranked.first.distance;
    final tied = ranked.where((option) => option.distance == bestDistance).toList();
    final chosen = tied[_tick % tied.length];
    ghost.cell = chosen.cell;
    ghost.direction = chosen.move;
  }

  void _checkCollision() {
    for (final ghost in _ghosts) {
      if (ghost.cell != _player) continue;
      if (_frightened > 0) {
        _score += 200 * (1 << min(_ghostChain, 3));
        _ghostChain++;
        ghost.cell = _ghostStart;
        ghost.release = 5;
      } else {
        _lives--;
        if (_lives <= 0) {
          _finish(false);
        } else {
          _player = _playerHomeCell;
          _direction = _Move.left;
          _queued = null;
          for (var i = 0; i < _ghosts.length; i++) {
            _ghosts[i].cell = _ghostStart + (i == 1 ? -1 : i == 2 ? 1 : i == 3 ? _w : 0);
            _ghosts[i].release = i * 3;
          }
        }
        break;
      }
    }
  }

  Future<void> _finish(bool won) async {
    _over = true;
    _won = won;
    _started = false;
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    if (_score > (prefs.getInt('best_pacman') ?? 0)) {
      await prefs.setInt('best_pacman', _score);
    }
    if (_score > (prefs.getInt('best') ?? 0)) {
      await prefs.setInt('best', _score);
    }
    if (!mounted) return;
    setState(() => _best = max(_best, _score));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _stat(String label, String value, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF151C31),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF36D8E8).withOpacity(.18)),
          ),
          child: Column(children: [
            Icon(icon, color: const Color(0xFFFFC857), size: 17),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  Widget _cell(int cell) {
    final matchingGhosts = _ghosts.where((g) => g.cell == cell && g.release == 0).toList();
    final ghost = matchingGhosts.isEmpty ? null : matchingGhosts.first;
    final isPlayer = cell == _player;
    final isPower = _power.contains(cell);
    final isPellet = _pellets.contains(cell);
    final wall = _wall(cell);
    return Container(
      margin: const EdgeInsets.all(.5),
      decoration: BoxDecoration(
        color: wall ? const Color(0xFF142B70) : const Color(0xFF070B18),
        borderRadius: BorderRadius.circular(wall ? 3 : 1),
        border: wall ? Border.all(color: const Color(0xFF315BEA), width: .7) : null,
      ),
      child: Center(
        child: isPlayer
            ? Transform.rotate(
                angle: _direction == _Move.left ? pi : _direction == _Move.up ? -pi / 2 : _direction == _Move.down ? pi / 2 : 0,
                child: const Icon(Icons.circle, color: Color(0xFFFFD84D), size: 17),
              )
            : ghost != null
                ? Text(_frightened > 0 ? '👻' : '👾', style: TextStyle(fontSize: 14, color: ghost.color))
                : isPower
                    ? const Icon(Icons.circle, color: Colors.white, size: 7)
                    : isPellet
                        ? Container(width: 3, height: 3, decoration: const BoxDecoration(color: Color(0xFFFFE8A3), shape: BoxShape.circle))
                        : null,
      ),
    );
  }

  Widget _arrow(IconData icon, _Move move) => SizedBox(
        width: 48,
        height: 42,
        child: IconButton.filledTonal(
          padding: EdgeInsets.zero,
          onPressed: () => _queue(move),
          icon: Icon(icon, size: 20),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final boardWidth = min(MediaQuery.of(context).size.width - 32, 420.0);
    return Directionality(
      textDirection: widget.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PAC-MAN'),
          actions: [
            IconButton(
              tooltip: _t('إعادة', 'Réinitialiser', 'Reset'),
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            child: Column(
              children: [
                Row(children: [
                  _stat(_t('النقاط', 'Score', 'Score'), '$_score', Icons.stars_rounded),
                  const SizedBox(width: 6),
                  _stat(_t('الأفضل', 'Record', 'Best'), '$_best', Icons.emoji_events_rounded),
                  const SizedBox(width: 6),
                  _stat(_t('الأرواح', 'Vies', 'Lives'), '$_lives', Icons.favorite_rounded),
                  const SizedBox(width: 6),
                  _stat(_t('المرحلة', 'Niveau', 'Level'), '$_level', Icons.flag_rounded),
                ]),
                const SizedBox(height: 12),
                Container(
                  width: boardWidth,
                  height: boardWidth * _h / _w,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF36D8E8), width: 1.4),
                    boxShadow: const [BoxShadow(color: Color(0x4436D8E8), blurRadius: 18)],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _w * _h,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _w),
                    itemBuilder: (_, i) => _cell(i),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _over
                      ? (_won ? _t('فزت! أحسنت', 'Gagné ! Bravo', 'You won!') : _t('انتهت اللعبة', 'Partie terminée', 'Game over'))
                      : _frightened > 0
                          ? _t('الأشباح خائفة! التهمها', 'Fantômes effrayés ! Mangez-les', 'Ghosts are frightened! Eat them')
                          : _t('اجمع النقاط وتجنب الأشباح', 'Mangez les points et évitez les fantômes', 'Collect dots and avoid ghosts'),
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _arrow(Icons.arrow_back, _Move.left),
                  const SizedBox(width: 8),
                  Column(children: [
                    _arrow(Icons.arrow_upward, _Move.up),
                    const SizedBox(height: 4),
                    _arrow(Icons.arrow_downward, _Move.down),
                  ]),