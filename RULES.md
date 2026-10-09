# Logic Grid — RULES.md
_The authoritative source of truth for the Logic Grid game. If implementation
conflicts with this document, fix the implementation._

Einstein-style logic grid deduction: every house holds exactly one value from
each category (Color, Pet, Drink, …). Read the clues, stamp ✓ where a value
belongs and ✕ where it cannot, and close the case.

## 1. Objective
Place every value in its correct house using only the given clues. A case is
solved when every value of every category is stamped ✓ in its true house.

## 2. Setup
- Choose a case: **Cottage Case** (Easy: 3 houses, 3 categories), **Maple
  Street** (Medium: 4 houses, 4 categories), **Einstein Avenue** (Hard:
  5 houses, 5 categories, PRO), or the **Daily Challenge** (a fresh seeded
  case every day; difficulty rotates Easy → Medium → Hard).
- Each case is generated from a seed: the same seed always produces the same
  solution and the same clue set. The Daily Challenge seed is derived from
  the calendar date, so everyone gets the same case all day.
- Every generated clue set is validated by the engine's solver to have
  **exactly one** solution before the case is offered.
- The grid starts blank. A timer runs; mistakes, hints used and elapsed time
  feed the final score.
- Cases generate on entry; a "Opening the case file…" loading view covers
  the brief generation step (hard cases take a few seconds on slower
  phones) so the menu never appears frozen.

## 3. Turn order
Logic Grid is single-player and turnless: the detective acts whenever ready.
Engine phases are: `playing` → (`autoFilling` | `checking` | `hinting` |
`revealing`) → `playing` → `solved` | `failed`. Input is only accepted in
`playing`; every other phase is engine-driven and returns to `playing` on
its own timers. A watchdog recovers any working phase found without a live
timer, so the game can never get stuck.

## 4. Legal moves
- **Tap a blank cell** → marks ✕ (this value cannot be in this house).
- **Tap a ✕ cell** → stamps ✓:
  - If the stamp matches the hidden solution: the ✓ is placed and the rest
    of that value's row and that house's column auto-fill with ✕, animated
    step by step.
  - If the stamp is wrong: it is recorded as a **mistake** and shown with a
    red stamp. Mistakes are limited (see §8).
- **Tap a ✓ cell** → clears it back to blank (and clears its mistake flag).
- **Naked single:** whenever a row has no ✓ and exactly one blank cell left,
  the ✓ stamps itself automatically with animation.
- **Hint (💡):** reveals one true cell with a glow animation, then stamps it
  (counts as a used hint). Free: 3 hints per case. PRO: unlimited.
- **Check (🔍):** every placed ✓ flashes in sequence and the detective is
  told how many of the total values are placed correctly. Never instant.
- **Reveal (👁):** stamps the entire solution cell by cell (animated, never
  instant). A revealed case is closed with **no score**.
- **Restart (↺):** clears the grid, mistakes, hints and timer; same case.

## 5. Illegal moves
- Tapping any cell while the engine is animating (`autoFilling`, `checking`,
  `hinting`, `revealing`) or after the case is closed is ignored with a
  gentle click — state never changes.
- There are no other illegal moves: ✕ marks are never penalized, and any
  cell may be cleared at any time.

## 6. Captures
Not applicable — Logic Grid has no captures.

## 7. Special rules
- **Clue types:** direct placements ("The 2nd house is Red."), pairings
  ("The Cat owner drinks Tea."), immediate-left ("The Cat is immediately to
  the left of the Tea drinker."), and adjacency ("The Cat is right next to
  the Tea drinker.").
- **Auto-exclusion:** stamping ✓ always excludes the rest of the row and
  column with ✕ — the fundamental deduction aid.
- **Daily streak:** solving the Daily Challenge on consecutive calendar days
  increments the streak; missing a day resets it to 1 on the next solve.

## 8. Scoring
- Solved case score: `1000 + max(0, 600 − seconds) × 2 − mistakes × 100 −
  hintsUsed × 50`, minimum 100.
- Revealed cases score 0 and do not count as solved.
- Best score per difficulty and total cases solved are kept in the
  detective's profile.

## 9. Winning conditions
The case is **solved** the moment every value of every category carries a ✓
in its true house. A "Case closed!" celebration shows the score, time,
mistakes and hints used.

## 10. Draw conditions
Not applicable — every case ends solved, revealed, or failed.

## 11. AI strategy
Not applicable — there is no opponent. Puzzle generation uses a seeded
backtracking CSP solver (propagation + MRV, solution cap 2) to guarantee a
unique solution; clue sets are greedily minimized so no clue is redundant.

## 12. Edge cases
- **Mistake limit reached** (Easy 3 / Medium 4 / Hard 5; +2 with PRO): the
  case fails ("The trail went cold…") with a lose sound; the detective may
  re-open the same case fresh.
- **Hint with no hints left (free):** gentle message pointing at PRO;
  no state change.
- **Check with no stamps placed:** message asking to mark deductions first.
- **Reveal with a complete grid:** treated as a normal solve check instead.
- **App backgrounded mid-animation:** the engine pauses (its step timers are
  frozen and the case clock stops); on resume the watchdog restarts or
  completes the interrupted phase — never stuck. A hint interrupted mid
  glow-beat is resumed, never silently lost.
- **Daily already solved today:** the card shows ✅ and can still be replayed.

## 13. Test cases
1. Generate Easy/Medium/Hard with fixed seeds → deterministic, identical
   clue sets on repeat runs; each validates as uniquely solvable.
2. Stamp a correct ✓ → row and column auto-fill with ✕, animated, one by
   one; input locked during the animation.
3. Stamp a wrong ✓ → mistake counted, red stamp shown; reaching the limit
   fails the case with the lose sound.
4. Naked single (one blank left in a row) → ✓ stamps itself automatically.
5. Hint → one true cell glows, then stamps with propagation; free hints
   exhaust after 3 per case; PRO never exhausts.
6. Check → every ✓ flashes in sequence; banner reports "n of total correct".
7. Reveal → solution stamps cell by cell; overlay shows "Case revealed",
   score 0, not recorded as solved.
8. Solve fully → "Case closed!" with score = formula in §8; stats and daily
   streak persist across app restarts.
9. Kill the app mid-animation and relaunch → new engine starts clean;
   background/foreground during animation → watchdog completes the phase.
10. Rename detective → name persists, shown on menu and case file.
11. PRO purchase (real store) → Hard, 12 extra themes, 4 extra stamp
    styles, custom theme creator, unlimited hints, +2 mistakes unlock.
12. Store unconfigured → PRO screen honestly says "Available after store
    setup"; no fake buy buttons.
