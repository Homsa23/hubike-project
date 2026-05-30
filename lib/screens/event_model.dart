import 'package:cloud_firestore/cloud_firestore.dart';

class HubikeEvent{
  final String id; // We store the document ID (like zI0KS...) just in case you need it later
  final int capacity;
  final int currentParticipants;
  final int coinsToEarn;
  final DateTime date;
  final String description; 
  final String eventName;
  final String categoryId;
  final int price;
  final int priceInCoins;
  final String startingPoint;
  final String level;
  final String officialPageLink;
  final String status;
  final String creatorName;
  final List<String> imageUrls;

  HubikeEvent({
    required this.id,
    required this.capacity,
    this.currentParticipants = 0,
    required this.coinsToEarn,
    required this.date,
    required this.description,
    required this.eventName,
    required this.categoryId,
    required this.price,
    required this.priceInCoins,
    required this.startingPoint,
    required this.level,
    required this.officialPageLink,
    this.status = 'Available',
    this.creatorName = 'HUBIKE Team',
    this.imageUrls = const [],
  });

  // THE TRANSLATOR: This factory method takes a Firebase Document and builds a HubikeEvent.
  // THE TRANSLATOR: This factory method takes a Firebase Document and builds a HubikeEvent.
  factory HubikeEvent.fromFirestore(DocumentSnapshot doc) {
    // Grab the raw data map from the Firebase document
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime eventDate = DateTime.now();
    if (data['date'] != null) {
      if (data['date'] is Timestamp) {
        eventDate = (data['date'] as Timestamp).toDate();
      } else if (data['date'] is String) {
        eventDate = DateTime.tryParse(data['date']) ?? DateTime.now();
      }
    }

    return HubikeEvent(
      id: doc.id, 
      
      capacity: (data['capacity'] ?? 0).toInt(),
      currentParticipants: (data['currentParticipants'] ?? 0).toInt(),
      coinsToEarn: (data['coinsToEarn'] ?? 0).toInt(),
      price: (data['price'] ?? 0).toInt(),
      priceInCoins: (data['priceInCoins'] ?? 0).toInt(),
      
      date: eventDate,
      description: data['description'] ?? 'No description available.', 
      eventName: data['eventName'] ?? 'Unknown Event',
      categoryId: data['categoryId'] ?? '',
      startingPoint: data['startingPoint'] ?? 'TBD',
      level: data['level'] ?? 'All Levels',
      officialPageLink: data['officialPageLink'] ?? '',
      status: data['status'] ?? 'Available',
      creatorName: data['creatorName'] ?? 'HUBIKE Team',
      imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : [],
    );
  }
}