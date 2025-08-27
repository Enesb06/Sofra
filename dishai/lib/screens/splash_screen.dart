import 'dart:async';
import 'package:dishai/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        MaterialPageRoute(builder: (context) => const HomePage()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon( Icons.ramen_dining_outlined, size: 100.0, color: Theme.of(context).colorScheme.primary, ),
            const SizedBox(height: 24),
            Text( 'DishAI', style: GoogleFonts.poppins( fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, ), ),
            const SizedBox(height: 12),
            Text( 'Your Personal Turkish Gastronomy Envoy', style: GoogleFonts.poppins( fontSize: 16, color: Colors.grey.shade700, ), ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(), // Renk artık temadan geliyor.
          ],
        ),
      ),
    );
  }
}