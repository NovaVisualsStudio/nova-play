import 'dart:math';
import 'package:flutter/material.dart';
import 'game_artwork.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chess_on_dart/chess_on_dart.dart' as chess;

class ChessGamePage extends StatefulWidget {
  final String lang;
  const ChessGamePage({super.key, required this.lang});
  @override
  State<ChessGamePage> createState() => _ChessGamePageState();
}

class _ChessGamePageState extends State<ChessGamePage> {
  chess.Game game = chess.Game();
  final Random random = Random();
  final List<chess.Move> history = [];
  int difficulty = 2;
  int? selected;
  int coins = 0;
  bool thinking = false;
  int _gameEpoch = 0;
  static const values = <int, int>{1: 100, 2: 320, 3: 335, 4: 500, 5: 900, 6: 20000};

  String t(String ar, String fr, String en) => widget.lang == 'ar' ? ar : widget.lang == 'fr' ? fr : en;
  bool get whiteTurn => game.turn == chess.whiteColor;
  chess.Piece pieceAt(int i) => game.squares[i];

  String glyph(chess.Piece p) {
    if (p == chess.Piece.empty) return '';
    final r = p.toRune().toUpperCase();
    const w = <String,String>{'K':'♔','Q':'♕','R':'♖','B':'♗','N':'♘','P':'♙'};
    const b = <String,String>{'K':'♚','Q':'♛','R':'♜','B':'♝','N':'♞','P':'♟'};
    return p.isWhite ? w[r]! : b[r]!;
  }

  String get gameStatus {
    if (game.isCheckmate) return t('كش مات — انتهت المباراة','Échec et mat — partie terminée','Checkmate — game over');
    if (game.isStalemate) return t('تعادل — جمود','Nulle — pat','Draw — stalemate');
    if (game.isMaterialDraw || game.isThreefoldRepetition || game.isFiftyMoveRule || game.isSeventyFiveMoveRule) return t('تعادل حسب القواعد','Nulle selon les règles','Draw by chess rules');
    if (game.isCheck) return t('كش!','Échec !','Check!');
    return whiteTurn ? t('دورك — الأبيض','À vous — Blancs','Your turn — White') : t('دور الكمبيوتر','Tour de l’ordinateur','Computer turn');
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() { coins = p.getInt('nova_coins') ?? 0; });
  }

  void _tapSquare(int index) {
    if (thinking || game.isFinished || !whiteTurn) return;
    final p = pieceAt(index);
    if (selected == null) {
      if (p != chess.Piece.empty && p.isWhite) setState(() { selected = index; });
      return;
    }
    if (selected == index) { setState(() { selected = null; }); return; }
    if (p != chess.Piece.empty && p.isWhite) { setState(() { selected = index; }); return; }
    final choices = game.legalMoves.where((m) => m.from().value == selected && m.to().value == index).toList();
    if (choices.isEmpty) { setState(() { selected = null; }); return; }
    final move = choices.firstWhere((m) => m.promotionTo() == chess.typeQueen, orElse: () => choices.first);
    _makePlayerMove(move);
  }

  void _makePlayerMove(chess.Move move) {
    game.tryMove(move);
    history.add(move);
    setState(() { selected = null; });
    if (game.isFinished) { _showResult(); return; }
    _computerMove();
  }

  Future<void> _computerMove() async {
    if (!mounted || game.isFinished) return;
    final epoch = _gameEpoch;
    setState(() { thinking = true; });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted || epoch != _gameEpoch || game.isFinished) return;
    final moves = List<chess.Move>.of(game.legalMoves)..shuffle(random);
    chess.Move? bestMove;
    var bestScore = -1000000;
    for (final move in moves) {
      game.makeMoveFast(move);
      final score = -_search(difficulty - 1, -1000000, 1000000, 1);
      game.undoMoveFast(move);
      if (score > bestScore) { bestScore = score; bestMove = move; }
    }
    if (!mounted) return;
    setState(() { thinking = false; });
    if (bestMove != null) {
      game.tryMove(bestMove);
      history.add(bestMove);
      setState(() {});
      if (game.isFinished) _showResult();
    }
  }

  int _search(int depth, int alpha, int beta, int ply) {
    final moves = List<chess.Move>.of(game.legalMoves);
    if (moves.isEmpty) return game.isCheck ? -100000 + ply : 0;
    if (depth <= 0) return _evaluate();
    moves.sort((a,b) => _order(b).compareTo(_order(a)));
    var best = -1000000;
    for (final move in moves) {
      game.makeMoveFast(move);
      final score = -_search(depth - 1, -beta, -alpha, ply + 1);
      game.undoMoveFast(move);
      if (score > best) best = score;
      if (score > alpha) alpha = score;
      if (alpha >= beta) break;
    }
    return best;
  }

  int _order(chess.Move m) {
    final captured = values[pieceAt(m.to().value).kind()] ?? 0;
    final moving = values[pieceAt(m.from().value).kind()] ?? 0;
    return captured * 10 - moving;
  }

  int _evaluate() {
    var score = 0;
    for (var i = 0; i < 64; i++) {
      final p = pieceAt(i);
      if (p == chess.Piece.empty) continue;
      final material = values[p.kind()] ?? 0;
      final row = i ~/ 8;
      final col = i % 8;
      final center = 7 - ((col - 3.5).abs() + (row - 3.5).abs()).round();
      final positional = p.kind() == chess.typePawn ? (p.isWhite ? 6 - row : row - 1) * 5 : center * 3;
      score += (p.isWhite ? 1 : -1) * (material + positional);
    }
    return whiteTurn ? score : -score;
  }

  Future<void> _showResult() async {
    final playerWon = game.winner == chess.whiteColor;
    final reward = playerWon ? 35 : 0;
    if (reward > 0) {
      final p = await SharedPreferences.getInstance();
      coins = (p.getInt('nova_coins') ?? 0) + reward;
      await p.setInt('nova_coins', coins);
    }
    if (!mounted) return;
    showDialog<void>(context: context, barrierDismissible: false, builder: (d) => AlertDialog(
      backgroundColor: const Color(0xFF151C31),
      title: Text(playerWon ? t('فزت على الكمبيوتر!','Vous avez gagné !','You beat the computer!') : game.winner == chess.blackColor ? t('فاز الكمبيوتر','L’ordinateur a gagné','Computer wins') : t('تعادل','Égalité','Draw')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.emoji_events, size: 58, color: Color(0xFFFFC857)),
        if (reward > 0) Text('+' + reward.toString() + ' 🪙'),
        Text(t('رصيدك: ','Solde : ','Balance: ') + coins.toString()),
      ]),
      actions: [TextButton(onPressed: () { Navigator.pop(d); _newGame(); }, child: Text(t('مباراة جديدة','Nouvelle partie','New game')))],
    ));
  }

  void _newGame() {
    _gameEpoch++;
    setState(() { game = chess.Game(); history.clear(); selected = null; thinking = false; });
  }

  void _undo() {
    if (thinking || history.isEmpty || game.isFinished) return;
    game.undoMove(history.removeLast());
    if (history.isNotEmpty && !whiteTurn) game.undoMove(history.removeLast());
    setState(() { selected = null; });
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: widget.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      backgroundColor: const Color(0xFF090D1B),
      appBar: AppBar(title: Row(mainAxisSize: MainAxisSize.min, children: [GameArtwork(gameId: 'chess', width: 42), const SizedBox(width: 9), Text(t('الشطرنج','Échecs','Chess'))]), actions: [
        IconButton(onPressed: _undo, icon: const Icon(Icons.undo), tooltip: t('تراجع','Annuler','Undo')),
        IconButton(onPressed: _newGame, icon: const Icon(Icons.refresh), tooltip: t('مباراة جديدة','Nouvelle partie','New game')),
      ]),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(14,8,14,8), child: Row(children: [
          Expanded(child: Text(gameStatus, style: TextStyle(fontWeight: FontWeight.w800, color: game.isCheck ? const Color(0xFFFF648D) : Colors.white))),
          PopupMenuButton<int>(
            initialValue: difficulty,
            onSelected: (v) => setState(() { difficulty = v; }),
            itemBuilder: (_) => [
              PopupMenuItem(value:1,child:Text(t('سهل','Facile','Easy'))),
              PopupMenuItem(value:2,child:Text(t('متوسط','Moyen','Medium'))),
              PopupMenuItem(value:3,child:Text(t('صعب','Difficile','Hard'))),
            ],
            child: Chip(avatar: const Icon(Icons.smart_toy_outlined,size:16), label: Text(difficulty == 1 ? t('سهل','Facile','Easy') : difficulty == 2 ? t('متوسط','Moyen','Medium') : t('صعب','Difficile','Hard'))),
          ),
        ])),
        Expanded(child: Center(child: AspectRatio(aspectRatio:1, child: Padding(padding: const EdgeInsets.all(10), child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 64,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:8),
          itemBuilder: (context,index) {
            final p = pieceAt(index);
            final isSelected = selected == index;
            final isTarget = selected != null && game.legalMoves.any((m) => m.from().value == selected && m.to().value == index);
            final light = ((index ~/ 8) + (index % 8)).isEven;
            return GestureDetector(
              onTap: () => _tapSquare(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds:120),
                decoration: BoxDecoration(color: isSelected ? const Color(0xFFB6C96B) : isTarget ? const Color(0xFFB5C58A) : light ? const Color(0xFFE8DCC5) : const Color(0xFF71865F)),
                child: Stack(alignment:Alignment.center, children: [
                  if (isTarget && p == chess.Piece.empty) Container(width:12,height:12,decoration:BoxDecoration(color:Colors.black.withOpacity(.25),shape:BoxShape.circle)),
                  if (isTarget && p != chess.Piece.empty) Container(decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:const Color(0xFFDA5B54),width:3))),
                  Text(glyph(p),style:TextStyle(fontSize:MediaQuery.of(context).size.width/13,color:p.isWhite?const Color(0xFFFDFBF5):const Color(0xFF151923),shadows:[Shadow(color:p.isWhite?Colors.black54:Colors.white24,blurRadius:2,offset:const Offset(1,2))])),
                  if (index % 8 == 0) Positioned(left:2,top:1,child:Text((8-index~/8).toString(),style:TextStyle(fontSize:8,color:light?Colors.black45:Colors.white60))),
                  if (index >= 56) Positioned(right:2,bottom:0,child:Text(String.fromCharCode(97+index%8),style:TextStyle(fontSize:8,color:light?Colors.black45:Colors.white60))),
                ]),
              ),
            );
          },
        ))))),
        Padding(padding: const EdgeInsets.fromLTRB(16,8,16,16), child: Column(children: [
          Row(children: [
            const Icon(Icons.tips_and_updates_outlined,color:Color(0xFFFFC857),size:18),
            const SizedBox(width:8),
            Expanded(child:Text(t('اختر القطعة ثم وجهتها. المحرك يمنع الحركات غير القانونية ويطبق قواعد الشطرنج.','Choisissez une pièce puis sa destination. Le moteur applique les règles officielles.','Select a piece and its destination. The rules engine rejects illegal moves.'),style:const TextStyle(fontSize:11,color:Colors.white60))),
          ]),
          const SizedBox(height:8),
          Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
            Text(t('النقلات: ','Coups : ','Moves: ') + history.length.toString(),style:const TextStyle(color:Colors.white70)),
            Text('🪙 ' + coins.toString(),style:const TextStyle(color:Color(0xFFFFC857))),
          ]),
        ])),
      ])),
    ),
  );
}
