// GÜNCELLENMİŞ DOSYA: lib/screens/festival_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/festival_model.dart';

class FestivalDetailPage extends StatelessWidget {
  final Festival festival;

  const FestivalDetailPage({super.key, required this.festival});

  // URL'leri güvenli bir şekilde açmak için yardımcı metot (Değişiklik yok)
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('Could not launch $urlString');
    }
  }

  // Google Haritalar'da konumu açmak için yardımcı metot (Değişiklik yok)
  void _launchMaps() {
    if (festival.locationCoordinates != null && festival.locationCoordinates!.isNotEmpty) {
      final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${festival.locationCoordinates}';
      _launchURL(googleMapsUrl);
    }
  }
  
    @override
  Widget build(BuildContext context) {
    final String dateRange = '${DateFormat.yMMMMd('en_US').format(festival.startDate)} - ${DateFormat.yMMMMd('en_US').format(festival.endDate)}';
    
    return Scaffold(
      // --- DEĞİŞİKLİK BURADA: AppBar'ı tema ile uyumlu hale getiriyoruz ---
      appBar: AppBar(
        // Başlığa "Festival Details" gibi genel bir metin ekleyebiliriz.
        // Veya festivalin adını göstermek için: title: Text(festival.nameEn),
        title: const Text('Festival Details'), 
        // backgroundColor ve elevation satırlarını siliyoruz.
        // Bu sayede main.dart'taki temamızdan turuncu rengi otomatik olarak alacak.
      ),
      // --- BİTTİ ---
      body: SingleChildScrollView(
        // İçerikte hiçbir değişiklik yapmıyoruz, olduğu gibi kalıyor.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: festival.coverImageUrl,
              width: double.infinity,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                festival.nameEn,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Date',
                    content: dateRange,
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    title: 'City',
                    content: festival.cityName,
                  ),
                  const Divider(height: 40, thickness: 1),

                  _SectionHeader(title: 'About the Festival'),
                  const SizedBox(height: 12),
                  Text(
                    festival.descriptionEn,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Bu alt widget'larda hiçbir değişiklik yok, olduğu gibi kalıyorlar.
  Widget _buildActionButtons() {
    bool hasWebsite = festival.officialWebsiteUrl != null && festival.officialWebsiteUrl!.isNotEmpty;
    bool hasLocation = festival.locationCoordinates != null && festival.locationCoordinates!.isNotEmpty;

    if (!hasWebsite && !hasLocation) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (hasLocation)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.map_outlined),
              label: const Text('View on Map'),
              onPressed: _launchMaps,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (hasWebsite && hasLocation)
          const SizedBox(width: 16),
        if (hasWebsite)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.public_outlined),
              label: const Text('Official Website'),
              onPressed: () => _launchURL(festival.officialWebsiteUrl!),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoRow({required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}