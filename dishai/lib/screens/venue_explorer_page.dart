// Lütfen bu dosyanın içeriğini projenizdeki lib/screens/venue_explorer_page.dart dosyasıyla tamamen değiştirin.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/city_model.dart';
import '../models/food_details.dart';
import '../services/database_helper.dart';
import '../services/places_service.dart';

// -----------------------------------------------------------------------------
// ÖNEMLİ: Google Cloud Platform'dan aldığın API anahtarını buraya yapıştır.
const String GOOGLE_API_KEY = "AIzaSyAELUVYZwhbFA5XCmmo_K59v44R36_do8U";
// -----------------------------------------------------------------------------

class VenueExplorerPage extends StatefulWidget {
  final City city;
  final bool showAllTurkishFoods;

  const VenueExplorerPage({
    super.key,
    required this.city,
    this.showAllTurkishFoods = false,
  });

  @override
  State<VenueExplorerPage> createState() => _VenueExplorerPageState();
}

class _VenueExplorerPageState extends State<VenueExplorerPage> {
  late Future<List<FoodDetails>> _foodsFuture;
  FoodDetails? _selectedFood;
  
  final PlacesService _placesService = PlacesService(apiKey: GOOGLE_API_KEY);
  List<PlaceSearchResult>? _venues;
  bool _isLoadingVenues = false;
  String? _errorMessage;

 @override
void initState() {
  super.initState();
  if (widget.showAllTurkishFoods) {
    _foodsFuture = _getAllFoods();
  } else {
    _foodsFuture = _getFoodsForCity();
  }
}

  Future<List<FoodDetails>> _getFoodsForCity() async {
    final foodNames = await DatabaseHelper.instance.getFoodNamesForCity(widget.city.id);
    List<FoodDetails> foods = [];
    for (var name in foodNames) {
      final details = await DatabaseHelper.instance.getFoodByName(name);
      if (details != null) {
        foods.add(details);
      }
    }
    foods.sort((a, b) => a.turkishName.compareTo(b.turkishName));
    return foods;
    
  }
  Future<List<FoodDetails>> _getAllFoods() async {
    final foods = await DatabaseHelper.instance.getAllFoods();
    return foods;
  }

  // <-- ADIM 3'ÜN UYGULANDIĞI YER BURASI -->
// venue_explorer_page.dart içinde

Future<void> _onFoodSelected(FoodDetails food) async {
  setState(() {
    _selectedFood = food;
    _isLoadingVenues = true;
    _errorMessage = null;
    _venues = null;
  });

  try {
    final position = await _placesService.getCurrentLocation();
    
    // DEĞİŞİKLİK BURADA: findRestaurants metodunu isimlendirilmiş parametreler ile çağırıyoruz.
    final results = await _placesService.findRestaurants(
      foodName: food.turkishName,    // "foodName:" eklendi
      foodCategory: food.foodCategory,   // "foodCategory:" eklendi
      position: position             // "position:" eklendi
    );

    setState(() {
      _venues = results;
    });
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
    });
  } finally {
    setState(() {
      _isLoadingVenues = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Places in ${widget.city.cityName}'),
        backgroundColor: Colors.teal.shade300,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFoodSelectionHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              _selectedFood == null
                  ? "Select a dish above to see nearby places"
                  : "Nearby places for ${_selectedFood!.turkishName}:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
          ),
          Expanded(child: _buildVenueList()),
        ],
      ),
    );
  }

  Widget _buildFoodSelectionHeader() {
    return Material(
      elevation: 2,
      color: Colors.white,
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: FutureBuilder<List<FoodDetails>>(
          future: _foodsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No dishes found for this city."));
            }
            final foods = snapshot.data!;
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
                final isSelected = _selectedFood?.name == food.name;
                return GestureDetector(
                  onTap: () => _onFoodSelected(food),
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.teal : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (food.imageUrl != null && food.imageUrl!.isNotEmpty) ? CachedNetworkImageProvider(food.imageUrl!) : null,
                            child: (food.imageUrl == null || food.imageUrl!.isEmpty) ? const Icon(Icons.ramen_dining) : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          food.turkishName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.teal : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildVenueList() {
    if (_isLoadingVenues) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "An error occurred:\n$_errorMessage\n\nPlease check your location services and internet connection.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      );
    }

    if (_selectedFood == null) {
      return Center(child: Icon(Icons.touch_app_outlined, size: 50, color: Colors.grey.shade400));
    }
    
    if (_venues == null) {
        return const SizedBox.shrink(); 
    }

    if (_venues!.isEmpty) {
      return const Center(child: Text("No restaurants found nearby for this dish."));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      itemCount: _venues!.length,
      itemBuilder: (context, index) {
        final venue = _venues![index];
        return GoogleVenueCard(
          venue: venue,
          placesService: _placesService,
        );
      },
    );
  }
}

class GoogleVenueCard extends StatelessWidget {
  final PlaceSearchResult venue;
  final PlacesService placesService;

  const GoogleVenueCard({
    super.key, 
    required this.venue,
    required this.placesService,
  });

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(venue.name)}&query_place_id=${venue.placeId}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (venue.photoReference != null)
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: placesService.getPhotoUrl(venue.photoReference!),
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.storefront, size: 60, color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(venue.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (venue.address != null)
                  Text(
                    venue.address!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                const SizedBox(height: 8),
                if (venue.rating != null)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        venue.rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
              ],
            ),
          ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 4.0).copyWith(bottom: 4),
             child: TextButton.icon(
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Get Directions'),
                onPressed: () => _launchURL(googleMapsUrl),
              ),
           ),
        ],
      ),
    );
  }
}