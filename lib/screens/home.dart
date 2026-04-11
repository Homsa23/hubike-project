import 'package:flutter/material.dart';
import 'dart:ui';
import 'inbox.dart'; 
import 'events.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 1; 

  final List<Widget> pages = [
     Container(color: Colors.blue.shade50, child: const Center(child: Text("Shop", style: TextStyle(fontSize: 24)))),
      const EventsPage(), 
     const InboxPage(),
  ];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      
      appBar: AppBar(
        title: const Text(
          "HUBIKE", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2.0),
        ),
        backgroundColor: const Color(0xFF121212), 
        centerTitle: true,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.white24, width: 0.2), // Thin white line at the bottom
        ),
      ),
      
      body: pages[selectedIndex],
      
      // =========================================================
      // 1. THE BIG FLOATING CENTER BUTTON (EVENTS / RIDES)
      // =========================================================
      floatingActionButton: GestureDetector(
        onTap: () => onItemTapped(1),
        child: Container(
          height: 65,
          width: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // If active, it's bright neon green. If inactive, it's dark grey.
            color: selectedIndex == 1 ? const Color(0xFF39FF14) : const Color(0xFF222222),
            // The neon glow effect from the HTML
            boxShadow: selectedIndex == 1 ? [
              BoxShadow(
                color: const Color(0xFF39FF14).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ] : [],
          ),
          child: Icon(
            Icons.directions_bike, // Changed to a bike icon to match the theme!
            color: selectedIndex == 1 ? Colors.black : Colors.white54,
            size: 32,
          ),
        ),
      ),
      // This tells Flutter to dock the button right in the middle of the bottom bar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // =========================================================
      // 2. THE GLASS BOTTOM NAVIGATION BAR
      // =========================================================
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: BottomAppBar(
            padding: EdgeInsets.zero,
            color: const Color(0xFF121212).withOpacity(0.8), // Glass background
            shape: const CircularNotchedRectangle(), // Creates the cutout for the circle
            notchMargin: 10, // Space between the bar and the floating button
            child: SizedBox(
              height: 70, // Height of the bar
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  
                  // LEFT BUTTON (SHOP / GEAR)
                  _buildSideNavButton(
                    icon: Icons.shopping_bag, 
                    label: "GEAR", 
                    index: 0
                  ),
                  
                  const SizedBox(width: 50), // Empty space in the middle for the big button
                  
                  // RIGHT BUTTON (INBOX / COMMS)
                  _buildSideNavButton(
                    icon: Icons.inbox, 
                    label: "COMMS", 
                    index: 2
                  ),
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HELPER WIDGET: Keeps the code clean for the side buttons
  // =========================================================
  Widget _buildSideNavButton({required IconData icon, required String label, required int index}) {
    bool isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isActive ? Colors.white : Colors.white54, // Bright white if active
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}