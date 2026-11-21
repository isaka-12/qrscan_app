/// A short quote or proverb to put on a photo. All entries are public-domain
/// sayings (classical authors and traditional proverbs).
class Quote {
  final String text;
  final String author;
  final String category;

  const Quote(this.text, this.author, this.category);

  static const categories = ['Motivation', 'Wisdom', 'Proverbs', 'Life'];

  static const all = <Quote>[
    // Motivation
    Quote('Well begun is half done.', 'Aristotle', 'Motivation'),
    Quote('Fortune favors the bold.', 'Latin proverb', 'Motivation'),
    Quote(
      'It does not matter how slowly you go as long as you do not stop.',
      'Confucius',
      'Motivation',
    ),
    Quote(
      'The journey of a thousand miles begins with a single step.',
      'Lao Tzu',
      'Motivation',
    ),
    Quote(
      'Act as if what you do makes a difference. It does.',
      'William James',
      'Motivation',
    ),
    Quote('The best way out is always through.', 'Robert Frost', 'Motivation'),
    // Wisdom
    Quote(
      'Waste no more time arguing what a good man should be. Be one.',
      'Marcus Aurelius',
      'Wisdom',
    ),
    Quote(
      'Luck is what happens when preparation meets opportunity.',
      'Seneca',
      'Wisdom',
    ),
    Quote(
      'Knowing yourself is the beginning of all wisdom.',
      'Aristotle',
      'Wisdom',
    ),
    Quote(
      'He who has a why to live can bear almost any how.',
      'Friedrich Nietzsche',
      'Wisdom',
    ),
    Quote(
      'This above all: to thine own self be true.',
      'William Shakespeare',
      'Wisdom',
    ),
    // Proverbs
    Quote(
      'Haba na haba hujaza kibaba.\n(Little by little fills the measure.)',
      'Swahili proverb',
      'Proverbs',
    ),
    Quote(
      'Haraka haraka haina baraka.\n(Hurry, hurry has no blessing.)',
      'Swahili proverb',
      'Proverbs',
    ),
    Quote(
      'If you want to go fast, go alone. If you want to go far, go together.',
      'African proverb',
      'Proverbs',
    ),
    Quote(
      'When the roots are deep, there is no reason to fear the wind.',
      'African proverb',
      'Proverbs',
    ),
    Quote(
      'A smooth sea never made a skilled sailor.',
      'English proverb',
      'Proverbs',
    ),
    // Life
    Quote('Wherever you go, go with all your heart.', 'Confucius', 'Life'),
    Quote('Hope is the thing with feathers.', 'Emily Dickinson', 'Life'),
    Quote('What we think, we become.', 'Buddha', 'Life'),
    Quote('Nothing will come of nothing.', 'William Shakespeare', 'Life'),
  ];
}
