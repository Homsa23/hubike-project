import 'package:flutter/material.dart';
import 'product_model.dart';

class CartState extends ChangeNotifier {
  static final CartState _instance = CartState._internal();
  factory CartState() => _instance;
  CartState._internal();

  final List<Product> _items = [];
  final Map<String, int> _quantities = {};

  List<Product> get items => _items;

  void addProduct(Product product) {
    if (_quantities.containsKey(product.id)) {
      _quantities[product.id] = _quantities[product.id]! + 1;
    } else {
      _items.add(product);
      _quantities[product.id] = 1;
    }
    notifyListeners();
  }

  int getQuantity(String productId) {
    return _quantities[productId] ?? 0;
  }

  void removeProduct(Product product) {
    if (_quantities.containsKey(product.id)) {
      if (_quantities[product.id]! > 1) {
        _quantities[product.id] = _quantities[product.id]! - 1;
      } else {
        _quantities.remove(product.id);
        _items.removeWhere((item) => item.id == product.id);
      }
      notifyListeners();
    }
  }

  void completelyRemoveProduct(String productId) {
    _quantities.remove(productId);
    _items.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _quantities.clear();
    notifyListeners();
  }

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + (item.price * getQuantity(item.id)));
  }
}

// Global instance for easy access
final cartState = CartState();
