// lib/screens/route_detail_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/database_helper.dart';
import '../models/route_model.dart';
import '../models/route_stop_model.dart';
import '../services/places_service.dart';
import 'venue_explorer_page.dart';

class RouteDetailPage extends StatefulWidget {
  final RouteModel route;
  const RouteDetailPage({super.key, required this.route});

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  late Future<List<RouteStop>> _stopsFuture;
  
  PlaceSearchResult? _selectedVenueDetails;
  bool _isVenueDetailsLoading = false;

  final Set<Marker> _markers = {};
  LatLng _initialCameraPosition = const LatLng(39.9334, 32.8597); // Ankara (varsayılan)

  @override
  void initState() {
    super.initState();
    _stopsFuture = _loadStops();
  }

  Future<List<RouteStop>> _loadStops() async {
    final stops = await DatabaseHelper.instance.getStopsForRoute(widget.route.id);
    if (stops.isNotEmpty) {
      if (mounted) {
        setState(() {
          _setupMarkers(stops);
          _initialCameraPosition = LatLng(stops.first.latitude, stops.first.longitude);
        });
      }
    }
    return stops;
  }

  void _setupMarkers(List<RouteStop> stops) {
    final markers = <Marker>{};
    for (var stop in stops) {
      markers.add(
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: stop.venueName,
            snippet: 'Stop ${stop.stopNumber}',
          ),
          onTap: () => _onMarkerTapped(stop),
        ),
      );
    }
    _markers.addAll(markers);
  }

  Future<void> _onMarkerTapped(RouteStop stop) async {
    if (!mounted) return;
    setState(() {
      _isVenueDetailsLoading = true;
      _selectedVenueDetails = null;
    });

    final venue = PlaceSearchResult(
      placeId: stop.googlePlaceId,
      name: stop.venueName,
      address: stop.stopNotesEn,
    );

    await Future.delayed(const Duration(milliseconds: 200)); 

    if (mounted) {
      setState(() {
        _selectedVenueDetails = venue;
        _isVenueDetailsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.route.descriptionEn,
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey.shade700),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildDurationInfo()),
          SliverToBoxAdapter(child: _buildMapSection()),
          SliverToBoxAdapter(child: _buildSelectedVenueCard()),
          _buildStopsList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.purple.shade300,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(widget.route.titleEn, style: const TextStyle(shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
        background: CachedNetworkImage(
          imageUrl: widget.route.coverImageUrl,
          fit: BoxFit.cover,
          color: Colors.black.withOpacity(0.4),
          colorBlendMode: BlendMode.darken,
        ),
      ),
    );
  }
  
  // =======================================================================
  // --- HATA BURADAYDI VE DÜZELTİLDİ ---
  // =======================================================================
  Widget _buildDurationInfo() {
    final List<Widget> durationChips = [];

    if (widget.route.durationWalkingMins != null && widget.route.travelWalkingMins != null) {
      durationChips.add(_buildDurationBreakdownChip(
        icon: Icons.directions_walk,
        totalDuration: widget.route.durationWalkingMins!,
        travelDuration: widget.route.travelWalkingMins!,
      ));
    }
    if (widget.route.durationTransitMins != null && widget.route.travelTransitMins != null) {
      durationChips.add(_buildDurationBreakdownChip(
        icon: Icons.directions_bus,
        totalDuration: widget.route.durationTransitMins!,
        travelDuration: widget.route.travelTransitMins!,
      ));
    }
    if (widget.route.durationDrivingMins != null && widget.route.travelDrivingMins != null) {
      durationChips.add(_buildDurationBreakdownChip(
        icon: Icons.directions_car,
        totalDuration: widget.route.durationDrivingMins!,
        travelDuration: widget.route.travelDrivingMins!,
      ));
    }

    // DÜZELTME: Eğer hiç çip yoksa, SliverToBoxAdapter yerine boş bir KUTU (SizedBox) döndürüyoruz.
    // Bu, üstteki SliverToBoxAdapter'ın içine boş bir kutu koymasını sağlar ve hatayı önler.
    if (durationChips.isEmpty) {
      return const SizedBox.shrink(); // <-- ESKİSİ: SliverToBoxAdapter(...) YENİSİ: SizedBox.shrink()
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        alignment: WrapAlignment.center,
        children: durationChips,
      ),
    );
  }
  // =======================================================================

  Widget _buildDurationBreakdownChip({ required IconData icon, required int totalDuration, required int travelDuration }) {
    final experienceDuration = totalDuration - travelDuration;
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      backgroundColor: Colors.purple.shade50,
      side: BorderSide(color: Colors.purple.shade100),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Colors.purple.shade800),
              const SizedBox(width: 8),
              Text(
                'Total: $totalDuration min',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.purple.shade900),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              '(Travel: $travelDuration min + Experience: $experienceDuration min)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMapSection() {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(target: _initialCameraPosition, zoom: 14.0),
          onMapCreated: (controller) => _mapController.isCompleted ? null : _mapController.complete(controller),
          markers: _markers,
        ),
      ),
    );
  }
  
  Widget _buildSelectedVenueCard() {
    if (_isVenueDetailsLoading) return const Center(heightFactor: 3, child: CircularProgressIndicator());
    if (_selectedVenueDetails == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text("Tap on a map marker to see details.", style: TextStyle(color: Colors.grey))),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_selectedVenueDetails!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_selectedVenueDetails!.address ?? "No notes.", style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsList() {
    return FutureBuilder<List<RouteStop>>(
      future: _stopsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SliverToBoxAdapter(child: Center(child: Text('No stops found.')));
        
        final stops = snapshot.data!;
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final stop = stops[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade400,
                child: Text(stop.stopNumber.toString(), style: const TextStyle(color: Colors.white)),
              ),
              title: Text(stop.venueName),
              subtitle: Text(stop.stopNotesEn),
              onTap: () async {
                final controller = await _mapController.future;
                controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(stop.latitude, stop.longitude), zoom: 16.0)));
                _onMarkerTapped(stop);
              },
            );
          }, childCount: stops.length),
        );
      },
    );
  }
}