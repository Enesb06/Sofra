// GÜNCELLENMİŞ DOSYA: lib/screens/passport_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
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
  final GlobalKey<_FavoritesListState> _favoritesKey = GlobalKey();

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
            FavoritesList(key: _favoritesKey),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }
        final favorites = snapshot.data;
        if (favorites == null || favorites.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('You have no favorite dishes yet.\nTap the heart icon on a dish\'s detail page to add it to your favorites.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final food = favorites[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: (food.imageUrl != null && food.imageUrl!.isNotEmpty)
                    ? NetworkImage(food.imageUrl!)
                    : null,
                backgroundColor: Colors.grey.shade200,
                child: (food.imageUrl == null || food.imageUrl!.isEmpty)
                    ? const Icon(Icons.ramen_dining)
                    : null,
              ),
              title: Text(food.turkishName),
              subtitle: Text(food.englishName),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FoodDetailsPage(food: food)),
                ).then((_) {
                  setState(() { _loadFavorites(); });
                });
              },
            );
          },
        );
      },
    );
  }
}

class TastedFoodsList extends StatefulWidget {
  const TastedFoodsList({super.key});
  @override
  State<TastedFoodsList> createState() => _TastedFoodsListState();
}

class _TastedFoodsListState extends State<TastedFoodsList> {
  late Future<List<TastedFood>> _tastedFuture;

  @override
  void initState() {
    super.initState();
    _loadTastedFoods();
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }
        final tastedFoods = snapshot.data;
        if (tastedFoods == null || tastedFoods.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('You haven\'t logged any dishes in your journal yet.\nPress the "Add Memory" button to start adding your culinary experiences.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: tastedFoods.length,
          itemBuilder: (context, index) {
            final entry = tastedFoods[index];
            final date = DateFormat('dd MMMM yyyy').format(DateTime.parse(entry.tastedDate));

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 3,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: entry.imagePath != null
                      ? FileImage(File(entry.imagePath!))
                      : null,
                  backgroundColor: Colors.grey.shade200,
                  child: entry.imagePath == null
                      ? const Icon(Icons.restaurant_menu, color: Colors.grey)
                      : null,
                ),
                title: Text(entry.foodName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('in ${entry.cityName}, on $date'),
              ),
            );
          },
        );
      },
    );
  }
}