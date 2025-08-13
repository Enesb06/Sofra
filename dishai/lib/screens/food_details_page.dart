import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/food_details.dart';
import 'show_to_waiter_page.dart'; // Mevcut garson sayfamızı kullanacağız!

class FoodDetailsPage extends StatefulWidget {
  final FoodDetails food;

  const FoodDetailsPage({super.key, required this.food});

  @override
  State<FoodDetailsPage> createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

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
      length: 3, // Hikaye, İçindekiler, Yanında Ne Gider?
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.food.turkishName),
          backgroundColor: Colors.deepOrange.shade300,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. GÖZ ALICI YEMEK FOTOĞRAFI
              if (widget.food.imageUrl != null && widget.food.imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: widget.food.imageUrl!,
                  height: 250,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.no_photography_outlined, size: 80, color: Colors.grey),
                ),
              
              // 2. YEMEK İSİMLERİ
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.food.turkishName,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.food.englishName,
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              // 3. AKSİYON BUTONLARI
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.volume_up_outlined),
                        label: const Text('Pronounce'),
                        onPressed: _playPronunciation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
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
                         style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 4. BİLGİ SEKMELERİ
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
                height: 250, // Sekme içeriği için bir yükseklik verelim
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

  // RecognitionPage'deki yardımcı fonksiyonları buraya taşıyoruz
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