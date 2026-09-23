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
import 'package:google_fonts/google_fonts.dart';

// =========================================================
// 1. THE WIDGET (THE BLUEPRINT)
// =========================================================
// StatefulWidget means this screen has data that can change over time
// (like which tab is selected, or who is logged in).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // This connects the blueprint (widget) to its brain (state).
  State<HomeScreen> createState() => HomeScreenState();
}

// =========================================================
// 2. THE STATE (THE BRAIN)
// =========================================================
// This class stays alive in memory and holds your variables.
class HomeScreenState extends State<HomeScreen> {
  // TRACKING CHANGES: This variable remembers which tab is currently active.
  // 0 = Left Tab (Gear/Shop), 1 = Center Tab (Events/Dashboard), 2 = Right Tab (Inbox/Profile)
  int selectedIndex = 1;
  
  // TRACKING CHANGES: This holds all the database info about the logged-in user.
  // If it's null, it means no one is logged in, or data hasn't loaded yet.
  Map<String, dynamic>? currentUser;

  // Helper properties (getters) to make code easier to read later on.
  bool get signedIn => FirebaseAuth.instance.currentUser != null;
  bool get isGroupLeader => (currentUser?['isGroupLeader'] as bool?) ?? false;

  // =========================================================
  // 3. INITIALIZATION (RUNS ONLY ONCE)
  // =========================================================
  @override
  void initState() {
    super.initState();
    // When the screen first opens, try to load the user's data.
    _loadCurrentUser();
    
    // Listen to Firebase Auth. If the user logs in or out anywhere in the app,
    // this listener catches it and updates the HomeScreen state automatically!

    // this is the live login , like in real time it rects to changes ,without it it wouldn't log you in until you restart the app
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadCurrentUser();
      } else {
        // setState tells Flutter to redraw the screen because data changed.
        setState(() {
          currentUser = null;
        });
      }
    });
  }

  // Helper to get the Firestore database instance.
  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  // =========================================================
  // 4. DATA FETCHING
  // =========================================================
  // This queries the 'user' collection in Firestore to get the user's details (like isGroupLeader).
  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore
          .collection('user')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        // Whenever you change 'currentUser', you MUST use setState so the UI updates!
        setState(() {
          currentUser = doc.data();
        });
      }
    }
  }
  // Logs the user out of Firebase and clears their data from memory.
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      currentUser = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out successfully')),
    );
  }

  // =========================================================
  // 5. NAVIGATION LOGIC (TOP LEFT PROFILE BUTTON)
  // =========================================================
  void _showProfileMenu() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // If logged in: Go to the Rider Profile Page.
      // .then() waits for the user to come back from that page.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RiderProfilePage()),
      ).then((result) {
        if (result == true) { // If they clicked "Logout" inside the profile page
          _signOut();
        } else {
          // If they just went back, reload data in case they changed their profile picture or name.
          _loadCurrentUser();
        }
      });
    } else {
      // If NOT logged in: Go to the Auth/Login Screen.
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

  // =========================================================
  // 6. DYNAMIC PAGES LIST (HOW SCREENS CHANGE)
  // =========================================================
  // LOOK HERE to see which screens are tied to which tabs!
  // This is a "getter" that returns a list of 3 screens depending on the user's role.
  List<Widget> get pages {
    if (isGroupLeader) {
      // What the Group Leader sees:
      return [
        const AdminShopPage(),       // Index 0 (Left Tab)
        const LeaderDashboardPage(), // Index 1 (Center Button)
        const LeaderProfilePage(),   // Index 2 (Right Tab)
      ];
    } else {
      // What the normal Rider sees:
      return [
        GearTab(groupLeaderId: (currentUser?['groupLeaderId'] as String?) ?? ''), // Index 0
        EventsPage(signedIn: signedIn, currentUser: currentUser),                 // Index 1
        const InboxPage(),                                                        // Index 2
      ];
    }
  }

  // =========================================================
  // 7. TAB CHANGING LOGIC
  // =========================================================
  // This is called whenever you tap a bottom navigation button.
  void onItemTapped(int index) {
    // setState is the magic word! It updates 'selectedIndex' and forces
    // Flutter to run the build() method again to draw the new page.
    setState(() {
      selectedIndex = index;
    });
  }

  // =========================================================
  // 8. THE UI BUILDER (DRAWS THE SCREEN)
  // =========================================================
  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic structure (AppBar, Body, BottomNavigationBar)
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBody: true, // Allows the body to flow underneath the transparent bottom bar
      
      // -- TOP BAR --
      appBar: AppBar(
        title: Text(
          "HUBIKE",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5 ),
        ),
        backgroundColor: const Color(0xFF121212), 
        centerTitle: true,
        elevation: 0,

        // The top-left button (Profile Picture / Login Button)
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _showProfileMenu,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF050505),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF39FF14).withOpacity(0.8),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF39FF14).withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ],
              ),
              // Show profile picture if it exists, otherwise show a default person icon
              child: ClipOval(
                child: (currentUser != null && currentUser!['image'] != null && currentUser!['image'].toString().isNotEmpty)
                    ? Image.network(
                        currentUser!['image'].toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          color: Color(0xFF39FF14),
                          size: 20,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Color(0xFF39FF14),
                        size: 20,
                      ),
              ),
            ),
          ),
        ),
        shape: Border(
          bottom: BorderSide(color: Colors.white24, width: 0.2), // Thin white line at the bottom
        ),
      ),
      
      // =========================================================
      // 🚨 THIS IS WHERE THE MAGIC HAPPENS! 🚨
      // =========================================================
      // This single line injects the entire screen (Events, Inbox, Shop, etc.)
      // based on the 'selectedIndex'. When selectedIndex changes, this swaps the page out!
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_pattern_hubike.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: pages[selectedIndex],
      ),

      // =========================================================
      // 9. THE BIG FLOATING CENTER BUTTON (INDEX 1)
      // =========================================================
      floatingActionButton: GestureDetector(
        onTap: () => onItemTapped(1), // Clicking this switches to page at Index 1 (Events)
        child: Container(
          height: 65,
          width: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // If active, it's bright neon green. If inactive, it's dark grey.
            color: selectedIndex == 1 ? const Color(0xFF39FF14) : const Color(0xFF222222),
            // The neon glow effect
            boxShadow: selectedIndex == 1 ? [
              BoxShadow(
                color: const Color(0xFF39FF14).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ] : [],
          ),
          child: Icon(
            Icons.directions_bike,
            color: selectedIndex == 1 ? Colors.black : Colors.white54,
            size: 32,
          ),
        ),
      ),
      // This tells Flutter to dock the button right in the middle of the bottom bar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // =========================================================
      // 10. THE GLASS BOTTOM NAVIGATION BAR
      // =========================================================
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: BottomAppBar(
            padding: EdgeInsets.zero,
            color: const Color(0xFF121212).withOpacity(0.8), // Glass background
            shape: const CircularNotchedRectangle(), // Creates the cutout for the circle button
            notchMargin: 10, // Space between the bar and the floating button
            child: SizedBox(
              height: 70, // Height of the bar
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  
                  // LEFT BUTTON (INDEX 0)
                  _buildSideNavButton(
                    icon: Icons.shopping_bag, 
                    label: isGroupLeader ? "SHOP MGT" : "GEAR", 
                    index: 0
                  ),
                  
                  const SizedBox(width: 50), // Empty space in the middle for the big button
                  
                  // RIGHT BUTTON (INDEX 2)
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
  // This takes an icon, a label, and the target index for the button.
  Widget _buildSideNavButton({required IconData icon, required String label, required int index}) {
    bool isActive = selectedIndex == index; // Check if this button is the currently selected tab
    return GestureDetector(
      onTap: () => onItemTapped(index), // Trigger a tab change when tapped
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
              style: GoogleFonts.montserrat(
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