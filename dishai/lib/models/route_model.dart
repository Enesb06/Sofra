// lib/models/route_model.dart

class RouteModel {
  final int id;
  final int cityId;
  final String titleEn;
  final String descriptionEn;
  final String coverImageUrl;
  final String difficulty;
  
  // TOPLAM SÜRELER (Yolculuk + Deneyim)
  final int? durationWalkingMins;
  final int? durationTransitMins;
  final int? durationDrivingMins;

  // YENİ ALANLAR: SADECE YOLCULUK SÜRELERİ
  final int? travelWalkingMins;
  final int? travelTransitMins;
  final int? travelDrivingMins;

  RouteModel({
    required this.id,
    required this.cityId,
    required this.titleEn,
    required this.descriptionEn,
    required this.coverImageUrl,
    required this.difficulty,
    this.durationWalkingMins,
    this.durationTransitMins,
    this.durationDrivingMins,
    this.travelWalkingMins,
    this.travelTransitMins,
    this.travelDrivingMins,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'],
      cityId: map['city_id'],
      titleEn: map['title_en'],
      descriptionEn: map['description_en'],
      coverImageUrl: map['cover_image_url'],
      difficulty: map['difficulty'],
      durationWalkingMins: map['duration_walking_mins'],
      durationTransitMins: map['duration_transit_mins'],
      durationDrivingMins: map['duration_driving_mins'],
      travelWalkingMins: map['travel_walking_mins'],
      travelTransitMins: map['travel_transit_mins'],
      travelDrivingMins: map['travel_driving_mins'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city_id': cityId,
      'title_en': titleEn,
      'description_en': descriptionEn,
      'cover_image_url': coverImageUrl,
      'difficulty': difficulty,
      'duration_walking_mins': durationWalkingMins,
      'duration_transit_mins': durationTransitMins,
      'duration_driving_mins': durationDrivingMins,
      'travel_walking_mins': travelWalkingMins,
      'travel_transit_mins': travelTransitMins,
      'travel_driving_mins': travelDrivingMins,
    };
  }
}