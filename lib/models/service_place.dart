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

  final double latitude;
  final double longitude;

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
    required this.latitude,
    required this.longitude,
  });

  static List<ServicePlace> get mockPlaces => generateNear(2.046934, 45.318162);

  static List<ServicePlace> generateNear(double lat, double lng) {
    return [
      ServicePlace(
        id: '1',
        name: 'TotalEnergies Station',
        address: 'Nearby location',
        distance: 0.0,
        rating: 4.5,
        status: 'Open 24 Hours',
        openHours: 'Open 24 Hours',
        imageUrl:
            'https://lh5.googleusercontent.com/p/AF1QipNqW_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4',
        type: ServiceType.gasStation,
        phone: '+252 61 555 5555',
        services: ['Fuel', 'Car Wash', 'Convenience Store', 'Oil Change'],
        latitude: lat + 0.005,
        longitude: lng + 0.002,
      ),
      ServicePlace(
        id: '2',
        name: 'Hass Petroleum',
        address: 'Nearby Road',
        distance: 0.0,
        rating: 4.2,
        status: 'Open Now',
        openHours: '6:00 AM - 11:00 PM',
        imageUrl:
            'https://lh5.googleusercontent.com/p/AF1QipNqW_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4',
        type: ServiceType.gasStation,
        phone: '+252 61 555 5556',
        services: ['Fuel', 'Air Pump', 'Snacks'],
        latitude: lat - 0.010,
        longitude: lng - 0.005,
      ),
      ServicePlace(
        id: '3',
        name: 'Somali Auto Repair',
        address: 'Nearby Service Center',
        distance: 0.0,
        rating: 4.8,
        status: 'Open Now',
        openHours: '8:00 AM - 6:00 PM',
        imageUrl:
            'https://lh5.googleusercontent.com/p/AF1QipNqW_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4',
        type: ServiceType.repairShop,
        phone: '+252 61 555 5557',
        services: ['Mechanic', 'Tire Repair', 'Electrical'],
        latitude: lat + 0.015,
        longitude: lng - 0.012,
      ),
      ServicePlace(
        id: '4',
        name: 'Banadir Garage',
        address: 'Nearby Garage',
        distance: 0.0,
        rating: 4.0,
        status: 'Closed',
        openHours: '8:00 AM - 5:00 PM',
        imageUrl:
            'https://lh5.googleusercontent.com/p/AF1QipNqW_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4',
        type: ServiceType.repairShop,
        phone: '+252 61 555 5558',
        services: ['Body Work', 'Painting', 'Engine Repair'],
        latitude: lat - 0.008,
        longitude: lng + 0.018,
      ),
      ServicePlace(
        id: '5',
        name: 'Medina Petroleum',
        address: 'Local Fueling',
        distance: 0.0,
        rating: 4.1,
        status: 'Open 24 Hours',
        openHours: 'Open 24 Hours',
        imageUrl:
            'https://lh5.googleusercontent.com/p/AF1QipNqW_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4',
        type: ServiceType.gasStation,
        phone: '+252 61 555 5559',
        services: ['Fuel', 'Car Wash'],
        latitude: lat - 0.020,
        longitude: lng - 0.020,
      ),
      ServicePlace(
        id: '6',
        name: 'Beexaani Auto Repair',
        address: 'Local Care',
        distance: 0.0,
        rating: 4.6,
        status: 'Open Now',
        openHours: '8:00 AM - 6:00 PM',
        imageUrl:
            'https://lh5.googleusercontent.com/p/AF1QipNqW_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4',
        type: ServiceType.repairShop,
        phone: '+252 61 555 5560',
        services: ['Mechanic', 'Tire Repair'],
        latitude: lat + 0.025,
        longitude: lng + 0.022,
      ),
      ServicePlace(
        id: '7',
        name: 'Dayniile Fuel Center',
        address: 'Speedway',
        distance: 0.0,
        rating: 3.9,
        status: 'Open Now',
        openHours: '6:00 AM - 10:00 PM',
        imageUrl:
            'https://lh5.googleusercontent.com/p/AF1QipNqW_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4',
        type: ServiceType.gasStation,
        phone: '+252 61 555 5561',
        services: ['Fuel', 'Snacks'],
        latitude: lat + 0.030,
        longitude: lng + 0.010,
      ),
      ServicePlace(
        id: '8',
        name: 'Waberi Auto Service',
        address: 'Quick Fix',
        distance: 0.0,
        rating: 4.9,
        status: 'Open Now',
        openHours: '7:00 AM - 7:00 PM',
        imageUrl:
            'https://lh5.googleusercontent.com/p/AF1QipNqW_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4W_4',
        type: ServiceType.repairShop,
        phone: '+252 61 555 5562',
        services: ['Oil Change', 'General Maintenance'],
        latitude: lat - 0.015,
        longitude: lng + 0.005,
      ),
    ];
  }
}
