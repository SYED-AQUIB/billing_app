import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/product.dart';

class ProductRepository {
  Future<List<Product>> getAllProducts() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'products',
      orderBy: 'name ASC',
    );

    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<int>> getQuickPickProductIds() async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'quick_pick_products',
      columns: ['product_id'],
      orderBy: 'position ASC',
    );

    return rows.map((row) => row['product_id'] as int).toList();
  }

  Future<bool> addQuickPick(int productId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final maxPositionResult = await db.rawQuery(
        'SELECT MAX(position) AS max_position '
        'FROM quick_pick_products',
      );

      final maxPosition =
          (maxPositionResult.first['max_position'] as int?) ?? -1;

      await db.insert(
        'quick_pick_products',
        {
          'product_id': productId,
          'position': maxPosition + 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeQuickPick(int productId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      await db.delete(
        'quick_pick_products',
        where: 'product_id = ?',
        whereArgs: [productId],
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await DatabaseHelper.instance.database;
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return getAllProducts();
    }

    final maps = await db.query(
      'products',
      where: 'name LIKE ? OR brand LIKE ?',
      whereArgs: ['%$normalizedQuery%', '%$normalizedQuery%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('products', product.toMap());
  }

  Future<bool> productExists({
    required int categoryId,
    required String brand,
    required String name,
    int? excludeId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'products',
      columns: ['id', 'categoryId', 'brand', 'name'],
    );

    final normalizedBrand = brand.trim().toLowerCase();
    final normalizedName = name.trim().toLowerCase();

    return maps.any((map) {
      final currentId = map['id'] as int?;
      final currentCategoryId = map['categoryId'] as int;
      final currentBrand =
          (map['brand'] as String? ?? '').trim().toLowerCase();
      final currentName =
          (map['name'] as String? ?? '').trim().toLowerCase();

      return currentCategoryId == categoryId &&
          currentBrand == normalizedBrand &&
          currentName == normalizedName &&
          (excludeId == null || currentId != excludeId);
    });
  }

  Future<int> updateProduct(Product product) async {
    final db = await DatabaseHelper.instance.database;

    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await DatabaseHelper.instance.database;

    return db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}