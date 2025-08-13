// GÜNCELLENMİŞ DOSYA: lib/screens/show_to_waiter_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <--- YENİ IMPORT
import '../models/food_details.dart';

class ShowToWaiterPage extends StatelessWidget {
  final FoodDetails food;

  const ShowToWaiterPage({Key? key, required this.food}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 32),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---
              if (food.imageUrl != null && food.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  // Image.network yerine CachedNetworkImage kullanıyoruz.
                  child: CachedNetworkImage(
                    imageUrl: food.imageUrl!,
                    height: MediaQuery.of(context).size.height * 0.35,
                    fit: BoxFit.cover,
                    // Resim yüklenirken gösterilecek olan widget (placeholder)
                    placeholder: (context, url) => Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                    // Hata durumunda gösterilecek olan widget
                    errorWidget: (context, url, error) => Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      alignment: Alignment.center,
                      child: const Icon(Icons.no_photography_outlined, size: 80, color: Colors.grey),
                    ),
                  ),
                ),
              // --- DEĞİŞİKLİK BURADA BİTİYOR ---
              const SizedBox(height: 32),
              Text(
                food.turkishName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '"Bir porsiyon alabilir miyim, lütfen?"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}