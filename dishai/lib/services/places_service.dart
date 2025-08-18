// Lütfen bu dosyanın içeriğini projenizdeki lib/services/places_service.dart dosyasıyla tamamen değiştirin.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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

  // --- GOOGLE MANTIĞI İLE ÇALIŞAN YENİ findRestaurants ALGORİTMASI ---
  Future<List<PlaceSearchResult>> findRestaurants({
    required String foodName,
    required String? foodCategory,
    required Position position,
  }) async {
    final location = "${position.latitude},${position.longitude}";
    List<PlaceSearchResult> finalResults = [];

    // --- ARAMA KATMANLARINI OLUŞTUR ---
    List<String> searchKeywords = _buildSearchPyramid(foodName, foodCategory);
    if (kDebugMode) print("🧠 Arama Piramidi: $searchKeywords");

    // --- KATMAN KATMAN ARA VE YETERLİ SONUÇ BULUNCA DUR ---
    for (String keyword in searchKeywords) {
      if (kDebugMode) print("🔍 Aranıyor: '$keyword'...");
      final newResults = await _performNearbySearch(keyword: keyword, placeType: 'restaurant', location: location);
      finalResults.addAll(newResults);

      // Tekrarlananları temizle ve sayısını kontrol et
      final uniqueIds = <String>{};
      final uniqueResults = finalResults.where((place) => uniqueIds.add(place.placeId)).toList();
      finalResults = uniqueResults;
      
      // Eğer yeterli sayıda (örn: 10) sonuç bulduysak, daha fazla arama yapmaya gerek yok.
      if (finalResults.length >= 10) {
        if (kDebugMode) print("✅ Yeterli sonuç bulundu (${finalResults.length}), arama durduruluyor.");
        break;
      }
    }
    
    if (kDebugMode) print("🏆 Toplam benzersiz sonuç: ${finalResults.length}");
    return finalResults;
  }

  // YARDIMCI METOT 1: Arama piramidini (katmanlarını) oluşturan beyin.
  List<String> _buildSearchPyramid(String foodName, String? foodCategory) {
    
    // Kategoriye özel mekan türü anahtar kelimeleri
    const categoryKeywords = {
      'dessert': 'Tatlıcı Pastane',
      'pastry_bakery': 'Pide Lahmacun Fırın',
      'street_food': 'Büfe Dürüm Kokoreç',
      'seafood': 'Balık Restoranı',
      'kebab': 'Kebapçı Izgara',
      'soup': 'Çorbacı',
      'breakfast': 'Kahvaltı Salonu Serpme Kahvaltı',
      'appetizer_meze': 'Meyhane Meze Evi',
    };

    final searchPyramid = <String>{}; // Set kullanarak otomatik tekilleştirme

    // Katman 1: Tam isim
    searchPyramid.add('"$foodName"');

    // Katman 2: Anahtar kelime (örn: "Antep Lahmacunu" -> "Lahmacunu")
    final parts = foodName.split(' ');
    if (parts.length > 1) {
      // "Sütlacı" veya "Kebabı" gibi son ekleri atmak için basit bir kontrol
      String lastPart = parts.last;
      if(lastPart.endsWith('ı') || lastPart.endsWith('i') || lastPart.endsWith('u') || lastPart.endsWith('ü')){
         lastPart = lastPart.substring(0, lastPart.length - 1);
      }
      searchPyramid.add('"$lastPart"');
    }

    // Katman 3: Kategori ipucu
    if (foodCategory != null && categoryKeywords.containsKey(foodCategory)) {
      searchPyramid.add(categoryKeywords[foodCategory]!);
    }

    // Katman 4: Güvenli Liman
    searchPyramid.add('Turkish Restaurant');

    return searchPyramid.toList();
  }

  // YARDIMCI METOT 2: API isteğini yapan kod.
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