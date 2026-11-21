import '../entities/created_code.dart';

abstract class CreatedCodeRepository {
  Future<List<CreatedCode>> getAll();

  /// Inserts a new code (no id) or updates an existing one; returns it with its id.
  Future<CreatedCode> save(CreatedCode code);

  Future<void> delete(int id);
}
