import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/detective_kit.dart';
import '../theme/grid_themes.dart';

/// Settings: music/SFX toggles, volume, and about.
class SettingsScreen extends StatelessWidget {
  final DetectiveAudio audio;
  final DetectiveSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  DetectiveThemeDef get _t => settings.theme;

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
          title: Text('Settings', style: Desk.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  DeskCard(
                    theme: t,
                    title: 'Sound',
                    child: Column(
                      children: [
                        _ToggleRow(
                          theme: t,
                          label: '🎵  Music',
                          value: settings.musicOn,
                          onChanged: (v) {
                            audio.click();
                            settings.setMusic(v);
                            audio.configure(
                                musicOn: v,
                                sfxOn: settings.sfxOn,
                                volume: settings.volume);
                            if (v) {
                              audio.startMenuMusic();
                            } else {
                              audio.stopMusic();
                            }
                          },
                        ),
                        _ToggleRow(
                          theme: t,
                          label: '🔔  Sound effects',
                          value: settings.sfxOn,
                          onChanged: (v) {
                            settings.setSfx(v);
                            audio.configure(
                                musicOn: settings.musicOn,
                                sfxOn: v,
                                volume: settings.volume);
                            audio.click();
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('🔊  Volume',
                                style: Desk.body(15, theme: t)),
                            Expanded(
                              child: Slider(
                                value: settings.volume,
                                activeColor: t.accent,
                                inactiveColor: t.accent.withValues(alpha: 0.3),
                                onChanged: (v) {
                                  settings.setVolume(v);
                                  audio.configure(
                                      musicOn: settings.musicOn,
                                      sfxOn: settings.sfxOn,
                                      volume: v);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  DeskCard(
                    theme: t,
                    title: 'About',
                    child: Column(
                      children: [
                        Text(
                          'Logic Grid — the detective\'s case files. Crack Einstein-style logic puzzles with nothing but clues and deduction.',
                          style: Desk.body(14, theme: t),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/wajiha_logo.png',
                                width: 26, height: 26, fit: BoxFit.contain),
                            const SizedBox(width: 10),
                            Text('Made with ♥ by WAJIHA',
                                style: Desk.label(13, theme: t)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Version 2.0.0',
                            style: Desk.body(12,
                                theme: t,
                                color:
                                    t.paper.withValues(alpha: 0.55))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final DetectiveThemeDef theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.theme,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: Desk.body(15, theme: theme))),
          Switch(
            value: value,
            activeColor: theme.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
