import '../database/database_helper.dart';
import '../models/shop_settings.dart';

class ShopSettingsRepository {
  Future<ShopSettings?> getSettings() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('shop_settings', limit: 1, orderBy: 'id DESC');
    if (maps.isEmpty) {
      return null;
    }
    return ShopSettings.fromMap(maps.first);
  }

  Future<int> insertSettings(ShopSettings settings) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('shop_settings', settings.toMap());
  }

  Future<int> updateSettings(ShopSettings settings) async {
    final db = await DatabaseHelper.instance.database;
    return db.update('shop_settings', settings.toMap(), where: 'id = ?', whereArgs: [settings.id]);
  }

  Future<int> upsertSettings(ShopSettings settings) async {
    final existing = await getSettings();
    if (existing == null) {
      return insertSettings(settings);
    }
    return updateSettings(settings.copyWith(id: existing.id));
  }
}
