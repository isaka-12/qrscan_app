import 'package:material_ui/material_ui.dart';

import '../../domain/post_style.dart';

/// The photo with text laid over it. Everything is sized relative to the
/// canvas width, so the on-screen preview and the 1080px export match.
/// Drag the text to move it.
class PostCanvas extends StatelessWidget {
  final ImageProvider image;

  /// Width / height of the canvas.
  final double aspectRatio;
  final PostStyle style;

  /// Called with the drag distance as a fraction of the canvas size.
  final void Function(double ddx, double ddy)? onMoveText;

  const PostCanvas({
    super.key,
    required this.image,
    required this.aspectRatio,
    required this.style,
    this.onMoveText,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          final fontSize = style.scale * w;
          final color = Color(style.color);
          final textAlign = switch (style.align) {
            PostAlign.left => TextAlign.left,
            PostAlign.center => TextAlign.center,
            PostAlign.right => TextAlign.right,
          };
          final cross = switch (style.align) {
            PostAlign.left => CrossAxisAlignment.start,
            PostAlign.center => CrossAxisAlignment.center,
            PostAlign.right => CrossAxisAlignment.end,
          };
          // A soft shadow keeps text readable on busy photos.
          final shadows = style.backdrop == PostBackdrop.box
              ? null
              : [
                  Shadow(
                    blurRadius: fontSize * 0.35,
                    color: Colors.black.withValues(
                      alpha: color.computeLuminance() > 0.5 ? 0.55 : 0.0,
                    ),
                  ),
                ];

          final hasText = style.text.trim().isNotEmpty;
          final hasAuthor = style.author.trim().isNotEmpty;

          Widget text = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: cross,
            children: [
              Text(
                hasText ? style.text.trim() : 'Your text here',
                textAlign: textAlign,
                // Don't let the system font size change the artwork.
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: style.fontPreset.family,
                  fontSize: fontSize,
                  height: 1.25,
                  fontWeight: style.bold ? FontWeight.w700 : FontWeight.w400,
                  color: hasText ? color : color.withValues(alpha: 0.5),
                  shadows: shadows,
                ),
              ),
              if (hasAuthor) ...[
                SizedBox(height: fontSize * 0.45),
                Text(
                  '— ${style.author.trim()}',
                  textAlign: textAlign,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontFamily: style.fontPreset.family,
                    fontSize: fontSize * 0.55,
                    fontStyle: FontStyle.italic,
                    color: color.withValues(alpha: 0.9),
                    shadows: shadows,
                  ),
                ),
              ],
            ],
          );

          if (style.backdrop == PostBackdrop.box) {
            text = DecoratedBox(
              decoration: BoxDecoration(
                color:
                    (color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)
                        .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(fontSize * 0.45),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: fontSize * 0.7,
                  vertical: fontSize * 0.5,
                ),
                child: text,
              ),
            );
          }

          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(image: image, fit: BoxFit.cover, gaplessPlayback: true),
                if (style.backdrop == PostBackdrop.shade)
                  const ColoredBox(color: Color(0x59000000)),
                if (style.backdrop == PostBackdrop.gradient)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xC0000000), Color(0x00000000)],
                        stops: [0.0, 0.65],
                      ),
                    ),
                  ),
                Align(
                  // Alignment keeps the text block fully inside the canvas.
                  alignment: Alignment(style.dx * 2 - 1, style.dy * 2 - 1),
                  child: Padding(
                    padding: EdgeInsets.all(w * 0.06),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: onMoveText == null
                          ? null
                          : (d) => onMoveText!(
                              d.delta.dx / (w * 0.6),
                              d.delta.dy / (h * 0.6),
                            ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w * 0.84),
                        child: text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
