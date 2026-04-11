import 'package:cloud_firestore/cloud_firestore.dart';

class HubikeEvent {
  final String id; // We store the document ID (like zI0KS...) just in case you need it later
  final int capacity;
  final int coinsToEarn;
  final String date;
  final String description; 
  final String eventName;
  final String eventType; // The golden key for your filter buttons!
  final int price;
  final int priceInCoins;
  final String startingPoint;

  HubikeEvent({
    required this.id,
    required this.capacity,
    required this.coinsToEarn,
    required this.date,
    required this.description,
    required this.eventName,
    required this.eventType,
    required this.price,
    required this.priceInCoins,
    required this.startingPoint,
  });

  // THE TRANSLATOR: This factory method takes a Firebase Document and builds a HubikeEvent.
  factory HubikeEvent.fromFirestore(DocumentSnapshot doc) {
    // Grab the raw data map from the Firebase document
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return HubikeEvent(
      id: doc.id, // Grabs the Firebase generated ID automatically
      
      // The ?? means "If this is missing in the database, use a default value so the app doesn't crash"
      capacity: data['capacity'] ?? 0,
      coinsToEarn: data['coinsToEarn'] ?? 0,
      date: data['date'] ?? 'TBD',
      
      // Notice we look for your exact database spelling "description" here!
      description: data['description'] ?? 'No description available.', 
      
      eventName: data['eventName'] ?? 'Unknown Event',
      eventType: data['eventType'] ?? 'All',
      price: data['price'] ?? 0,
      priceInCoins: data['priceInCoins'] ?? 0,
      startingPoint: data['startingPoint'] ?? 'TBD',
    );
  }
}