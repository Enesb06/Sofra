// FİNAL TASARIM v3: lib/screens/dashboard_page.dart (İkonik Yemek Vitrini)

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:intl/intl.dart';

import '../services/database_helper.dart';
import '../services/sync_parser.dart';
import '../models/food_details.dart';
import '../models/tasted_food_model.dart';
import '../models/city_model.dart';
import 'food_details_page.dart';

import '../models/city_food_model.dart';
import '../models/route_model.dart';
import '../models/route_stop_model.dart';

typedef TabNavigationRequest = void Function(int tabIndex, {City? city});
typedef FoodNavigationRequest = void Function(FoodDetails food);

class DashboardPage extends StatefulWidget {
  final TabNavigationRequest onNavigateToTab;
    final FoodNavigationRequest onNavigateToFood; // <-- Yeni parametre
  const DashboardPage({super.key, required this.onNavigateToTab,required this.onNavigateToFood, });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isReady = false;
  bool _isError = false;
  String _errorMessage = "";

  late Future<List<Map<String, dynamic>>> _featuredDishesFuture;
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
      setState(() { _isReady = true; });
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
    _featuredDishesFuture = DatabaseHelper.instance.getFeaturedDishesWithCity();
    _latestMemory = await DatabaseHelper.instance.getLatestTastedFood();
    _stats = await DatabaseHelper.instance.getTastedFoodStats();
    if(mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isError ? _buildErrorScreen() : AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isReady ? _buildDashboard() : _buildLoadingSkeleton(),
      ),
    );
  }

  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          pinned: true,
          expandedHeight: 120.0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text( 'DishAI Envoy', style: TextStyle( color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22,), ),
            background: Container(color: Colors.transparent),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            _buildSectionHeader("Featured Dishes"),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _featuredDishesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 220); 
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox(height: 220, child: Center(child: Text("No featured dishes found.")));
                }
                final dishes = snapshot.data!;
                return _DishCarousel(
                  dishes: dishes,
                  onDishTapped: (dishData) {
                    final food = FoodDetails.fromJson(dishData);
                    widget.onNavigateToFood(food);
                  },
                  onCityTapped: (dishData) {
                    final city = City(id: dishData['cityId'], cityName: dishData['cityName'], normalizedCityName: '');
                    widget.onNavigateToTab(1, city: city);
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            
            if (_latestMemory != null || _stats != null && (_stats!['totalDishes']! > 0)) ...[
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
      child: Text( title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54), ),
    );
  }
  
  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          const SizedBox(height: 140),
          Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0), child: _SkeletonBox(width: 220, height: 24), ),
          const SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 220, margin: 8),
          const SizedBox(height: 24),
          Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0), child: _SkeletonBox(width: 200, height: 24), ),
          const SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 104, margin: 16),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() { return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.wifi_off_rounded, color: Colors.red.shade300, size: 64), const SizedBox(height: 16), Text( "Connection Error", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center, ), const SizedBox(height: 8), Text( _errorMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700), ), ], ), ), ); }
}

class _DishCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> dishes; final Function(Map<String, dynamic>) onDishTapped; final Function(Map<String, dynamic>) onCityTapped;
  const _DishCarousel({required this.dishes, required this.onDishTapped, required this.onCityTapped});
  @override State<_DishCarousel> createState() => _DishCarouselState();
}

class _DishCarouselState extends State<_DishCarousel> {
  late final PageController _pageController; Timer? _timer; int _currentPage = 0;
  @override void initState() { super.initState(); _pageController = PageController(initialPage: _currentPage, viewportFraction: 0.85); _startTimer(); }
  void _startTimer() { if (widget.dishes.length > 1) { _timer = Timer.periodic(const Duration(seconds: 5), (timer) { _currentPage = (_currentPage + 1) % widget.dishes.length; if (_pageController.hasClients) { _pageController.animateToPage( _currentPage, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut, ); } }); } }
  @override void dispose() { _timer?.cancel(); _pageController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { return Column( children: [ SizedBox( height: 220, child: PageView.builder( controller: _pageController, itemCount: widget.dishes.length, onPageChanged: (index) => setState(() { _currentPage = index; }), itemBuilder: (context, index) { final dishData = widget.dishes[index]; final foodName = dishData['turkish_name'] as String; final cityName = dishData['cityName'] as String; final imageUrl = dishData['featured_image_url'] as String?; if (imageUrl == null || imageUrl.isEmpty) { return Container( margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration( borderRadius: BorderRadius.circular(20), color: Colors.grey.shade300, ), child: Center( child: Text("$foodName\n(Image not found)", textAlign: TextAlign.center),),); } return GestureDetector( onTap: () => widget.onDishTapped(dishData), child: Container( margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration( borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 6))] ), child: ClipRRect( borderRadius: BorderRadius.circular(20), child: Stack( fit: StackFit.expand, children: [ CachedNetworkImage( imageUrl: imageUrl, fit: BoxFit.cover, errorWidget: (context, url, error) => const Icon(Icons.error) ), Container( decoration: BoxDecoration( gradient: LinearGradient( colors: [Colors.black.withOpacity(0.8), Colors.transparent, Colors.black.withOpacity(0.8)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.5, 1.0]))), Positioned( bottom: 20, left: 20, right: 20, child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(foodName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2)])), const SizedBox(height: 4), InkWell( onTap: () => widget.onCityTapped(dishData), child: Container( padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration( color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(8)), child: Row( mainAxisSize: MainAxisSize.min, children: [ const Icon(Icons.location_on, color: Colors.white70, size: 14), const SizedBox(width: 4), Text(cityName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)), ], ), ), ), ], ), ), ], ), ), ), ); }, ), ), if (widget.dishes.length > 1) ...[ const SizedBox(height: 16), DotsIndicator( dotsCount: widget.dishes.length, position: _currentPage.toDouble(), decorator: DotsDecorator( activeColor: Colors.indigo, size: const Size.square(9.0), activeSize: const Size(18.0, 9.0), activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)), ), ), ], ], ); }
}
class _LatestMemoryCard extends StatelessWidget { final TastedFood memory; const _LatestMemoryCard({required this.memory}); @override Widget build(BuildContext context) { return Card( margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.all(12.0), child: Row( children: [ ClipRRect( borderRadius: BorderRadius.circular(8), child: memory.imagePath != null ? Image.file(File(memory.imagePath!), width: 80, height: 80, fit: BoxFit.cover) : Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.photo_size_select_actual_outlined)), ), const SizedBox(width: 16), Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text("Your Latest Memory", style: TextStyle(color: Colors.grey)), Text(memory.foodName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text("in ${memory.cityName} on ${DateFormat('dd MMM yyyy').format(DateTime.parse(memory.tastedDate))}"), ], ), ), ], ), ), ); } }
class _StatsCard extends StatelessWidget { final Map<String, int> stats; const _StatsCard({required this.stats}); @override Widget build(BuildContext context) { return Card( margin: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.symmetric(vertical: 16.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ _StatItem(count: stats['totalDishes'] ?? 0, label: "Dishes Tasted"), _StatItem(count: stats['citiesVisited'] ?? 0, label: "Cities Visited"), ], ), ), ); } }
class _StatItem extends StatelessWidget { final int count; final String label; const _StatItem({required this.count, required this.label}); @override Widget build(BuildContext context) { return Column( children: [ Text(count.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)), Text(label), ], ); } }
class _EmptyStateCard extends StatelessWidget { const _EmptyStateCard(); @override Widget build(BuildContext context) { return Card( margin: const EdgeInsets.all(16), color: Colors.indigo.withOpacity(0.05), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.all(20.0), child: Column( children: [ const Icon(Icons.menu_book_rounded, size: 40, color: Colors.indigo), const SizedBox(height: 12), const Text("Your Flavor Passport is Empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), const Text("Start logging the dishes you taste to see your journey here!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)), ], ), ), ); } }
class _SkeletonBox extends StatelessWidget { final double width; final double height; final double margin; const _SkeletonBox({ required this.width, required this.height, this.margin = 0 }); @override Widget build(BuildContext context) { return Container( width: width, height: height, margin: EdgeInsets.all(margin), decoration: BoxDecoration( color: Colors.black, borderRadius: BorderRadius.circular(8), ), ); } }