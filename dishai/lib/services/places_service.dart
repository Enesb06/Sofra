// Lütfen bu dosyanın içeriğini projenizdeki lib/services/places_service.dart dosyasıyla tamamen değiştirin.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Model sınıfında değişiklik yok.
class PlaceSearchResult {
  final String placeId;
  final String name;
  final String? address;
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

  // Bu metotlarda değişiklik yok.
  Future<Position> getCurrentLocation() async {
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
  
  String getPhotoUrl(String photoReference) {
    return "$_baseUrl/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey";
  }

  // <-- ASIL GÜNCELLEME BURADA BAŞLIYOR -->
  // Metot artık String? foodCategory parametresi alıyor.
  Future<List<PlaceSearchResult>> findRestaurants(String foodName, String? foodCategory, Position position) async {
    final location = "${position.latitude},${position.longitude}";
    List<PlaceSearchResult> finalResults = [];

    // --- TATLI, HAMUR İŞİ & KAHVALTI İÇİN ÖZEL ARAMA STRATEJİSİ ---
    if (foodCategory == 'dessert' || foodCategory == 'pastry_bakery' || foodCategory == 'breakfast') {
      if (kDebugMode) print("'$foodCategory' kategorisi için özel arama stratejisi başlatıldı...");

      // Kategoriye özel genel bir arama terimi belirliyoruz.
      String fallbackKeyword;
      switch(foodCategory) {
        case 'dessert':
          fallbackKeyword = 'tatlı';
          break;
        case 'pastry_bakery':
          fallbackKeyword = 'pide fırın';
          break;
        case 'breakfast':
          fallbackKeyword = 'kahvaltı';
          break;
        default:
          fallbackKeyword = foodName;
      }
      
      // 1. ÖNCELİK: Restoranlar (Geleneksel Tatlıcılar, Pideciler, Kahvaltı Salonları)
      final restaurantResults = await _performNearbySearch(keyword: '"$foodName" OR "$fallbackKeyword"', placeType: 'restaurant', location: location);
      finalResults.addAll(restaurantResults);
      
      // 2. ÖNCELİK: Fırınlar / Pastaneler (Bakery)
      final bakeryResults = await _performNearbySearch(keyword: '"$foodName"', placeType: 'bakery', location: location);
      finalResults.addAll(bakeryResults);

      // 3. ÖNCELİK (SON TERCİH): Kafeler (Cafe)
      final cafeResults = await _performNearbySearch(keyword: '"$foodName"', placeType: 'cafe', location: location);
      finalResults.addAll(cafeResults);
    }
    // --- DİĞER TÜM KATEGORİLER İÇİN STANDART ARAMA STRATEJİSİ ---
    else {
      if (kDebugMode) print("'$foodCategory' kategorisi için standart arama stratejisi başlatıldı...");
      
      // 1. Önce doğrudan yemeğin adıyla restoranları arayalım.
      final specificResults = await _performNearbySearch(keyword: '"$foodName"', placeType: 'restaurant', location: location);
      finalResults.addAll(specificResults);
      
      // 2. Eğer spesifik arama sonuç vermezse, genel "Türk Restoranı" araması yapalım.
      if (finalResults.isEmpty) {
         if (kDebugMode) print("Spesifik arama sonuç vermedi, 'Turkish Restaurant' için genel arama yapılıyor...");
         final fallbackResults = await _performNearbySearch(keyword: 'Turkish Restaurant', placeType: 'restaurant', location: location);
         finalResults.addAll(fallbackResults);
      }
    }
    
    // Sonuçları birleştirdikten sonra, tekrarlanan yerleri (aynı place_id'ye sahip) temizleyelim.
    final uniqueResults = <String, PlaceSearchResult>{};
    for (var result in finalResults) {
      uniqueResults[result.placeId] = result;
    }
    
    return uniqueResults.values.toList();
  }

  // Yardımcı metot.
  Future<List<PlaceSearchResult>> _performNearbySearch({
    required String keyword,
    required String placeType,
    required String location,
  }) async {
    final uri = Uri.parse("$_baseUrl/nearbysearch/json").replace(queryParameters: {
      'location': location,
      'radius': '5000',
      'keyword': keyword,
      'type': placeType,
      'key': apiKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final List results = data['results'];
          return results.map((place) => PlaceSearchResult.fromJson(place)).toList();
        } else {
          throw Exception(data['error_message'] ?? 'Google Places API Error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to connect to Google Places API');
      }
    } catch (e) {
      if (kDebugMode) print("PlacesService Error during search for '$keyword' with type '$placeType': $e");
      return []; // Hata durumunda boş liste dön, uygulama çökmesin.
    }
  }
}