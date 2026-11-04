import 'package:flutter/material.dart';

/// Lightweight, resolution-independent game artwork.
///
/// The illustrations are drawn by Flutter itself, so the app no longer
/// depends on a separately uploaded binary atlas asset.
class GameArtwork extends StatelessWidget {
  final String gameId;
  final double width;
  final double? height;

  const GameArtwork({
    super.key,
    required this.gameId,
    this.width = 52,
    this.height,
  });

  static const gameIds = <String>[
    'xo', 'memory', 'quick', 'quiz',
    'snake', 'chess', 'pacman', 'sonic',
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height ?? width * .75,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _GameVisual(gameId: gameId),
        ),
      );
}

/// Large responsive cover using the same vector artwork as the game tile.
class GameCover extends StatelessWidget {
  final String gameId;
  final BorderRadius borderRadius;

  const GameCover({
    super.key,
    required this.gameId,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: _GameVisual(gameId: gameId, large: true),
        ),
      );
}

class _GameVisual extends StatelessWidget {
  final String gameId;
  final bool large;

  const _GameVisual({required this.gameId, this.large = false});

  static const _icons = <String, IconData>{
    'xo': Icons.grid_3x3_rounded,
    'memory': Icons.psychology_alt_rounded,
    'quick': Icons.bolt_rounded,
    'quiz': Icons.quiz_rounded,
    'snake': Icons.route_rounded,
    'chess': Icons.workspace_premium_rounded,
    'pacman': Icons.circle,
    'sonic': Icons.speed_rounded,
  };

  static const _colors = <String, List<Color>>{
    'xo': [Color(0xFF153B66), Color(0xFF15172F)],
    'memory': [Color(0xFF563A91), Color(0xFF211B49)],
    'quick': [Color(0xFF9A4D16), Color(0xFF321B36)],
    'quiz': [Color(0xFF126B70), Color(0xFF172B4D)],
    'snake': [Color(0xFF236B45), Color(0xFF152D35)],
    'chess': [Color(0xFF75521F), Color(0xFF29213A)],
    'pacman': [Color(0xFF8B6514), Color(0xFF302044)],
    'sonic': [Color(0xFF145DA0), Color(0xFF172044)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _colors[gameId] ?? const [Color(0xFF273653), Color(0xFF151C31)];
    final icon = _icons[gameId] ?? Icons.videogame_asset_rounded;
    final iconSize = large ? 62.0 : 27.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
        CustomPaint(painter: _ArtworkPatternPainter(colors.last)),
        Center(
          child: Container(
            width: large ? 112 : 48,
            height: large ? 112 : 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .22),
                  blurRadius: large ? 24 : 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, size: iconSize, color: Colors.white),
          ),
        ),
        if (large)
          Positioned(
            left: 14,
            bottom: 12,
            child: Text(
              gameId.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
      ],
    );
  }
}

class _ArtworkPatternPainter extends CustomPainter {
  final Color color;
  const _ArtworkPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .055);
    canvas.drawCircle(Offset(size.width * .12, size.height * .18), size.width * .20, paint);
    canvas.drawCircle(Offset(size.width * .91, size.height * .82), size.width * .29, paint);
    final linePaint = Paint()
      ..color = color.withValues(alpha: .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = -2; i < 7; i++) {
      final x = i * size.width / 5;
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArtworkPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
