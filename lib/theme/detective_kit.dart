import 'package:flutter/material.dart';
import 'grid_themes.dart';

/// Shared pseudo-3D detective UI: leather desk backdrops, paper cards,
/// brass buttons, and typewriter-ish text styles. All widgets read colors
/// from the active [DetectiveThemeDef] — no hardcoded palette.
class Desk {
  static TextStyle display(double size, {required DetectiveThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: theme.paper,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.6),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      );

  static TextStyle label(double size,
          {required DetectiveThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme.accentLight,
        letterSpacing: 1.2,
      );

  static TextStyle body(double size,
          {required DetectiveThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? theme.paper,
        height: 1.35,
      );

  static TextStyle ink(double size, {required DetectiveThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: theme.ink,
        height: 1.35,
      );

  static ThemeData material(DetectiveThemeDef theme) {
    final scheme = ColorScheme.dark(
      primary: theme.accent,
      secondary: theme.accentLight,
      surface: theme.deskMid,
      onSurface: theme.paper,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: theme.deskDeep,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: theme.paper,
        elevation: 0,
      ),
      dialogBackgroundColor: theme.deskMid,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: theme.deskDeep,
        contentTextStyle: body(15, theme: theme),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Full-screen leather-desk backdrop with vignette and subtle grain lines.
class LeatherBackdrop extends StatelessWidget {
  final DetectiveThemeDef theme;
  final Widget child;
  const LeatherBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.deskMid, theme.deskDeep],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A sheet of case-file paper.
class PaperCard extends StatelessWidget {
  final DetectiveThemeDef theme;
  final Widget child;
  final EdgeInsets padding;
  const PaperCard({
    super.key,
    required this.theme,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.paper, theme.paperDark],
        ),
        border: Border.all(color: theme.accentDark, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A framed section on the desk (dark wood plaque with brass border).
class DeskCard extends StatelessWidget {
  final DetectiveThemeDef theme;
  final String title;
  final Widget child;
  const DeskCard(
      {super.key, required this.theme, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.deskMid.withValues(alpha: 0.92),
            theme.deskDeep.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: theme.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: Desk.display(20, theme: theme)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Brass desk button with press depth.
class DeskButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final DetectiveThemeDef theme;
  final double width;
  final double fontSize;
  final bool primary;
  const DeskButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.theme,
    this.width = 220,
    this.fontSize = 17,
    this.primary = true,
  });

  @override
  State<DeskButton> createState() => _DeskButtonState();
}

class _DeskButtonState extends State<DeskButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.primary
                ? [t.accentLight, t.accent, t.accentDark]
                : [t.deskMid, t.deskDeep],
          ),
          border: Border.all(
              color: widget.primary ? t.accentLight : t.accent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              offset: Offset(0, _pressed ? 1 : 5),
              blurRadius: _pressed ? 3 : 10,
            ),
          ],
        ),
        child: Text(
          widget.label,
          style: Desk.label(widget.fontSize,
              theme: t,
              color: widget.primary ? t.deskDeep : t.accentLight),
        ),
      ),
    );
  }
}

/// Wax-seal badge (circular, used for icons/counts).
class WaxSeal extends StatelessWidget {
  final DetectiveThemeDef theme;
  final Widget child;
  final double size;
  const WaxSeal(
      {super.key, required this.theme, required this.child, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 1.0,
          colors: [theme.stamp, theme.stamp.withValues(alpha: 0.75)],
        ),
        border: Border.all(
            color: theme.stamp.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: child,
    );
  }
}
