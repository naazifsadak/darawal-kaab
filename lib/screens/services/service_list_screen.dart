import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/service_place.dart';
import '../../widgets/glass_container.dart';
import '../../services/location_service.dart';
import '../../services/google_places_service.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import 'service_detail_screen.dart';
import 'map_screen.dart';
import 'package:darawalkaab/l10n/app_localizations.dart';

class ServiceListScreen extends StatefulWidget {
  final String title;
  final ServiceType type;
  final LatLng? userLocation;

  const ServiceListScreen({
    super.key,
    required this.title,
    required this.type,
    this.userLocation,
  });

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  bool _showMap = false;
  bool _isLoading = true;
  List<ServicePlace> _fetchedPlaces = [];
  late List<ServicePlace> _sortedPlaces;
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _lastFetchLocation;

  @override
  void initState() {
    super.initState();
    _sortedPlaces = [];
    _initData();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    final Uri appleMapsUrl = Uri.parse(
      "https://maps.apple.com/?daddr=$lat,$lng",
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl);
    } else {
      final Uri webUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
      );
      if (!await launchUrl(webUrl, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch maps');
      }
    }
  }

  Future<void> _initData() async {
    LatLng loc = widget.userLocation ?? const LatLng(2.046934, 45.318162);
    _lastFetchLocation = loc;

    // Initial fetch using available location
    final googlePlaces = GooglePlacesService();
    _fetchedPlaces = await googlePlaces.fetchNearbyPlaces(
      loc.latitude,
      loc.longitude,
      widget.type,
    );

    if (mounted) {
      setState(() {
        _sortWithLocation(loc);
        _isLoading = false;
      });
    }

    // Try to get an updated precise location and start listening
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      if (position != null) {
        loc = LatLng(position.latitude, position.longitude);
        if (mounted) _sortWithLocation(loc); // resort with precision
      }

      // Start listening to continuous location updates
      _positionSubscription = locationService.getPositionStream()?.listen((
        Position newPosition,
      ) async {
        final currentLoc = LatLng(newPosition.latitude, newPosition.longitude);

        if (_lastFetchLocation != null) {
          final double distance = Geolocator.distanceBetween(
            _lastFetchLocation!.latitude,
            _lastFetchLocation!.longitude,
            currentLoc.latitude,
            currentLoc.longitude,
          );

          // Re-fetch from OSM if user has moved more than 5000 meters (5km)
          if (distance > 5000) {
            _lastFetchLocation = currentLoc;
            final googlePlaces = GooglePlacesService();
            final newPlaces = await googlePlaces.fetchNearbyPlaces(
              currentLoc.latitude,
              currentLoc.longitude,
              widget.type,
            );
            if (mounted) {
              setState(() {
                _fetchedPlaces = newPlaces;
                _sortWithLocation(currentLoc);
              });
            }
            return;
          }
        }

        if (mounted) {
          setState(() {
            _sortWithLocation(currentLoc);
          });
        }
      });
    } catch (e) {
      // If error, fall back to initial sort
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortWithLocation(LatLng loc) {
    _sortedPlaces = _fetchedPlaces.map((place) {
      final double distanceInMeters = Geolocator.distanceBetween(
        loc.latitude,
        loc.longitude,
        place.latitude,
        place.longitude,
      );
      // Create a new ServicePlace with updated distance (in km)
      return ServicePlace(
        id: place.id,
        name: place.name,
        address: place.address,
        distance: distanceInMeters / 1000,
        rating: place.rating,
        status: place.status,
        openHours: place.openHours,
        imageUrl: place.imageUrl,
        type: place.type,
        phone: place.phone,
        services: place.services,
        latitude: place.latitude,
        longitude: place.longitude,
      );
    }).toList();

    _sortedPlaces.sort((a, b) => a.distance.compareTo(b.distance));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map, color: Colors.white),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            tooltip: _showMap
                ? AppLocalizations.of(context)!.showList
                : AppLocalizations.of(context)!.showMap,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
              ),
            ),
          ),

          // Content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _sortedPlaces.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.noPlacesFound,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : _showMap
              ? MapScreen(places: _sortedPlaces)
              : SafeArea(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sortedPlaces.length,
                    itemBuilder: (context, index) {
                      final place = _sortedPlaces[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ServiceDetailScreen(place: place),
                              ),
                            );
                          },
                          child: GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                 ClipRRect(
                                   borderRadius: BorderRadius.circular(12),
                                   child: place.imageUrl.startsWith('assets/')
                                       ? Image.asset(
                                           place.imageUrl,
                                           width: 80,
                                           height: 80,
                                           fit: BoxFit.cover,
                                         )
                                       : Image.network(
                                           place.imageUrl,
                                           width: 80,
                                           height: 80,
                                           fit: BoxFit.cover,
                                           errorBuilder: (context, error, stackTrace) {
                                             // Fall back to a local asset image on network error
                                             final asset = place.type == ServiceType.gasStation
                                                 ? 'assets/images/hass_petroleum.jpg'
                                                 : 'assets/images/joes_repair.jpg';
                                             return Image.asset(
                                               asset,
                                               width: 80,
                                               height: 80,
                                               fit: BoxFit.cover,
                                             );
                                           },
                                         ),
                                 ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Consumer<FavoritesProvider>(
                                    builder: (context, favoritesProvider, child) {
                                      final isFavorite = favoritesProvider
                                          .isFavorite(place.id);
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  place.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  isFavorite
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: isFavorite
                                                      ? Colors.red
                                                      : Colors.white70,
                                                  size: 24,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () {
                                                  favoritesProvider
                                                      .toggleFavorite(place);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        isFavorite
                                                            ? AppLocalizations.of(
                                                                context,
                                                              )!.removedFromFavorites
                                                            : AppLocalizations.of(
                                                                context,
                                                              )!.addedToFavorites,
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            place.address,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                place.rating.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              const Icon(
                                                Icons.location_on,
                                                color: Colors.redAccent,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${place.distance.toStringAsFixed(1)} km",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.directions,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  onPressed: () {
                                    _launchMaps(
                                      place.latitude,
                                      place.longitude,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
