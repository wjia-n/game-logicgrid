import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/puzzle.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/detective_kit.dart';
import '../theme/grid_themes.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — the detective's office.
/// Logo, case picker (Easy/Medium/Hard + Daily Challenge), theme picker,
/// mark styles, detective renaming, tip jar, settings.
class MenuScreen extends StatefulWidget {
  final DetectiveAudio audio;
  final DetectiveSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _store = StoreService();

  DetectiveSettings get _s => widget.settings;
  DetectiveThemeDef get _t => _s.theme;

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
    _store.proPurchased.addListener(_onPro);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Desk.body(15, theme: _t)),
        backgroundColor: _t.deskDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  void _onPro() {
    if (_store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      _store.proPurchased.value = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.proPurchased.removeListener(_onPro);
    _store.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
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

  void _play(String difficultyId) {
    widget.audio.caseStart();
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        audio: widget.audio,
        settings: _s,
        difficultyId: difficultyId,
        store: _store,
      ),
    ))
        .then((_) {
      if (mounted) {
        widget.audio.startMenuMusic();
        setState(() {}); // refresh daily-done / stats
      }
    });
  }

  void _goPro() {
    widget.audio.click();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: widget.audio,
        settings: _s,
        store: _store,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return LeatherBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo plaque.
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/logicgrid_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('Logic Grid', style: Desk.display(44, theme: t)),
                  Text(
                    "THE DETECTIVE'S CASE FILES",
                    style: Desk.label(12, theme: t),
                  ),
                  const SizedBox(height: 6),
                  Text('Welcome back, ${_s.displayName} 🕵️',
                      style: Desk.body(14, theme: t)),
                  const SizedBox(height: 20),
                  _DailyCard(theme: t, onPlay: () => _play('daily')),
                  const SizedBox(height: 14),
                  _CasesCard(theme: t, onPlay: _play, onPro: _goPro),
                  const SizedBox(height: 14),
                  _StyleCard(theme: t, onPro: _goPro),
                  const SizedBox(height: 14),
                  _DetectiveCard(theme: t),
                  const SizedBox(height: 14),
                  _SupportCard(theme: t, store: _store),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                        theme: t,
                        icon: Icons.workspace_premium,
                        label: _s.isPro ? 'PRO ✓' : 'PRO',
                        onTap: _goPro,
                      ),
                      const SizedBox(width: 18),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () async {
                          widget.audio.click();
                          await Share.share(
                              'Crack Einstein-style logic grid cases with me — Logic Grid is free! https://play.google.com/store/apps/details?id=com.gameswajiha.logicgrid');
                        },
                      ),
                      const SizedBox(width: 18),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: () async {
                          widget.audio.click();
                          await _requestReview();
                        },
                      ),
                      const SizedBox(width: 18),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          widget.audio.click();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: _s,
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 18),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.help_outline,
                        label: 'How to Play',
                        onTap: () {
                          widget.audio.click();
                          _showHowTo(context, t);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_s.totalSolved > 0)
                    Text(
                      'Cases solved: ${_s.totalSolved}   •   🔥 Streak: ${_s.dailyStreak}',
                      style: Desk.label(12, theme: t),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Desk.label(12, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context, DetectiveThemeDef t) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: PaperCard(
          theme: t,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How to Play', style: Desk.ink(24, theme: t)),
                const SizedBox(height: 12),
                for (final line in [
                  '• Read the clues and crack each case!',
                  '• Tap a cell to cycle: blank → ✕ (no) → ✓ (yes).',
                  '• Stamping ✓ fills the rest of that row and column with ✕.',
                  '• A wrong ✓ stamp counts as a mistake — too many and the trail goes cold.',
                  '• When only one blank is left in a row, the ✓ stamps itself.',
                  '• Use 💡 hints and 🔍 checks when you are stuck.',
                  '• 👁 reveals the whole truth — but scores no points.',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(line, style: Desk.ink(14, theme: t)),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: DeskButton(
                    label: 'Got it!',
                    width: 180,
                    fontSize: 16,
                    theme: t,
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _MenuIcon extends StatelessWidget {
  final DetectiveThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon(
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
            size: 58,
            child: Icon(icon, color: theme.paper, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: Desk.label(11, theme: theme)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Daily challenge card with streak.
class _DailyCard extends StatelessWidget {
  final DetectiveThemeDef theme;
  final VoidCallback onPlay;
  const _DailyCard({required this.theme, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    final done = s.dailyDoneToday;
    return GestureDetector(
      onTap: () {
        screen.widget.audio.click();
        onPlay();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.stamp, theme.stamp.withValues(alpha: 0.7)],
          ),
          border: Border.all(color: theme.accentLight, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(0, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Challenge',
                      style: Desk.display(20, theme: theme)),
                  Text(
                    done
                        ? 'Solved today — come back tomorrow! 🔥 ${s.dailyStreak}'
                        : s.dailyStreak > 0
                            ? 'A fresh case every day — streak: 🔥 ${s.dailyStreak}'
                            : 'A fresh case every day — start your streak!',
                    style: Desk.body(13, theme: theme),
                  ),
                ],
              ),
            ),
            Text(done ? '✅' : '▶️', style: const TextStyle(fontSize: 26)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Case difficulty picker: Easy / Medium / Hard (Hard = PRO).
class _CasesCard extends StatelessWidget {
  final DetectiveThemeDef theme;
  final void Function(String id) onPlay;
  final VoidCallback onPro;
  const _CasesCard(
      {required this.theme, required this.onPlay, required this.onPro});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    final audio = screen.widget.audio;
    const emojis = {'easy': '🏡', 'medium': '🏘️', 'hard': '🌆'};
    return DeskCard(
      theme: theme,
      title: 'Open a Case',
      child: Column(
        children: [
          for (final spec in puzzleSpecs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  audio.click();
                  final locked = spec.id == 'hard' && !s.isPro;
                  if (locked) {
                    onPro();
                    return;
                  }
                  onPlay(spec.id);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black.withValues(alpha: 0.3),
                    border: Border.all(
                        color: theme.accent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Text(emojis[spec.id]!,
                          style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(spec.name,
                                style: Desk.body(16, theme: theme)),
                            Text(spec.tagline,
                                style: Desk.body(12,
                                    theme: theme,
                                    color: theme.paper
                                        .withValues(alpha: 0.65))),
                            Builder(builder: (_) {
                              final solved = switch (spec.id) {
                                'easy' => s.solvedEasy,
                                'medium' => s.solvedMedium,
                                'hard' => s.solvedHard,
                                _ => 0,
                              };
                              final best = switch (spec.id) {
                                'easy' => s.bestScoreEasy,
                                'medium' => s.bestScoreMedium,
                                'hard' => s.bestScoreHard,
                                _ => 0,
                              };
                              return solved > 0
                                  ? Text(
                                      'Solved: $solved   •   Best: $best',
                                      style: Desk.label(11,
                                          theme: theme,
                                          color: theme.accentLight
                                              .withValues(alpha: 0.8)),
                                    )
                                  : const SizedBox.shrink();
                            }),
                          ],
                        ),
                      ),
                      if (spec.id == 'hard' && !s.isPro)
                        Icon(Icons.lock,
                            color: theme.accentLight, size: 22)
                      else
                        const Text('▶️',
                            style: TextStyle(fontSize: 22)),
                    ],
                  ),
                ),
              ),
            ),
          if (!s.isPro)
            Text('🔒 Einstein Avenue (Hard) unlocks with PRO',
                style: Desk.label(12, theme: theme)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Theme + mark-style picker with PRO locks.
class _StyleCard extends StatelessWidget {
  final DetectiveThemeDef theme;
  final VoidCallback onPro;
  const _StyleCard({required this.theme, required this.onPro});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    final audio = screen.widget.audio;
    final isPro = s.isPro;
    return DeskCard(
      theme: theme,
      title: 'Office Style',
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final th in DetectiveThemes.all)
                _ThemeTile(
                  theme: theme,
                  th: th,
                  selected: s.themeId == th.id,
                  locked: DetectiveThemes.isProTheme(th.id) && !isPro,
                  onTap: () {
                    audio.click();
                    if (DetectiveThemes.isProTheme(th.id) && !isPro) {
                      onPro();
                      return;
                    }
                    s.setTheme(th.id);
                  },
                ),
              _ThemeTile(
                theme: theme,
                th: s.customTheme,
                selected: s.themeId == 'custom',
                locked: !isPro,
                custom: true,
                onTap: () {
                  audio.click();
                  if (!isPro) {
                    onPro();
                    return;
                  }
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CustomThemeScreen(
                      audio: audio,
                      settings: s,
                    ),
                  ));
                },
              ),
            ],
          ),
          if (!isPro)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '🔒 ${DetectiveThemes.all.length - DetectiveThemes.freeThemeIds.length} more themes in PRO',
                style: Desk.label(12, theme: theme),
              ),
            ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Stamp style:',
                style: Desk.body(15, theme: theme)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < MarkStyles.names.length; i++)
                _Chip(
                  theme: theme,
                  label:
                      '${MarkStyles.isPro(i) && !isPro ? '🔒 ' : ''}${MarkStyles.xGlyph(i)}${MarkStyles.oGlyph(i)} ${MarkStyles.names[i]}',
                  selected: s.markStyle == i,
                  onTap: () {
                    audio.click();
                    if (MarkStyles.isPro(i) && !isPro) {
                      onPro();
                      return;
                    }
                    s.setMarkStyle(i);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final DetectiveThemeDef theme;
  final DetectiveThemeDef th;
  final bool selected;
  final bool locked;
  final bool custom;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.theme,
    required this.th,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.custom = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: th.deskDeep.withValues(alpha: 0.7),
              border: Border.all(
                color: selected
                    ? th.accentLight
                    : th.accent.withValues(alpha: 0.35),
                width: selected ? 3 : 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: th.paper,
                          border: Border.all(color: th.accentLight),
                        )),
                    const SizedBox(width: 4),
                    Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: th.stamp,
                          border: Border.all(color: th.accentLight),
                        )),
                    const SizedBox(width: 4),
                    Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: th.accent,
                          border: Border.all(color: th.accentLight),
                        )),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  custom ? '🎨 My Creation' : th.name,
                  style: Desk.label(10, theme: th),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (locked)
            Container(
              width: 96,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withValues(alpha: 0.55),
              ),
              child: Icon(Icons.lock,
                  color: theme.accentLight, size: 22),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Rename the detective.
class _DetectiveCard extends StatelessWidget {
  final DetectiveThemeDef theme;
  const _DetectiveCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    return DeskCard(
      theme: theme,
      title: 'Your Detective',
      child: Column(
        children: [
          _NameField(
            theme: theme,
            initial: s.detectiveName,
            onDone: (v) {
              screen.widget.audio.click();
              s.setDetectiveName(v);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Your name is stamped on every solved case.',
            style: Desk.body(12,
                theme: theme,
                color: theme.paper.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  final DetectiveThemeDef theme;
  final String initial;
  final ValueChanged<String> onDone;
  const _NameField(
      {required this.theme, required this.initial, required this.onDone});

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _c;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
    _focus = FocusNode();
    // Commit (trim) when the field loses focus — the live save already
    // persisted every keystroke, so nothing is ever lost.
    _focus.addListener(() {
      if (!_focus.hasFocus) widget.onDone(_c.text);
    });
  }

  @override
  void didUpdateWidget(covariant _NameField old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial && _c.text != widget.initial) {
      _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.3),
        border:
            Border.all(color: widget.theme.accent.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: _c,
        focusNode: _focus,
        style: Desk.body(16, theme: widget.theme),
        maxLength: 16,
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          hintText: 'Detective name',
          hintStyle: Desk.body(14,
              theme: widget.theme,
              color: widget.theme.paper.withValues(alpha: 0.4)),
        ),
        // Save on EVERY keystroke (not just keyboard-done).
        onChanged: (v) {
          final screen = context.findAncestorStateOfType<_MenuScreenState>();
          screen?._s.setDetectiveNameLive(v);
        },
        onSubmitted: widget.onDone,
        onEditingComplete: () => widget.onDone(_c.text),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Tip jar (IAP).
class _SupportCard extends StatelessWidget {
  final DetectiveThemeDef theme;
  final StoreService store;
  const _SupportCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final audio = screen.widget.audio;
    return DeskCard(
      theme: theme,
      title: 'Support Wajiha',
      child: Column(
        children: [
          Text(
            'Logic Grid is 100% free. If it sharpened your mind, a small tip keeps the cases coming!',
            style: Desk.body(14, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Builder(builder: (_) {
            final tips = [
              store.coffeeProduct,
              store.chocolateProduct,
            ].whereType<ProductDetails>().toList();
            if (!store.storeReady) {
              return Text(
                store.error ?? 'Loading…',
                style: Desk.body(13,
                    theme: theme,
                    color: theme.paper.withValues(alpha: 0.6)),
                textAlign: TextAlign.center,
              );
            }
            if (tips.isEmpty) {
              return Text('Tips coming soon.',
                  style: Desk.body(13,
                      theme: theme,
                      color: theme.paper.withValues(alpha: 0.6)));
            }
            return Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  _Chip(
                    theme: theme,
                    label: p.id == StoreService.chocolateId
                        ? '🍫 ${p.price}'
                        : '☕ ${p.price}',
                    selected: false,
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _Chip extends StatelessWidget {
  final DetectiveThemeDef theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.theme,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? theme.accent.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected
                ? theme.accentLight
                : theme.accent.withValues(alpha: 0.5),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: Desk.label(13,
              theme: theme,
              color: selected ? theme.deskDeep : theme.paper),
        ),
      ),
    );
  }
}
