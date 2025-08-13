class CityFood {
  final int cityId;
  final String foodName;

  CityFood({
    required this.cityId,
    required this.foodName,
  });

  factory CityFood.fromMap(Map<String, dynamic> map) {
    return CityFood(
      cityId: map['city_id'],
      foodName: map['food_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city_id': cityId,
      'food_name': foodName,
    };
  }
}