// YENİ DOSYA: lib/services/badge_service.dart

import '../models/badge_model.dart';

class BadgeService {
  static final List<Badge> allBadges = [
    // --- KATEGORİ ROZETLERİ ---
    const Badge(
      id: 'food_initiate',
      title: 'Food Initiate',
      description: 'Complete your first 3 flavor quests in any category.',
      lockedAssetPath: 'assets/images/badges/locked.png', // Bu görselleri eklemen gerekecek
      unlockedAssetPath: 'assets/images/badges/food_initiate.png',
      requirementType: BadgeRequirementType.questsByCategory,
      requiredCount: 3,
    ),
    const Badge(
      id: 'category_master',
      title: 'Category Master',
      description: 'Master all quests in a single food category.',
      lockedAssetPath: 'assets/images/badges/locked.png',
      unlockedAssetPath: 'assets/images/badges/category_master.png',
      requirementType: BadgeRequirementType.questsByCategory,
      requiredCount: 8, // Toplam 8 kategori görevimiz var.
    ),

    // --- ŞEHİR ROZETLERİ ---
    const Badge(
      id: 'city_explorer',
      title: 'City Explorer',
      description: 'Complete the gourmet quests for 5 different cities.',
      lockedAssetPath: 'assets/images/badges/locked.png',
      unlockedAssetPath: 'assets/images/badges/city_explorer.png',
      requirementType: BadgeRequirementType.questsByCity,
      requiredCount: 5,
    ),
    const Badge(
      id: 'city_conqueror',
      title: 'City Conqueror',
      description: 'Become a gourmet in all 10 featured cities.',
      lockedAssetPath: 'assets/images/badges/locked.png',
      unlockedAssetPath: 'assets/images/badges/city_conqueror.png',
      requirementType: BadgeRequirementType.questsByCity,
      requiredCount: 10,
    ),
      const Badge(
      id: 'novice_taster',
      title: 'Novice Taster',
      description: 'Taste and log 10 different dishes.',
      lockedAssetPath: 'assets/images/badges/locked.png',
      unlockedAssetPath: 'assets/images/badges/novice_taster.png',
      requirementType: BadgeRequirementType.totalDishesTasted,
      requiredCount: 10,
    ),
    const Badge(
      id: 'seasoned_epicure',
      title: 'Seasoned Epicure',
      description: 'Taste and log 25 different dishes.',
      lockedAssetPath: 'assets/images/badges/locked.png',
      unlockedAssetPath: 'assets/images/badges/seasoned_epicure.png',
      requirementType: BadgeRequirementType.totalDishesTasted,
      requiredCount: 25,
    ),
    const Badge(
      id: 'legendary_glutton',
      title: 'Legendary Glutton',
      description: 'Taste and log 50 different dishes. A true legend!',
      lockedAssetPath: 'assets/images/badges/locked.png',
      unlockedAssetPath: 'assets/images/badges/legendary_glutton.png',
      requirementType: BadgeRequirementType.totalDishesTasted,
      requiredCount: 50,
    ),

    // --- YENİ: GEZGİN ROZETLERİ ---
     const Badge(
      id: 'regional_traveler',
      title: 'Regional Traveler',
      description: 'Log memories from 3 different cities.',
      lockedAssetPath: 'assets/images/badges/locked.png',
      unlockedAssetPath: 'assets/images/badges/regional_traveler.png',
      requirementType: BadgeRequirementType.citiesVisited,
      requiredCount: 3,
    ),
     const Badge(
      id: 'cross_country_voyager',
      title: 'Cross-Country Voyager',
      description: 'Log memories from 7 different cities.',
      lockedAssetPath: 'assets/images/badges/locked.png',
      unlockedAssetPath: 'assets/images/badges/cross_country_voyager.png',
      requirementType: BadgeRequirementType.citiesVisited,
      requiredCount: 7,
    ),
    const Badge(
      id: 'culinary_ambassador',
      title: 'Culinary Ambassador',
      description: 'Log memories from 15 different cities. You are a true envoy!',
      lockedAssetPath: 'assets/images/badges/locked.png',
      unlockedAssetPath: 'assets/images/badges/culinary_ambassador.png',
      requirementType: BadgeRequirementType.citiesVisited,
      requiredCount: 15,
    ),
  ];
}