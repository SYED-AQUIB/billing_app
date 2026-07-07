import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryRepository {
  Future<List<Category>> getAllCategories() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'categories',
      orderBy: 'name ASC',
    );

    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('categories', category.toMap());
  }

  Future<bool> categoryNameExists(String name, {int? excludeId}) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('categories', columns: ['id', 'name']);
    final normalizedName = name.trim().toLowerCase();

    return maps.any((map) {
      final existingName = (map['name'] as String? ?? '').trim().toLowerCase();
      final currentId = map['id'] as int?;
      return existingName == normalizedName && (excludeId == null || currentId != excludeId);
    });
  }

  Future<int> updateCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasProducts(int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE categoryId = ?',
      [categoryId],
    );
    final count = result.first['count'] as int;
    return count > 0;
  }
}
