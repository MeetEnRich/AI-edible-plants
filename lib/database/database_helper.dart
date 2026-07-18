import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/plant_catalog_model.dart';
import '../models/indigenous_metadata_model.dart';

/// ──────────────────────────────────────────────
/// DatabaseHelper — Singleton manager for the local
/// SQLite database lifecycle, CRUD operations, and
/// initial seed data for indigenous plant metadata.
/// ──────────────────────────────────────────────
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'edible_plants.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// ── Table creation ──────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    // Users table removed (handled by Firebase Auth)

    // Plant Catalog (identifications) table
    await db.execute('''
      CREATE TABLE plant_catalog (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        scientific_name TEXT NOT NULL,
        common_name TEXT NOT NULL,
        local_name TEXT,
        confidence_score REAL NOT NULL,
        image_path TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        xai_reasoning TEXT NOT NULL,
        safety_warnings TEXT,
        preparation_methods TEXT,
        family TEXT,
        edibility_status TEXT,
        habitat TEXT,
        nutritional_highlights TEXT,
        timestamp TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        verification_status TEXT DEFAULT 'verified'
      )
    ''');

    // Indigenous Metadata reference table
    await db.execute('''
      CREATE TABLE indigenous_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scientific_name TEXT NOT NULL UNIQUE,
        family TEXT NOT NULL,
        igbo_name TEXT,
        hausa_name TEXT,
        yoruba_name TEXT,
        description TEXT NOT NULL,
        preparation_methods TEXT NOT NULL,
        safety_warnings TEXT NOT NULL
      )
    ''');

    // Seed initial data
    await _seedIndigenousMetadata(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE plant_catalog ADD COLUMN family TEXT');
      await db.execute('ALTER TABLE plant_catalog ADD COLUMN edibility_status TEXT');
      await db.execute('ALTER TABLE plant_catalog ADD COLUMN habitat TEXT');
      await db.execute('ALTER TABLE plant_catalog ADD COLUMN nutritional_highlights TEXT');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE plant_catalog ADD COLUMN verification_status TEXT DEFAULT 'verified'");
    }
  }

  /// ── Seed 8 core Nigerian edible plants ──────
  Future<void> _seedIndigenousMetadata(Database db) async {
    final seeds = [
      {
        'scientific_name': 'Vernonia amygdalina',
        'family': 'Asteraceae',
        'igbo_name': 'Onugbu',
        'hausa_name': 'Shiwaka',
        'yoruba_name': 'Ewuro',
        'description': 'A tropical shrub commonly known as Bitter Leaf. '
            'It is one of the most widely consumed leafy vegetables in Nigeria, '
            'known for its distinctive bitter taste and rich nutritional profile '
            'including proteins, vitamins, and minerals.',
        'preparation_methods': 'Wash thoroughly and squeeze repeatedly in water '
            'to reduce bitterness. Can be used fresh in soups (Ofe Onugbu, Egusi soup) '
            'or boiled. Young leaves are preferred. The washing water can be consumed '
            'as a medicinal tonic.',
        'safety_warnings': 'Generally safe when properly washed. Raw leaves are '
            'very bitter and may cause stomach upset if consumed unwashed. '
            'Pregnant women should consume in moderation.',
      },
      {
        'scientific_name': 'Telfairia occidentalis',
        'family': 'Cucurbitaceae',
        'igbo_name': 'Ugu',
        'hausa_name': 'Kabewa',
        'yoruba_name': 'Ẹgúsí-ìtọ́ọ́',
        'description': 'Fluted Pumpkin is a tropical vine cultivated extensively '
            'in West Africa. Its dark green leaves are among the most popular '
            'vegetables in Nigerian cuisine, prized for their high iron content '
            'and blood-boosting properties.',
        'preparation_methods': 'Leaves are washed, sliced thinly, and added to '
            'soups such as Egusi, Ogbono, or vegetable soup. Can also be blended '
            'into smoothies. Seeds are roasted and eaten or used to make oil. '
            'Best added towards the end of cooking to retain nutrients.',
        'safety_warnings': 'Safe for general consumption. Seeds should be properly '
            'roasted before eating. Excessive consumption of raw juice may cause '
            'diarrhoea in some individuals.',
      },
      {
        'scientific_name': 'Gnetum africanum',
        'family': 'Gnetaceae',
        'igbo_name': 'Okazi',
        'hausa_name': 'Afang',
        'yoruba_name': 'Afang',
        'description': 'A wild climbing plant found in tropical rainforests. '
            'The tough, dark green leaves are finely shredded and used in '
            'traditional soups. It is rich in protein, essential amino acids, '
            'and minerals.',
        'preparation_methods': 'Leaves must be finely shredded before cooking '
            'due to their tough texture. Commonly used in Afang soup (Cross River) '
            'and Okazi soup (Igbo). Often combined with Waterleaf to soften. '
            'Wash thoroughly before shredding.',
        'safety_warnings': 'Generally safe when cooked. Raw leaves are very tough '
            'and not recommended for direct consumption. Ensure leaves are sourced '
            'from non-polluted forest areas.',
      },
      {
        'scientific_name': 'Talinum triangulare',
        'family': 'Talinaceae',
        'igbo_name': 'Mgbolodi',
        'hausa_name': 'Alayyahu',
        'yoruba_name': 'Gbure',
        'description': 'Waterleaf is a fast-growing succulent herbaceous plant. '
            'It produces mucilaginous (slimy) leaves that are widely used in '
            'Nigerian soups, especially in the south. Very rich in vitamins A, C, '
            'and iron.',
        'preparation_methods': 'Wash and chop leaves. Add to soups like Edikaikong '
            'or Afang soup. Often parboiled before adding to reduce excess water content. '
            'Can be used in salads when young and tender.',
        'safety_warnings': 'Safe for consumption. Contains oxalates — individuals '
            'with kidney stones should consume in moderation. Wilts quickly after '
            'harvest; use fresh.',
      },
      {
        'scientific_name': 'Piper guineense',
        'family': 'Piperaceae',
        'igbo_name': 'Uziza',
        'hausa_name': 'Masoro',
        'yoruba_name': 'Iyere',
        'description': 'West African Black Pepper (Uziza) is a climbing vine '
            'whose leaves and seeds are used as a spice and vegetable. It has '
            'a warm, peppery flavour and is valued in traditional medicine for '
            'postpartum recovery.',
        'preparation_methods': 'Leaves are washed, shredded, and added to soups '
            '(pepper soup, Nsala soup, Ofe Nsala). Seeds are dried and ground '
            'into powder for seasoning. Add leaves at the very end of cooking to '
            'preserve flavour and nutrients.',
        'safety_warnings': 'Safe in culinary quantities. May cause mild stomach '
            'irritation if consumed in very large amounts. Not recommended in '
            'excessive quantities during early pregnancy.',
      },
      {
        'scientific_name': 'Ocimum gratissimum',
        'family': 'Lamiaceae',
        'igbo_name': 'Nchuanwu',
        'hausa_name': 'Daidoya',
        'yoruba_name': 'Efirin',
        'description': 'African Basil (Scent Leaf) is a highly aromatic herb '
            'used extensively in Nigerian cooking and traditional medicine. '
            'Its strong camphor-like scent makes it a key flavouring agent in '
            'pepper soups, yam porridge, and stews.',
        'preparation_methods': 'Wash leaves, shred or tear by hand, and add to '
            'dishes at the final stage of cooking. Used in pepper soup, Nkwobi, '
            'Isi-ewu, and jollof stews. Can be used to make herbal tea by '
            'steeping in hot water.',
        'safety_warnings': 'Generally recognized as safe. Essential oil extracts '
            'should not be applied directly to skin without dilution. Mild '
            'allergic reactions possible in sensitive individuals.',
      },
      {
        'scientific_name': 'Corchorus olitorius',
        'family': 'Malvaceae',
        'igbo_name': 'Ahịhara',
        'hausa_name': 'Lalo',
        'yoruba_name': 'Ewedu',
        'description': 'Jute Mallow (Ewedu) is a leafy vegetable that produces '
            'a characteristic slimy/mucilaginous texture when cooked. It is a '
            'staple in Yoruba cuisine and is rich in beta-carotene, iron, '
            'calcium, and vitamin C.',
        'preparation_methods': 'Wash leaves thoroughly, boil in a small amount '
            'of water, and blend or mash with a traditional broom (ijabe) to '
            'create the signature slimy consistency. Typically served with Àmàlà '
            'and gbegiri (bean soup). Add potash (kaun) to enhance sliminess.',
        'safety_warnings': 'Safe for general consumption. Seeds of mature plants '
            'may contain trace glycosides — use only young tender leaves. '
            'Avoid consuming extremely old or yellowed leaves.',
      },
      {
        'scientific_name': 'Amaranthus hybridus',
        'family': 'Amaranthaceae',
        'igbo_name': 'Inine',
        'hausa_name': 'Alayyahu-kaji',
        'yoruba_name': 'Tete',
        'description': 'Green Amaranth is a fast-growing leafy vegetable found '
            'across Nigeria. It is one of the most affordable and accessible '
            'green vegetables, often found in local markets. Rich in protein, '
            'lysine, iron, and vitamins A & C.',
        'preparation_methods': 'Wash and chop. Used in various soups and stews. '
            'In Yoruba cuisine, it is cooked in tomato-based stew (Efo Tete). '
            'In Igbo cuisine, it can be added to Ofe Owerri or yam porridge. '
            'Can also be steamed as a simple side dish.',
        'safety_warnings': 'Generally safe. Contains moderate levels of oxalates '
            'and nitrates — not advised for individuals with kidney issues in '
            'excessive quantities. Wash thoroughly to remove sand and debris.',
      },
      {
        'scientific_name': 'Pterocarpus mildbraedii',
        'family': 'Fabaceae',
        'igbo_name': 'Oha (Ora)',
        'hausa_name': 'Madubiya',
        'yoruba_name': 'Uro',
        'description': 'Oha is a beloved tree vegetable primarily found in southeastern '
            'Nigeria. Its tender leaves are treasured for their unique taste and '
            'silky texture when cooked. The plant is deeply embedded in Igbo cultural '
            'traditions.',
        'preparation_methods': 'Leaves must be plucked tenderly by hand, not cut with '
            'a knife, to prevent darkening and bitter taste. Used primarily in the '
            'famous Ofe Oha, thickened with cocoyam or achi. Always added at the very '
            'end of cooking.',
        'safety_warnings': 'Completely safe when cooked. Contains small amounts of '
            'hydrogen cyanide in raw form, which is destroyed completely during '
            'standard cooking.',
      },
      {
        'scientific_name': 'Gongronema latifolium',
        'family': 'Apocynaceae',
        'igbo_name': 'Utazi',
        'hausa_name': 'Madumaro',
        'yoruba_name': 'Arokeke',
        'description': 'Utazi is a tropical climbing shrub with broad, heart-shaped leaves. '
            'It has a sharp, bitter, and slightly sweet taste. Highly valued in '
            'traditional medicine for digestion and malaria treatment.',
        'preparation_methods': 'Can be eaten raw as a garnish or chewed. Often sliced '
            'and used sparingly as a spice/garnish for Nkwobi, Abacha (African Salad), '
            'Isi-ewu, and pepper soups. Only a few leaves are needed due to its potency.',
        'safety_warnings': 'Safe for consumption. Its extreme bitterness limits the '
            'amount one can comfortably eat. Pregnant women are advised to eat only '
            'in moderation.',
      },
      {
        'scientific_name': 'Treculia africana',
        'family': 'Moraceae',
        'igbo_name': 'Ukwa',
        'hausa_name': 'Barafuta',
        'yoruba_name': 'Afon',
        'description': 'African Breadfruit is a massive forest tree that produces '
            'huge compound fruits. The extracted seeds (ukwa) are considered a '
            'delicacy and a highly nutritious source of protein, fats, and complex '
            'carbohydrates.',
        'preparation_methods': 'Seeds are extracted from the spongy fruit core. They '
            'are thoroughly washed and boiled with potash (akanwu) to soften. Can be '
            'cooked as a porridge with bitter leaf and palm oil, or roasted and eaten '
            'with coconut.',
        'safety_warnings': 'Safe to eat. Uncooked seeds contain anti-nutritional factors '
            'like tannins and oxalates, which are significantly reduced through prolonged '
            'boiling or roasting.',
      },
      {
        'scientific_name': 'Solanum aethiopicum',
        'family': 'Solanaceae',
        'igbo_name': 'Anara',
        'hausa_name': 'Yalo',
        'yoruba_name': 'Igba',
        'description': 'The African Eggplant, or Garden Egg, comes in various shapes '
            'and colours (white, green, yellow). It is a culturally significant fruit '
            'often served to guests in southeastern Nigeria as a sign of welcome.',
        'preparation_methods': 'Can be eaten raw as a crunchy, slightly bitter snack '
            'often paired with peanut paste (Ose Oji). When cooked, it is chopped and '
            'used in Garden Egg sauce to eat with boiled yam or plantains. Leaves '
            '(Anara leaves) are also used in soups.',
        'safety_warnings': 'Safe for general consumption. Unripe green fruits are '
            'more bitter due to higher alkaloid content. People sensitive to nightshades '
            'should monitor consumption.',
      },
      {
        'scientific_name': 'Adansonia digitata',
        'family': 'Malvaceae',
        'igbo_name': 'Kuka',
        'hausa_name': 'Kuka',
        'yoruba_name': 'Ose',
        'description': 'The Baobab tree is an iconic savanna species in northern Nigeria. '
            'Every part of the tree is useful. The leaves are rich in iron and calcium, '
            'while the fruit pulp is famous for its exceptionally high vitamin C content.',
        'preparation_methods': 'Young leaves can be eaten fresh, but more commonly, '
            'leaves are sun-dried and ground into a green powder to make Miyan Kuka '
            '(a traditional Hausa soup). The powdery fruit pulp is dissolved in water '
            'to make refreshing drinks.',
        'safety_warnings': 'Very safe. The dried leaf powder (kuka) is mucilaginous '
            'when cooked. Ensure the powder is stored in a dry place to prevent mold.',
      },
    ];

    for (final seed in seeds) {
      await db.insert('indigenous_metadata', seed);
    }
  }

  // Users CRUD removed (handled by Firebase Auth)

  // ═══════════════════════════════════════════════
  // PLANT CATALOG CRUD
  // ═══════════════════════════════════════════════

  Future<int> insertPlantRecord(PlantCatalogModel record) async {
    final db = await database;
    return await db.insert('plant_catalog', record.toMap());
  }

  Future<List<PlantCatalogModel>> getUserPlantRecords(String userId) async {
    final db = await database;
    final maps = await db.query(
      'plant_catalog',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((e) => PlantCatalogModel.fromMap(e)).toList();
  }

  Future<List<PlantCatalogModel>> getUnsyncedRecords(String userId) async {
    final db = await database;
    final maps = await db.query(
      'plant_catalog',
      where: 'user_id = ? AND is_synced = 0 AND verification_status = ?',
      whereArgs: [userId, 'verified'],
      orderBy: 'timestamp ASC',
    );
    return maps.map((e) => PlantCatalogModel.fromMap(e)).toList();
  }


  Future<List<PlantCatalogModel>> getPendingVerifications() async {
    final db = await database;
    final maps = await db.query(
      'plant_catalog',
      where: 'verification_status = ?',
      whereArgs: ['pending'],
    );
    return maps.map((m) => PlantCatalogModel.fromMap(m)).toList();
  }

  Future<int> markAsSynced(int recordId) async {
    final db = await database;
    return await db.update(
      'plant_catalog',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<int> updatePlantRecord(PlantCatalogModel record) async {
    final db = await database;
    return await db.update(
      'plant_catalog',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deletePlantRecord(int recordId) async {
    final db = await database;
    return await db.delete('plant_catalog', where: 'id = ?', whereArgs: [recordId]);
  }

  Future<int> getPlantCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM plant_catalog WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUnsyncedCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM plant_catalog WHERE user_id = ? AND is_synced = 0 AND verification_status = ?',
      [userId, 'verified'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ═══════════════════════════════════════════════
  // INDIGENOUS METADATA READ
  // ═══════════════════════════════════════════════

  Future<IndigenousMetadataModel?> lookupMetadata(String scientificName) async {
    final db = await database;
    final maps = await db.query(
      'indigenous_metadata',
      where: 'LOWER(scientific_name) = LOWER(?)',
      whereArgs: [scientificName],
    );
    if (maps.isEmpty) return null;
    return IndigenousMetadataModel.fromMap(maps.first);
  }

  Future<List<IndigenousMetadataModel>> getAllMetadata() async {
    final db = await database;
    final maps = await db.query('indigenous_metadata', orderBy: 'scientific_name ASC');
    return maps.map((m) => IndigenousMetadataModel.fromMap(m)).toList();
  }

  Future<List<IndigenousMetadataModel>> searchMetadata(String query) async {
    final db = await database;
    final search = '%$query%';
    final maps = await db.query(
      'indigenous_metadata',
      where: 'scientific_name LIKE ? OR igbo_name LIKE ? OR hausa_name LIKE ? OR yoruba_name LIKE ? OR family LIKE ?',
      whereArgs: [search, search, search, search, search],
    );
    return maps.map((m) => IndigenousMetadataModel.fromMap(m)).toList();
  }
}
