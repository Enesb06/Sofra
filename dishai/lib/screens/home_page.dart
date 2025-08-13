import 'package:flutter/material.dart';
import 'recognition_page.dart';
import 'discover_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Navigasyon çubuğunun yöneteceği sayfaların listesi.
  // RecognitionPage'i buraya olduğu gibi yerleştiriyoruz.
  static const List<Widget> _widgetOptions = <Widget>[
    RecognitionPage(), // MEVCUT SAYFANIZ
    DiscoverPage(),    // YENİ SAYFAMIZ
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Seçili indekse göre ilgili sayfayı body'de gösteriyoruz.
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange, // Seçili sekmenin rengi
        unselectedItemColor: Colors.grey.shade600, // Seçili olmayan sekmelerin rengi
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // İkiden fazla sekme olursa diye
      ),
    );
  }
}