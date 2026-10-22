import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class ArchClipper extends CustomClipper<Path> {
  const ArchClipper({this.top = 100, this.bottom = 20});
  final double top, bottom;
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, top)
    ..quadraticBezierTo(0, 0, top, 0)
    ..lineTo(s.width - top, 0)
    ..quadraticBezierTo(s.width, 0, s.width, top)
    ..lineTo(s.width, s.height - bottom)
    ..quadraticBezierTo(s.width, s.height, s.width - bottom, s.height)
    ..lineTo(bottom, s.height)
    ..quadraticBezierTo(0, s.height, 0, s.height - bottom)
    ..close();
  @override
  bool shouldReclip(covariant ArchClipper old) =>
      old.top != top || old.bottom != bottom;
}

class ArchContainer extends StatelessWidget {
  const ArchContainer({
    required this.child,
    this.color = Palette.cream,
    this.borderColor,
    this.top = 100,
    this.bottom = 20,
    this.borderWidth = 1,
    super.key,
  });
  final Widget child;
  final Color color;
  final Color? borderColor;
  final double top, bottom, borderWidth;
  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: ArchClipper(top: top, bottom: bottom),
    child: Container(
      decoration: BoxDecoration(
        color: color,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
      ),
      child: child,
    ),
  );
}

class GoldButton extends StatelessWidget {
  const GoldButton({
    required this.label,
    required this.onPressed,
    this.dark = false,
    this.height = 52,
    super.key,
  });
  final String label;
  final VoidCallback onPressed;
  final bool dark;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: dark ? Palette.navy : Palette.gold,
        foregroundColor: dark ? Palette.gold : Palette.navy,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      child: Text(label),
    ),
  );
}

class CreamPill extends StatelessWidget {
  const CreamPill({
    required this.child,
    this.height = 54,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    super.key,
  });
  final Widget child;
  final double height;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: padding,
    decoration: const BoxDecoration(
      color: Palette.cream,
      borderRadius: BorderRadius.all(Radius.circular(30)),
    ),
    child: child,
  );
}

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({this.selected = 0, super.key});
  final int selected;
  @override
  Widget build(BuildContext context) {
    const labels = ['Home', 'Search', 'Bookings', 'Saved', 'Profile'];
    const icons = [
      Icons.home_outlined,
      Icons.search,
      Icons.calendar_month_outlined,
      Icons.favorite_border,
      Icons.person_outline,
    ];
    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Palette.cream,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          5,
          (i) => InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => context.go(
              i == 0
                  ? '/home'
                  : i == 4
                  ? '/profile'
                  : '/coming/${labels[i]}',
            ),
            child: SizedBox(
              width: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? Palette.gold : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icons[i], size: 21, color: Palette.navy),
                  ),
                  if (i == selected)
                    Text(
                      labels[i],
                      style: const TextStyle(
                        fontSize: 9,
                        color: Palette.navy,
                        fontWeight: FontWeight.w700,
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

TextStyle serif(
  double size, {
  Color color = Palette.cream,
  bool italic = false,
}) => GoogleFonts.playfairDisplay(
  fontSize: size,
  height: 1.1,
  color: color,
  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
);
