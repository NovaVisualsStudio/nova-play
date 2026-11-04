import 'package:flutter/material.dart';

/// Eight individually addressable game illustrations cropped from the NOVA
/// PLAY 4 × 2 atlas. Every crop preserves the atlas tile's native 4:3 ratio.
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

  int get _index => gameIds.indexOf(gameId);

  @override
  Widget build(BuildContext context) {
    final index = _index;
    if (index < 0) {
      return SizedBox(
        width: width,
        height: height ?? width * .75,
        child: const Center(
          child: Icon(Icons.videogame_asset_rounded, color: Colors.white70),
        ),
      );
    }

    final column = index % 4;
    final row = index ~/ 4;
    final tileHeight = height ?? width * .75;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        height: tileHeight,
        child: ClipRect(
          child: Align(
            alignment: Alignment(
              column * (2 / 3) - 1,
              row == 0 ? -1 : 1,
            ),
            widthFactor: .25,
            heightFactor: .5,
            child: Image.asset(
              'assets/game_icons.webp',
              width: width * 4,
              height: tileHeight * 2,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF151C31),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.videogame_asset_rounded,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Large, responsive game art for the home catalogue.
class GameCover extends StatelessWidget {
  final String gameId;
  final BorderRadius borderRadius;

  const GameCover({
    super.key,
    required this.gameId,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GameArtwork(
              gameId: gameId,
              width: 640,
              height: 480,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x12050A18),
                    Color(0x44050A18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
