import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import '../models/food_details.dart';
import '../services/database_helper.dart'; // Yolu kontrol edin: lib/services/database_helper.dart
import '../widgets/typing_indicator.dart';
import '../widgets/typewriter_chat_message.dart';
import 'show_to_waiter_page.dart';

final supabase = Supabase.instance.client;

// --- CHAT MESAJ MODELLERİ (DEĞİŞİKLİK YOK) ---
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
// ---

class RecognitionPage extends StatefulWidget {
  const RecognitionPage({super.key});

  @override
  State<RecognitionPage> createState() => _RecognitionPageState();
}

class _RecognitionPageState extends State<RecognitionPage> {
  // --- MEVCUT STATE DEĞİŞKENLERİ (DEĞİŞİKLİK YOK) ---
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
  
  // --- YENİ STATE DEĞİŞKENLERİ (Çevrimdışı yetenek için) ---
  bool _isSyncing = true; // Uygulama açılışında senkronizasyon başlasın
  String _syncStatusMessage = "Envoy is getting ready...";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // --- YENİ FONKSİYON: Başlatma işlemlerini yönetir ---
  Future<void> _initialize() async {
    // Model yükleme ve veri senkronizasyonunu aynı anda başlat
    await Future.wait([
      _loadModel(),
      _syncDataWithSupabase()
    ]);
  }

  // --- YENİ FONKSİYON: Supabase verilerini yerel DB'ye senkronize eder ---
  Future<void> _syncDataWithSupabase() async {
    setState(() {
      _syncStatusMessage = "Connecting to knowledge base...";
    });
    try {
      if (kDebugMode) print("Supabase'den veri çekiliyor...");
      final response = await supabase.from('foods').select();
      final foodList = (response as List)
          .map((item) => FoodDetails.fromJson(item))
          .toList();

      if (foodList.isNotEmpty) {
        setState(() {
          _syncStatusMessage = "Syncing local gastronomy atlas...";
        });
        await DatabaseHelper.instance.batchUpsert(foodList);
      }
      if (kDebugMode) print("✅ Senkronizasyon tamamlandı. ${foodList.length} yemek yerel veritabanında.");

    } catch (e) {
      if (kDebugMode) print("❗️ Senkronizasyon sırasında HATA: $e");
      // Hata olsa bile devam et, belki yerelde eski veri vardır.
    } finally {
      // İşlem bitince senkronizasyon modunu kapat
      if (mounted) {
        setState(() { _isSyncing = false; });
      }
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    _scrollController.dispose();
    super.dispose();
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

  // --- GÜNCELLENEN FONKSİYON: Artık yerel veritabanını kullanıyor ---
  Future<FoodDetails> _fetchFoodDetails(String foodName) async {
    final food = await DatabaseHelper.instance.getFoodByName(foodName);
    if (food == null) {
      // Eğer yemek yerel veritabanında bulunamazsa bu, senkronizasyonun başarısız olduğu anlamına gelir.
      // Yine de kullanıcıya bir cevap vermek için hata fırlatmak yerine özel bir mesaj gösterelim.
      throw Exception("Food '$foodName' not found in local database. Please ensure you have an internet connection on first launch to sync data.");
    }
    return food;
  }
  
  // --- AŞAĞIDAKİ TÜM FONKSİYONLARDA MANTIK OLARAK HİÇBİR DEĞİŞİKLİK YOKTUR ---
  
  void _resetState() => setState(() {
    _image = null;
    _loading = false;
    _isChatActive = false;
    _chatMessages.clear();
    _currentFood = null;
    _isBotTyping = false;
  });

  Future<void> _pickImage() async {
    _resetState();
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _loading = true;
      });
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
      setState(() {
        _currentFood = foodDetails;
        _isChatActive = true;
        _loading = false;
      });
      _addBotMessage(
        "It looks like you're having ${_currentFood!.englishName}! What would you like to know?",
        onFinished: _showMainOptions,
      );
    } catch (e) {
      if (kDebugMode) print("❗️_startChatbotFlow HATA: $e");
      setState(() { _loading = false; });
      _addBotMessage("I recognized it as '$foodName', but I couldn't find its details. Please check your internet connection and try again.");
    }
  }
  
  void _showMainOptions() {
     setState(() {
       _isBotTyping = false;
       _chatMessages.add(
         ButtonOptionsMessage([
           ChatButtonOption( text: '🛎️ Show to Waiter', onPressed: () => _handleOptionSelection(_navigateToWaiterCard, 'Show this to the waiter')),
           ChatButtonOption(text: '📖 Story & Origin', onPressed: () => _handleOptionSelection(_showStory, 'Tell me its story')),
           ChatButtonOption(text: '🥩 Ingredients & Allergens', onPressed: () => _handleOptionSelection(_showIngredients, 'What are the ingredients & allergens?')),
           ChatButtonOption(text: '🗣️ How to Pronounce?', onPressed: () => _handleOptionSelection(_showPronunciation, 'How do I pronounce it?')),
           ChatButtonOption(text: '🍷 What goes with it?', onPressed: () => _handleOptionSelection(_showPairing, 'What goes well with it?')),
         ])
       );
     });
     _scrollToBottom();
  }

  void _handleOptionSelection(Function actionFunction, String userText) {
    setState(() {
      _chatMessages.add(UserTextMessage(userText));
    });
    _scrollToBottom();
    
    if (actionFunction != _navigateToWaiterCard) {
      setState(() {
        _isBotTyping = true;
        _chatMessages.add(TypingIndicatorMessage());
      });
      _scrollToBottom();

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          _chatMessages.removeWhere((msg) => msg is TypingIndicatorMessage);
          actionFunction();
        });
        _scrollToBottom();
      });
    } else {
      actionFunction();
    }
  }

  void _askForMoreInfo() {
    _addBotMessage( "What else would you like to know?", onFinished: _showMainOptions );
  }

  void _addBotMessage(String text, {VoidCallback? onFinished}) {
    if(text.isEmpty) text = "Sorry, I don't have this information yet.";
    
    setState(() {
      _isBotTyping = true;
      _chatMessages.add(StreamingTextMessage(text, onFinished: onFinished ?? () => setState(() => _isBotTyping = false)));
    });
  }

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

  void _showPronunciation() => _addBotMessage(_currentFood?.pronunciationText ?? '', onFinished: _askForMoreInfo);
  void _showPairing() => _addBotMessage(_currentFood?.pairingEn ?? '', onFinished: _askForMoreInfo);

  void _navigateToWaiterCard() {
    if (_currentFood == null) return;

    setState(() {
      _chatMessages.removeWhere((msg) => msg is TypingIndicatorMessage);
      _isBotTyping = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowToWaiterPage(food: _currentFood!),
      ),
    ).then((_) {
      _askForMoreInfo();
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    const scrollTolerance = 50.0;
    final currentPosition = _scrollController.position.pixels;
    final maxPosition = _scrollController.position.maxScrollExtent;
    if ((maxPosition - currentPosition) < scrollTolerance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo( _scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    }
  }

  String _generateSpiceLevelText(int? level) {
    if (level == null) return "Unknown";
    switch (level) {
      case 1: return "🌶️ (Not Spicy)";
      case 2: return "🌶️🌶️ (Mild)";
      case 3: return "🌶️🌶️🌶️ (Medium)";
      case 4: return "🌶️🌶️🌶️🌶️ (Spicy)";
      case 5: return "🌶️🌶️🌶️🌶️🌶️ (Very Spicy)";
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
  
  // --- GÜNCELLENEN WIDGET: Senkronizasyon durumu için yükleme ekranı eklendi ---
  @override
  Widget build(BuildContext context) {
    if (!_modelLoaded || _isSyncing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('DishAI - Gastronomy Envoy'),
          backgroundColor: Colors.deepOrange.shade300,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _syncStatusMessage,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('DishAI - Gastronomy Envoy'),
        backgroundColor: Colors.deepOrange.shade300,
        actions: [
          if (_isChatActive)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetState,
              tooltip: 'Start Over',
            )
        ],
      ),
      body: Column(
        children: [
          if (_image != null && !_isChatActive) Padding(padding: const EdgeInsets.all(16.0), child: ClipRRect(borderRadius: BorderRadius.circular(12.0), child: Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover))),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_isChatActive && !_loading && _image == null) const Expanded(child: Center(child: Text('Let\'s identify your dish!\nClick the camera button below.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18),),),),
          if (_isChatActive)
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final message = _chatMessages[index];
                  if (message.isFromUser) {
                      return _buildUserMessage(message as UserTextMessage);
                  } else {
                      return _buildBotMessage(message);
                  }
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_modelLoaded && !_loading && !_isSyncing) ? _pickImage : null,
        tooltip: 'Select Photo',
        backgroundColor: (_modelLoaded && !_loading && !_isSyncing) ? Colors.deepOrange : Colors.grey,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  // --- BUILD HELPER WIDGETS (DEĞİŞİKLİK YOK) ---
  Widget _buildUserMessage(UserTextMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4).copyWith(left: 60),
        decoration: BoxDecoration(
          color: Colors.deepOrange.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(message.text, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
  
  Widget _buildBotMessage(ChatMessage message) {
    Widget messageContent;
    
    if (message is StreamingTextMessage) {
      messageContent = TypewriterChatMessage(
        text: message.text,
        onCharacterTyped: _scrollToBottom,
        onFinishedTyping: message.onFinished,
      );
    } else if (message is ButtonOptionsMessage) {
      messageContent = _buildButtonOptions(message);
    } else if (message is TypingIndicatorMessage) {
      messageContent = const AnimatedTypingIndicator();
    } else {
      messageContent = const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.ramen_dining_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(child: messageContent),
        ],
      ),
    );
  }

  Widget _buildButtonOptions(ButtonOptionsMessage message) {
    return AbsorbPointer(
      absorbing: _isBotTyping,
      child: Opacity(
        opacity: _isBotTyping ? 0.5 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: message.options.map((option) => Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _chatMessages.remove(message);
                });
                option.onPressed();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.deepOrange.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(option.text, style: TextStyle(color: Colors.deepOrange.shade800, fontWeight: FontWeight.bold)),
            ),
          )).toList(),
        ),
      ),
    );
  }
}