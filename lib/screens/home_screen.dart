import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jump_post_feed_screen.dart';
import 'services/service_list_screen.dart';
import '../models/service_place.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset:
          false, // Prevent map from squishing when keyboard opens
      body: Stack(
        children: [
          // 1. Map Layer (Full Screen Background)
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE0E0E0), // Placeholder Map Color
              child: Stack(
                children: [
                  // Fake Map Pattern
                  Opacity(
                    opacity: 0.05,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                          ),
                      itemBuilder: (context, index) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  // "Gas Station" Pill (Floated independently on the map)
                  Positioned(
                    bottom: 150, // Pinned to bottom-ish
                    right: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.local_gas_station,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Gas Station",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Random Pin (Floated independently)
                  Positioned(
                    bottom: 100,
                    left: 100,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF1565C0),
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Layer (Header + Flowing Icons)
          Column(
            children: [
              // Blue Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 30),
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
                    // Top Right Signal Icon
                    const Align(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.signal_cellular_alt,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),

                    Text(
                      "Welcome!",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Find Nearby Services",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search Bar
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          icon: Icon(
                            Icons.search,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                          hintText: "Search Repair Shops or Gas S...",
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Grid Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ServiceListScreen(
                                    serviceType: ServiceType.repairShop,
                                  ),
                                ),
                              );
                            },
                            child: _buildServiceCard(
                              color: const Color(0xFF1565C0), // Darker Blue
                              icon: Icons.build,
                              label: "Find Repair Shops",
                              rotateIcon: true,
                              height: 100,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ServiceListScreen(
                                    serviceType: ServiceType.gasStation,
                                  ),
                                ),
                              );
                            },
                            child: _buildServiceCard(
                              color: const Color(0xFF43A047), // Green
                              icon: Icons.local_gas_station,
                              label: "Find Gas Stations",
                              height: 100,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Jump Post Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const JumpPostFeedScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 90,
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
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Jump Post - Road Conditions",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
              // VISIBILITY GUARANTEED: In the Column, immediately after Header.
              Padding(
                padding: const EdgeInsets.only(top: 20.0), // Space from header
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMapItem(
                      icon: Icons.location_on,
                      color: Colors.blue,
                      label: "Nearby",
                      isPin: true,
                    ),
                    _buildMapItem(
                      icon: Icons.star,
                      color: const Color(0xFFEF6C00), // Orange
                      label: "Top Rated",
                    ),
                    _buildMapItem(
                      icon: Icons.local_offer,
                      color: Colors.blue,
                      label: "Offers",
                    ),
                  ],
                ),
              ),

              const Spacer(), // Pushes map content down if needed, or just lets it be transparent
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
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
    );
  }
}
