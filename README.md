# Logic Grid — The Detective's Case Files

Einstein-style logic grid deduction by WAJIHA (package
`com.gameswajiha.logicgrid`). Read the clues, stamp ✓ where a value belongs
and ✕ where it cannot, and close the case.

## Play

- **Cases:** Cottage Case (Easy, 3×3), Maple Street (Medium, 4×4),
  Einstein Avenue (Hard, 5×5, PRO), plus a seeded Daily Challenge that is
  the same for everyone all day (with streaks).
- Tap a cell to cycle blank → ✕ → ✓. Correct ✓ stamps animate
  propagation; wrong ✓ stamps count as mistakes (limited per case).
- Tools: 💡 hint (one true cell glows, then stamps), 🔍 check (every ✓
  flashes in sequence), 👁 reveal (animated full solution, no score),
  ↺ restart, ⏸ pause.
- Every generated clue set is validated by the engine's backtracking CSP
  solver to have exactly one solution; clue sets are minimized.

## Architecture

- `lib/engine/puzzle.dart` — pure-Dart puzzle model: seeded generation,
  uniqueness solver. No Flutter imports.
- `lib/engine/logicgrid_engine.dart` — engine-owned state machine
  (`CasePhase`) + watchdog: `playing → autoFilling|checking|hinting|
  revealing → playing → solved|failed`. The UI only renders; the engine
  steps its own timers. Input is locked outside `playing`.
- `lib/screens/` — splash (WAJIHA company moment → game splash), menu,
  game, settings, custom theme creator, PRO screen.
- `lib/services/` — `DetectiveAudio` (synthesized WAV clips, cached,
  generation-serialized music, lifecycle pause/resume, prewarm on splash),
  `DetectiveSettings` (single-JSON profile persistence), `StoreService`
  (real `in_app_purchase`).
- `lib/theme/` — 16 pseudo-3D detective-noir themes + 8 stamp mark styles
  + custom theme creator (all persisted); leather/wood/brass/paper
  materials, no neon.

## Monetization

- `logicgridpro` (one-time): Hard case, 12 extra themes, 4 extra stamp
  styles, custom theme creator, unlimited hints, +2 mistakes.
- `logicgridcoffee` / `logicgridchocolate` (consumables): tip jar.
- Products are created in Play Console; the app degrades gracefully
  ("Available after store setup") when unconfigured.

## Rules

See [RULES.md](RULES.md) — the authoritative source of truth (13 sections).
