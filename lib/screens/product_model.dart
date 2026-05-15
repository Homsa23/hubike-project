import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String groupLeaderId;
  final String name;
  final String brand;
  final String category;
  final String condition;
  final String description;
  final double price;
  final int quantity;
  final int discountCoins;
  final String imageUrl;

  Product({
    required this.id,
    required this.groupLeaderId,
    required this.name,
    required this.brand,
    required this.category,
    required this.condition,
    required this.description,
    required this.price,
    required this.quantity,
    required this.discountCoins,
    required this.imageUrl,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      groupLeaderId: data['groupLeaderId'] ?? '',
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
      condition: data['condition'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0).toInt(),
      discountCoins: (data['discountCoins'] ?? 0).toInt(),
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupLeaderId': groupLeaderId,
      'name': name,
      'brand': brand,
      'category': category,
      'condition': condition,
      'description': description,
      'price': price,
      'quantity': quantity,
      'discountCoins': discountCoins,
      'imageUrl': imageUrl,
    };
  }
}
