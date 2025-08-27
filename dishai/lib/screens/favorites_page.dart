// YENİ DOSYA: lib/screens/favorites_page.dart

import 'package:flutter/material.dart';
import '../models/food_details.dart';
import '../services/database_helper.dart';
import 'food_details_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FoodDetails>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = DatabaseHelper.instance.getAllFavoriteFoods();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Dishes'),
        
      ),
      body: FutureBuilder<List<FoodDetails>>(
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
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'You have no favorite dishes yet.\nTap the heart icon on a dish\'s detail page to add it here!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final food = favorites[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (food.imageUrl != null && food.imageUrl!.isNotEmpty) 
                        ? NetworkImage(food.imageUrl!) 
                        : null,
                    backgroundColor: Colors.grey.shade200,
                    child: (food.imageUrl == null || food.imageUrl!.isEmpty) 
                        ? const Icon(Icons.ramen_dining) 
                        : null,
                  ),
                  title: Text(food.turkishName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(food.englishName),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FoodDetailsPage(food: food)),
                    ).then((_) {
                      // Detay sayfasından geri dönüldüğünde (belki favorilerden çıkarılmıştır),
                      // listeyi yenile.
                      _loadFavorites();
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}