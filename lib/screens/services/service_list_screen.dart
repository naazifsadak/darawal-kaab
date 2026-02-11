import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/service_place.dart';
import '../../data/mock_places.dart';
import 'service_detail_screen.dart';

class ServiceListScreen extends StatefulWidget {
  final ServiceType serviceType;

  const ServiceListScreen({super.key, required this.serviceType});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  late List<ServicePlace> _places;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _places = widget.serviceType == ServiceType.gasStation
        ? mockGasStations
        : mockRepairShops;
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.serviceType == ServiceType.gasStation
        ? "Gas Stations"
        : "Repair Shops";

    List<ServicePlace> filteredPlaces = _places.where((place) {
      return place.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "List of Results",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey[300]!, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.blue[700], size: 26),
                  hintText: "Search $title...",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterText("Distance"),
                _buildFilterText("Rating"),
                _buildFilterText("Service Type"),
              ],
            ),
          ),

          // View Toggle (List, Map, Location)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildViewToggleOption(Icons.list, true),
                _buildViewToggleOption(Icons.map_outlined, false),
                _buildViewToggleOption(Icons.place, false),
              ],
            ),
          ),

          // List Results
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredPlaces.length,
              itemBuilder: (context, index) {
                return _buildPlaceCard(filteredPlaces[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterText(String text) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.blue[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Icon(Icons.arrow_drop_down, color: Colors.blue[600]),
      ],
    );
  }

  Widget _buildViewToggleOption(IconData icon, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.grey[50], // Simple indicator
          border: isSelected
              ? const Border(bottom: BorderSide(color: Colors.blue, width: 2))
              : null,
        ),
        child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      ),
    );
  }

  Widget _buildPlaceCard(ServicePlace place) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(place: place),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Image.asset(
                  place.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        place.type == ServiceType.gasStation
                            ? Icons.local_gas_station
                            : Icons.build,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, // Bold
                        fontSize: 16,
                        color: Colors.black, // Pure black
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Color(0xFF1976D2), // Strong Blue
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${place.distance} km",
                          style: GoogleFonts.poppins(
                            color: Colors.black87, // Darker grey
                            fontSize: 13,
                            fontWeight: FontWeight.w600, // SemiBold
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          "${place.rating}",
                          style: GoogleFonts.poppins(
                            color: Colors.black87, // Darker grey
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.status,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2E7D32), // Darker Green
                        fontWeight: FontWeight.w700, // Bold
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Direction Button
            Padding(
              padding: const EdgeInsets.only(top: 35, right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50), // Standard Green
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "Direction",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
