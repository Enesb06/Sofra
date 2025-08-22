// DÜZELTİLMİŞ VE NİHAİ DOSYA: lib/screens/sync_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/database_helper.dart';
// import '../services/sync_service.dart'; // <-- BU SATIRI SİLDİK. ARTIK GEREK YOK.
import '../models/food_details.dart';
import '../models/city_model.dart';
import '../models/city_food_model.dart';
import '../models/route_model.dart';
import '../models/route_stop_model.dart';
import 'home_page.dart';

final supabase = Supabase.instance.client;

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  String _syncStatusMessage = "Envoy is getting ready...";
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    try {
      // SyncService.isSyncCompleted.value = false; // <-- BU SATIRI SİLDİK.
      if (mounted) setState(() { _syncStatusMessage = "Connecting to knowledge base..."; });
      
      // Senkronizasyon adımları (hiçbir değişiklik yok)
      final response = await supabase.from('foods').select();
      final foodList = (response as List).map((item) => FoodDetails.fromJson(item)).toList();
      if (foodList.isNotEmpty) {
        if (mounted) setState(() { _syncStatusMessage = "Syncing local gastronomy atlas..."; });
        await DatabaseHelper.instance.batchUpsert(foodList);
      }
      if (kDebugMode) print("✅ Yemek senkronizasyonu tamamlandı: ${foodList.length} yemek.");

      if (mounted) setState(() { _syncStatusMessage = "Mapping cities..."; });
      final citiesResponse = await supabase.from('cities').select();
      final cityList = (citiesResponse as List).map((e) => City.fromMap(e)).toList();
      await DatabaseHelper.instance.batchUpsertCities(cityList);
      if (kDebugMode) print("✅ Şehir senkronizasyonu tamamlandı: ${cityList.length} şehir.");

      if (mounted) setState(() { _syncStatusMessage = "Building flavor connections..."; });
      final cityFoodsResponse = await supabase.from('city_foods').select();
      final cityFoodList = (cityFoodsResponse as List).map((e) => CityFood.fromMap(e)).toList();
      await DatabaseHelper.instance.batchUpsertCityFoods(cityFoodList);
      if (kDebugMode) print("✅ Şehir-Yemek ilişkileri senkronizasyonu tamamlandı: ${cityFoodList.length} ilişki.");
        
      if (mounted) setState(() { _syncStatusMessage = "Curating gourmet routes..."; });
      final routesResponse = await supabase.from('routes').select();
      final routeList = (routesResponse as List).map((e) => RouteModel.fromMap(e)).toList();
      await DatabaseHelper.instance.batchUpsertRoutes(routeList);
      if (kDebugMode) print("✅ Rota senkronizasyonu tamamlandı: ${routeList.length} rota.");

      if (mounted) setState(() { _syncStatusMessage = "Pinpointing delicious stops..."; });
      final stopsResponse = await supabase.from('route_stops').select();
      final stopList = (stopsResponse as List).map((e) => RouteStop.fromMap(e)).toList();
      await DatabaseHelper.instance.batchUpsertRouteStops(stopList);
      if (kDebugMode) print("✅ Rota durağı senkronizasyonu tamamlandı: ${stopList.length} durak.");

      // SyncService.isSyncCompleted.value = true; // <-- BU SATIRI SİLDİK.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }

    } catch (e) {
      if (kDebugMode) print("❗️❗️❗️ SYNC_PAGE'DE KRİTİK HATA: $e");
      if (mounted) {
        setState(() {
          _isError = true;
          _syncStatusMessage = "Failed to sync data.\nPlease check your internet connection and restart the app.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isError)
              const CircularProgressIndicator(),
            if (_isError)
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                _syncStatusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _isError ? Colors.red.shade700 : Colors.grey.shade700
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}