class InventoryItem {
  final int? id;

  final String kode;
  final String nama;
  final String kategori;
  final String satuan;

  final double stok;
  final double hargaSatuan;
  final double nilaiStok;

  final double stokMinimum;
  final bool sudahPr;
  final bool sudahDatang;

  final DateTime createdAt;

  const InventoryItem({
    this.id,
    required this.kode,
    required this.nama,
    required this.kategori,
    required this.satuan,
    required this.stok,
    required this.hargaSatuan,
    required this.nilaiStok,
    required this.stokMinimum,
    this.sudahPr = false,
    this.sudahDatang = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode': kode,
      'nama': nama,
      'kategori': kategori,
      'satuan': satuan,
      'stok': stok,
      'harga_satuan': hargaSatuan,
      'nilai_stok': nilaiStok,
      'stok_minimum': stokMinimum,
      'status_pr': sudahPr ? 1 : 0,
      'status_datang': sudahDatang ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      kode: map['kode'],
      nama: map['nama'],
      kategori: map['kategori'],
      satuan: map['satuan'],
      stok: (map['stok'] as num).toDouble(),
      hargaSatuan: (map['harga_satuan'] as num).toDouble(),
      nilaiStok: (map['nilai_stok'] as num).toDouble(),
      stokMinimum: (map['stok_minimum'] as num).toDouble(),
      sudahPr: (map['status_pr'] as num?)?.toInt() == 1,
      sudahDatang: (map['status_datang'] as num?)?.toInt() == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
