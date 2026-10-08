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

class IllustratedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IllustratedIcon({
    super.key,
    required this.icon,
    this.color = const Color(0xFF6C63FF),
    this.size = 36,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: size * .77,
            height: size * .77,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .24),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
        Icon(
          icon,
          size: size * .62,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ],
    ),
  );
}
