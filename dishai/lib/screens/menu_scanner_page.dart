// SON GÜNCEL DOSYA: lib/screens/menu_scanner_page.dart
// (En Uzun Eşleşme ve Türkçe Normalleştirme Algoritmasını İçeren Versiyon)

import 'dart:ui'; // Rect modeli için
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/food_details.dart';
import '../services/database_helper.dart';
import 'menu_result_page.dart';

// Eşleşen bir yemeğin bilgilerini ve ekrandaki konumunu tutan model sınıfı.
class MatchedFood {
  final FoodDetails food;
  final Rect boundingBox; // Metnin resimdeki koordinatları

  MatchedFood({required this.food, required this.boundingBox});
}

class MenuScannerPage extends StatefulWidget {
  const MenuScannerPage({super.key});

  @override
  State<MenuScannerPage> createState() => _MenuScannerPageState();
}

class _MenuScannerPageState extends State<MenuScannerPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras found on this device.')));
      return;
    }
    _cameraController = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to initialize camera.')));
    }
  }

  Future<void> _scanMenu() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isScanning) {
      return;
    }
    setState(() { _isScanning = true; });
    try {
      final XFile imageFile = await _cameraController!.takePicture();
      await _processImageForText(imageFile.path);
    } catch (e) {
      print('Error during scan: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred while scanning.')));
    } finally {
      if (mounted) setState(() { _isScanning = false; });
    }
  }

  Future<void> _processImageForText(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    await _matchTextWithDatabase(recognizedText, imagePath);
  }

  // Daha iyi eşleştirme için Türkçe karakterleri normalleştiren yardımcı fonksiyon
  String _normalizeText(String text) {
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o');
  }

  // "En Uzun Eşleşme Öncelikli" Algoritma
  Future<void> _matchTextWithDatabase(RecognizedText recognizedText, String imagePath) async {
    // 1. Veritabanından verileri al
    final foodNameMap = await DatabaseHelper.instance.getAllFoodNamesForMatching();

    // 2. Veritabanı verilerini normalleştir ve arama için hazırla
    Map<String, String> normalizedDbFoods = {};
    foodNameMap.forEach((turkishName, nameId) {
      normalizedDbFoods[_normalizeText(turkishName)] = nameId;
    });

    // Normalleştirilmiş isimleri uzunluklarına göre BÜYÜKTEN KÜÇÜĞE sırala
    final allDbFoodNames = normalizedDbFoods.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final List<MatchedFood> matchedFoods = [];
    final Set<String> foundFoodIds = {};
    final List<TextLine> allLines = [];
    for (var block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }
    
    // DEBUG: Tanınan tüm satırları yazdır
    print("--- Normalleştirilmiş OCR Satırları ---");
    for(var line in allLines) {
      print(_normalizeText(line.text));
    }
    print("-------------------------------------");
    
    // DEBUG: Veritabanındaki normalleştirilmiş isimleri yazdır
    print("--- Veritabanındaki Normalleştirilmiş İsimler (İlk 5) ---");
    print(allDbFoodNames.take(5));
    print("-------------------------------------------------------");

    // 3. TANINAN TÜM satırları döngüye al
    for (TextLine line in allLines) {
      String ocrLineText = _normalizeText(line.text);

      // 4. VERİTABANINDAKİ TÜM yemek isimlerini (uzunluğa göre sıralı) döngüye al
      for (String dbFoodName in allDbFoodNames) {
        // EŞLEŞME KURALI: Normalleştirilmiş OCR satırı, normalleştirilmiş veritabanı yemek adını içeriyor mu?
        if (ocrLineText.contains(dbFoodName)) {
          final foodId = normalizedDbFoods[dbFoodName]!;

          if (!foundFoodIds.contains(foodId)) {
            final foodDetails = await DatabaseHelper.instance.getFoodByName(foodId);
            if (foodDetails != null) {
              matchedFoods.add(MatchedFood(
                food: foodDetails,
                boundingBox: line.boundingBox,
              ));
              foundFoodIds.add(foodId);
              
              // Bu satır için EN İYİ (en uzun) eşleşmeyi bulduk.
              // Bu satırı daha fazla kontrol etmeyi bırakıp sonraki satıra geç.
              break; 
            }
          }
        }
      }
    }

    print("Eşleşme tamamlandı. Bulunan yemek sayısı: ${matchedFoods.length}");

    if (!mounted) return;

    if (matchedFoods.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MenuResultPage(
            imagePath: imagePath,
            matchedFoods: matchedFoods,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veritabanımızda eşleşen bir yemek bulunamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Translator'),
        backgroundColor: Colors.teal.shade300,
      ),
      body: _isLoading || _cameraController == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController!),
                if (_isScanning)
                  Container(
                    color: Colors.black.withOpacity(0.7),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 20),
                          Text(
                            "Scanning Menu...",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_isScanning) _buildOverlayUI(),
              ],
            ),
    );
  }

  Widget _buildOverlayUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: double.infinity,
          color: Colors.black.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: const Text(
            'Position the menu and tap the button to scan',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        Container(
          color: Colors.black.withOpacity(0.5),
          padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
          child: Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan Menu'),
              onPressed: _isScanning ? null : _scanMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}