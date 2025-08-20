// lib/screens/route_detail_page.dart

import 'dart:async';


import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../services/database_helper.dart';
import '../models/route_model.dart';
import '../models/route_stop_model.dart';

class RouteDetailPage extends StatefulWidget {
  final RouteModel route;
  const RouteDetailPage({super.key, required this.route});

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final PanelController _panelController = PanelController();
  late Future<List<RouteStop>> _stopsFuture;
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng _initialCameraPosition = const LatLng(39.9334, 32.8597);

  @override
  void initState() {
    super.initState();
    _stopsFuture = _loadStops();
    
    // Animatik ipucunu, sayfa yüklendikten kısa bir süre sonra başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPanelHint();
    });
  }

  void _showPanelHint() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_panelController.isPanelClosed && mounted) {
      await _panelController.animatePanelToPosition(
        0.4,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (_panelController.panelPosition >= 0.39 && _panelController.panelPosition <= 0.41 && mounted) {
      await _panelController.close();
    }
  }

  Future<List<RouteStop>> _loadStops() async {
    final stops = await DatabaseHelper.instance.getStopsForRoute(widget.route.id);
    if (stops.isNotEmpty) {
      if (mounted) {
        setState(() {
          _setupMarkers(stops);
          _createPolyline(stops);
          _fitBounds(stops);
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
          onTap: () {
            if (_panelController.isPanelClosed) {
              _panelController.open();
            }
          },
        ),
      );
    }
    _markers.addAll(markers);
  }

  void _createPolyline(List<RouteStop> stops) {
    final List<LatLng> polylineCoordinates = stops
        .map((stop) => LatLng(stop.latitude, stop.longitude))
        .toList();

    final Polyline routePolyline = Polyline(
      polylineId: const PolylineId('route_line'),
      color: Colors.deepOrange,
      width: 5,
      points: polylineCoordinates,
      patterns: [
        PatternItem.dash(20.0),
        PatternItem.gap(10.0),
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
    if (_panelController.isPanelClosed) {
      _panelController.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        controller: _panelController,
        minHeight: MediaQuery.of(context).size.height * 0.35,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        parallaxEnabled: true,
        parallaxOffset: .5,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        body: _buildMapSection(),
        panel: _buildSlidingPanelContent(),
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
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.30, top: 80),
        ),
        Positioned(
          top: 40.0,
          left: 20.0,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlidingPanelContent() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_up, size: 20, color: Colors.grey),
                  SizedBox(width: 4),
                  Text("More Details", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    widget.route.titleEn,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDurationInfo(),
                const Divider(height: 32, indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    widget.route.descriptionEn,
                    style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "Stops on this Route",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStopsList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

    if (durationChips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        alignment: WrapAlignment.start,
        children: durationChips,
      ),
    );
  }

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
  
  Widget _buildStopsList() {
    return FutureBuilder<List<RouteStop>>(
      future: _stopsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
        if (snapshot.hasError) return Center(child: Text("Error loading stops: ${snapshot.error}"));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No stops found.')));
        
        final stops = snapshot.data!;
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stops.length,
          itemBuilder: (context, index) {
            final stop = stops[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade400,
                child: Text(stop.stopNumber.toString(), style: const TextStyle(color: Colors.white)),
              ),
              title: Text(stop.venueName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(stop.stopNotesEn),
              onTap: () => _goToStop(stop),
            );
          },
        );
      },
    );
  }
}