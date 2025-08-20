// lib/models/route_stop_model.dart

class RouteStop {
  final int id;
  final int routeId;
  final int stopNumber;
  final String googlePlaceId;
  final String stopNotesEn;
  final double latitude;
  final double longitude;
  final String venueName; 

  RouteStop({
    required this.id,
    required this.routeId,
    required this.stopNumber,
    required this.googlePlaceId,
    required this.stopNotesEn,
    required this.latitude,
    required this.longitude,
    required this.venueName,
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
      // --- DÜZELTME BURADA ---
      // Eğer 'venue_name' null gelirse, varsayılan olarak "Unnamed Stop" ata.
      venueName: map['venue_name'] ?? 'Unnamed Stop', 
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
      'venue_name': venueName,
    };
  }
}