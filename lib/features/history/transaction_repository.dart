import '../../core/database/database_helper.dart';
import '../../models/inventory_item.dart';

class TransactionHistory {
  final int id;
  final String? bonNumber;
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
    required this.bonNumber,
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
      bonNumber: map['bon_number'] as String?,
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
    required double quantity,
    required String recipient,
    required String foreman,
    required String assistant,
    required String note,
    required int divisionId,
    String? documentationPhotoPath,
  }) async {
    await issueBon(
      bonNumber: null,
      date: DateTime.now(),
      items: [TransactionLine(item: item, quantity: quantity)],
      recipient: recipient,
      foreman: foreman,
      assistant: assistant,
      note: note,
      divisionId: divisionId,
      documentationPhotoPath: documentationPhotoPath,
    );
  }

  Future<void> issueBon({
    required String? bonNumber,
    required DateTime date,
    required List<TransactionLine> items,
    required String recipient,
    required String foreman,
    required String assistant,
    required String note,
    required int divisionId,
    String? documentationPhotoPath,
  }) async {
    if (items.isEmpty) {
      throw Exception('Tambahkan minimal satu barang');
    }
    final quantities = <int, double>{};
    for (final line in items) {
      if (line.item.id == null || line.quantity <= 0) {
        throw Exception('Data barang atau jumlah tidak valid');
      }
      quantities.update(
        line.item.id!,
        (current) => current + line.quantity,
        ifAbsent: () => line.quantity,
      );
    }

    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final lines = <Map<String, dynamic>>[];
      for (final entry in quantities.entries) {
        final rows = await txn.query(
          'items',
          columns: ['stok', 'harga_satuan'],
          where: 'id = ?',
          whereArgs: [entry.key],
          limit: 1,
        );
        if (rows.isEmpty || entry.value > (rows.first['stok'] as num)) {
          throw Exception('Stok berubah atau tidak mencukupi');
        }
        final price = (rows.first['harga_satuan'] as num).toDouble();
        lines.add({
          'itemId': entry.key,
          'quantity': entry.value,
          'price': price,
          'subtotal': entry.value * price,
        });
      }

      final transactionId = await txn.insert('transactions', {
        'nomor_bon': bonNumber?.trim().isEmpty ?? true
            ? null
            : bonNumber!.trim(),
        'nomor_ba': null,
        'tanggal': date.toIso8601String(),
        'jenis': 'keluar',
        'divisi_id': divisionId,
        'penerima': recipient.trim().isEmpty ? null : recipient.trim(),
        'nama_mandor': foreman.trim().isEmpty ? null : foreman.trim(),
        'nama_asisten': assistant.trim().isEmpty ? null : assistant.trim(),
        'keterangan': note.trim().isEmpty ? null : note.trim(),
        'foto_dokumentasi': documentationPhotoPath,
        'total_nilai': lines.fold<double>(
          0,
          (total, line) => total + (line['subtotal'] as double),
        ),
        'created_at': now,
      });

      for (final line in lines) {
        final updated = await txn.rawUpdate(
          '''
          UPDATE items
          SET stok = stok - ?,
              nilai_stok = (stok - ?) * harga_satuan
          WHERE id = ? AND stok >= ?
          ''',
          [
            line['quantity'],
            line['quantity'],
            line['itemId'],
            line['quantity'],
          ],
        );
        if (updated != 1) throw Exception('Stok berubah atau tidak mencukupi');

        await txn.insert('transaction_details', {
          'transaction_id': transactionId,
          'item_id': line['itemId'],
          'qty': line['quantity'],
          'harga': line['price'],
          'subtotal': line['subtotal'],
        });
      }
    });
  }

  Future<List<TransactionHistory>> getHistory() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT
        t.id,
        t.nomor_bon AS bon_number,
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

  Future<void> cancelTransaction(int transactionId) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      final transactionRows = await txn.query(
        'transactions',
        columns: ['id', 'jenis'],
        where: 'id = ? AND jenis = ?',
        whereArgs: [transactionId, 'keluar'],
        limit: 1,
      );
      if (transactionRows.isEmpty) {
        throw Exception('Transaksi sudah dibatalkan atau tidak ditemukan');
      }

      final details = await txn.query(
        'transaction_details',
        columns: ['item_id', 'qty'],
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      for (final detail in details) {
        final quantity = (detail['qty'] as num).toDouble();
        final updated = await txn.rawUpdate(
          '''
          UPDATE items
          SET stok = stok + ?,
              nilai_stok = (stok + ?) * harga_satuan
          WHERE id = ?
          ''',
          [quantity, quantity, detail['item_id']],
        );
        if (updated != 1) {
          throw Exception('Barang transaksi tidak ditemukan');
        }
      }

      await txn.update(
        'transactions',
        {'jenis': 'batal'},
        where: 'id = ? AND jenis = ?',
        whereArgs: [transactionId, 'keluar'],
      );
    });
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

class TransactionLine {
  final InventoryItem item;
  final double quantity;

  const TransactionLine({required this.item, required this.quantity});
}
