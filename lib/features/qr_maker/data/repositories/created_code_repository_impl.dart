import '../../domain/entities/created_code.dart';
import '../../domain/repositories/created_code_repository.dart';
import '../datasources/created_code_local_datasource.dart';
import '../models/created_code_model.dart';

class CreatedCodeRepositoryImpl implements CreatedCodeRepository {
  final CreatedCodeLocalDataSource _local;

  CreatedCodeRepositoryImpl(this._local);

  @override
  Future<List<CreatedCode>> getAll() => _local.getAll();

  @override
  Future<CreatedCode> save(CreatedCode code) async {
    final model = CreatedCodeModel.fromEntity(code);
    if (code.id == null) {
      final id = await _local.insert(model);
      return code.copyWith(id: id);
    }
    await _local.update(model);
    return code;
  }

  @override
  Future<void> delete(int id) => _local.delete(id);
}
