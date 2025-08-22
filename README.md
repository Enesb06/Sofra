# Sofra 🍲 - Türkiye'nin Dijital Gastronomi Elçisi


**Sofra**, Türkiye'nin zengin mutfak mirasını ve kültürel hikayelerini, yapay zeka destekli modern teknolojilerle birleştirerek yerli ve yabancı turistlere sunan interaktif bir mobil gastronomi ve kültür rehberidir.

---

### **⚠️ Önemli Not**

Bu proje, **[Fikrim Gelecek: Gençler Arası Dijital Çözümler Yarışması  ]** kapsamında değerlendirilmek üzere geçici olarak "Public" (Herkese Açık) hale getirilmiştir. **Bu bir Açık Kaynak (Open Source) projesi değildir.** Yarışma değerlendirme sürecinin tamamlanmasının ardından bu repository "Private" (Özel) olarak güncellenecektir. Lütfen kaynak kodlarını yarışma değerlendirmesi amacı dışında kopyalamayınız veya dağıtmayınız.

---

## ✨ Projenin Ana Özellikleri

Sofra, kullanıcılarına dört ana deneyim sunan bütünsel bir platformdur:

| Özellik | Açıklama | Teknoloji |
| :--- | :--- | :--- |
| 📸 **Tanıma Akışı** | Galeriden seçilen bir yemek fotoğrafını yerel yapay zeka modeliyle tanır ve yemek hakkında detaylı bilgi sunar. | `tflite_flutter` |
| 🗺️ **Keşif Akışı** | Harita üzerinden seçilen bir şehrin gastronomik dünyasını, "Önce Şehir, Sonra Türkiye" mantığıyla çalışan bir chatbot ile keşfettirir. | `google_maps_flutter` |
| 📖 **Lezzet Pasaportu** | Kullanıcının favori yemeklerini ve fotoğraflı yemek anılarını kaydettiği kişisel gastronomi günlüğü. | `sqflite` |
| 🧭 **Gurme Rotaları** | Kürate edilmiş, tematik yeme-içme turlarını, arka planı tamamen kaplayan interaktif bir harita ve üzerinde kayan modern bir bilgi paneliyle sunar. | `sliding_up_panel`, `polyline` |

---

## 🚀 Teknik Detaylar ve Mimari

Proje, modern ve ölçeklenebilir bir mimari üzerine kurulmuştur.

*   **Platform:** Flutter & Dart
*   **Uzak Veri Tabanı:** Supabase (PostgreSQL)
*   **Yerel Veri Tabanı:** `sqflite` (Sürüm 12)
    *   **Çevrimdışı Yetenek:** Uygulamanın ana içerikleri (yemekler, şehirler, rotalar) ilk açılışta senkronize edilerek internetsiz kullanıma olanak tanır.
*   **API Entegrasyonları:** Google Places API (Akıllı Mekan Arama)
*   **State Management:** `StatefulWidget` (`setState`) ve `ValueNotifier` (Global senkronizasyon takibi için `SyncService`).
*   **Öne Çıkan Paketler:** `sliding_up_panel`, `google_maps_flutter`, `cached_network_image`, `tflite_flutter`, `google_mlkit_text_recognition`.

---

## 🏛️ Mimari Felsefe ve Stratejik Kararlar

*   **Hibrit Veri Stratejisi:** Gurme Rotaları'nın süreleri, API maliyetini sıfırlamak ve performansı en üst düzeye çıkarmak için bir kereliğine mahsus **Google Colab scripti** ile hesaplanmış ve Supabase'e statik olarak kaydedilmiştir. Bu, uygulamanın hızlı ve çevrimdışı çalışmasını garanti eder.
*   **Merkezi Senkronizasyon:** Tüm veri senkronizasyonu, uygulamanın ilk açılan sayfası üzerinden yönetilir. `SyncService`, senkronizasyon durumunu uygulama geneline bildirerek diğer sayfaların verinin hazır olmasını akıllıca beklemesini sağlar.
*   **Kullanıcı Odaklı Tasarım:** Geliştirme sürecinde "kullanıcı ne hisseder?" sorusu her zaman öncelikli olmuştur. `SlidingUpPanel`'e geçiş, özel harita etiketleri ve animatik ipuçları gibi özellikler bu felsefenin bir sonucudur.

---

## 🏃 Projeyi Değerlendirme İçin Çalıştırma

Jüri üyelerinin projeyi yerel makinelerinde kolayca çalıştırabilmeleri için gereken adımlar:

1.  **Flutter Kurulumu:** Flutter SDK'sının (versiyon 3.x.x) kurulu olduğundan emin olun.
2.  **Depoyu Klonlama:**
    ```bash
    git clone https://github.com/kullanici-adiniz/sofra-projesi.git
    cd sofra-projesi
    ```
3.  **Paketleri Yükleme:**
    ```bash
    flutter pub get
    ```
4.  **API Anahtarlarını Yapılandırma:**
    *   **Google Maps API Anahtarı:** `lib/services/places_service.dart` dosyasını açın ve `GOOGLE_API_KEY` değişkenine, değerlendirme için sağlanan Google Cloud API anahtarını girin.
    *   **Supabase Entegrasyonu:** `lib/main.dart` dosyasındaki `supabaseUrl` ve `supabaseAnonKey` değişkenlerinin doğru olduğundan emin olun.
    *   **Platform Yapılandırması:** Android (`AndroidManifest.xml`) ve iOS (`AppDelegate.swift`) için platforma özel API anahtarı yapılandırmalarının tamamlandığını kontrol edin.
5.  **Uygulamayı Çalıştırma:**
    ```bash
    flutter run
    ```

---
