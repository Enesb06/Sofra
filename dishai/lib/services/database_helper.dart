// GÜNCELLENMİŞ VE GÜVENLİ DOSYA: lib/services/database_helper.dart

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../models/food_details.dart';
import '../models/city_model.dart';
import '../models/city_food_model.dart';
import '../models/tasted_food_model.dart';
import '../models/food_tip_model.dart';

class DatabaseHelper {
  static const _databaseName = "DishAI.db";
  // Veritabanı şeması değiştiği için versiyonu artırıyoruz (cities'e yeni sütunlar).
  static const _databaseVersion = 8;

  // Tablo ve Sütun Sabitleri (Değişiklik Yok)
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
  static const columnFoodCategory = 'food_category';

  static const tableCities = 'cities';
  static const columnCityId = 'id';
  static const columnCityName = 'city_name';
  static const columnNormalizedCityName = 'normalized_city_name';
  // YENİ SÜTUNLAR İÇİN SABİTLER
  static const columnGreetingsEn = 'greetings_en';
  static const columnCategoryPromptEn = 'category_prompt_en';
  // Eski sütunlar, uyumluluk için korunuyor
  static const columnCultureSummaryEn = 'culture_summary_en';
  static const columnLocalDrinksEn = 'local_drinks_en';
  static const columnPostMealSuggestionsEn = 'post_meal_suggestions_en';
  static const columnIconicDishName = 'iconic_dish_name';


  static const tableCityFoods = 'city_foods';
  static const columnRelCityId = 'city_id';
  static const columnRelFoodName = 'food_name';
  static const columnInsiderTipEn = 'insider_tip_en';

  static const tableUserTastedFoods = 'user_tasted_foods';
  static const columnTastedId = 'id';
  static const columnTastedFoodName = 'food_name';
  static const columnTastedCity = 'city_name';
  static const columnTastedDate = 'tasted_date';
  static const columnTastedImagePath = 'image_path';

  static const tableUserFavorites = 'user_favorites';
  static const columnFavFoodName = 'food_name';

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
    // Uygulama ilk kez kurulduğunda tüm tabloları en güncel halleriyle oluştur.
    await db.execute('''
      CREATE TABLE $tableFoods (
        $columnName TEXT PRIMARY KEY, $columnEnglishName TEXT NOT NULL, $columnTurkishName TEXT NOT NULL,
        $columnImageUrl TEXT, $columnStoryEn TEXT, $columnIngredientsEn TEXT, $columnPronunciationText TEXT,
        $columnPairingEn TEXT, $columnSpiceLevel INTEGER, $columnIsVegetarian INTEGER NOT NULL,
        $columnContainsGluten INTEGER NOT NULL, $columnContainsDairy INTEGER NOT NULL, $columnContainsNuts INTEGER NOT NULL,
        $columnCalorieInfoEn TEXT, $columnFoodCategory TEXT
      )
    ''');
    
    // cities tablosunu oluştururken yeni ve eski tüm sütunları ekliyoruz.
    await db.execute('''
        CREATE TABLE $tableCities (
          $columnCityId INTEGER PRIMARY KEY, $columnCityName TEXT NOT NULL, $columnNormalizedCityName TEXT NOT NULL,
          $columnCultureSummaryEn TEXT, $columnLocalDrinksEn TEXT, $columnPostMealSuggestionsEn TEXT, $columnIconicDishName TEXT,
          $columnGreetingsEn TEXT, $columnCategoryPromptEn TEXT
        )
      ''');

    await db.execute('''
      CREATE TABLE $tableCityFoods (
        $columnRelCityId INTEGER NOT NULL, $columnRelFoodName TEXT NOT NULL, $columnInsiderTipEn TEXT,
        PRIMARY KEY ($columnRelCityId, $columnRelFoodName),
        FOREIGN KEY ($columnRelCityId) REFERENCES $tableCities($columnCityId),
        FOREIGN KEY ($columnRelFoodName) REFERENCES $tableFoods($columnName)
      )
    ''');
    
    await _createPassportTables(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print("Veritabanı yükseltiliyor: $oldVersion -> $newVersion");
    }
    // Önceki versiyonlardan gelen yükseltmeler korunuyor.
    if (oldVersion < 7) {
       await db.execute('ALTER TABLE $tableFoods ADD COLUMN $columnFoodCategory TEXT');
       if (kDebugMode) { print("✅ v7: foods tablosuna food_category sütunu eklendi."); }
    }
    // YENİ GÜNCELLEME: Versiyon 8'e geçerken bu blok çalışacak.
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE $tableCities ADD COLUMN $columnGreetingsEn TEXT');
        await db.execute('ALTER TABLE $tableCities ADD COLUMN $columnCategoryPromptEn TEXT');
        if (kDebugMode) { print("✅ v8: cities tablosuna sohbet sütunları eklendi."); }
      } catch (e) {
        if (kDebugMode) { print("❗️ v8 Yükseltmesi sırasında HATA (Sütunlar zaten var olabilir): $e"); }
      }
    }
  }
  
  Future<void> _createPassportTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableUserFavorites (
        $columnFavFoodName TEXT PRIMARY KEY,
        FOREIGN KEY ($columnFavFoodName) REFERENCES $tableFoods($columnName) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableUserTastedFoods (
        $columnTastedId INTEGER PRIMARY KEY AUTOINCREMENT, $columnTastedFoodName TEXT NOT NULL,
        $columnTastedCity TEXT NOT NULL, $columnTastedDate TEXT NOT NULL, $columnTastedImagePath TEXT
      )
    ''');
  }

  // --- MEVCUT METOTLAR (HİÇBİR DEĞİŞİKLİK YAPILMADI) ---
  
  Future<void> batchUpsert(List<FoodDetails> foods) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var food in foods) {
      final map = {
        columnName: food.name, columnEnglishName: food.englishName, columnTurkishName: food.turkishName,
        columnImageUrl: food.imageUrl, columnStoryEn: food.storyEn, columnIngredientsEn: food.ingredientsEn,
        columnPronunciationText: food.pronunciationText, columnPairingEn: food.pairingEn, columnSpiceLevel: food.spiceLevel,
        columnIsVegetarian: food.isVegetarian ? 1 : 0, columnContainsGluten: food.containsGluten ? 1 : 0,
        columnContainsDairy: food.containsDairy ? 1 : 0, columnContainsNuts: food.containsNuts ? 1 : 0,
        columnCalorieInfoEn: food.calorieInfoEn, columnFoodCategory: food.foodCategory,
      };
      batch.insert(tableFoods, map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<FoodDetails?> getFoodByName(String name) async {
    final db = await instance.database;
    final maps =
        await db.query(tableFoods, where: '$columnName = ?', whereArgs: [name]);
    if (maps.isNotEmpty) {
      final map = maps.first;
      return FoodDetails(
        name: map[columnName] as String, englishName: map[columnEnglishName] as String, turkishName: map[columnTurkishName] as String,
        imageUrl: map[columnImageUrl] as String?, storyEn: map[columnStoryEn] as String?, ingredientsEn: map[columnIngredientsEn] as String?,
        pronunciationText: map[columnPronunciationText] as String?, pairingEn: map[columnPairingEn] as String?, spiceLevel: map[columnSpiceLevel] as int?,
        isVegetarian: (map[columnIsVegetarian] as int) == 1, containsGluten: (map[columnContainsGluten] as int) == 1,
        containsDairy: (map[columnContainsDairy] as int) == 1, containsNuts: (map[columnContainsNuts] as int) == 1,
        calorieInfoEn: map[columnCalorieInfoEn] as String?, foodCategory: map[columnFoodCategory] as String?,
      );
    }
    return null;
  }

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
    final List<Map<String, dynamic>> maps = await db.query(tableCityFoods,
        columns: [columnRelFoodName], where: '$columnRelCityId = ?', whereArgs: [cityId]);
    return List.generate(maps.length, (i) => maps[i][columnRelFoodName] as String);
  }

  Future<void> addFavorite(String foodName) async {
    final db = await instance.database;
    await db.insert(tableUserFavorites, {columnFavFoodName: foodName},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeFavorite(String foodName) async {
    final db = await instance.database;
    await db.delete(tableUserFavorites,
        where: '$columnFavFoodName = ?', whereArgs: [foodName]);
  }

  Future<bool> isFavorite(String foodName) async {
    final db = await instance.database;
    final result = await db.query(tableUserFavorites,
        where: '$columnFavFoodName = ?', whereArgs: [foodName]);
    return result.isNotEmpty;
  }

  Future<List<FoodDetails>> getAllFavoriteFoods() async {
    final db = await instance.database;
    final favoriteMaps = await db.query(tableUserFavorites);
    if (favoriteMaps.isEmpty) return [];

    final foodNames =
        favoriteMaps.map((map) => map[columnFavFoodName] as String).toList();
    List<FoodDetails> favoriteFoods = [];
    for (String name in foodNames) {
      final foodDetail = await getFoodByName(name);
      if (foodDetail != null) {
        favoriteFoods.add(foodDetail);
      }
    }
    favoriteFoods.sort((a, b) => a.turkishName.compareTo(b.turkishName));
    return favoriteFoods;
  }

  Future<void> addTastedFood(TastedFood tastedFood) async {
    final db = await instance.database;
    await db.insert(tableUserTastedFoods, tastedFood.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TastedFood>> getAllTastedFoods() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query(tableUserTastedFoods, orderBy: '$columnTastedDate DESC');
    return List.generate(maps.length, (i) => TastedFood.fromMap(maps[i]));
  }

  Future<Map<String, String>> getAllFoodNamesForMatching() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableFoods,
      columns: [columnTurkishName, columnName],
    );

    final Map<String, String> foodNameMap = {};
    for (var map in maps) {
      final turkishName = (map[columnTurkishName] as String).toLowerCase();
      final nameId = map[columnName] as String;
      foodNameMap[turkishName] = nameId;
    }
    return foodNameMap;
  }

  Future<List<FoodDetails>> getAllFoods() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query(tableFoods, orderBy: '$columnTurkishName ASC');

    List<FoodDetails> foods = [];
    for (var map in maps) {
      final foodDetail = await getFoodByName(map[columnName] as String);
      if (foodDetail != null) {
        foods.add(foodDetail);
      }
    }
    return foods;
  }

  // lib/services/database_helper.dart dosyasının İÇİNE ve en ALTINA ekle

  Future<List<FoodTip>> getFoodTipsForCity(int cityId) async {
    final db = await instance.database;

    // SQL'in gücünü kullanıyoruz: İki tabloyu (city_foods ve foods) birleştirerek
    // hem ipucunu hem de o ipucuna ait yemeğin Türkçe ismini tek seferde çekiyoruz.
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT
      T1.$columnInsiderTipEn,
      T2.$columnTurkishName
    FROM $tableCityFoods AS T1
    INNER JOIN $tableFoods AS T2 ON T1.$columnRelFoodName = T2.$columnName
    WHERE T1.$columnRelCityId = ? AND T1.$columnInsiderTipEn IS NOT NULL AND T1.$columnInsiderTipEn != ''
  ''', [cityId]);

    if (maps.isEmpty) {
      return [];
    }

    // Gelen her bir satırı, oluşturduğumuz FoodTip modeline dönüştürüyoruz.
    return List.generate(maps.length, (i) {
      return FoodTip(
        foodDisplayName: maps[i][columnTurkishName] as String,
        tip: maps[i][columnInsiderTipEn] as String,
      );
    });
  }
   /// **[YENİ]** Bir şehre ait TÜM FoodDetails nesnelerini doğrudan getirir.
  Future<List<FoodDetails>> getFoodsForCity(int cityId) async {
    final db = await instance.database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT T2.*
      FROM $tableCityFoods AS T1
      INNER JOIN $tableFoods AS T2 ON T1.$columnRelFoodName = T2.$columnName
      WHERE T1.$columnRelCityId = ?
      ORDER BY T2.$columnTurkishName ASC
    ''', [cityId]);

    if (maps.isEmpty) {
      return [];
    }
    
    return List.generate(maps.length, (i) {
      final map = maps[i];
      return FoodDetails(
        name: map[columnName] as String, englishName: map[columnEnglishName] as String, turkishName: map[columnTurkishName] as String,
        imageUrl: map[columnImageUrl] as String?, storyEn: map[columnStoryEn] as String?, ingredientsEn: map[columnIngredientsEn] as String?,
        pronunciationText: map[columnPronunciationText] as String?, pairingEn: map[columnPairingEn] as String?, spiceLevel: map[columnSpiceLevel] as int?,
        isVegetarian: (map[columnIsVegetarian] as int) == 1, containsGluten: (map[columnContainsGluten] as int) == 1,
        containsDairy: (map[columnContainsDairy] as int) == 1, containsNuts: (map[columnContainsNuts] as int) == 1,
        calorieInfoEn: map[columnCalorieInfoEn] as String?, foodCategory: map[columnFoodCategory] as String?,
      );
    });
  }

  /// **[YENİ]** Bir kategoriye ait TÜM yemekleri getirir.
  Future<List<FoodDetails>> getFoodsByCategory(String foodCategory) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableFoods,
      where: '$columnFoodCategory = ?',
      whereArgs: [foodCategory],
      orderBy: '$columnTurkishName ASC',
    );

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return FoodDetails(
        name: map[columnName] as String, englishName: map[columnEnglishName] as String, turkishName: map[columnTurkishName] as String,
        imageUrl: map[columnImageUrl] as String?, storyEn: map[columnStoryEn] as String?, ingredientsEn: map[columnIngredientsEn] as String?,
        pronunciationText: map[columnPronunciationText] as String?, pairingEn: map[columnPairingEn] as String?, spiceLevel: map[columnSpiceLevel] as int?,
        isVegetarian: (map[columnIsVegetarian] as int) == 1, containsGluten: (map[columnContainsGluten] as int) == 1,
        containsDairy: (map[columnContainsDairy] as int) == 1, containsNuts: (map[columnContainsNuts] as int) == 1,
        calorieInfoEn: map[columnCalorieInfoEn] as String?, foodCategory: map[columnFoodCategory] as String?,
      );
    });
  }
}

