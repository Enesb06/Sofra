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

 // LİDER ALGORİTMASI v2 - KESİN ÇÖZÜM
// lib/screens/menu_scanner_page.dart içindeki _matchTextWithDatabase metodunu bununla değiştirin.

 // ÇOKLU EŞLEŞME ALGORİTMASI
// lib/screens/menu_scanner_page.dart içindeki _matchTextWithDatabase metodunu bununla değiştirin.

// FİNAL ALGORİTMASI - ÇİFT YÖNLÜ KELİME KAPSAMA
// lib/screens/menu_scanner_page.dart içindeki _matchTextWithDatabase metodunu bununla değiştirin.

 // "ANAHTAR KELİME" ALGORİTMASI - SON TAVSİYE EDİLEN VERSİYON
// lib/screens/menu_scanner_page.dart içindeki _matchTextWithDatabase metodunu bununla değiştirin.

  Future<void> _matchTextWithDatabase(RecognizedText recognizedText, String imagePath) async {
    // 1. Veritabanı verilerini al ve normalleştir.
    final foodNameMap = await DatabaseHelper.instance.getAllFoodNamesForMatching();
    Map<String, String> normalizedDbFoods = {};
    foodNameMap.forEach((turkishName, nameId) {
      normalizedDbFoods[_normalizeText(turkishName)] = nameId;
    });

    // En uzun (en spesifik) isimlerin önce kontrol edilmesi için sırala.
    // Bu, "adana kebap"ın "adana"dan (eğer olsaydı) önce kontrol edilmesini sağlar.
    final allDbFoodNames = normalizedDbFoods.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    // 2. OCR'dan gelen tüm satırları al.
    final List<TextLine> allLines = [];
    for (var block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }
    
    final List<MatchedFood> matchedFoods = [];
    final Set<String> foundFoodIds = {}; // Sonuçların tekrar etmesini engellemek için.

    // 3. Veritabanındaki HER BİR yemek için döngü başlat.
    for (String dbFoodName in allDbFoodNames) {
      // 4. Yemeğin ilk kelimesini "anahtar kelime" olarak belirle.
      String keyWord = dbFoodName.split(' ').first;
      
      // "su", "tuz" gibi çok kısa ve genel anahtar kelimeleri atla.
      // Bu, yanlış pozitif eşleşmeleri (örn: "sulu köfte"nin "su" ile eşleşmesi) engeller.
      if (keyWord.length < 3) continue;

      // 5. OCR'daki HER BİR satır için döngü başlat.
      for (TextLine line in allLines) {
        String ocrLineText = _normalizeText(line.text);
        
        // 6. EŞLEŞME KURALI: Menüdeki satır, bizim anahtar kelimemizi içeriyor mu?
        if (ocrLineText.contains(keyWord)) {
          final foodId = normalizedDbFoods[dbFoodName]!;

          // Eğer bu yemeği daha önce HİÇBİR satırdan bulmadıysak...
          if (!foundFoodIds.contains(foodId)) {
            final foodDetails = await DatabaseHelper.instance.getFoodByName(foodId);
            if (foodDetails != null) {
              print("EŞLEŞME BULUNDU! Anahtar Kelime: '$keyWord' -> Menü: '$ocrLineText' -> DB: '$dbFoodName'");
              matchedFoods.add(MatchedFood(
                food: foodDetails,
                boundingBox: line.boundingBox,
              ));
              foundFoodIds.add(foodId);
              
              // Bu yemeği bulduk, artık bu yemeği başka satırlarda aramaya gerek yok.
              // Bir sonraki VERİTABANI yemeğine geç.
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