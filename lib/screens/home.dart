import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inbox.dart';
import 'events.dart';
import 'gear_tab.dart';
import 'auth_screen.dart';
import 'leader_dashboard.dart';
import 'admin_shop_page.dart';
import 'leader_profile.dart';
import 'rider_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 1;
  Map<String, dynamic>? currentUser;

  bool get signedIn => FirebaseAuth.instance.currentUser != null;
  int get coins => (currentUser?['coins'] as int?) ?? 0;
  bool get isGroupLeader => (currentUser?['isGroupLeader'] as bool?) ?? false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadCurrentUser();
      } else {
        setState(() {
          currentUser = null;
        });
      }
    });
  }

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore
          .collection('user')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          currentUser = doc.data();
        });
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      currentUser = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out successfully')),
    );
  }

  void _showProfileMenu() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Show Rider Profile Page for logged in users
      Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const RiderProfilePage()),
      ).then((didSignOut) {
        if (didSignOut == true) {
          _signOut();
        }
      });
    } else {
      // Show login screen for logged out users
      Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      ).then((userData) {
        if (userData is Map<String, dynamic>) {
          setState(() {
            currentUser = userData;
          });
        }
      });
    }
  }

  // Build the page list dynamically based on user role
  List<Widget> get pages {
    if (isGroupLeader) {
      return [
        const AdminShopPage(),
        const LeaderDashboardPage(),
        const LeaderProfilePage(),
      ];
    } else {
      return [
        GearTab(groupLeaderId: (currentUser?['groupLeaderId'] as String?) ?? ''),
        EventsPage(signedIn: signedIn, currentUser: currentUser),
        const InboxPage(),
      ];
    }
  }

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
        actions: [
          // Coins display (hidden for Group Leaders)
          if (!isGroupLeader)
            Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF39FF14), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFF39FF14), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      signedIn ? '$coins' : '0',
                      style: const TextStyle(
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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _showProfileMenu,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF39FF14),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF39FF14).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF39FF14),
                size: 20,
              ),
            ),
          ),
        ),
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
                  
                  // LEFT BUTTON (SHOP / GEAR or SHOP MGT)
                  _buildSideNavButton(
                    icon: Icons.shopping_bag, 
                    label: isGroupLeader ? "SHOP MGT" : "GEAR", 
                    index: 0
                  ),
                  
                  const SizedBox(width: 50), // Empty space in the middle for the big button
                  
                  // RIGHT BUTTON (INBOX / COMMS or PROFILE)
                  _buildSideNavButton(
                    icon: isGroupLeader ? Icons.person : Icons.inbox, 
                    label: isGroupLeader ? "PROFILE" : "COMMS", 
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