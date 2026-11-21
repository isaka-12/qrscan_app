import 'dart:math' as math;

/// How a created QR code looks. Colors are stored as ARGB ints so the domain
/// layer stays free of Flutter types.
class QrStyle {
  final int foreground;
  final int background;
  final bool roundDots;
  final bool roundEyes;
  final String caption;

  const QrStyle({
    this.foreground = 0xFF000000,
    this.background = 0xFFFFFFFF,
    this.roundDots = false,
    this.roundEyes = false,
    this.caption = '',
  });

  static const foregroundPresets = <int>[
    0xFF000000, // Black
    0xFF1E1E1E, // Charcoal
    0xFFF3742D, // Locus orange
    0xFF1A237E, // Navy
    0xFF1B5E20, // Green
    0xFF4A148C, // Purple
    0xFFB71C1C, // Red
  ];

  static const backgroundPresets = <int>[
    0xFFFFFFFF, // White
    0xFFFFF8E1, // Cream
    0xFFF5F5F5, // Light gray
    0xFFFFF3E0, // Light orange
    0xFFE3F2FD, // Light blue
    0xFF1E1E1E, // Charcoal (inverted: triggers a warning)
  ];

  QrStyle copyWith({
    int? foreground,
    int? background,
    bool? roundDots,
    bool? roundEyes,
    String? caption,
  }) => QrStyle(
    foreground: foreground ?? this.foreground,
    background: background ?? this.background,
    roundDots: roundDots ?? this.roundDots,
    roundEyes: roundEyes ?? this.roundEyes,
    caption: caption ?? this.caption,
  );

  /// A warning when the colors may stop scanners reading the code, else null.
  String? get scanWarning {
    final fg = _luminance(foreground);
    final bg = _luminance(background);
    if (fg > bg) {
      return 'Light code on a dark background: many scanners can\'t read '
          'inverted codes. Use a darker code color.';
    }
    final ratio = (bg + 0.05) / (fg + 0.05);
    if (ratio < 3) {
      return 'Low contrast: the code may not scan. Pick a darker code color '
          'or a lighter background.';
    }
    return null;
  }

  // WCAG relative luminance of an ARGB color.
  static double _luminance(int argb) {
    double channel(int c) {
      final s = c / 255;
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4) * 1.0;
    }

    return 0.2126 * channel((argb >> 16) & 0xFF) +
        0.7152 * channel((argb >> 8) & 0xFF) +
        0.0722 * channel(argb & 0xFF);
  }

  Map<String, dynamic> toJson() => {
    'foreground': foreground,
    'background': background,
    'roundDots': roundDots,
    'roundEyes': roundEyes,
    'caption': caption,
  };

  factory QrStyle.fromJson(Map<String, dynamic> json) => QrStyle(
    foreground: json['foreground'] as int? ?? 0xFF000000,
    background: json['background'] as int? ?? 0xFFFFFFFF,
    roundDots: json['roundDots'] as bool? ?? false,
    roundEyes: json['roundEyes'] as bool? ?? false,
    caption: json['caption'] as String? ?? '',
  );
}
