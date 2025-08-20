import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart'; // <--- YENİ
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import '../models/food_details.dart';
import '../services/database_helper.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/typewriter_chat_message.dart';
import 'show_to_waiter_page.dart';

import '../models/city_model.dart';
import '../models/city_food_model.dart';

import '../models/route_model.dart';
import '../models/route_stop_model.dart';
import '../services/sync_service.dart'; 

final supabase = Supabase.instance.client;

// --- CHAT MESAJ MODELLERİ ---
abstract class ChatMessage {
  final bool isFromUser;
  ChatMessage(this.isFromUser);
}
class UserTextMessage extends ChatMessage {
  final String text;
  UserTextMessage(this.text) : super(true);
}
class StreamingTextMessage extends ChatMessage {
  final String text;
  final VoidCallback onFinished;
  StreamingTextMessage(this.text, {required this.onFinished}) : super(false);
}
class ButtonOptionsMessage extends ChatMessage {
  final List<ChatButtonOption> options;
  ButtonOptionsMessage(this.options) : super(false);
}
class ChatButtonOption {
  final String text;
  final VoidCallback onPressed;
  ChatButtonOption({required this.text, required this.onPressed});
}
class TypingIndicatorMessage extends ChatMessage {
  TypingIndicatorMessage() : super(false);
}
// <--- YENİ MESAJ TİPİ ---
class CustomWidgetMessage extends ChatMessage {
  final Widget child;
  CustomWidgetMessage(this.child) : super(false);
}
// ---

class RecognitionPage extends StatefulWidget {
  const RecognitionPage({super.key});

  @override
  State<RecognitionPage> createState() => _RecognitionPageState();
}

class _RecognitionPageState extends State<RecognitionPage> {
  // --- MEVCUT STATE DEĞİŞKENLERİ ---
  File? _image;
  bool _loading = false;
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _modelLoaded = false;
  FoodDetails? _currentFood;
  final List<ChatMessage> _chatMessages = [];
  bool _isChatActive = false;
  final ScrollController _scrollController = ScrollController();
  bool _isBotTyping = false;
  bool _isSyncing = true;
  String _syncStatusMessage = "Envoy is getting ready...";

  // --- YENİ STATE DEĞİŞKENLERİ (Ses çalmak için) ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;
  String _currentlyPlayingFood = '';

  @override
  void initState() {
    super.initState();
    _initialize();
    
    // Ses oynatıcının durumu değiştiğinde dinle
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _interpreter?.close();
    _scrollController.dispose();
    _audioPlayer.dispose(); // Ses oynatıcıyı temizle
    super.dispose();
  }
  
  // --- YÖNETİM FONKSİYONLARI (DEĞİŞİKLİK YOK) ---
  Future<void> _initialize() async {
    await Future.wait([_loadModel(), _syncDataWithSupabase()]);
  }
// recognition_page.dart dosyasındaki _RecognitionPageState class'ı içinde

Future<void> _syncDataWithSupabase() async {
  SyncService.isSyncCompleted.value = false;
  setState(() { _syncStatusMessage = "Connecting to knowledge base..."; });
  try {
    // 1. YEMEKLERİ SENKRONİZE ET
    final response = await supabase.from('foods').select();
    final foodList = (response as List).map((item) => FoodDetails.fromJson(item)).toList();
    if (foodList.isNotEmpty) {
      setState(() { _syncStatusMessage = "Syncing local gastronomy atlas..."; });
      await DatabaseHelper.instance.batchUpsert(foodList);
    }
    if (kDebugMode) print("✅ Yemek senkronizasyonu tamamlandı: ${foodList.length} yemek.");

    // 2. ŞEHİRLERİ SENKRONİZE ET
    setState(() { _syncStatusMessage = "Mapping cities..."; });
    final citiesResponse = await supabase.from('cities').select();
    final cityList = (citiesResponse as List).map((e) => City.fromMap(e)).toList();
    await DatabaseHelper.instance.batchUpsertCities(cityList);
    if (kDebugMode) print("✅ Şehir senkronizasyonu tamamlandı: ${cityList.length} şehir.");

    // 3. ŞEHİR-YEMEK İLİŞKİLERİNİ SENKRONİZE ET
    setState(() { _syncStatusMessage = "Building flavor connections..."; });
    final cityFoodsResponse = await supabase.from('city_foods').select();
    final cityFoodList = (cityFoodsResponse as List).map((e) => CityFood.fromMap(e)).toList();
    await DatabaseHelper.instance.batchUpsertCityFoods(cityFoodList);
    if (kDebugMode) print("✅ Şehir-Yemek ilişkileri senkronizasyonu tamamlandı: ${cityFoodList.length} ilişki.");
      
    // 4. GURME ROTALARINI SENKRONİZE ET
    setState(() { _syncStatusMessage = "Curating gourmet routes..."; });
    final routesResponse = await supabase.from('routes').select();
    final routeList = (routesResponse as List).map((e) => RouteModel.fromMap(e)).toList();
    await DatabaseHelper.instance.batchUpsertRoutes(routeList);
    if (kDebugMode) print("✅ Rota senkronizasyonu tamamlandı: ${routeList.length} rota.");

    // ==========================================================
    // --- 5. ROTA DURAKLARINI SENKRONİZE ET (DEBUG BÖLÜMÜ) ---
    // ==========================================================
    setState(() { _syncStatusMessage = "Pinpointing delicious stops..."; });
    final stopsResponse = await supabase.from('route_stops').select();
    
    // --- 1. İŞARET FİŞEĞİ: Supabase'den veri geldi mi?
    print("DEBUG: Supabase'den ${stopsResponse.length} adet durak çekildi.");

    // Veri varsa, içeriğini görelim
    if (stopsResponse.isNotEmpty) {
      print("DEBUG: Çekilen ilk durak verisi (ham): ${stopsResponse.first}");
    }

    // Veriyi Dart modeline çeviriyoruz
    final stopList = (stopsResponse as List).map((e) => RouteStop.fromMap(e)).toList();

    // --- 2. İŞARET FİŞEĞİ: Model doğru oluştu mu?
    if (stopList.isNotEmpty) {
      print("DEBUG: İlk durak başarıyla modele çevrildi: Adı='${stopList.first.venueName}', Not='${stopList.first.stopNotesEn}'");
    }
    
    // Modeli yerel veritabanına yazıyoruz
    await DatabaseHelper.instance.batchUpsertRouteStops(stopList);
    
    // --- 3. İŞARET FİŞEĞİ: Yazma işlemi başarılı oldu mu?
    print("✅ DEBUG: ${stopList.length} adet durak yerel veritabanına yazma komutu başarıyla gönderildi.");
    // ==========================================================

  } catch (e) {
    if (kDebugMode) print("❗️❗️❗️ DEBUG: SENKRONİZASYON SIRASINDA KRİTİK HATA: $e");
  } finally {
    if (mounted) { 
      setState(() { _isSyncing = false; });
      SyncService.isSyncCompleted.value = true;
    }
  }
}
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').map((label) => label.trim()).where((label) => label.isNotEmpty).toList();
      if (mounted) setState(() => _modelLoaded = true);
    } catch (e) {
      if (kDebugMode) print('❗️ MODEL YÜKLENİRKEN HATA OLUŞTU: $e');
    }
  }
  Future<FoodDetails> _fetchFoodDetails(String foodName) async {
    final food = await DatabaseHelper.instance.getFoodByName(foodName);
    if (food == null) {
      throw Exception("Food '$foodName' not found in local database.");
    }
    return food;
  }
  void _resetState() => setState(() {
    _image = null;
    _loading = false;
    _isChatActive = false;
    _chatMessages.clear();
    _currentFood = null;
    _isBotTyping = false;
    _audioPlayer.stop();
  });

  // --- GÖRSEL TANIMA VE CHATBOT AKIŞI (DEĞİŞİKLİK YOK) ---
  Future<void> _pickImage() async {
    _resetState();
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() { _image = File(pickedFile.path); _loading = true; });
      await _runInference(File(pickedFile.path));
    }
  }
  Future<void> _runInference(File imageFile) async {
    if (!_modelLoaded || _interpreter == null || _labels == null) return;
    final imageData = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return;
    img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);
    var imageBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    var buffer = Float32List(1 * 224 * 224 * 3);
    for (var i = 0, bufferIndex = 0; i < imageBytes.length; i++) {
      buffer[bufferIndex++] = imageBytes[i].toDouble();
    }
    var input = buffer.reshape([1, 224, 224, 3]);
    var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);
    _interpreter!.run(input, output);
    double highestScore = 0.0;
    String predictedLabel = '';
    for (int i = 0; i < output[0].length; i++) {
      if (output[0][i] > highestScore) {
        highestScore = output[0][i];
        predictedLabel = _labels![i];
      }
    }
    if (predictedLabel.isNotEmpty) {
      await _startChatbotFlow(predictedLabel);
    } else {
      _addBotMessage("Sorry, I couldn't recognize this dish. Please try another photo.");
    }
  }
  Future<void> _startChatbotFlow(String foodName) async {
    try {
      final foodDetails = await _fetchFoodDetails(foodName);
      setState(() { _currentFood = foodDetails; _isChatActive = true; _loading = false; });
      _addBotMessage("It looks like you're having ${_currentFood!.englishName}! What would you like to know?", onFinished: _showMainOptions);
    } catch (e) {
      if (kDebugMode) print("❗️_startChatbotFlow HATA: $e");
      setState(() { _loading = false; });
      _addBotMessage("I recognized it as '$foodName', but I couldn't find its details. Please check your internet connection and try again.");
    }
  }
  void _showMainOptions() {
     setState(() {
       _isBotTyping = false;
       _chatMessages.add(ButtonOptionsMessage([
           ChatButtonOption(text: '🛎️ Show to Waiter', onPressed: () => _handleOptionSelection(_navigateToWaiterCard, 'Show this to the waiter')),
           ChatButtonOption(text: '📖 Story & Origin', onPressed: () => _handleOptionSelection(_showStory, 'Tell me its story')),
           ChatButtonOption(text: '🥩 Ingredients & Allergens', onPressed: () => _handleOptionSelection(_showIngredients, 'What are the ingredients & allergens?')),
           ChatButtonOption(text: '🗣️ How to Pronounce?', onPressed: () => _handleOptionSelection(_showPronunciation, 'How do I pronounce it?')),
           ChatButtonOption(text: '🍷 What goes with it?', onPressed: () => _handleOptionSelection(_showPairing, 'What goes well with it?')),
       ]));
     });
     _scrollToBottom();
  }
  void _handleOptionSelection(Function actionFunction, String userText) {
    setState(() { _chatMessages.add(UserTextMessage(userText)); });
    _scrollToBottom();
    if (actionFunction != _navigateToWaiterCard) {
      setState(() { _isBotTyping = true; _chatMessages.add(TypingIndicatorMessage()); });
      _scrollToBottom();
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() { _chatMessages.removeWhere((msg) => msg is TypingIndicatorMessage); });
        actionFunction();
      });
    } else {
      actionFunction();
    }
  }
  void _askForMoreInfo() {
    _addBotMessage("What else would you like to know?", onFinished: _showMainOptions);
  }
  void _addBotMessage(String text, {VoidCallback? onFinished}) {
    if (text.isEmpty) text = "Sorry, I don't have this information yet.";
    setState(() {
      _isBotTyping = true;
      _chatMessages.add(StreamingTextMessage(text, onFinished: onFinished ?? () => setState(() => _isBotTyping = false)));
    });
  }

  // --- CHATBOT BİLGİ FONKSİYONLARI ---
  void _showStory() => _addBotMessage(_currentFood?.storyEn ?? '', onFinished: _askForMoreInfo);
  void _showIngredients() {
    if (_currentFood == null) return;
    final ingredients = "📋 Ingredients:\n${_currentFood!.ingredientsEn ?? 'Not available.'}";
    final spiceLevel = "\n\n🔥 Spice Level:\n${_generateSpiceLevelText(_currentFood!.spiceLevel)}";
    final allergens = "\n\n⚠️ Allergen Info:\n${_generateAllergenText(_currentFood!)}";
    final vegetarianStatus = _currentFood!.isVegetarian ? "\n\n🌱 This dish is vegetarian." : "";
    final fullText = ingredients + spiceLevel + allergens + vegetarianStatus;
    _addBotMessage(fullText.trim(), onFinished: _askForMoreInfo);
  }
  void _showPairing() => _addBotMessage(_currentFood?.pairingEn ?? '', onFinished: _askForMoreInfo);
  void _navigateToWaiterCard() {
    if (_currentFood == null) return;
    setState(() { _chatMessages.removeWhere((msg) => msg is TypingIndicatorMessage); _isBotTyping = false; });
    Navigator.push(context, MaterialPageRoute(builder: (context) => ShowToWaiterPage(food: _currentFood!))).then((_) { _askForMoreInfo(); });
  }

  // <--- GÜNCELLENEN FONKSİYON: Telaffuz ve Ses Çalma ---
  void _showPronunciation() {
    if (_currentFood == null) return;
    final foodName = _currentFood!.name;
    final pronunciationText = _currentFood!.pronunciationText ?? 'No pronunciation guide available.';

    final pronunciationMessage = Builder(builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateInBubble) {
          final bool isThisPlaying = _isAudioPlaying && _currentlyPlayingFood == foodName;

          // Ses oynatıcının durumu değiştiğinde bu bubble'ı güncellemek için dinleyici
          final listener = _audioPlayer.onPlayerStateChanged.listen((state) {
            setStateInBubble(() {});
          });

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20).copyWith(topLeft: const Radius.circular(4)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isThisPlaying ? Icons.stop_circle_outlined : Icons.play_circle_filled_outlined,
                    color: Colors.deepOrange.shade600,
                    size: 36,
                  ),
                  onPressed: () async {
                    if (isThisPlaying) {
                      await _audioPlayer.stop();
                    } else {
                      try {
                        await _audioPlayer.stop();
                        setState(() { _currentlyPlayingFood = foodName; });
                        await _audioPlayer.play(AssetSource('audio/$foodName.mp3'));
                      } catch (e) {
                        if (kDebugMode) print("❗️ Ses dosyası çalınırken HATA: $e");
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sorry, audio for $foodName is not available.")));
                      }
                    }
                    setStateInBubble(() {});
                  },
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(pronunciationText, style: const TextStyle(fontSize: 16, color: Colors.black87))),
              ],
            ),
          );
        },
      );
    });

    setState(() {
      _isBotTyping = false;
      _chatMessages.add(CustomWidgetMessage(pronunciationMessage));
    });
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 500), _askForMoreInfo);
  }

  // --- YARDIMCI FONKSİYONLAR (DEĞİŞİKLİK YOK) ---
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        if (maxScroll - currentScroll < 50.0) {
          _scrollController.animateTo(maxScroll, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      }
    });
  }
  String _generateSpiceLevelText(int? level) {
    if (level == null) return "Unknown";
    switch (level) {
      case 1: return "🌶️ (Not Spicy)"; case 2: return "🌶️🌶️ (Mild)"; case 3: return "🌶️🌶️🌶️ (Medium)"; case 4: return "🌶️🌶️🌶️🌶️ (Spicy)"; case 5: return "🌶️🌶️🌶️🌶️🌶️ (Very Spicy)";
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
  
  // --- BUILD METODU VE WIDGET'LAR ---
  @override
  Widget build(BuildContext context) {
    if (!_modelLoaded || _isSyncing) {
      return Scaffold(
        appBar: AppBar(title: const Text('DishAI - Gastronomy Envoy'), backgroundColor: Colors.deepOrange.shade300),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 20), Text(_syncStatusMessage, style: const TextStyle(fontSize: 16, color: Colors.grey))])),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('DishAI - Gastronomy Envoy'), backgroundColor: Colors.deepOrange.shade300, actions: [if (_isChatActive) IconButton(icon: const Icon(Icons.refresh), onPressed: _resetState, tooltip: 'Start Over')]),
      body: Column(children: [
        if (_image != null && !_isChatActive) Padding(padding: const EdgeInsets.all(16.0), child: ClipRRect(borderRadius: BorderRadius.circular(12.0), child: Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover))),
        if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
        if (!_isChatActive && !_loading && _image == null) const Expanded(child: Center(child: Text('Let\'s identify your dish!\nClick the camera button below.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)))),
        if (_isChatActive) Expanded(child: ListView.builder(physics: const AlwaysScrollableScrollPhysics(), controller: _scrollController, padding: const EdgeInsets.all(16.0), itemCount: _chatMessages.length, itemBuilder: (context, index) {
          final message = _chatMessages[index];
          return message.isFromUser ? _buildUserMessage(message as UserTextMessage) : _buildBotMessage(message);
        })),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: (_modelLoaded && !_loading && !_isSyncing) ? _pickImage : null, tooltip: 'Select Photo', backgroundColor: (_modelLoaded && !_loading && !_isSyncing) ? Colors.deepOrange : Colors.grey, child: const Icon(Icons.camera_alt)),
    );
  }

  Widget _buildUserMessage(UserTextMessage message) {
    return Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), margin: const EdgeInsets.symmetric(vertical: 4).copyWith(left: 60), decoration: BoxDecoration(color: Colors.deepOrange.shade400, borderRadius: BorderRadius.circular(20)), child: Text(message.text, style: const TextStyle(fontSize: 16, color: Colors.white))));
  }
  
  // <--- GÜNCELLENEN WIDGET: CustomWidgetMessage'ı tanır ---
  Widget _buildBotMessage(ChatMessage message) {
    Widget messageContent;
    if (message is StreamingTextMessage) {
      messageContent = TypewriterChatMessage(text: message.text, onCharacterTyped: _scrollToBottom, onFinishedTyping: message.onFinished);
    } else if (message is ButtonOptionsMessage) {
      messageContent = _buildButtonOptions(message);
    } else if (message is TypingIndicatorMessage) {
      messageContent = const AnimatedTypingIndicator();
    } else if (message is CustomWidgetMessage) {
      messageContent = message.child; // Özel widget'ı direkt kullan
    } else {
      messageContent = const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.ramen_dining_outlined, color: Colors.white, size: 20)), const SizedBox(width: 8), Expanded(child: messageContent)]));
  }

  Widget _buildButtonOptions(ButtonOptionsMessage message) {
    return AbsorbPointer(absorbing: _isBotTyping, child: Opacity(opacity: _isBotTyping ? 0.5 : 1.0, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: message.options.map((option) => Container(width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 4.0), child: OutlinedButton(onPressed: () { setState(() { _chatMessages.remove(message); }); option.onPressed(); }, style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.deepOrange.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 12)), child: Text(option.text, style: TextStyle(color: Colors.deepOrange.shade800, fontWeight: FontWeight.bold))))).toList())));
  }
}