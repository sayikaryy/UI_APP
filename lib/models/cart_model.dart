import 'book_model.dart';

class CartItemModel {
  final int id;
  final int userId;
  final int bookId;
  int quantity;
  final BookModel? book;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.quantity,
    this.book,
  });

  double get subtotal => (book?.price ?? 0.0) * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      bookId: json['book_id'] is int ? json['book_id'] : int.tryParse(json['book_id'].toString()) ?? 0,
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity'].toString()) ?? 1,
      book: json['book'] != null ? BookModel.fromJson(json['book']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'quantity': quantity,
      if (book != null) 'book': book!.toJson(),
    };
  }
}

class CartSummaryModel {
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final int itemsCount;

  CartSummaryModel({
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.itemsCount,
  });

  factory CartSummaryModel.fromJson(Map<String, dynamic> json) {
    return CartSummaryModel(
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      itemsCount: json['items_count'] is int ? json['items_count'] : int.tryParse(json['items_count']?.toString() ?? '0') ?? 0,
    );
  }
}
