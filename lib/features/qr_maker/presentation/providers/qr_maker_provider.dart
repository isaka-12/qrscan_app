import 'package:flutter/foundation.dart';

import '../../domain/entities/created_code.dart';
import '../../domain/repositories/created_code_repository.dart';

/// Holds the user's saved QR codes ("My codes").
class QrMakerProvider extends ChangeNotifier {
  final CreatedCodeRepository _repository;

  QrMakerProvider(this._repository) {
    load();
  }

  List<CreatedCode> _codes = [];
  bool _isLoading = false;
  String? _error;

  List<CreatedCode> get codes => List.unmodifiable(_codes);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _codes = await _repository.getAll();
      _error = null;
    } catch (e) {
      _error = 'Could not load your codes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves (inserts or updates) and returns the code with its id.
  Future<CreatedCode> save(CreatedCode code) async {
    final saved = await _repository.save(code);
    _codes = [saved, ..._codes.where((c) => c.id != saved.id)];
    notifyListeners();
    return saved;
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    _codes = _codes.where((c) => c.id != id).toList();
    notifyListeners();
  }
}
