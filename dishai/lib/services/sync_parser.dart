// YENİ DOSYA: lib/services/sync_parser.dart

// Bu fonksiyonlar, ana UI thread'i dışında, ayrı bir Isolate'ta çalışacak.
// Bu yüzden class içinde değil, dosyanın en üst seviyesinde olmalılar.

import '../models/food_details.dart';
import '../models/city_model.dart';
import '../models/city_food_model.dart';
import '../models/route_model.dart';
import '../models/route_stop_model.dart';

// Gelen ham veriyi FoodDetails listesine çevirir.
List<FoodDetails> parseFoods(List<dynamic> data) {
  return data.map((item) => FoodDetails.fromJson(item)).toList();
}

// Gelen ham veriyi City listesine çevirir.
List<City> parseCities(List<dynamic> data) {
  return data.map((item) => City.fromMap(item)).toList();
}

// Gelen ham veriyi CityFood listesine çevirir.
List<CityFood> parseCityFoods(List<dynamic> data) {
  return data.map((item) => CityFood.fromMap(item)).toList();
}

// Gelen ham veriyi RouteModel listesine çevirir.
List<RouteModel> parseRoutes(List<dynamic> data) {
  return data.map((item) => RouteModel.fromMap(item)).toList();
}

// Gelen ham veriyi RouteStop listesine çevirir.
List<RouteStop> parseRouteStops(List<dynamic> data) {
  return data.map((item) => RouteStop.fromMap(item)).toList();
}