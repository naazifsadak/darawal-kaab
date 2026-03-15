import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/service_place.dart';

class OverpassService {
  final Dio _dio = Dio();

  // Queries Overpass API for real amenities near a radius (e.g. 5000 meters = 5km)
  Future<List<ServicePlace>> fetchNearbyPlaces(
    double lat,
    double lng,
    ServiceType type, {
    int radius = 15000,
  }) async {
    String nodeFilter = '';

    if (type == ServiceType.gasStation) {
      nodeFilter =
          '''
        nwr["amenity"="fuel"](around:$radius,$lat,$lng);
        nwr["building"="service_station"](around:$radius,$lat,$lng);
      ''';
    } else {
      // For repair shops: shop=car_repair, craft=car_repair
      nodeFilter =
          '''
        nwr["shop"="car_repair"](around:$radius,$lat,$lng);
        nwr["craft"="car_repair"](around:$radius,$lat,$lng);
      ''';
    }

    // Overpass QL Query
    final query =
        '''
      [out:json][timeout:25];
      (
        $nodeFilter
      );
      out center;
    ''';

    try {
      final response = await _dio.post(
        'https://overpass-api.de/api/interpreter',
        data: query,
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> elements = data['elements'] ?? [];

        List<ServicePlace> places = [];
        for (var el in elements) {
          final tags = el['tags'] ?? {};
          final name =
              tags['name'] ?? tags['brand'] ?? 'Unknown Service Station';

          final address =
              tags['addr:street'] ??
              tags['addr:full'] ??
              'Address not available';
          final phone =
              tags['phone'] ?? tags['contact:phone'] ?? 'Phone not available';
          final openHours = tags['opening_hours'] ?? 'Hours varying';

          places.add(
            ServicePlace(
              id: el['id'].toString(),
              name: name,
              address: address,
              distance: 0.0, // Calculated dynamically by UI later
              rating: 4.0, // OSM doesn't have reliable ratings, default to 4.0
              status: openHours != 'Hours varying' ? 'Check hours' : 'Open',
              openHours: openHours,
              imageUrl:
                  'https://images.unsplash.com/photo-1527018601619-a508a2800447?q=80&w=2674&auto=format&fit=crop', // generic auto theme fallback
              type: type,
              phone: phone,
              services: type == ServiceType.gasStation ? ['Fuel'] : ['Repair'],
              latitude: el['lat'] ?? el['center']?['lat'] ?? 0.0,
              longitude: el['lon'] ?? el['center']?['lon'] ?? 0.0,
            ),
          );
        }

        return places;
      }
      return [];
    } catch (e) {
      debugPrint("Overpass API error: $e");
      return [];
    }
  }
}
