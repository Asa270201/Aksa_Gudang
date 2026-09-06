import '../../core/database/database_helper.dart';
import '../../models/inventory_item.dart';

class TransactionHistory {
  final int id;
  final String itemName;
  final String itemCode;
  final String category;
  final String unit;
  final double quantity;
  final double subtotal;
  final String recipient;
  final String foreman;
  final String assistant;
  final String note;
  final String? documentationPhotoPath;
  final String division;
  final DateTime date;

  const TransactionHistory({
    required this.id,
    required this.itemName,
    required this.itemCode,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.subtotal,
    required this.recipient,
    required this.foreman,
    required this.assistant,
    required this.note,
    required this.documentationPhotoPath,
    required this.division,
    required this.date,
  });

  factory TransactionHistory.fromMap(Map<String, dynamic> map) {
    return TransactionHistory(
      id: map['id'] as int,
      itemName: map['item_name'] as String,
      itemCode: map['item_code'] as String,
      category: map['category'] as String,
      unit: map['unit'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      recipient: (map['recipient'] as String?) ?? '-',
      foreman: (map['foreman'] as String?) ?? '-',
      assistant: (map['assistant'] as String?) ?? '-',
      note: (map['note'] as String?) ?? '-',
      documentationPhotoPath: map['documentation_photo_path'] as String?,
      division: (map['division'] as String?) ?? '-',
      date: DateTime.parse(map['date'] as String),
    );
  }
}

class TransactionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<void> issueItem({
    required InventoryItem item,
    required int quantity,
    required String recipient,
    required String foreman,
    required String assistant,
    required String note,
    required int divisionId,
    String? documentationPhotoPath,
  }) async {
    if (item.id == null) {
      throw Exception('Barang tidak memiliki ID yang valid');
    }
    if (quantity <= 0) {
      throw Exception('Jumlah pengambilan harus lebih dari 0');
    }
    if (quantity > item.stok) {
      throw Exception('Stok tidak mencukupi');
    }

    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final currentRows = await txn.query(
        'items',
        columns: ['stok', 'harga_satuan'],
        where: 'id = ?',
        whereArgs: [item.id],
        limit: 1,
      );

      if (currentRows.isEmpty) {
        throw Exception('Barang tidak ditemukan');
      }

      final currentStock = (currentRows.first['stok'] as num).toDouble();
      final currentPrice = (currentRows.first['harga_satuan'] as num)
          .toDouble();
      if (quantity > currentStock) {
        throw Exception('Stok berubah atau tidak mencukupi');
      }

      final updated = await txn.rawUpdate(
        '''
        UPDATE items
        SET stok = stok - ?,
            nilai_stok = (stok - ?) * harga_satuan
        WHERE id = ? AND stok >= ?
        ''',
        [quantity, quantity, item.id, quantity],
      );

      if (updated != 1) {
        throw Exception('Stok berubah atau tidak mencukupi');
      }

      final subtotal = quantity * currentPrice;

      final transactionId = await txn.insert('transactions', {
        'nomor_ba': null,
        'tanggal': now,
        'jenis': 'keluar',
        'divisi_id': divisionId,
        'penerima': recipient.trim().isEmpty ? null : recipient.trim(),
        'nama_mandor': foreman.trim().isEmpty ? null : foreman.trim(),
        'nama_asisten': assistant.trim().isEmpty ? null : assistant.trim(),
        'keterangan': note.trim().isEmpty ? null : note.trim(),
        'foto_dokumentasi': documentationPhotoPath,
        'total_nilai': subtotal,
        'created_at': now,
      });

      await txn.insert('transaction_details', {
        'transaction_id': transactionId,
        'item_id': item.id,
        'qty': quantity,
        'harga': currentPrice,
        'subtotal': subtotal,
      });
    });
  }

  Future<List<TransactionHistory>> getHistory() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT
        t.id,
        i.nama AS item_name,
        i.kode AS item_code,
        i.kategori AS category,
        i.satuan AS unit,
        d.qty AS quantity,
        d.subtotal,
        t.penerima AS recipient,
        t.nama_mandor AS foreman,
        t.nama_asisten AS assistant,
        t.keterangan AS note,
        t.foto_dokumentasi AS documentation_photo_path,
        v.nama AS division,
        t.tanggal AS date
      FROM transactions t
      INNER JOIN transaction_details d ON d.transaction_id = t.id
      INNER JOIN items i ON i.id = d.item_id
      LEFT JOIN divisions v ON v.id = t.divisi_id
      WHERE t.jenis = 'keluar'
      ORDER BY t.tanggal DESC, t.id DESC
    ''');

    return result.map(TransactionHistory.fromMap).toList();
  }

  Future<List<String>> getDivisions() async {
    final db = await _databaseHelper.database;
    final result = await db.query('divisions', orderBy: 'id ASC');
    return result.map((row) => row['nama'] as String).toList();
  }

  Future<int?> getDivisionId(String name) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'divisions',
      columns: ['id'],
      where: 'nama = ?',
      whereArgs: [name],
      limit: 1,
    );

    return result.isEmpty ? null : result.first['id'] as int;
  }

  Future<Map<String, int>> getDivisionPickupCounts() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT v.nama AS division, COALESCE(SUM(d.qty), 0) AS total
      FROM divisions v
      LEFT JOIN transactions t
        ON t.divisi_id = v.id AND t.jenis = 'keluar'
      LEFT JOIN transaction_details d ON d.transaction_id = t.id
      GROUP BY v.id, v.nama
      ORDER BY v.id ASC
    ''');

    return {
      for (final row in result)
        row['division'] as String: (row['total'] as num).toInt(),
    };
  }
}
