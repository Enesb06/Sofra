import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

const String supabaseUrl = 'https://dqqtwebzwjlgyewmezma.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxcXR3ZWJ6d2psZ3lld21lem1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4NzYzOTcsImV4cCI6MjA2NzQ1MjM5N30.QloA5Q3FCI5B2wGI3yx5ZOGZj3_Asmn71RGJFs4PlNQ';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const DishAI());
}

final supabase = Supabase.instance.client;

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

  @override
  void initState() {
    super.initState();
    _loadModel();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _loading = true;
        _result = '';
      });
      _runInference(File(pickedFile.path));
    } else {
      print('Kullanıcı resim seçmedi.');
    }
  }

  Future<void> _runInference(File imageFile) async {
    if (!_modelLoaded || _interpreter == null || _labels == null) {
      print('Model veya etiketler henüz yüklenmedi.');
      setState(() {
        _result = "Model hazır değil, lütfen bekleyin.";
        _loading = false;
      });
      return;
    }

    final imageData = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return;

    // 1. Resmi modelin istediği boyuta getiriyoruz (224x224)
    img.Image resizedImage =
        img.copyResize(originalImage, width: 224, height: 224);

    // 2. Resmin ham byte verisini alıyoruz.
    var imageBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    var buffer = Float32List(1 * 224 * 224 * 3);
    var bufferIndex = 0;

    // --- DEĞİŞİKLİK BURADA ---
    // Piksel değerlerini 255'e bölmüyoruz.
    // Modele ham (0-255) değerleri gönderiyoruz, çünkü modelin ilk katmanı bu işlemi kendi yapıyor.
    for (var i = 0; i < imageBytes.length; i++) {
      buffer[bufferIndex++] = imageBytes[i].toDouble();
    }
    // --- DEĞİŞİKLİK SONU ---

    var input = buffer.reshape([1, 224, 224, 3]);
    var output =
        List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

    _interpreter!.run(input, output);

    // --- HATA AYIKLAMA KODU ---
    // Modelin verdiği olasılık listesini konsolda görelim.
    print("MODELİN HAM ÇIKTISI (Olasılıklar): ${output[0]}");
    // -------------------------

    double maxScore = 0;
    int maxIndex = -1;
    // En yüksek olasılığa sahip indeksi buluyoruz
    for (int i = 0; i < output[0].length; i++) {
      if (output[0][i] > maxScore) {
        maxScore = output[0][i];
        maxIndex = i;
      }
    }

    if (maxIndex != -1) {
      final predictedLabel = _labels![maxIndex];
      print("Tahmin edilen etiket: $predictedLabel, Skor: $maxScore");

      try {
        final response = await supabase
            .from('foods')
            .select('calories_per_portion')
            .eq('name', predictedLabel)
            .single();

        final calories = response['calories_per_portion'];
        // Underscore'ları boşlukla değiştirerek daha güzel bir görünüm sağlıyoruz.
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
        print("Supabase'den kalori çekilirken hata: $e");
        setState(() {
          _result =
              "Yemek: ${predictedLabel.replaceAll('_', ' ')}\n(Kalori bilgisi bulunamadı)";
          _loading = false;
        });
      }
    } else {
      setState(() {
        _result = "Yemek tanınamadı.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DishAI - Lezzet Tanıyıcı'),
        backgroundColor: Colors.deepOrange.shade300,
      ),
      body: !_modelLoaded
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text("Model Yükleniyor..."),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _image == null
                      ? const Text('Lütfen bir yemek fotoğrafı seçin.')
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.file(_image!,
                              height: 250, width: 250, fit: BoxFit.cover),
                        ),
                  const SizedBox(height: 20),
                  _loading
                      ? const CircularProgressIndicator()
                      : Text(
                          _result ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _modelLoaded ? _pickImage : null,
        tooltip: 'Fotoğraf Seç',
        backgroundColor: _modelLoaded ? Colors.deepOrange : Colors.grey,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
