class RouteStop {
  final int id;
  final int routeId;
  final int stopNumber;
  final String googlePlaceId;
  final String stopNotesEn;
  // Harita üzerinde daha performanslı çalışmak için lat/lng bilgilerini de ekliyoruz.
  // Bu bilgiyi Supabase'den çekmek en iyisi olacaktır.
  final double latitude;
  final double longitude;


  RouteStop({
    required this.id,
    required this.routeId,
    required this.stopNumber,
    required this.googlePlaceId,
    required this.stopNotesEn,
    required this.latitude,
    required this.longitude,
  });

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    return RouteStop(
      id: map['id'],
      routeId: map['route_id'],
      stopNumber: map['stop_number'],
      googlePlaceId: map['google_place_id'],
      stopNotesEn: map['stop_notes_en'],
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'stop_number': stopNumber,
      'google_place_id': googlePlaceId,
      'stop_notes_en': stopNotesEn,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}