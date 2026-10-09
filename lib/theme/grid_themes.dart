import 'package:flutter/material.dart';

/// Theme, mark-style catalog for Logic Grid.
///
/// Every theme stays inside the detective-noir material world: worn leather,
/// dark wood, brass/copper/silver, aged paper, ink, red wax seals. Variety
/// comes from different leathers, woods, metals, papers and ink tones —
/// never neon, never cyberpunk.
class DetectiveThemeDef {
  final String id;
  final String name;
  final Color deskDark;
  final Color deskMid;
  final Color deskDeep;
  final Color paper;
  final Color paperDark;
  final Color ink;
  final Color accent; // brass / copper / silver …
  final Color accentLight;
  final Color accentDark;
  final Color stamp; // wax seal red

  const DetectiveThemeDef({
    required this.id,
    required this.name,
    required this.deskDark,
    required this.deskMid,
    required this.deskDeep,
    required this.paper,
    required this.paperDark,
    required this.ink,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.stamp,
  });
}

class DetectiveThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'noir',
    'parchment',
    'emerald',
  ];

  static bool isProTheme(String id) => !freeThemeIds.contains(id);

  static const List<DetectiveThemeDef> all = [
    DetectiveThemeDef(
      id: 'classic',
      name: "Detective's Desk",
      deskDark: Color(0xFF3B2416),
      deskMid: Color(0xFF5C3A21),
      deskDeep: Color(0xFF241309),
      paper: Color(0xFFF1E6C8),
      paperDark: Color(0xFFE0CDA0),
      ink: Color(0xFF2E2118),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      stamp: Color(0xFFA31621),
    ),
    DetectiveThemeDef(
      id: 'noir',
      name: 'Noir Office',
      deskDark: Color(0xFF1A1A20),
      deskMid: Color(0xFF2B2B33),
      deskDeep: Color(0xFF0E0E12),
      paper: Color(0xFFE8E4DA),
      paperDark: Color(0xFFCFC8B8),
      ink: Color(0xFF1C1C22),
      accent: Color(0xFFB8BCC8),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      stamp: Color(0xFF8E1B1B),
    ),
    DetectiveThemeDef(
      id: 'parchment',
      name: 'Aged Parchment',
      deskDark: Color(0xFF4A3520),
      deskMid: Color(0xFF6B4E2E),
      deskDeep: Color(0xFF2E2013),
      paper: Color(0xFFF6EEDC),
      paperDark: Color(0xFFE4D3AC),
      ink: Color(0xFF3A2A18),
      accent: Color(0xFF9A6B2E),
      accentLight: Color(0xFFD4A95C),
      accentDark: Color(0xFF6E4A1E),
      stamp: Color(0xFF9C2B1E),
    ),
    DetectiveThemeDef(
      id: 'emerald',
      name: 'Emerald Club',
      deskDark: Color(0xFF1E3327),
      deskMid: Color(0xFF2E4D3A),
      deskDeep: Color(0xFF122019),
      paper: Color(0xFFF0E8D0),
      paperDark: Color(0xFFDCCFA8),
      ink: Color(0xFF1E2A22),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      stamp: Color(0xFFA31621),
    ),
    DetectiveThemeDef(
      id: 'mahogany',
      name: 'Royal Mahogany',
      deskDark: Color(0xFF4A1F14),
      deskMid: Color(0xFF6E2F1C),
      deskDeep: Color(0xFF2B1009),
      paper: Color(0xFFF3E9D2),
      paperDark: Color(0xFFE2D0A6),
      ink: Color(0xFF2E1A10),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      stamp: Color(0xFFB01E28),
    ),
    DetectiveThemeDef(
      id: 'midnight',
      name: 'Midnight Archive',
      deskDark: Color(0xFF1C2438),
      deskMid: Color(0xFF2C3A55),
      deskDeep: Color(0xFF101624),
      paper: Color(0xFFE9E2D0),
      paperDark: Color(0xFFCFC2A0),
      ink: Color(0xFF1A2030),
      accent: Color(0xFF8FA3C8),
      accentLight: Color(0xFFC4D2EE),
      accentDark: Color(0xFF5A6E96),
      stamp: Color(0xFF93302A),
    ),
    DetectiveThemeDef(
      id: 'sepia',
      name: 'Sepia Files',
      deskDark: Color(0xFF3D2E1C),
      deskMid: Color(0xFF5C452A),
      deskDeep: Color(0xFF241A0E),
      paper: Color(0xFFEFE0BE),
      paperDark: Color(0xFFD8BE92),
      ink: Color(0xFF33241A),
      accent: Color(0xFF8C6A3E),
      accentLight: Color(0xFFC8A468),
      accentDark: Color(0xFF5E4426),
      stamp: Color(0xFF8E3B22),
    ),
    DetectiveThemeDef(
      id: 'cobalt',
      name: 'Cobalt Precinct',
      deskDark: Color(0xFF1E2C4E),
      deskMid: Color(0xFF2E426E),
      deskDeep: Color(0xFF121B33),
      paper: Color(0xFFECE7D6),
      paperDark: Color(0xFFD2C8AC),
      ink: Color(0xFF1C2438),
      accent: Color(0xFF7FA8D8),
      accentLight: Color(0xFFB4CDEE),
      accentDark: Color(0xFF4E6E9E),
      stamp: Color(0xFFA31621),
    ),
    DetectiveThemeDef(
      id: 'burgundy',
      name: 'Burgundy Lounge',
      deskDark: Color(0xFF3E1E26),
      deskMid: Color(0xFF5C2E3A),
      deskDeep: Color(0xFF241014),
      paper: Color(0xFFF0E6CC),
      paperDark: Color(0xFFDECDA0),
      ink: Color(0xFF2C1A1E),
      accent: Color(0xFFC9963E),
      accentLight: Color(0xFFE8BE6E),
      accentDark: Color(0xFF8A6428),
      stamp: Color(0xFF9C1F2E),
    ),
    DetectiveThemeDef(
      id: 'forest',
      name: 'Forest Lodge',
      deskDark: Color(0xFF2A3320),
      deskMid: Color(0xFF42502F),
      deskDeep: Color(0xFF181D12),
      paper: Color(0xFFF1E9D2),
      paperDark: Color(0xFFDFD0A6),
      ink: Color(0xFF232A1A),
      accent: Color(0xFFA8894E),
      accentLight: Color(0xFFD4B478),
      accentDark: Color(0xFF74602F),
      stamp: Color(0xFF96321F),
    ),
    DetectiveThemeDef(
      id: 'desert',
      name: 'Desert Dossier',
      deskDark: Color(0xFF4E3A22),
      deskMid: Color(0xFF705632),
      deskDeep: Color(0xFF2E2214),
      paper: Color(0xFFF6ECD4),
      paperDark: Color(0xFFE6D2A4),
      ink: Color(0xFF3A2C1A),
      accent: Color(0xFFB08A3E),
      accentLight: Color(0xFFDDB96E),
      accentDark: Color(0xFF7C5F28),
      stamp: Color(0xFFA63A1E),
    ),
    DetectiveThemeDef(
      id: 'harbor',
      name: 'Harbor Bureau',
      deskDark: Color(0xFF22333E),
      deskMid: Color(0xFF354E5E),
      deskDeep: Color(0xFF142028),
      paper: Color(0xFFEEE8D4),
      paperDark: Color(0xFFD4C8A8),
      ink: Color(0xFF1E2A32),
      accent: Color(0xFF9FB4A8),
      accentLight: Color(0xFFC8D8CC),
      accentDark: Color(0xFF6A7E72),
      stamp: Color(0xFF9C2B2B),
    ),
    DetectiveThemeDef(
      id: 'library',
      name: 'Royal Library',
      deskDark: Color(0xFF33241A),
      deskMid: Color(0xFF4E3826),
      deskDeep: Color(0xFF1E140C),
      paper: Color(0xFFF2E8CE),
      paperDark: Color(0xFFE0CCA2),
      ink: Color(0xFF2A2014),
      accent: Color(0xFFB4943E),
      accentLight: Color(0xFFDCC06E),
      accentDark: Color(0xFF7E6428),
      stamp: Color(0xFF8E2418),
    ),
    DetectiveThemeDef(
      id: 'coffeehouse',
      name: 'Coffee House',
      deskDark: Color(0xFF2E2018),
      deskMid: Color(0xFF463026),
      deskDeep: Color(0xFF1A120C),
      paper: Color(0xFFF0E4C8),
      paperDark: Color(0xFFDCC89E),
      ink: Color(0xFF2A1E14),
      accent: Color(0xFFA87B4E),
      accentLight: Color(0xFFD4A878),
      accentDark: Color(0xFF74522F),
      stamp: Color(0xFF99331F),
    ),
    DetectiveThemeDef(
      id: 'clockwork',
      name: 'Clockwork Study',
      deskDark: Color(0xFF3A2E1E),
      deskMid: Color(0xFF56432C),
      deskDeep: Color(0xFF221A0E),
      paper: Color(0xFFEEE2C4),
      paperDark: Color(0xFFD8C49A),
      ink: Color(0xFF2E2414),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFF0D878),
      accentDark: Color(0xFF8A6D1A),
      stamp: Color(0xFFA62B1A),
    ),
    DetectiveThemeDef(
      id: 'cinema',
      name: 'Vintage Cinema',
      deskDark: Color(0xFF2A1E2E),
      deskMid: Color(0xFF423046),
      deskDeep: Color(0xFF181220),
      paper: Color(0xFFF0E6CC),
      paperDark: Color(0xFFDCCDA0),
      ink: Color(0xFF2A1E2E),
      accent: Color(0xFFC9A24E),
      accentLight: Color(0xFFE8C878),
      accentDark: Color(0xFF8A6E2F),
      stamp: Color(0xFF9C2B30),
    ),
  ];

  static DetectiveThemeDef byId(String id, {DetectiveThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

/// Mark styles: how X and O stamps look on the grid. First 4 free, last 4 PRO.
class MarkStyles {
  static const List<String> names = [
    'Classic',
    'Wax Seal',
    'Chalk',
    'Ink Pen',
    'Typewriter',
    'Quill',
    'Stamp Pad',
    'Star Sleuth',
  ];

  /// Glyph pair (x, o) per style.
  static const List<List<String>> glyphs = [
    ['✕', '✓'],
    ['✖', '✔'],
    ['+', '◆'],
    ['×', '●'],
    ['x', '■'],
    ['✗', '▲'],
    ['✘', '⬤'],
    ['?', '★'],
  ];

  static bool isPro(int i) => i >= 4;

  static String xGlyph(int i) => glyphs[i.clamp(0, 7)][0];
  static String oGlyph(int i) => glyphs[i.clamp(0, 7)][1];
}
