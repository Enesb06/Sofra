// YENİ DOSYA: lib/helpers/database_helper.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/food_details.dart'; // FoodDetails modelimizin yolu

class DatabaseHelper {
  // Veritabanı dosyasının adı.
  static const _databaseName = "DishAI.db";
  // Veritabanı versiyonu. Schema değiştiğinde bu numara artırılır.
  static const _databaseVersion = 1;

  // Tablo ve sütun adlarını sabit olarak tanımlamak, yazım hatalarını önler.
  static const table = 'foods';
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

  // Sınıfı bir singleton yapıyoruz. Bu, uygulama boyunca sadece bir tane
  // DatabaseHelper nesnesi olmasını sağlar.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Sadece bir tane uygulama çapında veritabanı referansı olacak.
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Eğer veritabanı null ise, ilk defa oluştur/aç.
    _database = await _initDatabase();
    return _database!;
  }

  // Veritabanını diskte açar (veya oluşturur).
  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate, // Veritabanı ilk kez oluşturulduğunda çalışır.
    );
  }

  // Veritabanı tablosunu oluşturan SQL komutu.
  // Supabase'deki tabloyla aynı yapıda olmalı.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
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
  }

  // Veritabanına bir yemek listesini eklemek veya güncellemek için metod.
  // 'upsert' (update or insert) mantığı kullanıyoruz.
  Future<void> batchUpsert(List<FoodDetails> foods) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var food in foods) {
      // FoodDetails nesnesini veritabanına uygun bir Map'e dönüştürüyoruz.
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
        // SQLite'da boolean için 0 ve 1 kullanılır.
        columnIsVegetarian: food.isVegetarian ? 1 : 0,
        columnContainsGluten: food.containsGluten ? 1 : 0,
        columnContainsDairy: food.containsDairy ? 1 : 0,
        columnContainsNuts: food.containsNuts ? 1 : 0,
        columnCalorieInfoEn: food.calorieInfoEn,
      };
      
      // Eğer aynı 'name' ile bir kayıt varsa üzerine yazar, yoksa yeni kayıt ekler.
      batch.insert(table, map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    print("✅ Veritabanına ${foods.length} yemek başarıyla eklendi/güncellendi.");
  }

  // İsmine göre tek bir yemeğin detaylarını getiren metod.
  // RecognitionPage'de artık bu metodu kullanacağız.
  Future<FoodDetails?> getFoodByName(String name) async {
    final db = await instance.database;
    final maps = await db.query(
      table,
      where: '$columnName = ?',
      whereArgs: [name],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      // Veritabanından gelen Map'i tekrar FoodDetails nesnesine çeviriyoruz.
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
        // Veritabanındaki 0/1 değerini tekrar boolean'a çeviriyoruz.
        isVegetarian: (map[columnIsVegetarian] as int) == 1,
        containsGluten: (map[columnContainsGluten] as int) == 1,
        containsDairy: (map[columnContainsDairy] as int) == 1,
        containsNuts: (map[columnContainsNuts] as int) == 1,
        calorieInfoEn: map[columnCalorieInfoEn] as String?,
      );
    }
    // Eğer yemek bulunamazsa null döner.
    return null;
  }
}