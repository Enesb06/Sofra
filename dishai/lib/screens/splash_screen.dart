import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Sadece giriş animasyonu için tek bir controller yeterli
  late final AnimationController _entryController;

  // İkonların yollarını bir listede tutuyoruz
  final List<String> _foodIcons = [
    'assets/images/icons/kebab.png',
    'assets/images/icons/pide.png',
    'assets/images/icons/baklava.png',
    'assets/images/icons/tea.png',
    'assets/images/icons/soup.png',
    'assets/images/icons/doner.png',
  ];

  @override
  void initState() {
    super.initState();

    // Giriş Animasyonu Controller'ı (2 saniye sürecek)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Animasyonları ve sayfa geçişini başlat
    _startAnimations();
  }

  void _startAnimations() {
    // Küçük bir gecikmeyle giriş animasyonunu başlat
    Timer(const Duration(milliseconds: 200), () {
      if(mounted) _entryController.forward();
    });

    // Ana sayfaya geçiş için zamanlayıcı
    Timer(
      const Duration(seconds: 4), // Toplam splash süresi
      () => Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor'ı yine kaldırıyoruz, çünkü Stack ekranı kaplayacak.
      body: Stack( // Ana widget'ı Stack yapıyoruz.
        fit: StackFit.expand, // Stack ekranı doldursun.
        children: [
          // 1. Katman: Arka Plan Resmi
          Image.asset(
            'assets/images/sofra_background.png',
            fit: BoxFit.cover,
          ),

          // 2. Katman: Renk Filtresi
          Container(
            color: Colors.deepOrange.shade50.withOpacity(0.75),
          ),
          
          // 3. Katman: Orijinal içeriğin kendisi (Center ve içindeki Stack)
          // Bu, tüm logo ve ikonların ekranın ortasında kalmasını garanti eder.
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // "Sofra" yazısı ve alt başlık
                FadeTransition(
                  opacity: CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sofra',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
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
                    ],
                  ),
                ),

                // Sabit duran ikonlar
                for (int i = 0; i < _foodIcons.length; i++)
                  _buildAnimatedIcon(i),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(int index) {
    // Her ikonun animasyonunun ne zaman başlayıp biteceğini belirleyen aralık
    final intervalStart = 0.2 + (index * 0.1); // Kademeli olarak başlasınlar
    final intervalEnd = intervalStart + 0.6; // Bitiş zamanı

    final animation = CurvedAnimation(
      parent: _entryController,
      // lastik gibi esnemek yerine daha yumuşak bir giriş animasyonu
      curve: Interval(intervalStart, min(intervalEnd, 1.0), curve: Curves.easeOut),
    );
    
    // İkonları dairesel yörüngeye yerleştirmek için matematik
    final angle = (2 * pi / _foodIcons.length) * index;
    final radius = 120.0; // Dairenin yarıçapını biraz artırdık
    final x = radius * cos(angle);
    final y = radius * sin(angle);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Animasyonun değeriyle hem pozisyonu hem de boyutu kontrol ediyoruz
        final currentRadius = radius * animation.value;
        final currentX = currentRadius * cos(angle);
        final currentY = currentRadius * sin(angle);
        
        return Transform.translate(
          offset: Offset(currentX, currentY),
          child: Transform.scale(
            scale: animation.value,
            child: Opacity(
              opacity: animation.value,
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(
        _foodIcons[index],
        width: 80,
        height: 80,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
      ),
    );
  }
}