import 'package:material_ui/material_ui.dart';

/// A labelled row of color swatches. Dots shrink (down to 32) so a whole
/// palette fits on one row; below that they wrap.
class ColorDotsPicker extends StatelessWidget {
  final String label;
  final List<int> presets;
  final int selected;
  final ValueChanged<int> onPick;

  const ColorDotsPicker({
    super.key,
    required this.label,
    required this.presets,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        // Dots shrink (down to 32) so a whole palette fits on one row;
        // below that they wrap.
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final fit =
                (constraints.maxWidth - gap * (presets.length - 1)) /
                presets.length;
            final dot = fit.clamp(32.0, 40.0);
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final c in presets)
                  Semantics(
                    button: true,
                    selected: c == selected,
                    label:
                        '$label #${(c & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onPick(c),
                      child: Container(
                        width: dot,
                        height: dot,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c == selected
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.5),
                            width: c == selected ? 3 : 1,
                          ),
                        ),
                        child: c == selected
                            ? Icon(
                                Icons.check,
                                size: dot / 2,
                                color: Color(c).computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
