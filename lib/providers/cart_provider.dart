import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/cart_model.dart';

class CartProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<CartItemModel> _items = [];
  double _subtotal = 0.0;
  double _deliveryFee = 0.0;
  double _totalAmount = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItemModel> get items => _items;
  double get subtotal => _subtotal;
  double get deliveryFee => _deliveryFee;
  double get totalAmount => _totalAmount;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.get(ApiConstants.cart);
      if (res != null && res['data'] is List) {
        _items = (res['data'] as List)
            .map((e) => CartItemModel.fromJson(e))
            .toList();

        if (res['summary'] != null) {
          _subtotal = (res['summary']['subtotal'] as num?)?.toDouble() ?? 0.0;
          _deliveryFee = (res['summary']['delivery_fee'] as num?)?.toDouble() ?? 0.0;
          _totalAmount = (res['summary']['total_amount'] as num?)?.toDouble() ?? 0.0;
        } else {
          _recalculate();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load shopping cart';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(int bookId, {int quantity = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(ApiConstants.cart, body: {
        'book_id': bookId,
        'quantity': quantity,
      });

      if (res != null && res['success'] == true) {
        await fetchCart();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to add item to cart.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> updateQuantity(int cartItemId, int newQty) async {
    try {
      final res = await _apiClient.put('${ApiConstants.cart}/$cartItemId', body: {
        'quantity': newQty,
      });

      if (res != null && res['success'] == true) {
        if (newQty <= 0) {
          _items.removeWhere((item) => item.id == cartItemId);
        } else {
          final idx = _items.indexWhere((item) => item.id == cartItemId);
          if (idx != -1) {
            _items[idx].quantity = newQty;
          }
        }
        _recalculate();
        notifyListeners();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> removeItem(int cartItemId) async {
    try {
      await _apiClient.delete('${ApiConstants.cart}/$cartItemId');
      _items.removeWhere((item) => item.id == cartItemId);
      _recalculate();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> clearCart() async {
    try {
      await _apiClient.delete(ApiConstants.cart);
      _items.clear();
      _subtotal = 0.0;
      _deliveryFee = 0.0;
      _totalAmount = 0.0;
      notifyListeners();
    } catch (_) {}
  }

  void _recalculate() {
    _subtotal = _items.fold(0.0, (sum, item) => sum + item.subtotal);
    _deliveryFee = _subtotal > 0 ? 1.50 : 0.0;
    _totalAmount = _subtotal + _deliveryFee;
  }
}
