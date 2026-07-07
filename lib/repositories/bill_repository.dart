import '../database/database_helper.dart';
import '../models/bill_item_model.dart';
import '../models/bill_model.dart';

class BillRepository {
  Future<String> getNextBillNumber() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(MAX(CAST(SUBSTR(billNumber, 2) AS INTEGER)), 0) as nextNumber FROM bills',
    );
    final current = result.first['nextNumber'] as int;
    return 'B${(current + 1).toString().padLeft(5, '0')}';
  }

  Future<int> insertBill(BillModel bill) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('bills', bill.toMap());
  }

  Future<int> insertBillItem(BillItemModel item) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('billItems', item.toMap());
  }

  Future<int> saveBillWithItems({required BillModel bill, required List<BillItemModel> items}) async {
    final db = await DatabaseHelper.instance.database;
    return db.transaction((txn) async {
      final billId = await txn.insert('bills', bill.toMap());
      for (final item in items) {
        await txn.insert('billItems', item.copyWith(billId: billId).toMap());
      }
      return billId;
    });
  }

  Future<List<BillModel>> getAllBills() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('bills', orderBy: 'createdAt DESC');
    return maps.map(BillModel.fromMap).toList();
  }

  Future<List<BillModel>> searchBills(String query) async {
    final db = await DatabaseHelper.instance.database;
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return getAllBills();
    }

    final maps = await db.query(
      'bills',
      where: 'billNumber LIKE ? OR customerName LIKE ? OR customerPhone LIKE ?',
      whereArgs: ['%$normalizedQuery%', '%$normalizedQuery%', '%$normalizedQuery%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map(BillModel.fromMap).toList();
  }

  Future<List<BillModel>> filterBillsByDateRange(DateTime start, DateTime end) async {
    final db = await DatabaseHelper.instance.database;
    final startIso = DateTime(start.year, start.month, start.day).toIso8601String();
    final endIso = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();
    final maps = await db.query(
      'bills',
      where: 'createdAt >= ? AND createdAt <= ?',
      whereArgs: [startIso, endIso],
      orderBy: 'createdAt DESC',
    );
    return maps.map(BillModel.fromMap).toList();
  }

  Future<List<BillItemModel>> getBillItems(int billId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('billItems', where: 'billId = ?', whereArgs: [billId]);
    return maps.map(BillItemModel.fromMap).toList();
  }

  Future<BillModel?> getBillById(int billId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('bills', where: 'id = ?', whereArgs: [billId], limit: 1);
    if (maps.isEmpty) {
      return null;
    }
    return BillModel.fromMap(maps.first);
  }

  Future<int> getBillItemCount(int billId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM billItems WHERE billId = ?', [billId]);
    return (result.first['count'] as int?) ?? 0;
  }

  Future<bool> deleteBill(int billId) async {
    final db = await DatabaseHelper.instance.database;
    final deleted = await db.transaction((txn) async {
      await txn.delete('billItems', where: 'billId = ?', whereArgs: [billId]);
      final count = await txn.delete('bills', where: 'id = ?', whereArgs: [billId]);
      return count > 0;
    });
    return deleted;
  }
}
