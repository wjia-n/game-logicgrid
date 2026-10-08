import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

class _Puzzle {
  final String name;
  final String diff;
  final List<String> cats;
  final List<List<String>> values;
  final List<String> clues;
  final List<List<int>> sol; // sol[cat][value] = house
  const _Puzzle(this.name, this.diff, this.cats, this.values, this.clues, this.sol);
}

const _puzzles = [
  _Puzzle(
    'Cozy Cottages',
    'Easy · 3 houses',
    ['Color', 'Pet', 'Drink'],
    [
      ['Red', 'Green', 'Blue'],
      ['Cat', 'Dog', 'Bird'],
      ['Tea', 'Coffee', 'Juice'],
    ],
    [
      '1. The first house is red.',
      '2. The dog lives in the green house.',
      '3. The bird drinks juice.',
      '4. The cat drinks tea.',
      '5. Coffee is drunk in the second house.',
      '6. The third house is blue.',
      '7. The cat lives in the first house.',
    ],
    [
      [0, 1, 2],
      [0, 1, 2],
      [0, 1, 2],
    ],
  ),
  _Puzzle(
    'Maple Street',
    'Medium · 4 houses',
    ['Color', 'Pet', 'Drink', 'Snack'],
    [
      ['Red', 'Green', 'Blue', 'Yellow'],
      ['Cat', 'Dog', 'Bird', 'Fish'],
      ['Tea', 'Coffee', 'Juice', 'Milk'],
      ['Cake', 'Pie', 'Cookie', 'Candy'],
    ],
    [
      '1. The first house is red.',
      '2. The cat lives in the first house.',
      '3. Tea is drunk in the red house.',
      '4. Cake is eaten in the first house.',
      '5. The dog lives in the green house.',
      '6. The green house drinks coffee.',
      '7. Pie is eaten in the green house.',
      '8. The bird drinks juice.',
      '9. Cookies are eaten in the blue house.',
      '10. The fourth house is yellow.',
      '11. The fish drinks milk.',
      '12. The fourth house eats candy.',
      '13. The green house is the second house.',
    ],
    [
      [0, 1, 2, 3],
      [0, 1, 2, 3],
      [0, 1, 2, 3],
      [0, 1, 2, 3],
    ],
  ),
  _Puzzle(
    'Einstein Avenue',
    'Hard · 5 houses',
    ['Color', 'Pet', 'Drink', 'Snack'],
    [
      ['Red', 'Green', 'Blue', 'Yellow', 'Purple'],
      ['Cat', 'Dog', 'Bird', 'Fish', 'Horse'],
      ['Tea', 'Coffee', 'Juice', 'Milk', 'Water'],
      ['Cake', 'Pie', 'Cookie', 'Candy', 'Chips'],
    ],
    [
      '1. The first house is red.',
      '2. The cat lives in the red house.',
      '3. Tea is drunk in the first house.',
      '4. Cake is eaten in the red house.',
      '5. The green house is the second house.',
      '6. The dog lives in the green house.',
      "7. The dog's owner drinks coffee.",
      '8. The bird drinks juice.',
      '9. The middle house is blue.',
      '10. Cookies are eaten in the blue house.',
      '11. The yellow house is the fourth house.',
      '12. The fish drinks milk.',
      '13. Candy is eaten in the fourth house.',
      '14. The purple house is the fifth house.',
      '15. The horse drinks water.',
      '16. Chips are eaten in the purple house.',
      '17. Pie is eaten in the green house.',
      '18. The bird lives in the middle house.',
      '19. The fish lives in the fourth house.',
    ],
    [
      [0, 1, 2, 3, 4],
      [0, 1, 2, 3, 4],
      [0, 1, 2, 3, 4],
      [0, 1, 2, 3, 4],
    ],
  ),
];

class LogicGridScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const LogicGridScreen({super.key, required this.players, required this.callbacks});

  @override
  State<LogicGridScreen> createState() => _LogicGridScreenState();
}

class _LogicGridScreenState extends State<LogicGridScreen> {
  int? puzzleIdx;
  late List<List<List<int>>> grid; // [cat][value][house] 0 blank 1 X 2 O
  int seconds = 0;
  int totalScore = 0;
  int solvedCount = 0;
  Timer? timer;
  bool over = false;
  bool showSolvedDialog = false;

  _Puzzle get pz => _puzzles[puzzleIdx!];
  int get nH => pz.values.first.length;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startPuzzle(int i) {
    final n = _puzzles[i].values.first.length;
    setState(() {
      puzzleIdx = i;
      grid = List.generate(
          _puzzles[i].cats.length,
          (c) => List.generate(
              _puzzles[i].values[c].length, (_) => List.filled(n, 0)));
      seconds = 0;
      showSolvedDialog = false;
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !over) setState(() => seconds++);
    });
    Sfx.click();
  }

  void _tap(int c, int v, int h) {
    if (over || showSolvedDialog) return;
    setState(() {
      final cur = grid[c][v][h];
      if (cur == 0) {
        grid[c][v][h] = 1;
        Sfx.tap();
      } else if (cur == 1) {
        grid[c][v][h] = 2;
        _propagate(c, v, h);
        Sfx.move();
      } else {
        grid[c][v][h] = 0;
        Sfx.tap();
      }
      _autoFill();
    });
    if (_solved()) _onSolved();
  }

  void _propagate(int c, int v, int h) {
    for (int h2 = 0; h2 < nH; h2++) {
      if (h2 != h && grid[c][v][h2] == 0) grid[c][v][h2] = 1;
    }
    for (int v2 = 0; v2 < pz.values[c].length; v2++) {
      if (v2 != v && grid[c][v2][h] == 0) grid[c][v2][h] = 1;
    }
  }

  void _autoFill() {
    bool changed = true;
    while (changed) {
      changed = false;
      for (int c = 0; c < pz.cats.length; c++) {
        for (int v = 0; v < pz.values[c].length; v++) {
          final row = grid[c][v];
          if (row.contains(2)) continue;
          final blanks =
              [for (int h = 0; h < nH; h++) if (row[h] == 0) h];
          if (blanks.length == 1) {
            final h = blanks.first;
            grid[c][v][h] = 2;
            _propagate(c, v, h);
            changed = true;
          }
        }
      }
    }
  }

  bool _solved() {
    for (int c = 0; c < pz.cats.length; c++) {
      for (int v = 0; v < pz.values[c].length; v++) {
        if (grid[c][v][pz.sol[c][v]] != 2) return false;
      }
    }
    return true;
  }

  int _correctCount() {
    int n = 0;
    for (int c = 0; c < pz.cats.length; c++) {
      for (int v = 0; v < pz.values[c].length; v++) {
        if (grid[c][v][pz.sol[c][v]] == 2) n++;
      }
    }
    return n;
  }

  int _totalCells() =>
      pz.cats.fold(0, (a, c) => a + pz.values[pz.cats.indexOf(c)].length);

  void _onSolved() {
    final gained = 1000 + (600 - seconds).clamp(0, 600) * 2;
    totalScore += gained;
    solvedCount++;
    Sfx.win();
    timer?.cancel();
    if (solvedCount >= _puzzles.length) {
      over = true;
      widget.players.first.score = totalScore;
      widget.callbacks.finish(
          headline: 'Master detective! 🕵️',
          subline: 'All 3 puzzles solved · score $totalScore');
    } else {
      setState(() => showSolvedDialog = true);
    }
  }

  void _reset() {
    setState(() {
      for (int c = 0; c < pz.cats.length; c++) {
        for (int v = 0; v < pz.values[c].length; v++) {
          for (int h = 0; h < nH; h++) {
            grid[c][v][h] = 0;
          }
        }
      }
    });
    Sfx.click();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    if (puzzleIdx == null) return _picker(theme);
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              _hud(theme),
              Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cluesCard(theme),
                  const SizedBox(height: 12),
                  for (int c = 0; c < pz.cats.length; c++) _catSection(theme, c),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      WajihaButton(
                          label: 'Check',
                          emoji: '🔍',
                          primary: false,
                          onTap: () {
                            final n = _correctCount();
                            final total = _totalCells();
                            Sfx.click();
                            showDialog(
                                context: context,
                                builder: (_) => WajihaDialog(
                                      title: n == total ? 'Perfect!' : 'Keep going!',
                                      emoji: n == total ? '🎉' : '🧐',
                                      children: [
                                        Text('$n of $total values placed correctly.',
                                            textAlign: TextAlign.center),
                                      ],
                                    ));
                          }),
                      WajihaButton(
                          label: 'Reset', emoji: '↺', primary: false, onTap: _reset),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      if (showSolvedDialog)
        Positioned.fill(child: _solvedOverlay(theme)),
    ],
    ),
  );
  }

  Widget _picker(GameTheme theme) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🕵️', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              Text('Pick your case, detective!',
                  style: TextStyle(
                      color: theme.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              for (int i = 0; i < _puzzles.length; i++)
                GestureDetector(
                  onTap: () => _startPuzzle(i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: theme.primary.withValues(alpha: 0.3))),
                    child: Row(children: [
                      Text(['🏡', '🏘️', '🌆'][i],
                          style: const TextStyle(fontSize: 34)),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_puzzles[i].name,
                                style: TextStyle(
                                    color: theme.text,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17)),
                            Text(_puzzles[i].diff,
                                style: TextStyle(
                                    color: theme.muted, fontSize: 13)),
                          ]),
                      const Spacer(),
                      const Text('▶️', style: TextStyle(fontSize: 22)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _hud(GameTheme theme) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          GestureDetector(
            onTap: () {
              timer?.cancel();
              setState(() => puzzleIdx = null);
            },
            child: Text('‹ Cases',
                style: TextStyle(
                    color: theme.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          const Spacer(),
          Text('⏱️ ${_fmt(seconds)}   ⭐ $totalScore',
              style:
                  TextStyle(color: theme.text, fontWeight: FontWeight.bold)),
        ]),
      );

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _cluesCard(GameTheme theme) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: theme.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📜 Clues — ${pz.name}',
                  style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
              const SizedBox(height: 6),
              for (final clue in pz.clues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(clue,
                      style: TextStyle(color: theme.text, fontSize: 13.5)),
                ),
            ]),
      );

  Widget _catSection(GameTheme theme, int c) {
    final vals = pz.values[c];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: theme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            SizedBox(
                width: 76,
                child: Text(pz.cats[c],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: theme.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 14))),
            for (int h = 0; h < nH; h++)
              Expanded(
                  child: Text('🏠${h + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: theme.muted,
                          fontWeight: FontWeight.bold,
                          fontSize: 12))),
          ]),
        ),
        for (int v = 0; v < vals.length; v++)
          Container(
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: theme.primary.withValues(alpha: 0.12)))),
            child: Row(children: [
              SizedBox(
                  width: 76,
                  child: Text(vals[v],
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.text, fontSize: 13))),
              for (int h = 0; h < nH; h++)
                Expanded(child: _cell(theme, c, v, h)),
            ]),
          ),
      ]),
    );
  }

  Widget _cell(GameTheme theme, int c, int v, int h) {
    final st = grid[c][v][h];
    return GestureDetector(
      onTap: () => _tap(c, v, h),
      child: Container(
        margin: const EdgeInsets.all(3),
        height: 34,
        decoration: BoxDecoration(
          color: st == 2
              ? const Color(0xFF4CAF50).withValues(alpha: 0.25)
              : st == 1
                  ? Colors.red.withValues(alpha: 0.08)
                  : theme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: st == 2
                  ? const Color(0xFF4CAF50)
                  : theme.primary.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(st == 2 ? '✅' : st == 1 ? '✖️' : '',
              style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }

  Widget _solvedOverlay(GameTheme theme) => Container(
        color: Colors.black54,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              Text('Case closed!',
                  style: TextStyle(
                      color: theme.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              Text('Score: $totalScore',
                  style: TextStyle(
                      color: theme.muted, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              WajihaButton(
                  label: 'Next case',
                  emoji: '🔎',
                  onTap: () => _startPuzzle(puzzleIdx! + 1)),
            ]),
          ),
        ),
      );
}
