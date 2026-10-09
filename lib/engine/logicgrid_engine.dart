import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'puzzle.dart';

/// Turn phases owned entirely by the engine. The UI only renders.
/// [autoFilling]/[checking]/[hinting]/[revealing] are engine-driven animation
/// phases: input is locked and the engine steps a queue on its own timers.
/// A watchdog recovers any of these phases found without a live timer, so
/// stuck states are impossible by construction.
enum CasePhase {
  playing,
  autoFilling,
  checking,
  hinting,
  revealing,
  solved,
  failed,
}

enum GridEvent {
  markX,
  unmark,
  stamp,
  autoX,
  error,
  hint,
  checkTick,
  revealTick,
  caseStart,
  solved,
  revealed,
  failed,
  noHints,
  invalid,
}

/// One animated mark applied by the engine's step timer.
class _Mark {
  final int c, v, h;
  final int mark; // 1 = X, 2 = O
  _Mark(this.c, this.v, this.h, this.mark);
}

int _code(int c, int v, int h) => c * 10000 + v * 100 + h;

/// Engine: deterministic rules, puzzle state, animations, watchdog.
/// UI-agnostic — the screen renders and forwards taps.
class LogicGridEngine extends ChangeNotifier {
  final Puzzle puzzle;
  final int maxMistakes;
  final int hintBudget; // -1 = unlimited (Pro)

  late List<List<List<int>>> grid; // [cat][value][house]: 0 blank, 1 X, 2 O
  final Set<int> wrongMarks = {}; // encoded O cells that are wrong (red stamp)

  CasePhase phase = CasePhase.playing;
  String banner = 'Tap a cell to cycle: blank → ✕ → ✓';
  int mistakes = 0;
  int hintsUsed = 0;
  int elapsed = 0;
  int score = 0;
  bool revealed = false;

  /// Cell currently flashing during check / hint animation (-1 = none).
  int flashCell = -1;
  bool flashGood = true;

  final _rand = Random();
  Timer? _stepTimer; // single animation-step timer
  Timer? _clock; // elapsed-time ticker
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;

  final List<_Mark> _queue = [];
  void Function(GridEvent event)? onEvent;

  /// A hint whose glow-beat timer was cancelled by pause: resumed by the
  /// watchdog on un-pause so the hint is never silently lost.
  _Mark? _pendingHint;

  int get n => puzzle.houses;
  int get nc => puzzle.categories.length;
  int get hintsLeft => hintBudget < 0 ? 999 : (hintBudget - hintsUsed);
  bool get unlimitedHints => hintBudget < 0;
  bool get working =>
      phase == CasePhase.autoFilling ||
      phase == CasePhase.checking ||
      phase == CasePhase.hinting ||
      phase == CasePhase.revealing;
  bool get terminal =>
      phase == CasePhase.solved || phase == CasePhase.failed;

  LogicGridEngine({
    required this.puzzle,
    required this.maxMistakes,
    required this.hintBudget,
  }) {
    _resetGrid();
    banner = 'Crack the case, detective — ${puzzle.clues.length} clues await.';
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed && !paused && !terminal) {
        elapsed++;
        notifyListeners();
      }
    });
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _recover());
  }

  void _resetGrid() {
    grid = List.generate(
        nc, (c) => List.generate(n, (_) => List.filled(n, 0)));
    wrongMarks.clear();
    mistakes = 0;
    hintsUsed = 0;
    elapsed = 0;
    score = 0;
    revealed = false;
    flashCell = -1;
    _pendingHint = null;
    _queue.clear();
    phase = CasePhase.playing;
  }

  @override
  void dispose() {
    _disposed = true;
    _stepTimer?.cancel();
    _clock?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------ pause
  void setPaused(bool v) {
    if (paused == v || _disposed || terminal) return;
    paused = v;
    if (v) {
      _stepTimer?.cancel();
      _stepTimer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: a working phase with no live step timer (or an empty queue)
  /// is finished or resumed. Respects [paused].
  void _recover() {
    if (_disposed || paused || terminal || _stepTimer != null) return;
    if (!working) return;
    // A hint interrupted mid glow-beat resumes its stamp animation.
    if (phase == CasePhase.hinting && _pendingHint != null) {
      final h = _pendingHint;
      _pendingHint = null;
      _runClosure(
          [h!], CasePhase.hinting, const Duration(milliseconds: 110));
      return;
    }
    if (_queue.isEmpty) {
      _finishWorkingPhase();
    } else {
      _pumpQueue();
    }
  }

  void _armStep(Duration d) {
    if (_disposed || paused) return;
    _stepTimer?.cancel();
    _stepTimer = Timer(d, () {
      _stepTimer = null;
      if (!_disposed && !paused) _stepOne();
    });
  }

  // ------------------------------------------------------------ tapping
  /// Player taps a cell. Only legal in [CasePhase.playing]; anything else is
  /// an invalid interaction (gentle feedback, no state change).
  void tap(int c, int v, int h) {
    if (terminal) return;
    if (phase != CasePhase.playing) {
      onEvent?.call(GridEvent.invalid);
      return;
    }
    final cur = grid[c][v][h];
    if (cur == 0) {
      grid[c][v][h] = 1;
      onEvent?.call(GridEvent.markX);
      notifyListeners();
    } else if (cur == 1) {
      _placeO(c, v, h);
    } else {
      grid[c][v][h] = 0;
      wrongMarks.remove(_code(c, v, h));
      onEvent?.call(GridEvent.unmark);
      notifyListeners();
    }
  }

  bool _isCorrect(int c, int v, int h) => puzzle.solution[c][v] == h;

  /// Place an O (player-initiated). Correct => animated propagation closure.
  /// Wrong => mistake recorded; too many mistakes fails the case.
  void _placeO(int c, int v, int h) {
    if (_isCorrect(c, v, h)) {
      onEvent?.call(GridEvent.stamp);
      _runClosure([_Mark(c, v, h, 2)], CasePhase.autoFilling,
          const Duration(milliseconds: 110));
    } else {
      grid[c][v][h] = 2;
      wrongMarks.add(_code(c, v, h));
      mistakes++;
      onEvent?.call(GridEvent.error);
      if (mistakes >= maxMistakes) {
        phase = CasePhase.failed;
        banner = 'Too many wrong stamps — the trail went cold.';
        notifyListeners();
        onEvent?.call(GridEvent.failed);
      } else {
        banner =
            'That stamp is wrong! ${maxMistakes - mistakes} mistake${maxMistakes - mistakes == 1 ? '' : 's'} left.';
        notifyListeners();
      }
    }
  }

  /// Compute the full propagation closure of placing O marks (X exclusions
  /// along the row and column, plus naked-single deductions), in causal
  /// order. Applied to a scratch copy so the real grid stays consistent.
  List<_Mark> _closure(List<_Mark> seeds) {
    final scratch = [
      for (int c = 0; c < nc; c++)
        [for (int v = 0; v < n) List<int>.of(grid[c][v])]
    ];
    final marks = <_Mark>[];
    final pending = [...seeds];
    void setMark(int c, int v, int h, int m) {
      if (scratch[c][v][h] != 0) return;
      scratch[c][v][h] = m;
      marks.add(_Mark(c, v, h, m));
      if (m == 2) pending.add(_Mark(c, v, h, 2));
    }

    while (pending.isNotEmpty) {
      final s = pending.removeAt(0);
      if (s.mark == 2) {
        setMark(s.c, s.v, s.h, 2);
        // Exclusions: rest of the value row and the house column.
        for (int h2 = 0; h2 < n; h2++) {
          if (h2 != s.h) setMark(s.c, s.v, h2, 1);
        }
        for (int v2 = 0; v2 < n; v2++) {
          if (v2 != s.v) setMark(s.c, v2, s.h, 1);
        }
      }
    }
    // Naked singles: a row with no O and exactly one blank gets the O.
    bool changed = true;
    while (changed) {
      changed = false;
      for (int c = 0; c < nc; c++) {
        for (int v = 0; v < n; v++) {
          final row = scratch[c][v];
          if (row.contains(2)) continue;
          final blanks = [
            for (int h = 0; h < n; h++)
              if (row[h] == 0) h
          ];
          if (blanks.length == 1) {
            final h = blanks.first;
            scratch[c][v][h] = 2;
            marks.add(_Mark(c, v, h, 2));
            for (int h2 = 0; h2 < n; h2++) {
              if (h2 != h && scratch[c][v][h2] == 0) {
                scratch[c][v][h2] = 1;
                marks.add(_Mark(c, v, h2, 1));
              }
            }
            for (int v2 = 0; v2 < n; v2++) {
              if (v2 != v && scratch[c][v2][h] == 0) {
                scratch[c][v2][h] = 1;
                marks.add(_Mark(c, v2, h, 1));
              }
            }
            changed = true;
          }
        }
      }
    }
    return marks;
  }

  /// Run a closure with visible step-by-step animation.
  void _runClosure(List<_Mark> seeds, CasePhase p, Duration step) {
    final marks = _closure(seeds);
    if (marks.isEmpty) return;
    // Apply the first mark instantly, animate the rest.
    final first = marks.first;
    grid[first.c][first.v][first.h] = first.mark;
    _queue.addAll(marks.skip(1));
    _stepInterval = step;
    phase = p;
    flashCell = _code(first.c, first.v, first.h);
    flashGood = first.mark == 2;
    notifyListeners();
    if (_queue.isEmpty) {
      _finishWorkingPhase();
    } else {
      _armStep(step);
    }
  }

  Duration _stepInterval = const Duration(milliseconds: 110);

  void _pumpQueue() {
    if (_queue.isEmpty) {
      _finishWorkingPhase();
      return;
    }
    _armStep(_stepInterval);
  }

  void _stepOne() {
    if (!working || _queue.isEmpty) {
      _finishWorkingPhase();
      return;
    }
    final m = _queue.removeAt(0);
    grid[m.c][m.v][m.h] = m.mark;
    flashCell = _code(m.c, m.v, m.h);
    flashGood = m.mark == 2;
    onEvent?.call(phase == CasePhase.revealing
        ? GridEvent.revealTick
        : phase == CasePhase.checking
            ? GridEvent.checkTick
            : GridEvent.autoX);
    notifyListeners();
    if (_queue.isEmpty) {
      // Small beat so the last mark is seen before the phase settles.
      _stepTimer = Timer(const Duration(milliseconds: 260), () {
        _stepTimer = null;
        if (!_disposed && !paused) _finishWorkingPhase();
      });
    } else {
      _armStep(_stepInterval);
    }
  }

  void _finishWorkingPhase() {
    _stepTimer?.cancel();
    _stepTimer = null;
    flashCell = -1;
    switch (phase) {
      case CasePhase.autoFilling:
        phase = CasePhase.playing;
        banner = 'Nice deduction — keep going!';
        notifyListeners();
        _checkSolved();
      case CasePhase.checking:
        phase = CasePhase.playing;
        final got = _correctCount();
        final total = puzzle.totalCells;
        banner = got == total
            ? 'Every stamp checks out!'
            : '$got of $total values placed correctly — keep deducing!';
        notifyListeners();
        onEvent?.call(GridEvent.checkTick);
      case CasePhase.hinting:
        phase = CasePhase.playing;
        notifyListeners();
        _checkSolved();
      case CasePhase.revealing:
        revealed = true;
        phase = CasePhase.solved;
        banner = 'Case revealed — the full truth, no score this time.';
        notifyListeners();
        onEvent?.call(GridEvent.revealed);
      default:
        phase = CasePhase.playing;
        notifyListeners();
    }
  }

  // ------------------------------------------------------------------ check
  /// Animated check: every placed O flashes in sequence — never instant.
  void check() {
    if (phase != CasePhase.playing || terminal) {
      onEvent?.call(GridEvent.invalid);
      return;
    }
    final cells = <_Mark>[];
    for (int c = 0; c < nc; c++) {
      for (int v = 0; v < n; v++) {
        for (int h = 0; h < n; h++) {
          if (grid[c][v][h] == 2) cells.add(_Mark(c, v, h, 2));
        }
      }
    }
    if (cells.isEmpty) {
      banner = 'No stamps placed yet — mark your deductions first!';
      notifyListeners();
      onEvent?.call(GridEvent.invalid);
      return;
    }
    _queue.addAll(cells);
    _stepInterval = const Duration(milliseconds: 150);
    phase = CasePhase.checking;
    banner = 'Checking your stamps…';
    notifyListeners();
    _armStep(_stepInterval);
  }

  int _correctCount() {
    int got = 0;
    for (int c = 0; c < nc; c++) {
      for (int v = 0; v < n; v++) {
        if (grid[c][v][puzzle.solution[c][v]] == 2) got++;
      }
    }
    return got;
  }

  // ------------------------------------------------------------------- hint
  /// Reveal one true cell with a visible animation.
  void hint() {
    if (phase != CasePhase.playing || terminal) {
      onEvent?.call(GridEvent.invalid);
      return;
    }
    if (!unlimitedHints && hintsUsed >= hintBudget) {
      banner = 'Out of hints — PRO detectives get unlimited hints!';
      notifyListeners();
      onEvent?.call(GridEvent.noHints);
      return;
    }
    final open = <List<int>>[];
    for (int c = 0; c < nc; c++) {
      for (int v = 0; v < n; v++) {
        final h = puzzle.solution[c][v];
        if (grid[c][v][h] != 2) open.add([c, v, h]);
      }
    }
    if (open.isEmpty) {
      _checkSolved();
      return;
    }
    final pick = open[_rand.nextInt(open.length)];
    hintsUsed++;
    phase = CasePhase.hinting;
    _pendingHint = _Mark(pick[0], pick[1], pick[2], 2);
    flashCell = _code(pick[0], pick[1], pick[2]);
    flashGood = true;
    final cat = puzzle.categories[pick[0]];
    banner =
        'Hint: ${cat.values[pick[1]]} belongs in the ${_ordinalWord(pick[2])} house!';
    onEvent?.call(GridEvent.hint);
    notifyListeners();
    // Beat so the player sees the hinted cell glow, then stamp it.
    // Cancelling this timer (pause) keeps [_pendingHint] so the watchdog
    // can resume the stamp instead of losing the hint.
    _stepTimer = Timer(const Duration(milliseconds: 650), () {
      _stepTimer = null;
      if (_disposed || paused || terminal) return;
      final h = _pendingHint;
      _pendingHint = null;
      if (h != null) {
        _runClosure([h], CasePhase.hinting,
            const Duration(milliseconds: 110));
      }
    });
  }

  String _ordinalWord(int h) {
    const words = ['first', 'second', 'third', 'fourth', 'fifth'];
    return words[h];
  }

  // ----------------------------------------------------------------- reveal
  /// Give up: animate the full solution cell by cell — never instant.
  void revealSolution() {
    if (phase != CasePhase.playing || terminal) {
      onEvent?.call(GridEvent.invalid);
      return;
    }
    final marks = <_Mark>[];
    for (int c = 0; c < nc; c++) {
      for (int v = 0; v < n; v++) {
        final h = puzzle.solution[c][v];
        if (grid[c][v][h] != 2) marks.add(_Mark(c, v, h, 2));
      }
    }
    if (marks.isEmpty) {
      _checkSolved();
      return;
    }
    marks.shuffle(_rand);
    _queue.addAll(marks);
    _stepInterval = const Duration(milliseconds: 85);
    phase = CasePhase.revealing;
    banner = 'Revealing the truth…';
    notifyListeners();
    _armStep(_stepInterval);
  }

  // ------------------------------------------------------------------ solve
  void _checkSolved() {
    if (terminal) return;
    if (_correctCount() == puzzle.totalCells) {
      phase = CasePhase.solved;
      final timeBonus = (600 - elapsed).clamp(0, 600) * 2;
      score = (1000 + timeBonus - mistakes * 100 - hintsUsed * 50)
          .clamp(100, 100000);
      banner = 'Case closed! Score: $score';
      notifyListeners();
      onEvent?.call(GridEvent.solved);
    }
  }

  // ----------------------------------------------------------------- restart
  void restart() {
    _stepTimer?.cancel();
    _stepTimer = null;
    paused = false;
    _resetGrid();
    banner = 'Fresh case file — ${puzzle.clues.length} clues await.';
    notifyListeners();
    onEvent?.call(GridEvent.caseStart);
  }

  String formatTime() {
    final m = (elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (elapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
