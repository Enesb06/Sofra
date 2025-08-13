import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';

// Projenizin yapısına uygun doğru import yolları
import '../services/database_helper.dart'; 
import '../models/city_model.dart';
import '../models/food_details.dart';
import 'food_details_page.dart';

// --- CHAT MESAJI MODELLERİ ---
abstract class ChatMessage { final bool isFromUser; ChatMessage(this.isFromUser); }
class BotTextMessage extends ChatMessage { final String text; BotTextMessage(this.text) : super(false); }
class UserTextMessage extends ChatMessage { final String text; UserTextMessage(this.text) : super(true); }
class FoodSuggestionMessage extends ChatMessage { final List<FoodDetails> foods; final Function(FoodDetails) onFoodTapped; FoodSuggestionMessage(this.foods, this.onFoodTapped) : super(false); }

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addBotMessage("Ready for a culinary adventure in Türkiye! 🇹🇷\n\nWhich city are you planning to visit?");
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) { setState(() { _isLoading = false; _chatMessages.add(BotTextMessage(text)); }); _scrollToBottom(); }
  void _addUserMessage(String text) { setState(() { _chatMessages.add(UserTextMessage(text)); _isLoading = true; }); _scrollToBottom(); }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    final userInput = text.trim();
    _textController.clear();
    _addUserMessage(userInput);
    await Future.delayed(const Duration(milliseconds: 500));
    await _findCityAndSuggestFoods(userInput);
  }

  Future<void> _findCityAndSuggestFoods(String userInput) async {
    final normalizedInput = _normalizeString(userInput);
    final allCities = await DatabaseHelper.instance.getAllCities();

    if (allCities.isEmpty) { _addBotMessage("Sorry, I can't access the city list right now. Please check your internet connection and restart the app."); return; }
    
    final cityNames = allCities.map((c) => c.normalizedCityName).toList();
    final bestMatchResult = StringSimilarity.findBestMatch(normalizedInput, cityNames);

    if (bestMatchResult.bestMatch.rating != null && bestMatchResult.bestMatch.rating! > 0.6) {
      final matchedCityName = bestMatchResult.bestMatch.target!;
      final bestMatch = allCities.firstWhere((c) => c.normalizedCityName == matchedCityName);
      
      _addBotMessage("Ah, ${bestMatch.cityName}! An excellent choice. Here are some must-try dishes for you:");
      
      final foodNames = await DatabaseHelper.instance.getFoodNamesForCity(bestMatch.id);
      if (foodNames.isNotEmpty) {
        List<FoodDetails> foodDetailsList = [];
        for(var name in foodNames) {
          final details = await DatabaseHelper.instance.getFoodByName(name);
          if (details != null) { foodDetailsList.add(details); }
        }
        setState(() { _chatMessages.add(FoodSuggestionMessage(foodDetailsList, _onFoodTapped)); });
        _scrollToBottom();
      } else {
        _addBotMessage("I know of ${bestMatch.cityName}, but I don't have specific food recommendations for it just yet.");
      }
    } else {
      _addBotMessage("I'm not familiar with a city called '$userInput'. Could you please check the spelling?");
    }
    setState(() { _isLoading = false; });
  }

  String _normalizeString(String text) { return text.toLowerCase().replaceAll('ı', 'i').replaceAll('ğ', 'g').replaceAll('ü', 'u').replaceAll('ş', 's').replaceAll('ö', 'o').replaceAll('ç', 'c').trim(); }
  void _onFoodTapped(FoodDetails food) {
  // Artık bir mesaj göndermiyoruz, doğrudan detay sayfasına uçuruyoruz!
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FoodDetailsPage(food: food),
    ),
  );
}
  void _scrollToBottom() { WidgetsBinding.instance.addPostFrameCallback((_) { if (_scrollController.hasClients) { _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); } }); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DishAI - Flavor Explorer'), backgroundColor: Colors.blue.shade300),
      body: Column(
        children: [
          Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(16.0), itemCount: _chatMessages.length, itemBuilder: (context, index) {
            final message = _chatMessages[index];
            if (message is UserTextMessage) return _buildUserMessage(message.text);
            if (message is BotTextMessage) return _buildBotMessage(message.text);
            if (message is FoodSuggestionMessage) return _buildFoodSuggestions(message.foods, message.onFoodTapped);
            return const SizedBox.shrink();
          })),
          if (_isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: LinearProgressIndicator()),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildTextComposer() { return Container(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black12, offset: Offset(0, -1))]), child: Row(children: [ Expanded(child: TextField(controller: _textController, onSubmitted: _isLoading ? null : _handleSubmitted, decoration: const InputDecoration.collapsed(hintText: 'Enter a city name...'))), IconButton(icon: const Icon(Icons.send), color: Colors.blue.shade600, onPressed: _isLoading ? null : () => _handleSubmitted(_textController.text)) ])); }
  Widget _buildBotMessage(String text) { return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.explore_outlined, color: Colors.white, size: 20)), const SizedBox(width: 8), Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20).copyWith(topLeft: const Radius.circular(4))), child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)))) ])); }
  Widget _buildUserMessage(String text) { return Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), margin: const EdgeInsets.symmetric(vertical: 4).copyWith(left: 60), decoration: BoxDecoration(color: Colors.blue.shade400, borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)))); }
  Widget _buildFoodSuggestions(List<FoodDetails> foods, Function(FoodDetails) onFoodTapped) { return Container(height: 140, alignment: Alignment.centerLeft, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: foods.length, itemBuilder: (context, index) { final food = foods[index]; return GestureDetector(onTap: () => onFoodTapped(food), child: Container(width: 120, margin: const EdgeInsets.only(right: 10), child: Column(mainAxisSize: MainAxisSize.min, children: [ CircleAvatar(radius: 40, backgroundImage: (food.imageUrl != null && food.imageUrl!.isNotEmpty) ? NetworkImage(food.imageUrl!) : null, backgroundColor: Colors.grey.shade200, child: (food.imageUrl == null || food.imageUrl!.isEmpty) ? const Icon(Icons.ramen_dining, color: Colors.grey, size: 40) : null), const SizedBox(height: 8), Text(food.turkishName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))])));}));}
}