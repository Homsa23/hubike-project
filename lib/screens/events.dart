import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_model.dart';
import 'category_model.dart';
import 'event_detail.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
// ============================================================================
// WIDGET: EVENTS PAGE
// ============================================================================
// This screen acts as the dynamic Event Feed. It displays event categories at
// the top and loads a filtered or unfiltered list of active cycling events.
// It receives signedIn and currentUser details from the parent HomeScreen.
class EventsPage extends StatefulWidget {
  final bool signedIn;
  final Map<String, dynamic>? currentUser;

  const EventsPage({super.key, required this.signedIn, this.currentUser});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

// ============================================================================
// STATE: EVENTS PAGE STATE (THE BRAIN)
// ============================================================================
class _EventsPageState extends State<EventsPage> {
  // 1. ACTIVE FILTER: Tracks which category is currently selected by the user.
  // If it is 'null', it means "All" categories are selected.
  HubikeCategory? selectedCategory; 
  
  // 2. COLOR CACHE: A map that stores loaded categories so event cards can
  // instantly lookup and render their category color without sending extra
  // queries to Firestore for each card.
  final Map<String, HubikeCategory> cachedCategories = {};

  @override
  void initState() {
    super.initState();
    // Start-up housekeeping: Automatically clean up finished events from the database.
    deleteForgottenEvents();
  }

  // ============================================================================
  // DATABASE CLEANUP: deleteForgottenEvents
  // ============================================================================
  // This automatically runs once when the screen opens. It queries Firestore to
  // find any event older than 24 hours (finished events) and deletes them.
  Future<void> deleteForgottenEvents() async {
    try {
      // Connect to the primary default database
      final firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
      
      // Calculate our 24-hour cutoff (events scheduled in the past)
      final twentyFourHoursAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));
      
      // Query events collection for expired items
      final snapshot = await firestore
          .collection('events')
          .where('date', isLessThanOrEqualTo: twentyFourHoursAgo)
          .get();

      // Loop through and delete each expired document
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('Cleaned up ${snapshot.docs.length} forgotten events.');
    } catch (e) {
      debugPrint('Failed to delete forgotten events: $e');
    }
  }

  // ============================================================================
  // RENDER INTERFACE (THE BODY)
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Ultra dark background for neon contrast
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_pattern_hubike.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
            children: [
              const SizedBox(height: 40), 
              
              // ==================================================================
              // PIPELINE 1: LIVE CATEGORY SELECTION BUTTONS (HORIZONTAL BAR)
              // ==================================================================
              SizedBox(
                height: 40,
                child: StreamBuilder<QuerySnapshot>(
                  // Query categories collection in real time!
                  stream: FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default')
                      .collection('categories')
                      .snapshots(),
                  builder: (context, snapshot) {
                    
                    // 1. Show loading progress indicator while connecting
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          width: 20, height: 20, 
                          child: CircularProgressIndicator(color: Color(0xFF39FF14), strokeWidth: 2)
                        )
                      );
                    }

                    // 2. Show error if Firestore query fails
                    if (snapshot.hasError) {
                      return Center(
                        child: Text("ERROR: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 10)),
                      );
                    }

                    // 3. Fallback text if categories list is empty
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No Categories Found", style: TextStyle(color: Colors.white)));
                    }

                    // Convert Firebase Document Snapshots into custom Category Models
                    List<HubikeCategory> liveCategories = snapshot.data!.docs
                        .map((doc) => HubikeCategory.fromFirestore(doc))
                        .toList();

                    // CACHING LOGIC: We store category details inside cachedCategories.
                    // Since we cannot run setState() directly inside build() without triggering
                    // infinite loops, we wrap it in a addPostFrameCallback.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      bool needsUpdate = false;
                      for (var cat in liveCategories) {
                        if (!cachedCategories.containsKey(cat.id) || cachedCategories[cat.id]?.colorHex != cat.colorHex) {
                          cachedCategories[cat.id] = cat;
                          needsUpdate = true;
                        }
                      }
                      // Redraw the screen once cache is updated so cards show correct colors
                      if (needsUpdate && mounted) {
                        setState(() {}); 
                      }
                    });

                    // Return the horizontal scrolling list of category buttons
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        // Manual static "All" button
                        _buildAllButton(),
                        
                        // Live category buttons from database
                        ...liveCategories.map((category) {
                          return _buildCategoryButton(category);
                        }),
                      ],
                    );
                  },
                ),
              ),
          
              const SizedBox(height: 24),
          
              // ==================================================================
              // PIPELINE 2: HERO CATEGORY BANNER (DYNAMIC CAGE)
              // ==================================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, 
                  children: [
                    Container(
                      height: 350, 
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          // Dynamic Image: Displays the active category photo. Defaults if 'All' is selected.
                          image: AssetImage(selectedCategory?.imageUrl ?? "assets/all_events.jpg"), 
                          fit: BoxFit.cover,
                        ),
                      ),
                      
                      child: Stack(
                        children: [
                          // Soft dark gradient overlay so text stays readable on top of images
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                              ),
                            ),
                          ),
                          // Title and description details aligned to bottom left
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    // Dynamic Category Title
                                    (selectedCategory?.name ?? "ALL RIDES").toUpperCase(),
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 42,
                                      color: Colors.white, 
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Flexible(
                                    child: Text(
                                      // Dynamic Category Description
                                      selectedCategory?.description ?? "Check out every ride happening around Annaba.",
                                      textAlign: TextAlign.left,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        color: Colors.white70, 
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          
                    const SizedBox(height: 30),
                    
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          "UPCOMING EVENTS",
                          style: GoogleFonts.rajdhani(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==================================================================
                    // PIPELINE 3: LIVE EVENTS FEED (STREAMBUILDER WITH QUERY FILTER)
                    // ==================================================================
                    StreamBuilder<QuerySnapshot>(
                      // Create dynamic stream: Filter events older than 24 hours.
                      // Also filter by selected category ID if a filter is active!
                      stream: (() {
                        final firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
                        final twentyFourHoursAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));
                        
                        if (selectedCategory == null) {
                          return firestore.collection('events')
                              .where('date', isGreaterThan: twentyFourHoursAgo)
                              .snapshots();
                        } else {
                          return firestore.collection('events')
                              .where('categoryId', isEqualTo: selectedCategory!.id)
                              .where('date', isGreaterThan: twentyFourHoursAgo)
                              .snapshots();
                        }
                      })(),
                      builder: (context, snapshot) {
                        
                        // 1. Loading state
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(child: CircularProgressIndicator(color: Color(0xFF39FF14))),
                          );
                        }

                        // 2. Error State
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("FIREBASE ERROR: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                          );
                        }

                        // 3. Empty state (No events match filter)
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min, // Keeps the icon and text grouped tightly together
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded, // A sleek calendar icon (or use Icons.directions_bike)
                                    size: 48,
                                    color: Colors.white24, // Faded into the background
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      "No upcoming ${(selectedCategory?.name ?? "Rides").toLowerCase()}.", 
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white54, 
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500, // Slightly thicker than normal for readability
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Parse Firestore documents into custom HubikeEvent model objects
                        List<HubikeEvent> liveEvents = snapshot.data!.docs.map((doc) {
                          return HubikeEvent.fromFirestore(doc);
                        }).toList();

                        // Double check array length
                        if (liveEvents.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 64,
                                    color: Colors.white24,
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      "No upcoming ${(selectedCategory?.name ?? "Rides").toUpperCase()}.", 
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white54, 
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Return vertical list of Event Cards
                        return Column(
                          children: liveEvents.map((event) {
                            return _buildEventCard(event); 
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 60), 
                  ],
                ),
              ),
            ],
        ),
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS (UI SUB-COMPONENTS)
  // ============================================================================

  // COLOR PARSER: Translates hexadecimal strings from Firestore (e.g. '#39FF14')
  // into functional Flutter Color objects.
  Color _parseColor(String colorHex) {
    if (colorHex.isEmpty) return const Color(0xFF39FF14);
    try {
      String hex = colorHex.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return const Color(0xFF39FF14);
    }
  }

  // All Category button: Tapping this sets selectedCategory = null (shows all events)
  Widget _buildAllButton() {
    bool isSelected = selectedCategory == null;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0), 
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedCategory = null; 
          });
        },
        style: _buttonStyle(isSelected, const Color(0xFF39FF14).withOpacity(0.15)),
        child: Text(
          "All",
          style: _buttonTextStyle(isSelected, const Color(0xFF39FF14)),
        ),
      ),
    );
  }

  // Dynamic Category button: Tapping this sets selectedCategory to the clicked category
  Widget _buildCategoryButton(HubikeCategory category) {
    bool isSelected = selectedCategory?.id == category.id;
    Color catColor = _parseColor(category.colorHex);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0), 
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedCategory = category; 
          });
        },
        style: _buttonStyle(isSelected, catColor),
        child: Text(
          category.name,
          style: _buttonTextStyle(isSelected, catColor),
        ),
      ),
    );
  }

  // Style builder for category filters. Active filter gets a subtle neon glow border.
  ButtonStyle _buttonStyle(bool isSelected, Color catColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: isSelected ? catColor.withOpacity(0.15) : const Color(0xFF1E1E1E), 
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide.none, // This permanently kills the harsh neon ring
      ),
    );
  }

  // Text color logic for active vs inactive categories
  TextStyle _buttonTextStyle(bool isSelected, Color catColor) {
    return GoogleFonts.montserrat(
      color: isSelected ? catColor : Colors.white54,
      fontWeight: FontWeight.w500, 
    );
  }

  // EVENT CARD COMPONENT: Draws a detailed preview block for a cycling event.
  Widget _buildEventCard(HubikeEvent event) {
    // 1. Check time properties of the event
    bool isOngoing = DateTime.now().isAfter(event.date) || DateTime.now().isAtSameMomentAs(event.date);
    bool isFull = event.currentParticipants >= event.capacity;
    bool isTooLate = DateTime.now().isAfter(event.date.subtract(const Duration(hours: 1)));
    
    // 2. Fetch category details from cache to read the color hex
    HubikeCategory? eventCategory = cachedCategories[event.categoryId];
    Color categoryColor = _parseColor(eventCategory?.colorHex ?? '');

    // 3. Calculate participation status
    String statusDisplay = 'Available';
    Color statusColor = const Color(0xFF39FF14); // Green
    
    if (isOngoing) {
      statusDisplay = 'Ongoing';
      statusColor = Colors.orange;
    } else if (isTooLate || isFull || event.status != 'Available') {
      statusDisplay = 'Unavailable';
      statusColor = Colors.red;
    }

    // 4. Format time from database into a human-readable string
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = months[event.date.month - 1];
    final dayStr = event.date.day.toString();
    final yearStr = event.date.year.toString();
    final hourStr = event.date.hour.toString().padLeft(2, '0');
    final minuteStr = event.date.minute.toString().padLeft(2, '0');
    final formattedDate = '$monthStr $dayStr, $yearStr - $hourStr:$minuteStr';

    return GestureDetector(
      // Tapping card opens the detailed registration page for this event
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event, currentUser: widget.currentUser),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          // Glow effect using the category color!
          border: Border.all(color: categoryColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Left color strip: Glow highlight matching the event's category color
            Container(
              width: 6,
              height: 120,
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
            // Text contents of the card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event.eventName,
                            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Show reward coins or status warning
                        statusDisplay == 'Available'
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "+${event.coinsToEarn} Coins",
                                style: TextStyle(color: categoryColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          : Text(
                              statusDisplay,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Hosted by ${event.creatorName}",
                      style: TextStyle(color: categoryColor.withOpacity(0.8), fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    // Date & Location Info Row
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: categoryColor.withOpacity(0.7), size: 16),
                        const SizedBox(width: 6),
                        Text(formattedDate, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 16),
                        Icon(Icons.location_on, color: categoryColor.withOpacity(0.7), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.startingPoint, 
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Short description block
                    Text(
                      event.description,
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis, 
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}