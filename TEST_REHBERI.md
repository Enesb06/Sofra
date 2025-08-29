# Sofra - Kullanıcı Rehberi ve Özellik Tanıtımı

Sayın Jüri Üyesi,  
Bu rehber, **Sofra uygulamasının** temel özelliklerini, yeteneklerini ve kullanıcıyı bir **"Lezzet Kaşifi"**ne dönüştüren oyunlaştırılmış yapısını test etmeniz için hazırlanmıştır.  

Sofra, statik bir yemek ansiklopedisi olmanın ötesinde, sizi **Türkiye'nin zengin mutfak kültüründe** bir maceraya çıkaran interaktif bir yol arkadaşıdır.

---

## ⚠️ Projenin Mevcut Durumu Hakkında Bilgilendirme
Uygulama aktif geliştirme aşamasındadır. Testleriniz sırasında aşağıdaki noktaları göz önünde bulundurmanızı rica ederiz:

- **İçerik:** 10 şehir ve bu şehirlere ait yüzlerce yemek bulunmaktadır.  
- **Gurme Rotaları:** Bu özellik şu anda sadece **Ankara** şehri için hazırlanmış rotalar içermektedir.  

---

## 1. Kurulum ve İlk Açılış

### 1.1. APK Dosyasını İndirme
1. Projenin ana **README.md** dosyasında bulunan **"Uygulamayı İndir (Google Drive)"** linkine tıklayın.  
2. Açılan Google Drive sayfasında, indirme ikonuna (sağ üstteki aşağı ok) basın.  
3. Google, **"Bu dosya için virüs taraması yapılamıyor"** uyarısı gösterebilir. Bu standarttır.  
4. **"Yine de indir" (Download anyway)** seçeneğine basarak **Sofra-v1.0.apk** dosyasını Android cihazınıza indirin.  

### 1.2. Uygulamayı Yükleme (Kurulum)
1. İndirme tamamlandıktan sonra, telefonunuzun bildirim panelinden veya **"Dosyalarım"** uygulamasından indirilen **Sofra-v1.0.apk** dosyasına dokunun.  
2. Android, güvenlik nedeniyle **"bilinmeyen kaynaklardan uygulama yüklemeye"** karşı uyarabilir. Bu uyarıya izin verin veya **Ayarlar**’dan etkinleştirin.  
3. **"Yükle"** butonuna basarak kurulumu tamamlayın.  

### 1.3. İlk Açılış ve Senkronizasyon
- Uygulamayı açın. Ana Sayfa'da bir **yükleme iskeleti (skeleton)** göreceksiniz.  
- Bu sırada uygulama, **güncel gastronomi verilerini** (yemekler, şehirler, rotalar vb.) senkronize eder.  
- Senkronizasyon tamamlandığında, Ana Sayfa içeriği otomatik olarak dolacaktır.  

---

## 2. Uygulamanın Özellikleri ve Kullanım Adımları
Uygulama, **Ana Sayfa** ve **alt navigasyon çubuğundaki modüller** üzerine kuruludur:

---

### 🏠 Özellik 1: Dinamik Ana Sayfa (Erişim Paneli)
Uygulamanın açılış ekranı, size ilham vermek ve yolculuğunuzu özetlemek için tasarlanmış oyunlaştırılmış bir **kontrol merkezidir**.  

**Nasıl Kullanılır ve Ne Test Edilmeli:**  
- **Öne Çıkan Lezzetler:**  
  - En üstteki büyük ve kaydırılabilir kartları inceleyin.  
  - Kartın üzerine tıklayarak **yemeğin detay sayfasına** gidin.  
  - Kartın altındaki **şehir etiketine** (örn: "Kayseri") tıklayarak, uygulamanın sizi doğrudan o şehrin seçili olduğu **Discover (Keşfet)** sekmesine yönlendirdiğini teyit edin.  

- **Eylem Merkezi ve Yolculuğunuz:**  
  - **Add Memory:** Oyun döngüsünü başlatan en önemli butondur.  
  - **Journal:** Eklediğiniz tüm anıları şık bir defter formatında gösterir.  
  - **Favorites:** Favorilediğiniz yemekleri listeler.  
  - **Achievements:** Görevlerinizi, rozetlerinizi ve genel istatistiklerinizi içerir.  

- **Sıradaki Göreviniz (Your Next Quest):**  
  - Bu dinamik kart, aktif görevinizi ve ilerlemenizi gösterir.  
  - Lütfen bir anı ekledikten sonra **ilerleme çubuğunun anında güncellendiğini** gözlemleyin.  

- **Anında Ödüllendirme:**  
  - Bir anı ekleyerek bir görevi tamamlamayı veya bir rozet kazanmayı deneyin.  
  - Örn: **3 farklı şehirden anı ekleyerek "Regional Traveler" rozetini kazanın**.  
  - Ekranda beliren **animasyonlu tebrik diyalogunu** test edin.  

---

### 🏆 Özellik 2: Oyunlaştırılmış Keşif Döngüsü (Temel Deneyim)
Uygulamanın kalbi, sizi sürekli keşfetmeye teşvik eden basit bir döngü üzerine kuruludur:  

1. **Deneyimleyin:** Gerçek hayatta bir yemeği tadın.  
2. **Kaydedin (En Önemli Eylem):**  
   Ana Sayfa'daki **"Add Memory"** butonuna basarak tattığınız yemeği **Lezzet Pasaportunuza** kaydedin.  
3. **Ödüllendirilin:**  
   Anınızı kaydettiğiniz anda **"Your Next Quest"** kartının güncellendiğini gözlemleyin.  
   Eğer bir görev tamamlarsanız veya rozet kazanırsanız, ekranda anında bir **tebrik mesajı** belirecektir.  
4. **İlerlemenizi Görün:**  
   **Achievements** butonuna basarak kişisel gastronomi müzenizi ve başarılarınızı inceleyin.  

---

### 🗺️ Özellik 3: İnteraktif Keşif (Discover Sekmesi)
Bir şehri **chatbot yardımıyla keşfetmenizi** sağlar.  

**Nasıl Kullanılır:**  
1. Alt çubuktan **Discover** sekmesine dokunun.  
2. Türkiye haritası üzerinden keşfetmek istediğiniz bir şehre (örn: **Ankara**) tıklayın.  
3. Chatbot size o şehrin en meşhur yerel lezzetlerini sunar.  
4. **📍 Find places for local food** butonuna basarak, konumunuza en yakın restoranları listeleyen **Mekan Kaşifi** sayfasını açın.  

---

### 📸 Özellik 4: Yapay Zeka ile Yemek Tanıma (Recognize Sekmesi)
Gördüğünüz bir yemeğin ne olduğunu **anında öğrenmenizi** sağlar.  

**Nasıl Kullanılır:**  
1. Alt çubuktan **Recognize** sekmesine dokunun.  
2. Kamera ikonuna basın ve galerinizden yöresel bir Türk yemeği fotoğrafı seçin.  
3. Yapay zeka modeli fotoğrafı analiz eder ve sonucu **sohbet ekranında** sunar.  
> Not: Şu an geliştirilme aşamasında, en meşhur **25 Türk yemeğini** tanımaktadır (lahmacun, iskender, baklava, yaprak sarma vb.).  

---

### 📝 Özellik 5: Menü Tercümanı (Scan Menu Sekmesi)
Menüleri anlamanızı sağlayan **kişisel çevirmeninizdir**.  

**Nasıl Kullanılır:**  
1. Alt çubuktan **Scan Menu** sekmesine dokunun.  
2. Kamerayı menüye odaklayın.  
3. **Scan Menu** butonuna basın ve uygulamanın tanıdığı yemekleri listelemesini izleyin.  

---

### 🧭 Özellik 6: Kürate Edilmiş Gurme Rotaları (Routes Sekmesi)
Sizin için özenle hazırlanmış **tematik lezzet turlarını** sunar.  

**Nasıl Kullanılır:**  
1. Alt çubuktan **Routes** sekmesine dokunun.  
   _(Şu anda sadece Ankara rotaları listelenecektir.)_  
2. İlgilendiğiniz bir rota kartına tıklayın.  
3. Açılan arayüzde, harita üzerindeki rota çizgisini ve özel durak etiketlerini inceleyin.  
4. Bilgi panelini yukarı kaydırarak **rota detaylarını** ve **durak listesini** görüntüleyin.  

---

## 🎯 Son Not
Uygulamayı test ederken keyifli bir deneyim yaşamanızı dileriz.  
Projemizin mevcut durumu ve potansiyeli hakkında vereceğiniz **geri bildirimler bizim için çok değerlidir.**  
