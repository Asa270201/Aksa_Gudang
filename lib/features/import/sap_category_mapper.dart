// lib/features/import/sap_category_mapper.dart

class SapCategoryMapper {
  static String getCategory(String itemName) {
    final name = itemName.toUpperCase();

    // ==========================
    // APD
    // ==========================
    const apdKeywords = [
      'HELM',
      'SAFETY',
      'FACE SHIELD',
      'SARUNG TANGAN',
      'SARUNG',
      'MASKER',
      'SEPATU BOOT',
      'BOOT',
      'JAS HUJAN',
      'HANDSCOON',
      'SARUNG PELINDUNG',
    ];

    // ==========================
    // ALAT PANEN
    // ==========================
    const alatPanenKeywords = [
      'EGREK',
      'DODOS',
      'CADOS',
      'TOJOK',
      'GANCU',
      'ANGKONG',
      'KAPAK BUAH',
      'HARVESTING POLE',
      'BATU ASAH',
      'JARING TBS',
      'KLEM HARVESTING',
      'LOOSE FRUIT COLLECTION',
      'CANGKUL',
    ];

    // ==========================
    // CEK APD
    // ==========================
    for (final keyword in apdKeywords) {
      if (name.contains(keyword)) {
        return 'APD';
      }
    }

    // ==========================
    // CEK ALAT PANEN
    // ==========================
    for (final keyword in alatPanenKeywords) {
      if (name.contains(keyword)) {
        return 'Alat Panen';
      }
    }

    // ==========================
    // DEFAULT
    // ==========================
    return 'Umum';
  }
}
