// Lütfen bu dosyanın içeriğini projenizdeki lib/screens/discover_page.dart dosyasıyla tamamen değiştirin.

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math'; // <-- YORUM: Rastgele ipucu seçmek için eklendi.

import '../services/database_helper.dart';
import '../models/city_model.dart';
import '../models/food_details.dart';
import 'food_details_page.dart';
import 'passport_page.dart';
import 'venue_explorer_page.dart';
import '../widgets/typewriter_chat_message.dart';
import '../widgets/typing_indicator.dart';
import '../models/food_tip_model.dart';

// --- CHAT MESAJI MODELLERİ (Değişiklik yok) ---
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
  final IconData icon;
  final VoidCallback onPressed;
  ChatButtonOption(
      {required this.text, required this.icon, required this.onPressed});
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
  // --- STATE DEĞİŞKENLERİ (Değişiklik yok) ---
  final List<ChatMessage> _chatMessages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  City? _selectedCity;
  List<City> _citiesOnMap = [];
  bool _isTransitioning = false;
  bool _isMapLoading = true;
  String _mapStatusMessage = "Harita yükleniyor...";
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
    // Bu metot aynı kalıyor
    if (mounted) setState(() { _isMapLoading = true; });
    List<City> cities = await DatabaseHelper.instance.getAllCities();
    int retries = 5;
    while (cities.isEmpty && retries > 0 && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      cities = await DatabaseHelper.instance.getAllCities();
      retries--;
    }
    if (!mounted) return;
    if (cities.isEmpty) {
      setState(() {
        _citiesOnMap = [];
        _isMapLoading = false;
        _mapStatusMessage = "Şehirler yüklenemedi.\nLütfen internet bağlantınızı kontrol edip uygulamayı yeniden başlatın.";
      });
    } else {
      setState(() {
        _citiesOnMap = cities;
        _isMapLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onCitySelected(City city) {
    // Bu metot aynı kalıyor
    setState(() {
      _selectedCity = city;
      _isTransitioning = true;
    });
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted || !_isTransitioning) return;
      _startChatFlowForCity(city);
    });
  }

  

Future<void> _showRandomInsiderTip(City city) async {
  if (!mounted) return;

  // Artık FoodTip listesi döndüren yeni, güçlü metodumuzu çağırıyoruz.
  final foodTips = await DatabaseHelper.instance.getFoodTipsForCity(city.id);

  // Eğer geçerli bir ipucu bulunduysa
  if (foodTips.isNotEmpty) {
    // Rastgele bir FoodTip nesnesi seçiyoruz.
    final randomFoodTip = foodTips[Random().nextInt(foodTips.length)];

    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
       child: AlertDialog(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  
  // <-- 1. DEĞİŞİKLİK: BAŞLIK
  // Başlığı sabit metin yapıp ortalıyoruz.
  title: const Text(
    "Insider Tip!",
    textAlign: TextAlign.center,
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
  ),

  // <-- 2. DEĞİŞİKLİK: İÇERİK
  // İçeriği, alt başlığı ve asıl ipucunu içerecek bir Kolon (Column) yapıyoruz.
  content: Column(
    mainAxisSize: MainAxisSize.min, // Bu, Column'un gereksiz yer kaplamasını önler.
    children: [
      // Alt Başlık (Yemek İsmi)
      Text(
        randomFoodTip.foodDisplayName,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade700, // Yemeğin ismini vurgulamak için renk
        ),
      ),
      const SizedBox(height: 16), // Başlık ile ipucu arasına boşluk
      // Asıl İpucu Metni
      Text(
        randomFoodTip.tip,
        textAlign: TextAlign.center, // Metni ortalamak için
        style: const TextStyle(fontSize: 16, height: 1.4),
      ),
    ],
  ),
  
  // Eylemler (actions) kısmında değişiklik yok.
  actions: <Widget>[
    TextButton(
      child: const Text("Got it!", style: TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ),
  ],
),
        );
      },
    );
  }
}
  


  // <-- YORUM: BU METOT GÜNCELLENDİ
  Future<void> _startChatFlowForCity(City city) async {
    // Sohbet başlamadan hemen önce, ipucu gösterme fonksiyonunu çağırıyoruz.
    _showRandomInsiderTip(city);

    // Metodun geri kalanı eskisi gibi çalışmaya devam ediyor.
    setState(() {
      _isTransitioning = false;
      _chatMessages.clear();
      _chatMessages.add(TypingIndicatorMessage());
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _addBotMessage(
        "Welcome to ${city.cityName}! A city of rich history and incredible flavors. Ready to explore?",
        onFinished: () {
          _suggestFoodsForCity(city);
        }
      );
    });
  }

  Future<void> _suggestFoodsForCity(City city) async {
    // Bu metotta değişiklik yok.
    setState(() {
      _chatMessages.add(TypingIndicatorMessage());
    });
    _scrollToBottom();
    
    final foodNames = await DatabaseHelper.instance.getFoodNamesForCity(city.id);

    if (foodNames.isNotEmpty) {
      _addBotMessage("Here are some must-try dishes for you:", onFinished: () async {
        List<FoodDetails> foodDetailsList = [];
        for (var name in foodNames) {
          final details = await DatabaseHelper.instance.getFoodByName(name);
          if (details != null) {
            foodDetailsList.add(details);
          }
        }

        if (mounted) {
          setState(() {
            _chatMessages.add(FoodSuggestionMessage(foodDetailsList, _onFoodTapped));
          });
          _scrollToBottom();
          
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (!mounted) return;
            _offerVenueExplorer(city);
          });
        }
      });
    } else {
      _addBotMessage(
        "I know of ${city.cityName}, but I don't have specific food recommendations for it just yet.",
        onFinished: _askForMore,
      );
    }
  }

  void _offerVenueExplorer(City city) {
    // Bu metotta değişiklik yok.
    setState(() {
      _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage);

      _chatMessages.add(ButtonOptionsMessage(
        title: "Let's find a place to eat!",
        options: [
          ChatButtonOption(
            text: "Show me ${city.cityName}'s specialties",
            icon: Icons.restaurant_menu_outlined,
            onPressed: () => _handleVenueExplorerSelection(city, showAllFoods: false),
          ),
          ChatButtonOption(
            text: "Search for any Turkish dish",
            icon: Icons.search_outlined,
            onPressed: () => _handleVenueExplorerSelection(city, showAllFoods: true),
          ),
        ],
      ));
    });
    _scrollToBottom();
    _askForMore();
  }

  void _handleVenueExplorerSelection(City city, {required bool showAllFoods}) {
    // İsim karışıklığını gidermek için bu metodun adını değiştirdim,
    // çünkü eski kodunuzda iki tane aynı isimli metot vardı.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenueExplorerPage(
          city: city,
          showAllTurkishFoods: showAllFoods,
        ),
      ),
    ).then((_) {
      if (!mounted) return;

      setState(() {
          _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage && msg.title == "Let's find a place to eat!");
          _chatMessages.removeWhere((msg) => msg is ButtonOptionsMessage && msg.title == "What else can I help you with?");
      });

      _offerVenueExplorer(city);
    });
  }

  void _showCityContextOptions() {
    // Bu metotta değişiklik yok.
    setState(() {
      _chatMessages.add(ButtonOptionsMessage(
        title: "What else can I help you with?",
        options: [
          ChatButtonOption(text: "Food Culture", icon: Icons.auto_stories_outlined, onPressed: () => _handleContextQuery("culture", "Food Culture")),
          ChatButtonOption(text: "Local Drinks", icon: Icons.local_cafe_outlined, onPressed: () => _handleContextQuery("drinks", "Local Drinks")),
          ChatButtonOption(text: "Iconic Dish", icon: Icons.star_border_outlined, onPressed: () => _handleContextQuery("iconic_dish", "Iconic Dish")),
          ChatButtonOption(text: "After the Meal", icon: Icons.directions_walk_outlined, onPressed: () => _handleContextQuery("after_meal", "After the Meal")),
        ],
      ));
    });
    _scrollToBottom();
  }

  void _handleContextQuery(String queryType, String userText) {
    // Bu metotta değişiklik yok.
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
          _addBotMessage(responseText ?? "I'm still learning about the unique food culture of ${city.cityName}.", onFinished: _askForMore);
          break;
        case "drinks":
          responseText = city.localDrinksEn;
          _addBotMessage(responseText ?? "While I don't have specific drink recommendations, Ayran is a popular choice all over Turkey!", onFinished: _askForMore);
          break;
        case "after_meal":
          responseText = city.postMealSuggestionsEn;
          _addBotMessage(responseText ?? "A short walk and a Turkish coffee is always a great idea after a good meal!", onFinished: _askForMore);
          break;
        case "iconic_dish":
          _showIconicDish(city);
          break;
      }
    });
  }

  Future<void> _showIconicDish(City city) async {
    // Bu metotta değişiklik yok.
    if (city.iconicDishName == null || city.iconicDishName!.isEmpty) {
      _addBotMessage("It's hard to pick just one! Every dish in ${city.cityName} tells a part of its story.", onFinished: _askForMore);
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
          _askForMore();
        }
      );
    } else {
      _addBotMessage("I know the most iconic dish is '${city.iconicDishName}', but I couldn't find its details right now.", onFinished: _askForMore);
    }
  }

  void _askForMore() {
    // Bu metotta değişiklik yok.
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 500), (){
      if (!mounted) return;
      _showCityContextOptions();
    });
  }

  void _addBotMessage(String text, {required VoidCallback onFinished}) {
    // Bu metotta değişiklik yok.
    if (text.isEmpty) {
      onFinished.call();
      return;
    }
    setState(() {
      _chatMessages.removeWhere((msg) => msg is TypingIndicatorMessage);
      _chatMessages.add(StreamingTextMessage(text, onFinished: onFinished));
    });
  }

  void _onFoodTapped(FoodDetails food) => Navigator.push(context, MaterialPageRoute(builder: (context) => FoodDetailsPage(food: food)));

  void _scrollToBottom() {
    // Metodun adını değiştirdim, kodda zaten bu kullanılıyordu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _resetToMapView() {
    // Bu metotta değişiklik yok.
    setState(() {
      _selectedCity = null;
      _chatMessages.clear();
      _isLoading = false;
      _isTransitioning = false;
    });
  }

  // --- BUILD METOTLARI (Değişiklik yok) ---
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PassportPage()),
              );
            },
            tooltip: 'Lezzet Pasaportu',
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

  // BUNDAN SONRAKİ TÜM WIDGET BUILDER'LARDA HİÇBİR DEĞİŞİKLİK YOK.
  // ... (kalan tüm kodlar aynı)
  Widget _buildMapView() { if (_isMapLoading) { return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(_mapStatusMessage)])); } if (_citiesOnMap.isEmpty) { return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(_mapStatusMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)))); } const double imageAspectRatio = 1920 / 924; final Map<String, Offset> cityCoordinates = { 'Ankara': const Offset(0.34, 0.45), 'İzmir': const Offset(0.05, 0.63), 'Gaziantep': const Offset(0.60, 0.86), 'Trabzon': const Offset(0.72, 0.27), 'Bursa': const Offset(0.17, 0.35), 'Hatay': const Offset(0.55, 0.95), 'Mersin': const Offset(0.41, 0.94), 'Erzurum': const Offset(0.82, 0.38), 'Kayseri': const Offset(0.52, 0.59), 'Şanlıurfa': const Offset(0.69, 0.83) }; return Column(children: [ Expanded(child: LayoutBuilder(builder: (context, constraints) { final containerWidth = constraints.maxWidth; final containerHeight = constraints.maxHeight; final containerAspectRatio = containerWidth / containerHeight; double renderedImageWidth; double renderedImageHeight; if (containerAspectRatio > imageAspectRatio) { renderedImageHeight = containerHeight; renderedImageWidth = renderedImageHeight * imageAspectRatio; } else { renderedImageWidth = containerWidth; renderedImageHeight = renderedImageWidth / imageAspectRatio; } const double referenceWidth = 800.0; final double scaleFactor = (renderedImageWidth / referenceWidth).clamp(0.7, 1.2); return Center(child: SizedBox(width: renderedImageWidth, height: renderedImageHeight, child: Stack(children: [ Image.asset('assets/images/turkey_map.png', fit: BoxFit.fill), ..._citiesOnMap.where((city) => cityCoordinates.containsKey(city.cityName)).map((city) { final isTuningThisCity = _isFineTuningMode && _selectedCityForTuning == city.cityName; final coords = isTuningThisCity ? Offset(_tuningX, _tuningY) : cityCoordinates[city.cityName]!; final leftPosition = renderedImageWidth * coords.dx; final topPosition = renderedImageHeight * coords.dy; return Positioned(left: leftPosition, top: topPosition, child: Transform.translate(offset: Offset(-25 * scaleFactor, -55 * scaleFactor), child: GestureDetector(onTap: () { if (_isFineTuningMode) { setState(() { _selectedCityForTuning = city.cityName; _tuningX = cityCoordinates[city.cityName]!.dx; _tuningY = cityCoordinates[city.cityName]!.dy; }); } else { _onCitySelected(city); } }, child: CityPin(city: city, scaleFactor: scaleFactor)))); }).toList()]))); })), if (_isFineTuningMode) Container(padding: const EdgeInsets.all(12), color: Colors.grey.shade200, child: Column(children: [ Text('İnce Ayar Modu: ${_selectedCityForTuning ?? "Konumu ayarlamak için bir şehir seçin."}', style: const TextStyle(fontWeight: FontWeight.bold)), if (_selectedCityForTuning != null) ...[ Row(children: [ const Text('X: '), Expanded(child: Slider(value: _tuningX, min: 0.0, max: 1.0, divisions: 200, label: _tuningX.toStringAsFixed(2), onChanged: (value) => setState(() => _tuningX = value))) ]), Row(children: [ const Text('Y: '), Expanded(child: Slider(value: _tuningY, min: 0.0, max: 1.0, divisions: 200, label: _tuningY.toStringAsFixed(2), onChanged: (value) => setState(() => _tuningY = value))) ]), const Text("Koddaki 'cityCoordinates' map'ine yapıştırmak için:", style: TextStyle(fontSize: 10, color: Colors.grey)), SelectableText("'$_selectedCityForTuning': const Offset(${_tuningX.toStringAsFixed(2)}, ${_tuningY.toStringAsFixed(2)}),", style: const TextStyle(fontFamily: 'monospace', backgroundColor: Colors.white, fontWeight: FontWeight.bold)) ] ])) ]); }
  Widget _buildTransitionOverlay() { return AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: _isTransitioning ? 1.0 : 0.0, child: IgnorePointer(ignoring: !_isTransitioning, child: Stack(children: [ BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: Container(color: Colors.black.withOpacity(0.4))), if (_selectedCity != null) _buildJourneyStartMessage(_selectedCity!)]))); }
  Widget _buildJourneyStartMessage(City city) { return Center(child: Container(padding: const EdgeInsets.all(24), margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 20), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.8) ]), borderRadius: BorderRadius.circular(20), boxShadow: [ BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, spreadRadius: 5) ]), child: Column(mainAxisSize: MainAxisSize.min, children: [ TweenAnimationBuilder(duration: const Duration(milliseconds: 1200), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Transform.scale(scale: 0.8 + (value * 0.2), child: Transform.rotate(angle: value * 0.1, child: Hero(tag: 'city-pin-${city.id}', child: Material(type: MaterialType.transparency, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ Colors.blue.shade400, Colors.blue.shade600 ]), boxShadow: [ BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, spreadRadius: 2) ]), child: const Icon(Icons.explore, size: 40, color: Colors.white)))))); }), const SizedBox(height: 20), TweenAnimationBuilder(duration: const Duration(milliseconds: 800), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: Text("Exploring ${city.cityName}", style: TextStyle(fontSize: 24, color: Colors.blue.shade800, fontWeight: FontWeight.bold, letterSpacing: 1.2), textAlign: TextAlign.center))); }), const SizedBox(height: 12), TweenAnimationBuilder(duration: const Duration(milliseconds: 1000), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 15 * (1 - value)), child: Text("Discovering authentic flavors and culinary treasures", style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500), textAlign: TextAlign.center))); }), const SizedBox(height: 24), SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600), backgroundColor: Colors.blue.shade100)), const SizedBox(height: 16), TweenAnimationBuilder(duration: const Duration(milliseconds: 1500), tween: Tween<double>(begin: 0, end: 1), builder: (context, double value, child) { return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (index) { final delay = index * 0.3; final animValue = ((value - delay).clamp(0.0, 1.0)); return Container(margin: const EdgeInsets.symmetric(horizontal: 4), child: AnimatedContainer(duration: Duration(milliseconds: 300 + (index * 100)), width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.shade400.withOpacity(animValue)))); })); })]))); }
  Widget _buildChatView() { return Column(children: [ Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(16.0), itemCount: _chatMessages.length, itemBuilder: (context, index) { final message = _chatMessages[index]; if (message is UserTextMessage) { return _buildUserMessage(message); } if (message is TypingIndicatorMessage) { return _buildBotMessageWrapper(const AnimatedTypingIndicator()); } if (message is StreamingTextMessage) { return _buildBotMessageWrapper(TypewriterChatMessage(text: message.text, onCharacterTyped: _scrollToBottom, onFinishedTyping: message.onFinished)); } if (message is FoodSuggestionMessage) { return _buildFoodSuggestions(message.foods, message.onFoodTapped); } if (message is ButtonOptionsMessage) { return _buildButtonOptions(message); } return const SizedBox.shrink(); })), if (_isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: LinearProgressIndicator())]); }
  Widget _buildUserMessage(UserTextMessage message) { return Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), margin: const EdgeInsets.symmetric(vertical: 4).copyWith(left: 80), decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(20).copyWith(topRight: const Radius.circular(4))), child: Text(message.text, style: const TextStyle(fontSize: 16, color: Colors.white)))); }
  Widget _buildBotMessageWrapper(Widget child) { return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.explore_outlined, color: Colors.white, size: 20)), const SizedBox(width: 8), Expanded(child: child)])); }
  Widget _buildFoodSuggestions(List<FoodDetails> foods, Function(FoodDetails) onFoodTapped) { return Container(height: 140, alignment: Alignment.centerLeft, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: foods.length, itemBuilder: (context, index) { final food = foods[index]; return GestureDetector(onTap: () => onFoodTapped(food), child: Container(width: 120, margin: const EdgeInsets.only(right: 10), child: Column(mainAxisSize: MainAxisSize.min, children: [ CircleAvatar(radius: 40, backgroundImage: (food.imageUrl != null && food.imageUrl!.isNotEmpty) ? NetworkImage(food.imageUrl!) : null, backgroundColor: Colors.grey.shade200, child: (food.imageUrl == null || food.imageUrl!.isEmpty) ? const Icon(Icons.ramen_dining, color: Colors.grey, size: 40) : null), const SizedBox(height: 8), Text(food.turkishName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))])));})); }
  Widget _buildButtonOptions(ButtonOptionsMessage message) { return Container(margin: const EdgeInsets.symmetric(vertical: 8.0), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ if (message.title != null) Padding(padding: const EdgeInsets.only(left: 4.0, bottom: 8.0), child: Text(message.title!, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))), Wrap(spacing: 8.0, runSpacing: 8.0, children: message.options.map((option) { return ElevatedButton.icon(icon: Icon(option.icon, size: 18), label: Text(option.text), onPressed: option.onPressed, style: ElevatedButton.styleFrom(elevation: 1, backgroundColor: Colors.white, foregroundColor: Colors.blue.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.blue.shade100)))); }).toList())])); }
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