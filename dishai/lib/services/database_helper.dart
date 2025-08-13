import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

// Projenizin yapısına göre doğru import yolları
import '../models/food_details.dart';
import '../models/city_model.dart';
import '../models/city_food_model.dart';

class DatabaseHelper {
  static const _databaseName = "DishAI.db";
  // !!! ÖNEMLİ: Veritabanı yapısı değiştiği için versiyonu artırıyoruz.
  static const _databaseVersion = 2;

  // 'foods' tablosu sabitleri
  static const tableFoods = 'foods';
  static const columnName = 'name';
  static const columnEnglishName = 'english_name';
  static const columnTurkishName = 'turkish_name';
  static const columnImageUrl = 'image_url';
  static const columnStoryEn = 'story_en';
  static const columnIngredientsEn = 'ingredients_en';
  static const columnPronunciationText = 'pronunciation_text';
  static const columnPairingEn = 'pairing_en';
  static const columnSpiceLevel = 'spice_level';
  static const columnIsVegetarian = 'is_vegetarian';
  static const columnContainsGluten = 'contains_gluten';
  static const columnContainsDairy = 'contains_dairy';
  static const columnContainsNuts = 'contains_nuts';
  static const columnCalorieInfoEn = 'calorie_info_en';

  // YENİ TABLO VE SÜTUN SABİTLERİ
  static const tableCities = 'cities';
  static const columnCityId = 'id';
  static const columnCityName = 'city_name';
  static const columnNormalizedCityName = 'normalized_city_name';

  static const tableCityFoods = 'city_foods';
  static const columnRelCityId = 'city_id';
  static const columnRelFoodName = 'food_name';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableFoods (
            $columnName TEXT PRIMARY KEY,
            $columnEnglishName TEXT NOT NULL,
            $columnTurkishName TEXT NOT NULL,
            $columnImageUrl TEXT,
            $columnStoryEn TEXT,
            $columnIngredientsEn TEXT,
            $columnPronunciationText TEXT,
            $columnPairingEn TEXT,
            $columnSpiceLevel INTEGER,
            $columnIsVegetarian INTEGER NOT NULL,
            $columnContainsGluten INTEGER NOT NULL,
            $columnContainsDairy INTEGER NOT NULL,
            $columnContainsNuts INTEGER NOT NULL,
            $columnCalorieInfoEn TEXT
          )
          ''');
    await _createCityTables(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCityTables(db);
    }
  }

  Future<void> _createCityTables(Database db) async {
    await db.execute('''
        CREATE TABLE $tableCities (
          $columnCityId INTEGER PRIMARY KEY,
          $columnCityName TEXT NOT NULL,
          $columnNormalizedCityName TEXT NOT NULL
        )
      ''');
    await db.execute('''
        CREATE TABLE $tableCityFoods (
          $columnRelCityId INTEGER NOT NULL,
          $columnRelFoodName TEXT NOT NULL,
          PRIMARY KEY ($columnRelCityId, $columnRelFoodName),
          FOREIGN KEY ($columnRelCityId) REFERENCES $tableCities ($columnCityId),
          FOREIGN KEY ($columnRelFoodName) REFERENCES $tableFoods ($columnName)
        )
      ''');
    print("✅ cities ve city_foods tabloları başarıyla oluşturuldu/güncellendi.");
  }

  // --- MEVCUT 'foods' İŞLEMLERİ ---
  Future<void> batchUpsert(List<FoodDetails> foods) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var food in foods) {
      final map = {
        columnName: food.name,
        columnEnglishName: food.englishName,
        columnTurkishName: food.turkishName,
        columnImageUrl: food.imageUrl,
        columnStoryEn: food.storyEn,
        columnIngredientsEn: food.ingredientsEn,
        columnPronunciationText: food.pronunciationText,
        columnPairingEn: food.pairingEn,
        columnSpiceLevel: food.spiceLevel,
        columnIsVegetarian: food.isVegetarian ? 1 : 0,
        columnContainsGluten: food.containsGluten ? 1 : 0,
        columnContainsDairy: food.containsDairy ? 1 : 0,
        columnContainsNuts: food.containsNuts ? 1 : 0,
        columnCalorieInfoEn: food.calorieInfoEn,
      };
      batch.insert(tableFoods, map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<FoodDetails?> getFoodByName(String name) async {
    final db = await instance.database;
    final maps = await db.query(tableFoods, where: '$columnName = ?', whereArgs: [name]);
    if (maps.isNotEmpty) {
      final map = maps.first;
      return FoodDetails(
        name: map[columnName] as String,
        englishName: map[columnEnglishName] as String,
        turkishName: map[columnTurkishName] as String,
        imageUrl: map[columnImageUrl] as String?,
        storyEn: map[columnStoryEn] as String?,
        ingredientsEn: map[columnIngredientsEn] as String?,
        pronunciationText: map[columnPronunciationText] as String?,
        pairingEn: map[columnPairingEn] as String?,
        spiceLevel: map[columnSpiceLevel] as int?,
        isVegetarian: (map[columnIsVegetarian] as int) == 1,
        containsGluten: (map[columnContainsGluten] as int) == 1,
        containsDairy: (map[columnContainsDairy] as int) == 1,
        containsNuts: (map[columnContainsNuts] as int) == 1,
        calorieInfoEn: map[columnCalorieInfoEn] as String?,
      );
    }
    return null;
  }
  
  // --- YENİ 'cities' ve 'city_foods' İŞLEMLERİ ---
  Future<void> batchUpsertCities(List<City> cities) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var city in cities) {
      batch.insert(tableCities, city.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> batchUpsertCityFoods(List<CityFood> relations) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var relation in relations) {
      batch.insert(tableCityFoods, relation.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<City>> getAllCities() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableCities);
    return List.generate(maps.length, (i) => City.fromMap(maps[i]));
  }

  Future<List<String>> getFoodNamesForCity(int cityId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCityFoods,
      columns: [columnRelFoodName],
      where: '$columnRelCityId = ?',
      whereArgs: [cityId],
    );
    return List.generate(maps.length, (i) => maps[i][columnRelFoodName] as String);
  }
}