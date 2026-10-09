import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/logicgrid_engine.dart';
import '../engine/puzzle.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/detective_kit.dart';
import '../theme/grid_themes.dart';

/// Case screen: renders the engine's grid, clues and phases. All state and
/// animation timing lives in [LogicGridEngine]; this widget only renders.
class GameScreen extends StatefulWidget {
  final DetectiveAudio audio;
  final DetectiveSettings settings;
  final String difficultyId; // 'easy' | 'medium' | 'hard' | 'daily'
  final StoreService store;

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.difficultyId,
    required this.store,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  LogicGridEngine? _engine;
  late final PuzzleSpec spec;
  late final String caseTitle;
  bool _statsRecorded = false;
  bool _cluesOpen = true;

  DetectiveSettings get _s => widget.settings;
  DetectiveThemeDef get _t => _s.theme;

  /// Non-null engine — only dereferenced once [_engine] is known ready.
  LogicGridEngine get _e => _engine!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    final String id;
    final int seed;
    if (widget.difficultyId == 'daily') {
      // Daily rotates difficulty so every day feels different.
      const ids = ['easy', 'medium', 'hard'];
      id = ids[now.day % 3];
      seed = dailySeed(now);
      caseTitle = 'Daily Challenge';
    } else {
      id = widget.difficultyId;
      seed = Random().nextInt(1 << 30);
      caseTitle = specById(id).name;
    }
    spec = specById(id);
    widget.audio.startGameMusic();
    _prepare(seed);
  }

  /// Build the puzzle off the critical path: the loading view paints first,
  /// then generation (seconds on hard cases) runs without a frozen screen.
  Future<void> _prepare(int seed) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final puzzle = generatePuzzle(spec, seed);
    final e = LogicGridEngine(
      puzzle: puzzle,
      maxMistakes: _s.isPro ? spec.maxMistakes + 2 : spec.maxMistakes,
      hintBudget: _s.isPro ? -1 : spec.freeHints,
    );
    e.onEvent = _onEvent;
    _engine = e;
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding mid-animation freezes the engine; the watchdog resumes
    // or completes the interrupted phase on return — never stuck.
    if (state == AppLifecycleState.paused) {
      _engine?.setPaused(true);
    } else if (state == AppLifecycleState.resumed) {
      _engine?.setPaused(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine?.dispose();
    super.dispose();
  }

  void _onEvent(GridEvent e) {
    final a = widget.audio;
    switch (e) {
      case GridEvent.markX:
        a.markX();
      case GridEvent.unmark:
        a.unmark();
      case GridEvent.stamp:
        a.stamp();
      case GridEvent.autoX:
        a.autoX();
      case GridEvent.error:
        a.error();
      case GridEvent.hint:
        a.hint();
      case GridEvent.checkTick:
        a.checkTick();
      case GridEvent.revealTick:
        a.reveal();
      case GridEvent.caseStart:
        a.caseStart();
      case GridEvent.solved:
        a.win();
        _onSolved();
      case GridEvent.revealed:
        a.reveal();
      case GridEvent.failed:
        a.lose();
      case GridEvent.noHints:
        a.error();
      case GridEvent.invalid:
        a.click();
    }
  }

  Future<void> _onSolved() async {
    if (_statsRecorded || _e.revealed) return;
    _statsRecorded = true;
    await _s.recordSolved(
        difficultyId: widget.difficultyId, score: _e.score);
  }

  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  Future<void> _shareScore() async {
    widget.audio.click();
    final text = _e.revealed
        ? 'I cracked a Logic Grid case! Play free: https://play.google.com/store/apps/details?id=com.gameswajiha.logicgrid'
        : 'I solved the $caseTitle Logic Grid case with ${_e.score} points in ${_e.formatTime()}! Can you beat me? https://play.google.com/store/apps/details?id=com.gameswajiha.logicgrid';
    await Share.share(text);
  }

  void _pauseDialog() {
    _e.setPaused(true);
    widget.audio.click();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: PaperCard(
          theme: _t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused', style: Desk.ink(26, theme: _t)),
              const SizedBox(height: 8),
              Text('The case file waits for you, ${_s.displayName}.',
                  style: Desk.ink(14, theme: _t), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              DeskButton(
                label: '▶  Resume',
                width: 200,
                theme: _t,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  _e.setPaused(false);
                },
              ),
              const SizedBox(height: 10),
              DeskButton(
                label: '↺  Restart case',
                width: 200,
                primary: false,
                theme: _t,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  _e.setPaused(false);
                  _e.restart();
                },
              ),
              const SizedBox(height: 10),
              DeskButton(
                label: '📁  Case list',
                width: 200,
                primary: false,
                theme: _t,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReveal() {
    widget.audio.click();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: PaperCard(
          theme: _t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reveal the truth?', style: Desk.ink(22, theme: _t)),
              const SizedBox(height: 8),
              Text(
                'The full solution will be stamped in — but a revealed case scores no points.',
                style: Desk.ink(14, theme: _t),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DeskButton(
                    label: 'Keep trying',
                    width: 140,
                    fontSize: 14,
                    primary: false,
                    theme: _t,
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 10),
                  DeskButton(
                    label: 'Reveal',
                    width: 120,
                    fontSize: 14,
                    theme: _t,
                    onTap: () {
                      widget.audio.reveal();
                      Navigator.of(context).pop();
                      _e.revealSolution();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return LeatherBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _engine == null
              ? _loadingView(t)
              : ListenableBuilder(
                  listenable: _engine!,
                  builder: (_, _) {
                    final LogicGridEngine engine = _e;
                    return Stack(
                      children: [
                        Column(
                          children: [
                            _hud(t),
                            _banner(t),
                            Expanded(child: _board(t)),
                            _actions(t),
                          ],
                        ),
                        if (engine.phase == CasePhase.solved)
                          _solvedOverlay(t),
                        if (engine.phase == CasePhase.failed)
                          _failedOverlay(t),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  /// Shown while the puzzle generates (hard cases take a few seconds).
  Widget _loadingView(DetectiveThemeDef t) => Center(
        child: PaperCard(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              Text('Opening the case file…',
                  style: Desk.ink(18, theme: t)),
              const SizedBox(height: 6),
              Text('Shuffling clues for $caseTitle',
                  style: Desk.ink(13, theme: t),
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  backgroundColor: t.ink.withValues(alpha: 0.15),
                  color: t.accent,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _hud(DetectiveThemeDef t) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                widget.audio.click();
                Navigator.of(context).pop();
              },
              child: Text('‹ Cases',
                  style: Desk.label(16, theme: t)),
            ),
            const Spacer(),
            _HudChip(
                theme: t, text: '⏱ ${_e.formatTime()}'),
            const SizedBox(width: 6),
            _HudChip(
                theme: t,
                text:
                    '✖ ${_e.mistakes}/${_e.maxMistakes}'),
            const SizedBox(width: 6),
            _HudChip(
                theme: t,
                text: _e.unlimitedHints
                    ? '💡 ∞'
                    : '💡 ${_e.hintsLeft}'),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _pauseDialog,
              child: _HudChip(theme: t, text: '⏸'),
            ),
          ],
        ),
      );

  Widget _banner(DetectiveThemeDef t) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: t.accent.withValues(alpha: 0.5)),
        ),
        child: Text(
          _e.banner,
          style: Desk.body(13, theme: t, color: t.accentLight),
          textAlign: TextAlign.center,
        ),
      );

  Widget _board(DetectiveThemeDef t) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cluesCard(t),
            const SizedBox(height: 10),
            Text(
              '$caseTitle — ${_s.displayName}’s case file',
              style: Desk.label(13, theme: t),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            for (int c = 0; c < _e.nc; c++) _categoryGrid(t, c),
            const SizedBox(height: 4),
          ],
        ),
      );

  Widget _cluesCard(DetectiveThemeDef t) => PaperCard(
        theme: t,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                widget.audio.click();
                setState(() => _cluesOpen = !_cluesOpen);
              },
              child: Row(
                children: [
                  Text('📜 Clues (${_e.puzzle.clues.length})',
                      style: Desk.ink(16, theme: t)),
                  const Spacer(),
                  Text(_cluesOpen ? '▾' : '▸',
                      style: Desk.ink(16, theme: t)),
                ],
              ),
            ),
            if (_cluesOpen) ...[
              const SizedBox(height: 6),
              for (int i = 0; i < _e.puzzle.clues.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${i + 1}. ${_e.puzzle.clueTexts()[i]}',
                      style: Desk.ink(13.5, theme: t)),
                ),
            ],
          ],
        ),
      );

  Widget _categoryGrid(DetectiveThemeDef t, int c) {
    final cat = _e.puzzle.categories[c];
    final n = _e.n;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.paper, t.paperDark],
        ),
        border: Border.all(color: t.accentDark, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(5)),
              color: t.ink.withValues(alpha: 0.85),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  child: Text(cat.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: Desk.label(12, theme: t, color: t.accentLight)),
                ),
                for (int h = 0; h < n; h++)
                  Expanded(
                    child: Text('${h + 1}',
                        textAlign: TextAlign.center,
                        style: Desk.label(12,
                            theme: t, color: t.paper.withValues(alpha: 0.8))),
                  ),
              ],
            ),
          ),
          for (int v = 0; v < n; v++)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: t.ink.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(cat.values[v],
                        textAlign: TextAlign.center,
                        style: Desk.ink(13, theme: t)),
                  ),
                  for (int h = 0; h < n; h++)
                    Expanded(child: _cell(t, c, v, h)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(DetectiveThemeDef t, int c, int v, int h) {
    final st = _e.grid[c][v][h];
    final code = c * 10000 + v * 100 + h;
    final flashing = _e.flashCell == code;
    final wrong = _e.wrongMarks.contains(code);
    final ms = _s.markStyle;
    return GestureDetector(
      onTap: () => _e.tap(c, v, h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.all(3),
        height: 36,
        decoration: BoxDecoration(
          color: flashing
              ? t.accent.withValues(alpha: 0.45)
              : st == 2
                  ? t.stamp.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: flashing
                ? t.accentLight
                : st == 2
                    ? t.stamp
                    : t.ink.withValues(alpha: 0.25),
            width: flashing || st == 2 ? 2 : 1,
          ),
          boxShadow: flashing
              ? [
                  BoxShadow(
                      color: t.accent.withValues(alpha: 0.6),
                      blurRadius: 8)
                ]
              : null,
        ),
        child: Center(
          child: st == 0
              ? const SizedBox.shrink()
              : Text(
                  st == 2
                      ? MarkStyles.oGlyph(ms)
                      : MarkStyles.xGlyph(ms),
                  style: TextStyle(
                    fontSize: st == 2 ? 17 : 15,
                    fontWeight: FontWeight.w900,
                    color: st == 2
                        ? (wrong ? const Color(0xFFC0392B) : t.stamp)
                        : t.ink.withValues(alpha: 0.75),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _actions(DetectiveThemeDef t) {
    final busy = _e.working || _e.terminal;
    Widget btn(IconData icon, String label, VoidCallback onTap) =>
        GestureDetector(
          onTap: busy ? null : onTap,
          child: Opacity(
            opacity: busy ? 0.45 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WaxSeal(
                  theme: t,
                  size: 52,
                  child: Icon(icon, color: t.paper, size: 24),
                ),
                const SizedBox(height: 4),
                Text(label, style: Desk.label(11, theme: t)),
              ],
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.45),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          btn(Icons.lightbulb, 'Hint', () {
            widget.audio.click();
            _e.hint();
          }),
          btn(Icons.search, 'Check', () {
            widget.audio.click();
            _e.check();
          }),
          btn(Icons.visibility, 'Reveal', _confirmReveal),
          btn(Icons.refresh, 'Restart', () {
            widget.audio.click();
            _e.restart();
          }),
        ],
      ),
    );
  }

  Widget _solvedOverlay(DetectiveThemeDef t) {
    final revealed = _e.revealed;
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(28),
      child: Center(
        child: PaperCard(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(revealed ? '👁' : '🎉',
                  style: const TextStyle(fontSize: 52)),
              Text(
                revealed ? 'Case revealed' : 'Case closed!',
                style: Desk.ink(26, theme: t),
              ),
              const SizedBox(height: 6),
              if (!revealed) ...[
                Text('Score: ${_e.score}',
                    style: Desk.ink(18, theme: t)),
                Text(
                  '⏱ ${_e.formatTime()}   ✖ ${_e.mistakes}   💡 ${_e.hintsUsed}',
                  style: Desk.ink(13, theme: t)),
                if (widget.difficultyId == 'daily')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('🔥 Daily streak: ${_s.dailyStreak}',
                        style: Desk.ink(14, theme: t)),
                  ),
              ] else
                Text('The full truth is stamped in — no score this time.',
                    style: Desk.ink(14, theme: t),
                    textAlign: TextAlign.center),
              const SizedBox(height: 16),
              DeskButton(
                label: '🔎  Next case',
                width: 210,
                theme: t,
                onTap: () {
                  widget.audio.caseStart();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        audio: widget.audio,
                        settings: _s,
                        difficultyId: widget.difficultyId,
                        store: widget.store,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _OverlayIcon(
                      theme: t,
                      icon: Icons.share,
                      label: 'Share',
                      onTap: _shareScore),
                  const SizedBox(width: 18),
                  _OverlayIcon(
                      theme: t,
                      icon: Icons.star_rate,
                      label: 'Rate',
                      onTap: () {
                        widget.audio.click();
                        _requestReview();
                      }),
                  const SizedBox(width: 18),
                  _OverlayIcon(
                      theme: t,
                      icon: Icons.folder_open,
                      label: 'Cases',
                      onTap: () {
                        widget.audio.click();
                        Navigator.of(context).pop();
                      }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _failedOverlay(DetectiveThemeDef t) => Container(
        color: Colors.black54,
        padding: const EdgeInsets.all(28),
        child: Center(
          child: PaperCard(
            theme: t,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🕯', style: TextStyle(fontSize: 52)),
                Text('The trail went cold…',
                    style: Desk.ink(24, theme: t)),
                const SizedBox(height: 6),
                Text(
                  'Too many wrong stamps. Every great detective re-opens the file.',
                  style: Desk.ink(14, theme: t),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                DeskButton(
                  label: '↺  Re-open the case',
                  width: 220,
                  theme: t,
                  onTap: () {
                    widget.audio.caseStart();
                    _e.restart();
                  },
                ),
                const SizedBox(height: 10),
                DeskButton(
                  label: '📁  Case list',
                  width: 220,
                  primary: false,
                  theme: t,
                  onTap: () {
                    widget.audio.click();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
}

class _HudChip extends StatelessWidget {
  final DetectiveThemeDef theme;
  final String text;
  const _HudChip({required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.4),
        border: Border.all(color: theme.accent.withValues(alpha: 0.5)),
      ),
      child: Text(text,
          style: Desk.label(12, theme: theme, color: theme.paper)),
    );
  }
}

class _OverlayIcon extends StatelessWidget {
  final DetectiveThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OverlayIcon(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          WaxSeal(
            theme: theme,
            size: 52,
            child: Icon(icon, color: theme.paper, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: Desk.ink(11, theme: theme)),
        ],
      ),
    );
  }
}
