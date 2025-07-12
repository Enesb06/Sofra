import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

// Supabase bilgilerin doğru, onlara dokunmuyoruz.
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

  @override
  void initState() {
    super.initState();
    _loadModel(); // Model ve etiketleri uygulama başlarken yükle
  }

  // Model ve Etiket Yükleme Fonksiyonu
  Future<void> _loadModel() async {
    try {
      // Modeli assets'den yükle
      _interpreter = await Interpreter.fromAsset('model.tflite');

      // Etiketleri assets'den yükle
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n');

      print('Model ve etiketler başarıyla yüklendi.');
    } catch (e) {
      print('Model yüklenirken hata oluştu: $e');
    }
  }

  // Resim Seçme Fonksiyonu (Dolu Hali)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Galeriyi açmak için ImageSource.gallery, kamerayı açmak için ImageSource.camera
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _loading = true; // Yükleme animasyonunu başlat
        _result = ''; // Eski sonucu temizle
      });
      // TODO: Resim seçildikten sonra TAHMİN fonksiyonunu çağıracağız.
      // Şimdilik sadece resmin ekranda görünmesini sağlıyoruz ve loading'i durduruyoruz.
      // Bu, bir sonraki adımda değişecek.
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _loading = false;
        });
      });
    } else {
      print('Kullanıcı resim seçmedi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DishAI - Lezzet Tanıyıcı'),
        backgroundColor: Colors.deepOrange.shade300,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null
                ? const Text('Lütfen bir yemek fotoğrafı seçin.')
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(_image!, height: 250, fit: BoxFit.cover),
                  ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : Text(
                    _result ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        tooltip: 'Fotoğraf Seç',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
