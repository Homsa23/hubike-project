import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_model.dart';
import 'category_model.dart';
import 'event_detail.dart';
import 'package:firebase_core/firebase_core.dart';

class EventsPage extends StatefulWidget {
  final bool signedIn;
  final Map<String, dynamic>? currentUser;

  const EventsPage({super.key, required this.signedIn, this.currentUser});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  // We now store the whole Category object so we can easily grab its image and description!
  // If it's null, that means we are on the "All" tab.
  HubikeCategory? selectedCategory; 
  
  // A local cache so Event Cards instantly know their Category's color without extra database reads!
  final Map<String, HubikeCategory> cachedCategories = {};

  @override
  void initState() {
    super.initState();
    deleteForgottenEvents();
  }

  Future<void> deleteForgottenEvents() async {
    try {
      final firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
      // Relaxed to 24 hours so testing/today events aren't instantly deleted
      final twentyFourHoursAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));
      
      final snapshot = await firestore
          .collection('events')
          .where('date', isLessThanOrEqualTo: twentyFourHoursAgo)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('Cleaned up ${snapshot.docs.length} forgotten events.');
    } catch (e) {
      debugPrint('Failed to delete forgotten events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: ListView(
          children: [
            const SizedBox(height: 40), 
            
            // ==========================================
            // 1. TOP PIPELINE: LIVE CATEGORY BUTTONS
            // ==========================================
            SizedBox(
              height: 40,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default').collection('categories').snapshots(),
                builder: (context, snapshot) {
                  
                  // 1. Show a loading spinner so we know it's trying to connect
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 20, height: 20, 
                        child: CircularProgressIndicator(color: Color(0xFF39FF14), strokeWidth: 2)
                      )
                    );
                  }

                  // 2. SHOW THE ERROR IF IT FAILS!
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("ERROR: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 10)),
                    );
                  }

                  // 3. If there is no data at all
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No Categories Found", style: TextStyle(color: Colors.white)));
                  }

                  // Convert Firebase docs to our Flutter Category Models
                  List<HubikeCategory> liveCategories = snapshot.data!.docs
                      .map((doc) => HubikeCategory.fromFirestore(doc))
                      .toList();

                  // Save them to our cache quietly so the Event Cards can use their colors
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    bool needsUpdate = false;
                    for (var cat in liveCategories) {
                      if (!cachedCategories.containsKey(cat.id) || cachedCategories[cat.id]?.colorHex != cat.colorHex) {
                        cachedCategories[cat.id] = cat;
                        needsUpdate = true;
                      }
                    }
                    if (needsUpdate && mounted) {
                      setState(() {}); // Redraw the event cards now that we have the colors!
                    }
                  });

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      // We manually build the "All" button first
                      _buildAllButton(),
                      
                      // Then we spread the live categories from Firebase!
                      ...liveCategories.map((category) {
                        return _buildCategoryButton(category);
                      }),
                    ],
                  );
                },
              ),
            ),
        
            const SizedBox(height: 24),
        
            // ==========================================
            // 2. THE STACK CAGE (Now Dynamic!)
            // ==========================================
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
                      border: Border.all(color: const Color(0xFF39FF14), width: 1),
                      image: DecorationImage(
                        // Dynamic Image! If null, show default. If active, show category image.
                        image: AssetImage(selectedCategory?.imageUrl ?? "assets/all_events.jpg"), 
                        fit: BoxFit.cover,
                      ),
                    ),
                    
                    child: Stack(
                      children: [
                        // Dark gradient overlay so text is readable
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
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // Dynamic Title!
                                  (selectedCategory?.name ?? "ALL RIDES").toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    color: Colors.white, 
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Flexible(
                                  child: Text(
                                    // Dynamic Description!
                                    selectedCategory?.description ?? "Check out every ride happening around Annaba.",
                                    textAlign: TextAlign.left,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
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
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "UPCOMING EVENTS",
                      style: TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ==========================================
                  // 3. BOTTOM PIPELINE: LIVE EVENTS
                  // ==========================================
                  StreamBuilder<QuerySnapshot>(
                    stream: (() {
                      final firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
                      // Matches the 24 hour relaxation so we see today's events!
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
                      
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF39FF14))),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text("FIREBASE ERROR: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              "No upcoming ${(selectedCategory?.name ?? "Rides").toUpperCase()}.", 
                              style: const TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          ),
                        );
                      }

                      // Factory Translator
                      List<HubikeEvent> liveEvents = snapshot.data!.docs.map((doc) {
                        return HubikeEvent.fromFirestore(doc);
                      }).toList();

                      if (liveEvents.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              "No upcoming ${(selectedCategory?.name ?? "Rides").toUpperCase()}.", 
                              style: const TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          ),
                        );
                      }

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
    );
  }

  // ---------------------------------------------------------
  // HELPER METHODS
  // ---------------------------------------------------------

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

  // The static "All" button
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
        style: _buttonStyle(isSelected, const Color(0xFF39FF14)),
        child: Text(
          "All",
          style: _buttonTextStyle(isSelected, const Color(0xFF39FF14)),
        ),
      ),
    );
  }

  // The dynamic buttons powered by Firebase
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

  // Extracted styling to keep code clean
  ButtonStyle _buttonStyle(bool isSelected, Color catColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: isSelected ? catColor.withOpacity(0.15) : Colors.grey.shade900,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(
          color: isSelected ? catColor : Colors.grey.withOpacity(0.3), 
          width: isSelected ? 1.5 : 0.5
        ),
      ),
    );
  }

  TextStyle _buttonTextStyle(bool isSelected, Color catColor) {
    return TextStyle(
      color: isSelected ? catColor : Colors.white54,
      fontWeight: FontWeight.w900, 
    );
  }

  Widget _buildEventCard(HubikeEvent event) {
    bool isOngoing = DateTime.now().isAfter(event.date) || DateTime.now().isAtSameMomentAs(event.date);
    bool isFull = event.currentParticipants >= event.capacity;
    bool isTooLate = DateTime.now().isAfter(event.date.subtract(const Duration(hours: 1)));
    
    // Grab the category color from our cache!
    HubikeCategory? eventCategory = cachedCategories[event.categoryId];
    Color categoryColor = _parseColor(eventCategory?.colorHex ?? '');

    String statusDisplay = 'Available';
    Color statusColor = const Color(0xFF39FF14); // Green
    
    if (isOngoing) {
      statusDisplay = 'Ongoing';
      statusColor = Colors.orange;
    } else if (isTooLate || isFull || event.status != 'Available') {
      statusDisplay = 'Unavailable';
      statusColor = Colors.red;
    }

    // Formatting date
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = months[event.date.month - 1];
    final dayStr = event.date.day.toString();
    final yearStr = event.date.year.toString();
    final hourStr = event.date.hour.toString().padLeft(2, '0');
    final minuteStr = event.date.minute.toString().padLeft(2, '0');
    final formattedDate = '$monthStr $dayStr, $yearStr - $hourStr:$minuteStr';

    return GestureDetector(
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
            // Glowing Left Color Strip
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