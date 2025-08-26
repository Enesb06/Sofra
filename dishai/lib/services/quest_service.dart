// lib/services/quest_service.dart

import '../models/quest_model.dart';

class QuestService {
  // Uygulamadaki tüm görevlerin listesi.
  static final List<Quest> allQuests = [
    const Quest(
      id: 'kebab_expert',
      title: 'Kebab Expert',
      description: 'Taste and log 3 different types of kebabs.',
      rules: [
        QuestRule(category: 'kebab', targetCount: 3),
      ],
    ),
    const Quest(
      id: 'sweet_tooth',
      title: 'Sweet Tooth',
      description: 'Try 2 syrup-based and 1 milk-based dessert.',
      rules: [
        QuestRule(category: 'dessert', targetCount: 3), // Şimdilik basit tutalım, ileride detaylandırabiliriz.
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
      id: 'pastry_pro',
      title: 'Pastry Pro',
      description: 'Log 3 different dishes from bakeries (pide, lahmacun etc).',
      rules: [
        QuestRule(category: 'pastry_bakery', targetCount: 3),
      ],
    ),
  ];

  // Şimdilik kullanıcıya her zaman ilk görevi vereceğiz.
  // Gelecekte buraya "kullanıcının tamamladığı görevleri atla, sıradakini ver"
  // gibi daha akıllı bir mantık eklenebilir.
  static Quest getCurrentQuestForUser() {
    // Bu mantığı daha sonra geliştirebiliriz. Şimdilik sabit.
    return allQuests.first; 
  }
}