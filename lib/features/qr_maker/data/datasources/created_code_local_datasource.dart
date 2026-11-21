import '../../../../core/database/database_helper.dart';
import '../models/created_code_model.dart';

class CreatedCodeLocalDataSource {
  final DatabaseHelper _databaseHelper;

  CreatedCodeLocalDataSource(this._databaseHelper);

  static const _table = 'created_codes';

  Future<List<CreatedCodeModel>> getAll() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(_table, orderBy: 'updated_at DESC');
    return maps.map(CreatedCodeModel.fromMap).toList();
  }

  Future<int> insert(CreatedCodeModel code) async {
    final db = await _databaseHelper.database;
    return db.insert(_table, code.toMap()..remove('id'));
  }

  Future<int> update(CreatedCodeModel code) async {
    final db = await _databaseHelper.database;
    return db.update(
      _table,
      code.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [code.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
