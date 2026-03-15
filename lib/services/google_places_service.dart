import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/service_place.dart';

class GooglePlacesService {
  final Dio _dio = Dio();

  // NOTE: This key was retrieved from your AndroidManifest.xml Google Maps setup
  static const String _apiKey = 'AIzaSyAHOeUAFjHezZRr9FT4RdGXxBpi9RQmKYE';

  Future<List<ServicePlace>> fetchNearbyPlaces(
    double lat,
    double lng,
    ServiceType type, {
    int radius = 5000,
  }) async {
    // Determine the keyword to search for based on type
    final keyword = type == ServiceType.gasStation
        ? 'gas station'
        : 'car repair mechanic';

    // Google Places API Nearby Search Endpoint
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'location': '$lat,$lng',
          'radius': radius,
          'keyword': keyword,
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          List<dynamic> results = data['results'] ?? [];

          List<ServicePlace> places = [];
          for (var el in results) {
            final name = el['name'] ?? 'Unknown Service Station';
            final address = el['vicinity'] ?? 'Address not available';

            // Google Places Nearby Search doesn't return phone or full hours by default
            // unless we do a separate Place Details request. For performance and cost,
            // we will use placeholders or basic info here.
            final bool openNow = el['opening_hours']?['open_now'] ?? true;
            final double rating = (el['rating'] ?? 4.0).toDouble();

            places.add(
              ServicePlace(
                id: el['place_id'] ?? el['reference'] ?? UniqueKey().toString(),
                name: name,
                address: address,
                distance: 0.0, // Calculated dynamically by UI later
                rating: rating,
                status: openNow ? 'Open Now' : 'Closed',
                openHours: openNow ? 'Open' : 'Closed',
                imageUrl: _getPhotoUrl(el['photos']),
                type: type,
                phone: 'Contact via Google Maps',
                services: type == ServiceType.gasStation
                    ? ['Fuel']
                    : ['Repair'],
                latitude: el['geometry']['location']['lat'],
                longitude: el['geometry']['location']['lng'],
              ),
            );
          }
          return places;
        } else {
          debugPrint(
            "Google Places API error status: ${data['status']} - ${data['error_message']}",
          );
          return [];
        }
      }
      return [];
    } catch (e) {
      debugPrint("Google Places HTTP error: $e");
      return [];
    }
  }

  // Helper to extract the first photo URL if available
  String _getPhotoUrl(dynamic photosArray) {
    if (photosArray != null && photosArray is List && photosArray.isNotEmpty) {
      final photoReference = photosArray[0]['photo_reference'];
      if (photoReference != null) {
        return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoReference&key=$_apiKey';
      }
    }
    // Fallback image if no Google Place photo is available
    return 'https://images.unsplash.com/photo-1527018601619-a508a2800447?q=80&w=2674&auto=format&fit=crop';
  }
}
