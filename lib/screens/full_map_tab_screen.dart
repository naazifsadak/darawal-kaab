import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/service_place.dart';
import '../../services/google_places_service.dart';
import '../../services/location_service.dart';
import 'services/service_detail_screen.dart';

class FullMapTabScreen extends StatefulWidget {
  const FullMapTabScreen({super.key});

  @override
  State<FullMapTabScreen> createState() => _FullMapTabScreenState();
}

class _FullMapTabScreenState extends State<FullMapTabScreen> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(
    2.046934,
    45.318162,
  ); // Mogadishu center
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initMapData();
  }

  Future<void> _initMapData() async {
    final loc = await LocationService().getCurrentLocation();
    if (loc != null) {
      if (mounted) {
        setState(() {
          _initialPosition = LatLng(loc.latitude, loc.longitude);
        });
      }
    }

    final placesService = GooglePlacesService();

    // Fetch both gas stations and repair shops
    final gasStations = await placesService.fetchNearbyPlaces(
      _initialPosition.latitude,
      _initialPosition.longitude,
      ServiceType.gasStation,
      radius: 10000,
    );

    final repairShops = await placesService.fetchNearbyPlaces(
      _initialPosition.latitude,
      _initialPosition.longitude,
      ServiceType.repairShop,
      radius: 10000,
    );

    if (!mounted) return;

    setState(() {
      _markers = [...gasStations, ...repairShops].map((place) {
        return Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude, place.longitude),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.address,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(place: place),
                ),
              );
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            place.type == ServiceType.gasStation
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueBlue,
          ),
        );
      }).toSet();
      _isLoading = false;
    });

    // Animate camera to user location if the map is ready
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialPosition, zoom: 14.0),
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!_isLoading) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialPosition, zoom: 14.0),
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    final loc = await LocationService().getCurrentLocation();
    if (loc != null && _mapController != null) {
      final latLng = LatLng(loc.latitude, loc.longitude);
      setState(() {
        _initialPosition = latLng;
      });
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 15.0),
        ),
      );
      // Re-fetch data around new location
      _initMapData();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Service Map",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
          ),

          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Loading Map Data..."),
                    ],
                  ),
                ),
              ),
            ),

          // Floating Location Button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'fullMapLocationBtn',
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // Legend
          Positioned(
            top: 20,
            left: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 12, height: 12, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          "Gas Stations",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 12, height: 12, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          "Repair Shops",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
