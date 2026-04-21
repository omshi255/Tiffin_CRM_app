import 'package:flutter/material.dart';

/// [tiffin_logo.png] includes a lot of empty padding around the mark.
/// This widget scales the artwork up and clips so the icon fills the box
/// (a mild “zoom” on the content rather than shrinking the full asset).
class TiffinLogoMark extends StatelessWidget {
  const TiffinLogoMark({
    super.key,
    required this.size,
    this.borderRadius = 12,
    /// Values ~1.9–2.4 work well for the current asset; tweak if the PNG changes.
    this.contentScale = 2.15,
  });

  final double size;
  final double borderRadius;
  final double contentScale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size,
        height: size,
        child: Transform.scale(
          scale: contentScale,
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/tiffin_logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
