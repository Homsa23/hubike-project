import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'product_model.dart';

class OrderModel {
  final String? id;
  final String name;
  final String lastName;
  final String phone;
  final String wilaya;
  final DateTime orderDate;
  final List<Product> products;
  final double totalAmount;

  OrderModel({
    this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    required this.wilaya,
    required this.orderDate,
    required this.products,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastName': lastName,
      'phone': phone,
      'wilaya': wilaya,
      'orderDate': Timestamp.fromDate(orderDate),
      'products': products.map((p) => p.toMap()).toList(),
      'totalAmount': totalAmount,
    };
  }

  Future<void> saveToFirestore() async {
    final firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    await firestore.collection('orders').add(toMap());
  }
}
