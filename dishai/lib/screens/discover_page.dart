// lib/screens/discover_page.dart - DİNAMİK PİN BOYUTLANDIRMALI VE PROFESYONEL GEÇİŞ ANİMASYONLU NİHAİ HALİ

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';    // Timer için gerekli
import 'dart:ui';       // BackdropFilter için gerekli

// Projenizin yapısına uygun doğru import yolları
import '../services/database_helper.dart';
import '../models/city_model.dart';
import '../models/food_details.dart';
import 'food_details_page.dart';

// --- CHAT MESAJI MODELLERİ (JourneyStartMessage kaldırıldı) ---
abstract class ChatMessage { final bool isFromUser; ChatMessage(this.isFromUser); }
class BotTextMessage extends ChatMessage { final String text; BotTextMessage(this.text) : super(false); }
class FoodSuggestionMessage extends ChatMessage { final List<FoodDetails> foods; final Function(FoodDetails) onFoodTapped; FoodSuggestionMessage(this.foods, this.onFoodTapped) : super(false); }


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

  // YENİ: Geçiş animasyonunu kontrol etmek için eklendi.
  bool _isTransitioning = false; 

  // İnce ayar modu kodunuz olduğu gibi bırakıldı.
  bool _isFineTuningMode = false;
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
    if (mounted) setState(() => _citiesOnMap = cities);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // GÜNCELLENDİ: Önce geçiş animasyonunu tetikleyecek, sonra sohbeti başlatacak.
  void _onCitySelected(City city) {
    setState(() {
      _selectedCity = city;      // Overlay'in şehir adını bilmesi için gerekli.
      _isTransitioning = true;   // Geçiş animasyonunu başlat.
    });

    // Animasyonun tamamlanması için bir süre bekle.
    Timer(const Duration(milliseconds: 2500), () {
      // Eğer kullanıcı bu sürede geri dönerse veya widget yok olduysa işlemi iptal et.
      if (!mounted || !_isTransitioning) return; 
      
      // Şimdi sohbet akışını başlat.
      _startChatFlowForCity(city);
    });
  }

  // GÜNCELLENDİ: Geçişi bitirir ve ilk mesajı ekler.
  Future<void> _startChatFlowForCity(City city) async {
    // Geçişi bitir ve sohbeti başlat, tek bir setState ile arayüzü güncelle.
    setState(() {
      _isTransitioning = false; // Animasyonlu overlay'i kapat.
      _chatMessages.clear();    // Sohbeti temizle.
    });

    // İlk mesajı ekle ve ardından yemekleri öner.
    _addBotMessage("Welcome to ${city.cityName}! A city of rich history and incredible flavors. Ready to explore?", onFinished: () {
      _suggestFoodsForCity(city);
    });
  }

  // Bu fonksiyonda değişiklik yok, olduğu gibi bırakıldı.
  Future<void> _suggestFoodsForCity(City city) async {
    setState(() => _isLoading = true);
    final foodNames = await DatabaseHelper.instance.getFoodNamesForCity(city.id);
    if (foodNames.isNotEmpty) {
      _addBotMessage("Here are some must-try dishes for you:");
      List<FoodDetails> foodDetailsList = [];
      for (var name in foodNames) {
        final details = await DatabaseHelper.instance.getFoodByName(name);
        if (details != null) foodDetailsList.add(details);
      }
      setState(() {
        _isLoading = false;
        _chatMessages.add(FoodSuggestionMessage(foodDetailsList, _onFoodTapped));
      });
      _scrollToBottom();
    } else {
      _addBotMessage("I know of ${city.cityName}, but I don't have specific food recommendations for it just yet.");
      setState(() => _isLoading = false);
    }
  }

  // Bu fonksiyonda ufak bir değişiklik yapıldı.
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

  void _onFoodTapped(FoodDetails food) => Navigator.push(context, MaterialPageRoute(builder: (context) => FoodDetailsPage(food: food)));
  void _scrollToBottom() { WidgetsBinding.instance.addPostFrameCallback((_) { if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }

  // Bu fonksiyonda değişiklik yok, olduğu gibi bırakıldı.
  void _resetToMapView() {
    setState(() {
      _selectedCity = null;
      _chatMessages.clear();
      _isLoading = false;
      _isTransitioning = false; // Geri dönerken geçişin kapalı olduğundan emin ol.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCity?.cityName ?? 'DishAI - Flavor Explorer'),
        backgroundColor: Colors.blue.shade300,
        leading: _selectedCity != null ? IconButton(icon: const Icon(Icons.map_outlined), onPressed: _resetToMapView, tooltip: 'Back to Map') : null,
      ),
      // GÜNCELLENDİ: Ana gövde, animasyon overlay'ini içerecek şekilde Stack ile sarmalandı.
      body: Stack(
        children: [
          // MEVCUT YAPINIZ: AnimatedSwitcher, harita ve sohbet arasında geçiş yapar.
          // Koşul, sohbet mesajlarının durumuna göre değiştirildi, bu daha stabil bir geçiş sağlar.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _chatMessages.isEmpty && !_isTransitioning 
                ? _buildMapView() 
                : _buildChatView(),
          ),
          
          // YENİ: Geçiş animasyonu overlay'i, her şeyin üzerinde görünür.
          _buildTransitionOverlay(),
        ],
      ),
    );
  }

  // Bu fonksiyonda değişiklik yok, olduğu gibi bırakıldı.
  Widget _buildMapView() {
    const double imageAspectRatio = 1920 / 924;
    final Map<String, Offset> cityCoordinates = { 'Ankara': const Offset(0.34, 0.45), 'İzmir': const Offset(0.05, 0.63), 'Gaziantep': const Offset(0.60, 0.86), 'Trabzon': const Offset(0.72, 0.27), 'Bursa': const Offset(0.17, 0.35), 'Hatay': const Offset(0.55, 0.95), 'Mersin': const Offset(0.41, 0.94), 'Erzurum': const Offset(0.82, 0.38), 'Kayseri': const Offset(0.52, 0.59), 'Şanlıurfa': const Offset(0.69, 0.83) };
    return Column(children: [ Expanded(child: LayoutBuilder(builder: (context, constraints) {
      final containerWidth = constraints.maxWidth;
      final containerHeight = constraints.maxHeight;
      final containerAspectRatio = containerWidth / containerHeight;
      double renderedImageWidth; double renderedImageHeight;
      if (containerAspectRatio > imageAspectRatio) { renderedImageHeight = containerHeight; renderedImageWidth = renderedImageHeight * imageAspectRatio; } else { renderedImageWidth = containerWidth; renderedImageHeight = renderedImageWidth / imageAspectRatio; }
      const double referenceWidth = 800.0;
      final double scaleFactor = (renderedImageWidth / referenceWidth).clamp(0.7, 1.2);
      return Center(child: SizedBox(width: renderedImageWidth, height: renderedImageHeight, child: Stack(children: [
        Image.asset('assets/images/turkey_map.png', fit: BoxFit.fill),
        ..._citiesOnMap.where((city) => cityCoordinates.containsKey(city.cityName)).map((city) {
          final isTuningThisCity = _isFineTuningMode && _selectedCityForTuning == city.cityName;
          final coords = isTuningThisCity ? Offset(_tuningX, _tuningY) : cityCoordinates[city.cityName]!;
          final leftPosition = renderedImageWidth * coords.dx;
          final topPosition = renderedImageHeight * coords.dy;
          return Positioned(left: leftPosition, top: topPosition, child: Transform.translate(offset: Offset(-25 * scaleFactor, -55 * scaleFactor), child: GestureDetector(onTap: () { if (_isFineTuningMode) { setState(() { _selectedCityForTuning = city.cityName; _tuningX = cityCoordinates[city.cityName]!.dx; _tuningY = cityCoordinates[city.cityName]!.dy; }); } else { _onCitySelected(city); } }, child: CityPin(city: city, scaleFactor: scaleFactor))));
        }).toList()])));
    })), if (_isFineTuningMode) Container(padding: const EdgeInsets.all(12), color: Colors.grey.shade200, child: Column(children: [ Text('İnce Ayar Modu: ${_selectedCityForTuning ?? "Konumunu ayarlamak için bir şehir seçin."}', style: const TextStyle(fontWeight: FontWeight.bold)), if (_selectedCityForTuning != null) ...[ Row(children: [const Text('X: '), Expanded(child: Slider(value: _tuningX, min: 0.0, max: 1.0, divisions: 200, label: _tuningX.toStringAsFixed(2), onChanged: (value) => setState(() => _tuningX = value)))]), Row(children: [const Text('Y: '), Expanded(child: Slider(value: _tuningY, min: 0.0, max: 1.0, divisions: 200, label: _tuningY.toStringAsFixed(2), onChanged: (value) => setState(() => _tuningY = value)))]), const Text("Koddaki 'cityCoordinates' map'ine yapıştırmak için:", style: TextStyle(fontSize: 10, color: Colors.grey)), SelectableText("'$_selectedCityForTuning': const Offset(${_tuningX.toStringAsFixed(2)}, ${_tuningY.toStringAsFixed(2)}),", style: const TextStyle(fontFamily: 'monospace', backgroundColor: Colors.white, fontWeight: FontWeight.bold))]]))]
  );
  }

  // YENİ: Geçiş animasyonunu oluşturan overlay widget'ı.
  Widget _buildTransitionOverlay() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _isTransitioning ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !_isTransitioning,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
            if (_selectedCity != null)
              _buildJourneyStartMessage(_selectedCity!),
          ],
        ),
      ),
    );
  }

  // YENİ: Sizin JourneyStartMessage'ınızın yerine geçen, estetik ve animasyonlu kart.
  Widget _buildJourneyStartMessage(City city) {
    return Center(child: Container(padding: const EdgeInsets.all(24), margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 20), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.8) ]), borderRadius: BorderRadius.circular(20), boxShadow: [ BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, spreadRadius: 5) ]), child: Column(mainAxisSize: MainAxisSize.min, children: [
      TweenAnimationBuilder(duration: const Duration(milliseconds: 1200), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Transform.scale(scale: 0.8 + (value * 0.2), child: Transform.rotate(angle: value * 0.1, child: Hero(tag: 'city-pin-${city.id}', child: Material(type: MaterialType.transparency, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ Colors.blue.shade400, Colors.blue.shade600 ]), boxShadow: [ BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, spreadRadius: 2) ]), child: const Icon(Icons.explore, size: 40, color: Colors.white)))))); }),
      const SizedBox(height: 20),
      TweenAnimationBuilder(duration: const Duration(milliseconds: 800), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: Text("Exploring ${city.cityName}", style: TextStyle(fontSize: 24, color: Colors.blue.shade800, fontWeight: FontWeight.bold, letterSpacing: 1.2), textAlign: TextAlign.center))); }),
      const SizedBox(height: 12),
      TweenAnimationBuilder(duration: const Duration(milliseconds: 1000), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 15 * (1 - value)), child: Text("Discovering authentic flavors and culinary treasures", style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500), textAlign: TextAlign.center))); }),
      const SizedBox(height: 24),
      SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600), backgroundColor: Colors.blue.shade100)),
      const SizedBox(height: 16),
      TweenAnimationBuilder(duration: const Duration(milliseconds: 1500), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (index) { final delay = index * 0.3; final animValue = ((value - delay).clamp(0.0, 1.0)); return Container(margin: const EdgeInsets.symmetric(horizontal: 4), child: AnimatedContainer(duration: Duration(milliseconds: 300 + (index * 100)), width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.shade400.withOpacity(animValue)))); })); }),
    ])));
  }

  // Bu fonksiyonda değişiklik yok, olduğu gibi bırakıldı. JourneyStartMessage case'i kaldırıldı.
  Widget _buildChatView() {
    return Column(children: [ Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(16.0), itemCount: _chatMessages.length, itemBuilder: (context, index) {
      final message = _chatMessages[index];
      if (message is BotTextMessage) return _buildBotMessage(message.text);
      if (message is FoodSuggestionMessage) return _buildFoodSuggestions(message.foods, message.onFoodTapped);
      return const SizedBox.shrink(); // JourneyStartMessage kaldırıldı
    })), if (_isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: LinearProgressIndicator())]);
  }

  // Bu iki fonksiyonda değişiklik yok, olduğu gibi bırakıldı.
  Widget _buildBotMessage(String text) { return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.explore_outlined, color: Colors.white, size: 20)), const SizedBox(width: 8), Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20).copyWith(topLeft: const Radius.circular(4))), child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)))) ])); }
  Widget _buildFoodSuggestions(List<FoodDetails> foods, Function(FoodDetails) onFoodTapped) { return Container(height: 140, alignment: Alignment.centerLeft, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: foods.length, itemBuilder: (context, index) { final food = foods[index]; return GestureDetector(onTap: () => onFoodTapped(food), child: Container(width: 120, margin: const EdgeInsets.only(right: 10), child: Column(mainAxisSize: MainAxisSize.min, children: [ CircleAvatar(radius: 40, backgroundImage: (food.imageUrl != null && food.imageUrl!.isNotEmpty) ? NetworkImage(food.imageUrl!) : null, backgroundColor: Colors.grey.shade200, child: (food.imageUrl == null || food.imageUrl!.isEmpty) ? const Icon(Icons.ramen_dining, color: Colors.grey, size: 40) : null), const SizedBox(height: 8), Text(food.turkishName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))])));}));}
}


// CityPin widget'ınızda değişiklik yok, olduğu gibi bırakıldı.
class CityPin extends StatelessWidget {
  final City city;
  final double scaleFactor;
  const CityPin({ super.key, required this.city, required this.scaleFactor });
  @override
  Widget build(BuildContext context) {
    const double baseFontSize = 12.0; const double baseIconSize = 30.0;
    return Hero(tag: 'city-pin-${city.id}', child: Material(type: MaterialType.transparency, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: EdgeInsets.symmetric(horizontal: 6 * scaleFactor, vertical: 2 * scaleFactor), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(8 * scaleFactor)), child: Text(city.cityName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: baseFontSize * scaleFactor))),
      Icon(Icons.location_on, color: Colors.red, size: baseIconSize * scaleFactor, shadows: [Shadow(color: Colors.black54, blurRadius: 4.0 * scaleFactor)])
    ])));
  }
}