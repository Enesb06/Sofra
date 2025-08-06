// lib/screens/lezzet_haritasi_page.dart

import 'package:flutter/material.dart';
import 'recognition_page.dart';

// VERİ MODELİ VE BÖLGESEL VERİLER
class BolgeselLezzet {
  final String bolgeAdi;
  final IconData ikon;
  final Color renk;
  final List<String> yemekler;

  BolgeselLezzet({
    required this.bolgeAdi,
    required this.ikon,
    required this.renk,
    required this.yemekler,
  });
}

final List<BolgeselLezzet> bolgeselLezzetler = [
  BolgeselLezzet(
      bolgeAdi: 'Akdeniz Bölgesi',
      ikon: Icons.wb_sunny,
      renk: Colors.orange,
      yemekler: ['adana_kebap', 'kunefe', 'icli_kofte']),
  BolgeselLezzet(
      bolgeAdi: 'Ege Bölgesi',
      ikon: Icons.local_florist,
      renk: Colors.green,
      yemekler: ['yaprak_sarma', 'coban_salata']),
  BolgeselLezzet(
      bolgeAdi: 'İç Anadolu Bölgesi',
      ikon: Icons.landscape,
      renk: Colors.brown,
      yemekler: [
        'manti',
        'sucuklu_yumurta',
        'et_doner',
        'mercimek_corbasi',
        'bulgur_pilavi',
        'pirinc_pilavi',
        'kofte'
      ]),
  BolgeselLezzet(
      bolgeAdi: 'Karadeniz Bölgesi',
      ikon: Icons.waves,
      renk: Colors.blue,
      yemekler: ['pide', 'hamsi_tava', 'kuru_fasulye']),
  BolgeselLezzet(
      bolgeAdi: 'Marmara Bölgesi',
      ikon: Icons.location_city,
      renk: Colors.purple,
      yemekler: ['iskender_kebap', 'simit', 'sutlac', 'su_boregi']),
  BolgeselLezzet(
      bolgeAdi: 'Güneydoğu Anadolu ',
      ikon: Icons.history_edu,
      renk: Colors.red,
      yemekler: ['baklava', 'lahmacun', 'karniyarik', 'cig_kofte']),
  BolgeselLezzet(
      bolgeAdi: 'Doğu Anadolu Bölgesi',
      ikon: Icons.ac_unit,
      renk: Colors.cyan,
      yemekler: ['menemen', 'biber_dolmasi', 'tavuk_doner']),
];

// ANA SAYFA WIDGET'I
class LezzetHaritasiPage extends StatelessWidget {
  const LezzetHaritasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DishAI Lezzet Atlası"),
        backgroundColor: Colors.deepOrange.shade300,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanıyabildiğimiz Lezzetler',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800)),
                const SizedBox(height: 8.0),
                Text(
                    'Yapay zekamızın hangi bölgelerden hangi lezzetleri tanıdığını keşfedin. Bölgelere tıklayarak listeyi görebilirsiniz.',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: bolgeselLezzetler.length,
              itemBuilder: (context, index) {
                final bolge = bolgeselLezzetler[index];
                return Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0)),
                  child: InkWell(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                BolgeDetayPage(bolge: bolge))),
                    borderRadius: BorderRadius.circular(15.0),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          gradient: LinearGradient(
                              colors: [bolge.renk.withOpacity(0.7), bolge.renk],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight)),
                      child: Row(
                        children: [
                          Icon(bolge.ikon, size: 40, color: Colors.white),
                          const SizedBox(width: 16),
                          Text(bolge.bolgeAdi,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Hadi Yemeğini Tanı!',
                  style: TextStyle(fontSize: 18)),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RecognitionPage())),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// DETAY SAYFASI WIDGET'I
class BolgeDetayPage extends StatelessWidget {
  final BolgeselLezzet bolge;
  const BolgeDetayPage({super.key, required this.bolge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(bolge.bolgeAdi), backgroundColor: bolge.renk),
      body: ListView.builder(
        itemCount: bolge.yemekler.length,
        itemBuilder: (context, index) {
          final yemekAdi = bolge.yemekler[index]
              .replaceAll('_', ' ')
              .split(' ')
              .map((e) =>
                  e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '')
              .join(' ');
          return ListTile(
              leading: Icon(Icons.restaurant_menu, color: bolge.renk.shade700),
              title: Text(yemekAdi, style: const TextStyle(fontSize: 18)));
        },
      ),
    );
  }
}

extension on Color {
  get shade700 => null;
}
