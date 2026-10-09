import 'dart:math';

/// Pure-Dart logic-grid puzzle model: categories, clue wording, seeded
/// puzzle generation with uniqueness-checked clue sets, and a backtracking
/// solver used to validate uniqueness. No Flutter imports — unit testable.

String _ordinal(int h) {
  final n = h + 1;
  if (n == 1) return '1st';
  if (n == 2) return '2nd';
  if (n == 3) return '3rd';
  return '${n}th';
}

/// A value category (Color, Pet, ...). Each category has exactly [houses]
/// values and each house holds exactly one value of each category.
class PuzzleCategory {
  final String id;
  final String name;
  final List<String> values;

  const PuzzleCategory({
    required this.id,
    required this.name,
    required this.values,
  });

  /// Subject phrase used in left-of / next-to clues.
  String noun(String v) => switch (id) {
        'color' => 'the $v house',
        'pet' => 'the $v',
        'drink' => 'the $v drinker',
        'snack' => 'the $v eater',
        'hobby' => 'the $v fan',
        _ => 'the $v',
      };

  /// Direct placement clue wording.
  String placed(String v, int house) => switch (id) {
        'color' => 'The ${_ordinal(house)} house is $v.',
        'pet' => 'The $v lives in the ${_ordinal(house)} house.',
        'drink' => '$v is drunk in the ${_ordinal(house)} house.',
        'snack' => '$v is eaten in the ${_ordinal(house)} house.',
        'hobby' => '$v is enjoyed in the ${_ordinal(house)} house.',
        _ => '$v is in the ${_ordinal(house)} house.',
      };
}

const allCategories = [
  PuzzleCategory(
      id: 'color',
      name: 'Color',
      values: ['Red', 'Green', 'Blue', 'Yellow', 'Purple']),
  PuzzleCategory(
      id: 'pet', name: 'Pet', values: ['Cat', 'Dog', 'Bird', 'Fish', 'Horse']),
  PuzzleCategory(
      id: 'drink',
      name: 'Drink',
      values: ['Tea', 'Coffee', 'Juice', 'Milk', 'Water']),
  PuzzleCategory(
      id: 'snack',
      name: 'Snack',
      values: ['Cake', 'Pie', 'Cookie', 'Candy', 'Chips']),
  PuzzleCategory(
      id: 'hobby',
      name: 'Hobby',
      values: ['Chess', 'Jazz', 'Reading', 'Gardening', 'Cycling']),
];

/// Two values from different categories sharing one house.
/// Template keyed on "aId|bId" with {0}/{1} as the values in that order.
const _pairTemplates = {
  'color|drink': '{1} is drunk in the {0} house.',
  'color|hobby': 'The {1} fan lives in the {0} house.',
  'color|pet': 'The {1} lives in the {0} house.',
  'color|snack': '{1} is eaten in the {0} house.',
  'drink|hobby': 'The {0} drinker enjoys {1}.',
  'drink|pet': 'The {1} owner drinks {0}.',
  'drink|snack': 'The {0} drinker eats {1}.',
  'hobby|pet': 'The {1} owner enjoys {0}.',
  'hobby|snack': 'The {1} eater enjoys {0}.',
  'pet|snack': 'The {0} owner eats {1}.',
};

String pairText(PuzzleCategory a, String va, PuzzleCategory b, String vb) {
  final first = a.id.compareTo(b.id) <= 0;
  final x = first ? a : b;
  final y = first ? b : a;
  final vx = first ? va : vb;
  final vy = first ? vb : va;
  final tpl = _pairTemplates['${x.id}|${y.id}'] ?? '{0} and {1} go together.';
  return tpl.replaceAll('{0}', vx).replaceAll('{1}', vy);
}

enum ClueKind { placement, pair, leftOf, adjacent }

/// A single clue. For [placement], (c1, v1, house) is used.
/// For the rest, (c1, v1) relates to (c2, v2).
class Clue {
  final ClueKind kind;
  final int c1, v1, c2, v2, house;

  const Clue.placement(this.c1, this.v1, this.house)
      : kind = ClueKind.placement,
        c2 = -1,
        v2 = -1;

  const Clue(this.kind, this.c1, this.v1, this.c2, this.v2) : house = -1;

  String text(List<PuzzleCategory> cats) {
    final a = cats[c1];
    switch (kind) {
      case ClueKind.placement:
        return a.placed(a.values[v1], house);
      case ClueKind.pair:
        final b = cats[c2];
        return pairText(a, a.values[v1], b, b.values[v2]);
      case ClueKind.leftOf:
        final b = cats[c2];
        return '${a.noun(a.values[v1]).capitalize()} is immediately to '
            'the left of ${b.noun(b.values[v2])}.';
      case ClueKind.adjacent:
        final b = cats[c2];
        return '${a.noun(a.values[v1]).capitalize()} is right next to '
            '${b.noun(b.values[v2])}.';
    }
  }
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

/// A generated puzzle: solution grid + clue list.
class Puzzle {
  final String difficultyId;
  final int seed;
  final List<PuzzleCategory> categories;
  final int houses;

  /// solution[cat][value] = house index.
  final List<List<int>> solution;

  /// valueAt[cat][house] = value index (inverse of solution).
  final List<List<int>> valueAt;
  final List<Clue> clues;

  Puzzle({
    required this.difficultyId,
    required this.seed,
    required this.categories,
    required this.houses,
    required this.solution,
    required this.valueAt,
    required this.clues,
  });

  List<String> clueTexts() =>
      [for (final c in clues) c.text(categories)];

  int get totalCells =>
      categories.fold(0, (a, c) => a + c.values.length);
}

// ---------------------------------------------------------------------------
// Uniqueness solver: backtracking CSP with propagation, solution cap of 2,
// node budget (budget exhaustion => "not proven unique").
// ---------------------------------------------------------------------------

class _Csp {
  final int n; // houses
  final int varCount;
  final List<Clue> clues;
  static const int nodeBudget = 20000;
  int nodes = 0;
  int solutions = 0;

  _Csp({
    required this.n,
    required this.varCount,
    required this.clues,
  });

  int _fullMask() => (1 << n) - 1;

  bool _propagate(List<int> dom) {
    bool changed = true;
    while (changed) {
      changed = false;
      // Category all-different: singleton domains eliminate from siblings.
      for (int c = 0; c * n < varCount; c++) {
        int used = 0;
        for (int v = 0; v < n; v++) {
          final d = dom[c * n + v];
          if (d != 0 && (d & (d - 1)) == 0) used |= d;
        }
        for (int v = 0; v < n; v++) {
          final i = c * n + v;
          final d = dom[i];
          if (d != 0 && (d & (d - 1)) != 0) {
            final nd = d & ~used;
            if (nd != d) {
              if (nd == 0) return false;
              dom[i] = nd;
              changed = true;
            }
          }
        }
      }
      // Clue constraints.
      for (final cl in clues) {
        switch (cl.kind) {
          case ClueKind.placement:
            final i = cl.c1 * n + cl.v1;
            final nd = dom[i] & (1 << cl.house);
            if (nd == 0) return false;
            if (nd != dom[i]) {
              dom[i] = nd;
              changed = true;
            }
          case ClueKind.pair:
            final a = cl.c1 * n + cl.v1;
            final b = cl.c2 * n + cl.v2;
            final inter = dom[a] & dom[b];
            if (inter == 0) return false;
            if (inter != dom[a]) {
              dom[a] = inter;
              changed = true;
            }
            if (inter != dom[b]) {
              dom[b] = inter;
              changed = true;
            }
          case ClueKind.leftOf:
            final a = cl.c1 * n + cl.v1;
            final b = cl.c2 * n + cl.v2;
            // b == a + 1
            int keepA = 0, keepB = 0;
            for (int h = 0; h + 1 < n; h++) {
              if ((dom[a] & (1 << h)) != 0 &&
                  (dom[b] & (1 << (h + 1))) != 0) {
                keepA |= 1 << h;
                keepB |= 1 << (h + 1);
              }
            }
            if (keepA == 0 || keepB == 0) return false;
            if (keepA != dom[a]) {
              dom[a] = keepA;
              changed = true;
            }
            if (keepB != dom[b]) {
              dom[b] = keepB;
              changed = true;
            }
          case ClueKind.adjacent:
            final a = cl.c1 * n + cl.v1;
            final b = cl.c2 * n + cl.v2;
            int keepA = 0, keepB = 0;
            for (int h = 0; h < n; h++) {
              if ((dom[a] & (1 << h)) == 0) continue;
              for (final g in [h - 1, h + 1]) {
                if (g >= 0 && g < n && (dom[b] & (1 << g)) != 0) {
                  keepA |= 1 << h;
                  keepB |= 1 << g;
                }
              }
            }
            if (keepA == 0 || keepB == 0) return false;
            if (keepA != dom[a]) {
              dom[a] = keepA;
              changed = true;
            }
            if (keepB != dom[b]) {
              dom[b] = keepB;
              changed = true;
            }
        }
      }
    }
    return true;
  }

  void _search(List<int> dom) {
    if (solutions >= 2 || nodes >= nodeBudget) return;
    nodes++;
    if (!_propagate(dom)) return;
    // MRV: unassigned variable with smallest domain > 1.
    int pick = -1, best = 99;
    for (int i = 0; i < varCount; i++) {
      final d = dom[i];
      if (d == 0) return;
      if ((d & (d - 1)) != 0) {
        final size = d.bitCount();
        if (size < best) {
          best = size;
          pick = i;
        }
      }
    }
    if (pick == -1) {
      solutions++;
      return;
    }
    var d = dom[pick];
    while (d != 0 && solutions < 2 && nodes < nodeBudget) {
      final bit = d & -d;
      d &= ~bit;
      final next = List<int>.of(dom);
      next[pick] = bit;
      _search(next);
    }
  }

  /// True only when exactly one solution exists within budget.
  bool isUnique() {
    final dom = List<int>.filled(varCount, _fullMask());
    _search(dom);
    return solutions == 1;
  }
}

int _bitCount(int x) {
  var c = 0;
  while (x != 0) {
    x &= x - 1;
    c++;
  }
  return c;
}

extension on int {
  int bitCount() => _bitCount(this);
}

// ---------------------------------------------------------------------------
// Seeded generator.
// ---------------------------------------------------------------------------

class PuzzleSpec {
  final String id;
  final String name;
  final String tagline;
  final List<int> categoryIdx; // indices into allCategories
  final int houses;
  final int maxMistakes;
  final int freeHints;

  const PuzzleSpec({
    required this.id,
    required this.name,
    required this.tagline,
    required this.categoryIdx,
    required this.houses,
    required this.maxMistakes,
    required this.freeHints,
  });
}

const puzzleSpecs = [
  PuzzleSpec(
    id: 'easy',
    name: 'Cottage Case',
    tagline: '3 houses · gentle warm-up',
    categoryIdx: [0, 1, 2],
    houses: 3,
    maxMistakes: 3,
    freeHints: 3,
  ),
  PuzzleSpec(
    id: 'medium',
    name: 'Maple Street',
    tagline: '4 houses · a proper mystery',
    categoryIdx: [0, 1, 2, 3],
    houses: 4,
    maxMistakes: 4,
    freeHints: 3,
  ),
  PuzzleSpec(
    id: 'hard',
    name: 'Einstein Avenue',
    tagline: '5 houses · for master minds',
    categoryIdx: [0, 1, 2, 3, 4],
    houses: 5,
    maxMistakes: 5,
    freeHints: 3,
  ),
];

PuzzleSpec specById(String id) =>
    puzzleSpecs.firstWhere((s) => s.id == id, orElse: () => puzzleSpecs[0]);

/// Deterministic daily seed: same puzzle for everyone, all day.
int dailySeed(DateTime day) => day.year * 10000 + day.month * 100 + day.day;

/// Generate a puzzle. Deterministic for a given (spec, seed).
Puzzle generatePuzzle(PuzzleSpec spec, int seed) {
  final rng = Random(seed);
  final cats =
      [for (final i in spec.categoryIdx) allCategories[i]];
  final n = spec.houses;
  final nc = cats.length;

  // Random solution: per-category permutation of houses.
  final solution = List.generate(nc, (_) {
    final perm = List<int>.generate(n, (i) => i)..shuffle(rng);
    return perm;
  });
  // valueAt[cat][house] = value index.
  final valueAt = List.generate(nc, (c) {
    final inv = List<int>.filled(n, 0);
    for (int v = 0; v < n; v++) {
      inv[solution[c][v]] = v;
    }
    return inv;
  });

  // Candidate clue pool: every clue consistent with the solution.
  final pool = <Clue>[];
  for (int c = 0; c < nc; c++) {
    for (int v = 0; v < n; v++) {
      pool.add(Clue.placement(c, v, solution[c][v]));
    }
  }
  for (int h = 0; h < n; h++) {
    for (int a = 0; a < nc; a++) {
      for (int b = a + 1; b < nc; b++) {
        final va = valueAt[a][h];
        final vb = valueAt[b][h];
        pool.add(Clue(ClueKind.pair, a, va, b, vb));
        if (h + 1 < n) {
          final wb = valueAt[b][h + 1];
          pool.add(Clue(ClueKind.leftOf, a, va, b, wb));
          pool.add(Clue(ClueKind.adjacent, a, va, b, wb));
          final wa = valueAt[a][h + 1];
          pool.add(Clue(ClueKind.leftOf, b, vb, a, wa));
          pool.add(Clue(ClueKind.adjacent, b, vb, a, wa));
        }
      }
    }
  }
  pool.shuffle(rng);

  bool unique(List<Clue> clues) => _Csp(
        n: n,
        varCount: nc * n,
        clues: clues,
      ).isUnique();

  // Greedy accumulation.
  final clues = <Clue>[];
  for (final cand in pool) {
    clues.add(cand);
    if (clues.length % 3 == 0 && unique(clues)) break;
  }
  // Fallback: if the pool ran dry without uniqueness, pin every cell of the
  // first category — a full column assignment is always unique.
  if (!unique(clues)) {
    for (int v = 0; v < n; v++) {
      clues.add(Clue.placement(0, v, solution[0][v]));
    }
  }
  // Minimize: drop any clue that is not needed for uniqueness.
  bool changed = true;
  while (changed) {
    changed = false;
    for (int i = clues.length - 1; i >= 0; i--) {
      final trial = [...clues]..removeAt(i);
      if (unique(trial)) {
        clues.removeAt(i);
        changed = true;
      }
    }
  }

  return Puzzle(
    difficultyId: spec.id,
    seed: seed,
    categories: cats,
    houses: n,
    solution: solution,
    valueAt: valueAt,
    clues: clues,
  );
}
