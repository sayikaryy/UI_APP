import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/order_model.dart';
import '../models/address_model.dart';
import '../models/payment_model.dart';

class OrderProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<OrderModel> _orders = [];
  List<AddressModel> _addresses = [];
  OrderModel? _currentOrder;
  DigitalReceiptModel? _currentReceipt;
  KhqrDataModel? _khqrData;

  bool _isLoading = false;
  String? _errorMessage;
  String? _paymentSuccessMessage;

  List<OrderModel> get orders => _orders;
  List<AddressModel> get addresses => _addresses;
  OrderModel? get currentOrder => _currentOrder;
  DigitalReceiptModel? get currentReceipt => _currentReceipt;
  KhqrDataModel? get khqrData => _khqrData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get paymentSuccessMessage => _paymentSuccessMessage;

  AddressModel? get defaultAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
  }

  Future<void> fetchAddresses() async {
    try {
      final res = await _apiClient.get(ApiConstants.addresses);
      if (res != null && res['data'] is List) {
        _addresses = (res['data'] as List)
            .map((e) => AddressModel.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> addAddress({
    required String recipientName,
    required String phone,
    required String addressLine,
    String city = 'Phnom Penh',
    String label = 'Home',
    bool isDefault = false,
  }) async {
    try {
      final res = await _apiClient.post(ApiConstants.addresses, body: {
        'recipient_name': recipientName,
        'phone': phone,
        'address_line': addressLine,
        'city': city,
        'label': label,
        'is_default': isDefault,
      });

      if (res != null && res['success'] == true) {
        await fetchAddresses();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.get(ApiConstants.orders);
      if (res != null && res['data'] is List) {
        _orders = (res['data'] as List)
            .map((e) => OrderModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to load order history.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> placeOrder({
    required String shippingAddress,
    required String paymentMethod,
    String deliveryMethod = 'Standard Courier (1-2 days)',
    String? phone,
    String? note,
    required List<Map<String, dynamic>> items,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(ApiConstants.orders, body: {
        'shipping_address': shippingAddress,
        'payment_method': paymentMethod,
        'delivery_method': deliveryMethod,
        'phone': phone,
        'note': note,
        'items': items,
      });

      if (res != null && res['success'] == true) {
        final orderData = res['order'] ?? res['data'];
        final order = OrderModel.fromJson(orderData);
        _currentOrder = order;
        _isLoading = false;
        notifyListeners();
        return order;
      } else {
        _errorMessage = res?['message']?.toString() ?? 'Order placement failed.';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e, stackTrace) {
      debugPrint('Error placing order: $e\n$stackTrace');
      _errorMessage = 'Order processing failed: $e';
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<bool> generateKhqr(int orderId, {String bank = 'ABA'}) async {
    _isLoading = true;
    _khqrData = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(ApiConstants.generateQr, body: {
        'order_id': orderId,
        'bank_provider': bank,
      });

      if (res != null && res['data'] != null) {
        _khqrData = KhqrDataModel.fromJson(res['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res?['message']?.toString() ?? 'Failed to generate KHQR code.';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Could not generate KHQR code.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> simulatePaymentSuccess(int orderId) async {
    _isLoading = true;
    _errorMessage = null;
    _paymentSuccessMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post('${ApiConstants.payments}/$orderId/simulate-success');
      if (res != null && res['success'] == true) {
        _paymentSuccessMessage = res['message']?.toString() ?? 'Payment successfully confirmed!';
        if (_currentOrder != null && _currentOrder!.id == orderId) {
          await fetchOrderDetail(orderId);
        }
        await fetchOrders();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res?['message']?.toString() ?? 'Payment simulation failed.';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'An error occurred during payment confirmation.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchOrderDetail(int orderId) async {
    try {
      final res = await _apiClient.get('${ApiConstants.orders}/$orderId');
      if (res != null && res['data'] != null) {
        _currentOrder = OrderModel.fromJson(res['data']);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<DigitalReceiptModel?> fetchReceipt(int orderId) async {
    _isLoading = true;
    _currentReceipt = null;
    notifyListeners();

    try {
      final res = await _apiClient.get('${ApiConstants.orders}/$orderId/receipt');
      if (res != null && res['data'] != null) {
        _currentReceipt = DigitalReceiptModel.fromJson(res['data']);
        _isLoading = false;
        notifyListeners();
        return _currentReceipt;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return null;
  }
}
