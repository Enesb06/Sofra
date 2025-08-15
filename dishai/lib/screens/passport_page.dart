// GÜNCELLENMİŞ DOSYA: lib/screens/passport_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // El yazısı fontu için
import 'package:intl/intl.dart';

import '../models/food_details.dart';
import '../models/tasted_food_model.dart';
import '../services/database_helper.dart';
import 'add_memory_page.dart';
import 'food_details_page.dart';

class PassportPage extends StatefulWidget {
  const PassportPage({super.key});

  @override
  State<PassportPage> createState() => _PassportPageState();
}

class _PassportPageState extends State<PassportPage> {
  final GlobalKey<_TastedFoodsListState> _journalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flavor Passport'),
          backgroundColor: Colors.teal.shade300,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: 'My Favorites'),
              Tab(icon: Icon(Icons.book), text: 'My Journal'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const FavoritesList(),
            TastedFoodsList(key: _journalKey),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddMemoryPage()),
            );
            if (result == true) {
              _journalKey.currentState?.refreshList();
            }
          },
          label: const Text('Add Memory'),
          icon: const Icon(Icons.add_a_photo_outlined),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

// Favoriler listesinde bir değişiklik yok, sadece FAB'ın listeyi örtmemesi için padding eklendi.
class FavoritesList extends StatefulWidget {
  const FavoritesList({super.key});
  @override
  State<FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<FavoritesList> {
  late Future<List<FoodDetails>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favoritesFuture = DatabaseHelper.instance.getAllFavoriteFoods();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FoodDetails>>(
      future: _favoritesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
        if (snapshot.hasError) { return Center(child: Text('An error occurred: ${snapshot.error}')); }
        final favorites = snapshot.data;
        if (favorites == null || favorites.isEmpty) { return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('You have no favorite dishes yet.\nTap the heart icon on a dish\'s detail page to add it to your favorites.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey))));}
        
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80.0), // FAB için boşluk
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final food = favorites[index];
            return ListTile(
              leading: CircleAvatar(backgroundImage: (food.imageUrl != null && food.imageUrl!.isNotEmpty) ? NetworkImage(food.imageUrl!) : null, backgroundColor: Colors.grey.shade200, child: (food.imageUrl == null || food.imageUrl!.isEmpty) ? const Icon(Icons.ramen_dining) : null),
              title: Text(food.turkishName),
              subtitle: Text(food.englishName),
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => FoodDetailsPage(food: food)),).then((_) { setState(() { _loadFavorites(); }); }); },
            );
          },
        );
      },
    );
  }
}

// ===================================================================
//              ANI DEFTERİ BÖLÜMÜ YENİDEN İNŞA EDİLİYOR
// ===================================================================

class TastedFoodsList extends StatefulWidget {
  const TastedFoodsList({super.key});
  @override
  State<TastedFoodsList> createState() => _TastedFoodsListState();
}

class _TastedFoodsListState extends State<TastedFoodsList> {
  late Future<List<TastedFood>> _tastedFuture;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadTastedFoods();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadTastedFoods() {
    _tastedFuture = DatabaseHelper.instance.getAllTastedFoods();
  }
  
  void refreshList() {
    setState(() {
      _loadTastedFoods();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TastedFood>>(
      future: _tastedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
        if (snapshot.hasError) { return Center(child: Text('An error occurred: ${snapshot.error}')); }
        
        final memories = snapshot.data;
        if (memories == null || memories.isEmpty) { return const Center( child: Padding( padding: EdgeInsets.all(16.0), child: Text('Your journal is empty.\nPress the "Add Memory" button to start your culinary adventure!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey))));}

        // Ana Defter Yapısı
        return Stack(
          children: [
            // Sayfalar
            PageView.builder(
              controller: _pageController,
              itemCount: memories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return _JournalPage(memory: memories[index]);
              },
            ),

            // Sayfa Numarası
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${_currentPage + 1} / ${memories.length}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ),
            ),
            
            // Geri Gitme Butonu
            if (_currentPage > 0)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ),
              ),

            // İleri Gitme Butonu
            if (_currentPage < memories.length - 1)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.black54),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Tek Bir Anı Sayfasını Temsil Eden Widget
class _JournalPage extends StatelessWidget {
  final TastedFood memory;
  const _JournalPage({required this.memory});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMMM yyyy').format(DateTime.parse(memory.tastedDate));

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fotoğraf
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: memory.imagePath != null
                  ? Image.file(
                      File(memory.imagePath!),
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      color: Colors.white,
                      child: const Icon(Icons.image_not_supported_outlined, size: 80, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Metinler
          Text(
            memory.foodName,
            textAlign: TextAlign.center,
            style: GoogleFonts.patrickHand( // El yazısı fontu
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'in ${memory.cityName}, on $date',
            style: GoogleFonts.patrickHand( // El yazısı fontu
              fontSize: 20,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}