// GÜNCELLENMİŞ VE TAM DOSYA: lib/screens/add_memory_page.dart (Yapılandırılmış Yemek Seçimi Entegre Edilmiş)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/food_details.dart'; // <-- FoodDetails modelini import ediyoruz
import '../models/tasted_food_model.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

class AddMemoryPage extends StatefulWidget {
  const AddMemoryPage({super.key});

  @override
  State<AddMemoryPage> createState() => _AddMemoryPageState();
}

class _AddMemoryPageState extends State<AddMemoryPage> {
  final _formKey = GlobalKey<FormState>();
  
  // TextFormField Controller'ını kaldırıp yerine seçilen yemeği tutan bir değişken ekliyoruz.
  FoodDetails? _selectedFood; 
  
  File? _imageFile;
  String? _selectedCity;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 60);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      setState(() {
        _imageFile = savedImage;
      });
    }
  }

  Future<void> _selectCity() async {
    final String? city = await showDialog<String>(
      context: context,
      builder: (context) => const _CitySearchDialog(),
    );

    if (city != null) {
      setState(() {
        _selectedCity = city;
      });
    }
  }

  // Yediği yemeği seçmesi için yeni bir metot
  Future<void> _selectFood() async {
    final FoodDetails? food = await showDialog<FoodDetails>(
      context: context,
      builder: (context) => const _FoodSearchDialog(), // Yeni arama diyaloğumuz
    );

    if (food != null) {
      setState(() {
        _selectedFood = food;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMemory() async {
    // Doğrulama koşuluna _selectedFood kontrolünü ekliyoruz
    if (_formKey.currentState!.validate() && _selectedCity != null && _selectedFood != null && !_isSaving) {
      setState(() { _isSaving = true; });
      
      final newMemory = TastedFood(
        // Veritabanına yemeğin serbest metnini değil, resmi ID'sini ('name') kaydediyoruz.
        foodName: _selectedFood!.name, 
        cityName: _selectedCity!,
        tastedDate: _selectedDate.toIso8601String(),
        imagePath: _imageFile?.path,
      );

      await DatabaseHelper.instance.addTastedFood(newMemory);
       journalUpdatedNotifier.value = !journalUpdatedNotifier.value;
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else if (_selectedCity == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a city')),
      );
    } else if (_selectedFood == null) { // Yemek seçilmediyse uyarı ver
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a food')),
      );
    }
  }

  @override
  void dispose() {
    // Artık controller olmadığı için dispose etmeye gerek yok
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a Food Memory'),
        backgroundColor: Colors.teal.shade300,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to add a photo', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // TextFormField'ı, tıklanabilir bir ListTile ile değiştiriyoruz
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                title: const Text('What did you eat?'),
                subtitle: Text(
                  _selectedFood?.turkishName ?? 'Select a food from the list',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedFood != null ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
                trailing: const Icon(Icons.restaurant_menu),
                onTap: _selectFood,
                shape: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),

              const SizedBox(height: 16),
              ListTile(
                title: const Text('Where did you eat it?'),
                subtitle: Text(_selectedCity ?? 'Select a city'),
                trailing: const Icon(Icons.location_city),
                onTap: _selectCity,
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                title: const Text('When did you eat it?'),
                subtitle: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Memory'),
                onPressed: _isSaving ? null : _saveMemory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// YENİ WIDGET: Yemekleri aramak ve seçmek için kullanılan diyalog
class _FoodSearchDialog extends StatefulWidget {
  const _FoodSearchDialog();

  @override
  State<_FoodSearchDialog> createState() => _FoodSearchDialogState();
}

class _FoodSearchDialogState extends State<_FoodSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  
  // Arama sonuçlarını tutmak için bir state değişkeni
  List<FoodDetails> _filteredFoods = [];
  // Tüm yemekleri bir kez yükleyip saklamak için
  List<FoodDetails> _allFoods = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Veritabanından tüm yemekleri bir kez yükle
    DatabaseHelper.instance.getAllFoods().then((foods) {
      if (!mounted) return;
      setState(() {
        _allFoods = foods;
        _filteredFoods = foods; // Başlangıçta hepsi görünsün
        _isLoading = false;
      });
    });
    _searchController.addListener(_filterFoods);
  }

  void _filterFoods() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFoods = _allFoods.where((food) {
        return food.turkishName.toLowerCase().contains(query) || 
               food.englishName.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What Dish Did You Taste?'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Type to search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredFoods.length,
                      itemBuilder: (context, index) {
                        final food = _filteredFoods[index];
                        return ListTile(
                          title: Text(food.turkishName),
                          subtitle: Text(food.englishName),
                          onTap: () {
                            Navigator.of(context).pop(food); 
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        )
      ],
    );
  }
}

// BU WIDGET'TA DEĞİŞİKLİK YOK, olduğu gibi kalıyor.
class _CitySearchDialog extends StatefulWidget {
  const _CitySearchDialog();

  @override
  State<_CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<_CitySearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _filteredCities;

  final List<String> _turkishCities = const [ 'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara', 'Antalya', 'Artvin', 'Aydın', 'Balıkesir', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari', 'Hatay', 'Isparta', 'Mersin', 'İstanbul', 'İzmir', 'Kars', 'Kastamonu', 'Kayseri', 'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Kahramanmaraş', 'Mardin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop', 'Sivas', 'Tekirdr','Tokat', 'Trabzon', 'Tunceli', 'Şanlıurfa', 'Uşak', 'Van', 'Yozgat', 'Zonguldak', 'Aksaray', 'Bayburt', 'Karaman', 'Kırıkkale', 'Batman', 'Şırnak', 'Bartın', 'Ardahan', 'Iğdır', 'Yalova', 'Karabük', 'Kilis', 'Osmaniye', 'Düzce' ];

  @override
  void initState() {
    super.initState();
    _filteredCities = _turkishCities;
    _searchController.addListener(_filterCities);
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCities = _turkishCities.where((city) {
        return city.toLowerCase().startsWith(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('In Which City Did You Taste It?'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Type to search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCities.length,
                itemBuilder: (context, index) {
                  final city = _filteredCities[index];
                  return ListTile(
                    title: Text(city),
                    onTap: () { Navigator.of(context).pop(city); },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        )
      ],
    );
  }
}