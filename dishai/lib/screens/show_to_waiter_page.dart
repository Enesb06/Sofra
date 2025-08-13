// YENİ DOSYA: lib/pages/show_to_waiter_page.dart

import 'package:flutter/material.dart';
import '../models/food_details.dart'; // Model dosyanızın yolunu kontrol edin

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
        child: SingleChildScrollView( // İçeriğin küçük ekranlarda taşmasını önler
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (food.imageUrl != null && food.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.network(
                    food.imageUrl!,
                    height: MediaQuery.of(context).size.height * 0.35,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        alignment: Alignment.center,
                        child: const Icon(Icons.no_photography_outlined, size: 80, color: Colors.grey),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 32),
              Text(
                food.turkishName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Roboto', // Fontu daha okunaklı yapabilir
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