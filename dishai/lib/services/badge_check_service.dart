// GÜNCELLENMİŞ VE TAM DOSYA: lib/services/badge_check_service.dart

import 'package:flutter/material.dart';
import '../models/badge_model.dart' as app_badge;
import '../models/quest_model.dart';
import '../services/badge_service.dart';
import '../services/database_helper.dart';
import '../services/quest_service.dart';

class BadgeCheckService {
  /// Journal güncellendikten sonra çağrılacak ana metot.
  /// Artık tüm rozet türlerini kontrol eder.
  static Future<void> checkAndAwardBadges(BuildContext context) async {
    // 1. Gerekli tüm verileri topla
    final tastedInfo = await DatabaseHelper.instance.getTastedFoodInfoForQuests();
    final unlockedBadgeIds = await DatabaseHelper.instance.getUnlockedBadgeIds();
    // YENİ: İstatistikleri de çekiyoruz
    final stats = await DatabaseHelper.instance.getTastedFoodStats();
    final totalDishes = stats['totalDishes'] ?? 0;
    final totalCities = stats['citiesVisited'] ?? 0;

    // 2. Tamamlanan görev sayılarını hesapla (bu kısım aynı kalıyor)
    final completedCategoryQuests = _countCompletedQuests(app_badge.BadgeRequirementType.questsByCategory, tastedInfo);
    final completedCityQuests = _countCompletedQuests(app_badge.BadgeRequirementType.questsByCity, tastedInfo);

    // 3. Kazanılacak yeni rozet var mı diye kontrol et (YENİ KONTROLLER EKLENDİ)
    List<app_badge.Badge> newlyUnlockedBadges = [];
    for (final badge in BadgeService.allBadges) {
      // Eğer bu rozet daha önce kazanılmamışsa...
      if (!unlockedBadgeIds.contains(badge.id)) {
        bool badgeUnlocked = false;
        
        // ...ve kazanma koşulları şimdi sağlanıyorsa...
        switch (badge.requirementType) {
          case app_badge.BadgeRequirementType.questsByCategory:
            if (completedCategoryQuests >= badge.requiredCount) badgeUnlocked = true;
            break;
          case app_badge.BadgeRequirementType.questsByCity:
            if (completedCityQuests >= badge.requiredCount) badgeUnlocked = true;
            break;
          case app_badge.BadgeRequirementType.totalDishesTasted:
            if (totalDishes >= badge.requiredCount) badgeUnlocked = true;
            break;
          case app_badge.BadgeRequirementType.citiesVisited:
            if (totalCities >= badge.requiredCount) badgeUnlocked = true;
            break;
        }

        if (badgeUnlocked) {
          newlyUnlockedBadges.add(badge);
        }
      }
    }

    // 4. Eğer yeni kazanılan rozetler varsa, sırayla kaydet ve göster (bu kısım aynı kalıyor)
    if (newlyUnlockedBadges.isNotEmpty && context.mounted) {
      for (final badge in newlyUnlockedBadges) {
        await DatabaseHelper.instance.addUserBadge(badge.id);
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _BadgeUnlockedDialog(badge: badge),
          );
        }
      }
    }
  }

  /// Belirli bir türdeki (kategori veya şehir) tamamlanmış görev sayısını döndürür.
  /// Bu metotta hiçbir değişiklik yok.
  static int _countCompletedQuests(app_badge.BadgeRequirementType type, List<TastedFoodInfo> tastedInfo) {
    int count = 0;
    final questsToCheck = QuestService.allQuests.where((q) {
      final rule = q.rules.first;
      if (type == app_badge.BadgeRequirementType.questsByCategory) return rule.category != null;
      if (type == app_badge.BadgeRequirementType.questsByCity) return rule.cityName != null;
      return false;
    }).toList();

    for (final quest in questsToCheck) {
      if (QuestService.isQuestCompleted(quest, tastedInfo)) {
        count++;
      }
    }
    return count;
  }
}

/// Rozet kazanıldığında gösterilecek olan şık diyalog penceresi.
/// Bu widget'ta hiçbir değişiklik yok.
class _BadgeUnlockedDialog extends StatelessWidget {
  final app_badge.Badge badge;
  const _BadgeUnlockedDialog({required this.badge});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(badge.unlockedAssetPath, width: 120, height: 120),
            const SizedBox(height: 20),
            const Text(
              'Congratulations!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve unlocked the "${badge.title}" badge!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
             const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Awesome!'),
            )
          ],
        ),
      ),
    );
  }
}