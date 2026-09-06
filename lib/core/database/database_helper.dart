// lib/core/database/database_helper.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, 'aksa_gudang.db');

    return openDatabase(
      path,
      version: 7,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    //
    // MASTER BARANG
    //
    await db.execute('''
      CREATE TABLE items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,

      kode TEXT NOT NULL UNIQUE,

      nama TEXT NOT NULL,

      kategori TEXT NOT NULL,

      satuan TEXT NOT NULL,

      stok REAL NOT NULL,

      harga_satuan REAL NOT NULL,

      nilai_stok REAL NOT NULL,

      stok_minimum REAL NOT NULL DEFAULT 0,

      created_at TEXT NOT NULL
    )
    ''');

    //
    // MASTER DIVISI
    //
    await db.execute('''
      CREATE TABLE divisions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await _seedDivisions(db);

    //
    // HEADER TRANSAKSI
    //
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nomor_ba TEXT,
        tanggal TEXT NOT NULL,
        jenis TEXT NOT NULL,
        divisi_id INTEGER,
        penerima TEXT,
        nama_mandor TEXT,
        nama_asisten TEXT,
        keterangan TEXT,
        foto_dokumentasi TEXT,
        total_nilai REAL DEFAULT 0,
        created_at TEXT NOT NULL,

        FOREIGN KEY (divisi_id)
        REFERENCES divisions (id)
      )
    ''');

    //
    // DETAIL TRANSAKSI
    //
    await db.execute('''
      CREATE TABLE transaction_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        harga REAL NOT NULL,
        subtotal REAL NOT NULL,

        FOREIGN KEY (transaction_id)
        REFERENCES transactions (id)
        ON DELETE CASCADE,

        FOREIGN KEY (item_id)
        REFERENCES items (id)
      )
    ''');

    //
    // INDEX
    //
    await db.execute('CREATE INDEX idx_items_kategori ON items(kategori)');

    await db.execute(
      'CREATE INDEX idx_transaction_tanggal ON transactions(tanggal)',
    );

    await db.execute(
      'CREATE INDEX idx_transaction_divisi ON transactions(divisi_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS items');

      await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode TEXT NOT NULL UNIQUE,
        nama TEXT NOT NULL,
        kategori TEXT NOT NULL,
        satuan TEXT NOT NULL,
        stok REAL NOT NULL,
        harga_satuan REAL NOT NULL,
        nilai_stok REAL NOT NULL,
        stok_minimum REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions ADD COLUMN keterangan TEXT');
    }

    if (oldVersion < 4) {
      await _seedDivisions(db);
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE transactions ADD COLUMN nama_mandor TEXT');
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE transactions ADD COLUMN nama_asisten TEXT');
    }

    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN foto_dokumentasi TEXT',
      );
    }
  }

  Future<void> _seedDivisions(DatabaseExecutor db) async {
    const divisions = [
      'Divisi 1',
      'Divisi 2',
      'Divisi 3',
      'Divisi 4',
      'Kantor Umum',
    ];

    for (final division in divisions) {
      await db.insert('divisions', {
        'nama': division,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> close() async {
    final db = await database;

    await db.close();
  }
}
