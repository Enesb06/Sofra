// lib/screens/discover_page.dart DOSYASININ DİNAMİK PİN BOYUTLANDIRMALI NİHAİ HALİ

import 'package:flutter/material.dart';
import 'dart:math' as math; // clamp fonksiyonu için
// Projenizin yapısına uygun doğru import yolları
import '../services/database_helper.dart';
import '../models/city_model.dart';
import '../models/food_details.dart';
import 'food_details_page.dart';

// --- CHAT MESAJI MODELLERİ ---
abstract class ChatMessage { final bool isFromUser; ChatMessage(this.isFromUser); }
class BotTextMessage extends ChatMessage { final String text; BotTextMessage(this.text) : super(false); }
class FoodSuggestionMessage extends ChatMessage { final List<FoodDetails> foods; final Function(FoodDetails) onFoodTapped; FoodSuggestionMessage(this.foods, this.onFoodTapped) : super(false); }
class JourneyStartMessage extends ChatMessage { final City city; JourneyStartMessage(this.city) : super(false); }

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final List<ChatMessage> _chatMessages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  City? _selectedCity;
  List<City> _citiesOnMap = [];

  bool _isFineTuningMode = false; // Geliştirme için açık bırakıyoruz
  String? _selectedCityForTuning;
  double _tuningX = 0.5;
  double _tuningY = 0.5;

  @override
  void initState() {
    super.initState();
    _loadCitiesForMap();
  }

  Future<void> _loadCitiesForMap() async {
    final cities = await DatabaseHelper.instance.getAllCities();
    if (mounted) {
      setState(() {
        _citiesOnMap = cities;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onCitySelected(City city) async {
    setState(() {
      _isLoading = true;
      _selectedCity = city;
      _chatMessages.clear();
      _chatMessages.add(JourneyStartMessage(city));
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    await _startChatFlowForCity(city);
  }

  Future<void> _startChatFlowForCity(City city) async {
    setState(() {
      _chatMessages.removeWhere((msg) => msg is JourneyStartMessage);
    });
    _addBotMessage("Welcome to ${city.cityName}! A city of rich history and incredible flavors. Ready to explore?", onFinished: () {
      _suggestFoodsForCity(city);
    });
  }

  Future<void> _suggestFoodsForCity(City city) async {
    final foodNames = await DatabaseHelper.instance.getFoodNamesForCity(city.id);
    if (foodNames.isNotEmpty) {
      _addBotMessage("Here are some must-try dishes for you:");
      List<FoodDetails> foodDetailsList = [];
      for (var name in foodNames) {
        final details = await DatabaseHelper.instance.getFoodByName(name);
        if (details != null) {
          foodDetailsList.add(details);
        }
      }
      setState(() {
        _isLoading = false;
        _chatMessages.add(FoodSuggestionMessage(foodDetailsList, _onFoodTapped));
      });
      _scrollToBottom();
    } else {
      _addBotMessage("I know of ${city.cityName}, but I don't have specific food recommendations for it just yet.");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addBotMessage(String text, {VoidCallback? onFinished}) {
    setState(() {
      _isLoading = false;
      _chatMessages.add(BotTextMessage(text));
    });
    _scrollToBottom();
    if (onFinished != null) {
      Future.delayed(const Duration(milliseconds: 500), onFinished);
    }
  }

  void _onFoodTapped(FoodDetails food) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => FoodDetailsPage(food: food)));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _resetToMapView() {
    setState(() {
      _selectedCity = null;
      _chatMessages.clear();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCity == null ? 'DishAI - Flavor Explorer' : _selectedCity!.cityName),
        backgroundColor: Colors.blue.shade300,
        leading: _selectedCity != null
            ? IconButton(
                icon: const Icon(Icons.map_outlined),
                onPressed: _resetToMapView,
                tooltip: 'Back to Map',
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _selectedCity == null ? _buildMapView() : _buildChatView(),
      ),
    );
  }

  Widget _buildMapView() {
    const double imageAspectRatio = 1920 / 924;

    final Map<String, Offset> cityCoordinates = {
      'Ankara':     const Offset(0.34, 0.45),
      'İzmir':      const Offset(0.05, 0.63),
      'Gaziantep':  const Offset(0.60, 0.86),
      'Trabzon':    const Offset(0.72, 0.27),
      'Bursa':      const Offset(0.17, 0.35),
      'Hatay':      const Offset(0.55, 0.95),
      'Mersin':     const Offset(0.41, 0.94),
      'Erzurum':    const Offset(0.82, 0.38),
      'Kayseri':    const Offset(0.52, 0.59),
      'Şanlıurfa':  const Offset(0.69, 0.83),
    };

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerWidth = constraints.maxWidth;
              final containerHeight = constraints.maxHeight;
              final containerAspectRatio = containerWidth / containerHeight;

              double renderedImageWidth;
              double renderedImageHeight;

              if (containerAspectRatio > imageAspectRatio) {
                renderedImageHeight = containerHeight;
                renderedImageWidth = renderedImageHeight * imageAspectRatio;
              } else {
                renderedImageWidth = containerWidth;
                renderedImageHeight = renderedImageWidth / imageAspectRatio;
              }

              // --- YENİ DİNAMİK BOYUTLANDIRMA MANTIĞI ---
              const double referenceWidth = 800.0; // Tablette iyi görünen referans harita genişliği
              final double scaleFactor = (renderedImageWidth / referenceWidth).clamp(0.7, 1.2); // Çok küçülmesini/büyümesini engelle

              return Center(
                child: SizedBox(
                  width: renderedImageWidth,
                  height: renderedImageHeight,
                  child: Stack(
                    children: [
                      Image.asset('assets/images/turkey_map.png', fit: BoxFit.fill),
                      ..._citiesOnMap.where((city) => cityCoordinates.containsKey(city.cityName)).map((city) {
                        final isTuningThisCity = _isFineTuningMode && _selectedCityForTuning == city.cityName;
                        final coords = isTuningThisCity ? Offset(_tuningX, _tuningY) : cityCoordinates[city.cityName]!;
                        
                        final leftPosition = renderedImageWidth * coords.dx;
                        final topPosition = renderedImageHeight * coords.dy;

                        return Positioned(
                          left: leftPosition,
                          top: topPosition,
                          child: Transform.translate(
                            // Offset değeri de artık dinamik!
                            offset: Offset(-25 * scaleFactor, -55 * scaleFactor),
                            child: GestureDetector(
                              onTap: () {
                                if (_isFineTuningMode) {
                                  setState(() {
                                    _selectedCityForTuning = city.cityName;
                                    _tuningX = cityCoordinates[city.cityName]!.dx;
                                    _tuningY = cityCoordinates[city.cityName]!.dy;
                                  });
                                } else {
                                  _onCitySelected(city);
                                }
                              },
                              // Ölçek faktörünü CityPin'e yolluyoruz
                              child: CityPin(city: city, scaleFactor: scaleFactor),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isFineTuningMode)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Column(
              children: [
                Text('İnce Ayar Modu: ${_selectedCityForTuning ?? "Konumunu ayarlamak için bir şehir seçin."}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_selectedCityForTuning != null) ...[
                  Row(children: [const Text('X: '), Expanded(child: Slider(value: _tuningX, min: 0.0, max: 1.0, divisions: 200, label: _tuningX.toStringAsFixed(2), onChanged: (value) => setState(() => _tuningX = value)))]),
                  Row(children: [const Text('Y: '), Expanded(child: Slider(value: _tuningY, min: 0.0, max: 1.0, divisions: 200, label: _tuningY.toStringAsFixed(2), onChanged: (value) => setState(() => _tuningY = value)))]),
                  const Text("Koddaki 'cityCoordinates' map'ine yapıştırmak için:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  SelectableText("'$_selectedCityForTuning': const Offset(${_tuningX.toStringAsFixed(2)}, ${_tuningY.toStringAsFixed(2)}),", style: const TextStyle(fontFamily: 'monospace', backgroundColor: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(16.0), itemCount: _chatMessages.length, itemBuilder: (context, index) {
          final message = _chatMessages[index];
          if (message is BotTextMessage) return _buildBotMessage(message.text);
          if (message is FoodSuggestionMessage) return _buildFoodSuggestions(message.foods, message.onFoodTapped);
          if (message is JourneyStartMessage) return _buildJourneyStartMessage(message.city);
          return const SizedBox.shrink();
        })),
        if (_isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: LinearProgressIndicator()),
      ],
    );
  }

  Widget _buildBotMessage(String text) { return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.explore_outlined, color: Colors.white, size: 20)), const SizedBox(width: 8), Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20).copyWith(topLeft: const Radius.circular(4))), child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)))) ])); }
  Widget _buildFoodSuggestions(List<FoodDetails> foods, Function(FoodDetails) onFoodTapped) { return Container(height: 140, alignment: Alignment.centerLeft, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: foods.length, itemBuilder: (context, index) { final food = foods[index]; return GestureDetector(onTap: () => onFoodTapped(food), child: Container(width: 120, margin: const EdgeInsets.only(right: 10), child: Column(mainAxisSize: MainAxisSize.min, children: [ CircleAvatar(radius: 40, backgroundImage: (food.imageUrl != null && food.imageUrl!.isNotEmpty) ? NetworkImage(food.imageUrl!) : null, backgroundColor: Colors.grey.shade200, child: (food.imageUrl == null || food.imageUrl!.isEmpty) ? const Icon(Icons.ramen_dining, color: Colors.grey, size: 40) : null), const SizedBox(height: 8), Text(food.turkishName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))])));}));}
  Widget _buildJourneyStartMessage(City city) { return Center(child: Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [Hero(tag: 'city-pin-${city.id}', child: const Material(type: MaterialType.transparency, child: Icon(Icons.flight_takeoff, size: 60, color: Colors.blue))), const SizedBox(height: 16), Text("Your journey to ${city.cityName} is starting...", style: TextStyle(fontSize: 20, color: Colors.grey.shade700, fontWeight: FontWeight.bold)), const SizedBox(height: 16), const CircularProgressIndicator()]))); }
}


// GÜNCELLENMİŞ VE DİNAMİK CityPin WIDGET'I
class CityPin extends StatelessWidget {
  final City city;
  final double scaleFactor; // Ölçek faktörünü dışarıdan alacak

  const CityPin({
    super.key,
    required this.city,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    // Baz boyutlar
    const double baseFontSize = 12.0;
    const double baseIconSize = 30.0;

    return Hero(
      tag: 'city-pin-${city.id}',
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6 * scaleFactor, vertical: 2 * scaleFactor),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8 * scaleFactor),
              ),
              child: Text(
                city.cityName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  // Yazı boyutu artık dinamik
                  fontSize: baseFontSize * scaleFactor, 
                ),
              ),
            ),
            Icon(
              Icons.location_on,
              color: Colors.red,
              // İkon boyutu artık dinamik
              size: baseIconSize * scaleFactor,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4.0 * scaleFactor)],
            ),
          ],
        ),
      ),
    );
  }
}