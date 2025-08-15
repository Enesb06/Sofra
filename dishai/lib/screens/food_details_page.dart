// TEMİZLENMİŞ DOSYA: lib/screens/food_details_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/food_details.dart';
import '../services/database_helper.dart';
import 'show_to_waiter_page.dart';

class FoodDetailsPage extends StatefulWidget {
  final FoodDetails food;
  const FoodDetailsPage({super.key, required this.food});

  @override
  State<FoodDetailsPage> createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await DatabaseHelper.instance.isFavorite(widget.food.name);
    if (mounted) {
      setState(() { _isFavorite = isFav; });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await DatabaseHelper.instance.removeFavorite(widget.food.name);
    } else {
      await DatabaseHelper.instance.addFavorite(widget.food.name);
    }
    setState(() { _isFavorite = !_isFavorite; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite
            ? '${widget.food.turkishName} was added to your favorites!'
            : '${widget.food.turkishName} was removed from your favorites.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPronunciation() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/${widget.food.name}.mp3'));
    } catch (e) {
      if (kDebugMode) print("❗️ Ses dosyası çalınırken HATA: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Sorry, audio for ${widget.food.turkishName} is not available.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.food.turkishName),
          backgroundColor: Colors.deepOrange.shade300,
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              onPressed: _toggleFavorite,
              tooltip: 'Add to Favorites',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.food.imageUrl != null && widget.food.imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: widget.food.imageUrl!,
                  height: 250,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.no_photography_outlined, size: 80, color: Colors.grey),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.food.turkishName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    Text(widget.food.englishName, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.volume_up_outlined),
                        label: const Text('Pronounce'),
                        onPressed: _playPronunciation,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade400, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.menu_book_outlined),
                        label: const Text('Show to Waiter'),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ShowToWaiterPage(food: widget.food)));
                        },
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade400, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                ),
              ),
              const TabBar(
                labelColor: Colors.deepOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepOrange,
                tabs: [
                  Tab(text: 'Story & Origin'),
                  Tab(text: 'Ingredients'),
                  Tab(text: 'Pairing'),
                ],
              ),
              SizedBox(
                height: 250, 
                child: TabBarView(
                  children: [
                    _buildInfoTab(widget.food.storyEn ?? 'No story available yet.'),
                    _buildInfoTab(_buildIngredientsText(widget.food)),
                    _buildInfoTab(widget.food.pairingEn ?? 'No pairing suggestions available yet.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(String text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(text, style: const TextStyle(fontSize: 16, height: 1.5)),
    );
  }

  String _buildIngredientsText(FoodDetails food) {
    final ingredients = "📋 Ingredients:\n${food.ingredientsEn ?? 'Not available.'}";
    final spiceLevel = "\n\n🔥 Spice Level: ${_generateSpiceLevelText(food.spiceLevel)}";
    final allergens = "\n\n⚠️ Allergen Info: ${_generateAllergenText(food)}";
    final vegetarianStatus = food.isVegetarian ? "\n\n🌱 This dish is vegetarian." : "";
    return (ingredients + spiceLevel + allergens + vegetarianStatus).trim();
  }

  String _generateSpiceLevelText(int? level) {
    if (level == null) return "Unknown";
    switch (level) {
      case 1: return "Not Spicy"; case 2: return "Mild"; case 3: return "Medium"; case 4: return "Spicy"; case 5: return "Very Spicy";
      default: return "Not specified";
    }
  }

  String _generateAllergenText(FoodDetails food) {
    List<String> allergens = [];
    if (food.containsGluten) allergens.add("Gluten");
    if (food.containsDairy) allergens.add("Dairy");
    if (food.containsNuts) allergens.add("Nuts");
    return allergens.isEmpty ? "No major allergens specified." : "Contains: ${allergens.join(', ')}.";
  }
}