// YENİ DOSYA: lib/models/festival_model.dart

class Festival {
  final int id;
  final String nameEn;
  final String cityName;
  final DateTime startDate;
  final DateTime endDate;
  final String descriptionEn;
  final String coverImageUrl;
  final String? officialWebsiteUrl;
  final String? locationCoordinates;

  Festival({
    required this.id,
    required this.nameEn,
    required this.cityName,
    required this.startDate,
    required this.endDate,
    required this.descriptionEn,
    required this.coverImageUrl,
    this.officialWebsiteUrl,
    this.locationCoordinates,
  });

  // Supabase'den gelen JSON verisini Festival modeline çeviren factory constructor.
  // Bu metot, sync_parser.dart içinde kullanılacak.
  factory Festival.fromJson(Map<String, dynamic> json) {
    return Festival(
      id: json['id'],
      nameEn: json['name_en'],
      cityName: json['city_name'],
      // Tarihleri güvenli bir şekilde DateTime nesnesine çeviriyoruz.
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      descriptionEn: json['description_en'],
      coverImageUrl: json['cover_image_url'],
      officialWebsiteUrl: json['official_website_url'],
      locationCoordinates: json['location_coordinates'],
    );
  }

  // Festival modelini veritabanına yazmak için Map'e çeviren metot.
  // Bu metot, database_helper.dart içinde kullanılacak.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_en': nameEn,
      'city_name': cityName,
      // Tarihleri veritabanına ISO 8601 formatında (YYYY-MM-DD) string olarak kaydediyoruz.
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'description_en': descriptionEn,
      'cover_image_url': coverImageUrl,
      'official_website_url': officialWebsiteUrl,
      'location_coordinates': locationCoordinates,
    };
  }

  // Veritabanından okunan Map'i Festival modeline çeviren factory constructor.
  factory Festival.fromMap(Map<String, dynamic> map) {
    return Festival(
      id: map['id'],
      nameEn: map['name_en'],
      cityName: map['city_name'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      descriptionEn: map['description_en'],
      coverImageUrl: map['cover_image_url'],
      officialWebsiteUrl: map['official_website_url'],
      locationCoordinates: map['location_coordinates'],
    );
  }
}