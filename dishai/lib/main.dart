import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

// LÜTFEN BU BİLGİLERİ KENDİ SUPABASE PROJENDEN ALARAK GÜNCELLE
const String supabaseUrl = 'https://dqqtwebzwjlgyewmezma.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxcXR3ZWJ6d2psZ3lld21lem1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4NzYzOTcsImV4cCI6MjA2NzQ1MjM5N30.QloA5Q3FCI5B2wGI3yx5ZOGZj3_Asmn71RGJFs4PlNQ';

Future<void> main() async {
  // Flutter uygulamasının başlamadan önce native kodla (Supabase) iletişim kurabilmesi için.
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase'i başlatıyoruz.
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const DishAI());
}

// Supabase istemcisine kolay erişim için bir kısayol
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
  final bool _loading = false;
  String? _result;

  // Henüz fonksiyonları doldurmadık, sadece iskeletlerini oluşturduk.
  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    // Model yükleme kodunu bir sonraki adımda buraya yazacağız.
    print("Model yükleme fonksiyonu çağrıldı.");
  }

  Future<void> _pickImage() async {
    // Resim seçme ve tahmin başlatma kodunu buraya yazacağız.
    print("Resim seçme fonksiyonu çağrıldı.");
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
            // Seçilen resmi göstermek için bir alan
            _image == null
                ? const Text('Lütfen bir yemek fotoğrafı seçin.')
                : Image.file(_image!, height: 250),

            const SizedBox(height: 20),

            // Sonucu göstermek için bir alan
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
