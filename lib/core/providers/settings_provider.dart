import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences for scanning, persisted with SharedPreferences.
class SettingsProvider extends ChangeNotifier {
  static const _kSaveScans = 'settings.saveScans';
  static const _kSaveLocation = 'settings.saveLocation';
  static const _kVibrate = 'settings.vibrateOnScan';

  bool _saveScans = true;
  bool _saveLocation = true;
  bool _vibrate = true;

  SettingsProvider() {
    _load();
  }

  /// Keep scanned codes in the Scans list. When off, a scan is shown once
  /// and then forgotten.
  bool get saveScans => _saveScans;

  /// Store where each code was scanned (asks for location permission).
  bool get saveLocation => _saveLocation;

  /// Buzz when a code is read.
  bool get vibrate => _vibrate;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _saveScans = prefs.getBool(_kSaveScans) ?? true;
    _saveLocation = prefs.getBool(_kSaveLocation) ?? true;
    _vibrate = prefs.getBool(_kVibrate) ?? true;
    notifyListeners();
  }

  Future<void> _set(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  set saveScans(bool v) {
    _saveScans = v;
    notifyListeners();
    _set(_kSaveScans, v);
  }

  set saveLocation(bool v) {
    _saveLocation = v;
    notifyListeners();
    _set(_kSaveLocation, v);
  }

  set vibrate(bool v) {
    _vibrate = v;
    notifyListeners();
    _set(_kVibrate, v);
  }
}
