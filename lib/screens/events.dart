import 'package:flutter/material.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Dark background
      
      body: ListView(
        
          children: [
            
            const SizedBox(height: 40), 
            
            // 1. THE HORIZONTAL FILTER BUTTONS
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildCategoryButton("All"),
                  _buildCategoryButton("Adventure"),
                  _buildCategoryButton("Green Bike"),
                  _buildCategoryButton("Family Rides"),
                  _buildCategoryButton("Competitive"),
                  _buildCategoryButton("Nocturne"),
                ],
              ),
            ),
        
            const SizedBox(height: 24), // Space between buttons and the image
        
            // 2. THE DYNAMIC CONTENT (Pushed to the top!)
            // 2. THE DYNAMIC CONTENT (With text layered OVER the image!)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, 
                  children: [
                    
                    // THE STACK CAGE: This holds the image, the dark filter, and the text!
                    Container(
                      height: 350, 
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF39FF14), width: 1),
                        // 1. The Background Image
                        image: DecorationImage(
                          image: AssetImage(_getImage()), 
                          fit: BoxFit.cover,
                        ),
                      ),
                      
                      // 2. The Stack lets us put things ON TOP of the image
                      child: Stack(
                        children: [
                                                  
                          // 4. The Text, perfectly centered over the dark image!
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // The Title
                                  Text(
                                    selectedCategory.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 30,
                                      color: Colors.white, 
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 250),
                                  
                                  // The Description
                                  Text(
                                    _getDescription(),
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white, // Made it pure white for contrast
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
        
                    SizedBox(height: 30), // Space between the image and the bottom buttons
                    
                    Text(
                      "UPCOMING EVENTS",
                      style: TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 18,
                      ),
                      
                    ),
                    
                    
                  ],
                ),
              ),
            ),
          ],
        
      ),
    );
  }



  // ---------------------------------------------------------
  // SIMPLE HELPER METHODS (Much easier to read than a Map!)
  // ---------------------------------------------------------

  // Returns the image path based on what button was clicked
  String _getImage() {
    if (selectedCategory == "All") return "assets/all_events.jpg";
    if (selectedCategory == "Adventure") return "assets/adventure.jpg";
    if (selectedCategory == "Green Bike") return "assets/green-bike.jpg";
    if (selectedCategory == "Family Rides") return "assets/family.jpg";
    if (selectedCategory == "Competitive") return "assets/competitive.jpg";
    if (selectedCategory == "Nocturne") return "assets/nocturne.jpg";
    
    return "assets/placeholder.jpg"; // Fallback image if one is missing
  }

  // Returns the description text based on what button was clicked
  String _getDescription() {
    if (selectedCategory == "All") return "Check out every ride happening around Annaba.";
    if (selectedCategory == "Adventure") return "Hit the dirt trails. Mountain bikes required.";
    if (selectedCategory == "Green Bike") return "Eco-friendly, slow-paced rides cleaning up the coast.";
    if (selectedCategory == "Family Rides") return "Safe, easy routes perfect for casual weekend pedaling.";
    if (selectedCategory == "Competitive") return "High-speed sprints. Bring your aero gear.";
    if (selectedCategory == "Nocturne") return "Midnight city cruising. Lights and good vibes only.";
    
    return "More information coming soon."; // Fallback text
  }

  // Draws the buttons
  Widget _buildCategoryButton(String title) {
    bool isSelected = selectedCategory == title;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0), 
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedCategory = title;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF39FF14) : Colors.grey.shade900,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), 
            side: const BorderSide(color: Colors.grey, width: 0.2),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white54,
            fontWeight: FontWeight.w900, 
          ),
        ),
      ),
    );
  }
}