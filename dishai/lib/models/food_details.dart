class FoodDetails {
  final String name;
  final String englishName;
  final String turkishName;
  final String? imageUrl;
  final String? storyEn;
  final String? ingredientsEn;
  final String? pronunciationText;
  final String? pairingEn;
  final int? spiceLevel;
  final bool isVegetarian;
  final bool containsGluten;
  final bool containsDairy;
  final bool containsNuts;
  final String? calorieInfoEn;
  final String? foodCategory;

  FoodDetails({
    required this.name,
    required this.englishName,
    required this.turkishName,
    this.imageUrl,
    this.storyEn,
    this.ingredientsEn,
    this.pronunciationText,
    this.pairingEn,
    this.spiceLevel,
    required this.isVegetarian,
    required this.containsGluten,
    required this.containsDairy,
    required this.containsNuts,
    this.calorieInfoEn,
    this.foodCategory,
  });

  // Bu metot artık hem Supabase'den gelen 'bool' değerlerini
  // hem de sqflite'tan gelen 'int' (0/1) değerlerini doğru şekilde işleyebilir.
  factory FoodDetails.fromJson(Map<String, dynamic> json) {
    return FoodDetails(
      name: json['name'],
      englishName: json['english_name'],
      turkishName: json['turkish_name'],
      imageUrl: json['image_url'],
      storyEn: json['story_en'],
      ingredientsEn: json['ingredients_en'],
      pronunciationText: json['pronunciation_text'],
      pairingEn: json['pairing_en'],
      spiceLevel: json['spice_level'],
      
      // Gelen değer 'true' (bool) VEYA '1' (int) ise 'true' kabul et. Değilse 'false'.
      isVegetarian: (json['is_vegetarian'] == true || json['is_vegetarian'] == 1),
      
      // Gluten verisi hiç yoksa (null) varsayılan olarak 'true' kabul et,
      // varsa 'true' (bool) VEYA '1' (int) olup olmadığını kontrol et.
      containsGluten: json['contains_gluten'] == null 
          ? true 
          : (json['contains_gluten'] == true || json['contains_gluten'] == 1),

      // Diğer boolean alanlar için de aynı mantığı uygula.
      containsDairy: (json['contains_dairy'] == true || json['contains_dairy'] == 1),
      containsNuts: (json['contains_nuts'] == true || json['contains_nuts'] == 1),
      
      calorieInfoEn: json['calorie_info_en'],
      foodCategory: json['food_category'],
    );
  }
}