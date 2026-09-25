import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/book_model.dart';
import '../models/order_model.dart';
import '../models/dashboard_model.dart';

class AdminProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  AdminDashboardKpis? _kpis;
  List<BookModel> _lowStockBooks = [];
  List<OrderModel> _recentOrders = [];
  List<BookModel> _topSellingBooks = [];

  List<BookModel> _adminBooks = [];
  List<CategoryModel> _adminCategories = [];
  List<SupplierModel> _suppliers = [];
  List<OrderModel> _adminOrders = [];
  List<ActivityLogModel> _activityLogs = [];

  bool _isLoading = false;
  String? _errorMessage;

  AdminDashboardKpis? get kpis => _kpis;
  List<BookModel> get lowStockBooks => _lowStockBooks;
  List<OrderModel> get recentOrders => _recentOrders;
  List<BookModel> get topSellingBooks => _topSellingBooks;

  List<BookModel> get adminBooks => _adminBooks;
  List<CategoryModel> get adminCategories => _adminCategories;
  List<SupplierModel> get suppliers => _suppliers;
  List<OrderModel> get adminOrders => _adminOrders;
  List<ActivityLogModel> get activityLogs => _activityLogs;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.get(ApiConstants.adminDashboard);
      if (res != null && res['data'] != null) {
        final data = res['data'];
        if (data['kpis'] != null) {
          _kpis = AdminDashboardKpis.fromJson(data['kpis']);
        }
        if (data['low_stock_books'] is List) {
          _lowStockBooks = (data['low_stock_books'] as List)
              .map((e) => BookModel.fromJson(e))
              .toList();
        }
        if (data['recent_orders'] is List) {
          _recentOrders = (data['recent_orders'] as List)
              .map((e) => OrderModel.fromJson(e))
              .toList();
        }
        if (data['top_selling_books'] is List) {
          _topSellingBooks = (data['top_selling_books'] as List)
              .map((e) => BookModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load dashboard metrics';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminBooks({String? search, int? categoryId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (categoryId != null) params['category_id'] = categoryId;

      final res = await _apiClient.get(ApiConstants.adminBooks, queryParams: params);
      if (res != null && res['data'] is List) {
        _adminBooks = (res['data'] as List)
            .map((e) => BookModel.fromJson(e))
            .toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveBook({
    int? id,
    required int categoryId,
    required String title,
    required String author,
    String? isbn,
    String? publisher,
    int? publicationYear,
    String? description,
    required double price,
    required int stock,
    int lowStockThreshold = 5,
    String? coverImage,
    bool isFeatured = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    final body = {
      'category_id': categoryId,
      'title': title,
      'author': author,
      'isbn': isbn,
      'publisher': publisher,
      'publication_year': publicationYear,
      'description': description,
      'price': price,
      'stock': stock,
      'low_stock_threshold': lowStockThreshold,
      'cover_image': coverImage,
      'is_featured': isFeatured,
      'status': 'active',
    };

    try {
      dynamic res;
      if (id != null) {
        res = await _apiClient.put('${ApiConstants.adminBooks}/$id', body: body);
      } else {
        res = await _apiClient.post(ApiConstants.adminBooks, body: body);
      }

      if (res != null && res['success'] == true) {
        await fetchAdminBooks();
        await fetchDashboard();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteBook(int id) async {
    try {
      final res = await _apiClient.delete('${ApiConstants.adminBooks}/$id');
      if (res != null && res['success'] == true) {
        _adminBooks.removeWhere((b) => b.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> fetchAdminCategories() async {
    try {
      final res = await _apiClient.get(ApiConstants.adminCategories);
      if (res != null && res['data'] is List) {
        _adminCategories = (res['data'] as List)
            .map((e) => CategoryModel.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> saveCategory({int? id, required String name, String? description}) async {
    final body = {'name': name, 'description': description, 'status': 'active'};
    try {
      dynamic res;
      if (id != null) {
        res = await _apiClient.put('${ApiConstants.adminCategories}/$id', body: body);
      } else {
        res = await _apiClient.post(ApiConstants.adminCategories, body: body);
      }
      if (res != null && res['success'] == true) {
        await fetchAdminCategories();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final res = await _apiClient.delete('${ApiConstants.adminCategories}/$id');
      if (res != null && res['success'] == true) {
        _adminCategories.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> fetchInventory({bool lowStockOnly = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiClient.get(
        ApiConstants.adminInventory,
        queryParams: lowStockOnly ? {'low_stock_only': 1} : null,
      );
      if (res != null && res['data'] is List) {
        _adminBooks = (res['data'] as List)
            .map((e) => BookModel.fromJson(e))
            .toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> adjustStock({
    required int bookId,
    required String type, // 'stock_in', 'stock_out', 'adjustment'
    required int quantity,
    int? supplierId,
    String? notes,
  }) async {
    try {
      final res = await _apiClient.post(ApiConstants.adminInventoryAdjust, body: {
        'book_id': bookId,
        'type': type,
        'quantity': quantity,
        'supplier_id': supplierId,
        'notes': notes,
      });

      if (res != null && res['success'] == true) {
        await fetchDashboard();
        await fetchInventory();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> fetchSuppliers() async {
    try {
      final res = await _apiClient.get(ApiConstants.adminSuppliers);
      if (res != null && res['data'] is List) {
        _suppliers = (res['data'] as List)
            .map((e) => SupplierModel.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchAdminOrders({String? status, String? search}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (status != null && status != 'all') params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final res = await _apiClient.get(ApiConstants.adminOrders, queryParams: params);
      if (res != null && res['data'] is List) {
        _adminOrders = (res['data'] as List)
            .map((e) => OrderModel.fromJson(e))
            .toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final res = await _apiClient.put('${ApiConstants.adminOrders}/$orderId/status', body: {
        'status': newStatus,
      });

      if (res != null && res['success'] == true) {
        final idx = _adminOrders.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          _adminOrders[idx] = OrderModel.fromJson(res['data']);
        }
        await fetchDashboard();
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> fetchActivityLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiClient.get(ApiConstants.adminActivityLogs);
      if (res != null && res['data'] is List) {
        _activityLogs = (res['data'] as List)
            .map((e) => ActivityLogModel.fromJson(e))
            .toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}
