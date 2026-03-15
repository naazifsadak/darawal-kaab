import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:darawalkaab/l10n/app_localizations.dart';

import '../providers/user_provider.dart';
import 'jump_post_feed_screen.dart';
import 'services/service_list_screen.dart';
import '../models/service_place.dart';
import '../services/location_service.dart';
import '../services/google_places_service.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  LatLng _initialPosition = const LatLng(
    2.046934,
    45.318162,
  ); // Mogadishu default

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Set<Marker> _markers = {};

  Future<void> _fetchMapMarkers(LatLng loc) async {
    final googlePlaces = GooglePlacesService();
    // Fetch both gas stations and repair shops for the map
    final gasStations = await googlePlaces.fetchNearbyPlaces(
      loc.latitude,
      loc.longitude,
      ServiceType.gasStation,
      radius: 10000,
    );
    final repairShops = await googlePlaces.fetchNearbyPlaces(
      loc.latitude,
      loc.longitude,
      ServiceType.repairShop,
      radius: 2000,
    );

    if (!mounted) return;

    setState(() {
      _markers = [...gasStations, ...repairShops].map((place) {
        return Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude, place.longitude),
          infoWindow: InfoWindow(title: place.name, snippet: place.address),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            place.type == ServiceType.gasStation
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueBlue,
          ),
        );
      }).toSet();
    });
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      if (!mounted) return;
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialPosition, zoom: 14.0),
        ),
      );
      _fetchMapMarkers(_initialPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[500];

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset:
          false, // Prevent map from squishing when keyboard opens
      body: Stack(
        children: [
          // 1. Map Layer (Full Screen Background)
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 14.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // Custom button if needed
              zoomControlsEnabled: false,
              markers: _markers,
            ),
          ),

          // 2. Content Layer (Header + Flowing Icons)
          // Content Layer (Header + Flowing Icons)
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Blue Header Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          70,
                          24,
                          30,
                        ), // Slightly reduced top padding
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E88E5), // Main Blue
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Hug content
                          children: [
                            // Top Right Profile Picture
                            Align(
                              alignment: Alignment.topRight,
                              child: Consumer<UserProvider>(
                                builder: (context, userProvider, _) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ProfileScreen(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundImage:
                                            userProvider.imageProvider,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 5),

                            Text(
                              AppLocalizations.of(context)!.welcomeMessage,
                              style: GoogleFonts.poppins(
                                fontSize: 26, // Slightly reduced
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.findNearbyServices,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Search Bar
                            Container(
                              height: 45, // Slightly reduced
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              alignment: Alignment.centerLeft,
                              child: TextField(
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                                decoration: InputDecoration(
                                  icon: Icon(
                                    Icons.search,
                                    color: Colors.blue[700],
                                    size: 22,
                                  ),
                                  hintText: AppLocalizations.of(
                                    context,
                                  )!.searchRepairShops,
                                  hintStyle: GoogleFonts.poppins(
                                    color: hintColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Grid Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ServiceListScreen(
                                                title: AppLocalizations.of(
                                                  context,
                                                )!.repairShops,
                                                type: ServiceType.repairShop,
                                                userLocation: _initialPosition,
                                              ),
                                        ),
                                      );
                                    },
                                    child: _buildServiceCard(
                                      color: const Color(
                                        0xFF1565C0,
                                      ), // Darker Blue
                                      icon: Icons.build,
                                      label: AppLocalizations.of(
                                        context,
                                      )!.findRepairShops,
                                      rotateIcon: true,
                                      height: 90, // Slightly reduced
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ServiceListScreen(
                                                title: AppLocalizations.of(
                                                  context,
                                                )!.gasStations,
                                                type: ServiceType.gasStation,
                                                userLocation: _initialPosition,
                                              ),
                                        ),
                                      );
                                    },
                                    child: _buildServiceCard(
                                      color: const Color(0xFF43A047), // Green
                                      icon: Icons.local_gas_station,
                                      label: AppLocalizations.of(
                                        context,
                                      )!.findGasStations,
                                      height: 90,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Jump Post Button
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const JumpPostFeedScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: 80, // Slightly reduced
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF6C00), // Orange
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_a_photo,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.jumpPostRoadConditions,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category Buttons Row (Nearby, Top Rated, Offers)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 20.0,
                          bottom: 20.0,
                        ), // Space from header
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMapItem(
                              icon: Icons.location_on,
                              color: Colors.blue,
                              label: AppLocalizations.of(context)!.nearby,
                              isPin: true,
                            ),
                            _buildMapItem(
                              icon: Icons.star,
                              color: const Color(0xFFEF6C00), // Orange
                              label: AppLocalizations.of(context)!.topRated,
                            ),
                            _buildMapItem(
                              icon: Icons.local_offer,
                              color: Colors.blue,
                              label: AppLocalizations.of(context)!.offers,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // My Location Fab (pushed to bottom underneath the scroll view)
              Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 20),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    backgroundColor: cardColor,
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required Color color,
    required IconData icon,
    required String label,
    bool rotateIcon = false,
    double height = 100,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: rotateIcon ? -0.5 : 0,
            child: Icon(icon, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapItem({
    required IconData icon,
    required Color color,
    required String label,
    bool isPin = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isPin) {
          _getCurrentLocation();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1565C0),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              shadows: [
                const Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
