import 'package:flutter/material.dart';
import '../models/service_place.dart';

final List<ServicePlace> mockGasStations = [
  const ServicePlace(
    id: 'g1',
    name: 'Hass Petroleum',
    address: 'Industrial Road, Mogadishu, Somalia',
    distance: 2.5,
    rating: 4.8,
    status: 'Open 24 Hours',
    openHours: 'Mon-Fri: 8:00 AM - 6:00 PM\nSat: 9:00 AM - 3:00 PM',
    imageUrl: 'assets/images/hass_petroleum.jpg', // Placeholder
    type: ServiceType.gasStation,
    phone: '+252 61 5000000',
    services: ['Petroleum', 'LPG Gas', 'Service Station', 'Convenience Store'],
  ),
  const ServicePlace(
    id: 'g2',
    name: 'Soltico Petroleum',
    address: 'Maka Al-Mukarama Rd, Mogadishu',
    distance: 3.1,
    rating: 4.5,
    status: 'Open until 10:00 PM',
    openHours: 'Mon-Sun: 6:00 AM - 10:00 PM',
    imageUrl: 'assets/images/soltico.jpg', // Placeholder
    type: ServiceType.gasStation,
    phone: '+252 61 5000001',
    services: ['Fuel', 'Car Wash', 'Oil Change'],
  ),
  const ServicePlace(
    id: 'g3',
    name: 'Sopico Petroleum',
    address: 'Wadada Sodonka, Mogadishu',
    distance: 2.0,
    rating: 4.3,
    status: 'Open 24 Hours',
    openHours: 'Open 24 Hours',
    imageUrl: 'assets/images/sopico.jpg', // Placeholder
    type: ServiceType.gasStation,
    phone: '+252 61 5000002',
    services: ['Diesel', 'Petrol', 'Air Pump'],
  ),
];

final List<ServicePlace> mockRepairShops = [
  const ServicePlace(
    id: 's1',
    name: "Joe's Auto Repair",
    address: 'Maka Al-Mukarama Rd, Mogadishu, Somalia',
    distance: 1.2,
    rating: 4.9,
    status: 'Open Now',
    openHours: 'Mon-Fri: 8:00 AM - 6:00 PM\nSat: 9:00 AM - 3:00 PM',
    imageUrl: 'assets/images/joes_repair.jpg', // Placeholder
    type: ServiceType.repairShop,
    phone: '+252 61 5555555',
    services: ['Engine Repair', 'Tire Change', 'Oil Change', 'Diagnostics'],
  ),
  const ServicePlace(
    id: 's2',
    name: 'Quick Tire Service',
    address: 'Km4 Junction, Mogadishu',
    distance: 1.8,
    rating: 4.2,
    status: 'Open until 8:00 PM',
    openHours: 'Mon-Sat: 7:00 AM - 8:00 PM',
    imageUrl: 'assets/images/tire_service.jpg', // Placeholder
    type: ServiceType.repairShop,
    phone: '+252 61 5555556',
    services: ['Tire Repair', 'Wheel Balancing', 'Alignment'],
  ),
  const ServicePlace(
    id: 's3',
    name: 'Xalane Garage',
    address: 'Xalane Neighborhood',
    distance: 1.5,
    rating: 4.7,
    status: 'Open 8:00 AM - 6:00 PM',
    openHours: 'Mon-Fri: 8:00 AM - 6:00 PM',
    imageUrl: 'assets/images/xalane_garage.jpg', // Placeholder
    type: ServiceType.repairShop,
    phone: '+252 61 5555557',
    services: ['Body Work', 'Painting', 'Mechanical Repair'],
  ),
];
