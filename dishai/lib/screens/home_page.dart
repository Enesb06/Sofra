// FİNAL KOD: lib/screens/home_page.dart (Tüm Akıllı Mantık Entegre Edilmiş)

import 'package:flutter/material.dart';
import '../models/city_model.dart'; 
import '../models/food_details.dart';
import 'dashboard_page.dart';
import 'recognition_page.dart';
import 'discover_page.dart';
import 'menu_scanner_page.dart';
import 'routes_list_page.dart';
import 'food_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2; // Başlangıçta Home sekmesi seçili
  late final List<Widget> _widgetOptions;
  
  // DiscoverPage'e dışarıdan komut göndermek için anahtar
  final GlobalKey<DiscoverPageState> _discoverPageKey = GlobalKey<DiscoverPageState>();

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const RecognitionPage(),
      DiscoverPage(key: _discoverPageKey),
      DashboardPage(
        onNavigateToTab: _onItemTapped,
        onNavigateToFood: _navigateToFoodDetail,
      ),
      const RoutesListPage(),
      const MenuScannerPage(),
    ];
  }

  /// Dashboard'dan gelen "yemek detayına git" isteğini yönetir.
  void _navigateToFoodDetail(FoodDetails food) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FoodDetailsPage(food: food)),
    );
  }

  /// Tüm sekme geçiş mantığını yöneten akıllı metot.
  void _onItemTapped(int index, {City? city}) {
    // --- Senaryo 1: Dashboard'dan bir ŞEHİR ile Discover'a yönlendirme ---
    if (city != null && index == 1) {
      // Önce Discover sekmesine geçiş yap.
      setState(() {
        _selectedIndex = index;
      });
      // Geçiş animasyonu bittikten sonra DiscoverPage'deki chatbot'u başlat.
      // Bu, sayfa henüz çizilmeden state'ini değiştirmeye çalışmayı önler.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _discoverPageKey.currentState?.startChatFlowForCity(city);
      });
      return; // İşlem tamamlandı, fonksiyondan çık.
    }

    // --- Senaryo 2: Alt navigasyon çubuğundan Discover sekmesine tıklama ---
    if (index == 1) {
      // Eğer Discover sekmesi zaten seçili ise hiçbir şey yapma.
      // Bu, kullanıcının mevcut sohbetini veya haritasını korur.
      if (_selectedIndex == 1) return;

      // Eğer başka bir sekmeden Discover'a geçiliyorsa, normal şekilde geçiş yap.
      // DiscoverPage'in son durumu (harita veya sohbet) korunacaktır.
      setState(() {
        _selectedIndex = index;
      });
      return; // İşlem tamamlandı, fonksiyondan çık.
    }

    // --- Senaryo 3: Diğer tüm normal sekme tıklamaları ---
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), activeIcon: Icon(Icons.camera_alt), label: 'Recognize'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.route_outlined), activeIcon: Icon(Icons.route), label: 'Routes'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Scan Menu'),
        ],
        currentIndex: _selectedIndex,
        
        // Alttaki bara tıklandığında sadece index gider, city null olur.
        onTap: (index) => _onItemTapped(index), 
        type: BottomNavigationBarType.fixed, 
      ),
    );
  }
}