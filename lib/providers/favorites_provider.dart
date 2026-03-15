import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_place.dart';

class FavoritesProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ServicePlace> _favorites = [];
  bool _isLoading = false;

  List<ServicePlace> get favorites => _favorites;
  bool get isLoading => _isLoading;

  FavoritesProvider() {
    loadFavorites();
  }

  /// Check if a place is favorited by the current user
  bool isFavorite(String placeId) {
    return _favorites.any((place) => place.id == placeId);
  }

  /// Load all favorites from Supabase for the active user
  Future<void> loadFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('favorite_services')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _favorites = (response as List<dynamic>).map((data) {
        return ServicePlace(
          id: data['place_id'],
          name: data['name'],
          address: data['address'] ?? '',
          imageUrl: data['image_url'] ?? '',
          type: data['type'] == 'gasStation'
              ? ServiceType.gasStation
              : ServiceType.repairShop,
          latitude: data['latitude'],
          longitude: data['longitude'],
          rating: (data['rating'] ?? 0.0).toDouble(),
          status: data['status'] ?? '',
          openHours: data['open_hours'] ?? '',
          phone: data['phone'] ?? '',
          services: (data['services'] as String?)?.split(', ') ?? [],
          distance: 0.0, // Distance is calculated dynamically relative to user
        );
      }).toList();
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add or remove a place from favorites in Supabase
  Future<void> toggleFavorite(ServicePlace place) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint("User must be logged in to favorite a place.");
      return;
    }

    final existingIndex = _favorites.indexWhere((p) => p.id == place.id);

    try {
      if (existingIndex >= 0) {
        // Optimistic UI update: Remove it locally first
        _favorites.removeAt(existingIndex);
        notifyListeners();

        // Delete from Supabase
        await _supabase.from('favorite_services').delete().match({
          'user_id': user.id,
          'place_id': place.id,
        });
      } else {
        // Optimistic UI update: Add it locally first
        _favorites.insert(0, place);
        notifyListeners();

        // Insert into Supabase mapping exactly to the schema
        await _supabase.from('favorite_services').insert({
          'user_id': user.id,
          'place_id': place.id,
          'name': place.name,
          'address': place.address,
          'image_url': place.imageUrl,
          'type': place.type == ServiceType.gasStation
              ? 'gasStation'
              : 'repairShop',
          'latitude': place.latitude,
          'longitude': place.longitude,
          'rating': place.rating,
          'status': place.status,
          'open_hours': place.openHours,
          'phone': place.phone,
          'services': place.services.join(', '),
        });
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
      // Revert optimistic update on failure by reloading true state
      await loadFavorites();
    }
  }

  /// Clears favorites (e.g., on logout)
  void clearFavorites() {
    _favorites = [];
    notifyListeners();
  }
}
