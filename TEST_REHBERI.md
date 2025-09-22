# Sofra - Kullanıcı Rehberi ve Özellik Tanıtımı

Sayın Jüri Üyesi,  

Sofra, Türkiye'ye gelen turistler için tasarlanmış kapsamlı bir dijital gastronomi elçisidir. Amacımız, zengin Türk mutfak kültürünü interaktif ve oyunlaştırılmış bir deneyimle tanıtmak, aynı zamanda gezginler için menüleri anlayan, lezzetleri tanıyan ve yeni tatlar keşfettiren akıllı bir rehber olmaktır. Bu uygulama, her tabağın arkasındaki hikayeyi anlatarak, bir yemek gezisini unutulmaz bir kültürel yolculuğa dönüştürmeyi hedefler.  

Bu rehber, Sofra uygulamasının temel özelliklerini, teknik yeteneklerini ve kullanıcıyı bir **"Lezzet Kaşifi"**ne dönüştüren oyunlaştırılmış yapısını adım adım test etmeniz için Türkçe olarak hazırlanmıştır. Uygulama arayüzü İngilizce olduğundan, ilgili buton ve metinlerin Türkçe karşılıkları parantez içinde belirtilmiştir.

---

## ⚠️ Projenin Mevcut Durumu Hakkında Bilgilendirme
Uygulama aktif geliştirme aşamasındadır. Testleriniz sırasında aşağıdaki noktaları göz önünde bulundurmanızı rica ederiz:

- **İçerik:** 11 şehir ve bu şehirlere ait yüzlerce yemek bulunmaktadır.  
- **Gurme Rotaları:** Bu özellik şu anda sadece **Ankara** şehri için hazırlanmış rotalar içermektedir.  

---

## 1. Kurulum ve İlk Açılış

### 1.1. APK Dosyasını İndirme
1. Lütfen Android telefonunuzdan projemizin reposunu açın.  
2. Projenin ana **README.md** dosyasında bulunan **"Uygulamayı İndir (Google Drive)"** linkine tıklayın.  
3. Açılan Google Drive sayfasında, indirme ikonuna (sağ üstteki aşağı ok) basın.  
4. Google, **"Bu dosya için virüs taraması yapılamıyor"** uyarısı gösterebilir. Bu standarttır.  
5. **"Yine de indir" (Download anyway)** seçeneğine basarak **Sofra-v1.0.apk** dosyasını Android cihazınıza indirin.  
6. ⚠️⚠️İndirme süreci yavaş olabilir, lütfen iptal etmeyin. Sabırla bekleyin, sorunsuz bir şekilde indirme süreci tamamlanacaktır.30-40 saniye ilerleme olmuyor ama arka planda uygulama telefonunuza indiriliyor lütfen iptal etmeyin⚠️⚠️

### 1.2. Uygulamayı Yükleme (Kurulum)
1. İndirme tamamlandıktan sonra, telefonunuzun bildirim panelinden veya **"Dosyalarım"** uygulamasından indirilen **Sofra-v1.0.apk** dosyasına dokunun.  
2. Android, güvenlik nedeniyle **"bilinmeyen kaynaklardan uygulama yüklemeye"** karşı uyarabilir. Bu uyarıya izin verin veya **Ayarlar**’dan etkinleştirin.  
3. **"Yükle"** butonuna basarak kurulumu tamamlayın.  

### 1.3. İlk Açılış ve Senkronizasyon
- Uygulamayı açın. Ana Sayfa'da bir **yükleme iskeleti (skeleton)** göreceksiniz.  
- Bu sırada uygulama, **güncel gastronomi verilerini** (yemekler, şehirler, rotalar vb.) senkronize eder.  
- Senkronizasyon tamamlandığında, Ana Sayfa içeriği otomatik olarak dolacaktır.  

---

## Bölüm 1: Lezzet Kaşifi Olmak
Uygulamanın kalbi, sizi sürekli keşfetmeye teşvik eden basit ve ödüllendirici bir döngü üzerine kuruludur. Lütfen aşağıdaki senaryoyu test ediniz:  

### 🏆 Temel Oyun Döngüsü Testi
- **Hayal Edin:** Herhangi bir Türk yemeğini (örneğin, Ankara'da Döner) yediğinizi varsayın.  
- **Kaydedin (En Önemli Eylem):**  
  Ana Sayfa'daki "Add Memory" (Anı Ekle) butonuna basın.  
  Açılan ekranda, yediğiniz yemeği (Döner) ve şehri (Ankara) aratarak seçin. Tarihi de belirleyip "Save Memory" (Anıyı Kaydet) butonuna basın.  
- **Anında Geri Bildirimi Gözlemleyin:**  
  Ana Sayfa'ya döndüğünüzde, "Your Next Quest" (Sıradaki Görevin) kartındaki ilerleme çubuğunun anında güncellendiğini teyit edin. Bu, Sinyal Tabanlı Reaktif mimarimizin bir sonucudur.  
- **Anı Defterinizi Görüntüleyin:**  
  Ana Sayfa'daki "Journal" (Anı Defteri) butonuna basın.  
  Az önce eklediğiniz Ankara'daki Döner anısının, şık bir defter formatında ilk sayfada göründüğünü teyit edin. Sayfalar arasında gezinmeyi deneyin.  
- **Ödüllendirme Anı:**  
  Bu işlemi 2 farklı şehirden daha yemek ekleyerek tekrarlayın (örn: İstanbul'dan Islak Burger, Gaziantep'ten Baklava).  
  Üçüncü anıyı eklediğiniz anda, "Regional Traveler" (Bölgesel Gezgin) rozetini kazandığınızı bildiren animasyonlu tebrik diyalogunun ekranda belirdiğini test edin.  
- **İlerlemenizi Keşfedin:**  
  "Achievements" (Başarımlar) butonuna basarak "Badges" (Rozetler) sekmesine geçin ve yeni kazandığınız rozetin artık renkli ve kilitsiz olduğunu görün. Kilitli bir rozete tıklayarak nasıl kazanılabileceği bilgisini içeren diyalogu test edin.  

---

## Bölüm 2: Modüllerin Detaylı Testi

### 🏠 2.1. Dinamik Ana Sayfa (Erişim Paneli)
- **Öne Çıkan Lezzetler (Featured Dishes):** En üstteki kaydırılabilir kartlardan birine (örneğin Mantı) tıklayın. Bu sizi bir sonraki test adımı olan Yemek Detay Sayfası'na götürecektir.  
- **Şehir Etiketiyle Yönlendirme:** Ana Sayfa'ya geri dönün. Kartın altındaki şehir etiketine (örn: "Kayseri") tıklayarak, uygulamanın sizi doğrudan o şehrin seçili olduğu Discover (Keşfet) sekmesine ışınladığını teyit edin.  

### 📖 2.2. Yemek Detay Sayfası: Gastronomi Ansiklopedisi
Bu sayfa, her yemeğin ruhunu ve detaylarını barındırır. Lütfen Ana Sayfa'dan bir yemeğe tıklayarak bu sayfayı açın ve aşağıdaki özellikleri test edin:  

- **Favorilere Ekleme:** Sağ üst köşedeki kalp ikonuna basarak yemeği favorilerinize eklemeyi ve çıkarmayı test edin.  
- **Telaffuz Yardımcısı:** Orta kısımdaki "Pronounce" (Telaffuz Et) butonuna basarak yemeğin isminin doğru okunuşunu dinleyin.  
- **Garsona Göster (Dil Bariyerini Aşma):** "Show to Waiter" (Garsona Göster) butonuna basın. Yemeğin adının ve fotoğrafının büyük, net ve dikkat dağıtmayan bir ekranda belirdiğini teyit edin. Bu ekran, dil bariyerini aşmak için tasarlanmıştır.  
- **Detaylı Bilgi Sekmeleri:**  
  - "Story & Origin" (Hikaye ve Köken): Yemeğin kültürel hikayesini okuyun.  
  - "Ingredients" (İçerik): Yemeğin malzemelerini ve alerjen bilgilerini (Gluten, Süt Ürünü, Kuruyemiş) kontrol edin.  
  - "Pairing" (Yanında Ne Gider): Yemekle birlikte hangi içeceklerin veya yan lezzetlerin iyi gittiğine dair tavsiyeleri inceleyin.  

---

## 🎉 Bölüm 3. Gastronomi Festivalleri (Festivals Sekmesi)

Uygulama, sadece yemekleri değil, aynı zamanda Türkiye’nin zengin gastronomi kültürünü kutlayan etkinlikleri de keşfetmenize yardımcı olur.  

### 📌 Ana Sayfa'dan 
Ana Sayfa’da **"Upcoming Festivals" (Yaklaşan Festivaller)** başlığı altında en yakın tarihte gerçekleşecek **4 gastronomi festivali ve etkinliği** kart formatında listelenir.İsterseniz merak ettiğiniz bir festival kartının üstüne basabilirsini isterseniz de See All butonuna basarak tüm festivalleri görebilirsiniz.

### 🎟️ Festival Kartı Özellikleri
- **Date (Tarih):** Festivalin gerçekleşeceği tarih bilgisi.
- **City (Şehir):** Festivalin gerçekleşeceği şehir.
- **About Festival (Festival Hakkında):** Etkinliğin kısa tanıtımı ve öne çıkan detaylar.
- **View on Map (Haritada Gör):** Festivalin konumunu haritada açarak kolayca ulaşmanızı sağlar.  
- **Official Website (Resmi Web Sitesi):** Daha fazla bilgi için festivalin resmi web sitesine yönlendirir.  

> Bu özellik sayesinde kullanıcılar, gezilerini planlarken gastronomik festivalleri de deneyimlerine dahil edebilir.

---
## 🗺️ Bölüm 4: İnteraktif Keşif (Discover - Keşfet Sekmesi)
Bu sekme, uygulamanın en akıllı özelliklerini barındırır. Lütfen aşağıdaki adımları sırasıyla takip edin:  

1. Alt navigasyon çubuğundan Discover (Keşfet) sekmesine dokunun. Harita üzerindeki "A Legacy of Flavor" (Bir Lezzet Mirası) atmosferini ve arka plan animasyonunu gözlemleyin.  
2. Haritadan Gaziantep'e tıklayın.  
3. **İçeriden İpucu (Insider Tip):** Şehri seçtiğinizde ekrana gelen "Insider Tip" penceresini test edin. Bu, o şehre özel, yerel halkın bildiği bir lezzet tavsiyesidir.  
4. **Chatbot Karşılaması:** Chatbot sizi karşılayacak ve Gaziantep'e özel yerel lezzetleri yatay bir listede sunacaktır.  
5. **Yemek Detaylarını Keşfetme:**  
   - Chatbot'un sunduğu yerel lezzetler listesindeki herhangi bir yemeğin üzerine (örneğin Baklava) dokunun.  
   - Yemeğin hikayesini, içeriğini ve telaffuzunu içeren Yemek Detay Sayfası'nın (Food Details Page) açıldığını teyit edin.  
   - Sağ üst köşedeki kalp ikonuna basarak yemeği favorilerinize eklemeyi test edin.  
6. **Chatbot Yetenekleri:**  
   - **Kültürel Derinlik:**  
     "ℹ️ More about Gaziantep" (Gaziantep Hakkında Daha Fazla Bilgi) → "Food Culture" (Yemek Kültürü).  
   - **Türkiye Mutfağını Keşfetme:**  
     "🇹🇷 Explore all Turkish Cuisine" (Tüm Türk Mutfağını Keşfet) → "🍰 Desserts" (Tatlılar).  
   - **Mekan Bulma (Venue Explorer):**  
     "📍 Find places..." (Mekan Bul...) → Google Places API ile yakın restoranları listeler.  

---

## 📸 Bölüm 5. Yapay Zeka ile Yemek Tanıma (Recognize - Tanı Sekmesi)
- **Modülü Başlatma:** Alt çubuktan Recognize (Tanı) sekmesine dokunun. Ortadaki kamera ikonuna basarak telefonunuzun galerisini açın.  
- **Fotoğraf Seçimi:** Galerinizden lahmacun, iskender, baklava veya yaprak sarma gibi belirgin bir Türk yemeği fotoğrafı seçin. Modelin en iyi sonuçları bu ikonik yemeklerde verdiğini göreceksiniz.  
- **Yapay Zeka Analizi:** Fotoğrafı seçtiğinizde, uygulamanın TensorFlow Lite modelini kullanarak yemeği tanımasını bekleyin. Bu işlem, internet bağlantısı gerektirmeden, tamamen cihaz üzerinde gerçekleşir ve birkaç saniye sürebilir.  
- **İnteraktif Sonuç Ekranı:** Model yemeği tanıdığında, ekranın statik bir sonuç yerine dinamik bir sohbet arayüzüne dönüştüğünü gözlemleyin. Chatbot'un size yemeğin ismini söylediğini ("It looks like you're having Lahmacun!") ve ne öğrenmek istediğinizi sorduğunu teyit edin.  
- **Detaylı Bilgi Alma:** Chatbot'un sunduğu butonları kullanarak yemek hakkında derinlemesine bilgi almayı test edin:  
  - "Story & Origin" (Hikaye ve Köken)  
  - "How to Pronounce?" (Nasıl Telaffuz Edilir?)  
  - Diğer seçenekler  

> Not: Yapay zeka modeli, projenin bu aşamasında en meşhur 25 Türk yemeğini yüksek doğrulukla tanımak üzere eğitilmiştir.  

---

## 📝 Bölüm 6. Menü Tercümanı (Scan Menu - Menü Tara Sekmesi)
1. Alt çubuktan Scan Menu (Menü Tara) sekmesine dokunun.  
2. Elinizde basılı bir menü varsa ona, yoksa internetten bulduğunuz bir Türk restoranı menüsünün ekran görüntüsüne kamerayı odaklayın.  
3. "Scan Menu" (Menüyü Tara) butonuna basın ve uygulamanın, menüdeki metinleri okuyup veritabanındaki yemeklerle eşleştirerek bir sonuç listesi oluşturduğunu gözlemleyin.  

---

## 🧭 Bölüm 7. Kürate Edilmiş Gurme Rotaları (Routes Sekmesi)
Sizin için özenle hazırlanmış **tematik lezzet turlarını** sunar.  

**Nasıl Kullanılır:**  
1. Alt çubuktan **Routes** sekmesine dokunun. _(Şu anda sadece Ankara rotaları listelenecektir.)_  
2. İlgilendiğiniz bir rota kartına tıklayın.  
3. Açılan arayüzde, harita üzerindeki rota çizgisini ve özel durak etiketlerini inceleyin.  
4. Bilgi panelini yukarı kaydırarak **rota detaylarını** ve **durak listesini** görüntüleyin.  

---

## 🎯 Son Not
Uygulamayı test ederken keyifli bir deneyim yaşamanızı dileriz.  
Projemizin mevcut durumu ve potansiyeli hakkında vereceğiniz **geri bildirimler bizim için çok değerlidir.**  
