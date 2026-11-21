// How text is laid over a photo in a post.

enum PostBackdrop {
  none('Plain'),
  shade('Dim'),
  gradient('Fade'),
  box('Box');

  const PostBackdrop(this.label);
  final String label;
}

enum PostAlign { left, center, right }

/// Output shapes. [ratio] is width / height; 0 means "the photo's own".
enum PostAspect {
  square('Square', 1),
  portrait('Portrait 4:5', 4 / 5),
  story('Story 9:16', 9 / 16),
  original('Original', 0);

  const PostAspect(this.label, this.ratio);
  final String label;
  final double ratio;
}

class PostFont {
  final String label;

  /// Android font family; null = the app's default sans-serif.
  final String? family;

  const PostFont(this.label, this.family);

  static const presets = <PostFont>[
    PostFont('Sans', null),
    PostFont('Serif', 'serif'),
    PostFont('Condensed', 'sans-serif-condensed'),
    PostFont('Mono', 'monospace'),
    PostFont('Script', 'cursive'),
  ];
}

class PostStyle {
  final String text;
  final String author;
  final int font; // index into PostFont.presets
  /// Text size as a fraction of the canvas width (so previews and exports
  /// look identical at any resolution).
  final double scale;
  final int color;
  final PostAlign align;
  final bool bold;
  final PostBackdrop backdrop;
  final PostAspect aspect;

  /// Text position, 0..1 across and down the canvas.
  final double dx;
  final double dy;

  const PostStyle({
    this.text = '',
    this.author = '',
    this.font = 1,
    this.scale = 0.07,
    this.color = 0xFFFFFFFF,
    this.align = PostAlign.center,
    this.bold = true,
    this.backdrop = PostBackdrop.gradient,
    this.aspect = PostAspect.portrait,
    this.dx = 0.5,
    this.dy = 0.75,
  });

  static const minScale = 0.04;
  static const maxScale = 0.12;

  static const colorPresets = <int>[
    0xFFFFFFFF, // White
    0xFF1E1E1E, // Charcoal
    0xFFF3742D, // Locus orange
    0xFFFFD54F, // Warm yellow
    0xFF80DEEA, // Light cyan
    0xFFF48FB1, // Pink
    0xFFA5D6A7, // Mint
  ];

  PostFont get fontPreset => PostFont.presets[font];

  PostStyle copyWith({
    String? text,
    String? author,
    int? font,
    double? scale,
    int? color,
    PostAlign? align,
    bool? bold,
    PostBackdrop? backdrop,
    PostAspect? aspect,
    double? dx,
    double? dy,
  }) => PostStyle(
    text: text ?? this.text,
    author: author ?? this.author,
    font: font ?? this.font,
    scale: (scale ?? this.scale).clamp(minScale, maxScale),
    color: color ?? this.color,
    align: align ?? this.align,
    bold: bold ?? this.bold,
    backdrop: backdrop ?? this.backdrop,
    aspect: aspect ?? this.aspect,
    dx: (dx ?? this.dx).clamp(0.0, 1.0),
    dy: (dy ?? this.dy).clamp(0.0, 1.0),
  );

  /// Moves the text by a fraction of the canvas.
  PostStyle moved(double ddx, double ddy) =>
      copyWith(dx: dx + ddx, dy: dy + ddy);

  /// A stable fingerprint, used to tell whether the post changed since it
  /// was last saved.
  String get signature =>
      '$text|$author|$font|${scale.toStringAsFixed(3)}|$color|${align.name}|'
      '$bold|${backdrop.name}|${aspect.name}|'
      '${dx.toStringAsFixed(3)}|${dy.toStringAsFixed(3)}';
}
