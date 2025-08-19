// GÜNCELLENMİŞ VE TAM DOSYA: lib/screens/discover_page.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math';

import '../services/database_helper.dart';
import '../models/city_model.dart';
import '../models/food_details.dart';
import 'food_details_page.dart';
import 'passport_page.dart';
import 'venue_explorer_page.dart';
import '../widgets/typewriter_chat_message.dart';
import '../widgets/typing_indicator.dart';
import '../models/food_tip_model.dart';

// --- CHAT MESAJI MODELLERİ (Yapısal Değişiklik Yok) ---
abstract class ChatMessage {
  final bool isFromUser;
  ChatMessage(this.isFromUser);
}
class FoodSuggestionMessage extends ChatMessage {
  final List<FoodDetails> foods;
  final Function(FoodDetails) onFoodTapped;
  FoodSuggestionMessage(this.foods, this.onFoodTapped) : super(false);
}
class ButtonOptionsMessage extends ChatMessage {
  final String? title;
  final List<ChatButtonOption> options;
  ButtonOptionsMessage({this.title, required this.options}) : super(false);
}
class ChatButtonOption {
  final String text;
  final IconData? icon; // <-- Değişiklik: İkonu nullable yaptık.
  final VoidCallback onPressed;
  ChatButtonOption(
      {required this.text, this.icon, required this.onPressed});
}
class TypingIndicatorMessage extends ChatMessage {
  TypingIndicatorMessage() : super(false);
}
class StreamingTextMessage extends ChatMessage {
  final String text;
  final VoidCallback onFinished;
  StreamingTextMessage(this.text, {required this.onFinished}) : super(false);
}
class UserTextMessage extends ChatMessage {
  final String text;
  UserTextMessage(this.text) : super(true);
}

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  // --- STATE DEĞİŞKENLERİ ---
  final List<ChatMessage> _chatMessages = [];
  final ScrollController _scrollController = ScrollController();
  City? _selectedCity;
  List<City> _citiesOnMap = [];
  bool _isTransitioning = false;
  bool _isMapLoading = true;
  String _mapStatusMessage = "Harita yükleniyor...";
  
  // <-- YENİ: Türkiye geneli kategorilerini merkezi bir yerde tanımlıyoruz. -->
  final Map<String, String> _turkishCuisineCategories = {
    'kebab': '🔥 Kebabs & Grills',
    'soup': '🍲 Soups',
    'dessert': '🍰 Desserts',
    'street_food': '🌯 Street Food',
    'pastry_bakery': '🍞 Pastries & Bakery',
    'seafood': '🐟 Seafood',
    'breakfast': '🍳 Breakfast',
    'appetizer_meze': '🥗 Appetizers & Mezes',
  };
  
  // Harita pinlerini ayarlamak için kullanılan değişkenler
  bool _isFineTuningMode = false;
  String? _selectedCityForTuning;
  double _tuningX = 0.5;
  double _tuningY = 0.5;

  @override
  void initState() {
    super.initState();
    _loadCitiesForMap();
  }

  // --- MEVCUT, DOKUNULMAYAN METOTLAR ---
  @override
  void dispose() { _scrollController.dispose(); super.dispose(); }
  void _onCitySelected(City city) { setState(() { _selectedCity = city; _isTransitioning = true; }); Timer(const Duration(milliseconds: 2500), () { if (!mounted || !_isTransitioning) return; _startChatFlowForCity(city); }); }
  void _resetToMapView() { setState(() { _selectedCity = null; _chatMessages.clear(); _isTransitioning = false; }); }
  void _addBotMessage(String text, {required VoidCallback onFinished}) { if ((text).isEmpty) { onFinished.call(); return; } setState(() { _chatMessages.removeWhere((msg) => msg is TypingIndicatorMessage); _chatMessages.add(StreamingTextMessage(text, onFinished: onFinished)); }); _scrollToBottom(); }
  void _onFoodTapped(FoodDetails food) => Navigator.push(context, MaterialPageRoute(builder: (context) => FoodDetailsPage(food: food)));
  void _scrollToBottom() { WidgetsBinding.instance.addPostFrameCallback((_) { if (_scrollController.hasClients) { _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); } }); }
  Future<void> _loadCitiesForMap() async { if (mounted) setState(() { _isMapLoading = true; }); List<City> cities = await DatabaseHelper.instance.getAllCities(); int retries = 5; while (cities.isEmpty && retries > 0 && mounted) { await Future.delayed(const Duration(milliseconds: 500)); cities = await DatabaseHelper.instance.getAllCities(); retries--; } if (!mounted) return; if (cities.isEmpty) { setState(() { _citiesOnMap = []; _isMapLoading = false; _mapStatusMessage = "Şehirler yüklenemedi.\nLütfen internet bağlantınızı kontrol edip uygulamayı yeniden başlatın."; }); } else { setState(() { _citiesOnMap = cities; _isMapLoading = false; }); } }
  Future<void> _showRandomInsiderTip(City city) async { final foodTips = await DatabaseHelper.instance.getFoodTipsForCity(city.id); if (foodTips.isNotEmpty) { final randomFoodTip = foodTips[Random().nextInt(foodTips.length)]; await Future.delayed(const Duration(milliseconds: 1000)); if (!mounted) return; showDialog( context: context, barrierDismissible: false, builder: (BuildContext context) { return BackdropFilter( filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), child: AlertDialog( shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), title: const Text("Insider Tip!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)), content: Column( mainAxisSize: MainAxisSize.min, children: [ Text( randomFoodTip.foodDisplayName, textAlign: TextAlign.center, style: TextStyle( fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue.shade700, ), ), const SizedBox(height: 16), Text( randomFoodTip.tip, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4), ), ], ), actions: <Widget>[ TextButton( child: const Text("Got it!", style: TextStyle(fontWeight: FontWeight.bold)), onPressed: () { Navigator.of(context).pop(); }, ), ], ), ); }, ); } }

  // =======================================================================
  // <-- YENİ "ÖNCE ŞEHİR, SONRA TÜRKİYE" CHATBOT AKIŞI -->
  // =======================================================================

  // ADIM 1: Sohbeti Başlat ve Lokal Lezzetleri Sun
  Future<void> _startChatFlowForCity(City city) async {
    _showRandomInsiderTip(city);

    setState(() {
      _isTransitioning = false;
      _chatMessages.clear();
      _chatMessages.add(TypingIndicatorMessage());
    });
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 1200));

    // Supabase'den gelen dinamik karşılama metnini kullan
    final greeting = city.greetingsEn ?? "Welcome to ${city.cityName}!";
    _addBotMessage(greeting, onFinished: () async {
      // Veritabanından o şehre özel yemekleri çek
      final localFoods = await DatabaseHelper.instance.getFoodsForCity(city.id);

      if (localFoods.isNotEmpty) {
        _addBotMessage("When in ${city.cityName}, you absolutely must try these local specialties:", onFinished: () {
          setState(() {
            _chatMessages.add(FoodSuggestionMessage(localFoods, _onFoodTapped));
          });
          _scrollToBottom();
          // Lokal yemekler sunulduktan sonra bir sonraki adımı teklif et
          _offerNextSteps(city);
        });
      } else {
        // Şehre özel yemek yoksa, direkt Türkiye mutfağına geç ve sonunda kültürel bilgileri sor
        _addBotMessage("I'm still learning about the local specialties of ${city.cityName}. But, we can explore the entire Turkish cuisine together!", onFinished: () {
          _showTurkishCuisineCategories();
        });
      }
    });
  }

  // ADIM 2: Sonraki Adımları Sun ("Mekan Bul", "Türkiye Mutfağı", "Daha Fazla Bilgi")
 // Mevcut _offerNextSteps fonksiyonunu sil ve yerine bunu yapıştır.

void _offerNextSteps(City city) {
  Future.delayed(const Duration(milliseconds: 1500), () {
    if (!mounted) return;
    setState(() {
      // ÖNLEM: Ekranda zaten bir seçenek menüsü varsa, onu temizle.
      _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage);

      _chatMessages.add(ButtonOptionsMessage(
        title: "What would you like to do now?", // Başlığı daha genel yaptık.
        options: [
          ChatButtonOption(
            text: "📍 Find places for local food", // Metni netleştirdik.
            icon: Icons.restaurant_menu,
            onPressed: () => _handleNavigateToVenueExplorer(city)
          ),
          ChatButtonOption(
            text: "🇹🇷 Explore all Turkish Cuisine",
            icon: Icons.travel_explore,
            onPressed: _handleExploreTurkishCuisine
          ),
          ChatButtonOption(
            text: "ℹ️ More about ${city.cityName}",
            icon: Icons.info_outline,
            onPressed: _showCityContextOptions
          ),
        ]
      ));
    });
    _scrollToBottom();
  });
}

  // ADIM 2.1: Mekan Kaşifi'ne Yönlendirme
  void _handleNavigateToVenueExplorer(City city) {
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenueExplorerPage(
          city: city,
          showAllTurkishFoods: false, // Sadece lokal yemekler arasından arama yap
        ),
      ),
    );
  }
  
  // ADIM 2.2: Türkiye Mutfağını Keşfetme Akışını Başlatma
  void _handleExploreTurkishCuisine() {
    setState(() {
      _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage);
      _chatMessages.add(UserTextMessage("Explore Turkish Cuisine"));
    });
    _scrollToBottom();
    _addBotMessage("Great choice! The culinary map of Turkey is vast and delicious. Which category interests you the most?", onFinished: () {
      _showTurkishCuisineCategories();
    });
  }
  
  // ADIM 3: Türkiye Mutfağı Kategorilerini Göster
  void _showTurkishCuisineCategories() {
    setState(() {
      final options = _turkishCuisineCategories.entries.map((entry) {
        return ChatButtonOption(
          text: entry.value,
          icon: null, // Kategori butonlarında ikona gerek yok.
          onPressed: () => _handleTurkishCategorySelection(entry.key, entry.value),
        );
      }).toList();
      _chatMessages.add(ButtonOptionsMessage(options: options));
    });
    _scrollToBottom();
  }

   

  

Future<void> _handleTurkishCategorySelection(String categoryKey, String categoryName) async {
  setState(() {
    _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage);
    _chatMessages.add(UserTextMessage(categoryName));
    _chatMessages.add(TypingIndicatorMessage());
  });
  _scrollToBottom();
  
  final foodsInCategory = await DatabaseHelper.instance.getFoodsByCategory(categoryKey);
  
  await Future.delayed(const Duration(milliseconds: 1200));

  if (foodsInCategory.isNotEmpty) {
    _addBotMessage("Here are some of the most beloved dishes from the '$categoryName' category across Turkey:", onFinished: () {
      setState(() {
        _chatMessages.add(FoodSuggestionMessage(foodsInCategory, _onFoodTapped));
      });
      _scrollToBottom();
      
      // GÜNCELLEME: categoryKey'i bir sonraki fonksiyona iletiyoruz.
      _offerVenueExplorerForTurkishCuisine(categoryKey); 
    });
  } else {
    _addBotMessage("I couldn't find any dishes for the '$categoryName' category at the moment. Please try another one!", onFinished: (){
      _showTurkishCuisineCategories();
    });
  }
}
  

 

 
// Mevcut _offerVenueExplorerForTurkishCuisine fonksiyonunu bununla değiştir.

void _offerVenueExplorerForTurkishCuisine(String categoryKey) {
  Future.delayed(const Duration(milliseconds: 1500), () {
    if (!mounted) return;
    setState(() {
      final city = _selectedCity!;

      _chatMessages.add(ButtonOptionsMessage(
        title: "Found something you like? Let's find a place!",
        options: [
          ChatButtonOption(
            text: "📍 Find places for '${_turkishCuisineCategories[categoryKey]}'",
            icon: Icons.search,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VenueExplorerPage(
                    city: city,
                    // ANA GÜNCELLEME: Hangi kategoriden geldiğimizi belirtiyoruz.
                    selectedCategory: categoryKey, 
                  ),
                ),
              );
            }
          ),
          ChatButtonOption(
            text: "⬅️ Back to Categories",
            icon: Icons.category_outlined,
            onPressed: () {
              setState(() {
                 _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage);
              });
              _addBotMessage("Sure, which other category would you like to see?", onFinished: () {
                _showTurkishCuisineCategories();
              });
            }
          ),
          ChatButtonOption(
            text: "ℹ️ More about ${city.cityName}",
            icon: Icons.info_outline,
            onPressed: _showCityContextOptions
          ),
        ]
      ));
    });
    _scrollToBottom();
  });
}

  // --- KÜLTÜREL DETAY FONKSİYONLARI ---
  
  void _showCityContextOptions() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
      _chatMessages.add(ButtonOptionsMessage(
        title: "Want to know more about ${ _selectedCity!.cityName }'s culinary secrets?",
        options: [
          ChatButtonOption(text: "Food Culture", icon: Icons.auto_stories_outlined, onPressed: () => _handleContextQuery("culture", "Food Culture")),
          ChatButtonOption(text: "Local Drinks", icon: Icons.local_cafe_outlined, onPressed: () => _handleContextQuery("drinks", "Local Drinks")),
          ChatButtonOption(text: "Iconic Dish", icon: Icons.star_border_outlined, onPressed: () => _handleContextQuery("iconic_dish", "Iconic Dish")),
          ChatButtonOption(text: "After the Meal", icon: Icons.directions_walk_outlined, onPressed: () => _handleContextQuery("after_meal", "After the Meal")),
        ],
      ));
    });
    _scrollToBottom();
    });
  }

 // Mevcut _handleContextQuery fonksiyonunu sil ve yerine bunu yapıştır.

// Mevcut _handleContextQuery fonksiyonunu bununla DEĞİŞTİR.

void _handleContextQuery(String queryType, String userText) {
  setState(() {
    _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage);
    _chatMessages.add(UserTextMessage(userText));
    _chatMessages.add(TypingIndicatorMessage());
  });
  _scrollToBottom();

  Future.delayed(const Duration(milliseconds: 1200), () {
    if(!mounted) return;
    final city = _selectedCity!;
    String? responseText;
    switch (queryType) {
      case "culture":
        responseText = city.cultureSummaryEn;
        _addBotMessage(responseText ?? "I'm still learning about the unique food culture of ${city.cityName}.", onFinished: () => _offerNextSteps(city));
        break;
      case "drinks":
        responseText = city.localDrinksEn;
        _addBotMessage(responseText ?? "While I don't have specific drink recommendations, Ayran is a popular choice all over Turkey!", onFinished: () => _offerNextSteps(city));
        break;
      case "after_meal":
        responseText = city.postMealSuggestionsEn;
        _addBotMessage(responseText ?? "A short walk and a Turkish coffee is always a great idea after a good meal!", onFinished: () => _offerNextSteps(city));
        break;
      case "iconic_dish":
        _showIconicDish(city);
        break;
    }
  });
}

// Mevcut _showIconicDish fonksiyonunu sil ve yerine bunu yapıştır.

// Mevcut _showIconicDish fonksiyonunu bununla DEĞİŞTİR.

Future<void> _showIconicDish(City city) async {
  if (city.iconicDishName == null || city.iconicDishName!.isEmpty) {
    _addBotMessage("It's hard to pick just one! Every dish in ${city.cityName} tells a part of its story.", onFinished: () => _offerNextSteps(city));
    return;
  }

  final iconicDishDetails = await DatabaseHelper.instance.getFoodByName(city.iconicDishName!);

  if (iconicDishDetails != null) {
    _addBotMessage("When in ${city.cityName}, you absolutely must try its most iconic dish: ${iconicDishDetails.turkishName}!",
      onFinished: () {
        setState(() {
          _chatMessages.add(FoodSuggestionMessage([iconicDishDetails], _onFoodTapped));
        });
        _scrollToBottom();
        Future.delayed(const Duration(milliseconds: 500), () => _offerNextSteps(city));
      }
    );
  } else {
    _addBotMessage("I know the most iconic dish is '${city.iconicDishName}', but I couldn't find its details right now.", onFinished: () => _offerNextSteps(city));
  }
}

  // =======================================================================
  // --- BUILD METOTLARI (YAPISAL DEĞİŞİKLİK YOK, SADECE BİR WIDGET GÜNCELLENDİ) ---
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCity?.cityName ?? 'DishAI - Flavor Explorer'),
        backgroundColor: Colors.blue.shade300,
        leading: _selectedCity != null ? IconButton(icon: const Icon(Icons.map_outlined), onPressed: _resetToMapView, tooltip: 'Back to Map') : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () { Navigator.push( context, MaterialPageRoute(builder: (context) => const PassportPage()), ); },
            tooltip: 'Flavor Passport',
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _chatMessages.isEmpty && !_isTransitioning ? _buildMapView() : _buildChatView(),
          ),
          _buildTransitionOverlay(),
        ],
      ),
    );
  }

  Widget _buildMapView() { if (_isMapLoading) { return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(_mapStatusMessage)])); } if (_citiesOnMap.isEmpty) { return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(_mapStatusMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)))); } const double imageAspectRatio = 1920 / 924; final Map<String, Offset> cityCoordinates = { 'Ankara': const Offset(0.34, 0.45), 'İzmir': const Offset(0.05, 0.63), 'Gaziantep': const Offset(0.60, 0.86), 'Trabzon': const Offset(0.72, 0.27), 'Bursa': const Offset(0.17, 0.35), 'Hatay': const Offset(0.55, 0.95), 'Mersin': const Offset(0.41, 0.94), 'Erzurum': const Offset(0.82, 0.38), 'Kayseri': const Offset(0.52, 0.59), 'Şanlıurfa': const Offset(0.69, 0.83) }; return Column(children: [ Expanded(child: LayoutBuilder(builder: (context, constraints) { final containerWidth = constraints.maxWidth; final containerHeight = constraints.maxHeight; final containerAspectRatio = containerWidth / containerHeight; double renderedImageWidth; double renderedImageHeight; if (containerAspectRatio > imageAspectRatio) { renderedImageHeight = containerHeight; renderedImageWidth = renderedImageHeight * imageAspectRatio; } else { renderedImageWidth = containerWidth; renderedImageHeight = renderedImageWidth / imageAspectRatio; } const double referenceWidth = 800.0; final double scaleFactor = (renderedImageWidth / referenceWidth).clamp(0.7, 1.2); return Center(child: SizedBox(width: renderedImageWidth, height: renderedImageHeight, child: Stack(children: [ Image.asset('assets/images/turkey_map.png', fit: BoxFit.fill), ..._citiesOnMap.where((city) => cityCoordinates.containsKey(city.cityName)).map((city) { final isTuningThisCity = _isFineTuningMode && _selectedCityForTuning == city.cityName; final coords = isTuningThisCity ? Offset(_tuningX, _tuningY) : cityCoordinates[city.cityName]!; final leftPosition = renderedImageWidth * coords.dx; final topPosition = renderedImageHeight * coords.dy; return Positioned(left: leftPosition, top: topPosition, child: Transform.translate(offset: Offset(-25 * scaleFactor, -55 * scaleFactor), child: GestureDetector(onTap: () { if (_isFineTuningMode) { setState(() { _selectedCityForTuning = city.cityName; _tuningX = cityCoordinates[city.cityName]!.dx; _tuningY = cityCoordinates[city.cityName]!.dy; }); } else { _onCitySelected(city); } }, child: CityPin(city: city, scaleFactor: scaleFactor)))); }).toList()]))); })), if (_isFineTuningMode) Container(padding: const EdgeInsets.all(12), color: Colors.grey.shade200, child: Column(children: [ Text('İnce Ayar Modu: ${_selectedCityForTuning ?? "Konumu ayarlamak için bir şehir seçin."}', style: const TextStyle(fontWeight: FontWeight.bold)), if (_selectedCityForTuning != null) ...[ Row(children: [ const Text('X: '), Expanded(child: Slider(value: _tuningX, min: 0.0, max: 1.0, divisions: 200, label: _tuningX.toStringAsFixed(2), onChanged: (value) => setState(() => _tuningX = value))) ]), Row(children: [ const Text('Y: '), Expanded(child: Slider(value: _tuningY, min: 0.0, max: 1.0, divisions: 200, label: _tuningY.toStringAsFixed(2), onChanged: (value) => setState(() => _tuningY = value))) ]), const Text("Koddaki 'cityCoordinates' map'ine yapıştırmak için:", style: TextStyle(fontSize: 10, color: Colors.grey)), SelectableText("'$_selectedCityForTuning': const Offset(${_tuningX.toStringAsFixed(2)}, ${_tuningY.toStringAsFixed(2)}),", style: const TextStyle(fontFamily: 'monospace', backgroundColor: Colors.white, fontWeight: FontWeight.bold)) ] ])) ]); }
  Widget _buildTransitionOverlay() { return AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: _isTransitioning ? 1.0 : 0.0, child: IgnorePointer(ignoring: !_isTransitioning, child: Stack(children: [ BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: Container(color: Colors.black.withOpacity(0.4))), if (_selectedCity != null) _buildJourneyStartMessage(_selectedCity!)]))); }
  Widget _buildJourneyStartMessage(City city) { return Center(child: Container(padding: const EdgeInsets.all(24), margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 20), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.8) ]), borderRadius: BorderRadius.circular(20), boxShadow: [ BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, spreadRadius: 5) ]), child: Column(mainAxisSize: MainAxisSize.min, children: [ TweenAnimationBuilder(duration: const Duration(milliseconds: 1200), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Transform.scale(scale: 0.8 + (value * 0.2), child: Transform.rotate(angle: value * 0.1, child: Hero(tag: 'city-pin-${city.id}', child: Material(type: MaterialType.transparency, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ Colors.blue.shade400, Colors.blue.shade600 ]), boxShadow: [ BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, spreadRadius: 2) ]), child: const Icon(Icons.explore, size: 40, color: Colors.white)))))); }), const SizedBox(height: 20), TweenAnimationBuilder(duration: const Duration(milliseconds: 800), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: Text("Exploring ${city.cityName}", style: TextStyle(fontSize: 24, color: Colors.blue.shade800, fontWeight: FontWeight.bold, letterSpacing: 1.2), textAlign: TextAlign.center))); }), const SizedBox(height: 12), TweenAnimationBuilder(duration: const Duration(milliseconds: 1000), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 15 * (1 - value)), child: Text("Discovering authentic flavors and culinary treasures", style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500), textAlign: TextAlign.center))); }), const SizedBox(height: 24), SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600), backgroundColor: Colors.blue.shade100)), const SizedBox(height: 16), TweenAnimationBuilder(duration: const Duration(milliseconds: 1500), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (index) { final delay = index * 0.3; final animValue = ((value - delay).clamp(0.0, 1.0)); return Container(margin: const EdgeInsets.symmetric(horizontal: 4), child: AnimatedContainer(duration: Duration(milliseconds: 300 + (index * 100)), width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.shade400.withOpacity(animValue)))); })); })]))); }
  Widget _buildChatView() { return Column(children: [ Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(16.0), itemCount: _chatMessages.length, itemBuilder: (context, index) { final message = _chatMessages[index]; if (message is UserTextMessage) { return _buildUserMessage(message); } if (message is TypingIndicatorMessage) { return _buildBotMessageWrapper(const AnimatedTypingIndicator()); } if (message is StreamingTextMessage) { return _buildBotMessageWrapper(TypewriterChatMessage(text: message.text, onCharacterTyped: _scrollToBottom, onFinishedTyping: message.onFinished)); } if (message is FoodSuggestionMessage) { return _buildFoodSuggestions(message.foods, message.onFoodTapped); } if (message is ButtonOptionsMessage) { return _buildButtonOptions(message); } return const SizedBox.shrink(); })), ]); }
  Widget _buildUserMessage(UserTextMessage message) { return Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), margin: const EdgeInsets.symmetric(vertical: 4).copyWith(left: 80), decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(20).copyWith(topRight: const Radius.circular(4))), child: Text(message.text, style: const TextStyle(fontSize: 16, color: Colors.white)))); }
  Widget _buildBotMessageWrapper(Widget child) { return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.explore_outlined, color: Colors.white, size: 20)), const SizedBox(width: 8), Expanded(child: child)])); }
  Widget _buildFoodSuggestions(List<FoodDetails> foods, Function(FoodDetails) onFoodTapped) { return Container(height: 140, alignment: Alignment.centerLeft, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: foods.length, itemBuilder: (context, index) { final food = foods[index]; return GestureDetector(onTap: () => onFoodTapped(food), child: Container(width: 120, margin: const EdgeInsets.only(right: 10), child: Column(mainAxisSize: MainAxisSize.min, children: [ CircleAvatar(radius: 40, backgroundImage: (food.imageUrl != null && food.imageUrl!.isNotEmpty) ? NetworkImage(food.imageUrl!) : null, backgroundColor: Colors.grey.shade200, child: (food.imageUrl == null || food.imageUrl!.isEmpty) ? const Icon(Icons.ramen_dining, color: Colors.grey, size: 40) : null), const SizedBox(height: 8), Text(food.turkishName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))])));})); }
  
  // <-- GÜNCELLENMİŞ WIDGET: İkonsuz butonları destekler.
  Widget _buildButtonOptions(ButtonOptionsMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text(message.title!, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: message.options.map((option) {
              return option.icon != null
                  ? ElevatedButton.icon(
                      icon: Icon(option.icon, size: 18),
                      label: Text(option.text),
                      onPressed: option.onPressed,
                      style: ElevatedButton.styleFrom(elevation: 1, backgroundColor: Colors.white, foregroundColor: Colors.blue.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.blue.shade100))),
                    )
                  : ElevatedButton(
                      onPressed: option.onPressed,
                      child: Text(option.text),
                      style: ElevatedButton.styleFrom(elevation: 1, backgroundColor: Colors.white, foregroundColor: Colors.blue.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.blue.shade100))),
                    );
            }).toList(),
          )
        ],
      ),
    );
  }
}

class CityPin extends StatelessWidget {
  final City city;
  final double scaleFactor;
  const CityPin({super.key, required this.city, required this.scaleFactor});
  @override
  Widget build(BuildContext context) {
    const double baseFontSize = 12.0; const double baseIconSize = 30.0;
    return Hero(tag: 'city-pin-${city.id}', child: Material(type: MaterialType.transparency, child: Column(mainAxisSize: MainAxisSize.min, children: [ Container(padding: EdgeInsets.symmetric(horizontal: 6 * scaleFactor, vertical: 2 * scaleFactor), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(8 * scaleFactor)), child: Text(city.cityName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: baseFontSize * scaleFactor))), Icon(Icons.location_on, color: Colors.red, size: baseIconSize * scaleFactor, shadows: [Shadow(color: Colors.black54, blurRadius: 4.0 * scaleFactor)])])));
  }
}