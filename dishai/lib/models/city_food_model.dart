// GÜNCELLENMİŞ DOSYA: lib/models/city_food_model.dart

class CityFood {
  final int cityId;
  final String foodName;
  final String? insiderTipEn; // <-- YENİ ALAN: İpucunu tutacak nullable String

  CityFood({
    required this.cityId,
    required this.foodName,
    this.insiderTipEn, // <-- YENİ ALAN: Constructor'a eklendi
  });

  // Veritabanından gelen veriyi modele çevirirken 'insider_tip_en' alanını da okur.
  factory CityFood.fromMap(Map<String, dynamic> map) {
    return CityFood(
      cityId: map['city_id'],
      foodName: map['food_name'],
      insiderTipEn: map['insider_tip_en'], // <-- YENİ ALAN: Map'ten okunuyor
    );
  }

  // Modeli veritabanına yazmak için veriye çevirirken 'insider_tip_en' alanını da ekler.
  Map<String, dynamic> toMap() {
    return {
      'city_id': cityId,
      'food_name': foodName,
      'insider_tip_en': insiderTipEn, // <-- YENİ ALAN: Map'e ekleniyor
    };
  }
}