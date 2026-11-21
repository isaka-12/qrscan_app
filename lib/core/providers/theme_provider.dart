import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light / dark / follow-the-phone theme, persisted.
class ThemeProvider extends ChangeNotifier {
  static const _kMode = 'themeMode';
  static const _kLegacyDark = 'isDarkMode'; // older builds stored a bool

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get themeMode => _mode;
  bool get isDarkMode => _mode == ThemeMode.dark;

  ThemeProvider() {
    _load();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMode, mode.name);
  }

  /// Switches between light and dark (kept for older call sites).
  void toggleTheme() =>
      setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kMode);
    if (saved != null) {
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.light,
      );
    } else {
      // Carry over the old light/dark switch.
      _mode = (prefs.getBool(_kLegacyDark) ?? false)
          ? ThemeMode.dark
          : ThemeMode.light;
    }
    notifyListeners();
  }
}
