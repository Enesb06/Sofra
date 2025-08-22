// GÜNCELLENMİŞ DOSYA: lib/screens/dashboard_page.dart (Shimmer Efekti ile)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart'; // <-- YENİ PAKETİ İMPORT ET

import '../services/database_helper.dart';
import '../services/sync_parser.dart';
import '../models/food_details.dart';
import '../models/city_model.dart';
import '../models/city_food_model.dart';
import '../models/route_model.dart';
import '../models/route_stop_model.dart';

typedef TabNavigationRequest = void Function(int tabIndex);

class DashboardPage extends StatefulWidget {
  final TabNavigationRequest onNavigateToTab;
  const DashboardPage({super.key, required this.onNavigateToTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isReady = false;
  bool _isError = false;
  String _errorMessage = ""; // Hata mesajını tutmak için

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    // Senkronizasyon 1 saniyeden kısa sürerse, shimmer efektini görmek için
    // küçük bir gecikme ekleyebiliriz. Bu, kullanıcı deneyimini daha tutarlı hale getirir.
    // await Future.delayed(const Duration(milliseconds: 1500)); // İsteğe bağlı
    try {
      final foodResponse = await Supabase.instance.client.from('foods').select();
      final List<FoodDetails> foodList = await compute(parseFoods, foodResponse as List);
      await DatabaseHelper.instance.batchUpsert(foodList);

      final citiesResponse = await Supabase.instance.client.from('cities').select();
      final List<City> cityList = await compute(parseCities, citiesResponse as List);
      await DatabaseHelper.instance.batchUpsertCities(cityList);

      final cityFoodsResponse = await Supabase.instance.client.from('city_foods').select();
      final List<CityFood> cityFoodList = await compute(parseCityFoods, cityFoodsResponse as List);
      await DatabaseHelper.instance.batchUpsertCityFoods(cityFoodList);
        
      final routesResponse = await Supabase.instance.client.from('routes').select();
      final List<RouteModel> routeList = await compute(parseRoutes, routesResponse as List);
      await DatabaseHelper.instance.batchUpsertRoutes(routeList);

      final stopsResponse = await Supabase.instance.client.from('route_stops').select();
      final List<RouteStop> stopList = await compute(parseRouteStops, stopsResponse as List);
      await DatabaseHelper.instance.batchUpsertRouteStops(stopList);
      
      if (mounted) {
        setState(() { _isReady = true; });
      }
    } catch (e) {
      if (kDebugMode) print("❗️❗️❗️ DASHBOARD SYNC HATA: $e");
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = "Failed to sync data.\nPlease check your internet connection and restart the app.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DishAI Home'),
        backgroundColor: Colors.indigo.shade200,
      ),
      // Hata varsa hata ekranını, yoksa duruma göre iskelet veya ana ekranı göster
      body: _isError
          ? _buildErrorScreen()
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _isReady ? _buildDashboard() : _buildLoadingSkeleton(),
            ),
    );
  }

  // Yükleme sırasında gösterilecek olan İSKELET arayüzü
  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          // Başlıklar için iskelet
          _SkeletonBox(width: 200, height: 32),
          SizedBox(height: 8),
          _SkeletonBox(width: 250, height: 20),
          SizedBox(height: 24),
          // Kartlar için iskelet
          _DashboardCardSkeleton(),
          _DashboardCardSkeleton(),
          _DashboardCardSkeleton(),
          _DashboardCardSkeleton(),
        ],
      ),
    );
  }

  // Veriler hazır olduğunda gösterilecek olan ana arayüz
  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text( "Welcome to DishAI!", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), ),
        Text( "What would you like to do today?", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600), ),
        const SizedBox(height: 24),
        _DashboardCard( title: "Recognize a Dish", subtitle: "Identify a dish from a photo", icon: Icons.camera_alt_outlined, color: Colors.deepOrange.shade300, onTap: () => widget.onNavigateToTab(0), ),
        _DashboardCard( title: "Discover Flavors", subtitle: "Explore the culinary map of Turkey", icon: Icons.explore_outlined, color: Colors.blue.shade300, onTap: () => widget.onNavigateToTab(1), ),
        _DashboardCard( title: "Gourmet Routes", subtitle: "Follow curated food tours", icon: Icons.route_outlined, color: Colors.purple.shade300, onTap: () => widget.onNavigateToTab(3), ),
        _DashboardCard( title: "Scan a Menu", subtitle: "Instantly translate menu items", icon: Icons.menu_book_outlined, color: Colors.teal.shade300, onTap: () => widget.onNavigateToTab(4), ),
      ],
    );
  }

  // Hata durumunda gösterilecek ekran
  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.red.shade300, size: 64),
            const SizedBox(height: 16),
            Text(
              "Connection Error",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

// --- YENİ WIDGET'LAR ---

// Ana sayfa kartlarının iskelet versiyonu
class _DashboardCardSkeleton extends StatelessWidget {
  const _DashboardCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          children: [
            _SkeletonBox(width: 40, height: 40, isCircle: true),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 150, height: 18),
                  SizedBox(height: 8),
                  _SkeletonBox(width: 200, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// İskelet arayüzünde kullanılacak temel gri kutu
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final bool isCircle;
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black, // Shimmer bu rengin üzerine efekt uygulayacak
        borderRadius: isCircle ? null : BorderRadius.circular(8),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}

// Mevcut _DashboardCard widget'ında hiçbir değişiklik yok.
class _DashboardCard extends StatelessWidget {
  final String title; final String subtitle; final IconData icon; final Color color; final VoidCallback onTap;
  const _DashboardCard({ required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap, });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16), elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color), const SizedBox(width: 20),
              Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(subtitle, style: TextStyle(color: Colors.grey.shade600)), ], ), ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}