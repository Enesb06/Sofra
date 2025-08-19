class RouteModel {
  final int id;
  final int cityId;
  final String titleEn;
  final String descriptionEn;
  final String coverImageUrl;
  final int estimatedDurationMins;
  final String difficulty;

  RouteModel({
    required this.id,
    required this.cityId,
    required this.titleEn,
    required this.descriptionEn,
    required this.coverImageUrl,
    required this.estimatedDurationMins,
    required this.difficulty,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'],
      cityId: map['city_id'],
      titleEn: map['title_en'],
      descriptionEn: map['description_en'],
      coverImageUrl: map['cover_image_url'],
      estimatedDurationMins: map['estimated_duration_mins'],
      difficulty: map['difficulty'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city_id': cityId,
      'title_en': titleEn,
      'description_en': descriptionEn,
      'cover_image_url': coverImageUrl,
      'estimated_duration_mins': estimatedDurationMins,
      'difficulty': difficulty,
    };
  }
}