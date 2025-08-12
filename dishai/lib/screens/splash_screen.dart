import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. DEĞİŞİKLİK: Eski sayfayı değil, tanıma sayfasını içeri aktar.
import 'recognition_page.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
      () => Navigator.of(context).pushReplacement(
        // 2. DEĞİŞİKLİK: LezzetHaritasiPage yerine RecognitionPage'e yönlendir.
        MaterialPageRoute(builder: (context) => const RecognitionPage()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.ramen_dining_outlined, // İkonu güncelledim
              size: 100.0,
              color: Colors.deepOrange.shade800,
            ),
            const SizedBox(height: 24),
            Text(
              'DishAI',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your Personal Turkish Gastronomy Envoy', // Metni güncelledim
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
            ),
          ],
        ),
      ),
    );
  }
}