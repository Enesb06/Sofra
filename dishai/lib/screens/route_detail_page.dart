// lib/screens/route_detail_page.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/database_helper.dart';
import '../models/route_model.dart';
import '../models/route_stop_model.dart';

class RouteDetailPage extends StatefulWidget {
  final RouteModel route;
  const RouteDetailPage({super.key, required this.route});

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  late Future<List<RouteStop>> _stopsFuture;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng _initialCameraPosition = const LatLng(39.9334, 32.8597);

  @override
  void initState() {
    super.initState();
    _stopsFuture = _loadStops();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  Future<List<RouteStop>> _loadStops() async {
    final stops = await DatabaseHelper.instance.getStopsForRoute(widget.route.id);
    if (stops.isNotEmpty) {
      await _setupMarkers(stops);
      if (mounted) {
        setState(() {
          _createPolyline(stops);
          _fitBounds(stops);
        });
      }
    }
    return stops;
  }

  Future<BitmapDescriptor> _createMarkerBitmap(String stopNumber, String venueName) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Size size = const Size(280, 140);

    final MarkerPainter painter = MarkerPainter(stopNumber, venueName);
    painter.paint(canvas, size);

    final ui.Image markerImage = await pictureRecorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<void> _setupMarkers(List<RouteStop> stops) async {
    final Set<Marker> markers = {};
    for (var stop in stops) {
      final BitmapDescriptor customIcon = await _createMarkerBitmap(
        stop.stopNumber.toString(),
        stop.venueName,
      );

      markers.add(
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: customIcon,
          anchor: const Offset(0.5, 0.8),
          onTap: () {
            _goToStop(stop);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers.addAll(markers);
      });
    }
  }

  void _createPolyline(List<RouteStop> stops) {
    final List<LatLng> polylineCoordinates = stops
        .map((stop) => LatLng(stop.latitude, stop.longitude))
        .toList();

    final Polyline routePolyline = Polyline(
      polylineId: const PolylineId('route_line'),
      color: const Color(0xFF6366F1),
      width: 4,
      points: polylineCoordinates,
      patterns: [
        PatternItem.dash(25.0),
        PatternItem.gap(8.0),
      ],
    );

    _polylines.add(routePolyline);
  }
  
  Future<void> _fitBounds(List<RouteStop> stops) async {
    if (stops.isEmpty || !_mapController.isCompleted) return;
    
    final controller = await _mapController.future;
    
    if (stops.length == 1) {
      final stop = stops.first;
      controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(stop.latitude, stop.longitude), 15.0));
    } else {
      double minLat = stops.first.latitude, maxLat = stops.first.latitude;
      double minLng = stops.first.longitude, maxLng = stops.first.longitude;

      for (var stop in stops) {
        if (stop.latitude < minLat) minLat = stop.latitude;
        if (stop.latitude > maxLat) maxLat = stop.latitude;
        if (stop.longitude < minLng) minLng = stop.longitude;
        if (stop.longitude > maxLng) maxLng = stop.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60.0));
    }
  }

  Future<void> _goToStop(RouteStop stop) async {
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(stop.latitude, stop.longitude), zoom: 16.0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Map section - fixed height
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            child: _buildMapSection(),
          ),
          // Details section - scrollable
          Expanded(
            child: _buildDetailsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(target: _initialCameraPosition, zoom: 12.0),
          onMapCreated: (controller) {
            if (!_mapController.isCompleted) {
              _mapController.complete(controller);
            }
          },
          markers: _markers,
          polylines: _polylines,
          padding: const EdgeInsets.only(top: 100),
          style: '''[
            {
              "featureType": "poi",
              "elementType": "labels.text",
              "stylers": [{"visibility": "off"}]
            },
            {
              "featureType": "poi.business",
              "stylers": [{"visibility": "off"}]
            },
            {
              "featureType": "road",
              "elementType": "labels.icon",
              "stylers": [{"visibility": "off"}]
            }
          ]''',
        ),
        // Gradient overlay at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Back button
        Positioned(
          top: 50.0,
          left: 20.0,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF1F2937),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            
            // Duration info
            _buildDurationInfo(),
            
            // Divider
            Container(
              margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.shade200,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.route.descriptionEn,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Stops section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Route Stops",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Stops list
            _buildStopsList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }



  Widget _buildDurationInfo() {
    final List<Widget> durationChips = [];
    
    // SADECE 'travel' verisi varsa, onu kullanarak çip oluşturuyoruz.
    if (widget.route.travelWalkingMins != null) {
      durationChips.add(_buildSimpleDurationChip(
        icon: Icons.directions_walk,
        label: "Walking",
        duration: widget.route.travelWalkingMins!,
        color: const Color(0xFF10B981),
      ));
    }
    if (widget.route.travelDrivingMins != null) {
      durationChips.add(_buildSimpleDurationChip(
        icon: Icons.directions_car,
        label: "Driving",
        duration: widget.route.travelDrivingMins!,
        color: const Color(0xFFEF4444),
      ));
    }
    // Gelecekte transit eklenirse diye burası da hazır.
    if (widget.route.travelTransitMins != null) {
      durationChips.add(_buildSimpleDurationChip(
        icon: Icons.directions_bus,
        label: "Transit",
        duration: widget.route.travelTransitMins!,
        color: const Color(0xFF3B82F6),
      ));
    }

    if (durationChips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.alt_route_outlined, // İkonu 'yol' ile değiştirdik
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Travel Times", // Başlığı güncelledik
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // LayoutBuilder hala hizalama ve eşit genişlik için görev başında.
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              const double spacing = 8.0;
              final int chipCount = durationChips.length > 0 ? durationChips.length : 1;
              final double chipWidth = (totalWidth - (spacing * (chipCount - 1))) / chipCount;
              
              return Wrap(
                spacing: spacing,
                runSpacing: 8.0,
                children: durationChips.map((chip) {
                  return SizedBox(
                    width: chipWidth,
                    child: chip,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // YENİ VE SADELEŞTİRİLMİŞ ÇİP WIDGET'I
  Widget _buildSimpleDurationChip({
    required IconData icon,
    required String label,
    required int duration,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // İçeriği ortala
        children: [
          // Renkli kutu içindeki ikon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          // Dikey Metin Grubu (Label ve Süre)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '$duration min',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
// ... (dosyanın geri kalan tüm metotları aynı kalacak)
  
  Widget _buildStopsList() {
    return FutureBuilder<List<RouteStop>>(
      future: _stopsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading stops",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.location_off, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No stops found',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }
        
        final stops = snapshot.data!;
        
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stops.length,
          separatorBuilder: (context, index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 1,
            color: Colors.grey.shade100,
          ),
          itemBuilder: (context, index) {
            final stop = stops[index];
            final isLast = index == stops.length - 1;
            
            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 24 : 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _goToStop(stop),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              stop.stopNumber.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.venueName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stop.stopNotesEn,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class MarkerPainter extends CustomPainter {
  final String stopNumber;
  final String venueName;

  MarkerPainter(this.stopNumber, this.venueName);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final RRect shadowRect = RRect.fromLTRBR(2, 2, size.width + 2, size.height - 18, const Radius.circular(22));
    canvas.drawRRect(shadowRect, shadowPaint);

    final Paint gradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height - 20));
    
    final RRect rrect = RRect.fromLTRBR(0, 0, size.width, size.height - 20, const Radius.circular(20));
    canvas.drawRRect(rrect, gradientPaint);

    final Path path = Path();
    path.moveTo(size.width / 2 - 15, size.height - 20);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width / 2 + 15, size.height - 20);
    path.close();
    canvas.drawPath(path, gradientPaint);

    final Paint circleShadow = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(const Offset(42, 42), 27, circleShadow);
    
    final Paint circlePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(40, 40), 25, circlePaint);
    
    final TextPainter numberPainter = TextPainter(
      text: TextSpan(
        text: stopNumber,
        style: const TextStyle(
          fontSize: 24,
          color: Color(0xFF6366F1),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    numberPainter.layout();
    numberPainter.paint(canvas, Offset(40 - numberPainter.width / 2, 40 - numberPainter.height / 2));

    final TextPainter namePainter = TextPainter(
      text: TextSpan(
        text: venueName,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    namePainter.layout(maxWidth: size.width - 90);
    namePainter.paint(canvas, const Offset(80, 25));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}