// YENİ DOSYA: lib/screens/festivals_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../models/festival_model.dart';
import '../services/database_helper.dart';
import 'festival_detail_page.dart'; // Bir sonraki adımda oluşturacağız

class FestivalsPage extends StatefulWidget {
  const FestivalsPage({super.key});

  @override
  State<FestivalsPage> createState() => _FestivalsPageState();
}

class _FestivalsPageState extends State<FestivalsPage> {
  late Future<List<Festival>> _festivalsFuture;

  @override
  void initState() {
    super.initState();
    _festivalsFuture = DatabaseHelper.instance.getAllFestivals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Festivals in Turkey'),
      ),
      body: FutureBuilder<List<Festival>>(
        future: _festivalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          final festivals = snapshot.data;
          if (festivals == null || festivals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No upcoming festivals found at the moment.\nPlease check back later!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: festivals.length,
            itemBuilder: (context, index) {
              return _FestivalCard(festival: festivals[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 3,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 20.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 200, color: Colors.white),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: double.infinity, height: 24, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 150, height: 20, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _FestivalCard extends StatelessWidget {
  final Festival festival;
  const _FestivalCard({required this.festival});

  // --- YENİ: Durum etiketini oluşturacak yardımcı metot ---
  Widget _buildStatusTag(BuildContext context, {required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5)],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5, // Harf aralığını biraz açalım
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tarih kontrollerini build metodunun en başına taşıyoruz,
    // çünkü hem opaklık hem de etiket için bu bilgiye ihtiyacımız var.
    final now = DateUtils.dateOnly(DateTime.now());
    final startDate = DateUtils.dateOnly(festival.startDate);
    final endDate = DateUtils.dateOnly(festival.endDate);

    final bool isOngoing = !now.isBefore(startDate) && !now.isAfter(endDate);
    final bool isUpcoming = now.isBefore(startDate);
    final bool isPast = now.isAfter(endDate);

    // Tarih metnini oluşturma (bu kısım aynı)
    String dateText;
    final format = DateFormat('d MMMM');
    if (festival.startDate.month == festival.endDate.month && festival.startDate.day == festival.endDate.day) {
      dateText = format.format(festival.startDate);
    } else {
      dateText = '${format.format(festival.startDate)} - ${format.format(festival.endDate)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5,
      child: InkWell(
        onTap: () {
          // Bu yönlendirme mantığı doğru ve aynı kalıyor.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FestivalDetailPage(festival: festival),
            ),
          );
        },
        // --- DEĞİŞİKLİK: Opaklığı sadece geçmiş festivaller için uyguluyoruz ---
        child: Opacity(
          opacity: isPast ? 0.65 : 1.0, // Geçmişse biraz daha soluk yapalım
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- DEĞİŞİKLİK: Resim oluşturma metoduna yeni durumları da gönderiyoruz ---
              _buildCardImage(context, isOngoing: isOngoing, isUpcoming: isUpcoming),
              _buildCardInfo(context, dateText, isPast: isPast),
            ],
          ),
        ),
      ),
    );
  }

  // --- DEĞİŞİKLİK: _buildCardImage metodu artık 3 durumu da işleyecek şekilde güncellendi ---
  Widget _buildCardImage(BuildContext context, {required bool isOngoing, required bool isUpcoming}) {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: festival.coverImageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.image, size: 80, color: Colors.grey),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Text(
            festival.nameEn,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ),
        // --- YENİ AKILLI ETİKETLEME MANTIĞI ---
        Positioned(
          top: 12,
          right: 12,
          child: Builder( // Builder widget'ı kullanarak koşullu mantığı temizliyoruz
            builder: (context) {
              if (isOngoing) {
                return _buildStatusTag(context, text: 'LIVE NOW', color: Colors.red.shade600);
              }
              if (isUpcoming) {
                return _buildStatusTag(context, text: 'UPCOMING', color: Colors.green.shade600);
              }
              // Geçmiş festivaller için etiket göstermiyoruz,
              // çünkü zaten tüm kart soluk görünecek.
              return const SizedBox.shrink(); // Boş widget
            },
          ),
        )
      ],
    );
  }

  // --- DEĞİŞİKLİK: _buildCardInfo metodu artık "PAST" yazısını göstermeyecek ---
  // Çünkü bu bilgi artık tüm kartın soluk olmasıyla veriliyor, daha şık bir çözüm.
  Widget _buildCardInfo(BuildContext context, String dateText, {required bool isPast}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoChip(context, icon: Icons.location_on_outlined, label: festival.cityName),
                const SizedBox(height: 8),
                _infoChip(context, icon: Icons.calendar_today_outlined, label: dateText),
              ],
            ),
          ),
          // "PAST" yazısını buradan kaldırıyoruz
          if (!isPast)
            const Icon(Icons.arrow_forward_ios, color: Colors.grey)
          else
            // Geçmiş festivallerin yanında ok yerine bir saat ikonu gösterebiliriz
            Icon(Icons.history, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _infoChip(BuildContext context, {required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }
}