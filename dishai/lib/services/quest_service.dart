// GÜNCELLENMİŞ VE TAM DOSYA: lib/services/quest_service.dart (Şehir Görevleri Eklendi)

import '../models/quest_model.dart';
import '../services/database_helper.dart'; // TastedFoodInfo için import edildi

class QuestService {
  // Uygulamadaki tüm görevlerin listesi.
  // Önce Şehir Gurmesi görevleri, sonra Kategori Uzmanı görevleri.
  static final List<Quest> allQuests = [
    // --- YENİ: ŞEHİR GURMESİ GÖREVLERİ ---
    const Quest(
      id: 'gaziantep_gourmet',
      title: 'Gaziantep Gourmet',
      description: 'Taste and log 3 different local dishes from Gaziantep.',
      rules: [
        QuestRule(cityName: 'Gaziantep', targetCount: 3),
      ],
    ),
    const Quest(
      id: 'hatay_explorer',
      title: 'Hatay Explorer',
      description: 'Discover 3 unique flavors from Hatay\'s rich cuisine.',
      rules: [
        QuestRule(cityName: 'Hatay', targetCount: 3),
      ],
    ),
      const Quest(
      id: 'ankara_local',
      title: 'Ankara Local',
      description: 'Taste 2 classic dishes from the capital city.',
      rules: [
        QuestRule(cityName: 'Ankara', targetCount: 2),
      ],
    ),
    const Quest(
      id: 'sanliurfa_pilgrim',
      title: 'Şanlıurfa Pilgrim',
      description: 'Taste 3 authentic dishes from the city of prophets.',
      rules: [
        QuestRule(cityName: 'Şanlıurfa', targetCount: 3),
      ],
    ),
     const Quest(
      id: 'bursa_connoisseur',
      title: 'Bursa Connoisseur',
      description: 'Enjoy 2 of Bursa\'s most famous dishes.',
      rules: [
        QuestRule(cityName: 'Bursa', targetCount: 2),
      ],
    ),
    const Quest(
      id: 'trabzon_voyager',
      title: 'Trabzon Voyager',
      description: 'Explore the Black Sea flavors by tasting 3 Trabzon dishes.',
      rules: [
        QuestRule(cityName: 'Trabzon', targetCount: 3),
      ],
    ),
    const Quest(
      id: 'kayseri_taster',
      title: 'Kayseri Taster',
      description: 'Log 2 famous dishes from Kayseri, the home of pastırma.',
      rules: [
        QuestRule(cityName: 'Kayseri', targetCount: 2),
      ],
    ),
    const Quest(
      id: 'erzurum_adventurer',
      title: 'Erzurum Adventurer',
      description: 'Brave the cold and taste 2 of Erzurum\'s hearty dishes.',
      rules: [
        QuestRule(cityName: 'Erzurum', targetCount: 2),
      ],
    ),
     const Quest(
      id: 'mersin_local',
      title: 'Mersin Local',
      description: 'Taste 2 local specialties from Mersin.',
      rules: [
        QuestRule(cityName: 'Mersin', targetCount: 2),
      ],
    ),
      const Quest(
      id: 'izmir_fan',
      title: 'İzmir Fan',
      description: 'Taste 3 of İzmir\'s light and delicious dishes.',
      rules: [
        QuestRule(cityName: 'İzmir', targetCount: 3),
      ],
    ),

    // --- MEVCUT: KATEGORİ UZMANI GÖREVLERİ ---
    const Quest(
      id: 'kebab_expert',
      title: 'Kebab Expert',
      description: 'Taste and log 3 different types of kebabs.',
      rules: [
        QuestRule(category: 'kebab', targetCount: 3),
      ],
    ),
    const Quest(
      id: 'soup_lover',
      title: 'Soup Lover',
      description: 'Warm up by tasting 4 different traditional soups.',
      rules: [
        QuestRule(category: 'soup', targetCount: 4),
      ],
    ),
    const Quest(
      id: 'dessert_connoisseur',
      title: 'Dessert Connoisseur',
      description: 'Indulge in 5 different Turkish desserts.',
      rules: [
        QuestRule(category: 'dessert', targetCount: 5),
      ],
    ),
    const Quest(
      id: 'street_food_specialist',
      title: 'Street Food Specialist',
      description: 'Log 3 different classic street foods.',
      rules: [
        QuestRule(category: 'street_food', targetCount: 3),
      ],
    ),
    const Quest(
      id: 'pastry_pro',
      title: 'Pastry Pro',
      description: 'Log 4 dishes from bakeries (pide, lahmacun etc).',
      rules: [
        QuestRule(category: 'pastry_bakery', targetCount: 4),
      ],
    ),
    const Quest(
      id: 'seafood_savant',
      title: 'Seafood Savant',
      description: 'Taste 3 different seafood dishes.',
      rules: [
        QuestRule(category: 'seafood', targetCount: 3),
      ],
    ),
    const Quest(
      id: 'breakfast_champion',
      title: 'Breakfast Champion',
      description: 'Try 3 different Turkish breakfast items.',
      rules: [
        QuestRule(category: 'breakfast', targetCount: 3),
      ],
    ),
    const Quest(
      id: 'meze_maestro',
      title: 'Meze Maestro',
      description: 'Log 5 different types of mezes/appetizers.',
      rules: [
        QuestRule(category: 'appetizer_meze', targetCount: 5),
      ],
    ),
  ];

  /// Dashboard'da gösterilecek bir sonraki tamamlanmamış görevi bulur.
  /// Eğer hepsi tamamlandıysa, ilk görevi gösterir.
  static Quest getNextUncompletedQuest(List<TastedFoodInfo> tastedInfo) {
    for (final quest in allQuests) {
      if (!_isQuestCompleted(quest, tastedInfo)) {
        return quest;
      }
    }
    // Eğer tüm görevler tamamlanmışsa, varsayılan olarak ilk görevi göster.
    return allQuests.first;
  }

  /// Bir görevin tamamlanıp tamamlanmadığını kontrol eden özel yardımcı metot.
  static bool _isQuestCompleted(Quest quest, List<TastedFoodInfo> tastedInfo) {
      int progressCount = calculateProgressForQuest(quest, tastedInfo);
      return progressCount >= quest.totalTarget;
  }

  /// Bir görevin ilerlemesini, hem kategori hem de şehir kurallarını dikkate alarak
  /// hesaplayan merkezi ve yeniden kullanılabilir metot.
  static int calculateProgressForQuest(Quest quest, List<TastedFoodInfo> tastedInfo) {
      int progressCount = 0;
      for (final rule in quest.rules) {
        int countForRule = 0;
        if (rule.category != null) {
          // Kategori kuralı için sayım yap
          countForRule = tastedInfo.where((info) => info.category == rule.category).length;
        } else if (rule.cityName != null) {
          // Şehir kuralı için sayım yap
          countForRule = tastedInfo.where((info) => info.cityName == rule.cityName).length;
        }
        progressCount += countForRule.clamp(0, rule.targetCount);
      }
      return progressCount;
  }
}