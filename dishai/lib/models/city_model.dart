class City {
  final int id;
  final String cityName;
  final String normalizedCityName;

  City({
    required this.id,
    required this.cityName,
    required this.normalizedCityName,
  });

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'],
      cityName: map['city_name'],
      normalizedCityName: map['normalized_city_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city_name': cityName,
      'normalized_city_name': normalizedCityName,
    };
  }
}