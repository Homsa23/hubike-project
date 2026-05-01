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
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                const SizedBox(height: 200), // Adjusted spacing to fit the gradient
                                Text(
                                  // Dynamic Description!
                                  selectedCategory?.description ?? "Check out every ride happening around Annaba.",
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white, 
                                    height: 1.5,
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
                    stream: selectedCategory == null 
                      ? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default').collection('events').snapshots() 
                      : FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default').collection('events')
                          .where('categoryId', isEqualTo: selectedCategory!.id) 
                          .snapshots(),
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

  // The static "All" button
  Widget _buildAllButton() {
    bool isSelected = selectedCategory == null;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0), 
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedCategory = null; // Setting to null triggers "All" mode
          });
        },
        style: _buttonStyle(isSelected),
        child: Text(
          "All",
          style: _buttonTextStyle(isSelected),
        ),
      ),
    );
  }

  // The dynamic buttons powered by Firebase
  Widget _buildCategoryButton(HubikeCategory category) {
    // Check if this specific category's ID matches the currently selected one
    bool isSelected = selectedCategory?.id == category.id;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0), 
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedCategory = category; // Save the whole category object!
          });
        },
        style: _buttonStyle(isSelected),
        child: Text(
          category.name,
          style: _buttonTextStyle(isSelected),
        ),
      ),
    );
  }

  // Extracted styling to keep code clean
  ButtonStyle _buttonStyle(bool isSelected) {
    return ElevatedButton.styleFrom(
      backgroundColor: isSelected ? const Color(0xFF39FF14) : Colors.grey.shade900,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: const BorderSide(color: Colors.grey, width: 0.2),
      ),
    );
  }

  TextStyle _buttonTextStyle(bool isSelected) {
    return TextStyle(
      color: isSelected ? Colors.black : Colors.white54,
      fontWeight: FontWeight.w900, 
    );
  }

  Widget _buildEventCard(HubikeEvent event) {
    return GestureDetector(
      onTap: () {
        // TEMPORARILY DISABLED: Sign-in check moved to Join button
        // TODO: Re-enable later when payment/join flow is ready
        // if (!widget.signedIn) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(
        //       content: Text('You must sign in first.'),
        //       duration: Duration(seconds: 3),
        //     ),
        //   );
        //   return;
        // }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event, currentUser: widget.currentUser),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, width: 1), 
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  event.eventName,
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  "+${event.coinsToEarn} Coins",
                  style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Text(event.date, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Text(event.startingPoint, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              maxLines: 2, 
              overflow: TextOverflow.ellipsis, 
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}