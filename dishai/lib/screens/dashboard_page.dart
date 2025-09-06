// FİNAL TASARIM v5: lib/screens/dashboard_page.dart (Üçlü Eylem Butonları ile)

import 'package:dishai/screens/add_memory_page.dart';

import 'dart:async';
import 'dart:io';
import 'package:dishai/screens/add_memory_page.dart';
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

import '../services/sync_service.dart';
import '../models/quest_model.dart';
import '../services/quest_service.dart';
import 'quests_page.dart';
import '../services/badge_check_service.dart';
import 'favorites_page.dart';
import 'journal_page.dart'; 
import 'package:google_fonts/google_fonts.dart'; 
import '../models/festival_model.dart';
import 'festivals_page.dart';
import 'festival_detail_page.dart';


typedef TabNavigationRequest = void Function(int tabIndex, {City? city});
typedef FoodNavigationRequest = void Function(FoodDetails food);

class DashboardPage extends StatefulWidget {
  final TabNavigationRequest onNavigateToTab;
  final FoodNavigationRequest onNavigateToFood;
  const DashboardPage({
    super.key,
    required this.onNavigateToTab,
    required this.onNavigateToFood,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isReady = false;
  bool _isError = false;
  String _errorMessage = "";

  late Future<List<Map<String, dynamic>>> _featuredDishesFuture;
  TastedFood? _latestMemory;
  QuestProgress? _currentQuestProgress;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
    journalUpdatedNotifier.addListener(_onJournalUpdate);
  }

  @override
  void dispose() {
    journalUpdatedNotifier.removeListener(_onJournalUpdate);
    super.dispose();
  }

  void _onJournalUpdate() async {
    if (mounted) {
      print(
          "🔄 Dashboard: Journal güncelleme sinyali alındı, veriler yenileniyor...");
      await _loadDashboardData();
      if (mounted) {
        await BadgeCheckService.checkAndAwardBadges(context);
      }
    }
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
      final foodResponse =
          await Supabase.instance.client.from('foods').select();
      final List<FoodDetails> foodList =
          await compute(parseFoods, foodResponse as List);
      await DatabaseHelper.instance.batchUpsert(foodList);
      final citiesResponse =
          await Supabase.instance.client.from('cities').select();
      final List<City> cityList =
          await compute(parseCities, citiesResponse as List);
      await DatabaseHelper.instance.batchUpsertCities(cityList);
      final cityFoodsResponse =
          await Supabase.instance.client.from('city_foods').select();
      final List<CityFood> cityFoodList =
          await compute(parseCityFoods, cityFoodsResponse as List);
      await DatabaseHelper.instance.batchUpsertCityFoods(cityFoodList);
      final routesResponse =
          await Supabase.instance.client.from('routes').select();
      final List<RouteModel> routeList =
          await compute(parseRoutes, routesResponse as List);
      await DatabaseHelper.instance.batchUpsertRoutes(routeList);
      final stopsResponse =
          await Supabase.instance.client.from('route_stops').select();
            final festivalsResponse =
          await Supabase.instance.client.from('festivals').select();
      final List<RouteStop> stopList =
          await compute(parseRouteStops, stopsResponse as List);
      await DatabaseHelper.instance.batchUpsertRouteStops(stopList);

       final List<Festival> festivalList =
          await compute(parseFestivals, festivalsResponse as List);
      await DatabaseHelper.instance.batchUpsertFestivals(festivalList);
      syncCompletedNotifier.value = true;
      return true;
    } catch (e) {
      if (kDebugMode) print("❗️❗️❗️ DASHBOARD SYNC HATA: $e");
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage =
              "Failed to sync data.\nPlease check your internet connection and restart the app.";
        });
      }
      return false;
    }
  }

  Future<void> _loadDashboardData() async {
    _featuredDishesFuture = DatabaseHelper.instance.getFeaturedDishesWithCity();
    _latestMemory = await DatabaseHelper.instance.getLatestTastedFood();

    final List<TastedFoodInfo> tastedInfo =
        await DatabaseHelper.instance.getTastedFoodInfoForQuests();

    final Quest currentQuest = QuestService.getNextUncompletedQuest(tastedInfo);

    final int progressCount =
        QuestService.calculateProgressForQuest(currentQuest, tastedInfo);

    _currentQuestProgress = QuestProgress(
      quest: currentQuest,
      currentProgress: progressCount,
    );

    if (mounted) setState(() {});
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

  // KENDİ DOSYANDAKİ _buildDashboard METODUNU BUNUNLA DEĞİŞTİR

  Widget _buildDashboard() {
   

    return CustomScrollView(
      slivers: [
                 SliverAppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          pinned: true,
          expandedHeight: 120.0,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text(
              'Sofra',
              style: GoogleFonts.playfairDisplay(
                color: Theme.of(context).colorScheme.primary, // Rengi temadan alalım, daha canlı dursun
                fontWeight: FontWeight.bold,
                fontSize: 36, // <-- YAZI BOYUTUNU BÜYÜTTÜK
                letterSpacing: 1.2, // Harf aralığını hafifçe açtık
              ),
            ),
            // Başlığın kaydırıldığında küçülürkenki dikey pozisyonunu ayarlar
            collapseMode: CollapseMode.pin, 
            background: Container(color: Colors.transparent),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            _buildSectionHeader("Featured Dishes"),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _featuredDishesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) { return const SizedBox(height: 220); }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) { return const SizedBox(height: 220, child: Center(child: Text("No featured dishes found."))); }
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

            _buildSectionHeader("Your Culinary Journey"),
            
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: GridView.count(
                crossAxisCount: 4, // Yan yana 4 eleman
                shrinkWrap: true, // İçeriği kadar yer kaplamasını sağla
                physics: const NeverScrollableScrollPhysics(), // GridView'in kendisi kaymasın
                mainAxisSpacing: 8, // Dikey boşluk
                crossAxisSpacing: 8, // Yatay boşluk
                childAspectRatio: 0.85, // Genişliğin yüksekliğe oranı (dikey olarak hafifçe uzun)

                children: [
                  _DashboardActionButton(
                    icon: Icons.add_a_photo_outlined,
                    label: "Add Memory",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddMemoryPage()),
                      );
                    },
                  ),
                  _DashboardActionButton(
                    icon: Icons.auto_stories_outlined,
                    label: "Journal",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const JournalPage()),
                      );
                    },
                  ),
                  _DashboardActionButton(
                    icon: Icons.favorite_border,
                    label: "Favorites",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FavoritesPage()),
                      );
                    },
                  ),
                  _DashboardActionButton(
                    icon: Icons.emoji_events_outlined,
                    label: "Achievements",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QuestsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

             const _FestivalsSection(),

            // Görev kartı artık kendi koşuluyla, her zaman görünür olacak.
            if (_currentQuestProgress != null)
              _FlavorQuestCard(progress: _currentQuestProgress!),

            // "Son Anı" kartı ise sadece bir anı varsa görünecek.
            if (_latestMemory != null) 
              _LatestMemoryCard(memory: _latestMemory!),
            
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
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _SkeletonBox(width: 220, height: 24),
          ),
          const SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 220, margin: 8),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _SkeletonBox(width: 200, height: 24),
          ),
          const SizedBox(height: 12),
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
            Text(
              "Connection Error",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
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

class _DashboardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _DashboardActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Butonun rengini ve arkaplanını belirliyoruz
    final color = Theme.of(context).colorScheme.primary;
    final bgColor = color.withOpacity(0.08);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16), // Daha yuvarlak kenarlar
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2))
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32), // İkon biraz daha büyük
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                label,
                textAlign: TextAlign.center,
                // Metnin en fazla 2 satır olmasını sağlıyoruz
                maxLines: 2, 
                // Taşma durumunda kelimeleri kesmek yerine ... koyar
                overflow: TextOverflow.ellipsis, 
                style: TextStyle(
                  fontSize: 13, // Yazı boyutu biraz küçültüldü
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.2, // Satır yüksekliği ayarlandı
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DishCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> dishes;
  final Function(Map<String, dynamic>) onDishTapped;
  final Function(Map<String, dynamic>) onCityTapped;
  const _DishCarousel(
      {required this.dishes,
      required this.onDishTapped,
      required this.onCityTapped});
  @override
  State<_DishCarousel> createState() => _DishCarouselState();
}

class _DishCarouselState extends State<_DishCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: _currentPage, viewportFraction: 0.85);
    _startTimer();
  }

  void _startTimer() {
    if (widget.dishes.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!mounted) return;
        _currentPage = (_currentPage + 1) % widget.dishes.length;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.dishes.length,
            onPageChanged: (index) => setState(() {
              _currentPage = index;
            }),
            itemBuilder: (context, index) {
              final dishData = widget.dishes[index];
              final foodName = dishData['turkish_name'] as String;
              final cityName = dishData['cityName'] as String;
              final imageUrl = dishData['featured_image_url'] as String?;
              if (imageUrl == null || imageUrl.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.shade300,
                  ),
                  child: Center(
                    child: Text("$foodName\n(Image not found)",
                        textAlign: TextAlign.center),
                  ),
                );
              }
              return GestureDetector(
                onTap: () => widget.onDishTapped(dishData),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: Offset(0, 6))
                      ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error)),
                        Container(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.8),
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: [0.0, 0.5, 1.0]))),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(foodName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(blurRadius: 2)])),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => widget.onCityTapped(dishData),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      Text(cityName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.dishes.length > 1) ...[
          const SizedBox(height: 16),
          DotsIndicator(
            dotsCount: widget.dishes.length,
            position: _currentPage.toDouble(),
            decorator: DotsDecorator(
              activeColor: Colors.indigo,
              size: const Size.square(9.0),
              activeSize: const Size(18.0, 9.0),
              activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0)),
            ),
          ),
        ],
      ],
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
                  ? Image.file(File(memory.imagePath!),
                      width: 80, height: 80, fit: BoxFit.cover)
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child:
                          const Icon(Icons.photo_size_select_actual_outlined)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Your Latest Memory",
                      style: TextStyle(color: Colors.grey)),
                  Text(memory.foodName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                      "in ${memory.cityName} on ${DateFormat('dd MMM yyyy').format(DateTime.parse(memory.tastedDate))}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double margin;
  const _SkeletonBox(
      {required this.width, required this.height, this.margin = 0});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _FlavorQuestCard extends StatelessWidget {
  final QuestProgress progress;

  const _FlavorQuestCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final double percentage = progress.quest.totalTarget == 0
        ? 0
        : progress.currentProgress / progress.quest.totalTarget;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
       shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(
            12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuestsPage()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Your Next Quest",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "See All",
                    style: TextStyle(
                         color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                      size: 14, color: Theme.of(context).colorScheme.primary),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                progress.quest.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progress.quest.description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${progress.currentProgress} / ${progress.quest.totalTarget}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// lib/screens/dashboard_page.dart DOSYASININ EN ALTINDAN _UpcomingFestivalsCard'I SİL
// VE YERİNE BU ÜÇ YENİ WIDGET'I EKLE:

// --- YENİ BÖLÜM WIDGET'I (ANA KONTROLCÜ) ---
class _FestivalsSection extends StatefulWidget {
  const _FestivalsSection();

  @override
  State<_FestivalsSection> createState() => _FestivalsSectionState();
}

class _FestivalsSectionState extends State<_FestivalsSection> {
  late Future<List<Festival>> _festivalsFuture;

  @override
  void initState() {
    super.initState();
    // Veriyi sadece bir kez yükle
    _festivalsFuture = DatabaseHelper.instance.getUpcomingFestivals(limit: 4);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Festival>>(
      future: _festivalsFuture,
      builder: (context, snapshot) {
        // Veri yoksa veya yükleniyorsa, hiçbir şey gösterme
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final festivals = snapshot.data!;

        return Column(
          children: [
            // "Upcoming Festivals" ve "See All >" başlığı
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 8.0, 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Upcoming Festivals",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FestivalsPage()),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("See All"),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Yatay kaydırılabilir festival kartları
            SizedBox(
              height: 220, // Liste yüksekliğini belirliyoruz
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: festivals.length,
                itemBuilder: (context, index) {
                  return _MiniFestivalCard(festival: festivals[index]);
                },
              ),
            ),
            const SizedBox(height: 16), // Alt boşluk
          ],
        );
      },
    );
  }
}
// lib/screens/dashboard_page.dart DOSYASININ EN ALTINDAKİ
// _MiniFestivalCard WIDGET'INI BUNUNLA DEĞİŞTİR

class _MiniFestivalCard extends StatelessWidget {
  final Festival festival;
  const _MiniFestivalCard({required this.festival});

  // --- DEĞİŞİKLİK BURADA: Sadece dış köşeyi yuvarlatıyoruz ---
  Widget _buildStatusTag({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        // Sadece sağ üst köşeyi yuvarlatıyoruz.
        // Bu, etikete şık bir "kurdele" efekti verir.
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12.0),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 7,
        ),
      ),
    );
  }
  // --- BİTTİ ---

  @override
  Widget build(BuildContext context) {
    final dateText = '${DateFormat.MMMd().format(festival.startDate)} - ${DateFormat.MMMd().format(festival.endDate)}';

    final now = DateUtils.dateOnly(DateTime.now());
    final startDate = DateUtils.dateOnly(festival.startDate);
    final endDate = DateUtils.dateOnly(festival.endDate);

    final bool isOngoing = !now.isBefore(startDate) && !now.isAfter(endDate);
    final bool isUpcoming = now.isBefore(startDate);

    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FestivalDetailPage(festival: festival)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: festival.coverImageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey.shade200),
                      errorWidget: (context, url, error) => Container(color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported)),
                    ),
                    // Positioned kısmı aynı kalıyor, köşeye sıfır.
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Builder(
                        builder: (context) {
                          if (isOngoing) {
                            return _buildStatusTag(text: 'LIVE NOW', color: Colors.red.shade600);
                          }
                          if (isUpcoming) {
                            return _buildStatusTag(text: 'UPCOMING', color: Colors.green.shade600);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        festival.nameEn,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            dateText,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}