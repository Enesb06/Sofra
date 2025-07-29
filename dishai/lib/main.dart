// main.dart dosyasının tamamını bu kodla değiştir

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

const String supabaseUrl = 'https://dqqtwebzwjlgyewmezma.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxcXR3ZWJ6d2psZ3lld21lem1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4NzYzOTcsImV4cCI6MjA2NzQ1MjM5N30.QloA5Q3FCI5B2wGI3yx5ZOGZj3_Asmn71RGJFs4PlNQ';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const DishAI());
}

final supabase = Supabase.instance.client;
const uuid = Uuid();

class DishAI extends StatelessWidget {
  const DishAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DishAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  bool _loading = false;
  String? _result;
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _modelLoaded = false;

  List<Map<String, dynamic>>? _predictions;
  String? _predictedLabel;
  String? _initialPredictionLabel;

  final _correctionController = TextEditingController();
  bool _showCorrectionUI = false;
  bool _isUploadingCorrection = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _correctionController.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();
      setState(() {
        _modelLoaded = true;
      });
      print(
          'Model ve etiketler başarıyla yüklendi. Etiket sayısı: ${_labels?.length}');
    } catch (e) {
      print('!!!!!!!! MODEL YÜKLENİRKEN HATA OLUŞTU: $e !!!!!!!!!!');
      setState(() {
        _result = "Model yüklenemedi.\nLütfen uygulamayı yeniden başlatın.";
      });
    }
  }

  void _resetState() {
    setState(() {
      _image = null;
      _result = null;
      _predictions = null;
      _predictedLabel = null;
      _initialPredictionLabel = null;
      _loading = false;
      _showCorrectionUI = false;
      _isUploadingCorrection = false;
      _correctionController.clear();
    });
  }

  Future<void> _pickImage() async {
    _resetState();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _loading = true;
        _result = '';
      });
      _runInference(File(pickedFile.path));
    }
  }

  Future<void> _runInference(File imageFile) async {
    if (!_modelLoaded || _interpreter == null || _labels == null) return;
    final imageData = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return;
    img.Image resizedImage =
        img.copyResize(originalImage, width: 224, height: 224);
    var imageBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    var buffer = Float32List(1 * 224 * 224 * 3);
    var bufferIndex = 0;
    for (var i = 0; i < imageBytes.length; i++) {
      buffer[bufferIndex++] = imageBytes[i].toDouble();
    }
    var input = buffer.reshape([1, 224, 224, 3]);
    var output =
        List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);
    _interpreter!.run(input, output);

    List<Map<String, dynamic>> predictions = [];
    for (int i = 0; i < output[0].length; i++) {
      predictions.add({"label": _labels![i], "score": output[0][i]});
    }
    predictions
        .sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    setState(() {
      _predictions = predictions;
      if (predictions.isNotEmpty) {
        _initialPredictionLabel = predictions.first['label'];
      }
    });

    await _showPrediction();
  }

  Future<void> _showPrediction() async {
    if (_predictions == null || _predictions!.isEmpty) {
      setState(() {
        _result =
            "Model başka tahmin bulamadı.\nLütfen doğru yemeği siz girin:";
        _showCorrectionUI = true;
        _loading = false;
      });
      return;
    }
    final bestPrediction = _predictions!.first;
    final predictedLabel = bestPrediction['label'] as String;
    setState(() {
      _predictedLabel = predictedLabel;
      _loading = true;
      _result = '';
    });
    try {
      final response = await supabase
          .from('foods')
          .select('calories_per_portion')
          .eq('name', predictedLabel)
          .single();
      final calories = response['calories_per_portion'];
      final foodName = predictedLabel
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
      setState(() {
        _result = "Yemek: $foodName\nKalori: Yaklaşık $calories kcal";
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result =
            "Yemek: ${predictedLabel.replaceAll('_', ' ')}\n(Kalori bilgisi bulunamadı)";
        _loading = false;
      });
    }
  }

  Future<void> _submitCorrection() async {
    if (_correctionController.text.trim().isEmpty || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lütfen yemeğin adını girin.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() {
      _isUploadingCorrection = true;
    });
    try {
      final imageBytes = await _image!.readAsBytes();
      final fileExt = _image!.path.split('.').last;
      final fileName = '${uuid.v4()}.$fileExt';
      final filePath = fileName;

      // 1. Resmi Supabase Storage'a yükle (KOVA ADI DÜZELTİLDİ)
      await supabase.storage.from('user-corrections').uploadBinary(
          filePath, imageBytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'));

      // 2. Yüklenen resmin URL'sini al (KOVA ADI DÜZELTİLDİ)
      final imageUrl =
          supabase.storage.from('user-corrections').getPublicUrl(filePath);

      // 3. Düzeltme verisini Supabase veritabanına kaydet
      await supabase.from('user_corrections').insert({
        'image_url': imageUrl,
        'user_provided_label': _correctionController.text
            .trim()
            .toLowerCase()
            .replaceAll(' ', '_'),
        'model_prediction': _initialPredictionLabel,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Değerli geri bildiriminiz kaydedildi. Teşekkürler!'),
          backgroundColor: Colors.green));
    } catch (e) {
      print("Düzeltme gönderilirken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bir hata oluştu, düzeltme gönderilemedi.'),
          backgroundColor: Colors.red));
    } finally {
      _resetState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('DishAI - Lezzet Tanıyıcı'),
          backgroundColor: Colors.deepOrange.shade300),
      body: !_modelLoaded
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text("Model Yükleniyor...")
                ],
              ),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (_image == null)
                      const Text('Lütfen bir yemek fotoğrafı seçin.')
                    else
                      ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.file(_image!,
                              height: 250, width: 250, fit: BoxFit.cover)),
                    const SizedBox(height: 20),
                    if (_loading)
                      const CircularProgressIndicator()
                    else if (_result != null && _result!.isNotEmpty)
                      Text(_result!,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    if (!_loading &&
                        !_showCorrectionUI &&
                        _predictions != null &&
                        _predictions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: Column(
                          children: [
                            Text('Tahmin doğru mu?',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey[700])),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                    onPressed: () => _resetState(),
                                    icon:
                                        const Icon(Icons.check_circle_outline),
                                    label: const Text('Doğru'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white)),
                                const SizedBox(width: 20),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (_predictions != null &&
                                        _predictions!.isNotEmpty) {
                                      setState(() {
                                        _predictions!.removeAt(0);
                                      });
                                    }
                                    _showPrediction();
                                  },
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Yanlış'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (_showCorrectionUI)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Column(
                          children: [
                            TextField(
                                controller: _correctionController,
                                decoration: const InputDecoration(
                                    labelText: 'Doğru Yemek Adı',
                                    border: OutlineInputBorder(),
                                    hintText: 'Örn: Adana Kebap')),
                            const SizedBox(height: 15),
                            _isUploadingCorrection
                                ? const CircularProgressIndicator()
                                : ElevatedButton.icon(
                                    onPressed: _submitCorrection,
                                    icon: const Icon(Icons.send),
                                    label: const Text('Geri Bildirimi Gönder'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12)),
                                  )
                          ],
                        ),
                      )
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            (_modelLoaded && !_isUploadingCorrection) ? _pickImage : null,
        tooltip: 'Fotoğraf Seç',
        backgroundColor: (_modelLoaded && !_isUploadingCorrection)
            ? Colors.deepOrange
            : Colors.grey,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
