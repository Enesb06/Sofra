// YENİ DOSYA: lib/models/badge_model.dart

// Bir rozetin nasıl kazanılacağını tanımlayan kural.
enum BadgeRequirementType {
  questsByCategory, // Belirli bir kategorideki görevleri tamamla
  questsByCity,     // Şehir görevlerini tamamla
   totalDishesTasted, // <-- YENİ
  citiesVisited,     // <-- YENİ
}

// Bir rozetin tüm bilgilerini içeren ana model.
class Badge {
  final String id;
  final String title;
  final String description;
  final String lockedAssetPath; // Kilitli rozet görseli
  final String unlockedAssetPath; // Kilidi açılmış rozet görseli

  // Rozetin kazanılma koşulu:
  final BadgeRequirementType requirementType;
  final int requiredCount; // Gerekli görev sayısı
  final String? targetCategory; // questsByCategory için gerekli

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.lockedAssetPath,
    required this.unlockedAssetPath,
    required this.requirementType,
    required this.requiredCount,
    this.targetCategory,
  });
}