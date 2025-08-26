// GÜNCELLENMİŞ VE DAHA DAYANIKLI DOSYA: lib/screens/routes_list_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../services/database_helper.dart';
import '../models/city_model.dart';
import '../models/route_model.dart';
import '../services/sync_service.dart';
import 'route_detail_page.dart';

class RoutesListPage extends StatefulWidget {
  const RoutesListPage({super.key});

  @override
  State<RoutesListPage> createState() => _RoutesListPageState();
}

class _RoutesListPageState extends State<RoutesListPage> {
  // Verileri FutureBuilder'da tutmak yerine, doğrudan state'te tutacağız.
  List<City> _citiesWithRoutes = [];
  List<RouteModel> _allRoutes = [];
  List<RouteModel> _filteredRoutes = [];
  int? _selectedCityId;

  // Future'ı state'ten kaldırdık.
  // late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    // initState'te artık veri yükleme yok.
  }

  // Veri yükleme metodu aynı kalıyor.
  Future<Map<String, dynamic>> _loadData() async {
    print("⏳ ROUTES_LIST_PAGE: Veritabanından veriler çekilmeye başlanıyor...");
    final allCities = await DatabaseHelper.instance.getAllCities();
    final allRoutes = <RouteModel>[];
    final citiesWithRoutesSet = <int>{};

    for (var city in allCities) {
      final routesForCity = await DatabaseHelper.instance.getRoutesForCity(city.id);
      if (routesForCity.isNotEmpty) {
        allRoutes.addAll(routesForCity);
        citiesWithRoutesSet.add(city.id);
      }
    }

    final citiesWithRoutes = allCities.where((city) => citiesWithRoutesSet.contains(city.id)).toList();
    
    print("📦 ROUTES_LIST_PAGE: ${allRoutes.length} rota ve ${citiesWithRoutes.length} şehir bulundu.");

    return {
      'cities': citiesWithRoutes,
      'routes': allRoutes,
    };
  }

  void _filterRoutes(int? cityId) {
    setState(() {
      _selectedCityId = cityId;
      if (cityId == null) {
        _filteredRoutes = _allRoutes;
      } else {
        _filteredRoutes = _allRoutes.where((route) => route.cityId == cityId).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gourmet Routes'),
        backgroundColor: Colors.purple.shade300,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: syncCompletedNotifier,
        builder: (context, isSyncComplete, child) {
          print("🚦 ROUTES_LIST_PAGE: Sinyal dinleniyor. Sync durumu: $isSyncComplete");
          
          if (!isSyncComplete) {
            return _buildLoadingSkeleton();
          }

          // SENKRONİZASYON BİTTİĞİNDE FutureBuilder'ı KULLANARAK VERİYİ BİR KEZ YÜKLE
          return FutureBuilder<Map<String, dynamic>>(
            // Future'ı doğrudan burada çağırıyoruz. Bu, her zaman doğru anda çalışmasını sağlar.
            future: _loadData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingSkeleton(); // Veri yüklenirken de skeleton göster
              }

              if (snapshot.hasError) {
                return const Center(child: Text('An error occurred while loading routes.'));
              }
              
              if (!snapshot.hasData) {
                return const Center(child: Text('Could not load route data.'));
              }

              // Veriler başarıyla çekildi. State'i güncelle ve UI'ı çiz.
              final data = snapshot.data!;
              _citiesWithRoutes = data['cities'];
              _allRoutes = data['routes'];

              // Filtre seçilmemişse veya ilk yüklemeyse, tüm rotaları göster
              if (_filteredRoutes.isEmpty && _allRoutes.isNotEmpty && _selectedCityId == null) {
                 _filteredRoutes = _allRoutes;
              }

              if (_allRoutes.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "No gourmet routes have been added yet.\nCheck back later!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  _buildCityFilters(),
                  Expanded(child: _buildRoutesList()),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Bu metot artık parametre almıyor, state'teki değişkeni kullanıyor.
  Widget _buildCityFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Cities'),
            selected: _selectedCityId == null,
            onSelected: (_) => _filterRoutes(null),
          ),
          const SizedBox(width: 8),
          ..._citiesWithRoutes.map((city) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(city.cityName),
                  selected: _selectedCityId == city.id,
                  onSelected: (_) => _filterRoutes(city.id),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRoutesList() {
    if (_filteredRoutes.isEmpty) {
      // Bu koşul artık sadece filtreleme sonrası boş sonuçlar için geçerli olacak.
      // İlk yüklemedeki "rota yok" durumu FutureBuilder içinde ele alınıyor.
      return const Center(
        child: Text(
          'No routes found for the selected city.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredRoutes.length,
      itemBuilder: (context, index) {
        final route = _filteredRoutes[index];
        return _RouteCard(route: route);
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: List.generate(3, (index) => _buildSkeletonCard()),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.white,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 100, height: 20, color: Colors.white),
                Container(width: 80, height: 20, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// _RouteCard widget'ında değişiklik yok
class _RouteCard extends StatelessWidget {
  final RouteModel route;
  const _RouteCard({required this.route});

  // ... (içeriği aynı)
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RouteDetailPage(route: route)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardImage(),
            _buildCardInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage() {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: route.coverImageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.map, size: 80, color: Colors.grey),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Text(
            route.titleEn,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardInfo(BuildContext context) {
    IconData durationIcon = Icons.timer_outlined;
    String durationLabel = '-- min';

    if (route.durationWalkingMins != null) {
      durationIcon = Icons.directions_walk;
      durationLabel = '${route.durationWalkingMins} min';
    } else if (route.durationDrivingMins != null) {
      durationIcon = Icons.directions_car;
      durationLabel = '${route.durationDrivingMins} min';
    } else if (route.durationTransitMins != null) {
      durationIcon = Icons.directions_bus;
      durationLabel = '${route.durationTransitMins} min';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _infoChip(
            context,
            icon: durationIcon,
            label: durationLabel,
          ),
          _infoChip(
            context,
            icon: Icons.hiking_outlined,
            label: route.difficulty,
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _infoChip(BuildContext context, {required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}