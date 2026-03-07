import 'package:flutter/material.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double _discount = 0;
  double get discount => _discount;

  double get total => (subtotal - _discount).clamp(0, double.infinity);

  void addItem(Product product, int quantity) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex] =
          _items[existingIndex].copyWith(quantity: _items[existingIndex].quantity + quantity);
    } else {
      _items.add(CartItem(
        product: product,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void setDiscount(double discountAmount) {
    _discount = discountAmount.clamp(0, subtotal);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _discount = 0;
    notifyListeners();
  }

  int get itemCount => _items.length;

  bool get isEmpty => _items.isEmpty;
}

class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.salePrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}
