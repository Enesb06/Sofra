// GÜNCELLENMİŞ DOSYA: lib/models/quest_model.dart

// Bir görevin tamamlanması için gereken kuralı tanımlar.
// Artık hem kategoriye hem de şehre göre kural tanımlayabilir.
class QuestRule {
  final String? category; // Hedeflenen yemek kategorisi (örn: 'kebab')
  final String? cityName; // Hedeflenen şehir adı (örn: 'Gaziantep')
  final int targetCount;  // Gerekli yemek sayısı

  const QuestRule({
    this.category,
    this.cityName,
    required this.targetCount,
  }) : assert(category != null || cityName != null, 'Rule must have at least a category or a city.');
  // assert, hem category hem de cityName'in aynı anda null olmasını engeller.
}

// Quest ve QuestProgress modellerinde hiçbir değişiklik yapmaya gerek yok.
// Onlar zaten bu esnek yapıyla çalışmaya hazırlar.
class Quest {
  final String id;
  final String title;
  final String description;
  final List<QuestRule> rules;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.rules,
  });

  int get totalTarget {
    return rules.fold(0, (sum, rule) => sum + rule.targetCount);
  }
}

class QuestProgress {
  final Quest quest;
  final int currentProgress;
  final bool isCompleted;

  QuestProgress({
    required this.quest,
    required this.currentProgress,
  }) : isCompleted = currentProgress >= quest.totalTarget;
}