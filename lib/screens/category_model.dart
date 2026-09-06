import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// DATA MODEL: HUBIKE CATEGORY
// ============================================================================
// This class acts as a blueprint (model) for event categories (like Mountain Bike, 
// Road Bike, etc.). It defines the structure of a category object and contains 
// a translator method to convert raw Firebase documents into clean Dart objects.
class HubikeCategory {
  // 1. PROPERTIES (THE BLUEPRINT FIELDS)
  // --------------------------------------------------
  final String id;          // The unique document ID from Firestore (e.g. 'mtb_01')
  final String name;        // Name of the category (e.g., 'Road Cycling')
  final String description; // Description of what this category is about
  final String imageUrl;    // Path to the banner image (e.g. 'assets/mtb.jpg')
  final String colorHex;    // Hex color code representing this category (e.g. '#39FF14')

  // 2. CONSTRUCTOR (THE BUILDER)
  // --------------------------------------------------
  // Used to instantiate a HubikeCategory object with all required properties.
  HubikeCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.colorHex,
  });

  // 3. FACTORY METHOD: fromFirestore (THE TRANSLATOR)
  // --------------------------------------------------
  // This takes a raw DocumentSnapshot (the envelope downloaded from Cloud Firestore)
  // and translates its raw JSON keys into a structured, type-safe HubikeCategory object.
  factory HubikeCategory.fromFirestore(DocumentSnapshot doc) {
    // Extract the raw data map from the document
    Map data = doc.data() as Map<String, dynamic>;
    
    return HubikeCategory(
      id: doc.id, // Extract the unique document ID straight from the Firebase Document!
      
      // Look up fields inside the Map. If they are missing or null, use safe fallbacks.
      name: data['name'] ?? 'Unknown Category',
      description: data['description'] ?? 'No description available.',
      imageUrl: data['image'] ?? 'assets/placeholder.jpg',
      colorHex: data['color']?.toString() ?? '#39FF14', // Default to neon green if null
    );
  }
}