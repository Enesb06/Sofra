import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. DEĞİŞİKLİK: RecognitionPage yerine yeni ana iskeletimiz olan HomePage'i import ediyoruz.
import 'home_page.dart'; 

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
        // 2. DEĞİŞİKLİK: Uygulamayı artık tek bir sayfaya değil, 
        // BottomNavigationBar içeren HomePage'e yönlendiriyoruz.
        MaterialPageRoute(builder: (context) => const HomePage()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // BU KISIMDA HİÇBİR DEĞİŞİKLİK YOK.
    // MEVCUT GÜZEL TASARIMINIZ OLDUĞU GİBİ KALIYOR.
    return Scaffold(
      backgroundColor: Colors.deepOrange.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.ramen_dining_outlined,
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
              'Your Personal Turkish Gastronomy Envoy',
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