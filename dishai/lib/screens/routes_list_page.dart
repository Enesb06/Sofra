// lib/screens/routes_list_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/database_helper.dart';
import '../models/city_model.dart';
import '../models/route_model.dart';
import '../services/sync_service.dart'; // <-- Senkronizasyon servisini import ediyoruz
import 'route_detail_page.dart';

class RoutesListPage extends StatefulWidget {
  const RoutesListPage({super.key});

  @override
  State<RoutesListPage> createState() => _RoutesListPageState();
}

class _RoutesListPageState extends State<RoutesListPage> {
  bool _isLoading = true; // Bu sayfanın kendi içindeki veri yükleme durumu
  List<City> _citiesWithRoutes = [];
  List<RouteModel> _allRoutes = [];
  List<RouteModel> _filteredRoutes = [];
  int? _selectedCityId;

  @override
  void initState() {
    super.initState();
    // Global senkronizasyon durumunu dinlemeye başla
    SyncService.isSyncCompleted.addListener(_onSyncCompleted);
    // Eğer bu sayfa açıldığında senkronizasyon zaten bitmişse, verileri direkt yükle
    if (SyncService.isSyncCompleted.value) {
      _loadData();
    }
  }

  // Senkronizasyon tamamlandığında tetiklenecek olan metot
  void _onSyncCompleted() {
    // Eğer senkronizasyon yeni bittiyse ve bu sayfa hala ekrandaysa...
    if (SyncService.isSyncCompleted.value && mounted) {
      _loadData(); // Verileri yerel veritabanından çek
    }
  }

  @override
  void dispose() {
    // Sayfa kapandığında dinleyiciyi kaldırarak hafıza sızıntılarını önle
    SyncService.isSyncCompleted.removeListener(_onSyncCompleted);
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _isLoading = true; });

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

    if (mounted) {
      setState(() {
        _allRoutes = allRoutes;
        _filteredRoutes = allRoutes; // Başlangıçta tüm rotaları göster
        _citiesWithRoutes = citiesWithRoutes;
        _isLoading = false;
      });
    }
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
        valueListenable: SyncService.isSyncCompleted,
        builder: (context, isSyncDone, child) {
          // 1. KONTROL: Global senkronizasyon bitti mi?
          if (!isSyncDone) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Preparing gourmet routes...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 2. KONTROL: Senkronizasyon bitti, şimdi yerel veriyi yüklüyoruz.
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 3. KONTROL: Yükleme bitti ama hiç rota bulunamadı mı?
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
          
          // Her şey yolundaysa, asıl içeriği göster
          return _buildContent();
        },
      ),
    );
  }

  // Arayüzün ana içeriğini oluşturan yardımcı metot
  Widget _buildContent() {
    return Column(
      children: [
        _buildCityFilters(),
        Expanded(child: _buildRoutesList()),
      ],
    );
  }

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
}

class _RouteCard extends StatelessWidget {
  final RouteModel route;
  const _RouteCard({required this.route});

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

     // Sade bir gösterim için, 'duration' (toplam) sürelerine bakıyoruz.
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