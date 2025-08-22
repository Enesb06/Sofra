// FİNAL TASARIM: lib/screens/dashboard_page.dart (Profesyonel Gastronomi Paneli)

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../services/database_helper.dart';
import '../services/sync_parser.dart';
import '../models/food_details.dart';
import '../models/tasted_food_model.dart';
import 'food_details_page.dart';

// Diğer modeller
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
  // Durum Yönetimi
  bool _isReady = false;
  bool _isError = false;
  String _errorMessage = "";
  
  // Dinamik Veriler
  FoodDetails? _featuredFood;
  TastedFood? _latestMemory;
  Map<String, int>? _stats;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    final bool syncSuccess = await _startSync();
    if (syncSuccess && mounted) {
      await _loadDashboardData();
      setState(() {
        _isReady = true;
      });
    }
  }

  Future<bool> _startSync() async {
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
      return true;
    } catch (e) {
      if (kDebugMode) print("❗️❗️❗️ DASHBOARD SYNC HATA: $e");
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = "Failed to sync data.\nPlease check your internet connection and restart the app.";
        });
      }
      return false;
    }
  }

  Future<void> _loadDashboardData() async {
    final featured = await DatabaseHelper.instance.getFeaturedFood();
    final latest = await DatabaseHelper.instance.getLatestTastedFood();
    final statistics = await DatabaseHelper.instance.getTastedFoodStats();
    
    if (mounted) {
      setState(() {
        _featuredFood = featured;
        _latestMemory = latest;
        _stats = statistics;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isError
          ? _buildErrorScreen()
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _isReady ? _buildDashboard() : _buildLoadingSkeleton(),
            ),
    );
  }

  // --- ARAYÜZ OLUŞTURMA METOTLARI ---

  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent, // Kaydırınca renk değişimini engeller
          pinned: true,
          expandedHeight: 120.0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(
              'DishAI Envoy',
              style: TextStyle(
                color: Colors.black87, 
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            background: Container(color: Colors.transparent),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 16),
            if (_featuredFood != null) ...[
              _buildSectionHeader("Envoy's Recommendation"),
              _FeaturedCard(food: _featuredFood!),
              const SizedBox(height: 24),
            ],
            
            if (_latestMemory != null || _stats != null) ...[
              _buildSectionHeader("Your Culinary Journey"),
              if(_latestMemory != null) _LatestMemoryCard(memory: _latestMemory!),
              if(_stats != null) const SizedBox(height: 16),
              if(_stats != null) _StatsCard(stats: _stats!),
            ] else ...[
              _EmptyStateCard()
            ],
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }
  
  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(0), // SliverAppBar ile uyumlu olması için
        children: [
          const SizedBox(height: 140), // SliverAppBar boşluğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _SkeletonBox(width: 220, height: 24),
          ),
          const SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 200, margin: 16),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _SkeletonBox(width: 200, height: 24),
          ),
          const SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 104, margin: 16),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.red.shade300, size: 64),
            const SizedBox(height: 16),
            Text( "Connection Error", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center, ),
            const SizedBox(height: 8),
            Text( _errorMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700), ),
          ],
        ),
      ),
    );
  }
}

// --- TASARIM WIDGET'LARI ---

class _FeaturedCard extends StatelessWidget {
  final FoodDetails food;
  const _FeaturedCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FoodDetailsPage(food: food))),
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: CachedNetworkImageProvider(food.imageUrl ?? ''),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.turkishName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2)])),
                Text(food.englishName, style: const TextStyle(color: Colors.white70, fontSize: 16, shadows: [Shadow(blurRadius: 2)])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LatestMemoryCard extends StatelessWidget {
  final TastedFood memory;
  const _LatestMemoryCard({required this.memory});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: memory.imagePath != null
                  ? Image.file(File(memory.imagePath!), width: 80, height: 80, fit: BoxFit.cover)
                  : Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.photo_size_select_actual_outlined)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Your Latest Memory", style: TextStyle(color: Colors.grey)),
                  Text(memory.foodName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("in ${memory.cityName} on ${DateFormat('dd MMM yyyy').format(DateTime.parse(memory.tastedDate))}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(count: stats['totalDishes'] ?? 0, label: "Dishes Tasted"),
            _StatItem(count: stats['citiesVisited'] ?? 0, label: "Cities Visited"),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count; final String label;
  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
        Text(label),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.indigo.withOpacity(0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.menu_book_rounded, size: 40, color: Colors.indigo),
            const SizedBox(height: 12),
            const Text("Your Flavor Passport is Empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Start logging the dishes you taste to see your journey here!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width; final double height; final double margin;
  const _SkeletonBox({ required this.width, required this.height, this.margin = 0 });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height, margin: EdgeInsets.all(margin),
      decoration: BoxDecoration( color: Colors.black, borderRadius: BorderRadius.circular(8), ),
    );
  }
}