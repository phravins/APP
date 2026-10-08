import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum DeskArt { clear, documents, search, connection, attention }

/// Compact vector artwork stays crisp at every device density.
class DeskIllustration extends StatelessWidget {
  final DeskArt kind;
  final double size;
  final bool monochrome;
  const DeskIllustration({
    super.key,
    required this.kind,
    this.size = 96,
    this.monochrome = false,
  });
  @override
  Widget build(BuildContext context) {
    Widget art = SvgPicture.asset(
      'assets/illustrations/${kind.name}.svg',
      width: size,
      height: size,
    );
    if (monochrome) {
      art = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          .2126,
          .7152,
          .0722,
          0,
          0,
          .2126,
          .7152,
          .0722,
          0,
          0,
          .2126,
          .7152,
          .0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: art,
      );
    }
    return ExcludeSemantics(child: art);
  }
}

/// A centred, tinted rounded tile with the glyph in the accent colour.
/// The glyph is always 55% of the tile so icons look balanced at any size.
class IllustratedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IllustratedIcon({
    super.key,
    required this.icon,
    this.color = const Color(0xFF6C63FF),
    this.size = 40,
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? .22 : .12),
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(
        icon,
        size: size * .55,
        color: dark ? Color.lerp(color, Colors.white, .35) : color,
      ),
    );
  }
}
