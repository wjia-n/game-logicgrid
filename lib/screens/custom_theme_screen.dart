import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/detective_kit.dart';
import '../theme/grid_themes.dart';

/// Custom theme creator (PRO): pick every material color of the office.
class CustomThemeScreen extends StatelessWidget {
  final DetectiveAudio audio;
  final DetectiveSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  DetectiveThemeDef get _t => settings.theme;

  static const _labels = {
    'deskDark': 'Desk leather (dark)',
    'deskMid': 'Desk leather (mid)',
    'deskDeep': 'Desk shadow (deep)',
    'paper': 'Case paper',
    'paperDark': 'Paper shading',
    'ink': 'Ink',
    'accent': 'Brass accent',
    'accentLight': 'Brass highlight',
    'accentDark': 'Brass shadow',
    'stamp': 'Wax seal',
  };

  /// Curated physical-material swatches (no neon, no synthetic hues).
  static const _swatches = [
    0xFF3B2416, 0xFF5C3A21, 0xFF241309, 0xFF4A1F14, 0xFF6E2F1C,
    0xFF1A1A20, 0xFF2B2B33, 0xFF0E0E12, 0xFF1C2438, 0xFF2C3A55,
    0xFF1E3327, 0xFF2E4D3A, 0xFF3E1E26, 0xFF5C2E3A, 0xFF2A3320,
    0xFFF1E6C8, 0xFFE0CDA0, 0xFFF6EEDC, 0xFFE9E2D0, 0xFFEFE0BE,
    0xFF2E2118, 0xFF1C1C22, 0xFF3A2A18, 0xFF1E2A22, 0xFF33241A,
    0xFFC9A227, 0xFFE8CE7A, 0xFF8A6D1A, 0xFFD4AF37, 0xFFB8BCC8,
    0xFF9A6B2E, 0xFFD4A95C, 0xFFA8894E, 0xFF8C6A3E, 0xFF7FA8D8,
    0xFFA31621, 0xFF8E1B1B, 0xFF9C2B1E, 0xFFB01E28, 0xFF96321F,
  ];

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return LeatherBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('My Creation', style: Desk.display(22, theme: t)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                audio.click();
                settings.resetCustomColors();
              },
              child: Text('Reset', style: Desk.label(13, theme: t)),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  for (final key in _labels.keys)
                    _ColorRow(
                      theme: t,
                      label: _labels[key]!,
                      current: settings.customColors[key]!,
                      swatches: _swatches,
                      onPick: (argb) {
                        audio.click();
                        settings.setCustomColor(key, argb);
                        settings.setTheme('custom');
                      },
                    ),
                  const SizedBox(height: 16),
                  DeskButton(
                    label: '🎨  Use my creation',
                    width: 240,
                    theme: t,
                    onTap: () {
                      audio.click();
                      settings.setTheme('custom');
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final DetectiveThemeDef theme;
  final String label;
  final int current;
  final List<int> swatches;
  final ValueChanged<int> onPick;
  const _ColorRow({
    required this.theme,
    required this.label,
    required this.current,
    required this.swatches,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: theme.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Color(current),
                  border: Border.all(color: theme.accentLight, width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Text(label, style: Desk.body(14, theme: theme)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in swatches)
                GestureDetector(
                  onTap: () => onPick(s),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Color(s),
                      border: Border.all(
                        color: s == current
                            ? theme.accentLight
                            : Colors.black.withValues(alpha: 0.4),
                        width: s == current ? 3 : 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
