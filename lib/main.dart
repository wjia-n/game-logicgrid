import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const LogicGridApp());

class LogicGridApp extends StatelessWidget {
  const LogicGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Logic Grid',
      tagline: 'Solve Einstein-style logic grid puzzles',
      emoji: '🕵️',
      slug: 'logicgrid',
      howToPlay:
          '• Read the clues and crack each logic puzzle!\n• Tap a cell to cycle: blank → ❌ (no) → ✅ (yes).\n• Marking ✅ auto-fills the rest of that row with ❌.\n• Every value belongs to exactly one house. Solve all three puzzles!',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          LogicGridScreen(players: players, callbacks: cb),
    );
  }
}
