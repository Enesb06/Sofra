import 'package:flutter/material.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  // TODO: Lezzet Kaşifi chatbot'unun mantığı buraya gelecek.
  // - Chat mesajları listesi
  // - Metin giriş kontrolcüsü
  // - Şehir arama ve öneri fonksiyonları

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DishAI - Flavor Explorer'),
        backgroundColor: Colors.blue.shade300, // Ayırt etmek için farklı bir renk
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Başlangıç için basit bir karşılama mesajı
                _buildBotMessage("Ready for a culinary adventure in Türkiye! 🇹🇷\n\nWhich city are you planning to visit?"),
              ],
            ),
          ),
          // TODO: Metin giriş alanı buraya eklenecek.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Chatbot input will be here...",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // RecognitionPage'den ödünç alınmış basit bir bot mesajı widget'ı
  Widget _buildBotMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.explore_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20).copyWith(topLeft: const Radius.circular(4)),
              ),
              child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }
}