import 'book_model.dart';
import 'payment_model.dart';
import 'user_model.dart';

class OrderItemModel {
  final int id;
  final int orderId;
  final int bookId;
  final int quantity;
  final double price;
  final double subtotal;
  final BookModel? book;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.bookId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.book,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      orderId: json['order_id'] is int ? json['order_id'] : int.tryParse(json['order_id'].toString()) ?? 0,
      bookId: json['book_id'] is int ? json['book_id'] : int.tryParse(json['book_id'].toString()) ?? 0,
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity'].toString()) ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      book: json['book'] != null ? BookModel.fromJson(json['book']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'book_id': bookId,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      if (book != null) 'book': book!.toJson(),
    };
  }
}

class OrderModel {
  final int id;
  final int userId;
  final String orderNumber;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double totalAmount;
  final String status; // 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
  final String shippingAddress;
  final String deliveryMethod;
  final String? phone;
  final String? note;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final PaymentModel? payment;
  final UserModel? user;

  OrderModel({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    this.deliveryMethod = 'Standard Courier (1-2 days)',
    this.phone,
    this.note,
    required this.createdAt,
    this.items = const [],
    this.payment,
    this.user,
  });

  String get invoiceNumber => orderNumber.isNotEmpty ? orderNumber : 'ORD-${id.toString().padLeft(6, '0')}';
  bool get isPaid => payment?.isPaid ?? false;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList();
    }

    return OrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      orderNumber: json['order_number'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      shippingAddress: json['shipping_address'] ?? '',
      deliveryMethod: json['delivery_method'] ?? 'Standard Courier',
      phone: json['phone']?.toString(),
      note: json['note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: parsedItems,
      payment: json['payment'] != null ? PaymentModel.fromJson(json['payment']) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_number': orderNumber,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount': discount,
      'total_amount': totalAmount,
      'status': status,
      'shipping_address': shippingAddress,
      'delivery_method': deliveryMethod,
      'phone': phone,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
      if (payment != null) 'payment': payment!.toJson(),
      if (user != null) 'user': user!.toJson(),
    };
  }
}

class DigitalReceiptModel {
  final String invoiceNumber;
  final String orderDate;
  final Map<String, dynamic> storeInfo;
  final Map<String, dynamic> customer;
  final List<dynamic> items;
  final Map<String, dynamic> financials;
  final Map<String, dynamic> payment;
  final String orderStatus;

  DigitalReceiptModel({
    required this.invoiceNumber,
    required this.orderDate,
    required this.storeInfo,
    required this.customer,
    required this.items,
    required this.financials,
    required this.payment,
    required this.orderStatus,
  });

  factory DigitalReceiptModel.fromJson(Map<String, dynamic> json) {
    return DigitalReceiptModel(
      invoiceNumber: json['invoice_number'] ?? '',
      orderDate: json['order_date'] ?? '',
      storeInfo: Map<String, dynamic>.from(json['store_info'] ?? {}),
      customer: Map<String, dynamic>.from(json['customer'] ?? {}),
      items: json['items'] is List ? json['items'] : [],
      financials: Map<String, dynamic>.from(json['financials'] ?? {}),
      payment: Map<String, dynamic>.from(json['payment'] ?? {}),
      orderStatus: json['order_status'] ?? 'pending',
    );
  }
}
