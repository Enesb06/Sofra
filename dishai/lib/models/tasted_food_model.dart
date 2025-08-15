// GÜNCELLENMİŞ DOSYA: lib/models/tasted_food_model.dart

class TastedFood {
  final int? id;
  final String foodName;
  final String cityName;
  final String tastedDate;
  final String? imagePath;

  TastedFood({
    this.id,
    required this.foodName,
    required this.cityName,
    required this.tastedDate,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_name': foodName,
      'city_name': cityName,
      'tasted_date': tastedDate,
      'image_path': imagePath,
    };
  }

  factory TastedFood.fromMap(Map<String, dynamic> map) {
    return TastedFood(
      id: map['id'],
      foodName: map['food_name'],
      cityName: map['city_name'],
      tastedDate: map['tasted_date'],
      imagePath: map['image_path'],
    );
  }
}