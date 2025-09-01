import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/database_helper.dart';
import '../models/city_model.dart';
import '../models/food_details.dart';
import 'food_details_page.dart';
import 'passport_page.dart';
import 'venue_explorer_page.dart';
import '../widgets/typewriter_chat_message.dart';
import '../widgets/typing_indicator.dart';
import '../models/food_tip_model.dart';
import '../widgets/loading_animation.dart';

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
  final IconData? icon;
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
  DiscoverPage({Key? key}) : super(key: key);

  @override
  State<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends State<DiscoverPage> with TickerProviderStateMixin {
  // --- STATE DEĞİŞKENLERİ ---
  final List<ChatMessage> _chatMessages = [];
  // ScrollController BURADAN KALDIRILDI!
  City? _selectedCity;
  List<City> _citiesOnMap = [];
  bool _isTransitioning = false;
  bool _isMapLoading = true;
  String _mapStatusMessage = "Harita yükleniyor...";
  
  // --- ANİMASYON DEĞİŞKENLERİ ---
  late final AnimationController _sceneAnimationController;
  late final Animation<double> _scaleAnimation;
  Timer? _sceneTimer;
  int _currentSceneIndex = 0;
  
  final List<String> _sceneImages = [
    'assets/images/scenes/scene_1.png',
    'assets/images/scenes/scene_2.png',
    'assets/images/scenes/scene_3.png',
    'assets/images/scenes/scene_4.png',
    'assets/images/scenes/scene_5.png',
  ];

  final Map<String, String> _turkishCuisineCategories = {
    'kebab': '🔥 Kebabs & Grills',
    'soup': '🍲 Soups',
    'dessert': '🍰 Desserts',
    'street_food': '🌯 Street Food',
    'pastry_bakery': '🍞 Pastries & Bakery',
    'seafood': '🐟 Seafood',
    'breakfast': '🍳 Breakfast',
    'appetizer_meze': '🥗 Appetizers & Mezes',
    'drinks': '🍹 Drinks & Beverages',
  };
  
  bool _isFineTuningMode =false;
  String? _selectedCityForTuning;
  double _tuningX = 0.5;
  double _tuningY = 0.5;

  @override
  void initState() {
    super.initState();
    _loadCitiesForMap();

    _sceneAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _sceneAnimationController, curve: Curves.easeInOut)
    );

    _sceneTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && _selectedCity == null) {
        setState(() {
          _currentSceneIndex = (_currentSceneIndex + 1) % _sceneImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _sceneAnimationController.dispose();
    _sceneTimer?.cancel();
    super.dispose();
  }
  
  void _onCitySelected(City city) { 
    setState(() { 
      _selectedCity = city; 
      _isTransitioning = true; 
    }); 
    Timer(const Duration(milliseconds: 2500), () { 
      if (!mounted || !_isTransitioning) return; 
      startChatFlowForCity(city); 
    }); 
  }

  void _resetToMapView() {
    // Controller yönetimi artık burada değil. Sadece state'i temizliyoruz.
    setState(() {
      _selectedCity = null;
      _chatMessages.clear();
      _isTransitioning = false;
    });
  }

  void _addBotMessage(String text, {required VoidCallback onFinished}) { 
      if ((text).isEmpty) { onFinished.call(); return; } 
      if (!mounted) return;
      setState(() { 
          _chatMessages.removeWhere((msg) => msg is TypingIndicatorMessage); 
          _chatMessages.add(StreamingTextMessage(text, onFinished: onFinished)); 
      }); 
  }

  void _onFoodTapped(FoodDetails food) => Navigator.push(context, MaterialPageRoute(builder: (context) => FoodDetailsPage(food: food)));
  
  // _scrollToBottom metodu buradan kaldırıldı, çünkü artık _ChatView içinde.

  Future<void> _loadCitiesForMap() async { /* ... içerik aynı ... */
      if (mounted) setState(() { _isMapLoading = true; }); List<City> cities = await DatabaseHelper.instance.getAllCities(); int retries = 5; while (cities.isEmpty && retries > 0 && mounted) { await Future.delayed(const Duration(milliseconds: 500)); cities = await DatabaseHelper.instance.getAllCities(); retries--; } if (!mounted) return; if (cities.isEmpty) { setState(() { _citiesOnMap = []; _isMapLoading = false; _mapStatusMessage = "Şehirler yüklenemedi.\nLütfen internet bağlantınızı kontrol edip uygulamayı yeniden başlatın."; }); } else { setState(() { _citiesOnMap = cities; _isMapLoading = false; }); } 
  }
  Future<void> _showRandomInsiderTip(City city) async { /* ... içerik aynı ... */
      final foodTips = await DatabaseHelper.instance.getFoodTipsForCity(city.id); if (foodTips.isNotEmpty) { final randomFoodTip = foodTips[Random().nextInt(foodTips.length)]; await Future.delayed(const Duration(milliseconds: 1000)); if (!mounted) return; showDialog( context: context, barrierDismissible: false, builder: (BuildContext context) { return BackdropFilter( filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), child: AlertDialog( shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), title: const Text("Insider Tip!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)), content: Column( mainAxisSize: MainAxisSize.min, children: [ Text( randomFoodTip.foodDisplayName, textAlign: TextAlign.center, style: TextStyle( fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue.shade700, ), ), const SizedBox(height: 16), Text( randomFoodTip.tip, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4), ), ], ), actions: <Widget>[ TextButton( child: const Text("Got it!", style: TextStyle(fontWeight: FontWeight.bold)), onPressed: () { Navigator.of(context).pop(); }, ), ], ), ); }, ); } 
  }

  Future<void> startChatFlowForCity(City city) async {
    _showRandomInsiderTip(city);

    // Controller yönetimi artık burada değil. Sadece state'i güncelliyoruz.
    setState(() {
      _isTransitioning = false;
      _chatMessages.clear();
      _chatMessages.add(TypingIndicatorMessage());
      _selectedCity = city;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    final greeting = city.greetingsEn ?? "Welcome to ${city.cityName}!";
    _addBotMessage(greeting, onFinished: () async {
      final localFoods = await DatabaseHelper.instance.getFoodsForCity(city.id);

      if (localFoods.isNotEmpty) {
        _addBotMessage("When in ${city.cityName}, you absolutely must try these local specialties:", onFinished: () {
          if (!mounted) return;
          setState(() {
            _chatMessages.add(FoodSuggestionMessage(localFoods, _onFoodTapped));
          });
          _offerNextSteps(city);
        });
      } else {
        _addBotMessage("I'm still learning about the local specialties of ${city.cityName}. But, we can explore the entire Turkish cuisine together!", onFinished: () {
          _showTurkishCuisineCategories();
        });
      }
    });
  }

  void _offerNextSteps(City city) { /* ... içerik aynı ... */
      Future.delayed(const Duration(milliseconds: 1500), () { if (!mounted) return; setState(() { _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage); _chatMessages.add(ButtonOptionsMessage( title: "What would you like to do now?", options: [ ChatButtonOption( text: "📍 Find places for local food", icon: Icons.restaurant_menu, onPressed: () => _handleNavigateToVenueExplorer(city) ), ChatButtonOption( text: "🇹🇷 Explore all Turkish Cuisine", icon: Icons.travel_explore, onPressed: _handleExploreTurkishCuisine ), ChatButtonOption( text: "ℹ️ More about ${city.cityName}", icon: Icons.info_outline, onPressed: _showCityContextOptions ), ] )); }); }); 
  }
  void _handleNavigateToVenueExplorer(City city) { /* ... içerik aynı ... */
       Navigator.push( context, MaterialPageRoute( builder: (context) => VenueExplorerPage( city: city, showAllTurkishFoods: false, ), ), ); 
  }
  void _handleExploreTurkishCuisine() { /* ... içerik aynı ... */
      setState(() { _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage); _chatMessages.add(UserTextMessage("Explore Turkish Cuisine")); }); _addBotMessage("Great choice! The culinary map of Turkey is vast and delicious. Which category interests you the most?", onFinished: () { _showTurkishCuisineCategories(); }); 
  }
  void _showTurkishCuisineCategories() { /* ... içerik aynı ... */
      setState(() { final options = _turkishCuisineCategories.entries.map((entry) { return ChatButtonOption( text: entry.value, icon: null, onPressed: () => _handleTurkishCategorySelection(entry.key, entry.value), ); }).toList(); _chatMessages.add(ButtonOptionsMessage(options: options)); }); 
  }
  Future<void> _handleTurkishCategorySelection(String categoryKey, String categoryName) async { /* ... içerik aynı ... */
    setState(() { _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage); _chatMessages.add(UserTextMessage(categoryName)); _chatMessages.add(TypingIndicatorMessage()); }); final foodsInCategory = await DatabaseHelper.instance.getFoodsByCategory(categoryKey); await Future.delayed(const Duration(milliseconds: 1200)); if (foodsInCategory.isNotEmpty) { _addBotMessage("Here are some of the most beloved dishes from the '$categoryName' category across Turkey:", onFinished: () { setState(() { _chatMessages.add(FoodSuggestionMessage(foodsInCategory, _onFoodTapped)); }); _offerVenueExplorerForTurkishCuisine(categoryKey); }); } else { _addBotMessage("I couldn't find any dishes for the '$categoryName' category at the moment. Please try another one!", onFinished: (){ _showTurkishCuisineCategories(); }); } 
  }
  void _offerVenueExplorerForTurkishCuisine(String categoryKey) { /* ... içerik aynı ... */
      Future.delayed(const Duration(milliseconds: 1500), () { if (!mounted) return; setState(() { final city = _selectedCity!; _chatMessages.add(ButtonOptionsMessage( title: "Found something you like? Let's find a place!", options: [ ChatButtonOption( text: "📍 Find places for '${_turkishCuisineCategories[categoryKey]}'", icon: Icons.search, onPressed: () { Navigator.push( context, MaterialPageRoute( builder: (context) => VenueExplorerPage( city: city, selectedCategory: categoryKey, ), ), ); } ), ChatButtonOption( text: "⬅️ Back to Categories", icon: Icons.category_outlined, onPressed: () { setState(() { _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage); }); _addBotMessage("Sure, which other category would you like to see?", onFinished: () { _showTurkishCuisineCategories(); }); } ), ChatButtonOption( text: "ℹ️ More about ${city.cityName}", icon: Icons.info_outline, onPressed: _showCityContextOptions ), ] )); }); }); 
  }
  void _showCityContextOptions() { /* ... içerik aynı ... */
      Future.delayed(const Duration(milliseconds: 500), () { if (!mounted) return; setState(() { _chatMessages.add(ButtonOptionsMessage( title: "Want to know more about ${ _selectedCity!.cityName }'s culinary secrets?", options: [ ChatButtonOption(text: "Food Culture", icon: Icons.auto_stories_outlined, onPressed: () => _handleContextQuery("culture", "Food Culture")), ChatButtonOption(text: "Local Drinks", icon: Icons.local_cafe_outlined, onPressed: () => _handleContextQuery("drinks", "Local Drinks")), ChatButtonOption(text: "Iconic Dish", icon: Icons.star_border_outlined, onPressed: () => _handleContextQuery("iconic_dish", "Iconic Dish")), ChatButtonOption(text: "After the Meal", icon: Icons.directions_walk_outlined, onPressed: () => _handleContextQuery("after_meal", "After the Meal")), ], )); }); }); 
  }
  void _handleContextQuery(String queryType, String userText) { /* ... içerik aynı ... */
    setState(() { _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage); _chatMessages.add(UserTextMessage(userText)); _chatMessages.add(TypingIndicatorMessage()); }); Future.delayed(const Duration(milliseconds: 1200), () { if(!mounted) return; final city = _selectedCity!; String? responseText; switch (queryType) { case "culture": responseText = city.cultureSummaryEn; _addBotMessage(responseText ?? "I'm still learning about the unique food culture of ${city.cityName}.", onFinished: () => _offerNextSteps(city)); break; case "drinks": responseText = city.localDrinksEn; _addBotMessage(responseText ?? "While I don't have specific drink recommendations, Ayran is a popular choice all over Turkey!", onFinished: () => _offerNextSteps(city)); break; case "after_meal": responseText = city.postMealSuggestionsEn; _addBotMessage(responseText ?? "A short walk and a Turkish coffee is always a great idea after a good meal!", onFinished: () => _offerNextSteps(city)); break; case "iconic_dish": _showIconicDish(city); break; } }); 
  }
  Future<void> _showIconicDish(City city) async { /* ... içerik aynı ... */
      if (city.iconicDishName == null || city.iconicDishName!.isEmpty) { _addBotMessage("It's hard to pick just one! Every dish in ${city.cityName} tells a part of its story.", onFinished: () => _offerNextSteps(city)); return; } final iconicDishDetails = await DatabaseHelper.instance.getFoodByName(city.iconicDishName!); if (iconicDishDetails != null) { _addBotMessage("When in ${city.cityName}, you absolutely must try its most iconic dish: ${iconicDishDetails.turkishName}!", onFinished: () { setState(() { _chatMessages.add(FoodSuggestionMessage([iconicDishDetails], _onFoodTapped)); }); Future.delayed(const Duration(milliseconds: 500), () => _offerNextSteps(city)); } ); } else { _addBotMessage("I know the most iconic dish is '${city.iconicDishName}', but I couldn't find its details right now.", onFinished: () => _offerNextSteps(city)); } 
  }
  
  // --- BUILD METOTLARI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCity?.cityName ?? 'Sofra - Flavor Explorer'),
        leading: _selectedCity != null 
            ? IconButton(
                icon: const Icon(Icons.map_outlined), 
                onPressed: _resetToMapView,
                tooltip: 'Back to Map',
              )
            : null,
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
            // DEĞİŞİKLİK: _buildChatView yerine _ChatView widget'ını kullanıyoruz
            child: _chatMessages.isEmpty && !_isTransitioning 
                ? _buildMapView() 
                : _ChatView(
                    key: const ValueKey('chat'), // AnimatedSwitcher için anahtar
                    messages: _chatMessages,
                    onFoodTapped: _onFoodTapped,
                    addBotMessage: _addBotMessage,
                    offerNextSteps: () => _offerNextSteps(_selectedCity!),
                    showCityContextOptions: _showCityContextOptions,
                    showTurkishCuisineCategories: _showTurkishCuisineCategories,
                    handleNavigateToVenueExplorer: () => _handleNavigateToVenueExplorer(_selectedCity!),
                    handleExploreTurkishCuisine: _handleExploreTurkishCuisine,
                    handleTurkishCategorySelection: _handleTurkishCategorySelection,
                    offerVenueExplorerForTurkishCuisine: (cat) => _offerVenueExplorerForTurkishCuisine(cat),
                    handleContextQuery: _handleContextQuery,
                    showIconicDish: () => _showIconicDish(_selectedCity!),
                    turkishCuisineCategories: _turkishCuisineCategories
                  ),
          ),
          _buildTransitionOverlay(),
        ],
      ),
    );
  }

  // ... (_buildMapView ve diğer alt build metotları burada, onlarda değişiklik yok)
   Widget _buildMapView() {
    if (_isMapLoading) { return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(_mapStatusMessage)])); } if (_citiesOnMap.isEmpty) { return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(_mapStatusMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)))); } const double imageAspectRatio = 1920 / 924; final Map<String, Offset> cityCoordinates = { 'Ankara': const Offset(0.34, 0.45), 'İzmir': const Offset(0.05, 0.63), 'Gaziantep': const Offset(0.60, 0.86), 'Trabzon': const Offset(0.72, 0.27), 'Bursa': const Offset(0.17, 0.40), 'Hatay': const Offset(0.55, 0.95), 'Mersin': const Offset(0.41, 0.94), 'Erzurum': const Offset(0.82, 0.38), 'Kayseri': const Offset(0.52, 0.59),'Istanbul': const Offset(0.17, 0.22) , 'Şanlıurfa': const Offset(0.69, 0.83) }; return Stack( fit: StackFit.expand, children: [ IgnorePointer( child: AnimatedSwitcher( duration: const Duration(seconds: 2), transitionBuilder: (Widget child, Animation<double> animation) { return FadeTransition(opacity: animation, child: child); }, child: ScaleTransition( key: ValueKey<int>(_currentSceneIndex), scale: _scaleAnimation, child: Container( decoration: BoxDecoration( image: DecorationImage( image: AssetImage(_sceneImages[_currentSceneIndex]), fit: BoxFit.cover, colorFilter: ColorFilter.mode( Colors.deepOrange.withOpacity(0.05), BlendMode.multiply, ), opacity: 0.4, ), ), ), ), ), ), LayoutBuilder(builder: (context, constraints) { final containerWidth = constraints.maxWidth; final containerHeight = constraints.maxHeight; final containerAspectRatio = containerWidth / containerHeight; double renderedImageWidth; double renderedImageHeight; if (containerAspectRatio > imageAspectRatio) { renderedImageHeight = containerHeight; renderedImageWidth = renderedImageHeight * imageAspectRatio; } else { renderedImageWidth = containerWidth; renderedImageHeight = renderedImageWidth / imageAspectRatio; } const double referenceWidth = 800.0; final double scaleFactor = (renderedImageWidth / referenceWidth).clamp(0.7, 1.2); return Center(child: SizedBox(width: renderedImageWidth, height: renderedImageHeight, child: Stack(children: [ Image.asset('assets/images/turkey_map.png', fit: BoxFit.fill), ..._citiesOnMap.where((city) => cityCoordinates.containsKey(city.cityName)).map((city) { final isTuningThisCity = _isFineTuningMode && _selectedCityForTuning == city.cityName; final coords = isTuningThisCity ? Offset(_tuningX, _tuningY) : cityCoordinates[city.cityName]!; final leftPosition = renderedImageWidth * coords.dx; final topPosition = renderedImageHeight * coords.dy; return Positioned(left: leftPosition, top: topPosition, child: Transform.translate(offset: Offset(-25 * scaleFactor, -55 * scaleFactor), child: GestureDetector(onTap: () { if (_isFineTuningMode) { setState(() { _selectedCityForTuning = city.cityName; _tuningX = cityCoordinates[city.cityName]!.dx; _tuningY = cityCoordinates[city.cityName]!.dy; }); } else { _onCitySelected(city); } }, child: CityPin(city: city, scaleFactor: scaleFactor)))); }).toList() ]))); }), IgnorePointer( child: Container( decoration: BoxDecoration( gradient: LinearGradient( begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [ Colors.black.withOpacity(0.4), Colors.transparent, ], stops: const [0.0, 0.4], ), ), ), ), IgnorePointer( child: Positioned( top: 50, left: 20, right: 20, child: Column( crossAxisAlignment: CrossAxisAlignment.center, children: [ Text( "A Legacy of Flavor", textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay( color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 1.2, shadows: [const Shadow(blurRadius: 12.0, color: Colors.black54)], ), ), const SizedBox(height: 12), Text( "Every city tells a story, every dish holds a memory.\nSelect a city to begin your journey.", textAlign: TextAlign.center, style: GoogleFonts.lato( color: Colors.white.withOpacity(0.95), fontSize: 16, height: 1.5, shadows: [const Shadow(blurRadius: 8.0, color: Colors.black54)], ), ), ], ), ), ), if (_isFineTuningMode) Positioned( bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(12), color: Colors.grey.shade200.withOpacity(0.9), child: Column(children: [ Text('İnce Ayar Modu: ${_selectedCityForTuning ?? "Konumu ayarlamak için bir şehir seçin."}', style: const TextStyle(fontWeight: FontWeight.bold)), if (_selectedCityForTuning != null) ...[ Row(children: [ const Text('X: '), Expanded(child: Slider(value: _tuningX, min: 0.0, max: 1.0, divisions: 200, label: _tuningX.toStringAsFixed(2), onChanged: (value) => setState(() => _tuningX = value))) ]), Row(children: [ const Text('Y: '), Expanded(child: Slider(value: _tuningY, min: 0.0, max: 1.0, divisions: 200, label: _tuningY.toStringAsFixed(2), onChanged: (value) => setState(() => _tuningY = value))) ]), const Text("Koddaki 'cityCoordinates' map'ine yapıştırmak için:", style: TextStyle(fontSize: 10, color: Colors.grey)), SelectableText("'$_selectedCityForTuning': const Offset(${_tuningX.toStringAsFixed(2)}, ${_tuningY.toStringAsFixed(2)}),", style: const TextStyle(fontFamily: 'monospace', backgroundColor: Colors.white, fontWeight: FontWeight.bold)) ] ]))) , ], ); 
   }
  Widget _buildTransitionOverlay() { return AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: _isTransitioning ? 1.0 : 0.0, child: IgnorePointer(ignoring: !_isTransitioning, child: Stack(children: [ BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: Container(color: Colors.black.withOpacity(0.4))), if (_selectedCity != null) _buildJourneyStartMessage(_selectedCity!)]))); }
  Widget _buildJourneyStartMessage(City city) { return Center(child: Container(padding: const EdgeInsets.all(24), margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 20), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ Colors.deepOrange.shade50, Colors.deepOrange.shade100.withOpacity(0.8) ]), borderRadius: BorderRadius.circular(20), boxShadow: [ BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 20, spreadRadius: 5) ]), child: Column(mainAxisSize: MainAxisSize.min, children: [ TweenAnimationBuilder(duration: const Duration(milliseconds: 1200), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Transform.scale(scale: 0.8 + (value * 0.2), child: Transform.rotate(angle: value * 0.1, child: Hero(tag: 'city-pin-${city.id}', child: Material(type: MaterialType.transparency, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.primary ]), boxShadow: [ BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 15, spreadRadius: 2) ]), child: const Icon(Icons.explore, size: 40, color: Colors.white)))))); }), const SizedBox(height: 20), TweenAnimationBuilder(duration: const Duration(milliseconds: 800), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: Text("Exploring ${city.cityName}", style: TextStyle(fontSize: 24, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2), textAlign: TextAlign.center))); }), const SizedBox(height: 12), TweenAnimationBuilder(duration: const Duration(milliseconds: 1000), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 15 * (1 - value)), child: Text("Discovering authentic flavors and culinary treasures", style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500), textAlign: TextAlign.center))); }), const SizedBox(height: 24), const LoadingAnimation(size: 80), const SizedBox(height: 16), TweenAnimationBuilder(duration: const Duration(milliseconds: 1500), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (index) { final delay = index * 0.3; final animValue = ((value - delay).clamp(0.0, 1.0)); return Container(margin: const EdgeInsets.symmetric(horizontal: 4), child: AnimatedContainer(duration: Duration(milliseconds: 300 + (index * 100)), width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withOpacity(animValue)))); })); })]))); }
}


// =======================================================================
// =================== YENİ ÖZEL CHAT WIDGET'I =======================
// =======================================================================

class _ChatView extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(FoodDetails) onFoodTapped;
  // Callback'leri DiscoverPageState'ten buraya taşıdık.
  final Function(String, {required VoidCallback onFinished}) addBotMessage;
  final VoidCallback offerNextSteps;
  final VoidCallback showCityContextOptions;
  final VoidCallback showTurkishCuisineCategories;
  final VoidCallback handleNavigateToVenueExplorer;
  final VoidCallback handleExploreTurkishCuisine;
  final Function(String, String) handleTurkishCategorySelection;
  final Function(String) offerVenueExplorerForTurkishCuisine;
  final Function(String, String) handleContextQuery;
  final VoidCallback showIconicDish;
  final Map<String, String> turkishCuisineCategories;


  const _ChatView({
    super.key,
    required this.messages,
    required this.onFoodTapped,
    required this.addBotMessage,
    required this.offerNextSteps,
    required this.showCityContextOptions,
    required this.showTurkishCuisineCategories,
    required this.handleNavigateToVenueExplorer,
    required this.handleExploreTurkishCuisine,
    required this.handleTurkishCategorySelection,
    required this.offerVenueExplorerForTurkishCuisine,
    required this.handleContextQuery,
    required this.showIconicDish,
    required this.turkishCuisineCategories,
  });

  @override
  __ChatViewState createState() => __ChatViewState();
}

class __ChatViewState extends State<_ChatView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(covariant _ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(maxScroll, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          itemCount: widget.messages.length,
          itemBuilder: (context, index) {
            final message = widget.messages[index];
            if (message is UserTextMessage) { return _buildUserMessage(message); }
            if (message is TypingIndicatorMessage) { return _buildBotMessageWrapper(const AnimatedTypingIndicator()); }
            if (message is StreamingTextMessage) { return _buildBotMessageWrapper(TypewriterChatMessage(text: message.text, onCharacterTyped: _scrollToBottom, onFinishedTyping: message.onFinished)); }
            if (message is FoodSuggestionMessage) { return _buildFoodSuggestions(message.foods, widget.onFoodTapped); }
            if (message is ButtonOptionsMessage) { return _buildButtonOptions(message); }
            return const SizedBox.shrink();
          },
        ),
      ),
    ]);
  }
  
  // Build metotları artık _DiscoverPageState'ten buraya taşındı.
  Widget _buildUserMessage(UserTextMessage message) { return Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), margin: const EdgeInsets.symmetric(vertical: 4).copyWith(left: 80), decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(20).copyWith(topRight: const Radius.circular(4))), child: Text(message.text, style: const TextStyle(fontSize: 16, color: Colors.white)))); }
  Widget _buildBotMessageWrapper(Widget child) { return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.explore_outlined, color: Colors.white, size: 20)), const SizedBox(width: 8), Expanded(child: child)])); }
  Widget _buildFoodSuggestions(List<FoodDetails> foods, Function(FoodDetails) onFoodTapped) { return Container(height: 140, alignment: Alignment.centerLeft, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: foods.length, itemBuilder: (context, index) { final food = foods[index]; return GestureDetector(onTap: () => onFoodTapped(food), child: Container(width: 120, margin: const EdgeInsets.only(right: 10), child: Column(mainAxisSize: MainAxisSize.min, children: [ CircleAvatar(radius: 40, backgroundImage: (food.imageUrl != null && food.imageUrl!.isNotEmpty) ? NetworkImage(food.imageUrl!) : null, backgroundColor: Colors.grey.shade200, child: (food.imageUrl == null || food.imageUrl!.isEmpty) ? const Icon(Icons.ramen_dining, color: Colors.grey, size: 40) : null), const SizedBox(height: 8), Text(food.turkishName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))])));})); }
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
                      style: ElevatedButton.styleFrom(elevation: 1, backgroundColor: Colors.white, foregroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.deepOrange.shade100))),
                    )
                  : ElevatedButton(
                      onPressed: option.onPressed,
                      child: Text(option.text),
                      style: ElevatedButton.styleFrom(elevation: 1, backgroundColor: Colors.white, foregroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.deepOrange.shade100))),
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