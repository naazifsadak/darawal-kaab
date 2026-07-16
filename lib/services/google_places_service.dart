import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_place.dart';

class GooglePlacesService {
  final _supabase = Supabase.instance.client;

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

    try {
      final response = await _supabase.functions.invoke(
        'google-places',
        body: {
          'action': 'nearbySearch',
          'lat': lat,
          'lng': lng,
          'radius': radius,
          'keyword': keyword,
        },
      );

      if (response.status == 200) {
        final data = response.data;
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          List<dynamic> results = data['results'] ?? [];

          List<ServicePlace> places = [];
          for (var el in results) {
            final name = el['name'] ?? 'Unknown Service Station';
            final address = el['vicinity'] ?? 'Address not available';

            // Google Places Nearby Search doesn't return phone or full hours by default
            // unless we do a separate Place Details request.
            final bool openNow = el['opening_hours']?['open_now'] ?? true;
            final double rating = (el['rating'] ?? 4.0).toDouble();

            // The Edge Function resolves photo_references into public CDN URLs
            // server-side so Image.network() can load them without auth headers.
            // Use a type-specific local asset as the client-side fallback.
            final String localFallback = type == ServiceType.gasStation
                ? 'assets/images/hass_petroleum.jpg'
                : 'assets/images/joes_repair.jpg';
            final String resolvedPhoto =
                (el['_resolvedPhotoUrl'] as String?) ?? localFallback;

            places.add(
              ServicePlace(
                id: el['place_id'] ?? el['reference'] ?? UniqueKey().toString(),
                name: name,
                address: address,
                distance: 0.0, // Calculated dynamically by UI later
                rating: rating,
                status: openNow ? 'Open Now' : 'Closed',
                openHours: openNow ? 'Open' : 'Closed',
                imageUrl: resolvedPhoto,
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

  Future<String?> fetchPlacePhoneNumber(String placeId) async {
    try {
      final response = await _supabase.functions.invoke(
        'google-places',
        body: {
          'action': 'details',
          'place_id': placeId,
          'fields': 'formatted_phone_number,international_phone_number',
        },
      );

      if (response.status == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final result = data['result'] ?? {};
          return result['international_phone_number'] ?? result['formatted_phone_number'];
        } else {
          debugPrint("Google Place Details error status: ${data['status']} - ${data['error_message']}");
        }
      }
      return null;
    } catch (e) {
      debugPrint("Google Place Details HTTP error: $e");
      return null;
    }
  }


}
