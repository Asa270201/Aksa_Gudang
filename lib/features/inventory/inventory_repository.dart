// lib/features/inventory/inventory_repository.dart

import '../../core/database/database_helper.dart';
import '../../models/inventory_item.dart';

class InventoryRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Tambah Barang
  Future<int> addItem(InventoryItem item) async {
    final db = await _databaseHelper.database;

    return await db.insert('items', item.toMap());
  }

  /// Ambil Semua Barang
  Future<List<InventoryItem>> getAllItems() async {
    final db = await _databaseHelper.database;

    final result = await db.query('items', orderBy: 'id DESC');

    return result.map((map) => InventoryItem.fromMap(map)).toList();
  }

  /// Ambil Barang Berdasarkan ID
  Future<InventoryItem?> getItemById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return InventoryItem.fromMap(result.first);
  }

  /// Cari Barang
  Future<List<InventoryItem>> searchItems(String keyword) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'items',
      where: '''
        nama LIKE ?
        OR kode LIKE ?
      ''',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'nama ASC',
    );

    return result.map((map) => InventoryItem.fromMap(map)).toList();
  }

  /// Filter Kategori
  Future<List<InventoryItem>> getItemsByCategory(String kategori) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'items',
      where: 'kategori = ?',
      whereArgs: [kategori],
      orderBy: 'nama ASC',
    );

    return result.map((map) => InventoryItem.fromMap(map)).toList();
  }

  /// Update Barang
  Future<int> updateItem(InventoryItem item) async {
    final db = await _databaseHelper.database;

    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Hapus Barang
  Future<int> deleteItem(int id) async {
    final db = await _databaseHelper.database;

    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  /// Total Barang
  Future<int> getItemCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM items
      ''');

    return result.first['total'] as int;
  }

  /// Total Nilai Stok
  Future<double> getTotalInventoryValue() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
    SELECT
    SUM(nilai_stok) as total
    FROM items
  ''');

    final total = result.first['total'];

    if (total == null) {
      return 0;
    }

    return (total as num).toDouble();
  }

  /// Barang Stok Kritis
  Future<List<InventoryItem>> getCriticalStockItems() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT *
      FROM items
      WHERE stok <= stok_minimum
      ORDER BY stok ASC
      ''');

    return result.map((e) => InventoryItem.fromMap(e)).toList();
  }
}
