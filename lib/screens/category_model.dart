import 'package:cloud_firestore/cloud_firestore.dart';

class HubikeCategory {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String colorHex;

  HubikeCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.colorHex,
  });

  // THE FACTORY: Takes the Firebase envelope and builds a Flutter instance
  factory HubikeCategory.fromFirestore(DocumentSnapshot doc) {
    // Extract the data map from the document
    Map data = doc.data() as Map<String, dynamic>;
    
    return HubikeCategory(
      id: doc.id, // We extract the document ID straight from Firebase!
      name: data['name'] ?? 'Unknown Category',
      description: data['description'] ?? 'No description available.',
      imageUrl: data['image'] ?? 'assets/placeholder.jpg',
      colorHex: data['color']?.toString() ?? '#39FF14',
    );
  }
}