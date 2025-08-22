// GÜNCELLENMİŞ DOSYA: lib/screens/home_page.dart (Düz Navigator Bar - Home Ortada)

import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'recognition_page.dart';
import 'discover_page.dart';
import 'menu_scanner_page.dart';
import 'routes_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Başlangıçta ortadaki Home butonu (index 2) seçili olacak.
  int _selectedIndex = 2; 
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    
    // YENİ SAYFA SIRALAMASI
    // Home (Dashboard) ortada (index 2) olacak şekilde düzenliyoruz.
    _widgetOptions = <Widget>[
      const RecognitionPage(),
      const DiscoverPage(),
      DashboardPage(onNavigateToTab: _onItemTapped), // Home (Dashboard) - index 2
      const RoutesListPage(),
      const MenuScannerPage(),
    ];
  }

  void _onItemTapped(int index) {
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
      // Klasik ve düz BottomNavigationBar'a geri dönüyoruz.
      bottomNavigationBar: BottomNavigationBar(
        // YENİ SEKME SIRALAMASI
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Recognize',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          // Home sekmesi tam ortada
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            activeIcon: Icon(Icons.route),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Scan Menu',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo, // Renkleri güncelledik
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
        // Bu, etiketlerin her zaman görünmesini ve ikonların kaymamasını sağlar.
        type: BottomNavigationBarType.fixed, 
      ),
    );
  }
}