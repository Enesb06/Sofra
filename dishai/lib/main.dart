// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

const String supabaseUrl = 'https://dqqtwebzwjlgyewmezma.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxcXR3ZWJ6d2psZ3lld21lem1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4NzYzOTcsImV4cCI6MjA2NzQ1MjM5N30.QloA5Q3FCI5B2wGI3yx5ZOGZj3_Asmn71RGJFs4PlNQ';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const DishAI());
}

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
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
