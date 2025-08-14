// GÜNCELLENMİŞ DOSYA: lib/models/city_model.dart

class City {
  final int id;
  final String cityName;
  final String normalizedCityName;
  final String? cultureSummaryEn;
  final String? localDrinksEn;
  final String? postMealSuggestionsEn;
  final String? iconicDishName;

  City({
    required this.id,
    required this.cityName,
    required this.normalizedCityName,
    this.cultureSummaryEn,
    this.localDrinksEn,
    this.postMealSuggestionsEn,
    this.iconicDishName,
  });

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'],
      cityName: map['city_name'],
      normalizedCityName: map['normalized_city_name'],
      cultureSummaryEn: map['culture_summary_en'],
      localDrinksEn: map['local_drinks_en'],
      postMealSuggestionsEn: map['post_meal_suggestions_en'],
      iconicDishName: map['iconic_dish_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city_name': cityName,
      'normalized_city_name': normalizedCityName,
      'culture_summary_en': cultureSummaryEn,
      'local_drinks_en': localDrinksEn,
      'post_meal_suggestions_en': postMealSuggestionsEn,
      'iconic_dish_name': iconicDishName,
    };
  }
}