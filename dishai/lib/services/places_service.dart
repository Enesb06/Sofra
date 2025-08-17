// GÜNCELLENMİŞ DOSYA: lib/services/places_service.dart
// http paketini kullanarak doğrudan API isteği yapar.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Google'dan gelen cevabı modellemek için basit sınıflar
class PlaceSearchResult {
  final String placeId;
  final String name;
  final String? address; // 'vicinity' alanı
  final double? rating;
  final String? photoReference;

  PlaceSearchResult({
    required this.placeId,
    required this.name,
    this.address,
    this.rating,
    this.photoReference,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResult(
      placeId: json['place_id'],
      name: json['name'],
      address: json['vicinity'],
      rating: (json['rating'] as num?)?.toDouble(),
      photoReference: (json['photos'] as List?)?.isNotEmpty ?? false
        ? json['photos'][0]['photo_reference']
        : null,
    );
  }
}

class PlacesService {
  final String apiKey;
  final String _baseUrl = "https://maps.googleapis.com/maps/api/place";

  PlacesService({required this.apiKey});

  // Cihazın mevcut konumunu al (Bu metot aynı kalıyor)
  Future<Position> getCurrentLocation() async {
      // ... öncekiyle tamamen aynı kod ...
        bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
  }
  
  // Google'dan fotoğraf URL'sini oluşturmak için yardımcı metot
  String getPhotoUrl(String photoReference) {
    return "$_baseUrl/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey";
  }

  // Belirtilen yemek ve konuma göre mekanları ara (http ile yeniden yazıldı)
  Future<List<PlaceSearchResult>> findRestaurants(String foodName, Position position) async {
    final query = '"$foodName" restaurant';
    final location = "${position.latitude},${position.longitude}";
    
    final uri = Uri.parse("$_baseUrl/textsearch/json").replace(queryParameters: {
      'query': query,
      'location': location,
      'radius': '5000', // metre cinsinden
      'type': 'restaurant',
      'key': apiKey,
    });
    
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List results = data['results'];
          return results.map((place) => PlaceSearchResult.fromJson(place)).toList();
        } else {
          throw Exception(data['error_message'] ?? 'Google Places API Error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to connect to Google Places API');
      }
    } catch (e) {
      if (kDebugMode) print("PlacesService Error: $e");
      // Hatanın kendisini yeniden fırlatarak UI'da göstermemizi sağlıyoruz.
      rethrow;
    }
  }
}