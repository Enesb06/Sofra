# Sofra - Kullanıcı Rehberi ve Özellik Tanıtımı

Sayın Jüri Üyesi,

Bu rehber, **Sofra** uygulamasının yeni Ana Sayfa (Dashboard) tasarımıyla birlikte, temel özelliklerini ve yeteneklerini test etmeniz için hazırlanmıştır.

### **⚠️ Projenin Mevcut Durumu Hakkında Bilgilendirme**

Uygulama aktif geliştirme aşamasındadır. Testleriniz sırasında aşağıdaki noktaları göz önünde bulundurmanızı rica ederiz:

*   **İçerik: **10 şehir** ve bu şehirlere ait yüzlerce yemek bulunmaktadır.
*   **Gurme Rotaları:** Bu özellik şu anda sadece **Ankara** şehri için hazırlanmış 3 farklı rota içermektedir.

### **1. Kurulum ve İlk Açılış**

1.  GitHub deposunun **"Releases"** bölümünden `Sofra-v1.0.apk` dosyasını Android cihazınıza indirin ve kurun.
2.  Uygulama ilk açılışta, yeni Ana Sayfa'da bir **yükleme iskeleti (skeleton)** göreceksiniz. Bu sırada uygulama, Supabase'den güncel gastronomi verilerini (yemekler, şehirler, rotalar vb.) senkronize etmektedir.
3.  Senkronizasyon tamamlandığında, Ana Sayfa içeriği otomatik olarak dolacaktır. İnternet bağlantısı yoksa, bir hata ekranı ile karşılaşılacaktır.

### **2. Uygulamanın Özellikleri ve Kullanım Adımları**

Uygulama, yeni Ana Sayfa ve alt navigasyon çubuğundaki diğer modüller üzerine kuruludur:

#### **🏠 Özellik 1: Dinamik Ana Sayfa (Dashboard)**

Uygulamanın yeni açılış ekranı, size ilham vermek ve yolculuğunuzu özetlemek için tasarlanmıştır.

*   **Nasıl Kullanılır ve Ne Test Edilmeli:**
    1.  **Öne Çıkan Lezzetler:** En üstteki büyük ve kaydırılabilir kartları inceleyin.
        *   Kartın üzerine tıklayarak yemeğin **detay sayfasına** gidin.
        *   Kartın altındaki **şehir etiketine** (örn: "Ankara") tıklayarak, uygulamanın sizi doğrudan o şehrin seçili olduğu **Discover (Keşfet) sekmesine** yönlendirdiğini teyit edin.
    2.  **Lezzet Pasaportu Özeti:** **"Your Culinary Journey"** (Lezzet Yolculuğunuz) bölümünde tattığınız toplam yemek ve ziyaret ettiğiniz şehir sayısını gösteren istatistikleri inceleyin.

#### **🗺️ Özellik 2: İnteraktif Keşif & Lezzet Pasaportu (Discover Sekmesi)**

Bir şehri chatbot yardımıyla keşfetmenizi ve anılarınıza hızla ulaşmanızı sağlar.

*   **Nasıl Kullanılır:**
    1.  Alt çubuktan **"Discover"** sekmesine dokunun.
    2.  Türkiye haritası üzerinden keşfetmek istediğiniz bir şehre (örn: **Ankara**) tıklayın.
    3.  Chatbot size önce o şehrin en meşhur yerel lezzetlerini sunacaktır.
    4.  **Lezzet Pasaportu Kısayolu:** Keşif yaparken, sağ üst köşede bulunan **kitap ikonuna** dokunarak favorilerinize ve anı defterinize anında erişim sağlayabildiğinizi teyit edin.
    5.  **Akıllı Mekan Arama:** Chatbot'un sunduğu **"📍 Find places for local food"** (Yerel lezzetler için mekan bul) butonuna basarak, konumunuza en yakın restoranları listeleyen **Mekan Kaşifi** sayfasını açın.

#### **📸 Özellik 3: Yapay Zeka ile Yemek Tanıma (Recognize Sekmesi)**

Bu modül, gördüğünüz bir yemeğin ne olduğunu anında öğrenmenizi sağlar.

*   **Nasıl Kullanılır:**
    1.  Alt çubuktan **"Recognize"** sekmesine dokunun.
    2.  Alttaki **kamera ikonuna** basın ve galerinizden yöresel bir Türk yemeği fotoğrafı seçin.
    3.  Yapay zeka modeli fotoğrafı analiz eder ve sonucu bir sohbet ekranında size sunar.
    Not:Şu an geliştirilme aşamasında olduğu için en meşhur 25 türk yemeğini tanıyor.(lahmacun,iskender,baklava,yaprak sarma vs.)

#### **MENU Özellik 4: Menü Tercümanı (Scan Menu Sekmesi)**

Bu modül, menüleri anlamanızı sağlayan kişisel çevirmeninizdir.

*   **Nasıl Kullanılır:**
    1.  Alt çubuktan **"Scan Menu"** sekmesine dokunun.
    2.  Kamerayı, metinleri net görünecek şekilde bir menüye odaklayın. (Test için bilgisayar ekranınızda şu linki açabilirsiniz: `https://i.ibb.co/680320f/istanbul-esnaf.jpg`)
    3.  **"Scan Menu"** butonuna basın ve uygulamanın tanıdığı yemekleri listelemesini izleyin.

#### **🧭 Özellik 5: Kürate Edilmiş Gurme Rotaları (Routes Sekmesi)**

Sizin için özenle hazırlanmış tematik lezzet turlarını sunar.

*   **Nasıl Kullanılır:**
    1.  Alt çubuktan **"Routes"** sekmesine dokunun. (Şu anda sadece **Ankara** rotaları listenecektir).
    2.  İlgilendiğiniz bir rotanın kartına tıklayın.
    3.  Açılan modern arayüzde, harita üzerindeki **rota çizgisini** ve **özel durak etiketlerini** inceleyin.
    4.  Alttaki **bilgi panelini yukarı kaydırarak** rotanın tüm detaylarını ve durak listesini görüntüleyin.


Uygulamayı test ederken keyifli bir deneyim yaşamanızı dileriz. Projemizin mevcut durumu ve potansiyeli hakkında vereceğiniz geri bildirimler bizim için çok değerlidir.
