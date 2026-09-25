import 'book_model.dart';
import 'order_model.dart';

class AdminDashboardKpis {
  final double totalRevenue;
  final int totalOrders;
  final int activeCustomers;
  final int totalBooks;
  final int lowStockCount;

  AdminDashboardKpis({
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeCustomers,
    required this.totalBooks,
    required this.lowStockCount,
  });

  factory AdminDashboardKpis.fromJson(Map<String, dynamic> json) {
    return AdminDashboardKpis(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] is int ? json['total_orders'] : int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
      activeCustomers: json['active_customers'] is int ? json['active_customers'] : int.tryParse(json['active_customers']?.toString() ?? '0') ?? 0,
      totalBooks: json['total_books'] is int ? json['total_books'] : int.tryParse(json['total_books']?.toString() ?? '0') ?? 0,
      lowStockCount: json['low_stock_count'] is int ? json['low_stock_count'] : int.tryParse(json['low_stock_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class SupplierModel {
  final int id;
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String status;

  SupplierModel({
    required this.id,
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.status = 'active',
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      contactPerson: json['contact_person']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_person': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'status': status,
    };
  }
}

class ActivityLogModel {
  final int id;
  final int? userId;
  final String action;
  final String module;
  final String description;
  final String? ipAddress;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    this.userId,
    required this.action,
    required this.module,
    required this.description,
    this.ipAddress,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
      action: json['action'] ?? '',
      module: json['module'] ?? '',
      description: json['description'] ?? '',
      ipAddress: json['ip_address']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
