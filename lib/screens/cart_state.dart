import 'package:flutter/material.dart';
import 'product_model.dart';

class CartState extends ChangeNotifier {
  static final CartState _instance = CartState._internal();
  factory CartState() => _instance;
  CartState._internal();

  final List<Product> _items = [];
  List<Product> get items => _items;

  bool addProduct(Product product) {
    if (hasProduct(product.id)) {
      return false; // Already in cart
    }
    _items.add(product);
    notifyListeners();
    return true; // Successfully added
  }

  bool hasProduct(String productId) {
    return _items.any((item) => item.id == productId);
  }

  void removeProduct(Product product) {
    _items.remove(product);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + item.price);
  }
}

// Global instance for easy access
final cartState = CartState();
