// lib/models/food_tip_model.dart

class FoodTip {
  final String foodDisplayName; // Örn: "Adana Kebap"
  final String tip;             // Örn: "Yanında şalgam suyu istemeyi unutma!"

  FoodTip({required this.foodDisplayName, required this.tip});
}