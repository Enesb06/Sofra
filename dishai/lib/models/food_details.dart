class FoodDetails {
  final String name;
  final String englishName;
  final String turkishName;
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

  FoodDetails({
    required this.name,
    required this.englishName,
    required this.turkishName,
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
  });

  factory FoodDetails.fromJson(Map<String, dynamic> json) {
    return FoodDetails(
      name: json['name'],
      englishName: json['english_name'],
      turkishName: json['turkish_name'],
      storyEn: json['story_en'],
      ingredientsEn: json['ingredients_en'],
      pronunciationText: json['pronunciation_text'],
      pairingEn: json['pairing_en'],
      spiceLevel: json['spice_level'],
      isVegetarian: json['is_vegetarian'] ?? false,
      containsGluten: json['contains_gluten'] ?? true,
      containsDairy: json['contains_dairy'] ?? false,
      containsNuts: json['contains_nuts'] ?? false,
      calorieInfoEn: json['calorie_info_en'],
    );
  }
}