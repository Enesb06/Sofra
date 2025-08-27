import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await dotenv.load(fileName: ".env");
    await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );


  // <--- DEĞİŞİKLİK: 'tr_TR' yerine 'en_US' kullanıyoruz ---
  // Bu, uygulamanın tarih formatları için İngilizce verilerini yüklemesini sağlar.
  await initializeDateFormatting('en_US', null);

  runApp(const DishAI());
}

class DishAI extends StatelessWidget {
  const DishAI({super.key});

  @override
  Widget build(BuildContext context) {
    // Splash ekranındaki metin rengini referans alarak ana rengimizi belirliyoruz.
    final Color primaryOrange = Colors.deepOrange.shade500;
    final Color secondaryOrange = Colors.deepOrange.shade700; // Butonlar için biraz daha canlı bir ton

    return MaterialApp(
      title: 'DishAI',
      theme: ThemeData(
        // Ana renk paletini bu ideal turuncu ile başlatıyoruz.
        colorScheme: ColorScheme.fromSeed(
            seedColor: primaryOrange,
            primary: primaryOrange,
            secondary: secondaryOrange,
        ),
        useMaterial3: true,
        
        // AppBarların rengini ana rengimiz yapıyoruz.
        appBarTheme: AppBarTheme(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 2,
        ),

        // FAB ve ana butonların rengini ikincil, daha canlı turuncu yapıyoruz.
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: secondaryOrange,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // Seçili chiplerin ve sekmelerin renklerini ayarlıyoruz.
        chipTheme: ChipThemeData(
          selectedColor: primaryOrange.withOpacity(0.15),
          checkmarkColor: primaryOrange,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: Colors.white,
          indicatorColor: Colors.orange.shade300, // Daha yumuşak bir gösterge rengi
          unselectedLabelColor: Colors.white.withOpacity(0.8),
        ),

        // Alt navigasyon çubuğu için tema.
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: primaryOrange,
          unselectedItemColor: Colors.grey.shade600,
        )
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}