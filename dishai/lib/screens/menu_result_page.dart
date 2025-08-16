// YENİ DOSYA: lib/screens/menu_result_page.dart (Liste Görünümlü Versiyon)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Daha şık bir görünüm için

import 'menu_scanner_page.dart'; // MatchedFood modeli için
import 'food_details_page.dart'; // Yemek detay sayfasına gitmek için

class MenuResultPage extends StatelessWidget {
  final String imagePath;
  final List<MatchedFood> matchedFoods;

  const MenuResultPage({
    super.key,
    required this.imagePath,
    required this.matchedFoods,
  });

  @override
  Widget build(BuildContext context) {
    // Eşleşen yemekleri alfabetik olarak sıralayalım.
    matchedFoods.sort((a, b) => a.food.turkishName.compareTo(b.food.turkishName));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dishes Found on Menu'),
        backgroundColor: Colors.teal.shade300,
      ),
      body: Column(
        children: [
          // 1. Taranan Menü Fotoğrafının Önizlemesi
          _buildScannedImagePreview(),

          // 2. "Bulunan Yemekler" Başlığı
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              '${matchedFoods.length} matching dishes found:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          // 3. Bulunan Yemeklerin Listesi
          Expanded(
            child: ListView.builder(
              itemCount: matchedFoods.length,
              itemBuilder: (context, index) {
                final matchedFood = matchedFoods[index];
                final food = matchedFood.food;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (food.imageUrl != null && food.imageUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(food.imageUrl!)
                          : null,
                      child: (food.imageUrl == null || food.imageUrl!.isEmpty)
                          ? const Icon(Icons.ramen_dining, color: Colors.grey)
                          : null,
                    ),
                    title: Text(
                      food.turkishName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      food.englishName,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FoodDetailsPage(food: food),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Taranan resmin küçük bir önizlemesini gösteren yardımcı widget.
  Widget _buildScannedImagePreview() {
    return Container(
      height: 150,
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}