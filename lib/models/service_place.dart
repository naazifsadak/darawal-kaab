enum ServiceType { gasStation, repairShop }

class ServicePlace {
  final String id;
  final String name;
  final String address;
  final double distance; // in km
  final double rating;
  final String status; // e.g., "Open 24 Hours", "Open Now"
  final String openHours; // e.g., "Mon-Fri: 8:00 AM - 6:00 PM"
  final String imageUrl;
  final ServiceType type;
  final String phone;
  final List<String> services;

  const ServicePlace({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.status,
    required this.openHours,
    required this.imageUrl,
    required this.type,
    required this.phone,
    required this.services,
  });
}
