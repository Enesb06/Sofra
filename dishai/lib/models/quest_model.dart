// lib/models/quest_model.dart

// Bir görevin tamamlanması için gereken kuralı tanımlar.
// Örneğin: 'kebab' kategorisinden 3 adet yemek.
class QuestRule {
  final String category; // Hedeflenen yemek kategorisi (örn: 'kebab')
  final int targetCount; // Gerekli yemek sayısı (örn: 3)

  const QuestRule({required this.category, required this.targetCount});
}

// Bir görevin tüm bilgilerini içeren ana model.
class Quest {
  final String id;
  final String title;
  final String description; // Arayüzde gösterilecek görev tanımı
  final List<QuestRule> rules;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.rules,
  });

  // Toplam hedef sayısını hesaplayan yardımcı metot.
  int get totalTarget {
    return rules.fold(0, (sum, rule) => sum + rule.targetCount);
  }
}

// Kullanıcının bir görevdeki mevcut ilerlemesini tutan model.
class QuestProgress {
  final Quest quest;
  final int currentProgress;
  final bool isCompleted;

  QuestProgress({
    required this.quest,
    required this.currentProgress,
  }) : isCompleted = currentProgress >= quest.totalTarget;
}