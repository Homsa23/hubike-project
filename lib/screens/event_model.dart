import 'package:cloud_firestore/cloud_firestore.dart';

class HubikeEvent {
  final String id; // We store the document ID (like zI0KS...) just in case you need it later
  final int capacity;
  final int coinsToEarn;
  final String date;
  final String description; 
  final String eventName;
  final String categoryId;
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
    required this.categoryId,
    required this.price,
    required this.priceInCoins,
    required this.startingPoint,
  });

  // THE TRANSLATOR: This factory method takes a Firebase Document and builds a HubikeEvent.
  // THE TRANSLATOR: This factory method takes a Firebase Document and builds a HubikeEvent.
  factory HubikeEvent.fromFirestore(DocumentSnapshot doc) {
    // Grab the raw data map from the Firebase document
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return HubikeEvent(
      id: doc.id, 
      
      // THE FIX: We added .toInt() to force Firebase's decimals into standard integers!
      capacity: (data['capacity'] ?? 0).toInt(),
      coinsToEarn: (data['coinsToEarn'] ?? 0).toInt(),
      price: (data['price'] ?? 0).toInt(),
      priceInCoins: (data['priceInCoins'] ?? 0).toInt(),
      
      // Strings stay exactly the same
      date: data['date'] ?? 'TBD',
      description: data['description'] ?? 'No description available.', 
      eventName: data['eventName'] ?? 'Unknown Event',
      categoryId: data['categoryId'] ?? '',
      startingPoint: data['startingPoint'] ?? 'TBD',
    );
  }
}